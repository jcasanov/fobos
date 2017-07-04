set isolation to dirty read;
select z02_codcli codcli, z02_referencia referencia, z02_credit_dias credito
	from cxct002
	where z02_compania = 99
	into temp t1;
load from "clientes_uio.unl" insert into t1;
set explain on;
select count(*) tot_cli from t1;
--begin work;
update cxct002
	set z02_credit_dias = (select credito from t1
				where codcli = z02_codcli)
	where z02_compania  = 1
	  and z02_localidad = 3
	  and z02_codcli    in (select unique codcli from t1);
update cxct002
	set z02_referencia  = (select referencia from t1
				where codcli = z02_codcli)
	where z02_compania  = 1
	  and z02_localidad = 3
	  and z02_codcli    in (select unique codcli from t1);
set explain off;
--commit work;
--drop table t1;
