{
select * from rept020
	where r20_compania = 1 and r20_localidad = 1 and
		r20_cod_tran = 'IM' and r20_num_tran = 1
	into temp te

select r20_item, r20_cant_ped, r20_costo, r17_cantrec, r20_stock_ant
	from te, rept017
	where r20_item = r17_item
}
select r20_item, r20_costant_mb, r20_stock_ant,  r20_costo, r20_cant_ven
	from te
