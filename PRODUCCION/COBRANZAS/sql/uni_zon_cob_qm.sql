set isolation to dirty read;

select z02_compania cia, z02_localidad loc, z02_codcli cli, z02_zona_cobro zon_c
	from cxct002, cxct001
	where z02_compania   = 1
	  and z02_zona_cobro is not null
	  and z01_codcli     = z02_codcli
	  and z01_estado     = "A"
	into temp t1;

unload to "cli_qm_antes_unif.unl" select * from t1;

select cia, cli, zon_c, count(*) ctos
	from t1
	group by 1, 2, 3
	having count(*) > 1
	into temp t2;

drop table t1;

select count(*) tot_cli from t2;

begin work;

	update cxct002
		set z02_zona_cobro = (select zon_c
					from t2
					where cia = z02_compania
					  and cli = z02_codcli)
		where z02_compania = 1
		  and z02_codcli   in (select cli
					from t2
					where cia = z02_compania);

commit work;

drop table t2;
