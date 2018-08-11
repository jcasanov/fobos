begin work;

	insert into gent054

		(g54_modulo, g54_proceso, g54_nombre, g54_tipo, g54_estado, g54_usuario,
		 g54_fecing)

		values
			('GE', 'genp145', 'CAMBIO FECHA DEL SISTEMA', 'M', 'A', 'FOBOS',
			 current);


	insert into gent057

		(g57_user, g57_compania, g57_modulo, g57_proceso, g57_usuario,
		 g57_fecing)

		values
			('FOBOS', 1, 'GE', 'genp145', 'FOBOS', current);

--rollback work;
commit work;
