select z02_codcli cli, z02_credit_dias plazo, z02_cupocred_mb cupo
	from cxct002
	where z02_compania = 99
	into temp t1;

load from "cupo_cli.unl" insert into t1;

begin work;

	update cxct002
		set z02_credit_dias = 0,
		    z02_cupocred_mb = 0.00
		where 1 = 1;

	update cxct002
		set z02_credit_dias = (select plazo
					from t1
					where cli = z02_codcli),
		    z02_cupocred_mb = (select cupo
					from t1
					where cli = z02_codcli)
		where z02_compania  = 1
		  and z02_localidad = 1
		  and z02_codcli    in (select unique cli from t1);

--rollback work;
commit work;

drop table t1;
