begin work;

	insert into base_inicial:gent057

		(g57_user, g57_compania, g57_modulo, g57_proceso, g57_usuario,
		 g57_fecing)


		select g57_user, g57_compania, g57_modulo, g57_proceso, 'FOBOS',
				current

			from jadesa:gent057
			where g57_user = 'FOBOS';

rollback work;

-- *** DESCOMENTAR SI SE QUIERE CARGAR ESTA TABLA EN LA BASE INICIAL *** --
--commit work;
