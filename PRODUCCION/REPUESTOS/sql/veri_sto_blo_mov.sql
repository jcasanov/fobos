set isolation to dirty read;
select r11_item item, r11_bodega bd, r11_stock_act stock
	from rept011, rept002
	where r11_compania   = 1
	  and r11_stock_act <> 0
	  and r02_compania   = r11_compania
	  and r02_codigo     = r11_bodega
	  --and r02_localidad  = 1
	  --and r02_localidad  in (3, 5)
	  and r02_localidad  = 4
	  and r02_estado     = 'A'
	  and not exists
		(select 1 from rept020
			where r20_compania   = r02_compania
			  and r20_localidad  = r02_localidad
			  and r20_cod_tran  <> 'TR'
			  and r20_bodega     = r02_codigo
			  and r20_item       = r11_item)
	  and not exists
		(select 1 from rept020
			where r20_compania   = r02_compania
			  and r20_localidad  = r02_localidad
			  and r20_cod_tran   = 'TR'
			  and r20_item       = r11_item)
	into temp t1;
begin work;
	update rept011
		set r11_stock_act = 0
		where r11_compania = 1
		  and exists (select 1 from t1
				where item = r11_item
				  and bd   = r11_bodega);
--rollback work;
commit work;
drop table t1;
