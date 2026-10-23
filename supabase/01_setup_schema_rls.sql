-- =====================================================================
-- STUDY MATERIALS — SUPABASE SCHEMA + ROW LEVEL SECURITY
-- Kiến trúc: Firebase Auth (Google) + Firebase Storage  <->  Supabase Postgres
--
-- Chạy TOÀN BỘ file này trong Supabase Dashboard > SQL Editor > New query > RUN.
-- Script idempotent: chạy lại nhiều lần không mất dữ liệu.
--
-- Điều kiện tiên quyết (1 lần): Authentication > Sign In / Providers >
--   Third-Party Auth > Add provider > Firebase > Project ID: document-bb712
--
-- Lưu ý quan trọng về role:
--   Firebase ID token KHÔNG có claim "role", nên PostgREST chạy truy vấn với role
--   "anon". Vì vậy mọi policy dưới đây KHÔNG dựa vào role mà dựa vào token Firebase
--   đã được Supabase xác minh chữ ký: iss + aud phải đúng project Firebase của app,
--   và "sub" chính là Firebase UID. Request chỉ có publishable key (không đăng nhập)
--   không có sub => bị từ chối toàn bộ.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. HÀM ĐỊNH DANH (đọc từ JWT Firebase đã được xác minh)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.firebase_uid()
RETURNS TEXT
LANGUAGE SQL STABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN auth.jwt() ->> 'iss' = 'https://securetoken.google.com/document-bb712'
     AND auth.jwt() ->> 'aud' = 'document-bb712'
    THEN NULLIF(auth.jwt() ->> 'sub', '')
  END;
$$;

CREATE OR REPLACE FUNCTION public.firebase_email()
RETURNS TEXT
LANGUAGE SQL STABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN public.firebase_uid() IS NOT NULL
    THEN lower(NULLIF(auth.jwt() ->> 'email', ''))
  END;
$$;

-- ---------------------------------------------------------------------
-- 1. BẢNG NGƯỜI DÙNG (PROFILES) — id = Firebase UID
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now()) NOT NULL,
    last_sign_in_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now())
);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ---------------------------------------------------------------------
-- 2. BẢNG TÀI LIỆU (DOCUMENTS) — metadata, file vật lý nằm trên Firebase Storage
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.documents (
    id TEXT PRIMARY KEY,
    owner_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    note TEXT,
    subject_code VARCHAR(50),
    subject_name VARCHAR(255),
    doc_type VARCHAR(50) DEFAULT 'Bài tập',
    status INT DEFAULT 0,
    due_date TIMESTAMPTZ,
    is_pinned BOOLEAN DEFAULT false,
    file_url TEXT,
    file_path TEXT,
    file_name VARCHAR(255),
    file_size BIGINT DEFAULT 0,
    storage_provider VARCHAR(50) DEFAULT 'firebase_storage',
    is_public BOOLEAN DEFAULT false,
    tags TEXT,
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now()) NOT NULL
);
-- Bổ sung cột cho bảng tạo từ phiên bản cũ
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS file_path TEXT;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS updated_by TEXT;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS tags TEXT;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS location_name TEXT;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

CREATE INDEX IF NOT EXISTS idx_documents_owner_id ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_subject_code ON public.documents(subject_code);
CREATE INDEX IF NOT EXISTS idx_documents_status ON public.documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_due_date ON public.documents(due_date);
CREATE INDEX IF NOT EXISTS idx_documents_fts ON public.documents
  USING GIN (to_tsvector('simple', title || ' ' || coalesce(note, '')));

-- ---------------------------------------------------------------------
-- 3. BẢNG QUYỀN CHIA SẺ (DOCUMENT_PERMISSIONS)
--    viewer: chỉ xem | editor: xem + sửa | admin: xem + sửa + chia sẻ tiếp
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.document_permissions (
    id BIGSERIAL PRIMARY KEY,
    document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    shared_with_email VARCHAR(255) NOT NULL,
    shared_with_user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) NOT NULL CHECK (permission_level IN ('viewer', 'editor', 'admin')),
    granted_by TEXT NOT NULL REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now()) NOT NULL,
    CONSTRAINT unique_doc_user_share UNIQUE (document_id, shared_with_email)
);
CREATE INDEX IF NOT EXISTS idx_perms_doc_id ON public.document_permissions(document_id);
CREATE INDEX IF NOT EXISTS idx_perms_shared_email ON public.document_permissions(shared_with_email);
CREATE INDEX IF NOT EXISTS idx_perms_shared_user ON public.document_permissions(shared_with_user_id);

