begin work;

	create index "fobos".i08_fk_cxpt020
		on "fobos".cxpt020
			(p20_codprov)
		in idxdbs;

	create index "fobos".i06_fk_cxpt021
		on "fobos".cxpt021
			(p21_codprov)
		in idxdbs;

commit work;
