select z01_codcli cli, z02_localidad loc, z02_cupocred_mb cupo
	from cxct001, cxct002
	where z01_codcli   = -99
	  and z02_compania = 99
	  and z02_codcli   = z01_codcli
	into temp t1;

load from "cupo_cli.unl" insert into t1;

begin work;

	update cxct002
		set z02_cupocred_mb = (select cupo
					from t1
					where loc = z02_localidad
					  and cli = z02_codcli)
		where z02_compania  = 1
		  and z02_localidad = 3
		  and z02_codcli    in (select unique cli
					from t1
					where loc = z02_localidad);

	update cxct002
		set z02_cupocred_mb = (select cupo
					from t1
					where loc = z02_localidad
					  and cli = z02_codcli)
		where z02_compania  = 1
		  and z02_localidad = 4
		  and z02_codcli    in (select unique cli
					from t1
					where loc = z02_localidad);

	update cxct002
		set z02_cupocred_mb = (select cupo
					from t1
					where loc = z02_localidad
					  and cli = z02_codcli)
		where z02_compania  = 1
		  and z02_localidad = 5
		  and z02_codcli    in (select unique cli
					from t1
					where loc = z02_localidad);

	update acero_qs@idsuio01:cxct002
		set z02_cupocred_mb = (select cupo
					from t1
					where loc = z02_localidad
					  and cli = z02_codcli)
		where z02_compania  = 1
		  and z02_localidad = 3
		  and z02_codcli    in (select unique cli
					from t1
					where loc = z02_localidad);

	update acero_qs@idsuio01:cxct002
		set z02_cupocred_mb = (select cupo
					from t1
					where loc = z02_localidad
					  and cli = z02_codcli)
		where z02_compania  = 1
		  and z02_localidad = 4
		  and z02_codcli    in (select unique cli
					from t1
					where loc = z02_localidad);

--rollback work;
commit work;

drop table t1;
