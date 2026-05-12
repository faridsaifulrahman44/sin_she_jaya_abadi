-- ============================================================
-- Migration: Stock movements ledger + atomic transaction RPC v2
-- Date: 2026-05-09
-- Scope:
--   1) Introduce stock_movements ledger (audit trail, reconciliation).
--   2) Introduce fn_create_transaction atomic RPC as canonical write path.
--   3) Keep fn_transaksi_insert for backward compatibility by delegating.
-- ============================================================

-- 1) STOCK MOVEMENTS LEDGER
CREATE TABLE IF NOT EXISTS public.stock_movements (
  id bigserial PRIMARY KEY,
  id_obat bigint NOT NULL REFERENCES public.obat(id_obat) ON DELETE RESTRICT,
  qty integer NOT NULL CHECK (qty > 0),
  movement_type varchar(20) NOT NULL
    CHECK (movement_type IN ('IN', 'OUT', 'ADJUSTMENT')),
  reference_type varchar(40),
  reference_id bigint,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by bigint NOT NULL REFERENCES public.admin(id_admin) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_stock_movements_id_obat_created_at
  ON public.stock_movements(id_obat, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_movements_reference
  ON public.stock_movements(reference_type, reference_id);

ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated can read stock_movements" ON public.stock_movements;
CREATE POLICY "authenticated can read stock_movements"
  ON public.stock_movements
  FOR SELECT
  TO authenticated
  USING (public.is_clinic_staff());

DROP POLICY IF EXISTS "authenticated can insert stock_movements" ON public.stock_movements;
CREATE POLICY "authenticated can insert stock_movements"
  ON public.stock_movements
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_admin_id() = created_by);

-- 2) ATOMIC TRANSACTION RPC V2
CREATE OR REPLACE FUNCTION public.fn_create_transaction(
  p_tanggal date,
  p_jenis_transaksi varchar(30),
  p_total numeric(12, 2),
  p_metode_bayar varchar(20),
  p_id_pasien bigint,
  p_keterangan text,
  p_durasi_harian int,
  p_id_admin bigint,
  p_items jsonb DEFAULT '[]'::jsonb
)
RETURNS SETOF public.transaksi
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_transaksi public.transaksi%ROWTYPE;
  v_item jsonb;
  v_id_obat bigint;
  v_jumlah integer;
  v_harga numeric(12, 2);
  v_subtotal numeric(12, 2);
  v_satuan_terjual varchar(30);
  v_row record;
BEGIN
  PERFORM public.require_clinic_staff(p_id_admin);

  IF p_total < 0 THEN
    RAISE EXCEPTION 'total transaksi tidak valid';
  END IF;

  IF p_jenis_transaksi = 'obat_ready_stock' THEN
    IF p_items IS NULL
       OR jsonb_typeof(p_items) <> 'array'
       OR jsonb_array_length(p_items) = 0 THEN
      RAISE EXCEPTION 'transaksi obat wajib memiliki minimal 1 item';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM jsonb_to_recordset(p_items) AS i(
        id_obat bigint,
        jumlah integer,
        harga_satuan numeric,
        subtotal numeric
      )
      WHERE COALESCE(i.id_obat, 0) <= 0
         OR COALESCE(i.jumlah, 0) <= 0
         OR i.harga_satuan IS NULL
         OR i.harga_satuan < 0
         OR i.subtotal IS NULL
         OR i.subtotal < 0
    ) THEN
      RAISE EXCEPTION 'item transaksi tidak valid';
    END IF;

    IF EXISTS (
      WITH grouped AS (
        SELECT id_obat, SUM(jumlah)::integer AS total_qty
        FROM jsonb_to_recordset(p_items) AS i(id_obat bigint, jumlah integer)
        GROUP BY id_obat
      )
      SELECT 1
      FROM grouped g
      LEFT JOIN public.obat o ON o.id_obat = g.id_obat
      WHERE o.id_obat IS NULL
    ) THEN
      RAISE EXCEPTION 'obat pada item transaksi tidak ditemukan';
    END IF;

    FOR v_row IN
      WITH grouped AS (
        SELECT id_obat, SUM(jumlah)::integer AS total_qty
        FROM jsonb_to_recordset(p_items) AS i(id_obat bigint, jumlah integer)
        GROUP BY id_obat
      )
      SELECT o.id_obat, o.stok_saat_ini, g.total_qty
      FROM grouped g
      JOIN public.obat o ON o.id_obat = g.id_obat
      FOR UPDATE OF o
    LOOP
      IF v_row.total_qty > v_row.stok_saat_ini THEN
        RAISE EXCEPTION USING
          MESSAGE = 'oversell: jumlah melebihi stok tersedia',
          HINT = 'CHECK_STOCK_FAILED';
      END IF;
    END LOOP;
  END IF;

  INSERT INTO public.transaksi (
    tanggal,
    jenis_transaksi,
    total,
    metode_bayar,
    id_pasien,
    keterangan,
    durasi_harian,
    id_admin
  ) VALUES (
    p_tanggal,
    p_jenis_transaksi,
    p_total,
    p_metode_bayar,
    p_id_pasien,
    p_keterangan,
    p_durasi_harian,
    p_id_admin
  )
  RETURNING * INTO v_transaksi;

  IF p_jenis_transaksi = 'obat_ready_stock' THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_id_obat := (v_item->>'id_obat')::bigint;
      v_jumlah := (v_item->>'jumlah')::integer;
      v_harga := (v_item->>'harga_satuan')::numeric(12, 2);
      v_subtotal := (v_item->>'subtotal')::numeric(12, 2);
      v_satuan_terjual := NULLIF(BTRIM(v_item->>'satuan_terjual'), '');

      INSERT INTO public.transaksi_item (
        id_transaksi,
        id_obat,
        jumlah,
        harga_satuan,
        subtotal,
        satuan_terjual,
        id_admin
      ) VALUES (
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

      INSERT INTO public.stock_movements (
        id_obat,
        qty,
        movement_type,
        reference_type,
        reference_id,
        created_by
      ) VALUES (
        v_id_obat,
        v_jumlah,
        'OUT',
        'transaksi',
        v_transaksi.id_transaksi,
        p_id_admin
      );
    END LOOP;
  END IF;

  RETURN NEXT v_transaksi;
END;
$$;

-- 3) BACKWARD-COMPAT ALIAS
CREATE OR REPLACE FUNCTION public.fn_transaksi_insert(
  p_tanggal date,
  p_jenis_transaksi varchar(30),
  p_total numeric(12, 2),
  p_metode_bayar varchar(20),
  p_id_pasien bigint,
  p_keterangan text,
  p_durasi_harian int,
  p_id_admin bigint,
  p_items jsonb DEFAULT '[]'::jsonb
)
RETURNS SETOF public.transaksi
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.fn_create_transaction(
    p_tanggal,
    p_jenis_transaksi,
    p_total,
    p_metode_bayar,
    p_id_pasien,
    p_keterangan,
    p_durasi_harian,
    p_id_admin,
    p_items
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_create_transaction(date, varchar, numeric, varchar, bigint, text, int, bigint, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.fn_transaksi_insert(date, varchar, numeric, varchar, bigint, text, int, bigint, jsonb) TO authenticated;
