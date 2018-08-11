begin work;

	update gent054
		set g54_nombre = 'MANTENIMIENTO ANEXO TRANSACCIONAL'
		where g54_proceso = 'srip201';

	update gent054
		set g54_nombre = 'ANEXO TRANSACCIONAL ANULADOS'
		where g54_proceso = 'srip202';

	insert into gent054
		(g54_modulo, g54_proceso, g54_nombre, g54_tipo, g54_estado,
		 g54_usuario, g54_fecing)
		values ('SR', 'srip206', 'GENERAR ANEXO TRANSACCIONAL', 'P', 'A',
				'FOBOS', current);

commit work;
