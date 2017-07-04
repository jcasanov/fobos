select z02_localidad loc, z02_codcli cli, z02_zona_cobro zon_cob
	from cxct002
	where z02_compania = 999
	into temp t1;

load from "cobradores_uio.unl" delimiter "," insert into t1;

select loc, cli, count(*) tot_reg
	from t1
	group by 1, 2
	having count(*) > 1;

--delete from t1 where cli = 49875;

begin work;

	update cxct002
		set z02_zona_cobro = (select zon_cob
					from t1
					where cli = z02_codcli
					  and loc = z02_localidad)
		where z02_compania  = 1
		  and z02_codcli   in (select cli from t1
					where loc = z02_localidad);

--rollback work;
commit work;

drop table t1;
