select r10_codigo as item,
	r10_cod_util as cod_uti,
	r10_precio_mb as pvp,
	r10_cantveh as cant_v
	from rept010
	where r10_compania = 999
	into temp t1;

load from "res_rshow_060814.unl" insert into t1;

create temp table tmp_pre
	(

		compania         integer,
		localidad        smallint,
		item             char(15),
		secuencia        serial,
		precio_act       decimal(11,2),
		precio_ant       decimal(11,2),
		usu_camprec      varchar(10,5),
		fec_camprec      datetime year to second

	) in datadbs lock mode row;

begin work;

	insert into tmp_pre
		(compania, localidad, item, secuencia, precio_act, precio_ant,
		 usu_camprec, fec_camprec) 
		select 1, 1, item, 0, pvp, r10_precio_mb, "HSALAZAR", current
			from t1, rept010
			where r10_compania = 1
			  and r10_codigo   = item;

	update rept010
		set r10_cod_util    = (select cod_uti
					from t1
					where item = r10_codigo),
		    r10_cantveh     = (select cant_v
					from t1
					where item = r10_codigo),
		    r10_precio_ant  = r10_precio_mb,
		    r10_precio_mb   = (select pvp
					from t1
					where item = r10_codigo),
		    r10_fec_camprec = current
		where r10_compania  = 1
		  and r10_codigo   in (select item from t1);

	insert into rept087
		(r87_compania, r87_localidad, r87_item, r87_secuencia,
		 r87_precio_act, r87_precio_ant, r87_usu_camprec,
		 r87_fec_camprec) 
		select * from tmp_pre;

rollback work;
--commit work;

drop table t1;
drop table tmp_pre;
