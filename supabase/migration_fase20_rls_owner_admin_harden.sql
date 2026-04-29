-- ============================================================
-- FASE 20 / P1: RLS owner/admin hardening
--
-- Safe for existing data:
-- - No DROP table/data.
-- - No RPC rename.
-- - Replaces policies and selected RPC bodies only.
--
-- Role model:
-- - kepala_klinik (owner): full operational access and report access.
-- - petugas: daily operational access.
-- - Report pages currently aggregate operational tables in Flutter, so there
--   is no separate report table/view to lock at DB level yet.
-- ============================================================

-- ============================================================
-- A. Role helpers
-- ============================================================

CREATE OR REPLACE FUNCTION public.current_admin_id()
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT a.id_admin
  FROM public.admin AS a
  WHERE a.auth_user_id = auth.uid()
  LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.current_admin_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT a.role
  FROM public.admin AS a
  WHERE a.auth_user_id = auth.uid()
    AND a.role IN ('petugas', 'kepala_klinik')
  LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.get_auth_admin_id()
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.current_admin_id()
$$;

CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.current_admin_role() = 'kepala_klinik'
$$;

CREATE OR REPLACE FUNCTION public.is_petugas()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.current_admin_role() = 'petugas'
$$;

CREATE OR REPLACE FUNCTION public.is_clinic_staff()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.current_admin_role() IN ('petugas', 'kepala_klinik')
$$;

CREATE OR REPLACE FUNCTION public.can_view_laporan()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.is_owner()
$$;

CREATE OR REPLACE FUNCTION public.require_clinic_staff(
  p_expected_admin_id bigint DEFAULT NULL
) RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
  v_admin_id bigint;
BEGIN
  v_admin_id := public.current_admin_id();

  IF v_admin_id IS NULL OR NOT public.is_clinic_staff() THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'akses ditolak: admin login tidak valid';
  END IF;

  IF p_expected_admin_id IS NOT NULL
     AND (p_expected_admin_id <= 0 OR p_expected_admin_id <> v_admin_id) THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'akses ditolak: id_admin tidak sesuai user login';
  END IF;

  RETURN v_admin_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.current_admin_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_admin_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_auth_admin_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_owner() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_petugas() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_clinic_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_view_laporan() TO authenticated;
GRANT EXECUTE ON FUNCTION public.require_clinic_staff(bigint) TO authenticated;

-- ============================================================
-- B. Role-aware RLS policies
-- ============================================================

ALTER TABLE public.admin ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat_masuk ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat_keluar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.obat_keluar_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sinkronisasi_stok ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pasien ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kehadiran_pasien ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaksi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaksi_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kunjungan_pasien ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can read admin" ON public.admin;
DROP POLICY IF EXISTS "admin read own row" ON public.admin;
DROP POLICY IF EXISTS "clinic staff can read admin" ON public.admin;
CREATE POLICY "clinic staff can read admin"
  ON public.admin
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "owner can insert admin" ON public.admin;
CREATE POLICY "owner can insert admin"
  ON public.admin
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_owner());

DROP POLICY IF EXISTS "owner can update admin" ON public.admin;
CREATE POLICY "owner can update admin"
  ON public.admin
  FOR UPDATE
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

DROP POLICY IF EXISTS "owner can delete admin" ON public.admin;
CREATE POLICY "owner can delete admin"
  ON public.admin
  FOR DELETE
  TO authenticated
  USING (public.is_owner());

