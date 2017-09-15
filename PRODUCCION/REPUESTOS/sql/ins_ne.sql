begin work;

	insert into "fobos".gent015
		(g15_compania, g15_localidad, g15_modulo, g15_bodega, g15_tipo,
		 g15_nombre, g15_numero, g15_usuario, g15_fecing)
		values
			(1, 1, "RE", "AA", "NE", "NOTA DE ENTREGA", 0, "FOBOS", current);

commit work;
