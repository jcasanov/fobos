select r20_compania cia, r20_localidad loc, r20_cod_tran tp, r20_num_tran num,
	r20_bodega bd, r20_item item, r20_costant_mb cos_ant,
	r20_costnue_mb cos_nue, r20_cant_ven cant, r20_stock_ant sto_ant,
	r20_fecing fecha
	from rept020
	where r20_compania   = 1
	  and r20_localidad  = 1
	  and r20_cod_tran   = 'CL'
	  and r20_num_tran  in (9291, 9295, 9318, 9393)
	into temp t1;
select count(*) tot_t1 from t1;
select r20_compania cia2, r20_localidad loc2, r20_bodega bd2, r20_item item2,
	max(r20_fecing) fecha2
	from t1, rept020
	where r20_compania   = cia
	  and r20_localidad  = loc
	  and r20_bodega     = bd
	  and r20_item       = item
	  and r20_fecing    >= fecha
	group by 1, 2, 3, 4
	into temp t2;
select count(*) tot_t2 from t2;
select r20_compania cia3, r20_localidad loc3, r20_cod_tran tp3,
	r20_num_tran num3, r20_bodega bd3, r20_item item3,
	r20_costant_mb cos_ant3, r20_costnue_mb cos_nue3, r20_cant_ven cant3,
	r20_stock_ant sto_ant3, r20_fecing fecha3
	from t2, rept020
	where r20_compania  = cia2
	  and r20_localidad = loc2
	  and r20_bodega    = bd2
	  and r20_item      = item2
	  and r20_fecing    = fecha2
	into temp t3;
drop table t2;
select count(*) tot_t3 from t3;
select tp cod, num numero, bd bodega, item items, cos_ant costo_ant,
	cos_nue costo_nue, cant cantidad, sto_ant stock_ant,
	cant + sto_ant stock_act, fecha fecing
	from t1
union
select tp3 cod, num3 numero, bd3 bodega, item3 items, cos_ant3 costo_ant,
	cos_nue3 costo_nue, cant3 cantidad, sto_ant3 stock_ant,
	r11_stock_act stock_act, fecha3 fecing
	from t3, rept011
	where r11_compania = cia3
	  and r11_bodega   = bd3
	  and r11_item     = item3
	into temp t4;
drop table t1;
drop table t3;
select count(*) tot_t4 from t4;
--unload to "item_edesa_mal.unl"
	select * from t4
		order by items, cod, numero, fecing;
drop table t4;
