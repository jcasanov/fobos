set isolation to dirty read;

select z02_codcli codcli, z02_zona_venta zonven
	from cxct002
	where z02_compania = 999
	into temp t1;

load from "cli_zon.unl"
	insert into t1;

select codcli cli, count(*) cuantos
	from t1
	group by 1
	having count(*) > 1
	into temp t2;

select * from t1
	where codcli not in (select cli from t2)
	into temp t3;

drop table t1;
drop table t2;

begin work;

	update cxct002
		set z02_zona_venta = (select zonven
					from t3
					where codcli = z02_codcli)
		where z02_compania  = 1
		  and z02_codcli   in (select codcli from t3);

	update cxct002
		set z02_zona_venta = 1
		where z02_compania   = 1
		  and z02_zona_venta is null
		  and z02_codcli     in
			(select z01_codcli
				from cxct001
				where z01_codcli = z02_codcli
				  and z01_estado = "A");

commit work;

drop table t3;
