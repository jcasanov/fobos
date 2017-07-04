begin work;

--create unique index "fobos".i01_pk_cajt001 on "fobos".cajt001
--	(j01_compania, j01_codigo_pago) in idxdbs;

alter table "fobos".cajt001
	add constraint
		primary key (j01_compania, j01_codigo_pago)
			constraint "fobos".pk_cajt001;

commit work;
