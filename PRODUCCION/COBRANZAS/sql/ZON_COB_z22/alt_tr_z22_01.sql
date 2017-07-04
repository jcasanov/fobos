begin work;

	alter table "fobos".tr_cxct022
                add (z22_zona_cobro     smallint        before z22_subtipo);

        create index "fobos".i08_fk_tr_cxct022
                on "fobos".tr_cxct022
                        (z22_zona_cobro)
                in idxdbs;

        alter table "fobos".tr_cxct022
                add constraint
                        (foreign key (z22_zona_cobro)
                         references "fobos".cxct006
                         constraint "fobos".fk_08_tr_cxct022);
commit work;
