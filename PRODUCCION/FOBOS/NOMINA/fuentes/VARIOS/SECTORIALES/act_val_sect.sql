select n17_sectorial as sectorial, n17_valor as valor
	from rolt017
	where n17_sectorial = 'caca'
	into temp t1;
load from "sectorial_2011.unl" insert into t1;
select count(*) tot_t1 from t1;
begin work;
	update rolt017
		set n17_valor = (select valor
					from t1
					where sectorial = n17_sectorial)
	where n17_sectorial in (select sectorial from t1);
commit work;
drop table t1;
