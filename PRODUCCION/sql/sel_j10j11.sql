select j10_tipo_fuente, j10_num_fuente, j10_tipo_destino, j10_num_destino,
	j11_codigo_pago, j11_valor, date(j10_fecing) fecha
	from cajt010, cajt011
	where j10_compania     = 1
	  and j10_localidad    = 2
	  and j10_tipo_fuente  = 'PR'
	  and year(j10_fecing) = 2004
	  and j11_compania     = j10_compania
	  and j11_localidad    = j10_localidad
	  and j11_tipo_fuente  = j10_tipo_fuente
	  and j11_num_fuente   = j10_num_fuente
	  and j11_codigo_pago  = 'TJ'
	  and j11_cod_bco_tarj = 3
	into temp t1;
select count(*) hay from t1;
select * from t1 order by fecha desc;
drop table t1;
