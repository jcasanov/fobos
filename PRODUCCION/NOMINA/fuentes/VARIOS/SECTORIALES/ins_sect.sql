select n17_sectorial as sectorial, n17_descripcion as nombre
	from rolt017
	where n17_sectorial = 'caca'
	into temp t1;
load from "sectoriales.unl" insert into t1;
select t1.*, n17_sectorial as sect
	from t1, outer rolt017
	where sectorial = n17_sectorial
	into temp t2;
delete from t2 where sect is not null;
begin work;
	update rolt017
		set n17_descripcion = (select nombre
					from t1
					where sectorial = n17_sectorial)
	where n17_sectorial in (select sectorial from t1);
	insert into rolt017
		(n17_sectorial, n17_descripcion, n17_valor)
		select sectorial, nombre, 0.00
			from t2;
commit work;
drop table t1;
drop table t2;
