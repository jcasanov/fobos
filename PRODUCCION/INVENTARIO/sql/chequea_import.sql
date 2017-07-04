--drop table t1;
select r19_num_tran imp, r20_item[1,6], (r20_cant_ven * r20_costo) val_imp,
	(r17_cantrec * r17_costuni_ing) val_liq, r20_costo, r17_costuni_ing,
	r17_cantrec
	from rept019, rept020, rept029, rept017
	where r19_compania    = 2
	  and r19_localidad   = 7
	  and r19_cod_tran    = 'IM'
	  and r20_compania    = r19_compania
	  and r20_localidad   = r19_localidad
	  and r20_cod_tran    = r19_cod_tran
	  and r20_num_tran    = r19_num_tran
	  --and r20_costo       > 0
	  --and r20_costo       < 1
	  and r29_compania    = r19_compania
	  and r29_localidad   = r19_localidad
	  and r29_numliq      = r19_numliq
	  and r17_compania    = r29_compania
	  and r17_localidad   = r29_localidad
	  and r17_pedido      = r29_pedido
	  and r17_item        = r20_item
	  --and r17_costuni_ing > 0
	  --and r17_costuni_ing < 1
	into temp t1;
delete from t1 where val_imp = val_liq;
select count(unique imp) tot_liq from t1;
select imp, r20_item, val_imp, val_liq, val_imp - val_liq dif
	from t1
	where r20_item = '4602';
select imp, r20_item, r17_cantrec, r17_costuni_ing
	from t1
	where r20_item = '4602';
select imp, r20_item, val_imp, val_liq, val_imp - val_liq dif
	from t1
	order by 1 desc;
select imp, r20_item, r20_costo, r17_costuni_ing from t1 order by 1 desc;
drop table t1;
