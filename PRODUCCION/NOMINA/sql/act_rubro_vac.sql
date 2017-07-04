begin work;

select n33_compania cia, n33_cod_liqrol c_rol, n33_fecha_ini fec_ini,
	n33_fecha_fin fec_fin, n33_cod_trab cod_trab, n33_valor valor
	from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_cod_rubro  = 11
	  and n33_valor      > 0
	into temp t1;

update rolt033
	set n33_horas_porc = (select valor from t1
				where cia      = n33_compania
				  and c_rol    = n33_cod_liqrol
				  and fec_ini  = n33_fecha_ini
				  and fec_fin  = n33_fecha_fin
				  and cod_trab = n33_cod_trab)
	where exists (select cia, c_rol, fec_ini, fec_fin, cod_trab from t1)
	  and n33_cod_rubro = 12
	  and n33_valor     > 0;

drop table t1;

commit work;
