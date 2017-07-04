select z01_codcli codcli
	from cxct001
	where z01_codcli = -1
	into temp t1;

load from "cli_rita_zon.unl" insert into t1;

begin work;

	update cxct002
		set z02_zona_cobro = 1
		where z02_compania = 1
		  and z02_codcli in (select codcli from t1);

commit work;

drop table t1;
