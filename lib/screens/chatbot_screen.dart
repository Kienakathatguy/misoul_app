  import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'dart:convert';
  import 'dart:async';
  import '../services/chat_service.dart';
  import 'therapy_chat_app.dart';
  import '../utils/time_manager.dart';

  class ChatbotScreen extends StatefulWidget {
    final int conversationId;
    final Function(List<Map<String, dynamic>>) onConversationUpdated;

    const ChatbotScreen({
      Key? key,
      required this.conversationId,
      required this.onConversationUpdated,
    }) : super(key: key);

    @override
    _ChatbotScreenState createState() => _ChatbotScreenState();
  }

  class _ChatbotScreenState extends State<ChatbotScreen> {
    final TextEditingController _controller = TextEditingController();
    List<Map<String, dynamic>> messages = [];
    Map<int, bool> showOptionsMap = {};
    Conversation? currentConversation;

    int usedChatMinutesToday = 0;
    static const int maxChatMinutesPerDay = 90;
    late Timer _minuteTimer;

    @override
    void initState() {
      super.initState();
      loadConversationHistory();
      loadChatTime();

      _minuteTimer = Timer.periodic(Duration(minutes: 90), (timer) async {
        await saveChatTime(1);
      });
    }

    @override
    void dispose() {
      _minuteTimer.cancel();
      super.dispose();
    }

    Future<void> loadChatTime() async {
      await TimeManager.initTodayTime();
      int minutes = await TimeManager.getUsedMinutes();

      if (minutes >= maxChatMinutesPerDay) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/time_up');
        }
      } else {
        setState(() {
          usedChatMinutesToday = minutes;
        });
      }
    }

    Future<void> saveChatTime(int minutesToAdd) async {
      await TimeManager.addMinuteUsed(minutesToAdd);
      int updated = await TimeManager.getUsedMinutes();

      if (updated >= maxChatMinutesPerDay) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/time_up');
        }
      } else {
        setState(() {
          usedChatMinutesToday = updated;
        });
      }
    }


    Future<void> loadConversationHistory() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Conversation> allConversations = [];
      String? conversationsData = prefs.getString('conversations');

      if (conversationsData != null) {
        allConversations = (json.decode(conversationsData) as List)
            .map((data) => Conversation.fromJson(data))
            .toList();
      }

      try {
        currentConversation = allConversations.firstWhere((c) => c.id == widget.conversationId);
      } catch (e) {
        print("❌ Không tìm thấy cuộc trò chuyện với ID: ${widget.conversationId}");
        return;
      }

      if (currentConversation != null) {
        setState(() {
          messages = List.from(currentConversation!.messages.map((msg) => {
            "role": msg["sender"] == "user" ? "user" : "bot",
            "text": msg["message"]
          }).toList());
        });
      }
    }

    Future<void> sendMessage() async {
      if (usedChatMinutesToday >= maxChatMinutesPerDay) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⏰ Bạn đã dùng hết 60 phút trò chuyện hôm nay")),
        );
        return;
      }

      String userMessage = _controller.text.trim();
      if (userMessage.isEmpty || currentConversation == null) return;

      setState(() {
        messages.add({"role": "user", "text": userMessage});
        currentConversation!.messages.add({
          "sender": "user",
          "message": userMessage,
        });
      });

      _controller.clear();

      Stopwatch stopwatch = Stopwatch()..start();

      var response = await ChatService.sendMessage(userMessage);

      stopwatch.stop();
      int secondsUsed = stopwatch.elapsed.inSeconds;
      int minutesUsed = (secondsUsed / 60).ceil();
      await saveChatTime(minutesUsed);

      if (response.containsKey("response")) {
        String botMessage = response["response"]["messages"].join("\n\n");

        setState(() {
          int index = messages.length;
          messages.add({"role": "bot", "text": botMessage});
          showOptionsMap[index] = shouldShowOptions(botMessage);
          currentConversation!.messages.add({
            "sender": "bot",
            "message": botMessage,
          });
        });

        _saveConversation();
      } else {
        setState(() {
          messages.add({"role": "bot", "text": "Có lỗi xảy ra khi gửi tin nhắn."});
        });
      }
    }

    bool shouldShowOptions(String message) {
      return message.contains("Bạn có muốn tôi chia sẻ một số bài tập/hướng dẫn");
    }

    Future<void> handleUserResponse(String response, int index) async {
      if (currentConversation == null) return;

      setState(() {
        messages.add({"role": "user", "text": response});
        showOptionsMap[index] = false;
        currentConversation!.messages.add({
          "sender": "user",
          "message": response,
        });
      });

      if (response == "đồng ý") {
        var botResponse = await ChatService.sendMessage(response);
        if (botResponse.containsKey("response")) {
          setState(() {
            messages.add({"role": "bot", "text": botResponse["response"]["messages"][0]});
            currentConversation!.messages.add({
              "sender": "bot",
              "message": botResponse["response"]["messages"][0],
            });
          });
        }
      } else {
        List<String> alternativeResponses = [
          "Không sao, nếu bạn cần giúp đỡ, cứ hỏi tôi nhé! 😊",
          "Bạn có muốn trò chuyện về điều gì khác không?",
          "Nếu có gì cần tâm sự, tôi luôn ở đây lắng nghe!"
        ];

        String botReply = (alternativeResponses..shuffle()).first;
        setState(() {
          messages.add({"role": "bot", "text": botReply});
          currentConversation!.messages.add({
            "sender": "bot",
            "message": botReply,
          });
        });
      }

      _saveConversation();
    }

    Future<void> _saveConversation() async {
      if (currentConversation == null) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<Conversation> allConversations = [];
      String? conversationsData = prefs.getString('conversations');

      if (conversationsData != null) {
        allConversations = (json.decode(conversationsData) as List)
            .map((data) => Conversation.fromJson(data))
            .toList();
      }

      int index = allConversations.indexWhere((c) => c.id == currentConversation!.id);
      if (index != -1) {
        allConversations[index] = currentConversation!;
      }

      prefs.setString('conversations', json.encode(allConversations.map((c) => c.toJson()).toList()));
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: Text("Trò chuyện cùng MISOUL")),
        body: Column(
          children: [
            // Thông báo thời gian còn lại
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              color: usedChatMinutesToday >= maxChatMinutesPerDay ? Colors.red[100] : Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    usedChatMinutesToday >= maxChatMinutesPerDay
                        ? "⏰ Bạn đã dùng hết 60 phút hôm nay"
                        : "🕒 Còn ${maxChatMinutesPerDay - usedChatMinutesToday} phút cho hôm nay",
                    style: TextStyle(
                      fontSize: 16,
                      color: usedChatMinutesToday >= maxChatMinutesPerDay ? Colors.red : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var msg = messages[index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      messageBubble(msg),
                      if (showOptionsMap[index] == true)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => handleUserResponse("đồng ý", index),
                              child: Text("Đồng ý"),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => handleUserResponse("từ chối", index),
                              child: Text("Từ chối"),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),

            messageInputField(),
          ],
        ),
      );
    }

    Widget messageBubble(Map<String, dynamic> msg) {
      return Align(
        alignment: msg["role"] == "user" ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: msg["role"] == "user" ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            msg["text"] ?? "",
            style: TextStyle(fontSize: 16),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      );
    }

    Widget messageInputField() {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: "Nhập tin nhắn..."),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: sendMessage,
            ),
          ],
        ),
      );
    }
  }
