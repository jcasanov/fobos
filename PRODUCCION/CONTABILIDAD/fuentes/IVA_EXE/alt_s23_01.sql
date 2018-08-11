begin work;


--------------------------------------------------------------------------------
drop index "fobos".i01_pk_srit023;

alter table "fobos".srit023 drop constraint "fobos".pk_srit023;

rename column "fobos".srit023.s23_sustento_tri to s23_sustento_sri;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".srit023 add (s23_fecing datetime year to second);

alter table "fobos".srit023 add (s23_secuencia integer before s23_fecing);

alter table "fobos".srit023 add (s23_usuario varchar(10,5) before s23_fecing);

alter table "fobos".srit023 add (s23_aux_cont char(12) before s23_usuario);

update srit023
	set s23_secuencia = 1,
	    s23_usuario   = 'FOBOS',
	    s23_fecing    = current
	where 1 = 1;

alter table "fobos".srit023
	modify (s23_secuencia integer not null);

alter table "fobos".srit023
	modify (s23_usuario varchar(10,5) not null);

alter table "fobos".srit023
	modify (s23_fecing datetime year to second not null);
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".srit023 add (s23_tributa char(1) before s23_usuario);

update srit023 set s23_tributa = 'S' where 1 = 1;

alter table "fobos".srit023 modify (s23_tributa char(1) not null);

alter table "fobos".srit023
	add constraint
		check (s23_tributa in ('S', 'N'))
			constraint "fobos".ck_01_srit023;

update srit023
	set s23_tributa = 'N'
	where s23_sustento_sri in ('00', '02', '04', '07');
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
create unique index "fobos".i01_pk_srit023 on "fobos".srit023
	(s23_compania, s23_tipo_orden, s23_sustento_sri, s23_secuencia)
	in idxdbs;

create index "fobos".i03_fk_srit023 on "fobos".srit023
	(s23_compania, s23_aux_cont) in idxdbs;

create index "fobos".i04_fk_srit023 on "fobos".srit023 (s23_usuario) in idxdbs;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
alter table "fobos".srit023
	add constraint
		primary key (s23_compania, s23_tipo_orden, s23_sustento_sri,
				s23_secuencia)
			constraint "fobos".pk_srit023;

alter table "fobos".srit023
	add constraint
		(foreign key (s23_compania, s23_aux_cont)
			references "fobos".ctbt010
			constraint "fobos".fk_03_srit023);

alter table "fobos".srit023
	add constraint
		(foreign key (s23_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_srit023);
--------------------------------------------------------------------------------


commit work;
