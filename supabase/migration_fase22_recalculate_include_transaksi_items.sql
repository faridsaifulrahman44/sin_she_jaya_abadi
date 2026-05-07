-- ============================================================
-- FASE 22 / P2: Recalculate stock includes ready-stock transaksi_item
--
-- Safe for existing data:
-- - No table/schema changes.
-- - Replaces fn_recalculate_obat_stok_single only.
-- - Keeps ready-stock transaksi_item deltas in stock replay so recalculate
--   cannot erase stock reductions made by fn_transaksi_insert.
-- ============================================================

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
        t.tanggal AS mutation_date,
        2 AS priority,
        t.created_at AS recorded_at,
        ti.id_item AS sequence_id,
        -ti.jumlah AS delta,
        false AS is_reset
      FROM public.transaksi_item ti
      JOIN public.transaksi t
        ON t.id_transaksi = ti.id_transaksi
      WHERE ti.id_obat = p_id_obat
        AND t.jenis_transaksi = 'obat_ready_stock'

      UNION ALL

      SELECT
        so.tanggal_opname AS mutation_date,
        3 AS priority,
        so.created_at AS recorded_at,
        so.id_opname AS sequence_id,
        so.stok_fisik AS delta,
        true AS is_reset
      FROM public.sinkronisasi_stok so
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

GRANT EXECUTE ON FUNCTION public.fn_recalculate_obat_stok_single(bigint) TO authenticated;
