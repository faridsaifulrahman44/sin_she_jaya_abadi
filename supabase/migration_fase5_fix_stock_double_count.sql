-- Migration FASE 5 (hotfix): repair stok_awal legacy agar tidak double count.
--
-- Akar masalah yang ditangani:
-- - Pada sebagian data lama, stok_awal pernah setara snapshot stok_saat_ini
--   saat histori obat_masuk/obat_keluar sudah ada.
-- - Ketika engine replay histori dijalankan, mutasi masuk dihitung lagi
--   sehingga stok bisa melonjak (contoh: 11 + masuk 11 -> 33).
--
-- Prinsip perbaikan:
-- - Hanya normalisasi baris obat yang BELUM punya sinkronisasi_stok.
-- - Baseline baru:
--     stok_awal = max(0, stok_saat_ini - total_masuk + total_keluar_non_legacy)
-- - Tidak mengubah stok_saat_ini pada migration ini (nilai berjalan dipertahankan).

WITH masuk AS (
  SELECT
    om.id_obat,
    COALESCE(SUM(om.jumlah_masuk), 0)::integer AS total_masuk
  FROM public.obat_masuk om
  GROUP BY om.id_obat
),
keluar AS (
  SELECT
    oki.id_obat,
    COALESCE(SUM(oki.jumlah), 0)::integer AS total_keluar
  FROM public.obat_keluar_item oki
  WHERE oki.is_legacy = false
  GROUP BY oki.id_obat
),
target AS (
  SELECT
    o.id_obat,
    GREATEST(
      0,
      o.stok_saat_ini
      - COALESCE(m.total_masuk, 0)
      + COALESCE(k.total_keluar, 0)
    )::integer AS stok_awal_normalized
  FROM public.obat o
  LEFT JOIN masuk m
    ON m.id_obat = o.id_obat
  LEFT JOIN keluar k
    ON k.id_obat = o.id_obat
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.sinkronisasi_stok so
    WHERE so.id_obat = o.id_obat
  )
)
UPDATE public.obat o
SET stok_awal = t.stok_awal_normalized
FROM target t
WHERE o.id_obat = t.id_obat
  AND o.stok_awal IS DISTINCT FROM t.stok_awal_normalized;
