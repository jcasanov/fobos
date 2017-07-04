select n30_num_doc_id as cedula, n30_sueldo_mes as diferencia
	from rolt030
	where n30_compania = 999
	into temp t1;
load from "aj_suel_12.unl" insert into t1;
select n30_cod_trab as codigo, diferencia
	from rolt030, t1
	where n30_num_doc_id = cedula
	into temp t2;
drop table t1;
begin work;
{--
update rolt032
	set n32_sueldo = (select n30_sueldo_mes
				from rolt030
				where n30_compania = n32_compania
				  and n30_cod_trab = n32_cod_trab)
	where n32_compania   = 1
	  and n32_cod_liqrol = 'Q2'
	  and n32_fecha_fin  = mdy(01, 31, 2012)
	  and n32_estado     = 'A';
--}
	update rolt033
		set n33_valor = n33_valor +
				(select diferencia
					from t2
					where codigo = n33_cod_trab)
		where n33_compania    = 1
		  and n33_cod_liqrol  = 'Q2'
		  and n33_fecha_fin   = mdy(01, 31, 2012)
		  and n33_cod_trab   in (select codigo from t2)
		  and n33_cod_rubro   = 2;
	update rolt033
		set n33_valor = n33_valor +
				(select (diferencia * 9.35 / 100)
					from t2
					where codigo = n33_cod_trab)
		where n33_compania    = 1
		  and n33_cod_liqrol  = 'Q2'
		  and n33_fecha_fin   = mdy(01, 31, 2012)
		  and n33_cod_trab   in (select codigo from t2)
		  and n33_cod_rubro   = 55;
	update rolt032
		set n32_tot_gan = n32_tot_gan +
				(select diferencia
					from t2
					where codigo = n32_cod_trab),
		    n32_tot_ing = n32_tot_ing +
				(select diferencia
					from t2
					where codigo = n32_cod_trab),
		    n32_tot_egr = n32_tot_egr +
				(select (diferencia * 9.35 / 100)
					from t2
					where codigo = n32_cod_trab),
		    n32_tot_neto = n32_tot_neto +
				(select diferencia
					from t2
					where codigo = n32_cod_trab) -
				(select (diferencia * 9.35 / 100)
					from t2
					where codigo = n32_cod_trab)
		where n32_compania    = 1
		  and n32_cod_liqrol  = 'Q2'
		  and n32_fecha_fin   = mdy(01, 31, 2012)
		  and n32_cod_trab   in (select codigo from t2);
commit work;
drop table t2;
