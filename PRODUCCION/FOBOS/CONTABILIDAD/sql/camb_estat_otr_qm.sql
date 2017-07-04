begin work;

	update ctbt040
		set b40_venta     = "41020201001",
		    b40_descuento = "41020201003",
		    b40_dev_venta = "41020201002"
		where b40_compania    = 1
		  and b40_localidad  in (3, 4, 5)
		  and b40_porc_impto  = 0
		  and b40_venta       = "41020101001"
		  and b40_descuento   = "41020101003"
		  and b40_dev_venta   = "41020101002";

	update ctbt040
		set b40_venta     = "41020203001",
		    b40_descuento = "41020203003",
		    b40_dev_venta = "41020203002"
		where b40_compania    = 1
		  and b40_localidad  in (3, 4, 5)
		  and b40_porc_impto  = 0
		  and b40_venta       = "41020103001"
		  and b40_descuento   = "41020103003"
		  and b40_dev_venta   = "41020103002";

	update ctbt040
		set b40_venta     = "41020204001",
		    b40_descuento = "41020204003",
		    b40_dev_venta = "41020204002"
		where b40_compania    = 1
		  and b40_localidad  in (3, 4, 5)
		  and b40_porc_impto  = 0
		  and b40_venta       = "41020104001"
		  and b40_descuento   = "41020104003"
		  and b40_dev_venta   = "41020104002";

--rollback work;
commit work;
