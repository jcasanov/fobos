begin work;

	alter table "fobos".rolt043
		add (n43_pago_efec	char(1)		before n43_usuario);

	alter table "fobos".rolt043
		add (n43_tributa	char(1)		before n43_usuario);

	alter table "fobos".rolt043
		add (n43_incluir_ej	char(1)		before n43_usuario);

	{--
	update rolt043
		set n43_pago_efec  = 'S',
		    n43_tributa    = 'S',
		    n43_incluir_ej = 'N'
		where n43_compania = 1
		  and n43_num_rol  < 8;

	update rolt043
		set n43_pago_efec  = 'N',
		    n43_tributa    = 'N',
		    n43_incluir_ej = 'S'
		where n43_compania = 1
		  and n43_num_rol  = 8;
	--}

	update rolt043
		set n43_pago_efec  = 'N',
		    n43_tributa    = 'N',
		    n43_incluir_ej = 'N'
		where n43_compania = 1;

	alter table "fobos".rolt043
		modify (n43_pago_efec	char(1)		not null);

	alter table "fobos".rolt043
		modify (n43_tributa	char(1)		not null);

	alter table "fobos".rolt043
		modify (n43_incluir_ej	char(1)		not null);

	alter table "fobos".rolt043
		add constraint
			check (n43_pago_efec in ('S', 'N'))
				constraint "fobos".ck_02_rolt043;

	alter table "fobos".rolt043
		add constraint
			check (n43_tributa in ('S', 'N'))
				constraint "fobos".ck_03_rolt043;

	alter table "fobos".rolt043
		add constraint
			check (n43_incluir_ej in ('S', 'N'))
				constraint "fobos".ck_04_rolt043;

commit work;
