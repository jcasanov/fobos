begin work;

	--alter table "fobos".ctbt010 drop b10_cuenta_padre;

	alter table "fobos".ctbt010
		add (b10_cuenta_padre	char(12)
				before b10_usuario);

	create index "fobos".i05_fk_ctbt010
		on "fobos".ctbt010
			(b10_compania, b10_cuenta_padre)
		in idxdbs;

	alter table "fobos".ctbt010
    	add constraint
			(foreign key
				(b10_compania, b10_cuenta_padre)
			 references "fobos".ctbt010
			 constraint "fobos".fk_05_ctbt010);

--rollback work;
commit work;
