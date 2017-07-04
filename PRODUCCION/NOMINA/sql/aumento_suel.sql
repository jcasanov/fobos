select n30_compania cia, n30_cod_trab cod, n30_nombres[1, 30] empleado,
	n30_sueldo_mes suel_nue
	from rolt030
	where n30_compania = 99
	into temp t1;
load from "sueldo_emp.txt" insert into t1;
select count(*) tot_emp from t1;
select cod, empleado, suel_nue, (suel_nue / (n00_dias_mes * n00_horas_dia))
	factor
	from t1, rolt000
	where n00_serial = cia
	into temp tmp_emp;
drop table t1;
select * from tmp_emp order by 2;
begin work;
	update rolt030
		set n30_sueldo_mes  = (select suel_nue from tmp_emp
					where cod = n30_cod_trab),
		    n30_factor_hora = (select suel_nue from tmp_emp
					where cod = n30_cod_trab)
	where n30_compania = 1
	  and n30_cod_trab = (select cod from tmp_emp where cod = n30_cod_trab);
commit work;
drop table tmp_emp;
select n30_cod_trab cod, n30_nombres[1, 30] empleado, n30_sueldo_mes suel_nue,
	n30_factor_hora factor
	from rolt030
	order by 2;
