begin work;

alter table "fobos".actt001
	add (a01_paga_iva	char(1)		before a01_usuario);

update actt001
	set a01_paga_iva = 'S'
	where a01_grupo_act <> 4;

update actt001
	set a01_paga_iva = 'N'
	where a01_grupo_act = 4;

alter table "fobos".actt001
	modify (a01_paga_iva	char(1)		not null);

alter table "fobos".actt001
	add constraint
		check (a01_paga_iva in ('S', 'N'))
			constraint "fobos".ck_02_actt001;

commit work;
