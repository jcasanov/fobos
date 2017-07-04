select r21_compania cia, r21_localidad loc, r21_numprof num, 70 vend
	from rept021
	where r21_compania      = 1
	  and r21_localidad     = 1
	  and r21_vendedor      = 66
	  and date(r21_fecing) >= mdy (06, 01, 2012)
	into temp tmp_r21;

select r23_compania cia, r23_localidad loc, r23_numprev num, 70 vend
	from rept023
	where r23_compania      = 1
	  and r23_localidad     = 1
	  and r23_vendedor      = 66
	  and date(r23_fecing) >= mdy (06, 01, 2012)
	into temp tmp_r23;

select r19_compania cia, r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	70 vend, date(r19_fecing) fecha, r01_user_owner usuario,
	r19_cont_cred contcred
	from rept019, rept001
	where r19_compania      = 1
	  and r19_localidad     = 1
	  and r19_vendedor      = 66
	  and date(r19_fecing) >= mdy (06, 01, 2012)
	  and r01_compania      = r19_compania
	  and r01_codigo        = r19_vendedor
	into temp tmp_r19;

begin work;

	update rept021
		set r21_vendedor = (select vend
					from tmp_r21
					where cia = r21_compania
					  and loc = r21_localidad
					  and num = r21_numprof)
	where r21_compania  = 1
	  and r21_localidad = 1
	  and r21_vendedor  = 66
	  and exists (select 1 from tmp_r21
			where cia = r21_compania
			  and loc = r21_localidad
			  and num = r21_numprof);

	update rept023
		set r23_vendedor = (select vend
					from tmp_r23
					where cia = r23_compania
					  and loc = r23_localidad
					  and num = r23_numprev)
	where r23_compania  = 1
	  and r23_localidad = 1
	  and r23_vendedor  = 66
	  and exists (select 1 from tmp_r23
			where cia = r23_compania
			  and loc = r23_localidad
			  and num = r23_numprev);

	update rept019
		set r19_vendedor = (select vend
					from tmp_r19
					where cia = r19_compania
					  and loc = r19_localidad
					  and cod = r19_cod_tran
					  and num = r19_num_tran)
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_vendedor  = 66
	  and exists (select 1 from tmp_r19
			where cia = r19_compania
			  and loc = r19_localidad
			  and cod = r19_cod_tran
			  and num = r19_num_tran);

	update cajt010
		set j10_usuario = (select usuario
					from tmp_r19
					where cia      = j10_compania
					  and loc      = j10_localidad
					  and cod      = j10_tipo_destino
					  and num      = j10_num_destino
					  and contcred = 'C')
		where j10_compania    = 1
		  and j10_localidad   = 1
		  and j10_tipo_fuente = 'PR'
		  and j10_valor       > 0
		  and exists (select 1 from tmp_r19
				where cia      = j10_compania
				  and loc      = j10_localidad
				  and cod      = j10_tipo_destino
				  and num      = j10_num_destino
				  and contcred = 'C');

{--
select tmp_r19.*, r20_bodega bod, r20_linea divi
	from tmp_r19, rept020
	where r20_compania  = cia
	  and r20_localidad = loc
	  and r20_cod_tran  = cod
	  and r20_num_tran  = num
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	into temp t1;

	update rept060
		set r60_vendedor = 70
		where r60_compania  = 1
		  and r60_fecha    >= mdy (06, 01, 2012)
		  and exists
			(select 1 from t1
				where cia   = r60_compania
				  and fecha = r60_fecha
				  and bod   = r60_bodega
				  and divi  = r60_linea);
--}

--rollback work;
commit work;

drop table tmp_r19;
drop table tmp_r21;
drop table tmp_r23;

--drop table t1;
