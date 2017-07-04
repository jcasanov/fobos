select date(t23_fec_factura) fecha_tran, t23_num_factura num_tran,
	t23_orden ord_t, t23_tot_bruto valor_mo, t23_tot_bruto valor_fa,
	t23_tot_bruto valor_oc, t23_tot_bruto valor_tot, t23_estado est,
	t23_cod_cliente codcli, t23_nom_cliente nomcli
	from talt023
	where t23_compania = 17
	into temp tmp_det;
insert into tmp_det
	select case when t23_estado = 'D'
			then (select date(t28_fec_anula)
				from talt028
				where t28_compania  = t23_compania
				  and t28_localidad = t23_localidad
				  and t28_factura   = t23_num_factura)
			else date(t23_fec_factura)
		end,
		case when t23_estado = 'D'
			then (select t28_num_dev
				from talt028
				where t28_compania  = t23_compania
				  and t28_localidad = t23_localidad
				  and t28_factura   = t23_num_factura)
			else t23_num_factura
		end,
		case when t23_estado = 'D'
			then (select t28_ot_ant
				from talt028
				where t28_compania  = t23_compania
				  and t28_localidad = t23_localidad
				  and t28_factura   = t23_num_factura)
			else t23_orden
		end,
		case when t23_estado = 'F'
			then t23_val_mo_tal
			else t23_val_mo_tal * (-1)
		end,
		case when t23_estado = 'F' then
			(select nvl(sum((c11_precio - c11_val_descto) *
				(1 + c10_recargo / 100)), 0)
				from ordt010, ordt011
				where c10_compania    = t23_compania
				  and c10_localidad   = t23_localidad
				  and c10_ord_trabajo = t23_orden
				  and c11_compania    = c10_compania
				  and c11_localidad   = c10_localidad
				  and c11_numero_oc   = c10_numero_oc
				  and c11_tipo        = 'S') +
			(select nvl(sum(((c11_cant_ped * c11_precio) -
				c11_val_descto) * (1 + c10_recargo / 100)), 0)
				from ordt010, ordt011
				where c10_compania    = t23_compania
				  and c10_localidad   = t23_localidad
				  and c10_ord_trabajo = t23_orden
				  and c11_compania    = c10_compania
				  and c11_localidad   = c10_localidad
				  and c11_numero_oc   = c10_numero_oc
				  and c11_tipo        = 'B') +
			t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti +
			t23_val_otros2
			else (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
				+ t23_val_rp_ext + t23_val_rp_cti +
				t23_val_otros2) * (-1)
		end,
		case when t23_estado = 'F' then
			(select nvl(sum(r19_tot_neto - r19_tot_dscto), 0)
				from rept019
				where r19_compania    = t23_compania
				  and r19_localidad   = t23_localidad
				  and r19_cod_tran    = 'FA'
				  and r19_ord_trabajo = t23_orden)
		     when t23_estado = 'D' then
			(select nvl(sum(r19_tot_neto - r19_tot_dscto), 0) *(-1)
				from rept019
				where r19_compania    = t23_compania
				  and r19_localidad   = t23_localidad
				  and r19_cod_tran    IN ('AF', 'DF')
				  and r19_ord_trabajo = t23_orden)
			else 0
		end,
	0 tot_ot, t23_estado, t23_cod_cliente, t23_nom_cliente
	from talt023, outer talt028
	where t23_compania          = 1
	  and t23_localidad         = 1
	  and t23_estado            = 'F'
	  and date(t23_fec_factura) between mdy(01, 01, 2003) and today
	  and t28_compania          = t23_compania
	  and t28_localidad         = t23_localidad
	  and t28_factura           = t23_num_factura
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
insert into tmp_det
	select case when t23_estado = 'D'
			then (select date(t28_fec_anula)
				from talt028
				where t28_compania  = t23_compania
				  and t28_localidad = t23_localidad
				  and t28_factura   = t23_num_factura)
			else date(t23_fec_factura)
		end,
		case when t23_estado = 'D'
			then (select t28_num_dev
				from talt028
				where t28_compania  = t23_compania
				  and t28_localidad = t23_localidad
				  and t28_factura   = t23_num_factura)
			else t23_num_factura
		end,
		case when t23_estado = 'D'
			then (select t28_ot_ant
				from talt028
				where t28_compania  = t23_compania
				  and t28_localidad = t23_localidad
				  and t28_factura   = t23_num_factura)
			else t23_orden
		end,
		case when t23_estado = 'F'
			then t23_val_mo_tal
			else t23_val_mo_tal * (-1)
		end,
		case when t23_estado = 'F' then
			(select nvl(sum((c11_precio - c11_val_descto) *
				(1 + c10_recargo / 100)), 0)
				from ordt010, ordt011
				where c10_compania    = t23_compania
				  and c10_localidad   = t23_localidad
				  and c10_ord_trabajo = t23_orden
				  and c11_compania    = c10_compania
				  and c11_localidad   = c10_localidad
				  and c11_numero_oc   = c10_numero_oc
				  and c11_tipo        = 'S') +
			(select nvl(sum(((c11_cant_ped * c11_precio) -
				c11_val_descto) * (1 + c10_recargo / 100)), 0)
				from ordt010, ordt011
				where c10_compania    = t23_compania
				  and c10_localidad   = t23_localidad
				  and c10_ord_trabajo = t23_orden
				  and c11_compania    = c10_compania
				  and c11_localidad   = c10_localidad
				  and c11_numero_oc   = c10_numero_oc
				  and c11_tipo        = 'B') +
			t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti +
			t23_val_otros2
			else (t23_val_mo_ext + t23_val_mo_cti + t23_val_rp_tal
				+ t23_val_rp_ext + t23_val_rp_cti +
				t23_val_otros2) * (-1)
		end,
		case when t23_estado = 'F' then
			(select nvl(sum(r19_tot_neto - r19_tot_dscto), 0)
				from rept019
				where r19_compania    = t23_compania
				  and r19_localidad   = t23_localidad
				  and r19_cod_tran    = 'FA'
				  and r19_ord_trabajo = t23_orden)
		     when t23_estado = 'D' then
			(select nvl(sum(r19_tot_neto - r19_tot_dscto), 0) *(-1)
				from rept019
				where r19_compania    = t23_compania
				  and r19_localidad   = t23_localidad
				  and r19_cod_tran    IN ('AF', 'DF')
				  and r19_ord_trabajo = t23_orden)
			else 0
		end,
	0 tot_ot, t23_estado, t23_cod_cliente, t23_nom_cliente
	from talt023, talt028
	where t23_compania        = 1
	  and t23_localidad       = 1
	  and t23_estado          = 'D'
	  and t28_compania        = t23_compania
	  and t28_localidad       = t23_localidad
	  and t28_factura         = t23_num_factura
	  and date(t28_fec_anula) between mdy(01, 01, 2003) and today
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
select fecha_tran, num_tran, ord_t, round(valor_mo, 2) valor_mo,
	round(valor_fa, 2) valor_fa, round(valor_oc, 2) valor_oc,
	round(valor_mo + valor_fa + valor_oc, 2) valor_tot, est,
	codcli, nomcli
	from tmp_det
	into temp t1;
drop table tmp_det;
select round(sum(valor_tot), 2) from t1 where codcli = 4367;
select * from t1 where codcli = 4367 order by 1 desc;
drop table t1;
