set isolation to dirty read;

select r21_compania cia, r21_localidad loc, r21_numprof num_p, r21_cod_tran tp,
	r21_num_tran num_f
	from rept021
	where r21_bodega = '30'
	into temp t1;

select r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num,
	r19_tipo_dev tip_d, r19_num_dev num_d
	from rept019
	where exists
		(select 1 from t1
			where cia   = r19_compania
			  and loc   = r19_localidad
			  and tp    = r19_cod_tran
			  and num_f = r19_num_tran)
	into temp t2;

--select * from t2;

begin work;

	update rept021
		set r21_bodega = (select r00_bodega_fact
					from rept000
					where r00_compania = r21_compania)
		where r21_compania  = 1
		  and r21_localidad in (3, 5)
		  and r21_numprof   in (select num_p
					from t1
					where cia = r21_compania
					  and loc = r21_localidad);

	update rept023
		set r23_bodega = (select r00_bodega_fact
					from rept000
					where r00_compania = r23_compania)
		where r23_compania  = 1
		  and r23_localidad in (3, 5)
		  and r23_numprof   in (select num_p
					from t1
					where cia = r23_compania
					  and loc = r23_localidad);

	update rept019
		set r19_bodega_ori  = (select r00_bodega_fact
					from rept000
					where r00_compania = r19_compania),
		    r19_bodega_dest = (select r00_bodega_fact
					from rept000
					where r00_compania = r19_compania)
		where r19_compania  = 1
		  and r19_localidad in (3, 5)
		  and exists
			(select 1 from t2
				where cia = r19_compania
				  and loc = r19_localidad
				  and tp  = r19_cod_tran
				  and num = r19_num_tran);

	update rept019
		set r19_bodega_ori  = (select r00_bodega_fact
					from rept000
					where r00_compania = r19_compania),
		    r19_bodega_dest = (select r00_bodega_fact
					from rept000
					where r00_compania = r19_compania)
		where r19_compania  = 1
		  and r19_localidad in (3, 5)
		  and exists
			(select 1 from t2
				where cia   = r19_compania
				  and loc   = r19_localidad
				  and tip_d = r19_cod_tran
				  and num_d = r19_num_tran);

commit work;
--rollback work;

drop table t1;
drop table t2;
