CREATE TABLE rept120 (
	r120_compania		INTEGER					NOT NULL, 
	r120_localidad 		SMALLINT				NOT NULL,
	r120_numprev		INTEGER					NOT NULL,
	r120_motivo			VARCHAR(200,100)		NOT NULL,
    r120_usuario 		VARCHAR(10,5) 			NOT NULL,
    r120_fecing 		DATETIME YEAR TO SECOND	NOT NULL 
  ) extent size 16 next size 16 lock mode row;
revoke all on "fobos".rept120 from "public";

create unique index "fobos".i01_pk_rept120 on "fobos".rept120 
    (r120_compania,r120_localidad,r120_numprev) in idxdbs;
    
create index "fobos".i02_fk_rept120 on "fobos".rept120 (r120_usuario) in idxdbs;
    
alter table "fobos".rept120 add constraint primary key (r120_compania,
    r120_localidad, r120_numprev) constraint "fobos".pk_rept120  ;

alter table "fobos".rept120 add constraint (foreign key (r120_compania, r120_localidad, r120_numprev) 
    references "fobos".rept023 );

alter table "fobos".rept120 add constraint (foreign key (r120_usuario) 
    references "fobos".gent005 );
