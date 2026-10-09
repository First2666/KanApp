# 📱 KanApp - แอพพลิเคชันท่องเที่ยวกาญจนบุรี (Flutter Mobile Client)

แอพพลิเคชันมือถือสร้างด้วย **Flutter** (รองรับทั้ง Android & iOS) เชื่อมต่อกับ Backend **ASP.NET Core Web API (KanG)** ที่พอร์ต `5088` ผ่านฐานข้อมูลและระบบ RESTful API ตัวเดียวกับหน้าเว็บ Vue 3 (`Kanvue`)

---

## 🏗️ โครงสร้างโฟลเดอร์ (Project Structure)

```text
C:\KanApp\
├── pubspec.yaml                 # รายการไลบรารีและแพ็กเกจ (http, provider, shared_preferences)
├── README.md
└── lib\
    ├── main.dart                # ทางเข้าหลักของแอพและระบบ State Provider
    ├── config\
    │   └── api_config.dart      # ตั้งค่า Base URL เชื่อมต่อไปยัง Backend
    ├── models\
    │   ├── user.dart            # โมเดลข้อมูลผู้ใช้งาน และสิทธิ์ (Admin / Member)
    │   ├── place.dart           # โมเดลสถานที่ท่องเที่ยว / ร้านอาหาร / ที่พัก
    │   └── notification_item.dart # โมเดลการแจ้งเตือน
    ├── services\
    │   └── api_service.dart     # Service ยิง REST API (Login, Register, Places, Favorites)
    ├── providers\
    │   ├── auth_provider.dart   # จัดการสถานะ Login / Logout และ JWT Token
    │   └── place_provider.dart  # จัดการรายการสถานที่ และรายการโปรด (Favorites)
    ├── screens\
    │   ├── main_navigation_screen.dart # เมนูนำทางล่าง 4 แท็บ (Home, Fav, Notify, Profile)
    │   ├── home_screen.dart     # หน้าแรก: ค้นหา + กรองหมวดหมู่ + รายการสถานที่
    │   ├── place_detail_screen.dart # หน้ารายละเอียดสถานที่ + แกลเลอรีรูปภาพ
    │   ├── favorites_screen.dart    # หน้ารายการโปรดของผู้ใช้
    │   ├── notifications_screen.dart # หน้ารายการแจ้งเตือน
    │   ├── login_screen.dart    # หน้าฟอร์มเข้าสู่ระบบ / สมัครสมาชิก
    │   └── profile_screen.dart  # หน้าโปรไฟล์ผู้ใช้ + สิทธิ์ Admin
    └── widgets\
        └── place_card.dart      # การ์ดแสดงผลสถานที่ท่องเที่ยวพร้อมปุ่มหัวใจ
```

---

## 🔌 การตั้งค่าเชื่อมต่อ Backend API (`lib/config/api_config.dart`)

* **ทดสอบผ่าน Android Emulator**: ระบบจะตั้งค่าให้อัตโนมัติเป็น `http://10.0.2.2:5088/api`
* **ทดสอบผ่าน Windows / iOS Simulator**: ใช้ `http://localhost:5088/api`
* **ทดสอบผ่านมือถือจริง (ผ่าน Wi-Fi)**:
  1. ดู IP คอมพิวเตอร์ของคุณ (เปิด CMD พิมพ์ `ipconfig`) เช่น `192.168.1.50`
  2. เปลี่ยนในไฟล์ `lib/config/api_config.dart` เป็น:
     ```dart
     static String get baseUrl => "http://192.168.1.50:5088/api";
     ```

---

## 🚀 วิธีเปิดและรันโปรเจกต์

1. เปิดโฟลเดอร์ `C:\KanApp` ใน **VS Code** หรือ **Android Studio**
2. ติดตั้ง Dependencies:
   ```bash
   flutter pub get
   ```
3. สั่งรันแอพ (เลือก Device เป็น Android Emulator, iOS Simulator หรือ Chrome):
   ```bash
   flutter run
   ```
