# HƯỚNG DẪN TỪNG BƯỚC SETUP FIREBASE & GOOGLE CLOUD
## DÀNH CHO BẠN (NGƯỜI DÙNG THỰC HIỆN)
> **Mục tiêu:** Hướng dẫn bạn tự tay thực hiện các bước cấu hình trên Firebase Console, kích hoạt dịch vụ Google Sign-In, Cloud Storage và Firestore.  
> **Toàn bộ Source code đã được hoàn thiện 100%:** Mã nguồn Flutter đã tích hợp sẵn `AuthService`, `CloudStorageService`, `CloudSyncService` và giao diện đăng nhập/tải tệp.

---

## BƯỚC 1: TẠO FIREBASE PROJECT TRÊN TRÌNH DUYỆT

1. Mở trình duyệt web và truy cập vào: [https://console.firebase.google.com](https://console.firebase.google.com)
2. Đăng nhập bằng tài khoản Google cá nhân của bạn (tài khoản Gmail sinh viên hoặc cá nhân).
3. Bấm vào nút **"Add project"** (Thêm dự án) hoặc **"Create a project"**.
4. Nhập tên dự án, ví dụ: `study-materials-app` (hoặc tên tùy thích).
5. Bấm **Continue** $\rightarrow$ Ở bước Google Analytics, bạn có thể **Tắt (Disable)** để thiết lập nhanh hơn $\rightarrow$ Bấm **Create project**.
6. Đợi 10–15 giây cho Firebase khởi tạo xong $\rightarrow$ Bấm **Continue** để vào màn hình quản trị dự án.

---

## BƯỚC 2: BẬT XÁC THỰC GOOGLE (AUTHENTICATION)

1. Ở menu thanh bên trái của Firebase Console, chọn **Build** $\rightarrow$ chọn **Authentication**.
2. Bấm vào nút **Get started** (Bắt đầu).
3. Tại thẻ **Sign-in method**, bấm chọn nhà cung cấp **Google**:
   - Gạt công tắc sang **Enable** (Bật).
   - Đặt tên hỗ trợ dự án (Project public-facing name): `Study Materials App`.
   - Chọn email hỗ trợ dự án (Support email): Chọn email Google của bạn.
4. Bấm **Save** (Lưu).

---

## BƯỚC 3: BẬT DỊCH VỤ CLOUD STORAGE (LƯU TRỮ TỆP TIN)

1. Ở menu thanh bên trái, chọn **Build** $\rightarrow$ chọn **Storage**.
2. Bấm vào nút **Get started** (Bắt đầu).
3. Ở bước chọn chế độ bảo mật:
   - Chọn **Start in test mode** (để dễ dàng kiểm thử ban đầu mà không bị chặn quyền) $\rightarrow$ Bấm **Next**.
4. Ở bước chọn vị trí lưu trữ (Cloud Storage location):
   - Chọn khu vực gần Việt Nam nhất: **`asia-southeast1`** (Singapore) hoặc **`asia-east1`** (Tokyo) $\rightarrow$ Bấm **Done**.
5. Đợi Firebase cấp phát Storage Bucket xong, bấm chuyển sang tab **Rules** và dán đoạn luật bảo mật sau:
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /users/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       // Hoặc cho phép đọc/ghi chế độ test trong 30 ngày:
       match /{allPaths=**} {
         allow read, write: if true;
       }
     }
   }
   ```
6. Bấm nút **Publish** để áp dụng.

---

## BƯỚC 4: BẬT CƠ SỞ DỮ LIỆU CLOUD FIRESTORE (ĐỒNG BỘ DỮ LIỆU)

1. Ở menu bên trái, chọn **Build** $\rightarrow$ chọn **Firestore Database**.
2. Bấm **Create database**.
3. Chọn vị trí: **`asia-southeast1`** $\rightarrow$ Bấm **Next**.
4. Chọn **Start in test mode** $\rightarrow$ Bấm **Enable**.
5. Chuyển sang tab **Rules** và dán đoạn cấu hình:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       // Cho phép test:
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
6. Bấm nút **Publish**.

---

## BƯỚC 5: LIÊN KẾT FIREBASE VỚI MÃ NGUỒN QUA TERMINAL

Mở cửa sổ Terminal (PowerShell hoặc CMD) tại máy tính của bạn và chạy 2 lệnh sau:

### Lệnh 5.1: Đăng nhập Firebase CLI trên máy
```bash
firebase login
```
*Trình duyệt sẽ tự động bật lên, bạn bấm chọn tài khoản Google của mình và bấm **Cho phép (Allow)**.*

### Lệnh 5.2: Tự động cấu hình FlutterFire
Di chuyển vào thư mục dự án và chạy:
```bash
cd "C:\Users\Nguyen Tung Duong\Desktop\MobileApp\fromCashew2crudTaiLieuHocTap"
flutterfire configure
```
* **Cách chọn trong terminal:**
  1. CLI sẽ hiển thị danh sách các dự án trên tài khoản của bạn $\rightarrow$ Dùng phím mũi tên chọn dự án bạn vừa tạo ở Bước 1 (ví dụ `study-materials-app`) $\rightarrow$ Nhấn **Enter**.
  2. Chọn các nền tảng: Nhấn phím cách (Space) để chọn **`android`**, **`ios`**, **`web`** $\rightarrow$ Nhấn **Enter**.
  3. Quá trình này sẽ tự động đăng ký App ID và ghi đè file `lib/firebase_options.dart` chính xác cho dự án của bạn!

---

## BƯỚC 6: CHẠY ỨNG DỤNG VÀ TRẢI NGHIỆM

Sau khi chạy xong lệnh ở Bước 5, bạn khởi chạy ứng dụng:
```bash
flutter run -d chrome
```
*(Hoặc chạy trên điện thoại Android / máy tính Windows)*

### Kiểm tra các tính năng trên màn hình:
1. **Kiểm tra Đăng nhập:**
   - Vào tab **Cài Đặt** (Settings).
   - Tại thẻ **"Đồng Bộ Đám Mây (Firebase)"**, bấm nút **"Đăng nhập bằng tài khoản Google"**.
   - Hộp thoại chọn tài khoản Google sẽ bật lên $\rightarrow$ Chọn tài khoản của bạn.
   - Khi đăng nhập thành công, giao diện sẽ hiển thị ngay **Ảnh đại diện (Avatar), Tên và Email** của bạn kèm dấu tích xanh xác thực.
2. **Kiểm tra Tải tệp lên Cloud Storage:**
   - Sang tab **Tài Liệu** $\rightarrow$ Bấm nút **(+)** để tạo tài liệu mới.
   - Nhập tiêu đề, chọn môn học.
   - Bấm nút **"Đính kèm tệp từ máy (PDF, Docx...)"** và chọn 1 file PDF hoặc ảnh bài giảng.
   - Bạn sẽ thấy công tắc **"Tự động tải tệp lên Firebase Cloud Storage"** được bật.
   - Bấm **LƯU TÀI LIỆU** $\rightarrow$ Ứng dụng sẽ tự động tải file lên Firebase Storage và lưu URL đám mây.
   - Bấm vào tài liệu vừa tạo xem chi tiết $\rightarrow$ Thẻ **"Tệp Đám Mây (Firebase Cloud Storage)"** màu tím sẽ xuất hiện, bấm vào để mở xem tệp trực tiếp!
3. **Kiểm tra Đồng bộ Metadata:**
   - Vào lại tab **Cài Đặt** $\rightarrow$ Bấm nút **"Đồng Bộ Ngay"**.
   - Ứng dụng sẽ tự động đẩy toàn bộ môn học và tài liệu từ SQLite lên Cloud Firestore.
   - Bạn có thể mở tab **Firestore Database** trên trình duyệt để thấy dữ liệu đã được lưu trữ an toàn trên đám mây!