-- ---------------------------------------------------------------------
-- 3b. BẢNG YÊU CẦU MƯỢN TÀI LIỆU (BORROW_REQUESTS)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.borrow_requests (
    id BIGSERIAL PRIMARY KEY,
    document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    requester_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    owner_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'returned')),
    request_note TEXT,
    response_note TEXT,
    borrow_date TIMESTAMPTZ,
    return_due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now()) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_borrow_doc_id ON public.borrow_requests(document_id);
CREATE INDEX IF NOT EXISTS idx_borrow_requester ON public.borrow_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_borrow_owner ON public.borrow_requests(owner_id);

-- ---------------------------------------------------------------------
-- 3c. BẢNG SỞ THÍCH NGƯỜI DÙNG (USER_PREFERENCES) CHO RECOMMENDATION
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_preferences (
    user_id TEXT PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    preferred_tags TEXT DEFAULT '',
    preferred_subjects TEXT DEFAULT '',
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', now()) NOT NULL
);

-- ---------------------------------------------------------------------
-- 4. TRIGGER
-- ---------------------------------------------------------------------
-- 4a. updated_at + updated_by, và cấm đổi id/owner_id (chống editor chiếm quyền sở hữu)
CREATE OR REPLACE FUNCTION public.handle_document_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.owner_id IS DISTINCT FROM OLD.owner_id THEN
        RAISE EXCEPTION 'Không được thay đổi id hoặc chủ sở hữu tài liệu'
            USING ERRCODE = '42501';
    END IF;
    NEW.updated_at = TIMEZONE('utc', now());
    NEW.updated_by = public.firebase_uid();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_documents_updated_at ON public.documents;
CREATE TRIGGER trigger_documents_updated_at
    BEFORE UPDATE ON public.documents
    FOR EACH ROW EXECUTE FUNCTION public.handle_document_update();

-- 4b. Chuẩn hóa email chia sẻ về chữ thường
CREATE OR REPLACE FUNCTION public.normalize_permission_email()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
    NEW.shared_with_email = lower(trim(NEW.shared_with_email));
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_permissions_normalize ON public.document_permissions;
CREATE TRIGGER trigger_permissions_normalize
    BEFORE INSERT OR UPDATE ON public.document_permissions
    FOR EACH ROW EXECUTE FUNCTION public.normalize_permission_email();

-- 4c. Khi người dùng đăng nhập lần đầu: tự liên kết các lời mời đã gửi tới email của họ
CREATE OR REPLACE FUNCTION public.link_pending_permissions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    UPDATE public.document_permissions
       SET shared_with_user_id = NEW.id
     WHERE shared_with_user_id IS NULL
       AND shared_with_email = lower(NEW.email);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_profiles_link_permissions ON public.profiles;
CREATE TRIGGER trigger_profiles_link_permissions
    AFTER INSERT ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.link_pending_permissions();

-- ---------------------------------------------------------------------
-- 5. HÀM PHÂN QUYỀN (SECURITY DEFINER để tránh đệ quy RLS giữa 2 bảng)
--    Trả về: 'owner' | 'admin' | 'editor' | 'viewer' | 'public' | NULL
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.document_role(p_document_id TEXT)
RETURNS TEXT
LANGUAGE plpgsql STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_uid   TEXT := public.firebase_uid();
    v_email TEXT := public.firebase_email();
    v_doc   RECORD;
    v_level TEXT;
