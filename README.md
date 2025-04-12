<<<<<<< HEAD
# MISOUL App

MISOUL App là một ứng dụng Flutter giúp người dùng quản lý cảm xúc và thư giãn thông qua các bài tập trị liệu. Ứng dụng cung cấp các tính năng như trò chuyện với chatbot, theo dõi tâm trạng, và nhiều tính năng hữu ích khác.

## Yêu cầu cần thiết

- Flutter SDK (2.5.0 trở lên)
- Dart SDK (2.14.0 trở lên)
- IDE (VS Code hoặc Android Studio)
- Git
- Tài khoản Firebase

## Cài đặt

# Bước 1: Clone repository
git clone https://github.com/Kienakathatguy/misoul_app.git

# Bước 2: Di chuyển vào thư mục dự án
cd misoul_app

# Bước 3: Cấu hình Tạo file .env trong thư mục gốc với nội dung:

GOOGLE_API_KEY=
MISOUL_API_KEY=
DEBUG=True
VECTOR_DB_PATH=./data/misoul_vectordb
MODEL_NAME=models/gemini-1.5-flash


SCHEDULER_API_URL=
FLASK_ENV=development
FLASK_APP=api/app.py
PORT=5000
DEBUG=True

# API Keys Ứng dụng yêu cầu hai API key:
## GOOGLE_API_KEY:
Cần đăng ký tại Google AI Studio (https://ai.google.dev/)
Hoặc liên hệ team lead để nhận key
## MISOUL_API_KEY:
Đây là key tự tạo để bảo vệ API của MISOUL Bạn có thể dùng key đã thống nhất trong team Hoặc tạo key ngẫu nhiên của riêng bạn Quan trọng: Dùng cùng một key trong cả server và client

# Bước 4: Sau khi đã clone 2 AI model chatbot và AI Scheduler 
(Nếu chưa thì phải clone và làm theo hướng dẫn của 2 AI model này trước:
https://github.com/ntlinh0402/Misoul_chatbot.git
https://github.com/ntlinh0402/Misoul_exercise.git)

Chạy 2 model trên VS Code
Thay API link cho chatbot trong file chat_service.dart bằng IPV4 của mạng mình: http://[IPV4]:5000/api/chat
Thay API link trong file .env: 
SCHEDULER_API_URL=http://[IPV4]:5000/recommend

# Bước 6: Thiết lập Firebase

Tạo dự án Firebase mới tại console.firebase.google.com
Kích hoạt Firestore Database và Authentication
Tạo ứng dụng Android trong Firebase
Tải tệp google-services.json và đặt vào thư mục android/app/
## Cập nhật thông tin Firebase trong file lib/main.dart:

dartawait Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY", 
    appId: "YOUR_APP_ID",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    projectId: "YOUR_PROJECT_ID", 
  ),
);

# Bước 7:Thiết lập dữ liệu người dùng


Tạo collection users trong Firestore Database
Thêm document cho Caregiver với cấu trúc:
id: "caregiver01"
userType: "caregiver"
name: "Tên Người Chăm Sóc"

Thêm document cho Patient với cấu trúc:
id: "patient01"
userType: "patient"
name: "Tên Bệnh Nhân"
lastStatus: "Bình thường"

Collection: imuMessages

Document ID: Tự động tạo
Fields:

senderId: ID người gửi
receiverId: ID người nhận
messageType: Loại tin nhắn (miss_you)
messageText: Nội dung tin nhắn
timestamp: Thời gian gửi
read: Trạng thái đã đọc



Tạo chỉ mục (index) cho Firestore
Để hiển thị tin nhắn đúng thứ tự, bạn cần tạo chỉ mục:

Vào Firestore trong Firebase Console
Chọn tab "Indexes"
Tạo chỉ mục mới:

Collection: imuMessages
Fields to index:

receiverId (Ascending)
timestamp (Descending)



# Bước 8: Cài đặt các dependencies
flutter pub get

# Bước 9: Chạy ứng dụng
flutter run

# Liên hệ
Nếu có bất kỳ câu hỏi hoặc đề xuất nào, vui lòng liên hệ:

Email: nguyenthuylinh040205@gmail.com


=======
# misoul_fixed_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 78a51ad (Fix music 2)
