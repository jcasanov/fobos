SELECT "IN" mod, r19_localidad loc, r19_codcli codcli, r19_nomcli nomcli,
	r19_cod_tran tp, r19_num_tran || " " num, DATE(r19_fecing) fecha,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_bruto - r19_tot_dscto)
		ELSE (r19_tot_bruto - r19_tot_dscto) * (-1)
	END subtotal,
	CASE WHEN r19_cod_tran = 'FA'
		THEN r19_flete
		ELSE r19_flete * (-1)
	END flete,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
		ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
			* (-1)
	END impuesto,
	r19_tot_neto total
	FROM acero_gm:rept019
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ('FA', 'NV', 'DF', 'AF')
	  AND EXTEND(r19_fecing, YEAR TO MONTH) = '2009-01'
UNION
SELECT "IN" mod, r19_localidad loc, r19_codcli codcli, r19_nomcli nomcli,
	r19_cod_tran tp, r19_num_tran || " " num, DATE(r19_fecing) fecha,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_bruto - r19_tot_dscto)
		ELSE (r19_tot_bruto - r19_tot_dscto) * (-1)
	END subtotal,
	CASE WHEN r19_cod_tran = 'FA'
		THEN r19_flete
		ELSE r19_flete * (-1)
	END flete,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
		ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
			* (-1)
	END impuesto,
	r19_tot_neto total
	FROM acero_gc:rept019
	WHERE r19_compania      = 1
	  AND r19_localidad     = 2
	  AND r19_cod_tran     IN ('FA', 'NV', 'DF', 'AF')
	  AND EXTEND(r19_fecing, YEAR TO MONTH) = '2009-01'
UNION
SELECT "IN" mod, r19_localidad loc, r19_codcli codcli, r19_nomcli nomcli,
	r19_cod_tran tp, r19_num_tran || " " num, DATE(r19_fecing) fecha,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_bruto - r19_tot_dscto)
		ELSE (r19_tot_bruto - r19_tot_dscto) * (-1)
	END subtotal,
	CASE WHEN r19_cod_tran = 'FA'
		THEN r19_flete
		ELSE r19_flete * (-1)
	END flete,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
		ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
			* (-1)
	END impuesto,
	r19_tot_neto total
	FROM acero_qm:rept019
	WHERE r19_compania      = 1
	  AND r19_localidad    IN (3, 5)
	  AND r19_cod_tran     IN ('FA', 'NV', 'DF', 'AF')
	  AND EXTEND(r19_fecing, YEAR TO MONTH) = '2009-01'
UNION
SELECT "IN" mod, r19_localidad loc, r19_codcli codcli, r19_nomcli nomcli,
	r19_cod_tran tp, r19_num_tran || " " num, DATE(r19_fecing) fecha,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_bruto - r19_tot_dscto)
		ELSE (r19_tot_bruto - r19_tot_dscto) * (-1)
	END subtotal,
	CASE WHEN r19_cod_tran = 'FA'
		THEN r19_flete
		ELSE r19_flete * (-1)
	END flete,
	CASE WHEN r19_cod_tran = 'FA'
		THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
		ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
			* (-1)
	END impuesto,
	r19_tot_neto total
	FROM acero_qs:rept019
	WHERE r19_compania      = 1
	  AND r19_localidad     = 4
	  AND r19_cod_tran     IN ('FA', 'NV', 'DF', 'AF')
	  AND EXTEND(r19_fecing, YEAR TO MONTH) = '2009-01'
	INTO TEMP tmp_inv;

SELECT t23_moneda mod, t23_localidad loc, t23_cod_cliente codcli,
	t23_nom_cliente nomcli, t23_moneda tp, t23_num_factura || " " num,
	DATE(t23_fec_factura) fecha, t23_tot_bruto subtotal,
	t23_tot_bruto flete, t23_val_impto impuesto, t23_tot_neto total
	FROM talt023
	WHERE t23_compania = 17
	INTO TEMP tmp_tal;

INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente,
		CASE WHEN t23_estado = 'F' THEN "FA"
		     WHEN t23_estado = 'D' THEN "DF"
		     WHEN t23_estado = 'N' THEN "AF"
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT t28_num_dev FROM acero_gm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT DATE(t28_fec_anula)
				FROM acero_gm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_gm:talt023, OUTER acero_gm:talt028
		WHERE t23_compania          = 1
		  AND t23_localidad         = 1
		  AND t23_estado            = 'F'
		  AND EXTEND(t23_fec_factura, YEAR TO MONTH) = '2009-01'
		  AND t28_compania          = t23_compania
		  AND t28_localidad         = t23_localidad
		  AND t28_factura           = t23_num_factura
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente,
		CASE WHEN t23_estado = 'F' THEN "FA"
		     WHEN t23_estado = 'D' THEN "DF"
		     WHEN t23_estado = 'N' THEN "AF"
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT t28_num_dev FROM acero_gm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT DATE(t28_fec_anula)
				FROM acero_gm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_gm:talt023, acero_gm:talt028
		WHERE t23_compania        = 1
		  AND t23_localidad       = 1
		  AND t23_estado          = 'D'
		  AND t28_compania        = t23_compania
		  AND t28_localidad       = t23_localidad
		  AND t28_factura         = t23_num_factura
		  AND EXTEND(t28_fec_anula, YEAR TO MONTH) = '2009-01'
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;

INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente,
		CASE WHEN t23_estado = 'F' THEN "FA"
		     WHEN t23_estado = 'D' THEN "DF"
		     WHEN t23_estado = 'N' THEN "AF"
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT t28_num_dev FROM acero_gm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT DATE(t28_fec_anula)
				FROM acero_gm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_gm:talt023, acero_gm:talt028
		WHERE t23_compania        = 1
		  AND t23_localidad       = 1
		  AND t23_estado          = 'N'
		  AND t28_compania        = t23_compania
		  AND t28_localidad       = t23_localidad
		  AND t28_factura         = t23_num_factura
		  AND EXTEND(t28_fec_anula, YEAR TO MONTH) = '2009-01'
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente, "FA",
		t23_num_factura, DATE(t23_fec_factura),
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_gm:ordt010, acero_gm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_gm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_gm:talt023, OUTER acero_gm:talt028
		WHERE t23_compania          = 1
		  AND t23_localidad         = 1
		  AND t23_estado            = 'D'
		  AND EXTEND(t23_fec_factura, YEAR TO MONTH) = '2009-01'
		  AND t28_compania          = t23_compania
		  AND t28_localidad         = t23_localidad
		  AND t28_factura           = t23_num_factura
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
DELETE FROM tmp_tal
	WHERE EXTEND(fecha, YEAR TO MONTH) <> '2009-01';
	--WHERE fecha < MDY(01, 01, 2009) OR fecha > MDY(01, 31, 2009);

INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente,
		CASE WHEN t23_estado = 'F' THEN "FA"
		     WHEN t23_estado = 'D' THEN "DF"
		     WHEN t23_estado = 'N' THEN "AF"
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT t28_num_dev FROM acero_qm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT DATE(t28_fec_anula)
				FROM acero_qm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_qm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_qm:talt023, OUTER acero_qm:talt028
		WHERE t23_compania          = 1
		  AND t23_localidad         IN (3, 5)
		  AND t23_estado            = 'F'
		  AND EXTEND(t23_fec_factura, YEAR TO MONTH) = '2009-01'
		  AND t28_compania          = t23_compania
		  AND t28_localidad         = t23_localidad
		  AND t28_factura           = t23_num_factura
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente,
		CASE WHEN t23_estado = 'F' THEN "FA"
		     WHEN t23_estado = 'D' THEN "DF"
		     WHEN t23_estado = 'N' THEN "AF"
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT t28_num_dev FROM acero_qm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT DATE(t28_fec_anula)
				FROM acero_qm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_qm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_qm:talt023, acero_qm:talt028
		WHERE t23_compania        = 1
		  AND t23_localidad       IN (3, 5)
		  AND t23_estado          = 'D'
		  AND t28_compania        = t23_compania
		  AND t28_localidad       = t23_localidad
		  AND t28_factura         = t23_num_factura
		  AND EXTEND(t28_fec_anula, YEAR TO MONTH) = '2009-01'
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;

INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente,
		CASE WHEN t23_estado = 'F' THEN "FA"
		     WHEN t23_estado = 'D' THEN "DF"
		     WHEN t23_estado = 'N' THEN "AF"
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT t28_num_dev FROM acero_qm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado <> 'F'
			THEN (SELECT DATE(t28_fec_anula)
				FROM acero_qm:talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_qm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_qm:talt023, acero_qm:talt028
		WHERE t23_compania        = 1
		  AND t23_localidad       IN (3, 5)
		  AND t23_estado          = 'N'
		  AND t28_compania        = t23_compania
		  AND t28_localidad       = t23_localidad
		  AND t28_factura         = t23_num_factura
		  AND EXTEND(t28_fec_anula, YEAR TO MONTH) = '2009-01'
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
INSERT INTO tmp_tal
	SELECT "TA", t23_localidad, t23_cod_cliente, t23_nom_cliente, "FA",
		t23_num_factura, DATE(t23_fec_factura),
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto)
				* (1 + c10_recargo / 100), 2)),0)
				FROM acero_qm:ordt010, acero_qm:ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM acero_qm:ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal +
			t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
		END,
		0.00, t23_val_impto, t23_tot_neto
		FROM acero_qm:talt023, OUTER acero_qm:talt028
		WHERE t23_compania          = 1
		  AND t23_localidad         IN (3, 5)
		  AND t23_estado            = 'D'
		  AND EXTEND(t23_fec_factura, YEAR TO MONTH) = '2009-01'
		  AND t28_compania          = t23_compania
		  AND t28_localidad         = t23_localidad
		  AND t28_factura           = t23_num_factura
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
DELETE FROM tmp_tal
	WHERE EXTEND(fecha, YEAR TO MONTH) <> '2009-01';
	--WHERE fecha < MDY(01, 01, 2009) OR fecha > MDY(01, 31, 2009);

SELECT "CO" mod, z20_localidad loc, z20_codcli codcli, z01_nomcli nomcli,
	z20_tipo_doc tp, z20_num_doc num, z20_fecha_emi fecha,
	(z20_valor_cap + z20_valor_int) subtotal, 0.00 flete,
	z20_val_impto impuesto, (z20_valor_cap + z20_valor_int +
	z20_val_impto) total
	FROM acero_gm:cxct020, acero_gm:cxct001
	WHERE z20_compania   = 1
	  AND z20_localidad IN (1, 2)
	  AND z20_tipo_doc   = 'ND'
	  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) = '2009-01'
	  AND z01_codcli     = z20_codcli
	INTO TEMP tmp_doc;

INSERT INTO tmp_doc
	SELECT "CO" mod, z21_localidad loc, z21_codcli codcli,
		z01_nomcli nomcli, z21_tipo_doc tp, z21_num_doc num,
		z21_fecha_emi fecha, z21_valor subtotal, 0.00 flete,
		z21_val_impto impuesto, (z21_valor + z21_val_impto) total
		FROM acero_gm:cxct021, acero_gm:cxct001
		WHERE z21_compania   = 1
		  AND z21_localidad IN (1, 2)
		  AND z21_tipo_doc   = 'NC'
		  AND EXTEND(z21_fecha_emi, YEAR TO MONTH) = '2009-01'
		  AND z21_origen     = 'M'
		  AND z01_codcli     = z21_codcli;

INSERT INTO tmp_doc
	SELECT "CO" mod, z20_localidad loc, z20_codcli codcli,
		z01_nomcli nomcli, z20_tipo_doc tp, z20_num_doc num,
		z20_fecha_emi fecha, (z20_valor_cap + z20_valor_int) subtotal,
		0.00 flete, z20_val_impto impuesto,
		(z20_valor_cap + z20_valor_int + z20_val_impto) total
		FROM acero_qm:cxct020, acero_qm:cxct001
		WHERE z20_compania   = 1
		  AND z20_localidad IN (3, 4, 5)
		  AND z20_tipo_doc   = 'ND'
		  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) = '2009-01'
		  AND z01_codcli     = z20_codcli;

INSERT INTO tmp_doc
	SELECT "CO" mod, z21_localidad loc, z21_codcli codcli,
		z01_nomcli nomcli, z21_tipo_doc tp, z21_num_doc num,
		z21_fecha_emi fecha, z21_valor subtotal, 0.00 flete,
		z21_val_impto impuesto, (z21_valor + z21_val_impto) total
		FROM acero_qm:cxct021, acero_qm:cxct001
		WHERE z21_compania   = 1
		  AND z21_localidad IN (3, 4, 5)
		  AND z21_tipo_doc   = 'NC'
		  AND EXTEND(z21_fecha_emi, YEAR TO MONTH) = '2009-01'
		  AND z21_origen     = 'M'
		  AND z01_codcli     = z21_codcli;

	SELECT * FROM tmp_inv
UNION
	SELECT * FROM tmp_tal
UNION
	SELECT * FROM tmp_doc
INTO TEMP tmp_vtas;

DROP TABLE tmp_inv;
DROP TABLE tmp_tal;
DROP TABLE tmp_doc;

SELECT * FROM tmp_vtas;

DROP TABLE tmp_vtas;
