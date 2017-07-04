select date(r19_fecing) fec, r19_localidad loc, r19_cod_tran tp,
	r19_num_tran num, r19_tipo_dev td, r19_nomcli cliente,r19_tot_neto total
	from rept019
	where r19_compania      = 1
	  and r19_localidad    in (3, 5)
	  and r19_cod_tran     in ("FA", "DF")
	  and year(r19_fecing)  = 2013
	  and not exists
		(select 1 from rept040
			where r40_compania  = r19_compania
			  and r40_localidad = r19_localidad
			  and r40_cod_tran  = r19_cod_tran
			  and r40_num_tran  = r19_num_tran)
	order by 1;
