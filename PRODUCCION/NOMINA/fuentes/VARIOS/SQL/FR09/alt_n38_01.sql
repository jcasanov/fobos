begin work;

	alter table "fobos".rolt038
		add (n38_pago_iess	char(1)		before n38_usuario);


	update rolt038
		set n38_pago_iess = 'S'
		where 1 = 1;

	alter table "fobos".rolt038
		modify (n38_pago_iess	char(1)		not null);

	alter table "fobos".rolt038
		add constraint check (n38_pago_iess	in ("S", "N"))
			constraint "fobos".ck_02_rolt038;

commit work;
