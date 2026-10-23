import 'package:flutter_test/flutter_test.dart';
import 'package:budget/core/models/cloud_document.dart';
import 'package:budget/core/services/cloud_storage_service.dart';

/// Kiểm thử logic phân quyền phía client với 3 tài khoản:
///   A = chủ sở hữu, B = editor, C = viewer (chia sẻ theo email, chưa có uid).
/// Logic này phản chiếu hàm public.document_role() trên Supabase; kiểm thử
/// RLS thật trên server nằm ở supabase/02_test_rls_3_users.sql.
void main() {
  const uidA = 'uid-a', uidB = 'uid-b', uidC = 'uid-c', uidD = 'uid-d';

  CloudDocument sharedDoc({bool isPublic = false}) => CloudDocument.fromMap({
        'id': 'doc-1',
        'owner_id': uidA,
        'title': 'Đề cương INT3120',
        'is_public': isPublic,
        'profiles': {'display_name': 'A', 'email': 'a@gmail.com'},
        'permissions': [
          {
            'shared_with_email': 'b@gmail.com',
            'shared_with_user_id': uidB,
            'permission_level': 'editor',
          },
          {
            'shared_with_email': 'c@gmail.com',
            'shared_with_user_id': null,
            'permission_level': 'viewer',
          },
        ],
      });

  group('Vai trò của 3 tài khoản trên cùng một tài liệu', () {
    test('A là chủ sở hữu: xem, sửa, chia sẻ, xóa', () {
      final role = sharedDoc().roleFor(uid: uidA, email: 'a@gmail.com');
      expect(role, DocumentRole.owner);
      expect(role.canEdit && role.canShare && role.canDelete, isTrue);
      expect(role.canGrantAdmin, isTrue);
    });

    test('B là editor: xem + sửa, không chia sẻ, không xóa', () {
      final role = sharedDoc().roleFor(uid: uidB, email: 'b@gmail.com');
      expect(role, DocumentRole.editor);
      expect(role.canView, isTrue);
      expect(role.canEdit, isTrue);
      expect(role.canShare, isFalse);
      expect(role.canDelete, isFalse);
    });

    test('C là viewer (nhận diện qua email, không phân biệt hoa thường)', () {
      final role = sharedDoc().roleFor(uid: uidC, email: 'C@Gmail.com');
      expect(role, DocumentRole.viewer);
      expect(role.canView, isTrue);
      expect(role.canEdit, isFalse);
      expect(role.canShare, isFalse);
      expect(role.canDelete, isFalse);
    });

    test('Người ngoài không có quyền', () {
      final role = sharedDoc().roleFor(uid: uidD, email: 'd@gmail.com');
      expect(role, DocumentRole.none);
      expect(role.canView, isFalse);
    });

    test('Tài liệu công khai: người ngoài chỉ được xem', () {
      final role =
          sharedDoc(isPublic: true).roleFor(uid: uidD, email: 'd@gmail.com');
      expect(role, DocumentRole.public);
      expect(role.canView, isTrue);
      expect(role.canEdit, isFalse);
    });

    test('Admin được chia sẻ tiếp nhưng không cấp quyền admin và không xóa', () {
      final role = DocumentRoleX.fromLevel('admin');
      expect(role.canShare, isTrue);
      expect(role.canGrantAdmin, isFalse);
      expect(role.canDelete, isFalse);
    });
  });

  test('Đường dẫn Firebase Storage theo cấu trúc users/{uid}/documents/{docId}/', () {
    final path = CloudStorageService.buildStoragePath(
      uid: uidA,
      documentId: 'doc-1',
      fileName: 'De cuong (on tap).pdf',
      at: DateTime.utc(2026, 10, 15, 9, 5, 7),
    );
    expect(path, 'users/uid-a/documents/doc-1/20261015090507_De_cuong__on_tap_.pdf');

    final unicode = CloudStorageService.buildStoragePath(
        uid: uidA, documentId: 'doc-1', fileName: 'Đề cương ôn tập.pdf');
    expect(RegExp(r'^[a-zA-Z0-9._/-]+$').hasMatch(unicode), isTrue,
        reason: 'Tên file chỉ còn ký tự an toàn cho Storage');
  });
}
