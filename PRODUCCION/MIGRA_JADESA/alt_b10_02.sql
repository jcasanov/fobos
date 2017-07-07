begin work;

	--alter table "fobos".ctbt010 drop b10_permite_mov;

	alter table "fobos".ctbt010
		add (b10_permite_mov	char(1)
				before b10_usuario);

	update "fobos".ctbt010
		set b10_permite_mov = "N"
		where 1 = 1;

	alter table "fobos".ctbt010
		modify (b10_permite_mov	char(1)		not null);

	alter table "fobos".ctbt010
    	add constraint
			check (b10_permite_mov in ('S', 'N'))
			constraint "fobos".ck_05_ctbt010;

--rollback work;
commit work;
