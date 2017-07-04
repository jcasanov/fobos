select b13_compania cia, b13_tipo_comp tp, b13_num_comp num, b13_cuenta cta
	from ctbt012, ctbt013
	where b12_compania     = 2
	  and b12_estado      <> 'E'
	  and b12_origen       = 'A'
	  and b12_fec_proceso between mdy(01,01,2006) and mdy(12,31,2006)
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta       = '11010101007'
	into temp t1;
select count(*) tot_reg from t1;
begin work;
	update ctbt013
		set b13_cuenta = '11010101005'
		where exists (select * from t1
				where cia = b13_compania
				  and tp  = b13_tipo_comp
				  and num = b13_num_comp
				  and cta = b13_cuenta);
commit work;
drop table t1;
