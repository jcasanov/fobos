select z01_num_doc_id, z01_nomcli, r19_flete
	from rept019, cxct001
	where r19_compania  = 10
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r19_tipo_dev  is null
	  and r19_flete     > 0
	  and date(r19_fecing) between mdy(6,1,2003) and mdy(6,30,2003)
	  and z01_codcli    = r19_codcli
	into temp t1;
insert into t1
	select z01_num_doc_id, z01_nomcli, r19_flete
		from rept019, cxct001
		where r19_compania  = 1
		  and r19_localidad = 1
		  and r19_cod_tran  = 'FA'
		  and r19_tipo_dev  is null
		  and r19_flete     > 0
		  and date(r19_fecing) between mdy(6,1,2003) and mdy(6,30,2003)
		  and z01_codcli    = r19_codcli;
insert into t1
	select z01_num_doc_id, z01_nomcli, r19_flete
		from acero_gc:rept019, acero_gc:cxct001
		where r19_compania  = 1
		  and r19_localidad = 2
		  and r19_cod_tran  = 'FA'
		  and r19_tipo_dev  is null
		  and r19_flete     > 0
		  and date(r19_fecing) between mdy(6,1,2003) and mdy(6,30,2003)
		  and z01_codcli    = r19_codcli;
unload to "vent_exec2003.txt"
	select z01_num_doc_id, z01_nomcli, sum(r19_flete) flete
		from t1
		group by 1, 2
		order by 2 asc;
drop table t1;
