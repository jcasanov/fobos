
create table "fobos".logt100 
  (
    l100_compania integer not null ,
    l100_tipo_comp char(2) not null ,
    l100_num_comp char(8) not null ,
    l100_secuencia smallint not null,
    l100_estado char(1) not null ,
    l100_subtipo smallint,
    l100_glosa varchar(130,60) not null ,
    l100_benef_che varchar(25),
    l100_num_cheque integer,
    l100_origen char(1) not null ,
    l100_moneda char(2) not null ,
    l100_paridad decimal(16,9) not null ,
    l100_fec_proceso date not null ,
    l100_fec_reversa date,
    l100_tip_reversa char(2),
    l100_num_reversa char(8),
    l100_fec_modifi datetime year to second,
    l100_modulo char(2),
    l100_usuario varchar(10,5) not null ,
    l100_fecing datetime year to second not null ,
    
    check (l100_estado IN ('A' ,'M' ,'E' )),
    
    check (l100_origen IN ('A' ,'M' ))
  );
revoke all on "fobos".logt100 from "public";

create unique index "fobos".i01_pk_logt101 on "fobos".logt101 
    (b12_compania,b12_tipo_comp,b12_num_comp);
    
alter table "fobos".ctbt012 add constraint primary key (b12_compania,
    b12_tipo_comp,b12_num_comp) constraint "fobos".pk_ctbt012 
     ;

alter table "fobos".ctbt012 add constraint (foreign key (b12_compania,
    b12_tip_reversa,b12_num_reversa) references "fobos".ctbt012 
    );

alter table "fobos".ctbt012 add constraint (foreign key (b12_compania,
    b12_tipo_comp) references "fobos".ctbt003 );

alter table "fobos".ctbt012 add constraint (foreign key (b12_compania,
    b12_subtipo) references "fobos".ctbt004 );

alter table "fobos".ctbt012 add constraint (foreign key (b12_moneda) 
    references "fobos".gent013 );

alter table "fobos".ctbt012 add constraint (foreign key (b12_usuario) 
    references "fobos".gent005 );





create table "fobos".ctbt013 
  (
    b13_compania integer not null ,
    b13_tipo_comp char(2) not null ,
    b13_num_comp char(8) not null ,
    b13_secuencia smallint not null ,
    b13_cuenta char(12) not null ,
    b13_tipo_doc char(3),
    b13_glosa varchar(35),
    b13_valor_base decimal(14,2) not null ,
    b13_valor_aux decimal(14,2) not null ,
    b13_num_concil integer,
    b13_filtro integer,
    b13_fec_proceso date not null ,
    b13_codcli integer,
    b13_codprov integer,
    b13_pedido char(10)
  );
revoke all on "fobos".ctbt013 from "public";

create unique index "fobos".i01_pk_ctbt013 on "fobos".ctbt013 
    (b13_compania,b13_tipo_comp,b13_num_comp,b13_secuencia);
create index "fobos".i01_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_tipo_comp,b13_num_comp);
create index "fobos".i02_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_cuenta);
create index "fobos".i03_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_num_concil);
create index "fobos".i04_fk_ctbt013 on "fobos".ctbt013 (b13_compania,
    b13_filtro);
alter table "fobos".ctbt013 add constraint primary key (b13_compania,
    b13_tipo_comp,b13_num_comp,b13_secuencia) constraint "fobos"
    .pk_ctbt013  ;

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_cuenta) references "fobos".ctbt010 );

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_tipo_comp,b13_num_comp) references "fobos".ctbt012 );

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_num_concil) references "fobos".ctbt030 );

alter table "fobos".ctbt013 add constraint (foreign key (b13_compania,
    b13_filtro) references "fobos".ctbt008 );




