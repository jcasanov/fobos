select 1 loc, lpad(n30_cod_trab, 3, 0) as cod,
	trim(n30_nombres[1, 35]) as empleados,
	to_char(nvl(n30_fecha_reing, n30_fecha_ing), "%d-%m-%Y") as fec_ing
	from rolt030
	where n30_compania  = 1
	  and n30_estado    = "A"
	  and nvl(n30_fecha_reing, n30_fecha_ing) < mdy(12, 16, 2003)
union
select 3 loc, lpad(n30_cod_trab, 3, 0) as cod,
	trim(n30_nombres[1, 35]) as empleados,
	to_char(nvl(n30_fecha_reing, n30_fecha_ing), "%d-%m-%Y") as fec_ing
	from acero_qm:rolt030
	where n30_compania  = 1
	  and n30_estado    = "A"
	  and nvl(n30_fecha_reing, n30_fecha_ing) < mdy(12, 16, 2003)
	order by 1, 3;

select count(*) tot_emp_antes
	from rolt030
	where   n30_compania  = 1
	  and ((n30_estado    = "A"
	  and   nvl(n30_fecha_reing, n30_fecha_ing) < mdy(12, 16, 2003))
	   or  (n30_estado    = "I"
	  and   nvl(n30_fecha_reing, n30_fecha_ing) < mdy(12, 16, 2003)
	  and   n30_fecha_sal > mdy(12, 16, 2003)))
	into temp t1;

select * from t1;

select round(tot_emp_antes / (YEAR(TODAY) - 2003), 2) sal_emp_anio
	from t1;

drop table t1;
