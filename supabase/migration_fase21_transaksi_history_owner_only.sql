-- ============================================================
-- FASE 21 / P2: Transaction history owner-only
--
-- Safe for existing data:
-- - No table/schema changes.
-- - Keeps fn_transaksi_insert as the official atomic insert path.
-- - Staff/petugas can still create transactions with their own id_admin.
-- - Transaction history SELECT is restricted to kepala_klinik/owner.
-- ============================================================

ALTER TABLE public.transaksi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaksi_item ENABLE ROW LEVEL SECURITY;

-- transaksi: owner-only history, staff insert via own id_admin, owner update.
DROP POLICY IF EXISTS "authenticated can read transaksi" ON public.transaksi;
CREATE POLICY "authenticated can read transaksi"
  ON public.transaksi
  FOR SELECT
  TO authenticated
  USING (public.is_owner());

DROP POLICY IF EXISTS "authenticated can insert transaksi" ON public.transaksi;
CREATE POLICY "authenticated can insert transaksi"
  ON public.transaksi
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_clinic_staff() AND public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update transaksi" ON public.transaksi;
CREATE POLICY "authenticated can update transaksi"
  ON public.transaksi
  FOR UPDATE
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

-- transaksi_item: owner-only history, staff insert via own id_admin, owner update.
DROP POLICY IF EXISTS "authenticated can read transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can read transaksi_item"
  ON public.transaksi_item
  FOR SELECT
  TO authenticated
  USING (public.is_owner());

DROP POLICY IF EXISTS "authenticated can insert transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can insert transaksi_item"
  ON public.transaksi_item
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_clinic_staff() AND public.current_admin_id() = id_admin);

DROP POLICY IF EXISTS "authenticated can update transaksi_item" ON public.transaksi_item;
CREATE POLICY "authenticated can update transaksi_item"
  ON public.transaksi_item
  FOR UPDATE
  TO authenticated
  USING (public.is_owner())
  WITH CHECK (public.is_owner());

-- fn_transaksi_insert remains SECURITY DEFINER and validates:
--   PERFORM public.require_clinic_staff(p_id_admin);
-- public.require_clinic_staff(p_id_admin) rejects mismatched id_admin.
GRANT EXECUTE ON FUNCTION public.fn_transaksi_insert(date, varchar, numeric, varchar, bigint, text, int, bigint, jsonb) TO authenticated;
