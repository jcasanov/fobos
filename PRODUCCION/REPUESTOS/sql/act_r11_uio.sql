begin work;

update rept011
	set r11_stock_act = 0
	where r11_compania   = 1
	  and r11_bodega     = '79'
	  and r11_stock_act <> 0;

commit work;
