# Study Materials Management App (fromCashew2crudTaiLieuHocTap)
> **Ứng dụng Quản Lý Tài Liệu Học Tập & Hạn Nộp Bài Tập**  
> *Được thiết kế và triển khai áp dụng chuẩn mực các nguyên lý kiến trúc của ứng dụng Cashew Budget Tracker.*

---

## 1. Giới Thiệu & Mục Tiêu Kỹ Thuật

Dự án này là bài tập lớn / đồ án chuyên sâu về **Kiến trúc Phần mềm trên nền tảng Flutter**. Mục tiêu là thiết kế và triển khai một ứng dụng quản lý tài liệu học tập (bài giảng, bài tập, đề thi, tài liệu tham khảo), kế thừa các điểm mạnh công nghệ của ứng dụng **Cashew**:
* **Triết lý Local-First (Offline-First):** 100% dữ liệu lưu trữ trong cơ sở dữ liệu SQLite cục bộ, chạy mượt mà không cần mạng.
* **Tối ưu hóa hiệu năng bằng Isolate (`MultiExecutor`):** Tách biệt luồng đọc dữ liệu (Main Thread) và luồng ghi đĩa nặng (Background Isolate) để giao diện luôn đạt 60 - 120 FPS không giật lag.
* **Đường ống phản ứng tự động (Reactive UI Pipeline):** Sử dụng Drift `.watch()` kết hợp với Provider để giao diện tự động vẽ lại khi CSDL thay đổi.
* **Tái cấu trúc Mô-đun hóa (Modularization):** Khắc phục triệt để điểm yếu "God-file" 7.600 dòng của Cashew cũ bằng cách phân rã thành các bảng độc lập và các DAO (Data Access Object) chuyên trách.

---

## 2. Bảng Đối Sánh Kiến Trúc: Cashew Gốc vs. Dự Án Mới

| Tiêu chí | Cashew Gốc (Tài chính cá nhân) | Ứng dụng Tài Liệu Mới (Study Materials) |
| :--- | :--- | :--- |
| **Miền nghiệp vụ** | Quản lý ví, ngân sách, giao dịch thu chi | Quản lý môn học, phân loại và tài liệu học tập |
| **Thực thể tương đương 1** | `Wallets` (Ví tiền) | **`Subjects`** (Môn học: Mã môn, tên, giảng viên, tín chỉ, màu) |
| **Thực thể tương đương 2** | `Categories` (Danh mục) | **`DocTypes`** (Phân loại: Slide, Bài tập, Đề thi, Giáo trình) |
| **Thực thể tương đương 3** | `Transactions` (Giao dịch) | **`Documents`** (Tài liệu: Tiêu đề, file đính kèm, link web, deadline, status, pin) |
| **Thực thể tương đương 4** | `Budgets` (Ngân sách) | **`StudyGoals`** (Mục tiêu học tập theo tuần/tháng) |
| **Cấu trúc CSDL** | "God-file" `tables.dart` dài >7.600 dòng | **Mô-đun hóa sạch sẽ**: Mỗi Table và DAO là 1 file riêng dưới 100 dòng |
| **Mô hình tổ chức Code** | Gom chung toàn bộ Page vào `lib/pages/` | **Feature-First**: `features/subjects/`, `features/documents/`, `features/deadlines/`, `features/settings/` |
| **Cơ chế I/O Đa luồng** | `MultiExecutor` (Isolate) | Giữ nguyên nguyên lý `MultiExecutor` của Cashew |
| **Độ phủ kiểm thử** | Thiếu kiểm thử đơn vị độc lập | Có bộ Unit Test tự động kiểm tra CSDL và Reactive Stream |

---

## 3. Cấu Trúc Thư Mục Chuẩn Mô-Đun (Feature-First)