BEGIN
    IF v_uid IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT owner_id, is_public INTO v_doc
      FROM public.documents WHERE id = p_document_id;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    IF v_doc.owner_id = v_uid THEN
        RETURN 'owner';
    END IF;

    SELECT dp.permission_level INTO v_level
      FROM public.document_permissions dp
     WHERE dp.document_id = p_document_id
       AND (dp.shared_with_user_id = v_uid OR dp.shared_with_email = v_email)
     ORDER BY CASE dp.permission_level WHEN 'admin' THEN 1 WHEN 'editor' THEN 2 ELSE 3 END
     LIMIT 1;
    IF v_level IS NOT NULL THEN
        RETURN v_level;
    END IF;

    IF v_doc.is_public THEN
        RETURN 'public';
    END IF;
    RETURN NULL;
END;
$$;

-- Hàm chẩn đoán: app gọi để kiểm tra Supabase đã nhận diện token Firebase chưa
CREATE OR REPLACE FUNCTION public.whoami()
RETURNS JSON
LANGUAGE SQL STABLE
SET search_path = ''
AS $$
  SELECT json_build_object(
    'firebase_uid', public.firebase_uid(),
    'email', public.firebase_email(),
    'postgres_role', current_user,
    'iss', auth.jwt() ->> 'iss'
  );
$$;

-- ---------------------------------------------------------------------
-- 6. QUYỀN SQL (GRANT) — role anon được cấp vì token Firebase chạy dưới anon;
--    RLS bên dưới quyết định từng dòng.
-- ---------------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.documents TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.document_permissions TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.borrow_requests TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_preferences TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.document_permissions_id_seq TO anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.borrow_requests_id_seq TO anon, authenticated;

