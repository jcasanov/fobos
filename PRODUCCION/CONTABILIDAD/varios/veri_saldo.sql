drop table te;
select b13_cuenta, sum(b13_valor_base) valor from ctbt012, ctbt013
	where b13_compania = 1 and year(b13_fec_proceso) = 2002 and
		month(b13_fec_proceso) = 05 and b13_valor_base > 0 and
		--b13_cuenta[1,1] = 1 and
           	b12_compania = b13_compania and
		b12_tipo_comp = b13_tipo_comp and
		b12_num_comp  = b13_num_comp and
		b12_estado <> 'E'
	group by 1
	union all
select b13_cuenta, sum(b13_valor_base) valor from ctbt012, ctbt013
	where b13_compania = 1 and year(b13_fec_proceso) = 2002 and
		month(b13_fec_proceso) = 05 and b13_valor_base < 0 and
		--b13_cuenta[1,1] = 1 and
           	b12_compania = b13_compania and
		b12_tipo_comp = b13_tipo_comp and
		b12_num_comp  = b13_num_comp and
		b12_estado <> 'E'
	group by 1
	order by 1
into temp te;

select b13_cuenta, valor, b11_db_mes_05, valor - b11_db_mes_05 from te, ctbt011
	where b13_cuenta = b11_cuenta and valor > 0 and
		b11_ano = 2002
	union all
select b13_cuenta, valor, b11_cr_mes_05, b11_cr_mes_05 + valor from te, ctbt011
	where b13_cuenta = b11_cuenta and valor < 0 and
		b11_ano = 2002
