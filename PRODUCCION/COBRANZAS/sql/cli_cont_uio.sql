select z02_codcli cod
	from cxct002
	where z02_compania = 999
	into temp t1;

load from "cli_cont_uio.unl" insert into t1;

begin work;

	update cxct002
		set z02_credit_dias = 0
		where z02_compania  = 1
		  and z02_codcli   in (select cod from t1);

commit work;

drop table t1;
