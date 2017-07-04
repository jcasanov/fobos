set isolation to dirty read;
SELECT r19_localidad LOC, r01_iniciales agt, r19_cod_tran codtran,
	r19_num_tran numtran, NVL(r19_codcli, 99) codcli,
	r19_nomcli nombre, DATE(r20_fecing) fecha,
	CASE WHEN r19_cont_cred = "C" THEN "CONTADO"
	     WHEN r19_cont_cred = "R" THEN "CREDITO"
	     ELSE ""
	END formapago,
    	NVL((SELECT MAX(z20_fecha_vcto)
		FROM aceros:cxct020
		WHERE z20_compania  = r19_compania
	 	  AND z20_localidad = r19_localidad
		  AND z20_codcli    = r19_codcli
		  AND z20_cod_tran  = r19_cod_tran
		  AND z20_num_tran  = r19_num_tran
		  AND z20_areaneg   = 1), DATE(r20_fecing)) fecha_vcto,
	r72_cod_clase clase, r72_desc_clase nombre_clase, r20_item coditem,
	r10_nombre nombre_item,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(r20_cant_ven, 0)
		ELSE NVL(r20_cant_ven, 0) * (-1)
	END can_vta,
	r20_precio pvp, r20_descuento por_dscto, r77_multiplic mult,
	r20_val_descto val_dscto,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0)
		ELSE NVL(((r20_cant_ven * r20_precio) - r20_val_descto),0) *(-1)
	END val_vta,
	NVL((SELECT r88_num_fact
		FROM aceros:rept088
		WHERE r88_compania     = r19_compania
		  AND r88_localidad    = r19_localidad
		  AND r88_cod_fact_nue = r19_cod_tran
		  AND r88_num_fact_nue = r19_num_tran), "") fac_ant,
	NVL(DATE((SELECT r19_fecing
		FROM aceros:rept088, aceros:rept019 repm
		WHERE repm.r19_compania	 = r88_compania
		  AND repm.r19_localidad = r88_localidad
		  AND repm.r19_cod_tran  = r88_cod_fact
		  AND repm.r19_num_tran  = r88_num_fact
		  AND r88_compania       = r19m.r19_compania
		  AND r88_localidad      = r19m.r19_localidad
		  AND r88_cod_fact_nue   = r19m.r19_cod_tran
		  AND r88_num_fact_nue   = r19m.r19_num_tran)), "") fech_ant,
	r19_tipo_dev tipodev, r19_num_dev numdev
	FROM aceros:rept019 r19m, aceros:rept020, aceros:rept072,
		aceros:rept010, aceros:rept077, aceros:rept001,
		aceros:rept073
	WHERE r19_compania    = 1
	  AND r19_localidad   = 1
	  AND (r19_cod_tran   = "DF"
	   OR (r19_cod_tran   = "FA"
	  AND (r19_tipo_dev   IS NULL
	   OR  r19_tipo_dev   = "DF")))
	  AND EXTEND(r19_fecing, YEAR TO MONTH) = '2010-11'
	  AND r20_compania    = r19_compania
	  AND r20_localidad   = r19_localidad
	  AND r20_cod_tran    = r19_cod_tran
	  AND r20_num_tran    = r19_num_tran
	  AND r10_compania    = r20_compania
	  AND r10_codigo      = r20_item
	  AND r10_compania    = r72_compania
	  AND r10_cod_clase   = r72_cod_clase
	  AND r10_cod_grupo   = r72_cod_grupo
	  AND r10_sub_linea   = r72_sub_linea
	  AND r10_linea       = r72_linea
	  AND r10_compania    = r73_compania
	  AND r10_marca	      = r73_marca
	  AND r77_compania    = r10_compania
	  AND r77_codigo_util = r10_cod_util
	  AND r01_compania    = r19_compania
	  AND r01_codigo      = r19_vendedor
