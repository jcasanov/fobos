begin work;

alter table "fobos".srit000
	add (s00_ano_proceso	integer		before s00_usuario);

alter table "fobos".srit000
	add (s00_mes_proceso	smallint	before s00_usuario);

alter table "fobos".srit000
	add (s00_dias_ane_vta	smallint	before s00_usuario);

alter table "fobos".srit000
	add (s00_dias_ane_com	smallint	before s00_usuario);

alter table "fobos".srit000
	add (s00_dias_ret	smallint	before s00_usuario);

update srit000
	set s00_ano_proceso  = 2009,
	    s00_mes_proceso  = 10,
	    s00_dias_ane_vta = 60,
	    s00_dias_ane_com = 45,
	    s00_dias_ret     = 60
	where 1 = 1;

alter table "fobos".srit000
	modify (s00_ano_proceso		integer		not null);

alter table "fobos".srit000
	modify (s00_mes_proceso		smallint	not null);

alter table "fobos".srit000
	modify (s00_dias_ane_vta	smallint	not null);

alter table "fobos".srit000
	modify (s00_dias_ane_com	smallint	not null);

alter table "fobos".srit000
	modify (s00_dias_ret		smallint	not null);

commit work;
