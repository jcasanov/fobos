select r41_compania cia, r41_localidad loc, r41_cod_tran tp, r41_num_tran num,
	r88_num_fact_nue num_n
	from rept041, rept088
	where r41_cod_tran  = 'FA'
	  and r88_compania  = r41_compania
	  and r88_localidad = r41_localidad
	  and r88_cod_fact  = r41_cod_tran
	  and r88_num_fact  = r41_num_tran
	into temp t1;
begin work;
	update rept041
		set r41_num_tran = (select num_n
					from t1
					where cia = r41_compania
					  and loc = r41_localidad
					  and tp  = r41_cod_tran
					  and num = r41_num_tran)
		where r41_cod_tran  = 'FA'
		  and exists (select 1 from t1
				where cia = r41_compania
				  and loc = r41_localidad
				  and tp  = r41_cod_tran
				  and num = r41_num_tran);
commit work;
drop table t1;
