select extend(mdy(n48_mes_proceso, 01, n48_ano_proceso), year to month) fecha,
	nvl(sum(n48_val_jub_pat), 0) val_jub
	from rolt048
	where n48_compania = 1
	  and n48_estado   = 'P'
	group by 1
	into temp t1;
select extend(b12_fec_proceso, year to month) fec_con,
	nvl(sum(b13_valor_base), 0) val_con
	from ctbt012, ctbt013
	where b12_compania     = 1
	  and b12_tipo_comp    = 'EG'
	  and b12_estado       = 'M'
	  and b12_fec_proceso >= mdy(12, 01, 2010)
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta       = '24010101001'
	  and b13_valor_base   > 0
	group by 1
	into temp t2;
select fecha, val_jub, val_con, round(val_jub - val_con, 2) diferencia
	from t1, t2
	where fecha = fec_con
	order by 1;
select round(sum(val_jub), 2) tot_jub from t1;
select round(sum(val_con), 2) tot_jub_con from t2;
drop table t1;
drop table t2;
