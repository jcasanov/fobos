SELECT r19_compania ciac, r19_localidad loc, r19_num_tran tp, r19_num_tran num
        FROM aceros:rept019, aceros:rept002
        WHERE r19_compania      = 1
          AND r19_localidad     = 1
          AND r19_cod_tran      = 'TR'
          AND YEAR(r19_fecing)  = 2009
          AND r02_compania      = r19_compania
          AND r02_codigo        = r19_bodega_dest
          AND r02_tipo         <> 'S'
          AND r02_localidad     = 3
UNION
SELECT r19_compania ciac, r19_localidad loc, r19_num_tran tp, r19_num_tran num
        FROM aceros:rept019, aceros:rept002
        WHERE r19_compania      = 1
          AND r19_localidad     = 1
          AND r19_cod_tran      = 'TR'
          AND YEAR(r19_fecing)  = 2009
          AND r02_compania      = r19_compania
          AND r02_codigo        = r19_bodega_ori
          AND r02_tipo         <> 'S'
          AND r02_localidad     = 3
	INTO TEMP t1;
SELECT COUNT(*) tot_t1 FROM t1;
SELECT ciac, loc, tp, num, r40_tipo_comp tpc, r40_num_comp numc
	FROM t1, aceros:rept040
	WHERE r40_compania  = ciac
	  AND r40_localidad = loc
	  AND r40_cod_tran  = 'TR'
	  AND r40_num_tran  = num
	INTO TEMP t2;
SELECT COUNT(*) tot_t2 FROM t2;
DROP TABLE t1;
SELECT b13_compania cia, b13_tipo_comp tp_c, b13_num_comp num_c,
	(b13_valor_base * (-1)) val_ctb
	FROM aceros:ctbt012,
		aceros:ctbt013
	WHERE b12_compania          = 1
	  and b12_tipo_comp         = 'DR'
	  and b12_estado            = 'M'
	  and b12_subtipo           = 25
	  and year(b12_fec_proceso) = 2009
	  and b13_compania          = b12_compania
	  and b13_tipo_comp         = b12_tipo_comp
	  and b13_num_comp          = b12_num_comp
	  and b13_cuenta            = '11400101006'
	into temp tmp_cont;
SELECT COUNT(*) tot_cont FROM tmp_cont;
SELECT * FROM tmp_cont, OUTER t2
	WHERE cia   = ciac
	  AND tp_c  = tpc
	  AND num_c = numc
	INTO TEMP t3;
DROP TABLE t2;
DROP TABLE tmp_cont;
DELETE FROM t3 WHERE numc IS NOT NULL;
SELECT * FROM t3;
DROP TABLE t3;
