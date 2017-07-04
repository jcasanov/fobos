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
begin work;
update ctbt013
	set b13_cuenta = '41010104004'
	where b13_compania  = 1
	  and exists (select * from t1
			where tp  = b13_tipo_comp
			  and st  = 52
			  and num = b13_num_comp)
	  and b13_cuenta      = '41010104001'
	  and b13_valor_base >= 0;

update ctbt013
	set b13_cuenta = '41010104001'
	where b13_compania  = 1
	  and exists (select * from t1
			where tp  = b13_tipo_comp
			  and st  = 52
			  and num = b13_num_comp
			  and cta = b13_cuenta)
	  and b13_valor_base <= 0;

update ctbt013
	set b13_cuenta = '41010104003'
	where b13_compania  = 1
	  and exists (select * from t1
			where tp  = b13_tipo_comp
			  and st  = 54
			  and num = b13_num_comp)
	  and b13_cuenta      = '41010104004'
	  and b13_valor_base >= 0;

update ctbt013
	set b13_cuenta = '41010104004'
	where b13_compania  = 1
	  and exists (select * from t1
			where tp  = b13_tipo_comp
			  and st  = 54
			  and num = b13_num_comp)
	  and b13_cuenta      = '41010104001'
	  and b13_valor_base <= 0;
commit work;
