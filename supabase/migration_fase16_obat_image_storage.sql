-- Migration FASE 16: storage foto obat (Master Obat).
--
-- Tujuan:
-- 1) Menyediakan bucket `obat-images` untuk upload foto obat.
-- 2) Menyediakan policy read/upload/update/delete yang aman dan eksplisit.
--
-- Catatan:
-- - `foto_url` dipertahankan untuk data legacy.
-- - `foto_key` + `foto_updated_at` adalah metadata storage final.

ALTER TABLE public.obat
  ADD COLUMN IF NOT EXISTS foto_key text,
  ADD COLUMN IF NOT EXISTS foto_updated_at timestamptz;

COMMENT ON COLUMN public.obat.foto_key IS
  'Storage object key untuk bucket obat-images. Null untuk data legacy.';

COMMENT ON COLUMN public.obat.foto_updated_at IS
  'Waktu terakhir metadata foto obat diperbarui.';

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'obat-images',
  'obat-images',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "public read obat-images" ON storage.objects;
CREATE POLICY "public read obat-images"
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'obat-images');

DROP POLICY IF EXISTS "authenticated upload obat-images" ON storage.objects;
CREATE POLICY "authenticated upload obat-images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'obat-images');

DROP POLICY IF EXISTS "authenticated update obat-images" ON storage.objects;
CREATE POLICY "authenticated update obat-images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'obat-images')
  WITH CHECK (bucket_id = 'obat-images');

DROP POLICY IF EXISTS "authenticated delete obat-images" ON storage.objects;
CREATE POLICY "authenticated delete obat-images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'obat-images');
