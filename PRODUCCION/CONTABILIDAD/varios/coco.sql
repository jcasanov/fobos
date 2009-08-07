select sum(b11_db_mes_02), sum(b11_cr_mes_02) from ctbt011, ctbt010
	where b11_compania = 1 and b11_ano = 2002 and
		b10_nivel = 6 and
		b11_compania = b10_compania and
		b11_cuenta = b10_cuenta	and b10_tipo_cta = 'B'
