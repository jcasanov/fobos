begin work;

	alter table "fobos".gent001
		add (g01_tip_docid_rep		char(1)			before g01_principal);

	alter table "fobos".gent001
		add (g01_tip_docid_con		char(1)			before g01_principal);

	alter table "fobos".gent001
		add (g01_num_docid_con		char(15)		before g01_principal);

	alter table "fobos".gent001
		add (g01_nomcontador		varchar(40,30)	before g01_principal);

	update gent001
		set g01_tip_docid_rep = 'C',
			g01_tip_docid_con = 'R',
			g01_num_docid_con = '0802232132001',
		    g01_nomcontador   = 'CINDY BAIDAL'
		where 1 = 1;

	alter table "fobos".gent001
		modify (g01_tip_docid_rep		char(1)			not null);

	alter table "fobos".gent001
		modify (g01_tip_docid_con		char(1)			not null);

	alter table "fobos".gent001
		add constraint
			check (g01_tip_docid_rep in ('C', 'R', 'P'))
				constraint "fobos".ck_03_gent001;

	alter table "fobos".gent001
		add constraint
			check (g01_tip_docid_con in ('C', 'R', 'P', 'N'))
				constraint "fobos".ck_04_gent001;

--rollback work;
commit work;
