select n32_compania cia, n32_cod_liqrol lq, n32_fecha_ini fec_ini,
	n32_fecha_fin fec_fin, n53_tipo_comp tipo_comp, n53_num_comp num_comp,
	nvl(sum(n32_tot_neto), 0) tot_nomina
	from rolt032, rolt053
	where n32_compania   = 1
	  and n32_cod_liqrol in ('Q1', 'Q2')
	  and n32_estado     = 'P'
	  and n53_compania   = n32_compania
	  and n53_cod_liqrol = n32_cod_liqrol
	  and n53_fecha_ini  = n32_fecha_ini
	  and n53_fecha_fin  = n32_fecha_fin
	group by 1, 2, 3, 4, 5, 6
	into temp t1;
select cia n53_compania, lq n53_cod_liqrol, fec_ini n53_fecha_ini,
	fec_fin n53_fecha_fin, tipo_comp n53_tipo_comp, num_comp n53_num_comp,
	nvl(sum(b13_valor_base), 0) tot_cont
	from t1, ctbt012, ctbt013
	where b12_compania   = cia
	  and b12_tipo_comp  = tipo_comp
	  and b12_num_comp   = num_comp
	  and b12_estado     = 'M'
	  and b13_compania   = b12_compania
	  and b13_tipo_comp  = b12_tipo_comp
	  and b13_num_comp   = b12_num_comp
	  and b13_valor_base > 0
	group by 1, 2, 3, 4, 5, 6
	into temp t2;
select t1.* from t1, t2
	where n53_compania    = cia
	  and n53_cod_liqrol  = lq
	  and n53_fecha_ini   = fec_ini
	  and n53_fecha_fin   = fec_ini
	  and n53_tipo_comp   = tipo_comp
	  and n53_num_comp    = num_comp
	  and tot_cont       <> tot_nomina
	into temp t3;
drop table t1;
drop table t2;
select count(*) tot_nom_des from t3;
select * from t3 order by fec_ini;
drop table t3;
