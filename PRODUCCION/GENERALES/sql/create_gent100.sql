drop table "fobos".gent100;
create table "fobos".gent100 (
	g100_compania			integer			not null,
	g100_banco				integer			not null,
	g100_numero_cta			char(15)		not null,
	g100_cheq_ini			decimal(10,0)	not null,
	g100_cheq_fin			decimal(10,0)	not null,
	g100_cheq_act			decimal(10,0)	not null,
	g100_posy_benef			integer			not null,
	g100_posix_benef		integer			not null,
	g100_posfx_benef		integer			not null,
	g100_posy_valn			integer			not null,
	g100_posix_valn			integer			not null,
	g100_posfx_valn			integer			not null,
	g100_posy_vallt1		integer			not null,
	g100_posix_vallt1		integer			not null,
	g100_posfx_vallt1		integer			not null,
	g100_posy_vallt2		integer			not null,
	g100_posix_vallt2		integer			not null,
	g100_posfx_vallt2		integer			not null,
	g100_posy_ciud			integer			not null,
	g100_posix_ciud			integer			not null,
	g100_posfx_ciud			integer			not null,
	g100_posy_fech			integer			not null,
	g100_posix_fech			integer			not null,
	g100_posfx_fech			integer			not null,

	check(g100_cheq_ini		> 0),
	check(g100_cheq_fin		> 0),
	check(g100_cheq_act		>= 0),
	check(g100_posy_benef	> 0),
	check(g100_posix_benef	> 0),
	check(g100_posfx_benef	> 0),
	check(g100_posy_valn	> 0),
	check(g100_posix_valn	> 0),
	check(g100_posfx_valn	> 0),
	check(g100_posy_vallt1	> 0),
	check(g100_posix_vallt1	> 0),
	check(g100_posfx_vallt1	> 0),
	check(g100_posy_vallt2	> 0),
	check(g100_posix_vallt2	> 0),
	check(g100_posfx_vallt2	> 0),
	check(g100_posy_ciud	> 0),
	check(g100_posix_ciud	> 0),
	check(g100_posfx_ciud	> 0),
	check(g100_posy_fech	> 0),
	check(g100_posix_fech	> 0),
	check(g100_posfx_fech	> 0)
) lock mode row;	
revoke all on "fobos".gent100 from "public";

create unique index "fobos".i01_pk_gent100 on "fobos".gent100 
    (g100_compania,g100_banco,g100_numero_cta) using btree ;
alter table "fobos".gent100 add constraint primary key (g100_compania,
    g100_banco,g100_numero_cta) constraint "fobos".pk_gent100  ;
    
alter table "fobos".gent100 add constraint (foreign key (g100_compania,
	g100_banco,g100_numero_cta) 
    references "fobos".gent009 );
