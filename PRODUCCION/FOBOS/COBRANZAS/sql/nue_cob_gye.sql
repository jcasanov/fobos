select z02_compania cia, z02_localidad loc, z02_codcli cod, z02_zona_venta zvta,
	z02_zona_cobro zcob
	from cxct002
	where z02_compania   = 1
	  and z02_zona_cobro is not null
union
select z02_compania cia, z02_localidad loc, z02_codcli cod, z02_zona_venta zvta,
	z02_zona_cobro zcob
	from cxct002
	where z02_compania   = 1
	  and z02_zona_venta is not null
	  and z02_zona_cobro is null
	into temp t1;

select count(*) tot_reg from t1;

update t1
	set zcob = 5
	where zvta in (17, 18, 10);

select * from t1
	where zvta in (17, 18, 10)
	  and zcob = 5
	into temp t2;

update t1
	set zcob = 3
	where zvta in (3, 9, 16, 19);

insert into t2
	select * from t1
		where zvta in (3, 9, 16, 19)
		  and zcob = 3;

update t1
	set zcob = 2
	where zvta in (12, 14, 4, 6);

insert into t2
	select * from t1
		where zvta in (12, 14, 4, 6)
		  and zcob = 2;

drop table t1;

select count(*) tot_t2 from t2;

begin work;

	update cxct002
		set z02_zona_cobro = (select zcob
					from t2
					where cia = z02_compania
					  and loc = z02_localidad
					  and cod = z02_codcli)
		where z02_compania  = 1
		  and z02_codcli   in (select cod
					from t2
					where cia = z02_compania
					  and loc = z02_localidad);

--rollback work;
commit work;

drop table t2;
