--delete from srit021 where 1 = 1;
select r19_cod_tran ct, extend(r19_fecing, year to month) mes,
	count(*) tot_reg,
	sum(r19_tot_bruto - r19_tot_dscto) total_r19
	from rept019
	where r19_cod_tran in ('DF', 'FA')
	  and extend(r19_fecing, year to month) = '2017-11'
	group by 1, 2
	order by 2 desc;
select s21_tipo_comp tc, trim(s21_anio || '-' || s21_mes) mes,
	count(*) tot_reg, sum(s21_bas_imp_gr_iva) total_s21
	from srit021
	where s21_anio = 2017
	  and s21_mes  = 11
	group by 1, 2;
