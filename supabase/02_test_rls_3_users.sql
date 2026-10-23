-- =====================================================================
-- KIỂM THỬ RLS VỚI 3 TÀI KHOẢN NGƯỜI DÙNG (giả lập token Firebase)
--
-- Chạy SAU file 01_setup_schema_rls.sql, trong Supabase SQL Editor (RUN cả file).
-- Script tạo dữ liệu test riêng (id bắt đầu bằng 'rlstest-'), đóng vai từng
-- người dùng bằng cách đặt request.jwt.claims + role anon (giống hệt request
-- thật từ app gửi Firebase ID token), ghi lại kết quả, rồi XÓA dữ liệu test.
--
-- Kết quả: bảng (step, test, expected, actual, result). Mọi dòng phải ✅ PASS.
--
--   A = Chủ sở hữu (owner)            rlstest-a@example.com
--   B = Được chia sẻ quyền editor     rlstest-b@example.com
--   C = Được chia sẻ quyền viewer     rlstest-c@example.com (sau đó được nâng admin)
-- =====================================================================

DROP TABLE IF EXISTS pg_temp.rls_test_results;
CREATE TEMP TABLE rls_test_results (
    step SERIAL,
    test TEXT,
    expected TEXT,
    actual TEXT,
    pass BOOLEAN
);

-- Dọn dữ liệu test cũ & tạo 3 hồ sơ người dùng test (chạy với quyền postgres)
DELETE FROM public.documents WHERE id LIKE 'rlstest-%';
DELETE FROM public.profiles WHERE id LIKE 'rlstest-%';
INSERT INTO public.profiles (id, email, display_name) VALUES
  ('rlstest-uid-a', 'rlstest-a@example.com', 'Test A (Owner)'),
  ('rlstest-uid-b', 'rlstest-b@example.com', 'Test B (Editor)'),
  ('rlstest-uid-c', 'rlstest-c@example.com', 'Test C (Viewer)');

-- Schema tạm chứa hàm tiện ích (xóa ở cuối script)
CREATE SCHEMA IF NOT EXISTS rls_test;
GRANT USAGE ON SCHEMA rls_test TO anon;