DROP POLICY IF EXISTS "authenticated can manage obat" ON public.obat;
DROP POLICY IF EXISTS "authenticated can read obat" ON public.obat;
CREATE POLICY "authenticated can read obat"
  ON public.obat
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert obat" ON public.obat;
CREATE POLICY "authenticated can insert obat"
  ON public.obat
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can update obat" ON public.obat;
CREATE POLICY "authenticated can update obat"
  ON public.obat
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can manage obat_masuk" ON public.obat_masuk;
DROP POLICY IF EXISTS "authenticated can read obat_masuk" ON public.obat_masuk;
CREATE POLICY "authenticated can read obat_masuk"
  ON public.obat_masuk
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert obat_masuk" ON public.obat_masuk;
CREATE POLICY "authenticated can insert obat_masuk"
  ON public.obat_masuk
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update obat_masuk" ON public.obat_masuk;
CREATE POLICY "authenticated can update obat_masuk"
  ON public.obat_masuk
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can manage obat_keluar" ON public.obat_keluar;
DROP POLICY IF EXISTS "authenticated can read obat_keluar" ON public.obat_keluar;
CREATE POLICY "authenticated can read obat_keluar"
  ON public.obat_keluar
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert obat_keluar" ON public.obat_keluar;
CREATE POLICY "authenticated can insert obat_keluar"
  ON public.obat_keluar
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update obat_keluar" ON public.obat_keluar;
CREATE POLICY "authenticated can update obat_keluar"
  ON public.obat_keluar
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can manage obat_keluar_item" ON public.obat_keluar_item;
DROP POLICY IF EXISTS "authenticated can read obat_keluar_item" ON public.obat_keluar_item;
CREATE POLICY "authenticated can read obat_keluar_item"
  ON public.obat_keluar_item
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert obat_keluar_item" ON public.obat_keluar_item;
CREATE POLICY "authenticated can insert obat_keluar_item"
  ON public.obat_keluar_item
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can update obat_keluar_item" ON public.obat_keluar_item;
CREATE POLICY "authenticated can update obat_keluar_item"
  ON public.obat_keluar_item
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can manage sinkronisasi_stok" ON public.sinkronisasi_stok;
DROP POLICY IF EXISTS "authenticated can read sinkronisasi_stok" ON public.sinkronisasi_stok;
CREATE POLICY "authenticated can read sinkronisasi_stok"
  ON public.sinkronisasi_stok
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert sinkronisasi_stok" ON public.sinkronisasi_stok;
CREATE POLICY "authenticated can insert sinkronisasi_stok"
  ON public.sinkronisasi_stok
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update sinkronisasi_stok" ON public.sinkronisasi_stok;
CREATE POLICY "authenticated can update sinkronisasi_stok"
  ON public.sinkronisasi_stok
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can manage pasien" ON public.pasien;
DROP POLICY IF EXISTS "authenticated can read pasien" ON public.pasien;
CREATE POLICY "authenticated can read pasien"
  ON public.pasien
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert pasien" ON public.pasien;
CREATE POLICY "authenticated can insert pasien"
  ON public.pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can update pasien" ON public.pasien;
