select r72_linea, r72_sub_linea, r72_cod_grupo, r72_cod_clase, r72_desc_clase
	from rept072
	where r72_compania = 1
	into temp t1;
select r72_linea division, r72_sub_linea linea, r72_cod_grupo grupo,
		r72_cod_clase clase, r72_desc_clase descrip
	from rept072
	where r72_compania = 10
	into temp t2;
load from "clases.txt" insert into t2;
select * from t1, outer t2
	where r72_linea     = division
	  and r72_sub_linea = linea
	  and r72_cod_grupo = grupo
	  and r72_cod_clase = clase
	into temp t3;
drop table t1;
drop table t2;
{
delete from t3
	where linea is null
	  and grupo is null
	  and clase is null;
}
select count(*) totales from t3;
select count(*) cuantos_no_iguales from t3
	where linea is null
	  and grupo is null
	  and clase is null;
select * from t3
	where linea is null
	  and grupo is null
	  and clase is null;
{
select count(*) cuantos_iguales from t3
	where linea is not null
	  and grupo is not null
	  and clase is not null;
select * from t3
	where linea is not null
	  and grupo is not null
	  and clase is not null;
}
delete from t3 where descrip = r72_desc_clase;
select count(*) cuantos_dif_desc from t3;
--unload to "clases_dif.txt" select * from t3;
select * from t3;
drop table t3;
