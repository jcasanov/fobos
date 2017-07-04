--drop table t1;
set isolation to dirty read;
{
select b12_subtipo, count(*) tot_tipo
	from ctbt012, ctbt013
        where b12_compania   = 1
	  and b12_tipo_comp  = 'DR'
          and b12_estado     = 'M'
          and extend(b12_fec_proceso, year to month) = '2007-08'
          and b13_compania   = b12_compania
          and b13_tipo_comp  = b12_tipo_comp
          and b13_num_comp   = b12_num_comp
	  and b13_cuenta     = '21040201001'
	group by 1;
}
select b12_tipo_comp tp, b12_num_comp num, b12_subtipo st, b13_cuenta cta,
	b13_valor_base valor
	from ctbt012, ctbt013
        where b12_compania   = 1
	  and b12_tipo_comp  = 'DR'
          and b12_estado     = 'M'
	  and b12_subtipo    in (52)
          and extend(b12_fec_proceso, year to month) = '2007-08'
          and b13_compania   = b12_compania
          and b13_tipo_comp  = b12_tipo_comp
          and b13_num_comp   = b12_num_comp
          and b13_cuenta     <> '41010104001'
	  and b13_cuenta     <> '21040201001'
          and b13_valor_base <= 0
union
select b12_tipo_comp tp, b12_num_comp num, b12_subtipo st, b13_cuenta cta,
	b13_valor_base valor
	from ctbt012, ctbt013
        where b12_compania   = 1
	  and b12_tipo_comp  = 'DR'
          and b12_estado     = 'M'
	  and b12_subtipo    in (54)
          and extend(b12_fec_proceso, year to month) = '2007-08'
          and b13_compania   = b12_compania
          and b13_tipo_comp  = b12_tipo_comp
          and b13_num_comp   = b12_num_comp
          and b13_cuenta     <> '41010104003'
	  and b13_cuenta     <> '21040201001'
          and b13_valor_base >= 0
	into temp t1;
select count(*) tot_reg from t1;
select * from t1 order by 2;
select round(sum(valor), 2) total from t1 into temp t2;
select total, round(total * 12 / 100, 2) iva from t2;
{
unload to "rept040_sur.unl"
	select r40_localidad, r40_cod_tran, r40_num_tran, r40_tipo_comp,
		r40_num_comp
		from rept040
		where r40_compania  = 1
		  and r40_localidad = 4
		  and exists (select * from t1
				where tp  = r40_tipo_comp
				  and num = r40_num_comp)
}
drop table t1;
drop table t2;
