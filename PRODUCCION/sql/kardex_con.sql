select r19_cod_tran, r19_num_tran, r20_cant_ven, r20_bodega, r19_fecing
	from rept019, rept020
	where r19_compania  = 1
	  and r19_localidad = 3
	  and date(r19_fecing) between mdy(7,1,2003) and mdy(8,31,2003)
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and r20_item      = '15666'
	order by r19_fecing;
select r31_bodega, r31_item, r31_stock
	from rept031
	where r31_compania  = 1
	  and r31_ano       = 2003
	  and r31_mes       in (7,8)
	  and r31_bodega    = 11
	  and r31_item      = '15666'
