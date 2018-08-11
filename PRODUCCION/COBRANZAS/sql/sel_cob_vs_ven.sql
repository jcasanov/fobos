create function fecha_ini() returning date;

	define fecha	date;

	let fecha = mdy(01, 01, 2003);

	return fecha;

end function;

select unique z22_compania cia, z22_localidad loc, z22_codcli codcli
	from cxct022
	where date(z22_fecing) between fecha_ini() and today
	into temp tmp_cli;
select count(*) tot_cli from tmp_cli;

select r19_localidad local, r19_codcli cli, nvl(sum(r19_tot_neto), 0) val_vta
	from rept019
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and r19_cont_cred    = 'R'
	  and date(r19_fecing) between fecha_ini() and today
	group by 1, 2
union all
	select r19_localidad local, r19_codcli cli,
		nvl(sum(r19_tot_neto), 0) val_vta
		from acero_gc:rept019
		where r19_compania     = 1
		  and r19_localidad    = 2
		  and r19_cod_tran     in ('FA', 'DF', 'AF')
		  and r19_cont_cred    = 'R'
		  and date(r19_fecing) between fecha_ini() and today
		group by 1, 2
union all
	select t23_localidad local, t23_cod_cliente cli,
		nvl(sum(t23_tot_neto), 0) val_vta
		from talt023
		where t23_compania          = 1
		  and t23_localidad         = 1
		  and t23_cont_cred         = 'R'
		  and t23_estado            in ('F', 'D')
		  and t23_num_factura       is not null
		  and date(t23_fec_factura) between fecha_ini() and today
		group by 1, 2
	into temp t1;

select r25_localidad local, r19_codcli cli,
	nvl(sum(r25_valor_cred), 0) val_apr
	from rept019, rept025
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and r19_cont_cred    = 'R'
	  and date(r19_fecing) between fecha_ini() and today
	  and r25_compania     = r19_compania
	  and r25_localidad    = r19_localidad
	  and r25_cod_tran     = r19_cod_tran
	  and r25_num_tran     = r19_num_tran
	group by 1, 2
union all
	select r25_localidad local, r19_codcli cli,
		nvl(sum(r25_valor_cred), 0) val_apr
		from acero_gc:rept019, acero_gc:rept025
		where r19_compania     = 1
		  and r19_localidad    = 2
		  and r19_cod_tran     in ('FA', 'DF', 'AF')
		  and r19_cont_cred    = 'R'
		  and date(r19_fecing) between fecha_ini() and today
		  and r25_compania     = r19_compania
		  and r25_localidad    = r19_localidad
		  and r25_cod_tran     = r19_cod_tran
		  and r25_num_tran     = r19_num_tran
		group by 1, 2
union all
	select t25_localidad local, t23_cod_cliente cli,
		nvl(sum(t25_valor_cred), 0) val_apr
		from talt023, talt025
		where t23_compania          = 1
		  and t23_localidad         = 1
		  and t23_cont_cred         = 'R'
		  and t23_estado            in ('F', 'D')
		  and t23_num_factura       is not null
		  and date(t23_fec_factura) between fecha_ini() and today
		  and t25_compania          = t23_compania
		  and t25_localidad         = t23_localidad
		  and t25_orden             = t23_orden
		group by 1, 2
	into temp t2;

update t2
	set val_apr = val_apr +
			nvl((select sum(z20_valor_cap + z20_valor_int)
			from cxct020
			where z20_compania   = 1
			  and z20_localidad  = local
			  and z20_codcli     = cli
			  and z20_tipo_doc   = 'FA'
			  and z20_fecha_emi <=
					(select z60_fecha_carga from cxct060
					where z60_compania  = z20_compania
					  and z60_localidad = z20_localidad)),0)
	where exists (select z20_compania, z20_localidad, z20_codcli,
				z20_tipo_doc, z20_num_doc, z20_dividendo
			from cxct020
			where z20_compania   = 1
			  and z20_localidad  = local
			  and z20_codcli     = cli
			  and z20_tipo_doc   = 'FA'
			  and z20_fecha_emi <=
					(select z60_fecha_carga from cxct060
					where z60_compania  = z20_compania
					  and z60_localidad = z20_localidad));

select z22_localidad local, z22_codcli cli,
	nvl(sum(z23_valor_cap + z23_valor_int), 0) * (-1) val_cob
	from cxct020, cxct023, cxct022
	where z20_compania     = 1
	  and z23_compania     = z20_compania
	  and z23_localidad    = z20_localidad
	  and z23_codcli       = z20_codcli
	  and z23_tipo_doc     = z20_tipo_doc
	  and z23_num_doc      = z20_num_doc
	  and z23_div_doc      = z20_dividendo
	  and z22_compania     = z23_compania
	  and z22_localidad    = z23_localidad
	  and z22_codcli       = z23_codcli
	  and z22_tipo_trn     = z23_tipo_trn
	  and z22_num_trn      = z23_num_trn
	  and date(z22_fecing) between fecha_ini() and today
	group by 1, 2
	into temp t3;

select loc, codcli, nvl((select sum(val_vta) from t1
			where local = loc
			  and cli   = codcli), 0) val_vta,
		nvl((select sum(val_apr) from t2
			where local = loc
			  and cli   = codcli), 0) val_apr,
		nvl((select val_cob from t3
			where local = loc
			  and cli   = codcli), 0) val_cob
	from tmp_cli
	group by 1, 2, 3, 4, 5
	into temp t4;

drop table t1;
drop table t2;
drop table t3;
drop table tmp_cli;

delete from t4 where val_vta = 0 and val_apr = 0;

select round(nvl(sum(val_vta), 0), 2) tot_vta,
	round(nvl(sum(val_apr), 0), 2) tot_apr,
	round(nvl(sum(val_cob), 0), 2) tot_cob
	from t4;

create temp table tmp_cobven
	(
		codcli		integer,
		val_vta		decimal(12,2),
		val_apr		decimal(12,2),
		val_cob		decimal(12,2),
		val_dif		decimal(12,2)
	);

insert into tmp_cobven
	select codcli, round(nvl(sum(val_vta), 0), 2) val_vta,
		round(nvl(sum(val_apr), 0), 2) val_apr,
		round(nvl(sum(val_cob), 0), 2) val_cob,
		round(nvl(sum(val_vta), 0) - nvl(sum(val_cob), 0), 2) val_dif
		from t4
		group by 1;

drop table t4;

select count(*) tot_cli_cred from tmp_cobven;
select * from tmp_cobven order by 2 desc, 3 desc;

select round(nvl(sum(val_vta), 0), 2) tot_vta,
	round(nvl(sum(val_apr), 0), 2) tot_apr,
	round(nvl(sum(val_cob), 0), 2) tot_cob,
	round(nvl(sum(val_dif), 0), 2) tot_dif
	from tmp_cobven;

drop table tmp_cobven;
drop function fecha_ini;
