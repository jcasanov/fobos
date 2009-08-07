{
select r11_item, r11_bodega, r11_stock_act from rept011
	where r11_stock_act > 0
	into temp te
}
insert into rept031
	select r10_compania, 2002,2, r11_bodega, r11_item, r11_stock_act,
	r10_costo_mb, r10_costo_ma, r10_precio_mb, r10_precio_ma
	from te, rept010
	where r11_item = r10_codigo and
		r10_compania = 1
