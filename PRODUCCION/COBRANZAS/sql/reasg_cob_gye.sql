select z02_codcli cli, z02_zona_cobro zon_cob
	from cxct002
	where z02_compania = 999
	into temp t1;

load from "cobradores_gye.unl" delimiter "," insert into t1;

select cli, count(*) tot_reg
	from t1
	group by 1
	having count(*) > 1;

--delete from t1 where cli in (14209, 12437, 3096, 3031);

begin work;

	update cxct002
		set z02_zona_cobro = (select zon_cob
					from t1
					where cli = z02_codcli)
		where z02_compania  = 1
		  and z02_codcli   in (select cli from t1);

--rollback work;
commit work;

drop table t1;
