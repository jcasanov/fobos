select b12_compania cia, b12_tipo_comp tp, b12_num_comp num, b13_secuencia sec,
	case when b13_cuenta = '61010101001' then '11400101001'
	     when b13_cuenta = '11400101006' then '11700101001'
	end cuenta
	from ctbt012, ctbt013
	where b12_compania  = 1
	  and b12_estado    = 'M'
	  and b12_subtipo   = 17
	  and b12_glosa     matches '*COMPO*'
	  and b13_compania  = b12_compania
	  and b13_tipo_comp = b12_tipo_comp
	  and b13_num_comp  = b12_num_comp
	into temp t1;
begin work;
	update ctbt013
		set b13_cuenta = (select cuenta
					from t1
					where cia = b13_compania
					  and tp  = b13_tipo_comp
					  and num = b13_num_comp
					  and sec = b13_secuencia)
		where b13_compania = 1
		  and exists (select 1 from t1
				where cia = b13_compania
				  and tp  = b13_tipo_comp
				  and num = b13_num_comp);
--rollback work;
commit work;
drop table t1;
