-- ============================================================
-- FINAL BASELINE SCHEMA (SOURCE OF TRUTH)
-- Project: Flutter Klinik
-- Scope:
--   admin, obat, obat_masuk, obat_keluar, obat_keluar_item,
--   stock_opname, pasien, kehadiran_pasien,
--   transaksi, transaksi_item, kunjungan_pasien
--
-- Notes:
-- 1) Untuk environment baru, jalankan file ini sebagai baseline tunggal.
-- 2) Untuk environment lama yang sudah punya data, gunakan urutan migration
--    di supabase/README.md agar aman.
-- 3) Tabel transaksi, transaksi_item, dan kunjungan_pasien ditambah di
--    STEP 2 sinkronisasi database (2026-04-17). Tidak ada migration
--    terpisah untuk tabel-tabel ini karena belum ada di codebase sebelumnya.
-- ============================================================

-- =========================
-- TABLES
-- =========================

CREATE TABLE IF NOT EXISTS public.admin (
  id_admin bigserial PRIMARY KEY,
  auth_user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,
  username varchar(50) NOT NULL UNIQUE,
  nama_admin varchar(100) NOT NULL,
  role varchar(20) NOT NULL CHECK (role IN ('petugas', 'kepala_klinik')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.obat (
  id_obat bigserial PRIMARY KEY,
  nama_obat varchar(100) NOT NULL,
  stok_awal integer NOT NULL DEFAULT 0 CHECK (stok_awal >= 0),
  stok_saat_ini integer NOT NULL DEFAULT 0 CHECK (stok_saat_ini >= 0),
  stok_minimum integer NOT NULL DEFAULT 10 CHECK (stok_minimum >= 0),
  etalase varchar(20) NOT NULL DEFAULT 'etalase1'
    CHECK (etalase IN ('etalase1', 'etalase2', 'etalase3')),
  satuan varchar(30),
  -- ── Harga Source of Truth (FASE 1, 2026-04-27) ───────────────────────────
  -- harga_jual  : harga utama per satuan_jual (numeric agar support desimal)
  harga_jual numeric(12, 2) CHECK (harga_jual IS NULL OR harga_jual >= 0),
  -- satuan_jual : satuan default untuk harga utama, contoh: botol, strip, pcs
  satuan_jual varchar(30),
  -- bisa_ecer   : apakah obat bisa dijual eceran
  bisa_ecer boolean NOT NULL DEFAULT false,
  -- harga_ecer  : harga per satuan_ecer (nullable — hanya relevan jika bisa_ecer=true)
  harga_ecer numeric(12, 2) CHECK (harga_ecer IS NULL OR harga_ecer >= 0),
  -- satuan_ecer  : satuan eceran, contoh: kapsul, tablet, ml
  satuan_ecer varchar(30),
  -- ────────────────────────────────────────────────────────────────────────
  keterangan text,
  foto_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.obat_masuk (
  id_masuk bigserial PRIMARY KEY,
  id_obat bigint NOT NULL REFERENCES public.obat(id_obat) ON DELETE RESTRICT,
  tanggal_masuk date NOT NULL,
  jumlah_masuk integer NOT NULL CHECK (jumlah_masuk > 0),
  keterangan text,
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.obat_keluar (
  id_terjual bigserial PRIMARY KEY,
  tanggal_terjual date NOT NULL,
  no_etalase varchar(20),
  -- jumlah_item header cache: COUNT(*) of non-legacy item rows in this nota.
  -- Semantic: JUMLAH UNIT/BARIS ITEM, bukan jumlah nota (1 nota = 1 header).
  -- Refreshed by fn_obat_keluar_refresh_totals after each insert/update.
  jumlah_transaksi integer NOT NULL DEFAULT 0 CHECK (jumlah_transaksi >= 0),
  -- total_nominal = SUM(subtotal) of non-legacy items in this nota.
  total_nominal numeric(14, 2) NOT NULL DEFAULT 0 CHECK (total_nominal >= 0),
  keterangan text,
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.obat_keluar_item (
  id_item bigserial PRIMARY KEY,
  id_terjual bigint NOT NULL
    REFERENCES public.obat_keluar(id_terjual) ON DELETE CASCADE,
  -- NULL diizinkan hanya untuk data legacy hasil backfill.
  id_obat bigint
    REFERENCES public.obat(id_obat) ON DELETE RESTRICT,
  jumlah integer NOT NULL CHECK (jumlah > 0),
  harga_satuan numeric(14, 2) NOT NULL CHECK (harga_satuan >= 0),
  subtotal numeric(14, 2) NOT NULL CHECK (subtotal >= 0),
  is_legacy boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.stock_opname (
  id_opname bigserial PRIMARY KEY,
  id_obat bigint NOT NULL REFERENCES public.obat(id_obat) ON DELETE RESTRICT,
  tanggal_opname date NOT NULL,
  stok_sistem integer NOT NULL DEFAULT 0,
  stok_fisik integer NOT NULL DEFAULT 0,
  selisih integer NOT NULL DEFAULT 0,
  alasan_penyesuaian text,
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.pasien (
  id_pasien bigserial PRIMARY KEY,
  nomor_pasien varchar(30) NOT NULL UNIQUE,
  nama_pasien varchar(100) NOT NULL,
  alamat text,
  usia integer CHECK (usia >= 0),
  jenis_kelamin char(1) NOT NULL CHECK (jenis_kelamin IN ('L', 'P')),
  tanggal_janjian date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.kehadiran_pasien (
  id_kehadiran bigserial PRIMARY KEY,
  id_pasien bigint NOT NULL REFERENCES public.pasien(id_pasien) ON DELETE CASCADE,
  tanggal_hadir date NOT NULL,
  status_hadir varchar(20) NOT NULL DEFAULT 'hadir'
    CHECK (status_hadir IN ('hadir', 'tidak_hadir')),
  keterangan text,
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id_pasien, tanggal_hadir)
);

COMMENT ON COLUMN public.obat.stok_saat_ini IS
  'stok_saat_ini dihitung dari stok_awal + mutasi masuk/keluar '
  'dan reset stock_opname. Di-maintain oleh SQL function fn_recalculate_obat_stok_*.';

-- =========================
-- TABEL: transaksi
-- Header transaksi klinik (ready stock / custom).
-- Steady-state: kode aplikasi insert via Supabase client (bukan RPC).
-- =========================

CREATE TABLE IF NOT EXISTS public.transaksi (
  id_transaksi bigserial PRIMARY KEY,
  tanggal date NOT NULL DEFAULT current_date,
  jenis_transaksi varchar(30) NOT NULL
    CHECK (jenis_transaksi IN ('obat_ready_stock', 'praktek_custom')),
  total numeric(12, 2) NOT NULL CHECK (total >= 0),
  metode_bayar varchar(20),
  id_pasien bigint REFERENCES public.pasien(id_pasien),
  keterangan text,
  durasi_harian int CHECK (durasi_harian IS NULL OR durasi_harian > 0),
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.transaksi_item (
  id_item bigserial PRIMARY KEY,
  id_transaksi bigint NOT NULL
    REFERENCES public.transaksi(id_transaksi) ON DELETE CASCADE,
  id_obat bigint NOT NULL REFERENCES public.obat(id_obat),
  jumlah int NOT NULL CHECK (jumlah > 0),
  harga_satuan numeric(12, 2) NOT NULL CHECK (harga_satuan >= 0),
  subtotal numeric(12, 2) NOT NULL CHECK (subtotal >= 0),
  -- ── Ecer Sederhana (FASE 3, 2026-04-27) ────────────────────────────
  -- satuan aktual yang dipilih user saat transaksi: satuan_jual atau satuan_ecer.
  -- Nullable → aman untuk legacy transaksi sebelum FASE 3 dan transaksi custom.
  satuan_terjual varchar(30),
  -- ──────────────────────────────────────────────────────────────────
  id_admin bigint REFERENCES public.admin(id_admin)
);

-- =========================
-- TABEL: kunjungan_pasien
-- Catatan hasil kunjungan / kontrol pasien.
-- Steady-state: kode aplikasi insert via Supabase client (bukan RPC).
-- =========================

CREATE TABLE IF NOT EXISTS public.kunjungan_pasien (
  id_kunjungan bigserial PRIMARY KEY,
  id_pasien bigint NOT NULL
    REFERENCES public.pasien(id_pasien) ON DELETE CASCADE,
  tanggal_kunjungan date NOT NULL,
  keluhan_singkat text,
  catatan_hasil text,
  tindak_lanjut text,
  tanggal_kontrol_berikutnya date,
  id_admin bigint NOT NULL REFERENCES public.admin(id_admin),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- =========================
-- INDEXES
-- =========================

CREATE INDEX IF NOT EXISTS idx_obat_masuk_tanggal
  ON public.obat_masuk(tanggal_masuk DESC);
CREATE INDEX IF NOT EXISTS idx_obat_masuk_id_obat
  ON public.obat_masuk(id_obat);

CREATE INDEX IF NOT EXISTS idx_obat_keluar_tanggal
  ON public.obat_keluar(tanggal_terjual DESC);

CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_terjual
  ON public.obat_keluar_item(id_terjual);
CREATE INDEX IF NOT EXISTS idx_obat_keluar_item_id_obat
  ON public.obat_keluar_item(id_obat);

CREATE INDEX IF NOT EXISTS idx_stock_opname_tanggal
  ON public.stock_opname(tanggal_opname DESC);
CREATE INDEX IF NOT EXISTS idx_stock_opname_id_obat
  ON public.stock_opname(id_obat);

CREATE INDEX IF NOT EXISTS idx_pasien_tanggal_janjian
  ON public.pasien(tanggal_janjian DESC);

-- transaksi indexes
CREATE INDEX IF NOT EXISTS idx_transaksi_tanggal
  ON public.transaksi(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_transaksi_jenis
  ON public.transaksi(jenis_transaksi);
CREATE INDEX IF NOT EXISTS idx_transaksi_pasien
  ON public.transaksi(id_pasien);

-- transaksi_item indexes
CREATE INDEX IF NOT EXISTS idx_transaksi_item_transaksi
  ON public.transaksi_item(id_transaksi);
CREATE INDEX IF NOT EXISTS idx_transaksi_item_obat
  ON public.transaksi_item(id_obat);

-- kunjungan_pasien indexes
CREATE INDEX IF NOT EXISTS idx_kunjungan_id_pasien
  ON public.kunjungan_pasien(id_pasien);
CREATE INDEX IF NOT EXISTS idx_kunjungan_tanggal
  ON public.kunjungan_pasien(id_kunjungan DESC);

-- Obat harga indexes (FASE 1, 2026-04-27)
CREATE INDEX IF NOT EXISTS idx_obat_harga_jual
  ON public.obat(harga_jual);
CREATE INDEX IF NOT EXISTS idx_obat_bisa_ecer
  ON public.obat(bisa_ecer);

-- =========================
-- TRIGGERS / FUNCTIONS
-- =========================

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_item_set_subtotal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_legacy = false THEN
    NEW.subtotal := NEW.jumlah * NEW.harga_satuan;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_obat_keluar_item_set_subtotal
  ON public.obat_keluar_item;

CREATE TRIGGER trg_obat_keluar_item_set_subtotal
  BEFORE INSERT OR UPDATE OF jumlah, harga_satuan
  ON public.obat_keluar_item
  FOR EACH ROW
  WHEN (NEW.is_legacy = false)
  EXECUTE FUNCTION public.fn_obat_keluar_item_set_subtotal();

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_refresh_totals(
  p_id_terjual bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.obat_keluar ok
  SET
    jumlah_transaksi = agg.total_items,
    total_nominal = agg.total_nominal
  FROM (
    SELECT
      COUNT(*)::integer AS total_items,
      COALESCE(SUM(oki.subtotal), 0)::numeric(14, 2) AS total_nominal
    FROM public.obat_keluar_item oki
    WHERE oki.id_terjual = p_id_terjual
      AND oki.is_legacy = false
  ) AS agg
  WHERE ok.id_terjual = p_id_terjual;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_recalculate_obat_stok_single(
  p_id_obat bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_stok integer;
  mut record;
BEGIN
  SELECT o.stok_awal
  INTO v_stok
  FROM public.obat o
  WHERE o.id_obat = p_id_obat
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF v_stok < 0 THEN
    v_stok := 0;
  END IF;

  FOR mut IN
    WITH mutations AS (
      SELECT
        om.tanggal_masuk AS mutation_date,
        1 AS priority,
        om.created_at AS recorded_at,
        om.id_masuk AS sequence_id,
        om.jumlah_masuk AS delta,
        false AS is_reset
      FROM public.obat_masuk om
      WHERE om.id_obat = p_id_obat

      UNION ALL

      SELECT
        ok.tanggal_terjual AS mutation_date,
        2 AS priority,
        COALESCE(oki.created_at, ok.created_at) AS recorded_at,
        oki.id_item AS sequence_id,
        -oki.jumlah AS delta,
        false AS is_reset
      FROM public.obat_keluar_item oki
      JOIN public.obat_keluar ok
        ON ok.id_terjual = oki.id_terjual
      WHERE oki.id_obat = p_id_obat
        AND oki.is_legacy = false

      UNION ALL

      SELECT
        so.tanggal_opname AS mutation_date,
        3 AS priority,
        so.created_at AS recorded_at,
        so.id_opname AS sequence_id,
        so.stok_fisik AS delta,
        true AS is_reset
      FROM public.stock_opname so
      WHERE so.id_obat = p_id_obat
    )
    SELECT
      mutations.delta,
      mutations.is_reset
    FROM mutations
    ORDER BY
      mutations.mutation_date ASC,
      mutations.priority ASC,
      mutations.recorded_at ASC NULLS FIRST,
      mutations.sequence_id ASC
  LOOP
    IF mut.is_reset THEN
      v_stok := GREATEST(mut.delta, 0);
    ELSE
      v_stok := GREATEST(v_stok + mut.delta, 0);
    END IF;
  END LOOP;

  UPDATE public.obat
  SET stok_saat_ini = v_stok
  WHERE id_obat = p_id_obat;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_recalculate_obat_stok_bulk(
  p_ids bigint[]
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_id bigint;
BEGIN
  IF p_ids IS NULL OR COALESCE(array_length(p_ids, 1), 0) = 0 THEN
    RETURN;
  END IF;

  FOR v_id IN
    SELECT DISTINCT id_obat
    FROM unnest(p_ids) AS id_obat
    ORDER BY id_obat
  LOOP
    IF v_id IS NOT NULL AND v_id > 0 THEN
      PERFORM public.fn_recalculate_obat_stok_single(v_id);
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_insert_atomic(
  p_tanggal_terjual date,
  p_no_etalase text,
  p_keterangan text,
  p_id_admin bigint,
  p_items jsonb
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_terjual bigint;
  v_item_count integer;
  v_affected_ids bigint[];
BEGIN
  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'items transaksi keluar wajib minimal 1 baris';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS i(
      id_obat bigint,
      jumlah integer,
      harga_satuan numeric
    )
    WHERE COALESCE(i.id_obat, 0) <= 0
       OR COALESCE(i.jumlah, 0) <= 0
       OR i.harga_satuan IS NULL
       OR i.harga_satuan < 0
  ) THEN
    RAISE EXCEPTION 'data item transaksi keluar tidak valid';
  END IF;

  -- Guard oversell: setiap item dicek terhadap stok_saat_ini terkini.
  -- Jika salah satu item qty > stok tersedia, transaksi ditolak.
  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS i(id_obat bigint, jumlah integer)
    JOIN public.obat o ON o.id_obat = i.id_obat
    WHERE i.jumlah > o.stok_saat_ini
  ) THEN
    RAISE EXCEPTION USING
      MESSAGE = 'oversell: qty melebihi stok tersedia',
      HINT = 'CHECK_STOCK_FAILED';
  END IF;

  SELECT COUNT(*)
  INTO v_item_count
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  IF COALESCE(v_item_count, 0) <= 0 THEN
    RAISE EXCEPTION 'items transaksi keluar wajib minimal 1 baris';
  END IF;

  INSERT INTO public.obat_keluar (
    tanggal_terjual,
    no_etalase,
    keterangan,
    id_admin
  )
  VALUES (
    p_tanggal_terjual,
    NULLIF(BTRIM(COALESCE(p_no_etalase, '')), ''),
    NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    p_id_admin
  )
  RETURNING id_terjual INTO v_id_terjual;

  INSERT INTO public.obat_keluar_item (
    id_terjual,
    id_obat,
    jumlah,
    harga_satuan,
    is_legacy
  )
  SELECT
    v_id_terjual,
    i.id_obat,
    i.jumlah,
    i.harga_satuan,
    false
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  PERFORM public.fn_obat_keluar_refresh_totals(v_id_terjual);

  SELECT array_agg(DISTINCT i.id_obat)
  INTO v_affected_ids
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);

  RETURN v_id_terjual;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_update_atomic(
  p_id_terjual bigint,
  p_tanggal_terjual date,
  p_no_etalase text,
  p_keterangan text,
  p_id_admin bigint,
  p_items jsonb
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_ids bigint[];
  v_new_ids bigint[];
  v_affected_ids bigint[];
BEGIN
  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'items transaksi keluar wajib minimal 1 baris';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS i(
      id_obat bigint,
      jumlah integer,
      harga_satuan numeric
    )
    WHERE COALESCE(i.id_obat, 0) <= 0
       OR COALESCE(i.jumlah, 0) <= 0
       OR i.harga_satuan IS NULL
       OR i.harga_satuan < 0
  ) THEN
    RAISE EXCEPTION 'data item transaksi keluar tidak valid';
  END IF;

  PERFORM 1
  FROM public.obat_keluar
  WHERE id_terjual = p_id_terjual
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi tidak ditemukan: %', p_id_terjual;
  END IF;

  -- Guard oversell untuk UPDATE.
  -- Hitung qty lama per obat dari item lama transaksi ini, lalu
  -- pastikan qty baru <= (stok_saat_ini + old_qty) agar tidak ada oversell bersih.
  -- Items baru yang belum ada di transaksi lama divalidasi terhadap stok_saat_ini langsung.
  IF EXISTS (
    WITH old_qty_per_obat AS (
      SELECT oki.id_obat, SUM(oki.jumlah)::integer AS old_qty
      FROM public.obat_keluar_item oki
      WHERE oki.id_terjual = p_id_terjual AND oki.is_legacy = false AND oki.id_obat IS NOT NULL
      GROUP BY oki.id_obat
    )
    SELECT 1
    FROM jsonb_to_recordset(p_items) AS ni(id_obat bigint, jumlah integer)
    JOIN public.obat o ON o.id_obat = ni.id_obat
    LEFT JOIN old_qty_per_obat oo ON oo.id_obat = ni.id_obat
    WHERE ni.jumlah > (o.stok_saat_ini + COALESCE(oo.old_qty, 0))
  ) THEN
    RAISE EXCEPTION USING
      MESSAGE = 'oversell: qty melebihi stok tersedia saat update',
      HINT = 'CHECK_STOCK_FAILED';
  END IF;

  SELECT array_agg(DISTINCT oki.id_obat)
  INTO v_old_ids
  FROM public.obat_keluar_item oki
  WHERE oki.id_terjual = p_id_terjual
    AND oki.is_legacy = false
    AND oki.id_obat IS NOT NULL;

  UPDATE public.obat_keluar
  SET
    tanggal_terjual = p_tanggal_terjual,
    no_etalase = NULLIF(BTRIM(COALESCE(p_no_etalase, '')), ''),
    keterangan = NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    id_admin = p_id_admin
  WHERE id_terjual = p_id_terjual;

  DELETE FROM public.obat_keluar_item
  WHERE id_terjual = p_id_terjual;

  INSERT INTO public.obat_keluar_item (
    id_terjual,
    id_obat,
    jumlah,
    harga_satuan,
    is_legacy
  )
  SELECT
    p_id_terjual,
    i.id_obat,
    i.jumlah,
    i.harga_satuan,
    false
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  PERFORM public.fn_obat_keluar_refresh_totals(p_id_terjual);

  SELECT array_agg(DISTINCT i.id_obat)
  INTO v_new_ids
  FROM jsonb_to_recordset(p_items) AS i(
    id_obat bigint,
    jumlah integer,
    harga_satuan numeric
  );

  SELECT array_agg(DISTINCT x.id_obat)
  INTO v_affected_ids
  FROM (
    SELECT unnest(COALESCE(v_old_ids, ARRAY[]::bigint[])) AS id_obat
    UNION ALL
    SELECT unnest(COALESCE(v_new_ids, ARRAY[]::bigint[])) AS id_obat
  ) x
  WHERE x.id_obat IS NOT NULL;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_delete_atomic(
  p_id_terjual bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  PERFORM 1
  FROM public.obat_keluar
  WHERE id_terjual = p_id_terjual
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi tidak ditemukan: %', p_id_terjual;
  END IF;

  SELECT array_agg(DISTINCT oki.id_obat)
  INTO v_affected_ids
  FROM public.obat_keluar_item oki
  WHERE oki.id_terjual = p_id_terjual
    AND oki.is_legacy = false
    AND oki.id_obat IS NOT NULL;

  DELETE FROM public.obat_keluar
  WHERE id_terjual = p_id_terjual;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_keluar_delete_by_tanggal_atomic(
  p_tanggal_terjual date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  SELECT array_agg(DISTINCT oki.id_obat)
  INTO v_affected_ids
  FROM public.obat_keluar ok
  JOIN public.obat_keluar_item oki
    ON oki.id_terjual = ok.id_terjual
  WHERE ok.tanggal_terjual = p_tanggal_terjual
    AND oki.is_legacy = false
    AND oki.id_obat IS NOT NULL;

  DELETE FROM public.obat_keluar
  WHERE tanggal_terjual = p_tanggal_terjual;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_insert_atomic(
  p_id_obat bigint,
  p_tanggal_masuk date,
  p_jumlah_masuk integer,
  p_keterangan text,
  p_id_admin bigint
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_masuk bigint;
BEGIN
  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_masuk IS NULL THEN
    RAISE EXCEPTION 'tanggal_masuk wajib diisi';
  END IF;

  IF COALESCE(p_jumlah_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'jumlah_masuk harus lebih dari 0';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  INSERT INTO public.obat_masuk (
    id_obat,
    tanggal_masuk,
    jumlah_masuk,
    keterangan,
    id_admin
  )
  VALUES (
    p_id_obat,
    p_tanggal_masuk,
    p_jumlah_masuk,
    NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    p_id_admin
  )
  RETURNING id_masuk INTO v_id_masuk;

  PERFORM public.fn_recalculate_obat_stok_single(p_id_obat);

  RETURN v_id_masuk;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_update_atomic(
  p_id_masuk bigint,
  p_id_obat bigint,
  p_tanggal_masuk date,
  p_jumlah_masuk integer,
  p_keterangan text,
  p_id_admin bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_id_obat bigint;
  v_affected_ids bigint[];
BEGIN
  IF COALESCE(p_id_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'id_masuk tidak valid';
  END IF;

  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_masuk IS NULL THEN
    RAISE EXCEPTION 'tanggal_masuk wajib diisi';
  END IF;

  IF COALESCE(p_jumlah_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'jumlah_masuk harus lebih dari 0';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  SELECT om.id_obat
  INTO v_old_id_obat
  FROM public.obat_masuk om
  WHERE om.id_masuk = p_id_masuk
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi obat masuk tidak ditemukan: %', p_id_masuk;
  END IF;

  UPDATE public.obat_masuk
  SET
    id_obat = p_id_obat,
    tanggal_masuk = p_tanggal_masuk,
    jumlah_masuk = p_jumlah_masuk,
    keterangan = NULLIF(BTRIM(COALESCE(p_keterangan, '')), ''),
    id_admin = p_id_admin
  WHERE id_masuk = p_id_masuk;

  SELECT array_agg(DISTINCT x.id_obat)
  INTO v_affected_ids
  FROM (
    SELECT v_old_id_obat AS id_obat
    UNION ALL
    SELECT p_id_obat AS id_obat
  ) x
  WHERE x.id_obat IS NOT NULL;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_delete_atomic(
  p_id_masuk bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_obat bigint;
BEGIN
  IF COALESCE(p_id_masuk, 0) <= 0 THEN
    RAISE EXCEPTION 'id_masuk tidak valid';
  END IF;

  SELECT om.id_obat
  INTO v_id_obat
  FROM public.obat_masuk om
  WHERE om.id_masuk = p_id_masuk
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'transaksi obat masuk tidak ditemukan: %', p_id_masuk;
  END IF;

  DELETE FROM public.obat_masuk
  WHERE id_masuk = p_id_masuk;

  PERFORM public.fn_recalculate_obat_stok_single(v_id_obat);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_delete_by_tanggal_atomic(
  p_tanggal_masuk date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  IF p_tanggal_masuk IS NULL THEN
    RAISE EXCEPTION 'tanggal_masuk wajib diisi';
  END IF;

  SELECT array_agg(DISTINCT om.id_obat)
  INTO v_affected_ids
  FROM public.obat_masuk om
  WHERE om.tanggal_masuk = p_tanggal_masuk
    AND om.id_obat IS NOT NULL;

  DELETE FROM public.obat_masuk
  WHERE tanggal_masuk = p_tanggal_masuk;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_insert_atomic(
  p_id_obat bigint,
  p_tanggal_opname date,
  p_stok_sistem integer,
  p_stok_fisik integer,
  p_alasan_penyesuaian text,
  p_id_admin bigint
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_opname bigint;
BEGIN
  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_opname IS NULL THEN
    RAISE EXCEPTION 'tanggal_opname wajib diisi';
  END IF;

  IF COALESCE(p_stok_sistem, -1) < 0 THEN
    RAISE EXCEPTION 'stok_sistem tidak valid';
  END IF;

  IF COALESCE(p_stok_fisik, -1) < 0 THEN
    RAISE EXCEPTION 'stok_fisik tidak valid';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  INSERT INTO public.stock_opname (
    id_obat,
    tanggal_opname,
    stok_sistem,
    stok_fisik,
    selisih,
    alasan_penyesuaian,
    id_admin
  )
  VALUES (
    p_id_obat,
    p_tanggal_opname,
    p_stok_sistem,
    p_stok_fisik,
    p_stok_fisik - p_stok_sistem,
    NULLIF(BTRIM(COALESCE(p_alasan_penyesuaian, '')), ''),
    p_id_admin
  )
  RETURNING id_opname INTO v_id_opname;

  PERFORM public.fn_recalculate_obat_stok_single(p_id_obat);

  RETURN v_id_opname;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_update_atomic(
  p_id_opname bigint,
  p_id_obat bigint,
  p_tanggal_opname date,
  p_stok_sistem integer,
  p_stok_fisik integer,
  p_alasan_penyesuaian text,
  p_id_admin bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_id_obat bigint;
  v_affected_ids bigint[];
BEGIN
  IF COALESCE(p_id_opname, 0) <= 0 THEN
    RAISE EXCEPTION 'id_opname tidak valid';
  END IF;

  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  IF p_tanggal_opname IS NULL THEN
    RAISE EXCEPTION 'tanggal_opname wajib diisi';
  END IF;

  IF COALESCE(p_stok_sistem, -1) < 0 THEN
    RAISE EXCEPTION 'stok_sistem tidak valid';
  END IF;

  IF COALESCE(p_stok_fisik, -1) < 0 THEN
    RAISE EXCEPTION 'stok_fisik tidak valid';
  END IF;

  IF COALESCE(p_id_admin, 0) <= 0 THEN
    RAISE EXCEPTION 'id_admin tidak valid';
  END IF;

  SELECT so.id_obat
  INTO v_old_id_obat
  FROM public.stock_opname so
  WHERE so.id_opname = p_id_opname
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'stock opname tidak ditemukan: %', p_id_opname;
  END IF;

  UPDATE public.stock_opname
  SET
    id_obat = p_id_obat,
    tanggal_opname = p_tanggal_opname,
    stok_sistem = p_stok_sistem,
    stok_fisik = p_stok_fisik,
    selisih = p_stok_fisik - p_stok_sistem,
    alasan_penyesuaian = NULLIF(BTRIM(COALESCE(p_alasan_penyesuaian, '')), ''),
    id_admin = p_id_admin
  WHERE id_opname = p_id_opname;

  SELECT array_agg(DISTINCT x.id_obat)
  INTO v_affected_ids
  FROM (
    SELECT v_old_id_obat AS id_obat
    UNION ALL
    SELECT p_id_obat AS id_obat
  ) x
  WHERE x.id_obat IS NOT NULL;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_delete_atomic(
  p_id_opname bigint
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_id_obat bigint;
BEGIN
  IF COALESCE(p_id_opname, 0) <= 0 THEN
    RAISE EXCEPTION 'id_opname tidak valid';
  END IF;

  SELECT so.id_obat
  INTO v_id_obat
  FROM public.stock_opname so
  WHERE so.id_opname = p_id_opname
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'stock opname tidak ditemukan: %', p_id_opname;
  END IF;

  DELETE FROM public.stock_opname
  WHERE id_opname = p_id_opname;

  PERFORM public.fn_recalculate_obat_stok_single(v_id_obat);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(
  p_tanggal_opname date
) RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  IF p_tanggal_opname IS NULL THEN
    RAISE EXCEPTION 'tanggal_opname wajib diisi';
  END IF;

  SELECT array_agg(DISTINCT so.id_obat)
  INTO v_affected_ids
  FROM public.stock_opname so
  WHERE so.tanggal_opname = p_tanggal_opname
    AND so.id_obat IS NOT NULL;

  DELETE FROM public.stock_opname
  WHERE tanggal_opname = p_tanggal_opname;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_delete_if_unused(
  p_id_obat bigint
) RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_used_in_obat_masuk boolean;
  v_used_in_obat_keluar_item boolean;
  v_used_in_stock_opname boolean;
BEGIN
  IF COALESCE(p_id_obat, 0) <= 0 THEN
    RAISE EXCEPTION 'id_obat tidak valid';
  END IF;

  PERFORM 1
  FROM public.obat
  WHERE id_obat = p_id_obat
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'obat tidak ditemukan: %', p_id_obat;
  END IF;

  SELECT EXISTS(
      SELECT 1
      FROM public.obat_masuk om
      WHERE om.id_obat = p_id_obat
    ),
    EXISTS(
      SELECT 1
      FROM public.obat_keluar_item oki
      WHERE oki.id_obat = p_id_obat
    ),
    EXISTS(
      SELECT 1
      FROM public.stock_opname so
      WHERE so.id_obat = p_id_obat
    )
  INTO
    v_used_in_obat_masuk,
    v_used_in_obat_keluar_item,
    v_used_in_stock_opname;

  IF v_used_in_obat_masuk
     OR v_used_in_obat_keluar_item
     OR v_used_in_stock_opname THEN
    RETURN jsonb_build_object(
      'deleted', false,
      'used_in_obat_masuk', v_used_in_obat_masuk,
      'used_in_obat_keluar_item', v_used_in_obat_keluar_item,
      'used_in_stock_opname', v_used_in_stock_opname
    );
  END IF;

  DELETE FROM public.obat
  WHERE id_obat = p_id_obat;

  RETURN jsonb_build_object(
    'deleted', true,
    'used_in_obat_masuk', false,
    'used_in_obat_keluar_item', false,
    'used_in_stock_opname', false
  );
END;
$$;

-- Legacy cleanup:
-- kontrak delete pasien lama (`fn_pasien_delete_if_unused`) sudah tidak dipakai
-- aplikasi. Baseline final hanya memakai `fn_pasien_delete_and_renumber`.
DROP FUNCTION IF EXISTS public.fn_pasien_delete_if_unused(bigint);

CREATE OR REPLACE FUNCTION public.fn_pasien_delete_and_renumber(
  p_id_pasien bigint
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next_nomor integer;
BEGIN
  IF COALESCE(p_id_pasien, 0) <= 0 THEN
    RAISE EXCEPTION 'id_pasien tidak valid';
  END IF;

  PERFORM 1
  FROM public.pasien
  WHERE id_pasien = p_id_pasien
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pasien tidak ditemukan: %', p_id_pasien;
  END IF;

  -- ON DELETE CASCADE pada kehadiran_pasien adalah kontrak final:
  -- hapus pasien akan sekaligus menghapus histori kehadirannya.
  DELETE FROM public.pasien
  WHERE id_pasien = p_id_pasien;

  SELECT COUNT(*) + 1
  INTO v_next_nomor
  FROM public.pasien;

  -- Renumber nomor_pasien agar tetap rapat 1..N
  UPDATE public.pasien AS p
  SET nomor_pasien = new_nomor.new_nomor::varchar
  FROM (
    SELECT id_pasien, ROW_NUMBER() OVER (ORDER BY id_pasien ASC) AS new_nomor
    FROM public.pasien
  ) AS new_nomor
  WHERE new_nomor.id_pasien = p.id_pasien;

  RETURN jsonb_build_object(
    'deleted', true,
    'next_nomor', v_next_nomor
  );
END;
$$;

-- =========================
-- ACCESS CONTROL MODEL
-- =========================
-- Aplikasi ini menggunakan model single-clinic, single-tenant.
-- Role yang ada: 'petugas' (staff) dan 'kepala_klinik' (supervisor).
--
-- Primary security layer: RPC functions di aplikasi (Dart)
--   → AdminSession.getCurrentId() memvalidasi auth session
--   → Semua mutation lewat RPC yang menerima p_id_admin dari session
--
-- Secondary / defense-in-depth layer: RLS policies di bawah
--   → Melindungi akses PostgREST langsung
--   → Tidak sebagai satu-satunya enforcement point
--
-- Model akses data:
--   • admin          → hanya row milik user sendiri (auth_user_id match)
--   • obat           → semua authenticated user (data bersama klinik)
--   • obat_masuk     → semua authenticated user
--   • obat_keluar    → semua authenticated user
--   • obat_keluar_item → semua authenticated user
--   • stock_opname   → semua authenticated user
--   • pasien         → semua authenticated user
--   • kehadiran_pasien → semua authenticated user
--   • transaksi      → semua authenticated user (steady-state: RPC/application-level enforcement)
--   • transaksi_item → semua authenticated user
--   • kunjungan_pasien → semua authenticated user
--
-- Future enhancements:
--   → Role-based restrictions (petugas vs kepala_klinik)
--   → Row-level isolation antar klinik (multi-tenant)
--   → Audit log per-user

-- =========================
-- HELPER: get auth admin id
-- =========================
-- Mengembalikan id_admin dari user yang sedang login.
-- Return NULL jika tidak ada session atau tidak ada mapping.
-- Dapat dipanggil dari RLS policy context (security definer).
--
-- Penggunaan di RLS:
--   get_auth_admin_id() = o.id_admin   → hanya baris miliknya
--   get_auth_admin_id() IS NOT NULL    → user terautentikasi

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

-- ============================================================
-- RLS POLICIES
-- ============================================================
-- Catatan penting:
-- - INSERT melalui RPC functions (fn_*_insert_atomic) melewati WITH CHECK.
--   RLS INSERT/SELECT berlaku hanya untuk akses PostgREST langsung.
-- - Semua policy menggunakan auth.uid() bukan auth.jwt() untuk kejelasan.

ALTER TABLE public.admin ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat_masuk ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat_keluar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat_keluar_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_opname ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pasien ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kehadiran_pasien ENABLE ROW LEVEL SECURITY;

-- admin: hanya profile milik user sendiri
DROP POLICY IF EXISTS "admin read own row" ON public.admin;
CREATE POLICY "admin read own row"
  ON public.admin
  FOR SELECT
  TO authenticated
  USING (auth.uid() = admin.auth_user_id);

-- obat: semua authenticated user (data bersama klinik)
DROP POLICY IF EXISTS "authenticated can read obat" ON public.obat;
CREATE POLICY "authenticated can read obat"
  ON public.obat
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert obat" ON public.obat;
CREATE POLICY "authenticated can insert obat"
  ON public.obat
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update obat" ON public.obat;
CREATE POLICY "authenticated can update obat"
  ON public.obat
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- obat_masuk: semua authenticated user
DROP POLICY IF EXISTS "authenticated can read obat_masuk" ON public.obat_masuk;
CREATE POLICY "authenticated can read obat_masuk"
  ON public.obat_masuk
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert obat_masuk" ON public.obat_masuk;
CREATE POLICY "authenticated can insert obat_masuk"
  ON public.obat_masuk
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update obat_masuk" ON public.obat_masuk;
CREATE POLICY "authenticated can update obat_masuk"
  ON public.obat_masuk
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- obat_keluar: semua authenticated user
DROP POLICY IF EXISTS "authenticated can read obat_keluar" ON public.obat_keluar;
CREATE POLICY "authenticated can read obat_keluar"
  ON public.obat_keluar
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert obat_keluar" ON public.obat_keluar;
CREATE POLICY "authenticated can insert obat_keluar"
  ON public.obat_keluar
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update obat_keluar" ON public.obat_keluar;
CREATE POLICY "authenticated can update obat_keluar"
  ON public.obat_keluar
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- obat_keluar_item: semua authenticated user
DROP POLICY IF EXISTS "authenticated can read obat_keluar_item" ON public.obat_keluar_item;
CREATE POLICY "authenticated can read obat_keluar_item"
  ON public.obat_keluar_item
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert obat_keluar_item" ON public.obat_keluar_item;
CREATE POLICY "authenticated can insert obat_keluar_item"
  ON public.obat_keluar_item
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update obat_keluar_item" ON public.obat_keluar_item;
CREATE POLICY "authenticated can update obat_keluar_item"
  ON public.obat_keluar_item
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- stock_opname: semua authenticated user
DROP POLICY IF EXISTS "authenticated can read stock_opname" ON public.stock_opname;
CREATE POLICY "authenticated can read stock_opname"
  ON public.stock_opname
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert stock_opname" ON public.stock_opname;
CREATE POLICY "authenticated can insert stock_opname"
  ON public.stock_opname
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update stock_opname" ON public.stock_opname;
CREATE POLICY "authenticated can update stock_opname"
  ON public.stock_opname
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- pasien: semua authenticated user
DROP POLICY IF EXISTS "authenticated can read pasien" ON public.pasien;
CREATE POLICY "authenticated can read pasien"
  ON public.pasien
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert pasien" ON public.pasien;
CREATE POLICY "authenticated can insert pasien"
  ON public.pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update pasien" ON public.pasien;
CREATE POLICY "authenticated can update pasien"
  ON public.pasien
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- kehadiran_pasien: semua authenticated user
DROP POLICY IF EXISTS "authenticated can read kehadiran_pasien" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can read kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert kehadiran_pasien" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can insert kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update kehadiran_pasien" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can update kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- transaksi: semua authenticated user (INSERT/UPDATE via Supabase client)
ALTER TABLE public.transaksi ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can read transaksi" ON public.transaksi;
CREATE POLICY "authenticated can read transaksi"
  ON public.transaksi
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert transaksi" ON public.transaksi;
CREATE POLICY "authenticated can insert transaksi"
  ON public.transaksi
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update transaksi" ON public.transaksi;
CREATE POLICY "authenticated can update transaksi"
  ON public.transaksi
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- transaksi_item: semua authenticated user
ALTER TABLE public.transaksi_item ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can read transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can read transaksi_item"
  ON public.transaksi_item
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can insert transaksi_item"
  ON public.transaksi_item
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can update transaksi_item"
  ON public.transaksi_item
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- kunjungan_pasien: semua authenticated user (owner-only di aplikasi, RLS defense-in-depth)
ALTER TABLE public.kunjungan_pasien ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can read kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can read kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can insert kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can insert kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can update kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can update kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR UPDATE
  TO authenticated
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "authenticated can delete kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can delete kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR DELETE
  TO authenticated
  USING (auth.uid() IS NOT NULL);

-- =========================
-- GRANTS
-- =========================

GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_refresh_totals(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_recalculate_obat_stok_single(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_recalculate_obat_stok_bulk(bigint[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_insert_atomic(date, text, text, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_update_atomic(bigint, date, text, text, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_delete_by_tanggal_atomic(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_insert_atomic(bigint, date, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_update_atomic(bigint, bigint, date, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_by_tanggal_atomic(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_insert_atomic(bigint, date, integer, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_update_atomic(bigint, bigint, date, integer, integer, text, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_delete_if_unused(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_pasien_delete_and_renumber(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_auth_admin_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_kurangi_stok(int, int) TO authenticated;

-- =========================
-- STORAGE: FOTO OBAT
-- =========================
-- Bucket publik untuk identitas visual obat pada Master Obat.
-- Batas upload:
-- - max file size: 5 MB
-- - mime type: image/jpeg, image/png, image/webp

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
