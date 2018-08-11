--
alter table "fobos".cxpt002 drop constraint "fobos".fk_09_cxpt002;
alter table "fobos".cxpt002 drop constraint "fobos".ck_02_cxpt002;

drop index "fobos".i09_fk_cxpt002;
drop index "fobos".i10_fk_cxpt002;

alter table "fobos".cxpt002 drop p02_banco_prov;
alter table "fobos".cxpt002 drop p02_cod_bco_tra;
alter table "fobos".cxpt002 drop p02_tip_cta_prov;
alter table "fobos".cxpt002 drop p02_cta_prov;
alter table "fobos".cxpt002 drop p02_email;
--

begin work;

	alter table "fobos".cxpt002
		add (p02_banco_prov	integer		before p02_usuario);

	alter table "fobos".cxpt002
		add (p02_cod_bco_tra	char(2)		before p02_usuario);

	alter table "fobos".cxpt002
		add (p02_tip_cta_prov	char(1)		before p02_usuario);

	alter table "fobos".cxpt002
		add (p02_cta_prov	char(15)	before p02_usuario);

	alter table "fobos".cxpt002
		add (p02_email		varchar(100)	before p02_usuario);

	create index "fobos".i09_fk_cxpt002
		on "fobos".cxpt002
			(p02_banco_prov)
		in idxdbs;

	create index "fobos".i10_fk_cxpt002
		on "fobos".cxpt002
			(p02_compania, p02_cod_bco_tra, p02_banco_prov)
		in idxdbs;

	alter table "fobos".cxpt002
		add constraint
			(foreign key (p02_banco_prov)
				references "fobos".gent008
				constraint "fobos".fk_09_cxpt002);

	alter table "fobos".cxpt002
		add constraint
			(foreign key (p02_compania, p02_cod_bco_tra,
					p02_banco_prov)
				references "fobos".cxpt006
				constraint "fobos".fk_10_cxpt002);

	alter table "fobos".cxpt002
		add constraint
			check (p02_tip_cta_prov in ("A", "C", NULL))
			constraint "fobos".ck_02_cxpt002;

--rollback work;
commit work;
