--select n33_compania cia, 'Q2' lq, n32_fecha_ini fec_ini, n32_fecha_fin fec_fin,
select n32_cod_trab cod_t, n33_cod_rubro rubro, n33_valor valor
	from rolt032, rolt033
	where n32_compania   = 1
	  and n32_cod_liqrol = 'Q2'
	  and extend(n32_fecha_fin, year to month) = '2014-10'
	  and n33_compania   = n32_compania
	  and n33_cod_liqrol = n32_cod_liqrol
	  and n33_fecha_ini  = n32_fecha_ini
	  and n33_fecha_fin  = n32_fecha_fin
	  and n33_cod_trab   = n32_cod_trab
	  and n33_cod_rubro in (7, 9, 76, 13, 23, 32, 51)
	  and n33_valor      > 0
	into temp t1;
begin work;
	update rolt033
		set n33_valor = n33_valor +
				nvl((select valor
					from t1
					where cod_t = n33_cod_trab
					  and rubro = n33_cod_rubro), 0)
		where n33_compania   = 1
		  and n33_cod_liqrol = 'Q2'
		  and extend(n33_fecha_fin, year to month) = '2014-11'
		  and n33_cod_trab  in (select unique cod_t from t1)
		  and n33_cod_rubro in (select unique rubro from t1);
commit work;
drop table t1;
