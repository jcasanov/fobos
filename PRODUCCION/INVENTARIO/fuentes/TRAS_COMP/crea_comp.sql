begin work;


--------------------------------------------------------------------------------
drop index "fobos".i02_fk_rept045;
drop index "fobos".i01_pk_rept045;
alter table "fobos".rept045 drop constraint "fobos".fk_02_rept045;
alter table "fobos".rept045 drop constraint "fobos".pk_rept045;

drop index "fobos".i01_fk_rept044;
drop index "fobos".i01_pk_rept044;
alter table "fobos".rept044 drop constraint "fobos".fk_01_rept044;
alter table "fobos".rept044 drop constraint "fobos".pk_rept044;

drop index "fobos".i01_pk_rept043;
alter table "fobos".rept043 drop constraint "fobos".pk_rept043;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".rept043
	add (r43_cod_tras	char(2)		before r43_traspaso);

update rept043
	set r43_cod_tras = 'TI'
	where 1 = 1;

alter table "fobos".rept043
	modify (r43_cod_tras	char(2)		not null);

create unique index "fobos".i01_pk_rept043
	on "fobos".rept043
		(r43_compania, r43_localidad, r43_cod_tras, r43_traspaso)
	in idxdbs;

alter table "fobos".rept043
	add constraint
		primary key (r43_compania, r43_localidad, r43_cod_tras,
				r43_traspaso)
			constraint "fobos".pk_rept043;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".rept044
	add (r44_cod_tras	char(2)		before r44_traspaso);

update rept044
	set r44_cod_tras = 'TI'
	where 1 = 1;

alter table "fobos".rept044
	modify (r44_cod_tras	char(2)		not null);

create unique index "fobos".i01_pk_rept044
	on "fobos".rept044
		(r44_compania, r44_localidad, r44_cod_tras, r44_traspaso,
		 r44_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_localidad, r44_cod_tras, r44_traspaso)
	in idxdbs;

alter table "fobos".rept044
	add constraint
		primary key (r44_compania, r44_localidad, r44_cod_tras,
				r44_traspaso, r44_secuencia)
			constraint "fobos".pk_rept044;

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_localidad, r44_cod_tras,
				r44_traspaso)
			references "fobos".rept043
			constraint "fobos".fk_01_rept044);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".rept045
	add (r45_cod_tras	char(2)		before r45_traspaso);

update rept045
	set r45_cod_tras = 'TI'
	where 1 = 1;

alter table "fobos".rept045
	modify (r45_cod_tras	char(2)		not null);

create unique index "fobos".i01_pk_rept045
	on "fobos".rept045
		(r45_compania, r45_localidad, r45_cod_tras, r45_traspaso,
		 r45_cod_tran, r45_num_tran)
	in idxdbs;

create index "fobos".i02_fk_rept045
	on "fobos".rept045
		(r45_compania, r45_localidad, r45_cod_tras, r45_traspaso)
	in idxdbs;

alter table "fobos".rept045
	add constraint
		primary key (r45_compania, r45_localidad, r45_cod_tras,
				r45_traspaso, r45_cod_tran, r45_num_tran)
			constraint "fobos".pk_rept045;

alter table "fobos".rept045
	add constraint
		(foreign key (r45_compania, r45_localidad, r45_cod_tras,
				r45_traspaso)
			references "fobos".rept043
			constraint "fobos".fk_02_rept045);
--------------------------------------------------------------------------------


commit work;
