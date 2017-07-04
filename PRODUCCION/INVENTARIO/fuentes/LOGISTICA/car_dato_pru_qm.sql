begin work;

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_usuario, r108_fecing)
	values (1, 3, 1, "A", "ZONA NORTE", "FOBOS", current);

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_usuario, r108_fecing)
	values (1, 3, 2, "A", "ZONA CENTRO", "FOBOS", current);

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_usuario, r108_fecing)
	values (1, 3, 3, "A", "ZONA SUR", "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 3, 1, 1, "A", "NORTE", 24, "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 3, 1, 2, "A", "JIPIJAPA", 12, "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 3, 2, 1, "A", "CHILLOGALLO", 48, "FOBOS", current);

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	values (1, 3, 3, 1, "A", "BATALLON", 72, "FOBOS", current);

insert into rept110
	(r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	 r110_descripcion, r110_placa, r110_usuario, r110_fecing)
	values (1, 3, 1, "A", "CAMION AZUL", "GFP-0012", "FOBOS", current);

insert into rept110
	(r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	 r110_descripcion, r110_placa, r110_usuario, r110_fecing)
	values (1, 3, 2, "A", "CAMION PLANCHA", "GPX-0055", "FOBOS", current);

create temp table tmp_r111

	(
		r111_compania		integer			not null,
		r111_localidad		smallint		not null,
		r111_cod_trans		smallint		not null,
		r111_cod_chofer		serial			not null,
		r111_estado		char(1)			not null,
		r111_nombre		varchar(45,30)		not null,
		r111_cod_trab		integer,
		--r111_tipo		char(1)			not null,
		r111_usuario		varchar(10,5)		not null,
		r111_fecing		datetime year to second	not null

	);

insert into tmp_r111
	(r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	 r111_estado, r111_nombre, r111_cod_trab, --r111_tipo,
	 r111_usuario, r111_fecing)
	select n30_compania, 3, 1, 0, n30_estado, n30_nombres, n30_cod_trab,
		"FOBOS", current
		from rolt030
		where n30_compania  = 1
		  and n30_estado    = "A"
		  and n30_cod_depto = 8;

insert into rept111
	(r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	 r111_estado, r111_nombre, r111_cod_trab, --r111_tipo,
	 r111_usuario, r111_fecing)
	select * from tmp_r111;

drop table tmp_r111;

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	values (1, 3, 1, "A", "LLEVAR LA GUIA AL CLIENTE", "C","FOBOS",current);

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	values (1, 3, 2, "A", "DEJAR MERCADERIA", "C", "FOBOS", current);

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	values (1, 3, 3, "A", "LLEVAR EN EL CAMION", "C", "FOBOS", current);

commit work;
