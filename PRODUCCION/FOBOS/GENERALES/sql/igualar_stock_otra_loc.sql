select r11_bodega, r11_item, r11_stock_act, r11_stock_ant
	from rept011
	where r11_compania  = 1
	  and r11_bodega in
		(select r02_codigo from rept002
			where r02_compania   = 1
			  and r02_localidad  = 3
			  and r02_tipo      <> 'S')
	  and r11_stock_act < 0
	order by 3
