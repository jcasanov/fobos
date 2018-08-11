select z02_localidad loc, z02_codcli cli, z02_zona_cobro zon_cob
	from cxct002
	where z02_compania = 999
	into temp t1;

load from "cobradores_loc.unl" delimiter "," insert into t1;

select loc, cli, count(*) tot_reg
	from t1
	group by 1, 2
	having count(*) > 1;

--delete from t1 where cli = 49875;

begin work;

{--
	update acero_gm@idsgye01:cxct002
		set z02_zona_cobro = (select zon_cob
					from t1
					where cli = z02_codcli
					  and loc = 1)
		where z02_compania  = 1
		  and z02_codcli   in (select cli
					from t1
					where loc = 1);
--}

	update acero_qm@idsuio01:cxct002
		set z02_zona_cobro = (select zon_cob
					from t1
					where cli = z02_codcli
					  and loc = 3)
		where z02_compania  = 1
		  and z02_codcli   in (select cli
					from t1
					where loc = 3);

{--
	update acero_qs@idsuio02:cxct002
		set z02_zona_cobro = (select zon_cob
					from t1
					where cli = z02_codcli
					  and loc = 4)
		where z02_compania  = 1
		  and z02_codcli   in (select cli
					from t1
					where loc = 4);
--}

--rollback work;
commit work;

drop table t1;
