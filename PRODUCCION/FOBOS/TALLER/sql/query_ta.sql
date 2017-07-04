INSERT INTO tmp_det
	SELECT CASE WHEN t23_estado = 'D'
			THEN (SELECT DATE(t28_fec_anula)
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'D'
			THEN (SELECT t28_num_dev FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado = 'D'
			THEN (SELECT t28_ot_ant
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_orden
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'S') +
			(SELECT NVL(SUM(ROUND(((c11_cant_ped * c11_precio)
				- c11_val_descto) *
				(1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM ordt010
					WHERE c10_compania    = t23_compania
					  AND c10_localidad   = t23_localidad
					  AND c10_ord_trabajo = t23_orden
					  AND c10_estado      = 'C') = 0
				THEN (t23_val_rp_tal + t23_val_rp_ext +
					t23_val_rp_cti + t23_val_otros2)
				ELSE 0.00
			END
			ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
				+ t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2) * (-1)
		END tot_oc,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				* (-1)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
			ELSE 0
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
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
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
			CASE WHEN (SELECT COUNT(*) FROM ordt010
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
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				* (-1)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
			ELSE 0
		END,
		CASE WHEN 1 = 1 THEN t23_estado ELSE 'F' END,
		t23_cod_cliente, t23_nom_cliente
		FROM talt023, OUTER talt028
		WHERE t23_compania  = 1
		  AND t23_localidad = 1
		  AND t23_estado    = 'F'
		  AND DATE(t23_fec_factura) BETWEEN MDY(08, 01, 2008)
						AND MDY(08, 31, 2008)
		  AND t28_compania  = t23_compania
		  AND t28_localidad = t23_localidad
		  AND t28_factura   = t23_num_factura
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
 
INSERT INTO tmp_det
	SELECT CASE WHEN t23_estado = 'D' THEN
		(SELECT DATE(t28_fec_anula)
			FROM talt028
			WHERE t28_compania  = t23_compania
			  AND t28_localidad = t23_localidad
			  AND t28_factura   = t23_num_factura)
		ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'D' THEN
			(SELECT t28_num_dev
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
			END,
		CASE WHEN t23_estado = 'D' THEN
			(SELECT t28_ot_ant
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_orden
			END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
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
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
		CASE WHEN (SELECT COUNT(*) FROM ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
			END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
			+ t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END tot_oc,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				* (-1)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
			ELSE 0
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
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
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
		CASE WHEN (SELECT COUNT(*) FROM ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
		END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
			+ t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				* (-1)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
			ELSE 0
		END,
		CASE WHEN 1 = 1 THEN t23_estado ELSE 'F' END, t23_cod_cliente,
		t23_nom_cliente
		FROM talt023, talt028
		WHERE t23_compania        = 1
		  AND t23_localidad       = 1
		  AND t23_estado          = 'D'
		  AND t28_compania        = t23_compania
		  AND t28_localidad       = t23_localidad
		  AND t28_factura         = t23_num_factura
		  AND DATE(t28_fec_anula) BETWEEN MDY(08, 01, 2008)
					      AND MDY(08, 31, 2008)
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;

INSERT INTO tmp_det
	SELECT CASE WHEN t23_estado = 'D' THEN
		(SELECT DATE(t28_fec_anula)
			FROM talt028
			WHERE t28_compania  = t23_compania
			  AND t28_localidad = t23_localidad
			  AND t28_factura   = t23_num_factura)
		ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'D' THEN
			(SELECT t28_num_dev
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado = 'D' THEN
			(SELECT t28_ot_ant
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_orden
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
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
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
		CASE WHEN (SELECT COUNT(*) FROM ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
		END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
			+ t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END tot_oc,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				* (-1)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
			ELSE 0
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal * (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
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
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
		CASE WHEN (SELECT COUNT(*) FROM ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
		END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
			+ t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
			* (-1)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				* (-1)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
			ELSE 0
		END,
		CASE WHEN 1 = 1 THEN t23_estado ELSE 'F' END, t23_cod_cliente,
		t23_nom_cliente
		FROM talt023, talt028
		WHERE t23_compania        = 1
		  AND t23_localidad       = 1
		  AND t23_estado          = 'N'
		  AND t28_compania        = t23_compania
		  AND t28_localidad       = t23_localidad
		  AND t28_factura         = t23_num_factura
		  AND DATE(t28_fec_anula) BETWEEN MDY(08, 01, 2008)
					      AND MDY(08, 31, 2008)
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
 
INSERT INTO tmp_det
	SELECT CASE WHEN t23_estado = 'D' AND 2 = 1
		THEN (SELECT DATE(t28_fec_anula)
			FROM talt028
			WHERE t28_compania  = t23_compania
			  AND t28_localidad = t23_localidad
			  AND t28_factura   = t23_num_factura)
		ELSE DATE(t23_fec_factura)
		END,
		CASE WHEN t23_estado = 'D' AND 2 = 1
			THEN (SELECT t28_num_dev
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_num_factura
		END,
		CASE WHEN t23_estado = 'D'
			THEN (SELECT t28_ot_ant
				FROM talt028
				WHERE t28_compania  = t23_compania
				  AND t28_localidad = t23_localidad
				  AND t28_factura   = t23_num_factura)
			ELSE t23_orden
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal
		END,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
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
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
		CASE WHEN (SELECT COUNT(*) FROM ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
		END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
			+ t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
		END tot_oc,
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
			ELSE 0
		END,
		CASE WHEN t23_estado = 'F'
			THEN t23_val_mo_tal
			ELSE t23_val_mo_tal
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(ROUND((c11_precio - c11_val_descto)
				* (1 + c10_recargo / 100), 2)), 0)
				FROM ordt010, ordt011
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
				FROM ordt010, ordt011
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C'
				  AND c11_compania    = c10_compania
				  AND c11_localidad   = c10_localidad
				  AND c11_numero_oc   = c10_numero_oc
				  AND c11_tipo        = 'B') +
		CASE WHEN (SELECT COUNT(*) FROM ordt010
				WHERE c10_compania    = t23_compania
				  AND c10_localidad   = t23_localidad
				  AND c10_ord_trabajo = t23_orden
				  AND c10_estado      = 'C') = 0
			THEN (t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti
				+ t23_val_otros2)
			ELSE 0.00
		END
		ELSE (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
			+ t23_val_rp_ext + t23_val_rp_cti + t23_val_otros2)
		END +
		CASE WHEN t23_estado = 'F' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran     = 'FA'
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t23_fec_factura, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t23_fec_factura, YEAR TO MONTH))
			WHEN t23_estado = 'D' THEN
			(SELECT NVL(SUM(r19_tot_bruto - r19_tot_dscto), 0)
				FROM rept019
				WHERE r19_compania     = t23_compania
				  AND r19_localidad    = t23_localidad
				  AND r19_cod_tran    IN ('DF', 'AF')
				  AND r19_ord_trabajo  = t23_orden
				  AND EXTEND(r19_fecing, YEAR TO MONTH) >=
					EXTEND(t28_fec_anula, YEAR TO MONTH)
				  AND EXTEND(r19_fecing, YEAR TO MONTH) <=
					EXTEND(t28_fec_anula, YEAR TO MONTH))
		       ELSE 0
		END,
		CASE WHEN 2 = 1 THEN t23_estado ELSE 'F' END,
		t23_cod_cliente, t23_nom_cliente
		FROM talt023, OUTER talt028
		WHERE t23_compania          = 1
		  AND t23_localidad         = 1
		  AND t23_estado            = 'D'
		  AND DATE(t23_fec_factura) BETWEEN MDY(08, 01, 2008)
						AND MDY(08, 31, 2008)
		  AND t28_compania          = t23_compania
		  AND t28_localidad         = t23_localidad
		  AND t28_factura           = t23_num_factura
		GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
 
DELETE FROM tmp_det
	WHERE fecha_tran < MDY(08, 01, 2008)
	   OR fecha_tran > MDY(08, 31, 2008);
