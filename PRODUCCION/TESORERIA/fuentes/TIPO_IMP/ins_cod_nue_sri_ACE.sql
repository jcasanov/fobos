begin work;

{------------------------------------------------------------------------------}
{--- REG. CODIGOS SRI NUEVOS QUE SE CREAN EN TABLA DE CONFIGURACION ordt003 ---}
{------------------------------------------------------------------------------}

	insert into ordt003
		values (1, 'F', 1.00, 340, "A",
			"Otras retenciones aplicables el 1%, 2%, 8% y 25%",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'F', 2.00, 308, "A", "Servicios entre sociedades",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'F', 2.00, 341, "A",
			"Otras retenciones aplicables el 1%, 2%, 8% y 25%",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'F', 8.00, 304, "A", "Predomina el intelecto",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'F', 8.00, 342, "A",
			"Otras retenciones aplicables el 1%, 2%, 8% y 25%",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'F', 25.00, 343, "A",
			"Otras retenciones aplicables el 1%, 2%, 8% y 25%",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'I', 30.00, 721, "A", "IVA por la compra de bienes",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'I', 70.00, 723, "A",
			"IVA por la prestacióe otros servicios",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

	insert into ordt003
		values (1, 'I', 100.00, 725, "A",
			"IVA por la Prestacióe Serivicios Profesionales",
			mdy(02, 01, 2009), null, "N", null, null, null, null,
			"FOBOS", current);

{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}



{------------------------------------------------------------------------------}
{-- REG. CODIGOS SRI NUEVOS QUE SE ACTUALIZAN EN LA TABLA DE CONFIG. cxpt005 --}
{------------------------------------------------------------------------------}

	select * from cxpt005
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 1.00
		  and p05_codigo_sri in ('309', '310', '311', '312')
		into temp t1;
	delete from cxpt005
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 1.00
		  and p05_codigo_sri in ('309', '310', '311', '312');
	update t1 set p05_codigo_sri = '340' where 1 = 1;
	select unique p05_compania, p05_codprov, p05_tipo_ret, p05_porcentaje,
		p05_codigo_sri
		from t1
		into temp t2;
	drop table t1;
	insert into cxpt005 select * from t2;
	drop table t2;

	update cxpt005
		set p05_codigo_sri = '312'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 1.00
		  and p05_codigo_sri = '307';

	select * from cxpt005
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 1.00
		  and p05_codigo_sri = '313'
		into temp t1;
	delete from cxpt005
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 1.00
		  and p05_codigo_sri = '313';
	update t1 set p05_codigo_sri = '310' where 1 = 1;
	insert into cxpt005
		select * from t1
			where not exists
				(select 1 from cxpt005 a
				where a.p05_compania   = t1.p05_compania
				  and a.p05_tipo_ret   = t1.p05_tipo_ret
				  and a.p05_porcentaje = t1.p05_porcentaje
				  and a.p05_codigo_sri = t1.p05_codigo_sri);
	drop table t1;

	update cxpt005
		set p05_codigo_sri = '309'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 1.00
		  and p05_codigo_sri = '318';

	update cxpt005
		set p05_codigo_sri = '307'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 2.00
		  and p05_codigo_sri = '329';

	update cxpt005
		set p05_codigo_sri = '341'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 2.00
		  and p05_codigo_sri = '331';

	update cxpt005
		set p05_codigo_sri = '342'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 8.00
		  and p05_codigo_sri = '316';

	select * from cxpt005
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 8.00
		  and p05_codigo_sri in ('303', '342')
		into temp t1;
	update t1 set p05_codigo_sri = '304' where 1 = 1;
	select unique p05_compania, p05_codprov, p05_tipo_ret, p05_porcentaje,
		p05_codigo_sri
		from t1
		into temp t2;
	drop table t1;
	insert into cxpt005 select * from t2;
	drop table t2;

	update cxpt005
		set p05_codigo_sri = '343'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'F'
		  and p05_porcentaje = 25.00
		  and p05_codigo_sri = '305';

	update cxpt005
		set p05_codigo_sri = '721'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'I'
		  and p05_porcentaje = 30.00
		  and p05_codigo_sri = '819';

	update cxpt005
		set p05_codigo_sri = '723'
		where p05_compania   = 1
		  and p05_tipo_ret   = 'I'
		  and p05_porcentaje = 70.00
		  and p05_codigo_sri = '813';

	select * from cxpt005
		where p05_compania   = 1
		  and p05_tipo_ret   = 'I'
		  and p05_porcentaje = 100.00
		  and p05_codigo_sri in ('801', '805')
		into temp t1;
	delete from cxpt005
		where p05_compania   = 1
		  and p05_tipo_ret   = 'I'
		  and p05_porcentaje = 100.00
		  and p05_codigo_sri in ('801', '805');
	update t1 set p05_codigo_sri = '725' where 1 = 1;
	select unique p05_compania, p05_codprov, p05_tipo_ret, p05_porcentaje,
		p05_codigo_sri
		from t1
		into temp t2;
	drop table t1;
	insert into cxpt005 select * from t2;
	drop table t2;

{------------------------------------------------------------------------------}
{------------------------------------------------------------------------------}

commit work;
--rollback work;
