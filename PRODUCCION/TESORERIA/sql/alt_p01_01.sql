begin work;

	alter table "fobos".cxpt001
		modify (p01_telefono1	char(11)	 not null);

	alter table "fobos".cxpt001
		modify (p01_telefono2	char(11));

commit work;
