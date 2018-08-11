--
alter table "fobos".tr_cxct002 drop constraint "fobos".ck_03_tr_cxct002;

alter table "fobos".tr_cxct002 drop z02_contr_espe;
alter table "fobos".tr_cxct002 drop z02_oblig_cont;
alter table "fobos".tr_cxct002 drop z02_email;
--

begin work;

	alter table "fobos".tr_cxct002
		add (z02_contr_espe	char(5)		before z02_usuario);

	alter table "fobos".tr_cxct002
		add (z02_oblig_cont	char(2)		before z02_usuario);

	alter table "fobos".tr_cxct002
		add (z02_email		varchar(100)	before z02_usuario);

	alter table "fobos".tr_cxct002
		add constraint
			check (z02_oblig_cont in ("SI", "NO", NULL))
			constraint "fobos".ck_03_tr_cxct002;

--rollback work;
commit work;
