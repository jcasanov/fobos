select z02_codcli as codcli, z02_localidad as loc, z02_email as email
	from cxct002
	where z02_compania = 999
	into temp tmp_z02;

load from "MAIL_CLI_GYE.csv" delimiter "," insert into tmp_z02;

begin work;

	update cxct002
		set z02_email = (select email
					from tmp_z02
					where loc    = z02_localidad
					  and codcli = z02_codcli)
		where z02_compania  = 1
		  and z02_codcli   in
			(select codcli
				from tmp_z02
				where loc = z02_localidad);

commit work;
--rollback work;

drop table tmp_z02;
