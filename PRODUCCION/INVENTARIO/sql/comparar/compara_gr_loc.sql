select r71_linea, r71_sub_linea, r71_cod_grupo, r71_desc_grupo
	from rept071
	where r71_compania = 1
	into temp t1;
select r71_linea division, r71_sub_linea linea, r71_cod_grupo grupo,
		r71_desc_grupo descrip
	from rept071
	where r71_compania = 10
	into temp t2;
load from "grupos.txt" insert into t2;
select * from t1, outer t2
	where r71_linea     = division
	  and r71_sub_linea = linea
	  and r71_cod_grupo = grupo
	into temp t3;
drop table t1;
drop table t2;
{
delete from t3
	where linea is null
	  and grupo is null;
}
select count(*) totales from t3;
select count(*) cuantos_no_iguales from t3
	where linea is null
	  and grupo is null;
select * from t3
	where linea is null
	  and grupo is null;
{
select count(*) cuantos_iguales from t3
	where linea is not null
	  and grupo is not null;
select * from t3
	where linea is not null
	  and grupo is not null;
}
delete from t3 where descrip = r71_desc_grupo;
select count(*) cuantos_dif_desc from t3;
--unload to "grupos_dif.txt" select * from t3;
select * from t3;
drop table t3;
