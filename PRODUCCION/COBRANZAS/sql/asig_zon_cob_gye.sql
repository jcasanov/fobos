select z02_codcli codcli, z02_zona_cobro zon_c
	from cxct002
	where z02_compania = 999
	into temp t1;
load from "asig_zon_cob_gye.unl" insert into t1;
begin work;
	update cxct002
		set z02_zona_cobro = (select zon_c
					from t1
					where codcli = z02_codcli)
		where z02_compania = 1
		  and z02_codcli   in (select codcli from t1);
--rollback work;
commit work;
drop table t1;
