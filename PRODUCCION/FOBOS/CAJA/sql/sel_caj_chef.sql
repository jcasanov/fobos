select j10_tipo_destino tp, j10_num_destino num, j10_usuario usua,
	j11_valor, j02_usua_caja usucaj, j10_codigo_caja codcaj,
	j11_codigo_pago cp, date(j10_fecing) fecha
	from cajt010, cajt011, cajt002
	where date(j10_fecing) >= today - 2
	  and j10_estado       = 'P'
	  and j10_codigo_caja  = 2
	  and j02_compania     = j10_compania
	  and j02_localidad    = j10_localidad
	  and j02_codigo_caja  = j10_codigo_caja
	  and j11_compania     = j10_compania
	  and j11_localidad    = j10_localidad
	  and j11_tipo_fuente  = j10_tipo_fuente
	  and j11_num_fuente   = j10_num_fuente
	  --and j11_codigo_pago  = 'CH'
	into temp t1;
select * from t1 order by usucaj;
select fecha, usucaj, cp, sum(j11_valor) valor
	from t1
	group by 1, 2, 3
	order by 1;
drop table t1;