UNION ALL
SELECT r19_localidad LOC, r01_iniciales agt, r19_cod_tran codtran,
	r19_num_tran numtran, NVL(r19_codcli, 99) codcli, r19_nomcli nombre,
	DATE(r20_fecing) fecha,
	CASE WHEN r19_cont_cred = "C" THEN "CONTADO"
	     WHEN r19_cont_cred = "R" THEN "CREDITO"
	     ELSE ""
	END formapago,
	NVL((SELECT MAX(z20_fecha_vcto)
		FROM acero_gc:cxct020
		WHERE z20_compania  = r19_compania
		  AND z20_localidad = r19_localidad
		  AND z20_codcli    = r19_codcli
		  AND z20_cod_tran  = r19_cod_tran
		  AND z20_num_tran  = r19_num_tran
		  AND z20_areaneg   = 1), DATE(r20_fecing)) fecha_vcto,
	r72_cod_clase clase, r72_desc_clase nombre_clase, r20_item coditem,
	r10_nombre nombre_item,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(r20_cant_ven, 0)
		ELSE NVL(r20_cant_ven, 0) * (-1)
	END can_vta,
	r20_precio pvp, r20_descuento por_dscto, r77_multiplic mult,
	r20_val_descto val_dscto,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0)
		ELSE NVL(((r20_cant_ven * r20_precio) - r20_val_descto),0) *(-1)
	END val_vta,
	NVL((SELECT r88_num_fact
		FROM acero_gc:rept088
		WHERE r88_compania     = r19_compania
		  AND r88_localidad    = r19_localidad
		  AND r88_cod_fact_nue = r19_cod_tran
		  AND r88_num_fact_nue = r19_num_tran), "") fac_ant,
	NVL(DATE((SELECT r19_fecing
		FROM acero_gc:rept088, acero_gc:rept019 reps
		WHERE reps.r19_compania  = r88_compania
		  AND reps.r19_localidad = r88_localidad
		  AND reps.r19_cod_tran  = r88_cod_fact
		  AND reps.r19_num_tran  = r88_num_fact
		  AND r88_compania 	 = r19s.r19_compania
		  AND r88_localidad	 = r19s.r19_localidad
		  AND r88_cod_fact_nue   = r19s.r19_cod_tran
		  AND r88_num_fact_nue   = r19s.r19_num_tran)), "") fech_ant,
	r19_tipo_dev tipodev, r19_num_dev numdevi
	FROM acero_gc:rept019 r19s, acero_gc:rept020, acero_gc:rept072,
		acero_gc:rept010, acero_gc:rept077, acero_gc:rept001,
		acero_gc:rept073
	WHERE r19_compania    = 1
	  AND r19_localidad   = 2
	  AND (r19_cod_tran   = "DF"
	   OR (r19_cod_tran   = "FA"
	  AND (r19_tipo_dev   IS NULL
	   OR  r19_tipo_dev   = "DF")))
	  AND EXTEND(r19_fecing, YEAR TO MONTH) = '2010-11'
	  AND r20_compania    = r19_compania
	  AND r20_localidad   = r19_localidad
	  AND r20_cod_tran    = r19_cod_tran
	  AND r20_num_tran    = r19_num_tran
	  AND r10_compania    = r20_compania
	  AND r10_codigo      = r20_item
	  AND r10_compania    = r72_compania
	  AND r10_cod_clase   = r72_cod_clase
	  AND r10_cod_grupo   = r72_cod_grupo
	  AND r10_sub_linea   = r72_sub_linea
	  AND r10_linea       = r72_linea
	  AND r10_compania    = r73_compania
	  AND r10_marca	      = r73_marca
	  AND r77_compania    = r10_compania
	  AND r77_codigo_util = r10_cod_util
	  AND r01_compania    = r19_compania
	  AND r01_codigo      = r19_vendedor
	into temp t1;
select codcli, count(*) total_cli from t1 group by 1 into temp t2;
select count(*) tot_reg from t1;
select count(*) tot_reg2 from t2;
select round(sum(val_vta), 2) tot_vta from t1;
drop table t1;
drop table t2;
