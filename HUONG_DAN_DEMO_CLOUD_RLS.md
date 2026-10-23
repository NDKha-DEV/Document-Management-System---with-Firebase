# HƯỚNG DẪN SETUP & KỊCH BẢN QUAY DEMO — FIREBASE + SUPABASE + RLS

Kiến trúc: **Firebase Auth (Google)** ↔ **Supabase** (Postgres: metadata, tìm kiếm, chia sẻ, RLS + **Storage**: tệp đính kèm).
Ghi chú: ban đầu thiết kế lưu tệp trên Firebase Storage, nhưng project Firebase mới bắt buộc gói Blaze (có thẻ thanh toán) mới bật được Storage, nên tệp được chuyển sang **Supabase Storage** (gói Free) — vẫn giữ nguyên cấu trúc thư mục và còn được hưởng RLS theo quyền chia sẻ.
Supabase xác minh Firebase ID token (Third-Party Auth) → RLS dùng Firebase UID (`sub`) và email trong token.

| # | Yêu cầu | Nằm ở đâu trong mã nguồn |
|---|---|---|
| 1 | Firebase + đăng nhập Google | `lib/core/services/auth_service.dart`, `lib/core/widgets/account_button.dart` |
| 2 | Cấu trúc lưu file trên Storage ↔ bảng documents | `lib/core/services/cloud_storage_service.dart` (bucket `documents`, đường dẫn `users/{uid}/documents/{docId}/{timestamp}_{file}`), `supabase/03_setup_storage.sql`, cột `file_path / file_name / file_size / storage_provider` |
| 3 | 3 bảng Người dùng / Tài liệu / Quyền chia sẻ | `supabase/01_setup_schema_rls.sql` (`profiles`, `documents`, `document_permissions`) |
| 4 | Tìm kiếm, cập nhật, chia sẻ | `lib/core/services/supabase_service.dart`, `lib/features/documents/cloud_*.dart`, `share_document_sheet.dart` |
| 5 | RLS | `supabase/01_setup_schema_rls.sql` (mục 5–7) |
| 6 | Kiểm thử ≥ 3 tài khoản | `supabase/02_test_rls_3_users.sql` (25 ca), nút **"Kiểm thử quyền trên server"** trong app, `test/permissions_test.dart` |

---

## A. SETUP MỘT LẦN (khoảng 10 phút)

### A1. Supabase — tin tưởng token Firebase
Supabase Dashboard → **Authentication** → **Sign In / Providers** → **Third-Party Auth** → **Add provider** → **Firebase** → Project ID: `study-materials-app-8fcf8` → Save.

### A2. Supabase — tạo bảng + RLS
SQL Editor → New query → dán toàn bộ `supabase/01_setup_schema_rls.sql` → **Run**.
Kết quả cuối: 3 bảng `rls_enabled = true` (profiles 3 policy, documents 4, document_permissions 4).
Script chạy lại nhiều lần không mất dữ liệu.

### A3. Supabase — chạy kiểm thử RLS 3 tài khoản
New query → dán `supabase/02_test_rls_3_users.sql` → **Run** → bảng 25 dòng, tất cả **✅ PASS**.
(Script tự dọn dữ liệu test.)

### A4. Supabase Storage — tạo bucket + RLS cho tệp
New query → dán `supabase/03_setup_storage.sql` → **Run** (nếu có cảnh báo, chọn Run).
Kết quả: bucket `documents`, `public = false`, `storage_policies = 4`. Kiểm tra ở menu **Storage** thấy bucket `documents`.

### A5. Chạy ứng dụng
```powershell
flutter build web --release --no-tree-shake-icons
python -m http.server 5000 --directory build/web
```
Mở `http://localhost:5000` (phải dùng **localhost** — domain đã được Firebase cho phép).
Hoặc chạy nhanh: `flutter run -d chrome --web-port 5000`.

### A6. Kiểm tra nhanh
Tab **Cài Đặt** → đăng nhập Google → **Kiểm tra kết nối Supabase + Firebase Auth**.
Phải thấy dòng xanh: *"Supabase đã xác minh token Firebase: uid = …"*. Nếu đỏ → xem lại A1/A2.

---

## B. CHUẨN BỊ 3 TÀI KHOẢN

Mỗi tài khoản cần một cửa sổ trình duyệt riêng (phiên đăng nhập Firebase lưu theo profile trình duyệt):

| Vai | Cửa sổ | Ví dụ |
|---|---|---|
| **A — Chủ sở hữu** | Chrome thường | tài khoản Google chính |
| **B — Editor** | Chrome **Ẩn danh** (Ctrl+Shift+N) | tài khoản Google thứ 2 |
| **C — Viewer → Admin** | **Edge** hoặc Chrome profile khác | tài khoản Google thứ 3 |

Xếp 3 cửa sổ cạnh nhau (Win + ←/→) để quay một lần thấy cả 3.
Trước khi quay: đăng nhập B và C vào app **một lần** để hồ sơ của họ có trong bảng `profiles`.

---

## C. KỊCH BẢN QUAY (≈ 8–10 phút)

**1. Kiến trúc & CSDL (1 phút)** — Mở Supabase Table Editor: 3 bảng có biểu tượng khóa **RLS enabled**. Mở `01_setup_schema_rls.sql`, lướt qua hàm `firebase_uid()`, `document_role()` và các policy.

