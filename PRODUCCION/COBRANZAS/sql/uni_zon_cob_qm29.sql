set isolation to dirty read;

select z02_compania cia, z02_localidad loc, z02_codcli cli, z02_zona_cobro zon_c
	from cxct002, cxct001
	where z02_compania   = 1
	  and z02_localidad  = 3
	  and z02_zona_cobro = 29
	  and z01_codcli     = z02_codcli
	  and z01_estado     = "A"
	into temp t1;

unload to "cli_qm_antes_unif29.unl" select * from t1;

begin work;

	update cxct002
		set z02_zona_cobro = (select zon_c
					from t1
					where cia = z02_compania
					  and cli = z02_codcli)
		where z02_compania = 1
		  and z02_codcli   in (select cli
					from t1
					where cia = z02_compania);

	update cxct022
		set z22_zona_cobro = (select zon_c
					from t1
					where cia = z22_compania
					  and cli = z22_codcli)
		where z22_compania      = 1
		  and z22_codcli       in (select cli
						from t1
						where cia = z22_compania)
		  and date(z22_fecing) >= mdy(04,16,2014);

	update cxct024
		set z24_zona_cobro = (select zon_c
					from t1
					where cia = z24_compania
					  and cli = z24_codcli)
		where z24_compania      = 1
		  and z24_codcli       in (select cli
						from t1
						where cia = z24_compania)
		  and date(z24_fecing) >= mdy(04,16,2014);

--rollback work;
commit work;

drop table t1;
