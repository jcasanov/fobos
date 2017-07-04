select r73_marca, r73_desc_marca
	from rept073
	where r73_compania = 1
	into temp t1;
select r73_marca marca, r73_desc_marca descrip
	from rept073
	where r73_compania = 10
	into temp t2;
load from "marcas.txt" insert into t2;
select * from t1, outer t2 where r73_marca = marca into temp t3;
drop table t1;
drop table t2;
delete from t3 where marca is not null;
select count(*) cuantos_no_iguales from t3;
select * from t3;
delete from t3 where descrip = r73_desc_marca;
select count(*) cuantos_dif_desc from t3;
select * from t3;
drop table t3;
