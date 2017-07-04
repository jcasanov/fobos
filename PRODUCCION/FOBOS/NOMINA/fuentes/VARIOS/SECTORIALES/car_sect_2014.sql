select n17_compania cia, n17_ano_sect anio, n17_sectorial sect,
	n17_descripcion descrip, n17_valor valor, n17_usuario usua
	from rolt017
	where n17_compania = 999
	into temp t1;

load from "sectorial_2014.unl" insert into t1;

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

	update rolt030
		set n30_ano_sect  = (select anio
					from t1
					where sect = n30_sectorial),
		    n30_sectorial = (select sect
					from t1
					where sect = n30_sectorial)
		where n30_compania   = 1
		  and n30_sectorial in (select sect from t1)
		  and n30_estado    <> "I";

	update rolt030
		set n30_sueldo_mes  = (select valor
					from t1
					where sect = n30_sectorial),
		    n30_factor_hora = (select valor / 240
					from t1
					where sect = n30_sectorial)
		where n30_compania   = 1
		  and exists
			(select 1 from t1
				where sect  = n30_sectorial
				  and valor > n30_sueldo_mes)
		  and n30_estado     = "A";

--rollback work;
commit work;

drop table t1;
