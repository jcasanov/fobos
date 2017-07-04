select count(*) cuantas, month(t23_fecing) mes, year(t23_fecing) anio,'TA' mod
 	from talt023
	where t23_compania  = 1
	  and t23_localidad = 1
	  and t23_estado    = 'F'
	  and extend(t23_fecing, year to month) <
		(select extend(mdy(r00_mespro, 1, r00_anopro), year to month)
			from rept000
			where r00_compania = t23_compania)
	group by 2, 3, 4
	into temp t1;
insert into t1
	select count(*) cuantas, month(r19_fecing) mes, year(r19_fecing) anio,
			'RE' mod
 		from rept019
			where r19_compania  = 1
			  and r19_localidad = 1
			  and r19_cod_tran  = 'FA'
			  and extend(r19_fecing, year to month) <
				(select extend(mdy(r00_mespro, 1, r00_anopro),
						year to month)
					from rept000
					where r00_compania = r19_compania)
			group by 2, 3, 4;
select nvl(sum(cuantas), 0) total_facturas from t1;
select anio, 0 t_mes, nvl(sum(cuantas), 0) tot_mes from t1 group by 1, 2
	into temp t2;
select anio, max(mes) t_m from t1 group by 1 into temp t3;
drop table t1;
update t2 set t_mes = (select t_m from t3 where t3.anio = t2.anio)
	where t2.anio in (select t3.anio from t3);
drop table t3;
select anio, t_mes, tot_mes from t2 order by 1;
select anio, round((tot_mes / t_mes), 2) prom_mes,
		round(round((tot_mes / t_mes), 2) / 20, 2) prom_dia
	from t2
	group by 1, 2, 3
	order by 1;
select anio, round((tot_mes / t_mes), 2) prom_mes from t2 group by 1, 2
	into temp t3;
update t3 set t3.anio = (select count(t2.anio) from t2) where 1 = 1;
drop table t2;
select unique anio, sum(prom_mes) tot_fact from t3 group by 1 into temp t2;
drop table t3;
select round(tot_fact / anio) prom_mes_anio,
		round(round(tot_fact / anio) / 20, 2) prom_dia_anio
	from t2;
drop table t2;
