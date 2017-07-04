begin work;

drop index "fobos".i01_pk_cajt001;
drop index "fobos".i02_fk_cajt001;

alter table "fobos".cajt001 drop constraint "fobos".pk_cajt001;
alter table "fobos".cajt001 drop constraint "fobos".fk_02_cajt001;

delete from cajt001
	where j01_cont_cred = 'C';

alter table "fobos".cajt001 drop j01_cont_cred;
alter table "fobos".cajt001 drop j01_retencion;

alter table "fobos".cajt001
	add (j01_cont_cred char(1) before j01_nombre);
alter table "fobos".cajt001
	add (j01_retencion char(1) before j01_usuario);

select * from cajt001
	where j01_codigo_pago in ('EF', 'CH', 'RT', 'RJ', 'RI', 'TJ')
	into temp t1;

update t1
	set j01_cont_cred = 'C',
	    j01_fecing    = current
	where 1 = 1;

update cajt001
	set j01_cont_cred = 'R'
	where 1 = 1;

insert into cajt001
        select * from t1
                where not exists
                        (select 1 from t1 a, cajt001 b
                                where a.j01_compania    = b.j01_compania
                                  and a.j01_codigo_pago = b.j01_codigo_pago
                                  and a.j01_cont_cred   = b.j01_cont_cred);

drop table t1;

update cajt001
	set j01_retencion = 'N'
	where 1 = 1;

update cajt001
	set j01_retencion = 'S'
	where j01_codigo_pago like 'R%';

alter table "fobos".cajt001
	modify (j01_cont_cred char(1) not null);
alter table "fobos".cajt001
	modify (j01_retencion char(1) not null);

create unique index "fobos".i01_pk_cajt001
	on "fobos".cajt001
		(j01_compania, j01_codigo_pago, j01_cont_cred)
	in idxdbs;

create index "fobos".i02_fk_cajt001
	on "fobos".cajt001
		(j01_compania, j01_aux_cont)
	in idxdbs;

alter table "fobos".cajt001
	add constraint
		primary key (j01_compania, j01_codigo_pago, j01_cont_cred)
			constraint "fobos".pk_cajt001;

alter table "fobos".cajt001
	add constraint
		check (j01_cont_cred in ("C", "R"))
			constraint "fobos".ck_01_cajt001;
alter table "fobos".cajt001
	add constraint
		check (j01_retencion in ("S", "N"))
			constraint "fobos".ck_02_cajt001;

alter table "fobos".cajt001
	add constraint
		(foreign key (j01_compania, j01_aux_cont)
			references "fobos".ctbt010
			constraint "fobos".fk_02_cajt001);

commit work;