-- Đóng vai một người dùng Firebase (p_uid NULL = khách chỉ có publishable key)
CREATE OR REPLACE FUNCTION rls_test.act_as(p_uid TEXT, p_email TEXT, p_iss TEXT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE 'RESET ROLE';
    IF p_uid IS NULL THEN
        PERFORM set_config('request.jwt.claims',
            json_build_object('role', 'anon', 'iss', 'supabase')::TEXT, true);
    ELSE
        PERFORM set_config('request.jwt.claims', json_build_object(
            'iss', coalesce(p_iss, 'https://securetoken.google.com/document-bb712'),
            'aud', 'document-bb712',
            'sub', p_uid,
            'email', p_email
        )::TEXT, true);
    END IF;
    EXECUTE 'SET LOCAL ROLE anon';
END $$;

-- Ghi kết quả (quay về role postgres trước khi ghi)
CREATE OR REPLACE FUNCTION rls_test.log(p_test TEXT, p_expected TEXT, p_actual TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE 'RESET ROLE';
    INSERT INTO rls_test_results (test, expected, actual, pass)
    VALUES (p_test, p_expected, p_actual, p_expected = p_actual);
END $$;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA rls_test TO anon;

DO $$
DECLARE
    n INT;
    v TEXT;
BEGIN
    -- ===== 1. A tạo tài liệu và chia sẻ =====
    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    INSERT INTO public.documents (id, owner_id, title, note)
    VALUES ('rlstest-doc-1', 'rlstest-uid-a', 'Đề cương INT3120', 'Tài liệu test RLS');
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('A (owner) tạo tài liệu', '1', n::TEXT);

    -- App lưu bằng UPSERT (INSERT ... ON CONFLICT DO UPDATE): tạo mới rồi cập nhật
    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    INSERT INTO public.documents (id, owner_id, title)
    VALUES ('rlstest-doc-private', 'rlstest-uid-a', 'Ghi chú riêng của A')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title;
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('A tạo thêm 1 tài liệu riêng tư bằng UPSERT (như app)', '1', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    INSERT INTO public.documents (id, owner_id, title)
    VALUES ('rlstest-doc-private', 'rlstest-uid-a', 'Ghi chú riêng của A (sửa)')
    ON CONFLICT (id) DO UPDATE SET title = EXCLUDED.title;
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('A cập nhật tài liệu của mình bằng UPSERT', '1', n::TEXT);

    BEGIN
        PERFORM rls_test.act_as('rlstest-uid-b', 'rlstest-b@example.com');
        INSERT INTO public.documents (id, owner_id, title)
        VALUES ('rlstest-doc-fake', 'rlstest-uid-a', 'B tạo tài liệu đứng tên A');
        v := 'cho phép';
    EXCEPTION WHEN OTHERS THEN
        v := 'bị chặn';
    END;
    PERFORM rls_test.log('B KHÔNG tạo được tài liệu đứng tên người khác', 'bị chặn', v);

    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    INSERT INTO public.document_permissions (document_id, shared_with_email, shared_with_user_id, permission_level, granted_by)
    VALUES ('rlstest-doc-1', 'rlstest-b@example.com', 'rlstest-uid-b', 'editor', 'rlstest-uid-a'),
           ('rlstest-doc-1', 'RLSTEST-C@example.com', NULL, 'viewer', 'rlstest-uid-a')
    ON CONFLICT (document_id, shared_with_email) DO UPDATE SET permission_level = EXCLUDED.permission_level;
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('A chia sẻ cho B (editor) và C (viewer, chỉ theo email)', '2', n::TEXT);

    -- ===== 2. QUYỀN XEM (SELECT) =====
    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    SELECT count(*) INTO n FROM public.documents WHERE id LIKE 'rlstest-%';
    PERFORM rls_test.log('A thấy cả 2 tài liệu của mình', '2', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-b', 'rlstest-b@example.com');
    SELECT count(*) INTO n FROM public.documents WHERE id LIKE 'rlstest-%';
    PERFORM rls_test.log('B chỉ thấy tài liệu được chia sẻ, không thấy tài liệu riêng của A', '1', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-c', 'rlstest-c@example.com');
    SELECT count(*) INTO n FROM public.documents WHERE id LIKE 'rlstest-%';
    PERFORM rls_test.log('C (viewer, chia sẻ qua email) thấy đúng 1 tài liệu', '1', n::TEXT);

    PERFORM rls_test.act_as(NULL, NULL);
    SELECT count(*) INTO n FROM public.documents WHERE id LIKE 'rlstest-%';
    PERFORM rls_test.log('Khách chưa đăng nhập (chỉ publishable key) không thấy gì', '0', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com', 'https://securetoken.google.com/project-khac');
    SELECT count(*) INTO n FROM public.documents WHERE id LIKE 'rlstest-%';
    PERFORM rls_test.log('Token của project Firebase khác (giả mạo UID của A) không thấy gì', '0', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-c', 'rlstest-c@example.com');
    SELECT count(*) INTO n FROM public.document_permissions WHERE document_id = 'rlstest-doc-1';
    PERFORM rls_test.log('C (viewer) chỉ thấy dòng quyền của chính mình', '1', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    SELECT count(*) INTO n FROM public.document_permissions WHERE document_id = 'rlstest-doc-1';
    PERFORM rls_test.log('A (owner) thấy toàn bộ danh sách chia sẻ', '2', n::TEXT);

    -- ===== 3. QUYỀN SỬA (UPDATE) =====
    PERFORM rls_test.act_as('rlstest-uid-b', 'rlstest-b@example.com');
    UPDATE public.documents SET note = 'B (editor) đã cập nhật' WHERE id = 'rlstest-doc-1';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('B (editor) sửa được tài liệu được chia sẻ', '1', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-c', 'rlstest-c@example.com');
    UPDATE public.documents SET note = 'C cố sửa' WHERE id = 'rlstest-doc-1';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('C (viewer) KHÔNG sửa được tài liệu', '0', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-b', 'rlstest-b@example.com');
    UPDATE public.documents SET title = 'B cố sửa' WHERE id = 'rlstest-doc-private';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('B KHÔNG sửa được tài liệu riêng của A', '0', n::TEXT);

    BEGIN
        PERFORM rls_test.act_as('rlstest-uid-b', 'rlstest-b@example.com');
        UPDATE public.documents SET owner_id = 'rlstest-uid-b' WHERE id = 'rlstest-doc-1';
        v := 'cho phép';
    EXCEPTION WHEN OTHERS THEN
        v := 'bị chặn';
    END;
    PERFORM rls_test.log('B (editor) KHÔNG chiếm được quyền sở hữu (đổi owner_id)', 'bị chặn', v);

    -- ===== 4. QUYỀN CHIA SẺ =====
    BEGIN
        PERFORM rls_test.act_as('rlstest-uid-b', 'rlstest-b@example.com');
        INSERT INTO public.document_permissions (document_id, shared_with_email, permission_level, granted_by)
        VALUES ('rlstest-doc-1', 'rlstest-x@example.com', 'viewer', 'rlstest-uid-b');
        v := 'cho phép';
    EXCEPTION WHEN OTHERS THEN
        v := 'bị chặn';
    END;
    PERFORM rls_test.log('B (editor) KHÔNG được chia sẻ tiếp', 'bị chặn', v);

    BEGIN
        PERFORM rls_test.act_as('rlstest-uid-c', 'rlstest-c@example.com');
        UPDATE public.document_permissions SET permission_level = 'admin'
         WHERE document_id = 'rlstest-doc-1' AND shared_with_email = 'rlstest-c@example.com';
        GET DIAGNOSTICS n = ROW_COUNT;
        v := CASE WHEN n = 0 THEN 'bị chặn' ELSE 'cho phép' END;
    EXCEPTION WHEN OTHERS THEN
        v := 'bị chặn';
    END;
    PERFORM rls_test.log('C (viewer) KHÔNG tự nâng quyền của mình lên admin', 'bị chặn', v);

    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    UPDATE public.document_permissions SET permission_level = 'admin'
     WHERE document_id = 'rlstest-doc-1' AND shared_with_email = 'rlstest-c@example.com';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('A (owner) nâng C lên admin', '1', n::TEXT);

    BEGIN
        PERFORM rls_test.act_as('rlstest-uid-c', 'rlstest-c@example.com');
        INSERT INTO public.document_permissions (document_id, shared_with_email, permission_level, granted_by)
        VALUES ('rlstest-doc-1', 'rlstest-y@example.com', 'viewer', 'rlstest-uid-c');
        v := 'cho phép';
    EXCEPTION WHEN OTHERS THEN
        v := 'bị chặn';
    END;
    PERFORM rls_test.log('C (admin) chia sẻ tiếp quyền viewer cho người khác', 'cho phép', v);

    BEGIN
        PERFORM rls_test.act_as('rlstest-uid-c', 'rlstest-c@example.com');
        INSERT INTO public.document_permissions (document_id, shared_with_email, permission_level, granted_by)
        VALUES ('rlstest-doc-1', 'rlstest-z@example.com', 'admin', 'rlstest-uid-c');
        v := 'cho phép';
    EXCEPTION WHEN OTHERS THEN
        v := 'bị chặn';
    END;
    PERFORM rls_test.log('C (admin) KHÔNG được cấp quyền admin cho người khác', 'bị chặn', v);

    -- ===== 5. QUYỀN XÓA (DELETE) =====
    PERFORM rls_test.act_as('rlstest-uid-b', 'rlstest-b@example.com');
    DELETE FROM public.documents WHERE id = 'rlstest-doc-1';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('B (editor) KHÔNG xóa được tài liệu', '0', n::TEXT);

    PERFORM rls_test.act_as('rlstest-uid-c', 'rlstest-c@example.com');
    DELETE FROM public.documents WHERE id = 'rlstest-doc-1';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('C (admin) KHÔNG xóa được tài liệu (chỉ owner)', '0', n::TEXT);

    -- ===== 6. Chống giả mạo hồ sơ =====
    BEGIN
        PERFORM rls_test.act_as('rlstest-uid-d', 'rlstest-d@example.com');
        INSERT INTO public.profiles (id, email) VALUES ('rlstest-uid-d', 'victim@example.com');
        v := 'cho phép';
    EXCEPTION WHEN OTHERS THEN
        v := 'bị chặn';
    END;
    PERFORM rls_test.log('Không tạo được hồ sơ mang email của người khác', 'bị chặn', v);

    -- ===== 7. A xóa tài liệu => quyền chia sẻ bị xóa theo (CASCADE) =====
    PERFORM rls_test.act_as('rlstest-uid-a', 'rlstest-a@example.com');
    DELETE FROM public.documents WHERE id = 'rlstest-doc-1';
    GET DIAGNOSTICS n = ROW_COUNT;
    PERFORM rls_test.log('A (owner) xóa được tài liệu', '1', n::TEXT);

    EXECUTE 'RESET ROLE';
    SELECT count(*) INTO n FROM public.document_permissions WHERE document_id = 'rlstest-doc-1';
    PERFORM rls_test.log('Quyền chia sẻ của tài liệu đã xóa bị xóa theo (CASCADE)', '0', n::TEXT);

    -- ---------- Dọn dữ liệu test ----------
    PERFORM set_config('request.jwt.claims', '', true);
    DELETE FROM public.documents WHERE id LIKE 'rlstest-%';
    DELETE FROM public.profiles WHERE id LIKE 'rlstest-%';
END $$;

DROP SCHEMA rls_test CASCADE;

SELECT step, test, expected, actual,
       CASE WHEN pass THEN '✅ PASS' ELSE '❌ FAIL' END AS result
  FROM rls_test_results
 ORDER BY step;
