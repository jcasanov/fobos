select z02_codcli cli, z02_zona_cobro zon_cob
	from cxct002
	where z02_compania = 999
	into temp t1;

load from "asg_cobuio130913.unl" insert into t1;

select cli, count(*) tot_reg
	from t1
	group by 1
	having count(*) > 1;

delete from t1 where cli = 39952;

begin work;

	update cxct002
		set z02_zona_cobro = (select zon_cob
					from t1
					where cli = z02_codcli)
		where z02_compania  = 1
		  and z02_codcli   in (select cli from t1);

commit work;

drop table t1;
