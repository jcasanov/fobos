select unique a12_compania cia, a12_codigo_tran cod_tran,
	case when a12_codigo_tran = 'IN' then 60
	     when a12_codigo_tran = 'DP' then 61
	     when a12_codigo_tran = 'BA' then 62
	     when a12_codigo_tran = 'VE' then 63
	     when a12_codigo_tran = 'EG' then 65
	end subtipo_af,
	a12_tipcomp_gen tipo_comp, a12_numcomp_gen num_comp
	from actt012
	where a12_tipcomp_gen is not null
	into temp t1;
select count(*) tot_t1 from t1;
select tipo_comp tc, num_comp num_c
	from t1
	where cod_tran = 'EG'
	into temp t2;
delete from t1
	where cod_tran = 'IN'
	  and exists (select * from t2
			where tc    = tipo_comp
			  and num_c = num_comp);
select count(*) tot_reg from t1;
drop table t2;
--select * from t1 order by tipo_comp, num_comp;
begin work;
	update ctbt012
		set b12_subtipo = (select subtipo_af
					from t1
					where cia       = b12_compania
					  and tipo_comp = b12_tipo_comp
					  and num_comp  = b12_num_comp)
		where exists (select 1 from t1
				where cia       = b12_compania
				  and tipo_comp = b12_tipo_comp
				  and num_comp  = b12_num_comp);
commit work;
drop table t1;
