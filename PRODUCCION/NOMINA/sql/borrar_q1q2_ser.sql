begin work;

delete from rolt033
	where n33_compania   = 2
	  and n33_cod_liqrol in ('Q1', 'Q2')
	  and n33_fecha_ini  >= mdy(01, 01, 2007)
	  and n33_fecha_fin  <= mdy(01, 31, 2007)
	  and n33_cod_trab   in (3, 11);

delete from rolt032
	where n32_compania   = 2
	  and n32_cod_liqrol in ('Q1', 'Q2')
	  and n32_fecha_ini  >= mdy(01, 01, 2007)
	  and n32_fecha_fin  <= mdy(01, 31, 2007)
	  and n32_cod_trab   in (3, 11);

commit work;
