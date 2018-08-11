select t23_tel_cliente t23_orden, t23_tel_cliente t23_cod_cliente,
	t23_nom_cliente, t23_val_mo_tal, t23_tot_neto tot_oc,
	t23_tot_neto tot_fa, t23_tot_neto tot_ot, t23_estado
	from talt023
	where t23_compania = 17
	into temp t1;
INSERT INTO t1
SELECT t23_orden, t23_cod_cliente, t23_nom_cliente, t23_val_mo_tal,
	(SELECT NVL(SUM((c11_precio - c11_val_descto) *
		(1 + c10_recargo / 100)), 0)
		FROM ordt010, ordt011
		WHERE c10_compania    = t23_compania
		  AND c10_localidad   = t23_localidad
		  AND c10_ord_trabajo = t23_orden
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'S') +
	(SELECT NVL(SUM(((c11_cant_ped * c11_precio) - c11_val_descto) *
		(1 + c10_recargo / 100)), 0)
		FROM ordt010, ordt011
		WHERE c10_compania    = t23_compania
		  AND c10_localidad   = t23_localidad
		  AND c10_ord_trabajo = t23_orden
		  AND c11_compania    = c10_compania
		  AND c11_localidad   = c10_localidad
		  AND c11_numero_oc   = c10_numero_oc
		  AND c11_tipo        = 'B') tot_oc,
	CASE WHEN t23_estado = 'A' OR t23_estado = 'C' THEN
		(SELECT NVL(SUM(r21_tot_neto), 0)
		 FROM rept021
		 WHERE r21_compania  = t23_compania
		   AND r21_localidad = t23_localidad
		   AND r21_num_ot    = t23_orden)
	     WHEN t23_estado = 'F' OR t23_estado = 'D' THEN
		(SELECT NVL(SUM(r19_tot_neto), 0)
		 FROM rept019
		 WHERE r19_compania    = t23_compania
		   AND r19_localidad   = t23_localidad
		   AND r19_cod_tran    = 'FA'
		   AND r19_ord_trabajo = t23_orden)
	     ELSE 0
	END CASE,
	0 tot_ot, t23_estado
	FROM talt023
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    IN('A', 'C', 'E', 'F', 'D')
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;
select t23_orden[1, 5] ord_ot, t23_cod_cliente[1, 5] cod_c,
	t23_nom_cliente[1, 20] cliente, round(t23_val_mo_tal, 2) total_mo,
	round(tot_oc, 2) total_oc, round(tot_fa, 2) total_fa,
	round(t23_val_mo_tal + tot_oc + tot_fa, 2) total_ot, t23_estado
	from t1
	into temp t2;
drop table t1;
select * from t2 order by 1 desc;
drop table t2;