```
lib/
├── database/
│   ├── connection/
│   │   ├── native.dart        # MultiExecutor (Foreground read + Background Isolate write)
│   │   ├── shared.dart        # Conditional export đa nền tảng
│   │   ├── web.dart           # Hỗ trợ WebAssembly WasmDatabase
│   │   └── unsupported.dart
│   ├── daos/
│   │   ├── subjects_dao.dart   # SubjectsDao: CRUD & thống kê tiến độ môn học
│   │   ├── documents_dao.dart  # DocumentsDao: Lọc, tìm kiếm, toggle status, deadlines
│   │   ├── doc_types_dao.dart  # DocTypesDao: Quản lý danh mục loại tài liệu
│   │   └── study_goals_dao.dart# StudyGoalsDao: Quản lý mục tiêu học tập
│   ├── tables/
│   │   ├── subjects_table.dart
│   │   ├── documents_table.dart
│   │   ├── doc_types_table.dart
│   │   ├── study_goals_table.dart
│   │   ├── delete_logs_table.dart  # Tombstone phục vụ sao lưu/khôi phục
│   │   └── app_settings_table.dart
│   ├── default_data.dart       # Nạp dữ liệu môn học & tài liệu mẫu khởi đầu
│   ├── study_database.dart     # Class chính @DriftDatabase
│   └── study_database.g.dart   # Code sinh tự động bởi build_runner
├── features/
│   ├── subjects/
│   │   ├── subjects_page.dart          # Màn hình danh sách môn học & tiến độ
│   │   └── add_edit_subject_page.dart  # Form thêm/sửa môn học kèm chọn màu
│   ├── documents/
│   │   ├── documents_page.dart         # Kho tài liệu (Tìm kiếm + Bộ lọc môn + Loại)
│   │   ├── add_edit_document_page.dart # Form thêm/sửa tài liệu (đính kèm file, link, deadline)
│   │   └── document_details_page.dart  # Chi tiết tài liệu, mở file/link, đổi trạng thái
│   ├── deadlines/
│   │   └── deadlines_page.dart         # Lịch nộp gom nhóm: Quá hạn, Hôm nay, Tuần này
│   └── settings/
│       └── settings_page.dart          # Thống kê tổng quan, Xuất file CSDL (.sqlite)
├── navigation/
│   └── main_navigation_framework.dart  # Shell điều hướng 4 tab dùng IndexedStack
└── main.dart                           # Điểm khởi động ứng dụng
```

---

## 4. Hướng Dẫn Chạy & Kiểm Thử Ứng Dụng

### 4.1. Chạy Ứng Dụng (Run App)
Mở terminal tại thư mục này và gõ:
```bash
# Lấy các gói phụ thuộc
flutter pub get

# Chạy trên thiết bị kết nối (Windows, Chrome, hoặc Android Emulator)
flutter run
```

### 4.2. Chạy Kiểm Thử Đơn Vị (Run Unit Tests)
Bộ kiểm thử tự động đã được cấu hình sẵn với CSDL in-memory:
```bash
flutter test test/study_database_test.dart
```
**Kết quả kiểm thử:**
* `1. Thêm và truy vấn môn học (SubjectsDao)`: **Passed**
* `2. Thêm loại tài liệu và kiểm tra (DocTypesDao)`: **Passed**
* `3. Thêm tài liệu và kiểm tra luồng phản ứng (DocumentsDao Reactive Stream)`: **Passed**
* `4. Kiểm tra tính toán thống kê tiến độ học tập (SubjectsDao watchSubjectsWithStats)`: **Passed**

### 4.3. Kiểm Tra Chất Lượng Mã Nguồn (Linter)
```bash
flutter analyze
```
$\rightarrow$ Kết quả: **`No issues found!`** (0 lỗi, 0 cảnh báo).

---

## 5. Các Tính Năng Nổi Bật

1. **Quản lý Môn học:**
   - Tạo môn học kèm Mã môn (INT3120), Tên môn, Giảng viên, Số tín chỉ và Mã màu nhận diện.
   - Hiển thị thanh tiến độ (% hoàn thành bài tập/tài liệu của từng môn).
2. **Kho Tài Liệu Thông Minh:**
   - Tìm kiếm tức thì theo từ khóa trong tiêu đề và ghi chú.
   - Lọc nhanh theo Môn học (Chips) và Loại tài liệu (Slide, Bài tập, Đề thi, Giáo trình).
   - Ghim tài liệu quan trọng lên đầu danh sách.
   - Thao tác 1 chạm để chuyển trạng thái: *Cần đọc $\rightarrow$ Đang làm $\rightarrow$ Hoàn thành*.
3. **Quản lý Hạn Nộp (Deadlines):**
   - Tự động gom nhóm bài tập: *Quá hạn (Đỏ), Hôm nay (Vàng), Tuần này (Xanh dương), Đã xong (Xanh lá)*.
   - Tích chọn hoàn thành nhanh chóng.
4. **Hỗ Trợ Tệp Đính Kèm & Liên Kết Trực Tuyến:**
   - Đính kèm tệp PDF, Word từ máy tính/điện thoại qua `file_picker`.
   - Lưu liên kết Google Drive, Youtube bài giảng và mở bằng 1 chạm qua `url_launcher`.
5. **Sao Lưu & Phục Hồi Dữ Liệu Cục Bộ:**
   - Xuất nguyên khối file CSDL `study_materials.sqlite` để sao lưu hoặc chuyển đổi sang máy khác.
