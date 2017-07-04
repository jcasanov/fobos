begin work;

select r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	r108_descripcion, r108_cia_trans
	from rept108
	where r108_compania = 999
	into temp tmp_r108;

select r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	r109_estado, r109_descripcion, r109_horas_entr, r109_pais,
	r109_divi_poli, r109_ciudad
	from rept109
	where r109_compania = 999
	into temp tmp_r109;

select r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	r110_descripcion, r110_placa
	from rept110
	where r110_compania = 999
	into temp tmp_r110;

select r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	r111_estado, r111_nombre, r111_cod_trab
	from rept111
	where r111_compania = 999
	into temp tmp_r111;

select r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	r112_descripcion, r112_tipo
	from rept112
	where r112_compania = 999
	into temp tmp_r112;

select r115_compania, r115_localidad, r115_cod_trans, r115_cod_ayud,
	r115_estado, r115_nombre, r115_cod_trab
	from rept115
	where r115_compania = 999
	into temp tmp_r115;

select r116_compania, r116_localidad, r116_cia_trans, r116_estado,
	r116_razon_soc, r116_tipo, r116_codprov
	from rept116
	where r116_compania = 999
	into temp tmp_r116;

load from "rept108_gm.csv" delimiter "," insert into tmp_r108;
load from "rept109_gm.csv" delimiter "," insert into tmp_r109;
load from "rept110_gm.csv" delimiter "," insert into tmp_r110;
load from "rept111_gm.csv" delimiter "," insert into tmp_r111;
load from "rept112_gm.csv" delimiter "," insert into tmp_r112;
load from "rept115_gm.csv" delimiter "," insert into tmp_r115;
load from "rept116_gm.csv" delimiter "," insert into tmp_r116;

insert into rept116
	(r116_compania, r116_localidad, r116_cia_trans, r116_estado,
	 r116_razon_soc, r116_tipo, r116_codprov, r116_usuario, r116_fecing)
	select tmp_r116.*, "FOBOS", current
		from tmp_r116;

insert into rept108
	(r108_compania, r108_localidad, r108_cod_zona, r108_estado,
	 r108_descripcion, r108_cia_trans, r108_usuario, r108_fecing)
	select tmp_r108.*, "FOBOS", current
		from tmp_r108;

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_pais,
	 r109_divi_poli, r109_ciudad, r109_usuario, r109_fecing)
	select tmp_r109.*, "FOBOS", current
		from tmp_r109;

insert into rept110
	(r110_compania, r110_localidad, r110_cod_trans, r110_estado,
	 r110_descripcion, r110_placa, r110_usuario, r110_fecing)
	select tmp_r110.*, "FOBOS", current
		from tmp_r110;

insert into rept111
	(r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer,
	 r111_estado, r111_nombre, r111_cod_trab, r111_usuario, r111_fecing)
	select tmp_r111.*, "FOBOS", current
		from tmp_r111;

insert into rept112
	(r112_compania, r112_localidad, r112_cod_obser, r112_estado,
	 r112_descripcion, r112_tipo, r112_usuario, r112_fecing)
	select tmp_r112.*, "FOBOS", current
		from tmp_r112;

insert into rept115
	(r115_compania, r115_localidad, r115_cod_trans, r115_cod_ayud,
	 r115_estado, r115_nombre, r115_cod_trab, r115_usuario, r115_fecing)
	select tmp_r115.*, "FOBOS", current
		from tmp_r115;

drop table tmp_r108;
drop table tmp_r109;
drop table tmp_r110;
drop table tmp_r111;
drop table tmp_r112;
drop table tmp_r115;
drop table tmp_r116;

--rollback work;
commit work;
