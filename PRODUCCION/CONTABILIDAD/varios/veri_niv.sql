select b10_nivel, sum(b11_db_mes_01) from ctbt011, ctbt010
	where b10_compania = b11_compania and b10_cuenta = b11_cuenta
	group by 1
