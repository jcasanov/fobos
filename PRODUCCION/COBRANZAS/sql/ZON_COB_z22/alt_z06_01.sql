begin work;

	alter table "fobos".cxct006
		add (z06_estado 	char(1)		before z06_usuario);

	alter table "fobos".cxct006
		add (z06_comision 	char(1)		before z06_usuario);

	update cxct006
		set z06_estado   = 'A',
		    z06_comision = 'S'
		where 1 = 1;

	alter table "fobos".cxct006
		modify (z06_estado 	char(1)		not null);

	alter table "fobos".cxct006
		modify (z06_comision 	char(1)		not null);

	alter table "fobos".cxct006
		add constraint check
			(z06_estado in ("A", "B"))
			 constraint "fobos".ck_01_cxct006;

	alter table "fobos".cxct006
		add constraint check
			(z06_comision in ("S", "N"))
			 constraint "fobos".ck_02_cxct006;

commit work;
