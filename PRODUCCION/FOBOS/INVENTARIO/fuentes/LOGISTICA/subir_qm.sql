begin work;

select r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	r108_descripcion
	from rept108
	where r108_compania = 999
	into temp tmp_r108;

select r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	r109_estado, r109_descripcion, r109_horas_entr
	from rept109
	where r109_compania = 999
	into temp tmp_r109;

select r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	r110_descripcion, r110_placa
	from rept110
	where r110_compania = 999
	into temp tmp_r110;

select r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	r111_estado, r111_nombre, r111_cod_trab--, r111_tipo
	from rept111
	where r111_compania = 999
	into temp tmp_r111;

select r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	r112_descripcion, r112_tipo
	from rept112
	where r112_compania = 999
	into temp tmp_r112;

load from "rept108_qm.csv" delimiter "," insert into tmp_r108;
load from "rept109_qm.csv" delimiter "," insert into tmp_r109;
load from "rept110_qm.csv" delimiter "," insert into tmp_r110;
load from "rept111_qm.csv" delimiter "," insert into tmp_r111;
load from "rept112_qm.csv" delimiter "," insert into tmp_r112;

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_usuario, r108_fecing)
	select tmp_r108.*, "FOBOS", current
		from tmp_r108;

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_usuario,
	 r109_fecing)
	select tmp_r109.*, "FOBOS", current
		from tmp_r109;

insert into rept110
	(r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	 r110_descripcion, r110_placa, r110_usuario, r110_fecing)
	select tmp_r110.*, "FOBOS", current
		from tmp_r110;

insert into rept111
	(r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	 r111_estado, r111_nombre, r111_cod_trab, --r111_tipo,
	 r111_usuario, r111_fecing)
	select tmp_r111.*, "FOBOS", current
		from tmp_r111;

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	select tmp_r112.*, "FOBOS", current
		from tmp_r112;

drop table tmp_r108;
drop table tmp_r109;
drop table tmp_r110;
drop table tmp_r111;
drop table tmp_r112;

commit work;
