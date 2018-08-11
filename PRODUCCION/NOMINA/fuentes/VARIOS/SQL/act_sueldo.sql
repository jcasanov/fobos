select n30_cod_trab as cod_trab, n30_sueldo_mes as sueldo,
	n30_factor_hora as factor
	from rolt030
	where n30_compania = 999
	into temp t1;
load from "sueldos_2011.unl" insert into t1;
select count(*) tot_t1 from t1;
begin work;
	update rolt030
		set n30_sueldo_mes  = (select sueldo
					from t1
					where cod_trab = n30_cod_trab),
		    n30_factor_hora = (select factor
					from t1
					where cod_trab = n30_cod_trab)
	where n30_compania = 1
	  and n30_cod_trab in (select cod_trab from t1);
commit work;
drop table t1;