**2. Đăng nhập Google (30 giây)** — Cửa sổ A: tab Cài Đặt → *Đăng nhập bằng tài khoản Google* → chọn tài khoản → bấm *Kiểm tra kết nối* → thấy uid Firebase được Supabase xác minh.

**3. Tạo tài liệu + tải tệp lên Storage (1 phút)** — A: Tài Liệu → *Thêm Tài Liệu* → tiêu đề "Đề cương INT3120", đính kèm 1 file PDF, bật *Tự động tải tệp lên Supabase Storage* → Lưu.
Tab **Cloud của tôi** → mở tài liệu: thấy tên tệp, dung lượng, đường dẫn `users/{uid}/documents/doc-…/…pdf`; bấm vào để mở (signed URL).
Mở Supabase → **Storage → documents** để chỉ đúng thư mục `users/{uid}/documents/{docId}/`; mở **Table Editor → documents** để chỉ cột `file_path`, `file_name`, `file_size`, `storage_provider`.

**4. Chia sẻ (1 phút)** — A: nút Chia sẻ → email B quyền **Chỉnh sửa**, email C quyền **Chỉ xem**. Supabase → bảng `document_permissions` có 2 dòng.

**5. Kiểm chứng quyền với 3 tài khoản (3 phút)**
- **B (editor)**: tab **Được chia sẻ** → thấy tài liệu, badge *Chỉnh sửa*. Mở → có nút **Sửa** nhưng **không có** Chia sẻ/Xóa. Sửa ghi chú → *Lưu lên Supabase* → thành công.
- **A**: bấm nút làm mới ⟳ ở tab Cloud của tôi → thấy nội dung B vừa sửa ("Cập nhật lần cuối … bởi cộng tác viên").
- **C (viewer)**: thấy tài liệu, badge *Chỉ xem*, không có nút Sửa. Bấm tệp → mở được file (Storage cấp signed URL vì C có quyền xem tài liệu).
- **C**: cuộn xuống **Kiểm thử quyền trên server (RLS)** → *Chạy kiểm thử* → Xem ✅, Tải tệp ✅, Sửa ⛔, Chia sẻ ⛔, Xóa ⛔ — server chặn thật, không chỉ ẩn nút.
- **B** chạy kiểm thử → Xem ✅, Sửa ✅, Chia sẻ ⛔, Xóa ⛔.
- **A** chạy kiểm thử → tất cả ✅.
- (Tuỳ chọn) A tạo thêm tài liệu riêng không chia sẻ → B, C không thấy ở bất kỳ tab nào.

**6. Admin chia sẻ tiếp (1 phút)** — A nâng C lên **Toàn quyền** (chia sẻ lại cùng email). C: mở lại tài liệu → có nút Chia sẻ; danh sách quyền chỉ có *Chỉ xem / Chỉnh sửa* (admin không cấp được admin); vẫn **không có** nút Xóa.

**7. Tìm kiếm (30 giây)** — Ở bất kỳ cửa sổ nào: kính lúp → gõ "INT3120" hoặc 1 từ trong ghi chú → tab Cloud / Được chia sẻ lọc ngay trên Supabase (tiêu đề, ghi chú, mã môn, tên file) — kết quả vẫn chỉ gồm những tài liệu RLS cho phép.

**8. Thu hồi & xóa (1 phút)** — A thu hồi quyền của B → B bấm ⟳ → tài liệu biến mất (và B cũng mất quyền tải tệp, vì RLS của Storage dựa trên quyền chia sẻ). A xóa tài liệu → quyền chia sẻ bị xóa theo (CASCADE) và tệp trên Storage bị xóa.

**9. Kiểm thử tự động (1 phút)** — Supabase SQL Editor chạy `02_test_rls_3_users.sql` → 25/25 ✅ PASS. Terminal: `flutter test` → *All tests passed!*.

---

## D. XỬ LÝ SỰ CỐ

| Hiện tượng | Nguyên nhân / cách sửa |
|---|---|
| "Supabase từ chối token Firebase" | Chưa làm bước A1 (Third-Party Auth → Firebase). |
| "Thiếu bảng/hàm trên Supabase" | Chưa chạy `01_setup_schema_rls.sql`. |
| Đăng nhập nhưng tab Cloud trống, chẩn đoán báo uid null | Token chưa được Supabase xác minh → kiểm tra Project ID ở A1 đúng `study-materials-app-8fcf8`. |
| "tải tệp lên Supabase Storage thất bại" / "Bucket not found" | Chưa chạy `03_setup_storage.sql` (A4). Tài liệu vẫn được lưu, chỉ thiếu tệp. |
| Popup Google bị chặn / `auth/unauthorized-domain` | Dùng `http://localhost:5000`, không dùng `127.0.0.1`. |
| Người được chia sẻ không thấy tài liệu | Phải nhập đúng email Google của họ; bấm ⟳ để làm mới tab. |

**Ghi chú bảo mật:** Firebase token không có claim `role`, nên Supabase chạy truy vấn dưới role `anon`. Mọi policy vì thế kiểm tra token Firebase đã được xác minh (`iss`/`aud` đúng project + `sub`), không dựa vào role; request chỉ có publishable key không có `sub` nên không đọc/ghi được gì (ca kiểm thử số 8–9).
