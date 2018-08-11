begin work;

alter table "fobos".rept010
	modify (r10_cod_util char(5) default "RE000" not null);

commit work;
