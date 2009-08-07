{´
select unique r11_item from rept011
	where r11_compania = 1
	  and r11_stock_act > 0
	into temp temp_jcm;
}
select r10_codigo, r10_nombre, r10_partida
	from temp_jcm, rept010
	where r10_compania = 1
	  and r10_codigo   = r11_item
	order by 3, 1;
