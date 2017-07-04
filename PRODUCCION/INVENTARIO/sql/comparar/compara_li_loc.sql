select r70_linea, r70_sub_linea, r70_desc_sub
	from rept070
	where r70_compania = 1
	into temp t1;
select r70_linea division, r70_sub_linea linea, r70_desc_sub descrip
	from rept070
	where r70_compania = 10
	into temp t2;
load from "lineas.txt" insert into t2;
select * from t1, outer t2
	where r70_linea     = division
	  and r70_sub_linea = linea
	into temp t3;
drop table t1;
drop table t2;
--delete from t3 where linea is not null;
select count(*) totales from t3;
select count(*) cuantos_no_iguales from t3 where linea is null;
select * from t3 where linea is null;
select count(*) cuantos_iguales from t3 where linea is not null;
select * from t3 where linea is not null;
delete from t3 where descrip = r70_desc_sub;
select count(*) cuantos_dif_desc from t3;
--unload to "lineas_dif.txt" select * from t3;
select * from t3;
drop table t3;
