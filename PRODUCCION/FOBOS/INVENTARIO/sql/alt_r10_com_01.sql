begin work;

	alter table "fobos".rept010
		modify (r10_cod_comerc	char(60));

commit work;
