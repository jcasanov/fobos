begin work;

	alter table "fobos".fobos
		add (fb_usar_fechasist			char(1));

	alter table "fobos".fobos
		add constraint
			check (fb_usar_fechasist in ('S', 'N'))
			constraint "fobos".ck_01_fobos;

	update "fobos".fobos
		set fb_usar_fechasist = 'N'
		where 1 = 1;
 
	alter table "fobos".fobos
		modify (fb_usar_fechasist		char(1)			not null);

	alter table "fobos".fobos
		add (fb_fechasist				date);

--rollback work;
commit work;
