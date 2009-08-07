create table "fobos".rept103 (
	r103_compania		integer					not null,	
	r103_codigo			integer					not null,
	r103_descripcion	varchar(30,10)			not null,
	r103_valor_unico	char(1)					not null,
    r103_usuario 		varchar(10,5) 			not null ,
    r103_fecing 		datetime year to second not null ,
	check (r103_valor_unico in ('S', 'N'))
);
revoke all on "fobos".rept103 from "public";

create unique index "fobos".i01_pk_rept103 
	on "fobos".rept103 (r103_compania, r103_codigo);
alter table "fobos".rept103 
	add constraint primary key (r103_compania, r103_codigo)
    constraint "fobos".pk_rept103  ;

create index "fobos".i01_fk_rept103 on "fobos".rept103 (r103_compania);
alter table "fobos".rept103 add constraint (foreign key (r103_compania) 
    references "fobos".rept000 );

create index "fobos".i02_fk_rept103 on "fobos".rept103 (r103_usuario);
alter table "fobos".rept103 add constraint (foreign key (r103_usuario) 
    references "fobos".gent005 );

{ --- }

create table "fobos".rept104 (
	r104_compania		integer					not null,	
    r104_item 			char(15) 				not null ,
	r104_clasificador	integer					not null,
	r104_secuencia		integer					not null,
	r104_valor			varchar(35,10)			not null,
    r104_usuario 		varchar(10,5) 			not null ,
    r104_fecing 		datetime year to second not null 
);
revoke all on "fobos".rept104 from "public";

create unique index "fobos".i01_pk_rept104 
	on "fobos".rept104 (r104_compania, r104_item, r104_clasificador, 
                        r104_secuencia);
alter table "fobos".rept104 
	add constraint primary key (r104_compania, r104_item, r104_clasificador, 
                        		r104_secuencia)
    constraint "fobos".pk_rept104  ;

create index "fobos".i01_fk_rept104 on "fobos".rept104 (r104_compania, r104_item);
alter table "fobos".rept104 add constraint (foreign key (r104_compania, r104_item) 
    references "fobos".rept010 );


create index "fobos".i02_fk_rept104 on "fobos".rept104 (r104_compania, r104_clasificador);
alter table "fobos".rept104 add constraint (foreign key (r104_compania, r104_clasificador) 
    references "fobos".rept103 );

create index "fobos".i03_fk_rept104 on "fobos".rept104 (r104_usuario);
alter table "fobos".rept104 add constraint (foreign key (r104_usuario) 
    references "fobos".gent005 );
