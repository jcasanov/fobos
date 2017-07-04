begin work;

	insert into rept002
		(r02_compania, r02_codigo, r02_nombre, r02_estado, r02_tipo,
		 r02_area, r02_factura, r02_localidad, r02_tipo_ident,
		 r02_usuario, r02_fecing)
		select g02_compania, 'SP', 'SUBFACTORY', 'A', 'F', 'R', 'N',
			g02_localidad, 'S', 'FOBOS', current
		from gent002
		where g02_matriz = 'S'
		  and g02_estado = 'A';

	update rept002
		set r02_tipo_ident = 'X'
		where r02_compania in (1, 2)
		  and r02_codigo    = '04';

commit work;
