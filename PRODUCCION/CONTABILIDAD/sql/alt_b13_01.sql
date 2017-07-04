begin work;

	create index "fobos".i05_fk_ctbt013
		on "fobos".ctbt013
			(b13_codprov)
		in idxdbs;

commit work;
