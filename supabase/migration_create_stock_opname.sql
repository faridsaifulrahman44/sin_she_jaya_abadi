-- Migration: Create stock_opname table for physical inventory reconciliation
-- Run this migration in Supabase to enable stock opname feature.

CREATE TABLE IF NOT EXISTS public.stock_opname (
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
CREATE INDEX IF NOT EXISTS idx_stock_opname_tanggal ON public.stock_opname(tanggal_opname DESC);
CREATE INDEX IF NOT EXISTS idx_stock_opname_id_obat ON public.stock_opname(id_obat);

-- RLS
ALTER TABLE public.stock_opname ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "authenticated can manage stock_opname" ON public.stock_opname;
CREATE POLICY "authenticated can manage stock_opname" ON public.stock_opname
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