CREATE POLICY "authenticated can update pasien"
  ON public.pasien
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can manage kehadiran" ON public.kehadiran_pasien;
DROP POLICY IF EXISTS "authenticated can read kehadiran_pasien" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can read kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert kehadiran_pasien" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can insert kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update kehadiran_pasien" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can update kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can delete kehadiran_pasien" ON public.kehadiran_pasien;
CREATE POLICY "authenticated can delete kehadiran_pasien"
  ON public.kehadiran_pasien
  FOR DELETE
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "guest_cannot_access_transaksi" ON public.transaksi;
DROP POLICY IF EXISTS "authenticated can read transaksi" ON public.transaksi;
CREATE POLICY "authenticated can read transaksi"
  ON public.transaksi
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert transaksi" ON public.transaksi;
CREATE POLICY "authenticated can insert transaksi"
  ON public.transaksi
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update transaksi" ON public.transaksi;
CREATE POLICY "authenticated can update transaksi"
  ON public.transaksi
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "guest_cannot_access_transaksi_item" ON public.transaksi_item;
DROP POLICY IF EXISTS "authenticated can read transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can read transaksi_item"
  ON public.transaksi_item
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can insert transaksi_item"
  ON public.transaksi_item
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can update transaksi_item"
  ON public.transaksi_item
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can read kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can read kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can insert kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can update kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR UPDATE
  TO authenticated
  USING (public.is_clinic_staff())
  WITH CHECK (public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can delete kunjungan_pasien" ON public.kunjungan_pasien;
CREATE POLICY "authenticated can delete kunjungan_pasien"
  ON public.kunjungan_pasien
  FOR DELETE
  TO authenticated
  USING (public.is_clinic_staff());

-- Storage: read remains public; writes require a mapped clinic staff user.
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
  WITH CHECK (bucket_id = 'obat-images' AND public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated update obat-images" ON storage.objects;
CREATE POLICY "authenticated update obat-images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'obat-images' AND public.is_clinic_staff())
  WITH CHECK (bucket_id = 'obat-images' AND public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated delete obat-images" ON storage.objects;
CREATE POLICY "authenticated delete obat-images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'obat-images' AND public.is_clinic_staff());

-- ============================================================
-- C. SECURITY DEFINER RPC validation
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_transaksi_insert(
  p_tanggal            date,
  p_jenis_transaksi    varchar(30),
  p_total              numeric(12, 2),
  p_metode_bayar       varchar(20),
  p_id_pasien          bigint,
  p_keterangan         text,
  p_durasi_harian      int,
  p_id_admin           bigint,
  p_items              jsonb DEFAULT '[]'::jsonb
)
RETURNS SETOF public.transaksi
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaksi       public.transaksi%ROWTYPE;
  v_item            jsonb;
  v_id_obat         int;
  v_jumlah          int;
  v_harga           numeric(12, 2);
  v_subtotal        numeric(12, 2);
  v_satuan_terjual  varchar(30);
BEGIN
  PERFORM public.require_clinic_staff(p_id_admin);

  INSERT INTO public.transaksi (
    tanggal, jenis_transaksi, total, metode_bayar,
    id_pasien, keterangan, durasi_harian, id_admin
  )
  VALUES (
    p_tanggal, p_jenis_transaksi, p_total, p_metode_bayar,
    p_id_pasien, p_keterangan, p_durasi_harian, p_id_admin
  )
  RETURNING * INTO v_transaksi;

  IF p_jenis_transaksi = 'obat_ready_stock'
     AND jsonb_typeof(p_items) = 'array'
     AND jsonb_array_length(p_items) > 0 THEN

    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(p_items) AS i(id_obat bigint, jumlah integer)
      JOIN public.obat o ON o.id_obat = i.id_obat
      WHERE i.jumlah > o.stok_saat_ini
    ) THEN
      RAISE EXCEPTION USING
        MESSAGE = 'oversell: jumlah melebihi stok tersedia',
        HINT    = 'CHECK_STOCK_FAILED';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_id_obat        := (v_item->>'id_obat')::int;
      v_jumlah         := (v_item->>'jumlah')::int;
      v_harga          := (v_item->>'harga_satuan')::numeric(12, 2);
      v_subtotal       := (v_item->>'subtotal')::numeric(12, 2);
      v_satuan_terjual := NULLIF(BTRIM(v_item->>'satuan_terjual'), '');

      INSERT INTO public.transaksi_item (
        id_transaksi,
        id_obat,
        jumlah,
        harga_satuan,
        subtotal,
        satuan_terjual,
        id_admin
      )
      VALUES (
        v_transaksi.id_transaksi,
        v_id_obat,
        v_jumlah,
        v_harga,
        v_subtotal,
        v_satuan_terjual,
        p_id_admin
      );

      UPDATE public.obat
      SET stok_saat_ini = GREATEST(0, stok_saat_ini - v_jumlah)
      WHERE id_obat = v_id_obat;
    END LOOP;
  END IF;

  RETURN NEXT v_transaksi;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_kurangi_stok(
  p_id_obat  int,
  p_jumlah   int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_stok_sekarang integer;
BEGIN
  PERFORM public.require_clinic_staff();

  SELECT stok_saat_ini INTO v_stok_sekarang
  FROM public.obat
  WHERE id_obat = p_id_obat
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Obat dengan ID % tidak ditemukan', p_id_obat;
  END IF;

  IF p_jumlah > v_stok_sekarang THEN
    RAISE EXCEPTION USING
      MESSAGE = 'oversell: jumlah melebihi stok tersedia',
      HINT    = 'CHECK_STOCK_FAILED';
  END IF;

  UPDATE public.obat
  SET stok_saat_ini = GREATEST(0, stok_saat_ini - p_jumlah)
  WHERE id_obat = p_id_obat;
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
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_ids bigint[];
  v_new_ids bigint[];
  v_affected_ids bigint[];
BEGIN
  PERFORM public.require_clinic_staff(p_id_admin);

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

  IF EXISTS (
    WITH old_qty_per_obat AS (
      SELECT oki.id_obat, SUM(oki.jumlah)::integer AS old_qty
      FROM public.obat_keluar_item oki
      WHERE oki.id_terjual = p_id_terjual
        AND oki.is_legacy = false
        AND oki.id_obat IS NOT NULL
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
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  PERFORM public.require_clinic_staff();

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
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  PERFORM public.require_clinic_staff();

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

CREATE OR REPLACE FUNCTION public.fn_obat_masuk_delete_atomic(
  p_id_masuk bigint
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id_obat bigint;
BEGIN
  PERFORM public.require_clinic_staff();

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
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  PERFORM public.require_clinic_staff();

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

CREATE OR REPLACE FUNCTION public.fn_stock_opname_delete_atomic(
  p_id_opname bigint
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id_obat bigint;
BEGIN
  PERFORM public.require_clinic_staff();

  IF COALESCE(p_id_opname, 0) <= 0 THEN
    RAISE EXCEPTION 'id_opname tidak valid';
  END IF;

  SELECT so.id_obat
  INTO v_id_obat
  FROM public.sinkronisasi_stok so
  WHERE so.id_opname = p_id_opname
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'sinkronisasi stok tidak ditemukan: %', p_id_opname;
  END IF;

  DELETE FROM public.sinkronisasi_stok
  WHERE id_opname = p_id_opname;

  PERFORM public.fn_recalculate_obat_stok_single(v_id_obat);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(
  p_tanggal_opname date
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_affected_ids bigint[];
BEGIN
  PERFORM public.require_clinic_staff();

  IF p_tanggal_opname IS NULL THEN
    RAISE EXCEPTION 'tanggal_opname wajib diisi';
  END IF;

  SELECT array_agg(DISTINCT so.id_obat)
  INTO v_affected_ids
  FROM public.sinkronisasi_stok so
  WHERE so.tanggal_opname = p_tanggal_opname
    AND so.id_obat IS NOT NULL;

  DELETE FROM public.sinkronisasi_stok
  WHERE tanggal_opname = p_tanggal_opname;

  PERFORM public.fn_recalculate_obat_stok_bulk(v_affected_ids);
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_obat_delete_if_unused(
  p_id_obat bigint
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_used_in_obat_masuk boolean;
  v_used_in_obat_keluar_item boolean;
  v_used_in_sinkronisasi_stok boolean;
BEGIN
  PERFORM public.require_clinic_staff();

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
      FROM public.sinkronisasi_stok so
      WHERE so.id_obat = p_id_obat
    )
  INTO
    v_used_in_obat_masuk,
    v_used_in_obat_keluar_item,
    v_used_in_sinkronisasi_stok;

  IF v_used_in_obat_masuk
     OR v_used_in_obat_keluar_item
     OR v_used_in_sinkronisasi_stok THEN
    RETURN jsonb_build_object(
      'deleted', false,
      'used_in_obat_masuk', v_used_in_obat_masuk,
      'used_in_obat_keluar_item', v_used_in_obat_keluar_item,
      'used_in_sinkronisasi_stok', v_used_in_sinkronisasi_stok
    );
  END IF;

  DELETE FROM public.obat
  WHERE id_obat = p_id_obat;

  RETURN jsonb_build_object(
    'deleted', true,
    'used_in_obat_masuk', false,
    'used_in_obat_keluar_item', false,
    'used_in_sinkronisasi_stok', false
  );
END;
$$;

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
  PERFORM public.require_clinic_staff();

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

  DELETE FROM public.pasien
  WHERE id_pasien = p_id_pasien;

  SELECT COUNT(*) + 1
  INTO v_next_nomor
  FROM public.pasien;

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

GRANT EXECUTE ON FUNCTION public.fn_transaksi_insert(date, varchar, numeric, varchar, bigint, text, int, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_kurangi_stok(int, int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_update_atomic(bigint, date, text, text, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_keluar_delete_by_tanggal_atomic(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_masuk_delete_by_tanggal_atomic(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_atomic(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_stock_opname_delete_by_tanggal_atomic(date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_obat_delete_if_unused(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_pasien_delete_and_renumber(bigint) TO authenticated;
