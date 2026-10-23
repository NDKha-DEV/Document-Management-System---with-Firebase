# Checklist kiểm thử cuối cùng --- Document Management System

> **Trạng thái:** Đã tự kiểm tra --- hoàn thành checklist\
> **Ngày xác nhận:** 23/10/2026\
> **Phạm vi:** Các chức năng đã triển khai trong dự án hiện tại. Các mục
> được đánh dấu hoàn thành theo xác nhận của người kiểm thử; giới hạn
> kiểm thử được ghi riêng bên dưới.

## 1. Kiểm tra tổng thể

-   [x] Đã rà soát các chức năng thuộc phạm vi công việc.
-   [x] Các chức năng trong phạm vi đã được tự kiểm tra.
-   [x] Không còn mục nào trong checklist áp dụng đang chờ xử lý.
-   [x] Không tự ý thay đổi schema, RLS hoặc dữ liệu Cloud ngoài phạm vi
    được duyệt.
-   [x] Không tạo commit/push nếu chưa có yêu cầu.

## 2. Tài liệu Local và Cloud

-   [x] Các màn hình và thao tác Local hoạt động theo phạm vi đã kiểm
    tra.
-   [x] Các màn hình và thao tác Cloud hoạt động theo phạm vi đã kiểm
    tra.
-   [x] Xử lý dữ liệu tùy chọn hoặc để trống không gây lỗi trong các
    trường hợp đã kiểm tra.
-   [x] Thay đổi ở Local không làm ảnh hưởng nhầm đến Cloud và ngược
    lại.

## 3. Tags và vị trí tài liệu

-   [x] Có thể nhập và chỉnh sửa tags.
-   [x] Tags được xử lý theo định dạng đã triển khai; trường rỗng được
    xử lý phù hợp.
-   [x] Có thể nhập/chỉnh sửa tên vị trí và tọa độ theo các trường hợp
    đã kiểm tra.
-   [x] Các trường vị trí tùy chọn để trống được xử lý phù hợp.

## 4. Yêu cầu mượn tài liệu Cloud

-   [x] Người dùng không sở hữu tài liệu có thể gửi yêu cầu mượn theo
    luồng đã kiểm tra.
-   [x] Người gửi xem được trạng thái yêu cầu của mình.
-   [x] Chủ sở hữu xem được các yêu cầu liên quan đến tài liệu của mình.
-   [x] Chủ sở hữu có thể chấp nhận hoặc từ chối yêu cầu đang chờ.
-   [x] Luồng xử lý yêu cầu trùng lặp đã được kiểm tra.
-   [x] Trạng thái tải, làm mới, lỗi và xác nhận thao tác đã được kiểm
    tra trong phạm vi phù hợp.

## 5. Gợi ý tài liệu theo tags

-   [x] Gợi ý được lấy riêng theo nguồn Local hoặc Cloud tương ứng.
-   [x] Tài liệu hiện tại không xuất hiện trong danh sách gợi ý của
    chính nó.
-   [x] Việc so khớp tags không phân biệt chữ hoa/chữ thường theo cách
    triển khai.
-   [x] Trạng thái không có kết quả được hiển thị phù hợp.
-   [x] Chọn tài liệu gợi ý sẽ mở trang chi tiết tương ứng.

## 6. Bộ lọc tài liệu Cloud

-   [x] Bộ lọc chủ đề và loại tài liệu hiển thị trong tab Cloud của tôi.
-   [x] Có thể chọn/bỏ chọn giá trị lọc.
-   [x] Có thể kết hợp hai bộ lọc.
-   [x] Dữ liệu thiếu hoặc trường chủ đề/loại trống được xử lý an toàn.
-   [x] Tìm kiếm và làm mới hoạt động cùng bộ lọc theo thiết kế đã kiểm
    tra.
-   [x] Bộ lọc không làm thay đổi tab Local hoặc các màn hình ngoài phạm
    vi.

## 7. Giao diện và bố cục

-   [x] Các trường tọa độ có bố cục phù hợp trên màn hình hẹp đã kiểm
    tra.
-   [x] Các nút xử lý yêu cầu mượn có bố cục phù hợp trên màn hình hẹp
    đã kiểm tra.
-   [x] Các bộ lọc Cloud có thể sử dụng trên chiều rộng màn hình nhỏ đã
    kiểm tra.
-   [x] Không phát hiện lỗi giao diện nghiêm trọng trong các màn hình đã
    kiểm tra.

## 8. Kiểm tra kỹ thuật

-   [x] `dart format` hoàn thành.
-   [x] `flutter analyze --no-pub` hoàn thành không có lỗi phân tích cần
    xử lý.
-   [x] `git diff --check` hoàn thành.
-   [x] Đã chạy
    `flutter test --no-pub test\permissions_test.dart test\study_database_test.dart`.
-   [x] Kết quả các bài test đã chạy: 11 tests passed.
-   [x] `flutter build web --release` hoàn thành thành công.

## 9. Giới hạn kiểm thử đã ghi nhận

-   [x] Đã ghi nhận build APK Android chưa xác minh được do môi trường
    chưa có Android SDK.
-   [x] Không coi build Web thành công là bằng chứng rằng toàn bộ luồng
    Android đã được kiểm thử.
-   [x] Không coi phân tích tĩnh hoặc unit test là bằng chứng thay thế
    cho kiểm thử tích hợp Supabase thực tế.
-   [x] Các luồng cần tài khoản/dữ liệu Supabase thật chỉ được xem là đã
    kiểm thử nếu người kiểm thử thực sự chạy và xác nhận trên môi trường
    đó.

## 10. Xác nhận hoàn tất

-   [x] Người kiểm thử xác nhận đã tự kiểm tra và hoàn thành các
    checklist áp dụng cho phạm vi công việc.
-   [x] Không còn mục nào trong phạm vi kiểm thử đã thống nhất đang chờ
    xử lý.
-   [x] Sẵn sàng kết thúc đợt kiểm thử hiện tại; lỗi phát hiện sau thời
    điểm xác nhận sẽ được ghi nhận riêng.

**Kết luận:** Checklist cuối cùng được xác nhận hoàn thành theo phạm vi
đã kiểm tra. Các giới hạn môi trường và loại kiểm thử chưa thực sự thực
hiện vẫn được ghi rõ, không được hiểu là đã vượt qua.
