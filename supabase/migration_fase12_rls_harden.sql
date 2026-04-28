-- Migration: Harden RLS Policies
--
-- Scope:
-- 1. Ganti policy `USING (true) / WITH CHECK (true)` yang terlalu permisif
--    dengan policy yang menggunakan `auth.uid() IS NOT NULL` secara eksplisit.
-- 2. Pasang policy ketat pada tabel `admin` — user hanya bisa baca row sendiri.
-- 3. Tambah helper function `get_auth_admin_id()` untuk future enhancements.
--
-- Catatan keamanan:
--   Primary security layer: RPC functions di aplikasi (Dart)
--   → AdminSession.getCurrentId() memvalidasi auth session
--   → Semua mutation lewat RPC yang menerima p_id_admin dari session
--   RLS policy ini: defense-in-depth untuk akses PostgREST langsung.
--
-- Tabel yang dilindungi:
--   admin          → hanya row milik user sendiri (auth_user_id = auth.uid())
--   obat           → semua authenticated (data bersama klinik)
--   obat_masuk     → semua authenticated
--   obat_keluar    → semua authenticated
--   obat_keluar_item → semua authenticated
--   stock_opname    → semua authenticated
--   pasien         → semua authenticated
--   kehadiran_pasien → semua authenticated

-- ============================================================
-- A. Helper: get_auth_admin_id()
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_auth_admin_id()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_auth_uid uuid;
  v_id_admin bigint;
BEGIN
  v_auth_uid := auth.uid();
  IF v_auth_uid IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT a.id_admin
  INTO v_id_admin
  FROM public.admin a
  WHERE a.auth_user_id = v_auth_uid
  LIMIT 1;

  RETURN v_id_admin;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_auth_admin_id() TO authenticated;

-- ============================================================
-- B. admin: hanya profile milik user sendiri
-- ============================================================

DROP POLICY IF EXISTS "authenticated can read admin" ON public.admin;
CREATE POLICY "admin read own row"
  ON public.admin
  FOR SELECT
  TO authenticated
  USING (auth.uid() = admin.auth_user_id);

-- ============================================================
-- C. obat
-- ============================================================

DROP POLICY IF EXISTS "authenticated can manage obat" ON public.obat;
CREATE POLICY "authenticated can read obat"
  ON public.obat
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can insert obat"
  ON public.obat
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can update obat"
  ON public.obat
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- D. obat_masuk
-- ============================================================

DROP POLICY IF EXISTS "authenticated can manage obat_masuk" ON public.obat_masuk;
CREATE POLICY "authenticated can read obat_masuk"
  ON public.obat_masuk
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can insert obat_masuk"
  ON public.obat_masuk
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can update obat_masuk"
  ON public.obat_masuk
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- E. obat_keluar
-- ============================================================

DROP POLICY IF EXISTS "authenticated can manage obat_keluar" ON public.obat_keluar;
CREATE POLICY "authenticated can read obat_keluar"
  ON public.obat_keluar
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can insert obat_keluar"
  ON public.obat_keluar
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can update obat_keluar"
  ON public.obat_keluar
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- F. obat_keluar_item
-- ============================================================

DROP POLICY IF EXISTS "authenticated can manage obat_keluar_item" ON public.obat_keluar_item;
CREATE POLICY "authenticated can read obat_keluar_item"
  ON public.obat_keluar_item
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can insert obat_keluar_item"
  ON public.obat_keluar_item
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can update obat_keluar_item"
  ON public.obat_keluar_item
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- G. stock_opname
-- ============================================================

DROP POLICY IF EXISTS "authenticated can manage stock_opname" ON public.stock_opname;
CREATE POLICY "authenticated can read stock_opname"
  ON public.stock_opname
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can insert stock_opname"
  ON public.stock_opname
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can update stock_opname"
  ON public.stock_opname
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- H. pasien
-- ============================================================

DROP POLICY IF EXISTS "authenticated can manage pasien" ON public.pasien;
CREATE POLICY "authenticated can read pasien"
  ON public.pasien
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can insert pasien"
  ON public.pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can update pasien"
  ON public.pasien
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================================
-- I. kehadiran_pasien
-- ============================================================

DROP POLICY IF EXISTS "authenticated can manage kehadiran" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can read kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can insert kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "authenticated can update kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);
