-- ============================================================
-- FASE 2: TRANSAKSI / PEMBAYARAN
-- Project: Flutter Klinik
-- Target: Tabel transaksi, transaksi_item, dan kolom harga_jual di obat
-- ============================================================

-- ============================================================
-- KOLOM: harga_jual di tabel obat (sudah ada di schema.sql? jika belum, tambahkan)
-- ============================================================
-- Jika kolom ini belum ada di schema.sql baseline, kita tambahkan:
-- ALTER TABLE public.obat ADD COLUMN IF NOT EXISTS harga_jual numeric(12, 2) DEFAULT 0 CHECK (harga_jual >= 0);

-- ============================================================
-- TABEL: transaksi
-- Header transaksi klinik (ready stock / custom)
-- ============================================================
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

-- Index untuk filtering & sorting
CREATE INDEX IF NOT EXISTS idx_transaksi_tanggal ON public.transaksi(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_transaksi_jenis ON public.transaksi(jenis_transaksi);
CREATE INDEX IF NOT EXISTS idx_transaksi_pasien ON public.transaksi(id_pasien);

-- ============================================================
-- TABEL: transaksi_item
-- Item detail untuk transaksi ready stock
-- ============================================================
CREATE TABLE IF NOT EXISTS public.transaksi_item (
  id_item bigserial PRIMARY KEY,
  id_transaksi bigint NOT NULL REFERENCES public.transaksi(id_transaksi) ON DELETE CASCADE,
  id_obat bigint NOT NULL REFERENCES public.obat(id_obat),
  jumlah int NOT NULL CHECK (jumlah > 0),
  harga_satuan numeric(12, 2) NOT NULL CHECK (harga_satuan >= 0),
  subtotal numeric(12, 2) NOT NULL CHECK (subtotal >= 0),
  id_admin bigint REFERENCES public.admin(id_admin)
);

-- Index untuk join
CREATE INDEX IF NOT EXISTS idx_transaksi_item_transaksi ON public.transaksi_item(id_transaksi);
CREATE INDEX IF NOT EXISTS idx_transaksi_item_obat ON public.transaksi_item(id_obat);

-- ============================================================
-- FUNCTION: fn_transaksi_insert
-- Insert transaksi dengan item dan kurangi stok secara atomik
-- ============================================================
CREATE OR REPLACE FUNCTION fn_transaksi_insert(
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
AS $$
DECLARE
  v_transaksi public.transaksi%ROWTYPE;
  v_item jsonb;
  v_id_obat int;
  v_jumlah int;
  v_harga numeric(12, 2);
  v_subtotal numeric(12, 2);
BEGIN
  -- Insert header transaksi
  INSERT INTO public.transaksi (
    tanggal, jenis_transaksi, total, metode_bayar,
    id_pasien, keterangan, durasi_harian, id_admin
  )
  VALUES (
    p_tanggal, p_jenis_transaksi, p_total, p_metode_bayar,
    p_id_pasien, p_keterangan, p_durasi_harian, p_id_admin
  )
  RETURNING * INTO v_transaksi;

  -- Jika ready stock dan ada items, proses item & kurangi stok
  IF p_jenis_transaksi = 'obat_ready_stock' AND jsonb_typeof(p_items) = 'array' AND jsonb_array_length(p_items) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_id_obat := (v_item->>'id_obat')::int;
      v_jumlah := (v_item->>'jumlah')::int;
      v_harga := (v_item->>'harga_satuan')::numeric(12, 2);
      v_subtotal := (v_item->>'subtotal')::numeric(12, 2);

      -- Insert item
      INSERT INTO public.transaksi_item (
        id_transaksi, id_obat, jumlah, harga_satuan, subtotal, id_admin
      )
      VALUES (
        v_transaksi.id_transaksi, v_id_obat, v_jumlah, v_harga, v_subtotal, p_id_admin
      );

      -- Kurangi stok (langsung UPDATE, bukan RPC untuk simplicity)
      UPDATE public.obat
      SET stok_saat_ini = GREATEST(0, stok_saat_ini - v_jumlah)
      WHERE id_obat = v_id_obat;
    END LOOP;
  END IF;

  RETURN NEXT v_transaksi;
END;
$$;

-- ============================================================
-- FUNCTION: fn_obat_kurangi_stok
-- Kurangi stok obat (pakai ini dari Flutter jika RPC lain tidak tersedia)
-- ============================================================
CREATE OR REPLACE FUNCTION fn_obat_kurangi_stok(
  p_id_obat int,
  p_jumlah int
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.obat
  SET stok_saat_ini = GREATEST(0, stok_saat_ini - p_jumlah)
  WHERE id_obat = p_id_obat;
END;
$$;

-- ============================================================
-- RLS POLICIES (jika diperlukan)
-- ============================================================
-- Guest/anon tidak bisa akses
CREATE POLICY "guest_cannot_access_transaksi"
ON public.transaksi FOR ALL
USING (false)
WITH CHECK (false);

CREATE POLICY "guest_cannot_access_transaksi_item"
ON public.transaksi_item FOR ALL
USING (false)
WITH CHECK (false);

-- Enable Row Level Security
ALTER TABLE public.transaksi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaksi_item ENABLE ROW LEVEL SECURITY;