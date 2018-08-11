begin work;

alter table "fobos".rept085
	add (r85_tipo_carga	char(1)		before r85_referencia);
alter table "fobos".rept085
	add (r85_usu_reversa	varchar(10,5)	before r85_fec_reversa);

update rept085
	set r85_tipo_carga = 'N'
	where 1 = 1;

update rept085
	set r85_tipo_carga = 'P'
	where r85_referencia = 'POR CARGA DE ARCHIVO';

update rept085
	set r85_usu_reversa = r85_usuario
	where r85_estado = 'R';

alter table "fobos".rept085
	modify (r85_tipo_carga	char(1)		not null);

alter table "fobos".rept085
        add constraint
		check (r85_tipo_carga in ('N', 'C', 'P', 'E'))
                	constraint "fobos".ck_02_rept085;

commit work;
