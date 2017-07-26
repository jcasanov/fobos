set isolation to dirty read;

select r19_localidad, NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_cod_tran,
	r20_num_tran, r20_fecing, 'IN' areaneg, r19_porc_impto porc,
	-- PARA OTRO TIPO DE ANALISIS
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_tot_bruto
	else
		r19_tot_bruto * (-1)
	end val_bru,
	(case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_tot_dscto
	else
		r19_tot_dscto * (-1)
	end) * (-1) descto,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		(r19_tot_bruto - r19_tot_dscto)
	else
		(r19_tot_bruto - r19_tot_dscto) * (-1)
	end subtotal,
	--
	{-- PARA OTRO TIPO DE ANALISIS CON LA rept020
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		nvl(sum(r20_cant_ven * r20_precio), 0)
	else
		nvl(sum(r20_cant_ven * r20_precio), 0) * (-1)
	end val_bru,
	(case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		nvl(sum(r20_val_descto), 0)
	else
		nvl(sum(r20_val_descto), 0) * (-1)
	end) * (-1) descto,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end subtotal,
	--}
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		(r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
	else
		(r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete) *(-1)
	end val_imp,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_flete
	else
		r19_flete * (-1)
	end flete,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_tot_neto
	else
		r19_tot_neto * (-1)
	end val_net
	from rept019, rept020
	where r19_compania                       = 1
	  and r19_localidad                     in (3, 5)
	  and r19_cod_tran                      in ('FA', 'NV', 'DF', 'AF')
	  and extend(r19_fecing, year to month)  = '2009-01'
	  and r20_compania                       = r19_compania
	  and r20_localidad                      = r19_localidad
	  and r20_cod_tran                       = r19_cod_tran
	  and r20_num_tran                       = r19_num_tran
	--group by 1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14
union
select r19_localidad, NVL(r19_codcli, 99) r19_codcli, r19_nomcli, r19_cod_tran,
	r20_num_tran, r20_fecing, 'TA' areaneg, r19_porc_impto porc,
	-- PARA OTRO TIPO DE ANALISIS
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_tot_bruto
	else
		r19_tot_bruto * (-1)
	end val_bru,
	(case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_tot_dscto
	else
		r19_tot_dscto * (-1)
	end) * (-1) descto,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		(r19_tot_bruto - r19_tot_dscto)
	else
		(r19_tot_bruto - r19_tot_dscto) * (-1)
	end subtotal,
	--
	{-- PARA OTRO TIPO DE ANALISIS CON LA rept020
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		nvl(sum(r20_cant_ven * r20_precio), 0)
	else
		nvl(sum(r20_cant_ven * r20_precio), 0) * (-1)
	end val_bru,
	(case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		nvl(sum(r20_val_descto), 0)
	else
		nvl(sum(r20_val_descto), 0) * (-1)
	end) * (-1) descto,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) *(-1)
	end subtotal,
	--}
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		(r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
	else
		(r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete) *(-1)
	end val_imp,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_flete
	else
		r19_flete * (-1)
	end flete,
	case when (r19_cod_tran = 'FA' or r19_cod_tran = 'NV') then
		r19_tot_neto
	else
		r19_tot_neto * (-1)
	end val_net
	from acero_qs:rept019, acero_qs:rept020
	where r19_compania                       = 1
	  and r19_localidad                      = 4
	  and r19_cod_tran                      in ('FA', 'NV', 'DF', 'AF')
	  and extend(r19_fecing, year to month)  = '2009-01'
	  and r20_compania                       = r19_compania
	  and r20_localidad                      = r19_localidad
	  and r20_cod_tran                       = r19_cod_tran
	  and r20_num_tran                       = r19_num_tran
	--group by 1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14
	into temp tmp_inv;
select r19_cod_tran tp, porc, round(sum(val_bru), 2) tot_bru,
	round(sum(descto), 2) tot_des, round(sum(subtotal), 2) tot_sub,
	round(sum(val_imp), 2) tot_iva, round(sum(flete), 2) tot_fle,
	round(sum(val_net), 2) tot_net
	from tmp_inv
	group by 1, 2
	into temp tmp_t_inv;
select porc, round(sum(tot_bru), 2) tot_bru, round(sum(tot_des), 2) tot_des,
	round(sum(tot_sub), 2) tot_sub, round(sum(tot_iva), 2) tot_iva,
	round(sum(tot_fle), 2) tot_fle, round(sum(tot_net), 2) tot_net
	from tmp_t_inv
	group by 1
	order by 1;
select count(*) tot_tran from tmp_inv order by 1 desc;
--select * from tmp_inv order by 1 desc;

select tmp_inv.*, r40_compania cia, r40_tipo_comp tp, r40_num_comp num
	from tmp_inv, rept040
	where r40_compania  = 1
          and r40_localidad = r19_localidad
          and r40_cod_tran  = r19_cod_tran
          and r40_num_tran  = r20_num_tran
	into temp t1;
select t1.*, b13_cuenta cuenta, nvl(sum(b13_valor_base), 0) val_ctb
	from t1, ctbt012, ctbt013
	where b12_compania   = cia
          and b12_tipo_comp  = tp
          and b12_num_comp   = num
          and b12_estado    <> 'E'
          and b13_compania   = b12_compania
          and b13_tipo_comp  = b12_tipo_comp
          and b13_num_comp   = b12_num_comp
          and b13_cuenta    in ('41010101001', '41010101003', '41010101004',
                                '41010103001', '41010103003', '41010103004',
                                '41020101001', '41020101002', '41020101003',
                                '41020103001', '41020103002', '41020103003',
                                '41020201001', '41020201002', '41020201003',
                                '41020203001', '41020203002', '41020203003')
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
        into temp t2;
drop table t1;

--
select * from t2
	where cuenta  in ('41010101001', '41010103001', '41020101001',
				'41020103001', '41020201001', '41020203001')
	  and val_bru <> (val_ctb * (-1));
select * from t2
	where cuenta  in ('41010101003', '41010103003', '41020101002',
				'41020103002', '41020201002', '41020203002')
	  and val_bru <> (val_ctb * (-1));
select * from t2
	where cuenta  in ('41010101004', '41010103004', '41020101003',
				'41020103003', '41020201003', '41020203003')
	  and (descto * (-1)) <> val_ctb;
--
drop table t2;

select date(t23_fec_factura) fecha_tran, t23_num_factura num_tran,
	t23_orden ord_t, t23_porc_impto porc, t23_tot_bruto valor_mo,
	t23_tot_bruto valor_oc, t23_tot_bruto valor_fa,t23_tot_bruto valor_tot,
	t23_estado est, t23_cod_cliente codcli, t23_nom_cliente nomcli
	from talt023
	where t23_compania = 17
	into temp tmp_tal;

INSERT INTO tmp_tal
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
		t23_porc_impto,
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
		WHERE t23_compania             = 1
		  AND t23_localidad            in (3, 5)
		  AND t23_estado               = 'F'
		  AND EXTEND(t23_fec_factura,
				YEAR TO MONTH) = '2009-01'
		  AND t28_compania             = t23_compania
		  AND t28_localidad            = t23_localidad
		  AND t28_factura              = t23_num_factura;
		--GROUP BY 1, 2, 3, 5, 6, 7, 8, 9, 10, 11;
 
INSERT INTO tmp_tal
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
		t23_porc_impto,
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
		WHERE t23_compania             = 1
		  AND t23_localidad            in (3, 5)
		  AND t23_estado               = 'D'
		  AND t28_compania             = t23_compania
		  AND t28_localidad            = t23_localidad
		  AND t28_factura              = t23_num_factura
		  AND EXTEND(t28_fec_anula,
				YEAR TO MONTH) = '2009-01';
		--GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;

INSERT INTO tmp_tal
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
		t23_porc_impto,
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
		WHERE t23_compania             = 1
		  AND t23_localidad            in (3, 5)
		  AND t23_estado               = 'N'
		  AND t28_compania             = t23_compania
		  AND t28_localidad            = t23_localidad
		  AND t28_factura              = t23_num_factura
		  AND EXTEND(t28_fec_anula,
				YEAR TO MONTH) = '2009-01';
		--GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
INSERT INTO tmp_tal
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
		t23_porc_impto,
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
		WHERE t23_compania             = 1
		  AND t23_localidad            in (3, 5)
		  AND t23_estado               = 'D'
		  AND EXTEND(t23_fec_factura,
				YEAR TO MONTH) = '2009-01'
		  AND t28_compania             = t23_compania
		  AND t28_localidad            = t23_localidad
		  AND t28_factura              = t23_num_factura;
		--GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
 
DELETE FROM tmp_tal
	WHERE EXTEND(fecha_tran, YEAR TO MONTH) <> '2009-01';

select fecha_tran, num_tran, ord_t, porc, round(valor_mo, 2) valor_mo,
	round(valor_fa, 2) valor_fa, round(valor_oc, 2) valor_oc,
	round(valor_mo + valor_fa + valor_oc, 2) valor_tot, est,
	codcli, nomcli
	from tmp_tal
	into temp t1;

select round(sum(valor_tot), 2) tot_ot from t1;
select round(sum(valor_mo), 2) tot_mo,
	round(sum(valor_oc), 2) tot_oc, 
	round(sum(valor_mo + valor_oc), 2) tot_ta, 
	round(sum(valor_fa), 2) tot_fa
	from t1;
select porc, round(sum(valor_tot), 2) tot_ot
	from t1
	group by 1
	order by 1;
select case when est = 'F' then 'FA'
	    when est = 'D' then 'DF'
	    when est = 'N' then 'AF'
	end tp,
	porc, round(sum(valor_mo), 2) tot_mo,
	round(sum(valor_oc), 2) tot_oc, 
	round(sum(valor_mo + valor_oc), 2) tot_ta, 
	round(sum(valor_fa), 2) tot_fa
	from t1
	group by 1, 2
	into temp tmp_t_tal;
select porc, round(sum(tot_mo), 2) tot_mo, round(sum(tot_oc), 2) tot_oc,
	round(sum(tot_ta), 2) tot_ta, round(sum(tot_fa), 2) tot_fa
	from tmp_t_tal
	group by 1
	order by 1;
select count(*) tot_tran from t1 order by 1 desc;
--select * from t1 order by 1 desc;
drop table t1;

select tmp_tal.*, t50_compania cia, t50_tipo_comp tp, t50_num_comp num
	from tmp_tal, talt050
	where est           = 'F'
	  and t50_compania  = 1
	  and t50_localidad in (3, 5)
	  and t50_orden     = ord_t
	  and t50_factura   = num_tran
union
	select tmp_tal.*, t50_compania cia, t50_tipo_comp tp, t50_num_comp num
		from tmp_tal, talt050
		where est           in ('N', 'D')
		  and t50_compania   = 1
		  and t50_localidad in (3, 5)
		  and t50_orden      = ord_t
	into temp t1;
select t1.*, b13_cuenta cuenta, nvl(sum(b13_valor_base), 0) val_ctb
	from t1, ctbt012, ctbt013
	where b12_compania   = cia
          and b12_tipo_comp  = tp
          and b12_num_comp   = num
          and b12_estado    <> 'E'
          and b13_compania   = b12_compania
          and b13_tipo_comp  = b12_tipo_comp
          and b13_num_comp   = b12_num_comp
          and (b13_cuenta   matches '41010102*'
           or  b13_cuenta   matches '41020102*'
           or  b13_cuenta   matches '41020202*')
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
        into temp t2;
drop table t1;

--
select * from t2
	where cuenta        in ('41010102001', '41010102003', '41010102004',
				'41020102001', '41020202001')
	  and abs(valor_mo) <> abs(val_ctb)
union
select * from t2
	where cuenta        in ('41010102005', '41010102006', '41010102007',
				'41010102006', '41010102007', '41010102008',
				'41010102009', '41010102010', '41010102011',
				'41020102002', '41020102003',
				'41020202002', '41020202003')
	  and abs(valor_oc) <> abs(val_ctb);

select * from t2
	where cuenta        in ('41010102103', '41010102104',
				'41020102004', '41020202004')
	  and abs(valor_mo) <> abs(val_ctb)
union
select * from t2
	where cuenta        in ('41010102105', '41010102106', '41010102107',
				'41010102108', '41010102109', '41010102110',
				'41010102111',
				'41020102005', '41020102006',
				'41020202005', '41020202006')
	  and abs(valor_oc) <> abs(val_ctb);
--

drop table t2;

drop table tmp_tal;
drop table tmp_inv;

select a.tp, a.porc, round(nvl(a.tot_sub, 0), 2) tot_sub,
	round(nvl(b.tot_mo, 0), 2) tot_mo,
	round(nvl(b.tot_oc, 0), 2) tot_oc,
	round(nvl(a.tot_sub, 0) + nvl(b.tot_mo, 0) + nvl(b.tot_oc, 0),
		2) tot_gen
	from tmp_t_inv a, outer tmp_t_tal b
	where a.porc = b.porc
	  and a.tp   = b.tp
	into temp t1;
select * from t1 order by 2, 1;
select porc, nvl(sum(tot_gen), 0) tot_gen from t1 group by 1 order by 1;
drop table t1;
drop table tmp_t_inv;
drop table tmp_t_tal;
