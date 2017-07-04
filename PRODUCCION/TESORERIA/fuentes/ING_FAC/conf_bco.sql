begin work;

alter table "fobos".gent008 modify (g08_banco integer not null);
alter table "fobos".gent008
	add constraint
		primary key (g08_banco)
			constraint pk_gent008;

alter table "fobos".gent009
	add constraint
		(foreign key (g09_banco)
			references "fobos".gent008
			constraint "fobos".fk_02_gent009);

alter table "fobos".cxct026
	add constraint
		(foreign key (z26_banco)
			references "fobos".gent008
			constraint "fobos".fk_03_cxct026);

alter table "fobos".cajt010
	add constraint
		(foreign key (j10_banco)
			references "fobos".gent008
			constraint "fobos".fk_07_cajt010);

alter table "fobos".rolt060
	add constraint
		(foreign key (n60_banco)
			references "fobos".gent008
			constraint "fobos".fk_02_rolt060);

alter table "fobos".rolt068
	add constraint
		(foreign key (n68_banco)
			references "fobos".gent008
			constraint "fobos".fk_06_rolt068);

alter table "fobos".rolt069
	add constraint
		(foreign key (n69_banco)
			references "fobos".gent008
			constraint "fobos".fk_02_rolt069);

alter table "fobos".rolt039
	add constraint
		(foreign key (n39_bco_empresa)
			references "fobos".gent008
			constraint "fobos".fk_06_rolt039);

alter table "fobos".rolt045
	add constraint
		(foreign key (n45_bco_empresa)
			references "fobos".gent008
			constraint "fobos".fk_05_rolt045);

alter table "fobos".rolt091
	add constraint
		(foreign key (n91_bco_empresa)
			references "fobos".gent008
			constraint "fobos".fk_04_rolt091);

insert into gent008 values (0, 'PAGO EFECTIVO', 'FOBOS', current);

commit work;
