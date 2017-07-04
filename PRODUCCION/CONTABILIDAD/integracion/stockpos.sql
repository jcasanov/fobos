{
select r20_cod_tran, r20_num_tran, r20_bodega, r20_cant_ven, r20_fecing,
	r20_stock_ant
	from rept020
	where r20_item = '46312'
	into temp to;
}
select r20_cod_tran, r19_bodega_ori, r19_bodega_dest, r20_bodega,
	r20_cant_ven, r20_fecing, r19_referencia, r20_stock_ant
	from to, rept019
	where r20_cod_tran = r19_cod_tran and
	      r20_num_tran = r19_num_tran
	order by 6
