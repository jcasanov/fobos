begin work;

	alter table "fobos".rept000
		add (r00_concil_cl_im			char(1));

	update "fobos".rept000
		set r00_concil_cl_im = 'N'
		where 1 = 1;

	alter table "fobos".rept000
		modify (r00_concil_cl_im		char(1)		not null);

	alter table "fobos".rept000
		add constraint
			check (r00_concil_cl_im in ('S', 'N'))
				constraint "fobos".ck_08_rept000;

	update "fobos".rept000
		set r00_bodega_fact = 'JA'
		where 1 = 1;

--rollback work;
commit work;
