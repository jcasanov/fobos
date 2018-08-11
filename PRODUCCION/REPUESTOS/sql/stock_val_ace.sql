--unload to "stock_val_ser.txt"
select r31_item, r31_bodega,
	r31_stock, r31_costo_mb, (r31_costo_mb * r31_stock) costo_tot,
	r31_precio_mb, (r31_precio_mb * r31_stock) prec_tot
	from rept031, rept002
	where r31_compania     = 1
	  and r31_ano          = 2006
	  and r31_mes          = 12
	  and r31_bodega       <> '98'
	  and r02_compania     = r31_compania
	  and r02_codigo       = r31_bodega
	  and r02_localidad    in (3)
	into temp t1;
select nvl(sum(costo_tot), 0) costo_tot, nvl(sum(prec_tot), 0) prec_tot
	from t1;
drop table t1;
