select z01_codcli cli, z02_localidad loc
	from cxct001, cxct002
	where z01_codcli   = -99
	  and z02_compania = 99
	  and z02_codcli   = z01_codcli
	into temp t1;

load from "blo_cli_uio.unl" insert into t1;

select count(*), loc from t1 group by 2;

select unique cli
	from t1
	into temp tmp_cli_3;

select unique cli
	from t1
	where loc = 4
	into temp tmp_cli_4;

select cli from tmp_cli_4
	where not exists
		(select z01_codcli
			from acero_qs:cxct001
			where z01_codcli = cli);

begin work;

	update cxct001
		set z01_estado = 'B'
		where z01_codcli in (select cli from tmp_cli_3);

	update acero_qs@idsuio01:cxct001
	--update acero_qs:cxct001
		set z01_estado = 'B'
		where z01_codcli in (select cli from tmp_cli_4);

--rollback work;
commit work;

drop table tmp_cli_3;
drop table tmp_cli_4;
drop table t1;
