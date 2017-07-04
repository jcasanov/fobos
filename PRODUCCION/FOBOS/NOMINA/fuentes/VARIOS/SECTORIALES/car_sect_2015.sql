select n17_compania cia, n17_ano_sect anio, n17_sectorial sect,
	n17_descripcion descrip, n17_valor valor, n17_usuario usua
	from rolt017
	where n17_compania = 999
	into temp t1;

load from "sectorial_2015.unl" insert into t1;

select cia, anio, sect, replace(descrip, ";", ",") descrip, valor, usua
	from t1
	into temp t2;

drop table t1;

select * from t2 into temp t1;

drop table t2;

begin work;

	insert into rolt017
		(n17_compania, n17_ano_sect, n17_sectorial, n17_descripcion,
		 n17_valor, n17_usuario, n17_fecing)
		select cia, anio, sect, descrip, valor, usua, current
			from t1;

--rollback work;
commit work;

drop table t1;
