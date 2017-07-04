select j10_tipo_fuente tf, j10_codigo_caja caja, j11_codigo_pago cp,
	extend(j10_fecha_pro, year to month) fecha,
	nvl(sum(j11_valor), 0) saldo_caja
	from cajt010, cajt011
	where j10_compania        = 2
	  and j10_valor           > 0
	  and year(j10_fecha_pro) = 2006
	  and j11_compania        = j10_compania
	  and j11_localidad       = j10_localidad
	  and j11_tipo_fuente     = j10_tipo_fuente
	  and j11_num_fuente      = j10_num_fuente
	  and j11_codigo_pago     not in ('RT', 'TJ')
	group by 1, 2, 3, 4
union
	select j10_tipo_fuente tf, j10_codigo_caja caja, j11_codigo_pago cp,
		extend(j10_fecha_pro, year to month) fecha,
		nvl(case when j11_codigo_pago = 'CH'
			then sum(j11_valor) * (-1)
			else sum(j10_valor) * (-1)
		end, 0) saldo_caja
	from cajt010, outer cajt011
	where j10_compania        = 2
	  and j10_tipo_fuente     = 'EC'
	  and year(j10_fecha_pro) = 2006
	  and j11_compania        = j10_compania
	  and j11_localidad       = j10_localidad
	  and j11_num_egreso      = j10_num_fuente
	group by 1, 2, 3, 4
	into temp t1;
select fecha, tf, caja, nvl(cp, 'EF') cp, round(saldo_caja, 2) saldo_caja
	from t1
	into temp t2;
drop table t1;
select fecha, tf, caja, cp, round(saldo_caja, 2) saldo_caja
	from t2
	order by 1, 3, 4;
select fecha, caja, cp, round(sum(saldo_caja), 2) saldo_caja
	from t2
	group by 1, 2, 3
	order by 1, 2, 3;
select extend(b12_fec_proceso, year to month) fecha_con,
	nvl(round(sum(b13_valor_base), 2), 0) saldo_cont
	from ctbt012, ctbt013
	where b12_compania           = 2
	  and b12_estado            <> 'E'
	  and year(b12_fec_proceso)  = 2006
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta            like ('11010101%')
	group by 1
	into temp tmp_cont;
select fecha, round(nvl(sum(saldo_caja), 0), 2) saldo_caja, saldo_cont
	from t2, tmp_cont
	where fecha = fecha_con
	group by 1, 3
	into temp t3;
drop table tmp_cont;
select fecha, saldo_caja, saldo_cont,
	round(abs(saldo_caja) - abs(saldo_cont), 2) diferencia
	from t3
	order by 1;
select year(fecha) anio, nvl(round(sum(saldo_caja), 2), 0) saldo_caja,
	nvl(round(sum(saldo_cont), 2), 0) saldo_cont,
	nvl(round(abs(sum(saldo_caja)) - abs(sum(saldo_cont)), 2),0) diferencia
	from t3
	group by 1
	order by 1;
drop table t3;
select year(fecha) anio, tf, caja, cp, round(sum(saldo_caja), 2) saldo_caja
	from t2
	group by 1, 2, 3, 4
	order by 3, 4;
select caja, cp, round(sum(saldo_caja), 2) saldo_caja
	from t2
	group by 1, 2
	order by 1, 2;
select round(nvl(sum(saldo_caja), 0), 2) saldo_caja from t2;
drop table t2;
