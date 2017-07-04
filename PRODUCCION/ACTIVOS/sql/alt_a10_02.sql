begin work;

	alter table "fobos".actt010
		drop constraint "fobos".c308_2332;	-- gm
		--drop constraint "fobos".c304_2265;	-- qm

	create index "fobos".i12_fk_actt006
		on "fobos".actt010
			(a10_compania, a10_estado)
		in idxdbs;

	alter table "fobos".actt010
		add constraint
			(foreign key (a10_compania, a10_estado)
				references "fobos".actt006
				constraint "fobos".fk_12_actt010);

commit work;
