select n30_cod_trab cod, n30_ano_sect anio, n30_sectorial sect
	from rolt030
	where n30_compania = 999
	into temp t1;

load from "sect_uio_ina.unl" insert into t1;

select cod, (select max(n17_ano_sect)
		from rolt017
		where n17_compania = 1
		  and n17_sectorial = sect) anio,
	sect
	from t1
	into temp t2;

select * from t2 where anio is null;

drop table t1;

begin work;

update rolt030
	set n30_ano_sect = (select anio
				from t2
				where cod = n30_cod_trab),
	    n30_sectorial = (select sect
				from t2
				where cod = n30_cod_trab)
	where n30_compania = 1
	  and n30_cod_trab in (select cod from t2);

commit work;

drop table t2;
