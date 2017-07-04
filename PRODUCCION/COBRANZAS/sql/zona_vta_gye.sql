create temp table t1
	(cia	integer,
	 zona	serial,
	 nomb	varchar(30,15),
	 usua	varchar(10,5),
	 feci	datetime year to second) in datadbs;

select r01_compania as cia_v, r01_nombres as vend
	from rept001
	where r01_compania  = 1
	  and r01_codigo   in (25, 70, 69, 58, 8, 68, 63, 10, 37, 36, 72, 75,
				14, 15, 49, 17, 18, 41)
	into temp t2;

insert into t1
	values (1, 1, "POR ASIGNAR", "FOBOS", current);

insert into t1
	(cia, nomb, usua, feci)
	select cia_v, vend, "FOBOS", current
		from t2;

drop table t2;

begin work;

	update cxct002
		set z02_zona_venta = null
		where 1 = 1;

	delete from gent032 where 1 = 1;

	insert into gent032
		(g32_compania, g32_zona_venta, g32_nombre, g32_usuario,
		 g32_fecing)
		select * from t1;

--rollback work;
commit work;

drop table t1;
