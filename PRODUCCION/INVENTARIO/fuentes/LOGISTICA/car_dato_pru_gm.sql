begin work;

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_usuario, r108_fecing)
	values (1, 1, 1, "A", "ZONA NORTE", "FOBOS", current);

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_usuario, r108_fecing)
	values (1, 1, 2, "A", "ZONA CENTRO", "FOBOS", current);

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_usuario, r108_fecing)
	values (1, 1, 3, "A", "ZONA SUR", "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 1, 1, 1, "A", "BELLAVISTA", 24, "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 1, 1, 2, "A", "URDESA", 12, "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 1, 2, 1, "A", "CENTRO", 12, "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 1, 3, 1, "A", "BATALLON", 72, "FOBOS", current);

insert into rept110
	(r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	 r110_descripcion, r110_placa, r110_usuario, r110_fecing)
	values (1, 1, 1, "A", "CAMION AZUL", "GFP-0012", "FOBOS", current);

insert into rept110
	(r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	 r110_descripcion, r110_placa, r110_usuario, r110_fecing)
	values (1, 1, 2, "A", "CAMION PLANCHA", "GPX-0055", "FOBOS", current);

insert into rept111
	(r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	 r111_estado, r111_nombre, r111_cod_trab, --r111_tipo,
	 r111_usuario, r111_fecing)
	select n30_compania, 1, 1, 1, n30_estado, n30_nombres, n30_cod_trab,
		"FOBOS", current
		from rolt030
		where n30_compania  = 1
		  and n30_estado    = "A"
		  and n30_cod_depto = 13;

insert into rept111
	(r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	 r111_estado, r111_nombre, r111_cod_trab, --r111_tipo,
	 r111_usuario, r111_fecing)
	select n30_compania, 1, 2, 1, n30_estado, n30_nombres, n30_cod_trab,
		"FOBOS", current
		from rolt030
		where n30_compania  = 1
		  and n30_estado    = "A"
		  and n30_cod_depto = 13;

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	values (1, 1, 1, "A", "LLEVAR LA GUIA AL CLIENTE", "C","FOBOS",current);

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	values (1, 1, 2, "A", "DEJAR MERCADERIA", "C", "FOBOS", current);

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	values (1, 1, 3, "A", "LLEVAR EN EL CAMION", "C", "FOBOS", current);

commit work;
