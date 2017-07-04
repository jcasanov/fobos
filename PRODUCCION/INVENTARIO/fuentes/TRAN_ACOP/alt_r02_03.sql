begin work;

	create index "fobos".i03_fk_rept002
		on "fobos".rept002
			(r02_compania, r02_tipo_ident)
		in idxdbs;

	alter table "fobos".rept002
		add constraint
			(foreign key
				(r02_compania, r02_tipo_ident)
				references "fobos".rept009
				constraint "fobos".fk_03_rept002);

commit work;
