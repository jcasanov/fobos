select n32_cod_trab cod, n30_nombres[1, 25] empleados,
	nvl(sum(n32_tot_gan), 0) tot_gan
	from rolt032, rolt030
	where n32_compania   in (1, 2)
	  and n32_cod_liqrol in ('Q1', 'Q2')
	  and n32_fecha_ini  >= mdy (07,01,2008)
	  and n32_fecha_fin  <= mdy (07,31,2008)
	  and n30_compania    = n32_compania
	  and n30_cod_trab    = n32_cod_trab
	group by 1, 2
	into temp t1;
select round(nvl(sum(tot_gan), 0), 2) tot_emp from t1;
select * from t1 order by 2;
select n33_cod_trab cod2, n30_nombres[1, 25] empleados2,
	nvl(sum(n33_valor), 0) tot_det
	from rolt033, rolt030
	where n33_compania   in (1, 2)
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy (07,01,2008)
	  and n33_fecha_fin  <= mdy (07,31,2008)
	  and n33_cod_rubro  in (select n08_rubro_base
					from rolt008, rolt006
					where n08_cod_rubro  = n06_cod_rubro
					  and n06_flag_ident = 'AP')
	  and n33_valor       > 0
	  and n30_compania    = n33_compania
	  and n30_cod_trab    = n33_cod_trab
	group by 1, 2
	into temp t2;
select round(nvl(sum(tot_det), 0), 2) tot_emp2 from t2;
select * from t2 order by 2;
select * from t1, t2
	where cod      = cod2
	  and tot_gan <> tot_det;
drop table t1;
drop table t2;
