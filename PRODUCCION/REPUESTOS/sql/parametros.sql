create table "fobos".rept105 (
	r105_compania		integer					not null,	
	r105_codigo			char(3)					not null,
	r105_descripcion	varchar(30,10)			not null,
    r105_usuario 		varchar(10,5) 			not null ,
    r105_fecing 		datetime year to second not null 
);
revoke all on "fobos".rept105 from "public";

create unique index "fobos".i01_pk_rept105 
	on "fobos".rept105 (r105_compania, r105_codigo);
alter table "fobos".rept105 
	add constraint primary key (r105_compania, r105_codigo)
    constraint "fobos".pk_rept105  ;

create index "fobos".i01_fk_rept105 on "fobos".rept105 (r105_compania);
alter table "fobos".rept105 add constraint (foreign key (r105_compania) 
    references "fobos".rept000 );

create index "fobos".i02_fk_rept105 on "fobos".rept105 (r105_usuario);
alter table "fobos".rept105 add constraint (foreign key (r105_usuario) 
    references "fobos".gent005 );

insert into rept105 values (1, 'LT',  'Lead Time', 'FOBOS', current);
insert into rept105 values (1, 'PR',  'Punto de reorden', 'FOBOS', current);
insert into rept105 values (1, 'EOQ', 'Economic Order Quantity', 'FOBOS', current);

{ --- }

create table "fobos".rept106 (
	r106_compania		integer					not null,	
    r106_item 			char(15) 				not null,
	r106_parametro		char(3)					not null,
	r106_fecha_ini		date					not null,
	r106_secuencia		integer					not null,
	r106_valor			decimal(5,2)			not null,
	r106_origen			char(1)					not null,
    r106_usuario 		varchar(10,5) 			not null,
    r106_fecha_fin	 	date					        ,
	check (r106_origen in ('A', 'M'))
);
revoke all on "fobos".rept106 from "public";

create unique index "fobos".i01_pk_rept106 
	on "fobos".rept106 (r106_compania, r106_item, r106_parametro, r106_fecha_ini, 
                        r106_secuencia);
alter table "fobos".rept106 
	add constraint primary key (r106_compania, r106_item, r106_parametro, 
                        		r106_fecha_ini, r106_secuencia)
    constraint "fobos".pk_rept106  ;

create index "fobos".i01_fk_rept106 on "fobos".rept106 (r106_compania, r106_item);
alter table "fobos".rept106 add constraint (foreign key (r106_compania, r106_item) 
    references "fobos".rept010 );


create index "fobos".i02_fk_rept106 on "fobos".rept106 (r106_compania, r106_parametro);
alter table "fobos".rept106 add constraint (foreign key (r106_compania, r106_parametro) 
    references "fobos".rept105 );

create index "fobos".i03_fk_rept106 on "fobos".rept106 (r106_usuario);
alter table "fobos".rept106 add constraint (foreign key (r106_usuario) 
    references "fobos".gent005 );
