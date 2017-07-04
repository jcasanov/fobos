select n10_compania cia, n10_cod_trab cod, n10_valor movil
	from rolt010
	where n10_compania   = 1
	  and n10_cod_liqrol = 'Q2'
	  and n10_cod_rubro  = 15
	  and n10_valor      < 50
	into temp t1;
select cia, cod, n30_nombres empleado, n30_sueldo_mes suel_ant,
	(n30_sueldo_mes + movil) suel_nue,
	((n30_sueldo_mes + movil) / (n00_dias_mes * n00_horas_dia)) factor
	from t1, rolt030, rolt000
	where n30_compania = cia
	  and n30_cod_trab = cod
	  and n00_serial   = n30_compania
	into temp t2;
drop table t1;
select * from t2 order by empleado;
begin work;
	update rolt030
		set n30_sueldo_mes  = (select suel_nue from t2
					where cia = n30_compania
					  and cod = n30_cod_trab),
		    n30_factor_hora = (select factor from t2
					where cia = n30_compania
					  and cod = n30_cod_trab)
	where n30_compania = 1
	  and n30_cod_trab = (select cod from t2 where cod = n30_cod_trab);
	delete from rolt010
		where n10_compania   = 1
		  and n10_cod_liqrol = 'Q2'
		  and n10_cod_rubro  = 15
		  and n10_cod_trab   = (select cod from t2
					where cod = n10_cod_trab);
commit work;
drop table t2;
