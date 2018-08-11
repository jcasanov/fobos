begin work;

insert into ctbt040
	select b40_compania, b40_localidad, b40_modulo, b40_bodega,
		b40_grupo_linea, 0.00, '41010101010', b40_descuento,
		b40_dev_venta, b40_costo_venta, b40_dev_costo, b40_inventario,
		b40_transito, b40_ajustes, b40_flete
		from ctbt040
		where 1 = 1;

commit work;
