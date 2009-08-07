{
select * from rept020 where r20_cod_tran = 'IM'
	INTO TEMP te

select r20_item, r20_costant_mb, r20_stock_ant, te_stock, te_costo
	from te, migracion:te_stock
	where r20_item = te_item

select r20_item, ((r20_costant_mb * r20_stock_ant) +
		  (r20_cant_ven * r20_costo)) / (r20_stock_ant + r20_cant_ven),
	r20_costnue_mb, r10_costo_mb, r10_costult_mb
	from te, rept010
	where r20_item = r10_codigo and
 	r10_compania = 1

select r20_item, r10_costo_mb, r20_precio, r10_precio_mb, r10_precio_ant,
	r10_fec_camprec
	from te, rept010
	where r20_item = r10_codigo and
 	r10_compania = 1
}
