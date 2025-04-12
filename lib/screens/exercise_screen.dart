import 'package:flutter/material.dart';
import 'package:misoul_fixed_app/screens/countdown_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final String exerciseName;
  final String musicLabel;

  const ExerciseScreen({
    Key? key,
    required this.exerciseName,
    this.musicLabel = 'Tĩnh tâm',
  }) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int selectedMinutes = 5;
  int selectedSeconds = 0;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Bài tập", style: TextStyle(color: Colors.black, fontSize: 24)),
        centerTitle: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Bạn muốn\n${widget.exerciseName.toLowerCase()}\ntrong bao lâu?",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(
                label: "$selectedMinutes",
                unit: "phút",
                onTap: () => _showTimePicker(type: "minute"),
              ),
              const SizedBox(width: 20),
              _buildTimeBox(
                label: "${selectedSeconds.toString().padLeft(2, '0')}",
                unit: "giây",
                onTap: () => _showTimePicker(type: "second"),
              ),
            ],
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _selectStartTime,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.deepPurple),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  Text(
                    selectedTime != null
                        ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                        : "Chọn giờ bắt đầu",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFB084F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_up, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text("Nhạc: ${widget.musicLabel}", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _startExercise,
              icon: const Icon(Icons.timer),
              label: const Text("Bắt đầu bài tập", style: TextStyle(fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeBox({required String label, required String unit, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
            decoration: BoxDecoration(
              color: const Color(0xFFB084F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(unit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showTimePicker({required String type}) {
    int initial = type == "minute" ? selectedMinutes : selectedSeconds;
    int max = type == "minute" ? 60 : 59;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int tempValue = initial;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 320,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    "Chọn ${type == "minute" ? "phút" : "giây"}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      onSelectedItemChanged: (index) => setModalState(() => tempValue = index),
                      physics: const FixedExtentScrollPhysics(),
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) => Center(
                          child: Text(
                            "$index",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: tempValue == index ? Colors.deepPurple : Colors.grey,
                            ),
                          ),
                        ),
                        childCount: max + 1,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      setState(() {
                        if (type == "minute") {
                          selectedMinutes = tempValue;
                        } else {
                          selectedSeconds = tempValue;
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Chọn"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _selectStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  void _startExercise() {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn thời gian bắt đầu")),
      );
      return;
    }

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final totalDuration = Duration(minutes: selectedMinutes, seconds: selectedSeconds);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountdownScreen(
          exerciseName: widget.exerciseName,
          duration: totalDuration,
          startTime: startDateTime, // gửi qua để lên lịch nhắc
        ),
      ),
    );
  }
}