REVOKE ALL ON FUNCTION public.document_role(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.link_pending_permissions() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.document_role(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.firebase_uid() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.firebase_email() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.whoami() TO anon, authenticated;

-- ---------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.borrow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- Xóa toàn bộ policy cũ trên các bảng
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN
        SELECT policyname, tablename FROM pg_policies
         WHERE schemaname = 'public'
           AND tablename IN ('profiles', 'documents', 'document_permissions', 'borrow_requests', 'user_preferences')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', r.policyname, r.tablename);
    END LOOP;
END $$;

-- ===== PROFILES =====
-- Người đã đăng nhập được xem hồ sơ (để tìm người nhận khi chia sẻ)
CREATE POLICY profiles_select ON public.profiles
  FOR SELECT TO anon, authenticated
  USING (public.firebase_uid() IS NOT NULL);

-- Chỉ tạo/sửa hồ sơ của chính mình, email phải khớp email trong token Google
-- (chống giả mạo email để chiếm lời mời chia sẻ của người khác)
CREATE POLICY profiles_insert ON public.profiles
  FOR INSERT TO anon, authenticated
  WITH CHECK (id = public.firebase_uid() AND lower(email) = public.firebase_email());

CREATE POLICY profiles_update ON public.profiles
  FOR UPDATE TO anon, authenticated
  USING (id = public.firebase_uid())
  WITH CHECK (id = public.firebase_uid() AND lower(email) = public.firebase_email());

-- ===== DOCUMENTS =====
-- XEM: chủ sở hữu, người được chia sẻ (bất kỳ quyền), hoặc tài liệu công khai.
-- Điều kiện owner_id kiểm tra trực tiếp trên dòng: cần cho UPSERT (INSERT ... ON CONFLICT),
-- vì Postgres áp policy SELECT lên dòng mới khi dòng đó chưa tồn tại trong bảng.
CREATE POLICY documents_select ON public.documents
  FOR SELECT TO anon, authenticated
  USING (
    owner_id = public.firebase_uid()
    OR public.document_role(id) IS NOT NULL
  );

-- TẠO: chỉ tạo tài liệu đứng tên chính mình
CREATE POLICY documents_insert ON public.documents
  FOR INSERT TO anon, authenticated
  WITH CHECK (owner_id = public.firebase_uid());

-- SỬA: owner / admin / editor (viewer bị chặn)
CREATE POLICY documents_update ON public.documents
  FOR UPDATE TO anon, authenticated
  USING (public.document_role(id) IN ('owner', 'admin', 'editor'))
  WITH CHECK (public.document_role(id) IN ('owner', 'admin', 'editor'));

-- XÓA: duy nhất chủ sở hữu
CREATE POLICY documents_delete ON public.documents
  FOR DELETE TO anon, authenticated
  USING (owner_id = public.firebase_uid());

-- ===== DOCUMENT_PERMISSIONS =====
-- XEM: owner/admin của tài liệu thấy toàn bộ danh sách; người được chia sẻ thấy dòng của mình
CREATE POLICY permissions_select ON public.document_permissions
  FOR SELECT TO anon, authenticated
  USING (
    public.document_role(document_id) IN ('owner', 'admin')
    OR shared_with_user_id = public.firebase_uid()
    OR shared_with_email = public.firebase_email()
  );

-- CẤP QUYỀN: owner cấp mọi mức; admin chỉ cấp viewer/editor. granted_by phải là chính mình.
CREATE POLICY permissions_insert ON public.document_permissions
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    granted_by = public.firebase_uid()
    AND shared_with_email <> coalesce(public.firebase_email(), '')
    AND (
      public.document_role(document_id) = 'owner'
      OR (public.document_role(document_id) = 'admin' AND permission_level <> 'admin')
    )
  );

-- ĐỔI MỨC QUYỀN: như trên; admin không được động vào dòng admin khác
CREATE POLICY permissions_update ON public.document_permissions
  FOR UPDATE TO anon, authenticated
  USING (
    public.document_role(document_id) = 'owner'
    OR (public.document_role(document_id) = 'admin' AND permission_level <> 'admin')
  )
  WITH CHECK (
    granted_by = public.firebase_uid()
    AND (
      public.document_role(document_id) = 'owner'
      OR (public.document_role(document_id) = 'admin' AND permission_level <> 'admin')
    )
  );

-- THU HỒI: owner thu hồi mọi quyền; admin chỉ thu hồi viewer/editor
CREATE POLICY permissions_delete ON public.document_permissions
  FOR DELETE TO anon, authenticated
  USING (
    public.document_role(document_id) = 'owner'
    OR (public.document_role(document_id) = 'admin' AND permission_level <> 'admin')
  );

-- ===== BORROW_REQUESTS =====
-- XEM: Người gửi yêu cầu mượn hoặc chủ sở hữu tài liệu
CREATE POLICY borrow_select ON public.borrow_requests
  FOR SELECT TO anon, authenticated
  USING (
    requester_id = public.firebase_uid()
    OR owner_id = public.firebase_uid()
  );

-- TẠO YÊU CẦU: Người gửi phải là chính mình
CREATE POLICY borrow_insert ON public.borrow_requests
  FOR INSERT TO anon, authenticated
  WITH CHECK (requester_id = public.firebase_uid());

-- CẬP NHẬT TRẠNG THÁI: Chủ sở hữu (duyệt/từ chối/nhận lại) hoặc người mượn (đổi ghi chú)
CREATE POLICY borrow_update ON public.borrow_requests
  FOR UPDATE TO anon, authenticated
  USING (
    requester_id = public.firebase_uid()
    OR owner_id = public.firebase_uid()
  );

-- XÓA: Người mượn hoặc chủ sở hữu
CREATE POLICY borrow_delete ON public.borrow_requests
  FOR DELETE TO anon, authenticated
  USING (
    requester_id = public.firebase_uid()
    OR owner_id = public.firebase_uid()
  );

-- ===== USER_PREFERENCES =====
CREATE POLICY prefs_select ON public.user_preferences
  FOR SELECT TO anon, authenticated
  USING (user_id = public.firebase_uid());

CREATE POLICY prefs_insert ON public.user_preferences
  FOR INSERT TO anon, authenticated
  WITH CHECK (user_id = public.firebase_uid());

CREATE POLICY prefs_update ON public.user_preferences
  FOR UPDATE TO anon, authenticated
  USING (user_id = public.firebase_uid());

-- Nạp lại schema cache của PostgREST
NOTIFY pgrst, 'reload schema';

-- Kiểm tra nhanh: 3 bảng phải có rls_enabled = true
SELECT tablename, rowsecurity AS rls_enabled,
       (SELECT count(*) FROM pg_policies p WHERE p.schemaname = 'public' AND p.tablename = t.tablename) AS policies
  FROM pg_tables t
 WHERE schemaname = 'public' AND tablename IN ('profiles', 'documents', 'document_permissions');
