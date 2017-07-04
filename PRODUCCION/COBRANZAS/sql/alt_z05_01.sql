begin work;

	alter table "fobos".cxct005
		add (z05_comision	char(1)		before z05_usuario);

	update cxct005
		set z05_comision = 'N'
		where 1 = 1;

	alter table "fobos".cxct005
		modify (z05_comision	char(1)		not null);

	alter table "fobos".cxct005
		add constraint
			check (z05_comision in ("S", "N"))
				constraint "fobos".ck_03_cxct005;

commit work;
