begin work;

select r109_compania cia, r109_localidad loc, r109_cod_zona cod_z,
	r109_cod_subzona cod_sz, r109_estado est, r109_descripcion nom,
	r109_horas_entr hor_e, r109_pais pais, r109_divi_poli divi_p,
	r109_ciudad ciu, r109_usuario usua, r109_fecing fec
	from rept109
	where r109_compania = 999
	into temp t1;

load from "divi_poli_nue_uio.unl" insert into t1;

insert into rept109
	(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona,
	 r109_estado, r109_descripcion, r109_horas_entr, r109_pais,
	 r109_divi_poli, r109_ciudad, r109_usuario, r109_fecing)
	select * from t1;

drop table t1;

commit work;
