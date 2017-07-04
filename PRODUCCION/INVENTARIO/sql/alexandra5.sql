select r19_cod_tran, r20_fecing, r19_vendedor,
	case when r19_cod_tran = 'FA' then
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	else
		nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto),0) * (-1)
	end val_vta	 --case
	from rept019, rept020
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	  and date(r20_fecing) between mdy(01, 01, 2006)
				   and mdy(11, 30, 2006)
	group by 1, 2, 3
	into temp tmp_r20;
select extend(r20_fecing, year to month) fecha, r01_nombres vendedor,
	nvl(round(sum(val_vta), 2), 0) val_vta
	from tmp_r20, rept001
	where r01_compania  = 1
	  and r01_codigo    = r19_vendedor
	group by 1, 2
	into temp t1;
drop table tmp_r20;
create temp table tmp_vta_ven
	(
		anio		smallint,
		vendedor	varchar(30,15),
		val_mes01	decimal(12,2),
		val_mes02	decimal(12,2),
		val_mes03	decimal(12,2),
		val_mes04	decimal(12,2),
		val_mes05	decimal(12,2),
		val_mes06	decimal(12,2),
		val_mes07	decimal(12,2),
		val_mes08	decimal(12,2),
		val_mes09	decimal(12,2),
		val_mes10	decimal(12,2),
		val_mes11	decimal(12,2),
		val_mes12	decimal(12,2),
		total		decimal(12,2)
	);
insert into tmp_vta_ven
	(anio, vendedor, val_mes01, val_mes02, val_mes03, val_mes04, val_mes05,
	 val_mes06, val_mes07, val_mes08, val_mes09, val_mes10, val_mes11,
	 val_mes12, total) 
	select unique year(a.fecha) anio, a.vendedor,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 1
			  and b.vendedor     = a.vendedor), 0) val_mes01,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 2
			  and b.vendedor     = a.vendedor), 0) val_mes02,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 3
			  and b.vendedor     = a.vendedor), 0) val_mes03,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 4
			  and b.vendedor     = a.vendedor), 0) val_mes04,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 5
			  and b.vendedor     = a.vendedor), 0) val_mes05,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 6
			  and b.vendedor     = a.vendedor), 0) val_mes06,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 7
			  and b.vendedor     = a.vendedor), 0) val_mes07,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 8
			  and b.vendedor     = a.vendedor), 0) val_mes08,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 9
			  and b.vendedor     = a.vendedor), 0) val_mes09,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 10
			  and b.vendedor     = a.vendedor), 0) val_mes10,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 11
			  and b.vendedor     = a.vendedor), 0) val_mes11,
		nvl((select b.val_vta
			from t1 b
			where year(b.fecha)  = year(a.fecha)
			  and month(b.fecha) = 12
			  and b.vendedor     = a.vendedor), 0) val_mes12,
		0.00 total
		from t1 a;
update tmp_vta_ven
	set total = val_mes01 + val_mes02 + val_mes03 + val_mes04 + val_mes05 +
			val_mes06 + val_mes07 + val_mes08 + val_mes09 +
			val_mes10 + val_mes11 + val_mes12
	where anio in (select unique year(t1.fecha)
			from t1
			where year(t1.fecha) = anio
			  and t1.vendedor    = vendedor);
drop table t1;
unload to "vend_anio_mes.txt" select * from tmp_vta_ven order by 1, 15 desc, 2;
select * from tmp_vta_ven order by 1, 15 desc, 2;
drop table tmp_vta_ven;
