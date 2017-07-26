select "gm" as base,
	z02_localidad as loc,
	z02_codcli as codcli,
	z01_nomcli as nomcli,
	z02_email as email
	from acero_gm@idsgye01:cxct002,
		acero_gm@idsgye01:cxct001
	where z02_compania = 1
	  and z02_email    is not null
	  and z01_codcli   = z02_codcli
union all
select "qm" as base,
	z02_localidad as loc,
	z02_codcli as codcli,
	z01_nomcli as nomcli,
	z02_email as email
	from acero_qm@idsuio01:cxct002,
		acero_qm@idsuio01:cxct001
	where z02_compania = 1
	  and z02_email    is not null
	  and z01_codcli   = z02_codcli
union all
select "qs" as base,
	z02_localidad as loc,
	z02_codcli as codcli,
	z01_nomcli as nomcli,
	z02_email as email
	from acero_qs@idsuio02:cxct002,
		acero_qs@idsuio02:cxct001
	where z02_compania = 1
	  and z02_email    is not null
	  and z01_codcli   = z02_codcli
	into temp t1;

unload to "sel_mail_cli.unl" select * from t1;

drop table t1;
