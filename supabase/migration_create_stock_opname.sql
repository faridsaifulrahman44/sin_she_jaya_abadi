-- Migration: create physical inventory reconciliation table.
-- Historical file name uses "stock_opname", but the final table used by
-- Flutter and live Supabase is public.sinkronisasi_stok.

CREATE TABLE IF NOT EXISTS public.sinkronisasi_stok (
  id_opname bigserial primary key,
  id_obat bigint not null references public.obat(id_obat) on delete restrict,
  tanggal_opname date not null,
  stok_sistem integer not null default 0,
  stok_fisik integer not null default 0,
  selisih integer not null default 0,
  alasan_penyesuaian text,
  id_admin bigint not null references public.admin(id_admin) on delete restrict,
  created_at timestamptz not null default now()
);

-- Index for fast lookup by date and by obat
CREATE INDEX IF NOT EXISTS idx_sinkronisasi_stok_tanggal
  ON public.sinkronisasi_stok(tanggal_opname DESC);
CREATE INDEX IF NOT EXISTS idx_sinkronisasi_stok_id_obat
  ON public.sinkronisasi_stok(id_obat);

-- RLS
ALTER TABLE public.sinkronisasi_stok ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "authenticated can manage sinkronisasi_stok" ON public.sinkronisasi_stok;
CREATE POLICY "authenticated can manage sinkronisasi_stok" ON public.sinkronisasi_stok
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
