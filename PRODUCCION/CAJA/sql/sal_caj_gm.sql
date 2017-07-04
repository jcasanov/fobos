select j11_compania cia, j11_localidad loc, j11_tipo_fuente tp_f,
	j11_num_fuente num_f, j11_secuencia secu, j10_codigo_caja cod_caj,
	j11_codigo_pago cod_p, sum(j11_valor) valor
	from cajt010, cajt011
	where j10_compania    = 1
	  and j10_estado      = "P"
	  and j11_compania    = j10_compania
	  and j11_localidad   = j10_localidad
	  and j11_tipo_fuente = j10_tipo_fuente
	  and j11_num_fuente  = j10_num_fuente
	  and j11_codigo_pago in ("CH")
	  and j11_num_egreso  is null
	group by 1, 2, 3, 4, 5, 6, 7
	into temp t1;
select loc, cod_caj, cod_p, round(sum(valor), 2) valor, count(cod_p) tot_reg
	from t1
	group by 1, 2, 3
	order by 1, 2, 3;
select * from t1;
drop table t1;
