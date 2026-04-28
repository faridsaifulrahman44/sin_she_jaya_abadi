-- ============================================================
-- FASE 7: KUNJUNGAN / CATATAN HASIL / KONTROL
-- Tabel: kunjungan_pasien
--
-- Ringkasan:
--   - Menyimpan catatan hasil kunjungan pasien
--   - Tanggal kontrol berikutnya (nullable, opsional)
--   - Relasi ke pasien, bukan menu dashboard utama
-- ============================================================

CREATE TABLE IF NOT EXISTS public.kunjungan_pasien (
  id_kunjungan bigserial PRIMARY KEY,
  id_pasien   bigint NOT NULL REFERENCES public.pasien(id_pasien) ON DELETE CASCADE,
  tanggal_kunjungan date NOT NULL,
  keluhan_singkat text,
  catatan_hasil text,
  tindak_lanjut text,
  tanggal_kontrol_berikutnya date,
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Index untuk query umum
CREATE INDEX IF NOT EXISTS idx_kunjungan_id_pasien
  ON public.kunjungan_pasien(id_pasien);

CREATE INDEX IF NOT EXISTS idx_kunjungan_tanggal
  ON public.kunjungan_pasien(tanggal_kunjungan DESC);

-- RLS: semua authenticated user bisa baca
-- INSERT/UPDATE/DELETE ditangani oleh permission check di aplikasi (owner only)
ALTER TABLE public.kunjungan_pasien ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can read kunjungan_pasien"
  ON public.kunjungan_pasien;
CREATE POLICY "authenticated can read kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert kunjungan_pasien"
  ON public.kunjungan_pasien;
CREATE POLICY "authenticated can insert kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update kunjungan_pasien"
  ON public.kunjungan_pasien;
CREATE POLICY "authenticated can update kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can delete kunjungan_pasien"
  ON public.kunjungan_pasien;
CREATE POLICY "authenticated can delete kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);
