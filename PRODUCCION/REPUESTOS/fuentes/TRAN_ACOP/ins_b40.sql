begin work;

	insert into ctbt040
		(b40_compania, b40_localidad, b40_modulo, b40_bodega,
		 b40_grupo_linea, b40_porc_impto, b40_venta, b40_descuento,
		 b40_dev_venta, b40_costo_venta, b40_dev_costo, b40_inventario,
		 b40_transito, b40_ajustes, b40_flete)
		select b40_compania, b40_localidad, b40_modulo, 'EB',
			b40_grupo_linea, b40_porc_impto, b40_venta,
			b40_descuento, b40_dev_venta, b40_costo_venta,
			b40_dev_costo, '11400101006', b40_transito,
			b40_ajustes, b40_flete
			from ctbt040
			where b40_bodega     =
				(select r00_bodega_fact
					from rept000
					where r00_compania in (1, 2)
					  and r00_estado   = 'A')
			  and b40_porc_impto = 0.00;

commit work;
