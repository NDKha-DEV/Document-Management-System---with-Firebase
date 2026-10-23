-- =====================================================================
-- SUPABASE STORAGE — LƯU TỆP TÀI LIỆU + RLS TRÊN storage.objects
--
-- Chạy SAU 01_setup_schema_rls.sql, trong SQL Editor (RUN cả file).
-- Nếu SQL Editor cảnh báo "destructive operations" → chọn Run (chỉ xóa/tạo lại policy).
--
-- Cấu trúc đường dẫn (bucket private "documents"):
--     users/{firebase_uid}/documents/{document_id}/{yyyyMMddHHmmss}_{ten_file}
--      [1]      [2]          [3]          [4]
-- Liên kết với bảng public.documents qua cột file_path (+ file_name, file_size,
-- storage_provider = 'supabase_storage').
--
-- Quyền:
--   * Tải lên / xóa: chỉ chủ thư mục (users/{uid} trùng Firebase UID trong token).
--   * Đọc (tạo signed URL để tải về): chủ thư mục, HOẶC bất kỳ ai có quyền xem
--     tài liệu {document_id} theo public.document_role() — tức quyền đọc tệp đi
--     theo đúng quyền chia sẻ tài liệu; thu hồi chia sẻ là mất quyền tải tệp.
-- =====================================================================

-- 1. Bucket private, giới hạn 25 MB / tệp
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('documents', 'documents', false, 26214400)
ON CONFLICT (id) DO UPDATE
   SET public = false,
       file_size_limit = EXCLUDED.file_size_limit;

-- 2. Policy trên storage.objects (token Firebase chạy dưới role anon, xem ghi chú trong file 01)
DROP POLICY IF EXISTS documents_files_select ON storage.objects;
DROP POLICY IF EXISTS documents_files_insert ON storage.objects;
DROP POLICY IF EXISTS documents_files_update ON storage.objects;
DROP POLICY IF EXISTS documents_files_delete ON storage.objects;

CREATE POLICY documents_files_select ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (
    bucket_id = 'documents'
    AND public.firebase_uid() IS NOT NULL
    AND (storage.foldername(name))[1] = 'users'
    AND (storage.foldername(name))[3] = 'documents'
    AND (
      (storage.foldername(name))[2] = public.firebase_uid()
      OR public.document_role((storage.foldername(name))[4]) IS NOT NULL
    )
  );

CREATE POLICY documents_files_insert ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND public.firebase_uid() IS NOT NULL
    AND (storage.foldername(name))[1] = 'users'
    AND (storage.foldername(name))[2] = public.firebase_uid()
    AND (storage.foldername(name))[3] = 'documents'
  );

CREATE POLICY documents_files_update ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[2] = public.firebase_uid()
  )
  WITH CHECK (
    bucket_id = 'documents'
    AND (storage.foldername(name))[2] = public.firebase_uid()
  );

CREATE POLICY documents_files_delete ON storage.objects
  FOR DELETE TO anon, authenticated
  USING (
    bucket_id = 'documents'
    AND public.firebase_uid() IS NOT NULL
    AND (storage.foldername(name))[2] = public.firebase_uid()
  );

-- 3. Mặc định nhà cung cấp lưu trữ cho tài liệu mới
ALTER TABLE public.documents ALTER COLUMN storage_provider SET DEFAULT 'supabase_storage';

-- 4. Kiểm tra
SELECT id AS bucket, public, file_size_limit,
       (SELECT count(*) FROM pg_policies
         WHERE schemaname = 'storage' AND tablename = 'objects'
           AND policyname LIKE 'documents_files_%') AS storage_policies
  FROM storage.buckets
 WHERE id = 'documents';
