alter table "fobos".rept021 drop r21_trans_fact;
alter table "fobos".rept021 drop r21_usr_tr_fa;
alter table "fobos".rept021 drop r21_fec_tr_fa;

--begin work;

	alter table "fobos".rept021
		add (r21_trans_fact	char(1)		before r21_usuario);

	alter table "fobos".rept021
		add (r21_usr_tr_fa	varchar(10,5)	before r21_usuario);

	alter table "fobos".rept021
		add (r21_fec_tr_fa	datetime year to second
			before r21_usuario);

	update rept021
		set r21_trans_fact = 'N'
		where 1 = 1;

	alter table "fobos".rept021
		modify (r21_trans_fact	char(1)		not null);

	alter table "fobos".rept021
		add constraint
			check (r21_trans_fact		in ("S", "N"))
			constraint "fobos".ck_02_rept021;

	create index "fobos".i11_fk_rept021
		on "fobos".rept021
			(r21_usr_tr_fa)
		in idxdbs;

	alter table "fobos".rept021
		add constraint
			(foreign key (r21_usr_tr_fa)
				references "fobos".gent005
				constraint "fobos".fk_11_rept021);

--commit work;
