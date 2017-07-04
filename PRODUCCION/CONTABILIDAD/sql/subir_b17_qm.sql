select b17_compania, b17_cuenta, b17_descripcion, b17_descri_alt, b17_estado,
	b17_tipo_cta, b17_tipo_mov, b17_nivel, b17_cod_ccosto, b17_saldo_ma,
	b17_cuenta_fobos, b17_localidad
	from ctbt017
	where b17_compania = 999
	into temp t1;

load from "ctbt017_uio.unl" insert into t1;

insert into ctbt017
	(b17_compania, b17_cuenta, b17_descripcion, b17_descri_alt, b17_estado,
	 b17_tipo_cta, b17_tipo_mov, b17_nivel, b17_cod_ccosto, b17_saldo_ma,
	 b17_cuenta_fobos, b17_localidad, b17_usuario, b17_fecing)
	select t1.*, "FOBOS", current
		from t1;

drop table t1;
