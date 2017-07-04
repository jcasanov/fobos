select a.r19_compania cia, a.r19_localidad loc, a.r19_cod_tran tp,
	a.r19_num_tran num, date(a.r19_fecing) fecha, 'S' cruce
	from rept019 a
	where a.r19_cod_tran     in ('FA', 'NV')
	  and a.r19_tipo_dev     is null
	  and year(a.r19_fecing)  = 2009
	  and exists
		(select 1 from rept019 b, rept041
			where b.r19_compania  = a.r19_compania
			  and b.r19_localidad = a.r19_localidad
			  and b.r19_cod_tran  = 'TR'
			  and b.r19_tipo_dev  = a.r19_cod_tran
			  and b.r19_num_dev   = a.r19_num_tran
			  and r41_compania    = b.r19_compania
			  and r41_localidad   = b.r19_localidad
			  and r41_cod_tr      = b.r19_cod_tran
			  and r41_num_tr      = b.r19_num_tran)
union
select a.r19_compania cia, a.r19_localidad loc, a.r19_cod_tran tp,
	a.r19_num_tran num, date(a.r19_fecing) fecha, 'N' cruce
	from rept019 a
	where a.r19_cod_tran     in ('FA', 'NV')
	  and a.r19_tipo_dev     is null
	  and year(a.r19_fecing)  = 2009
	  and not exists
		(select 1 from rept019 b, rept041
			where b.r19_compania  = a.r19_compania
			  and b.r19_localidad = a.r19_localidad
			  and b.r19_cod_tran  = 'TR'
			  and b.r19_tipo_dev  = a.r19_cod_tran
			  and b.r19_num_dev   = a.r19_num_tran
			  and r41_compania    = b.r19_compania
			  and r41_localidad   = b.r19_localidad
			  and r41_cod_tr      = b.r19_cod_tran
			  and r41_num_tr      = b.r19_num_tran)
	order by 5 desc;
