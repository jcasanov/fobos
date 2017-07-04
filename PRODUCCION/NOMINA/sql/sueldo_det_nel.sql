select lpad(year(n33_fecha_fin),4,0) || "-" || lpad(month(n33_fecha_fin),2,0)
	|| "-" || lpad(day(n33_fecha_fin),2,0) fecha, n32_sueldo sueldo,
	n33_cod_rubro rubro, n06_nombre_abr nombre, n33_orden orden,
	n33_det_tot tipo, n33_valor valor
	from rolt033, rolt032, rolt006
	where n33_compania   = 1
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_cod_trab   = 117
	  and (n33_valor      > 0 or n33_cod_rubro in (9, 10, 11, 12, 61))
	  and n32_compania   = n33_compania
	  and n32_cod_liqrol = n33_cod_liqrol
	  and n32_fecha_ini  = n33_fecha_ini
	  and n32_fecha_fin  = n33_fecha_fin
	  and n32_cod_trab   = n33_cod_trab
	  and n33_cod_rubro  = n06_cod_rubro
	into temp t1;
select count(*) tot_reg from t1;
{--
select fecha, sueldo, count(*) max_reg from t1 group by 1, 2 into temp t2;
select fecha, sueldo, max_reg
	from t2
	where max_reg in (select max(max_reg) from t2)
	order by fecha;
drop table t2;
--}
unload to "sueldo_det_nel.txt" select * from t1 order by fecha, orden, tipo;
select * from t1 order by fecha, orden, tipo;
drop table t1;
