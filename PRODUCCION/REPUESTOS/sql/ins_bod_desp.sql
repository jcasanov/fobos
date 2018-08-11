begin work;

	insert into "fobos".rept009
		(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado, r09_usuario,
		 r09_fecing)
		values
			(1, 'D', 'BODEGA DE DESPACHO', 'A', 'FOBOS', current);

	insert into "fobos".rept009
		(r09_compania, r09_tipo_ident, r09_descripcion, r09_estado, r09_usuario,
		 r09_fecing)
		values
			(1, 'I', 'BODEGA DE VERIFICACION', 'A', 'FOBOS', current);

	update "fobos".rept002
		set r02_tipo_ident = 'D'
		where r02_compania = 1
		  and r02_codigo   = 'LU';

--rollback work;
commit work;
