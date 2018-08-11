begin work;

	drop table "fobos".srit026;

	create table "fobos".srit026

		(

			s26_compania			integer			not null,
			s26_cod_for_pago		char(2)			not null,
			s26_forma_de_pago		varchar(150,50)	not null,
			s26_fecha_ini			date			not null,
			s26_fecha_fin			date,
			s26_usuario				varchar(10,5)	not null,
			s26_fecing				datetime year to second	not null

		) in datadbs lock mode row;

	revoke all on "fobos".srit026 from "public";

	create unique index "fobos".i01_pk_srit026
		on "fobos".srit026
			(s26_compania, s26_cod_for_pago)
		in idxdbs;

	create index "fobos".i01_fk_srit026
		on "fobos".srit026
			(s26_compania)
		in idxdbs;

	create index "fobos".i02_fk_srit026
		on "fobos".srit026
			(s26_usuario)
		in idxdbs;

	alter table "fobos".srit026
		add constraint
				primary key (s26_compania, s26_cod_for_pago)
					constraint "fobos".pk_srit026;

	alter table "fobos".srit026
		add constraint
				(foreign key (s26_compania)
					references "fobos".srit000
					constraint "fobos".fk_01_srit026);

	alter table "fobos".srit026
		add constraint
				(foreign key (s26_usuario)
					references "fobos".gent005
					constraint "fobos".fk_02_srit026);

	load from "srit026_sri.unl" delimiter "|"
		insert into srit026;

--rollback work;
commit work;
