drop table te;
select b13_cuenta, sum(b13_valor_base) valor from ctbt012, ctbt013
	where b13_compania = 1 and year(b13_fec_proceso) = 2002 and
		month(b13_fec_proceso) = 02 and b13_valor_base > 0 and
           	b12_compania = b13_compania and
		b12_tipo_comp = b13_tipo_comp and
		b12_num_comp  = b13_num_comp and
		b12_estado <> 'E'
	group by 1
	union all
select b13_cuenta, sum(b13_valor_base) valor from ctbt012, ctbt013
	where b13_compania = 1 and year(b13_fec_proceso) = 2002 and
		month(b13_fec_proceso) = 02 and b13_valor_base < 0 and
           	b12_compania = b13_compania and
		b12_tipo_comp = b13_tipo_comp and
		b12_num_comp  = b13_num_comp and
		b12_estado <> 'E'
	group by 1
	order by 1
into temp te;
select b13_cuenta, valor, b11_db_mes_02, valor - b11_db_mes_02
	from te, ctbt011
	where b13_cuenta = b11_cuenta and valor > 0 and
		b11_ano = 2002 and
		abs(valor) <> abs(b11_db_mes_02);
select b13_cuenta, valor, b11_cr_mes_02, abs(valor) - b11_cr_mes_02
	from te, ctbt011
	where b13_cuenta = b11_cuenta and valor < 0 and
		b11_ano = 2002 and
		abs(valor) <> abs(b11_cr_mes_02);
{
select sum(valor) from te
	where valor > 0
union all
select sum(valor) from te
	where valor < 0;
select sum(b11_db_mes_06), sum(b11_cr_mes_06)
	from ctbt011, ctbt010
	where b10_compania = b11_compania and
		b10_nivel = 6 and
		b11_ano   = 2002 and
		b11_cuenta <> '31040101002' and
		b11_cuenta = b10_cuenta;

select b11_cuenta, sum(b11_db_mes_06), sum(b11_cr_mes_06)
	from ctbt011, ctbt010
	where b10_compania = b11_compania and
		b10_nivel = 6 and
		b11_ano   = 2002 and
		b11_cuenta = '31040101002' and
		b11_cuenta = b10_cuenta
	group by 1;
select sum(valor) from te
	where b13_cuenta[1,1] > '2' and valor > 0
union all
select sum(valor) from te
	where b13_cuenta[1,1] > '2' and valor < 0
}
