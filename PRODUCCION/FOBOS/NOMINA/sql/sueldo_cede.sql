--op table t1;
select n32_fecha_fin fecha, n32_tot_gan total_gan, n32_tot_ing total_ing,
	n32_tot_egr total_des, n32_tot_neto total_neto
	from rolt032
	where n32_compania   = 1
	  and n32_cod_liqrol in ('Q1', 'Q2')
	  and n32_fecha_ini  >= mdy(04,16,2006)
	  and n32_fecha_ini  <= mdy(01,15,2007)
	  and n32_cod_trab    = 21
	into temp t1;
select * from t1 order by 1;
select nvl(sum(total_gan), 0) total_gan,
	nvl(sum(total_ing), 0) total_ing,
	nvl(sum(total_des), 0) total_des,
	nvl(sum(total_neto), 0) total_neto
	from t1;
drop table t1;
