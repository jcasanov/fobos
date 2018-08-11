begin work;

	create index "fobos".i06_fk_ctbt013
		on "fobos".ctbt013
			(b13_compania, b13_cuenta, b13_codprov)
		in idxdbs;

commit work;
