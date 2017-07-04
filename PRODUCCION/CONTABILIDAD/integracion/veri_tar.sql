
drop table te;
select j10_tipo_fuente, j10_num_fuente, j10_tipo_destino, j10_num_destino,
	j11_valor, j10_estado from cajt011, cajt010
	where j11_codigo_pago = 'TJ' and j10_tipo_fuente = j11_tipo_fuente and
		j10_num_fuente = j11_num_fuente
	into temp te;

select b13_tipo_comp, b13_num_comp, j10_num_destino, b13_glosa
	from te, ctbt013
	where j11_valor = b13_valor_base and b13_tipo_comp = 'DR' and
		b13_cuenta = '11210101001' and b13_glosa
		matches '*' || j10_num_destino || '*'
	order by 1,2
