import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class IMUScreen extends StatefulWidget {
  const IMUScreen({Key? key}) : super(key: key);

  @override
  State<IMUScreen> createState() => _IMUScreenState();
}

class _IMUScreenState extends State<IMUScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _patientIdController = TextEditingController();

  String _currentPatientId = '';
  bool _isConnected = false;
  bool _isSending = false;

  final String _caregiverId = 'caregiver01';
  final String _caregiverName = 'Người chăm sóc';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
  }

  Future<void> _sendMissYouMessage() async {
    if (!_isConnected) return;

    setState(() => _isSending = true);

    try {
      await _firestore.collection('imuMessages').add({
        'senderId': _caregiverId,
        'receiverId': _currentPatientId,
        'messageType': 'miss_you',
        'messageText': '$_caregiverName đã gửi lời thương yêu tới bạn',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi "I miss you" thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _connectToPatient() async {
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập ID của patient'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final snapshot = await _firestore.collection('users').where('id', isEqualTo: patientId).get();

    if (snapshot.docs.isNotEmpty) {
      final userData = snapshot.docs.first.data();
      if (userData['userType'] == 'patient') {
        setState(() {
          _isConnected = true;
          _currentPatientId = patientId;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã kết nối với patient $patientId'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID này không phải của patient'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy patient với ID này'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I MISS U - Caregiver'),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              setState(() {
                _isConnected = false;
                _currentPatientId = '';
              });
            },
            tooltip: 'Ngắt kết nối',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isConnected) ...[
                const Text(
                  'Kết nối với bệnh nhân',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: _patientIdController,
                  decoration: InputDecoration(
                    hintText: 'Nhập ID bệnh nhân (ví dụ: patient01)',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: _connectToPatient,
                  child: const Text('Kết nối'),
                ),
              ] else ...[
                Text(
                  'Đã kết nối với Patient ID: $_currentPatientId',
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),
                GestureDetector(
                  onTap: _isSending ? null : _sendMissYouMessage,
                  child: Container(
                    width: 200.0,
                    height: 200.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.pink)
                          : const Icon(
                        Icons.favorite,
                        color: Colors.pink,
                        size: 100.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Chạm vào trái tim để gửi "I miss you"',
                  style: TextStyle(fontSize: 16.0),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isConnected = false;
                      _currentPatientId = '';
                    });
                  },
                  child: const Text('Ngắt kết nối'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
