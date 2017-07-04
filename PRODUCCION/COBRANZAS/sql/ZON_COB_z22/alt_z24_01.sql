begin work;

	alter table "fobos".cxct024
		add (z24_zona_cobro 	smallint	before z24_subtipo);

	create index "fobos".i07_fk_cxct024
		on "fobos".cxct024
			(z24_zona_cobro)
		in idxdbs;

	alter table "fobos".cxct024
		add constraint
			(foreign key (z24_zona_cobro)
			 references "fobos".cxct006
			 constraint "fobos".fk_07_cxct024);

commit work;
