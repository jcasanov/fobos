begin work;

create table "fobos".gent057 
	(
		g57_user		varchar(10,5)		not null,
		g57_compania		integer			not null,
		g57_modulo		char(2)			not null,
		g57_proceso		char(10)		not null,
		g57_usuario		varchar(10,5)		not null,
		g57_fecing		datetime year to second	not null 
	);

create unique index "fobos".i01_pk_gent057 on "fobos".gent057
	(g57_user, g57_compania, g57_modulo, g57_proceso);

create index "fobos".i01_fk_gent057 on "fobos".gent057
	(g57_modulo, g57_proceso);

create index "fobos".i02_fk_gent057 on "fobos".gent057 (g57_compania);
    
create index "fobos".i03_fk_gent057 on "fobos".gent057 (g57_user);
    
create index "fobos".i04_fk_gent057 on "fobos".gent057 (g57_usuario);
    
alter table "fobos".gent057
	add constraint
		primary key (g57_user, g57_compania, g57_modulo, g57_proceso)
			constraint "fobos".pk_gent057;

alter table "fobos".gent057
	add constraint
		(foreign key (g57_modulo, g57_proceso)
			references "fobos".gent054);

alter table "fobos".gent057
	add constraint (foreign key (g57_compania) references "fobos".gent001);

alter table "fobos".gent057
	add constraint (foreign key (g57_user) references "fobos".gent005);

alter table "fobos".gent057
	add constraint (foreign key (g57_usuario) references "fobos".gent005);

alter table "fobos".gent057 lock mode (row);

commit work;
