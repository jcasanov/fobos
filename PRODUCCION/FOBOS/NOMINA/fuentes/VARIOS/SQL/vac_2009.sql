select n39_compania cia, n39_proceso cp, n39_cod_trab cod,n39_periodo_ini p_ini,
	n39_periodo_fin p_fin, n30_nombres[1, 20] empleados,
	n39_valor_vaca val_v, n39_valor_adic val_a,
	round(case when n39_tipo = 'G' and n39_gozar_adic = 'S'
		then n39_valor_vaca + n39_valor_adic
	     when n39_tipo = 'G' and n39_gozar_adic = 'N'
		then n39_valor_vaca
	     when n39_tipo = 'P' and n39_gozar_adic = 'N'
		then 0.00
	end, 2) val_vac,
	b13_cuenta cta, b13_valor_base val_ctb
	from rolt039, rolt030, rolt057, ctbt012, ctbt013
	where n39_ano_proceso  = 2009
	  and year(n39_fecing) = 2009
	  and n30_compania     = n39_compania
	  and n30_cod_trab     = n39_cod_trab
	  and n57_compania     = n39_compania
	  and n57_proceso      = n39_proceso
	  and n57_cod_trab     = n39_cod_trab
	  and n57_periodo_ini  = n39_periodo_ini
	  and n57_periodo_fin  = n39_periodo_fin
	  and b12_compania     = n57_compania
	  and b12_tipo_comp    = n57_tipo_comp
	  and b12_num_comp     = n57_num_comp
	  and b12_estado      <> "E"
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_valor_base   > 0
	into temp t1;
select cod, empleados, val_v, val_a, sum(val_ctb) val_ctb
	from t1
	group by 1, 2, 3, 4
	into temp t2;
{--
select unique t2.cod, t2.empleados, t1.cta cta1, t1.val_ctb, t1.val_vac vac
	from t2, t1
	where t1.cta[1, 1]  = '1'
	  and t2.cod        = t1.cod
	  and t1.val_vac   <> t1.val_ctb
union all
select unique t2.cod, t2.empleados, t1.cta cta1, t1.val_ctb, t1.val_vac vac
	from t2, t1
	where t1.cta[1, 1]  = '5'
	  and t2.cod        = t1.cod
	  and t1.val_vac   <> t1.val_ctb
	into temp t3;
select sum(val_ctb) tot_ctb, sum(vac) tot_vac, sum(val_ctb - vac) dife
	from t3;
select * from t3 order by 2;
drop table t3;
--}
--select unique cod, empleados, val_vac from t1 order by 2;
select sum(val_v) tot_v, sum(val_a) tot_a, sum(val_ctb) tot_ctb
	from t2;
select sum(val_v + val_a) total_v
	from t2;
drop table t2;
select cta[1, 8] cta, sum(val_ctb) val_ctb
	from t1
	group by 1
	order by 1;
drop table t1;
