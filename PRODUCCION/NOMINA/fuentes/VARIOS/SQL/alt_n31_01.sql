begin work;

	alter table "fobos".rolt031
		add (n31_cod_trab_e	integer		before n31_nombres);

	alter table "fobos".rolt031
		modify (n31_nombres	varchar(45,25)	not null);

commit work;
