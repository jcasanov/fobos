begin work;

select r20_compania, date(r20_fecing) fecha, r20_bodega, r20_linea,
	r20_rotacion, nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	precio, nvl(sum(r20_costo * r20_cant_ven), 0) costo
       	from rept020
        where r20_compania  = 2
       	  and r20_localidad = 6
          and r20_cod_tran  = 'FA'
          and r20_num_tran  in (67, 76, 81)
        group by 1, 2, 3, 4, 5
	into temp t1;

merge into rept060
	using t1
	on (r60_compania = r20_compania
	and r60_fecha    = fecha
        and r60_bodega   = r20_bodega
        and r60_vendedor = 4
        and r60_moneda   = 'DO'
        and r60_linea    = r20_linea
        and r60_rotacion = r20_rotacion)
	when matched then
		update set r60_precio = r60_precio + t1.precio,
			   r60_costo  = r60_costo  + t1.costo
	when not matched then
		insert (r60_compania, r60_fecha, r60_bodega, r60_vendedor,
			r60_moneda, r60_linea, r60_rotacion, r60_precio,
			r60_costo)
		values (r20_compania, fecha, r20_bodega, 4, 'DO', r20_linea,
			r20_rotacion, precio, costo);

drop table t1;

commit work;
