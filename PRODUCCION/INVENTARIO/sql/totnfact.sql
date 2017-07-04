select t23_orden num, z01_num_doc_id cedruc, t23_fecing fecha, 'TA' mod
 	from talt023, cxct001
	where t23_compania  = 1
	  and t23_estado    = 'F'
	  and extend(t23_fecing, year to month) <
		(select extend(mdy(r00_mespro, 1, r00_anopro), year to month)
			from rept000
			where r00_compania = t23_compania)
	  and z01_codcli    = t23_cod_cliente
	into temp tmp_fac;
insert into tmp_fac
	select r19_num_tran num, r19_cedruc cedruc, r19_fecing fecha, 'RE' mod
 		from rept019
		where r19_compania  = 1
		  and r19_cod_tran  = 'FA'
		  and extend(r19_fecing, year to month) <
			(select extend(mdy(r00_mespro, 1, r00_anopro),
					year to month)
				from rept000
				where r00_compania = r19_compania);
select count(*) cuantas, month(fecha) mes, year(fecha) anio, mod, 'F' tipo
 	from tmp_fac
	where mod            = 'TA'
	  and length(cedruc) = 13
	group by 2, 3, 4, 5
	into temp t1;
insert into t1
	select count(*) cuantas, month(fecha) mes, year(fecha) anio, mod,
		'N' tipo
	 	from tmp_fac
		where mod            = 'TA'
		  and length(cedruc) = 10
		group by 2, 3, 4, 5;
insert into t1
	select count(*) cuantas, month(fecha) mes, year(fecha) anio, mod,
		'F' tipo
 		from tmp_fac
		where mod            = 'RE'
		  and length(cedruc) = 13
		group by 2, 3, 4, 5;
insert into t1
	select count(*) cuantas, month(fecha) mes, year(fecha) anio, mod,
		'N' tipo
 		from tmp_fac
		where mod            = 'RE'
		  and length(cedruc) = 10
		group by 2, 3, 4, 5;
drop table tmp_fac;

----------------------- PROMEDIO FACTURAS --------------------------
select nvl(sum(cuantas), 0) total_facturas
	from t1
	where tipo = 'F';
select anio, 0 t_mes, nvl(sum(cuantas), 0) tot_mes
	from t1
	where tipo = 'F'
	group by 1, 2
	into temp t2;
select anio, max(mes) t_m
	from t1
	where tipo = 'F'
	group by 1
	into temp t3;
--drop table t1;
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
----------------------------------------------------------------------

--------------------- PROMEDIO NOTA DE VENTA -------------------------
select nvl(sum(cuantas), 0) total_nota_venta
	from t1
	where tipo = 'N';
select anio, 0 t_mes, nvl(sum(cuantas), 0) tot_mes
	from t1
	where tipo = 'N'
	group by 1, 2
	into temp t2;
select anio, max(mes) t_m
	from t1
	where tipo = 'N'
	group by 1
	into temp t3;
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
----------------------------------------------------------------------
