select n33_cod_trab cod, n33_valor valor
	from rolt033
	where n33_compania = 999
	into temp t1;
load from "empleados_ir_men.unl" insert into t1;
begin work;
update rolt033
	set n33_valor = (select valor from t1
				where cod   = n33_cod_trab
				  and valor > 0)
	where n33_compania   in (1, 2)
	  and n33_cod_liqrol = "Q2"
	  and n33_fecha_ini  = mdy(12, 16, 2012)
	  and n33_fecha_fin  = mdy(12, 31, 2012)
	  and n33_cod_trab   in (select cod from t1
				where cod   = n33_cod_trab
				  and valor > 0)
	  and n33_cod_rubro  = (select n06_cod_rubro
				from rolt006
				where n06_cod_rubro  = n33_cod_rubro
				  and n06_flag_ident = "IR")
	  and n33_valor      = 0;
update rolt033
	set n33_valor = (select valor * (-1) from t1
				where cod   = n33_cod_trab
				  and valor < 0)
	where n33_compania   in (1, 2)
	  and n33_cod_liqrol = "Q2"
	  and n33_fecha_ini  = mdy(12, 16, 2012)
	  and n33_fecha_fin  = mdy(12, 31, 2012)
	  and n33_cod_trab   in (select cod from t1
				where cod   = n33_cod_trab
				  and valor < 0)
	  and n33_cod_rubro  = (select n06_cod_rubro
				from rolt006
				where n06_cod_rubro  = n33_cod_rubro
				  and n06_flag_ident = "DI")
	  and n33_valor      = 0;
commit work;
drop table t1;
