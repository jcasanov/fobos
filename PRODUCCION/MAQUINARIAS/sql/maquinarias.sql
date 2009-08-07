-- Modulo Maquinarias

begin work;

drop table maqt012;
drop table maqt011;
drop table maqt010;
drop table maqt005;
drop table maqt004;
drop table maqt003;
drop table maqt002;
drop table maqt001;
drop table maqt000;
drop table mailt001;


-- maqt000	** Configuración modulo

create table "fobos".maqt000 (
	m00_compania		integer		not null,
	m00_dias_revi_ini 	smallint	not null,
	check (m00_dias_revi_ini > 0)
) lock mode row;	
revoke all on "fobos".maqt000 from "public";

create unique index "fobos".pk_maqt000 on maqt000(m00_compania) in idxdbs;

alter table "fobos".maqt000 add constraint primary key (m00_compania);
alter table "fobos".maqt000 add constraint ( 
	foreign key (m00_compania) references "fobos".maqt000);

INSERT into maqt000 values (1, 30);


-- maqt001	** Provincias

create table "fobos".maqt001 (
	m01_provincia	smallint		not null,
	m01_nombre	varchar(20,10)		not null 
) lock mode row;	
revoke all on "fobos".maqt001 from "public";

create unique index "fobos".pk_maqt001 on "fobos".maqt001(m01_provincia) 
in idxdbs;

alter table "fobos".maqt001 add constraint primary key (m01_provincia);


-- maqt002	** Cantones

create table "fobos".maqt002 (
	m02_provincia	smallint		not null,
	m02_canton	smallint		not null,
	m02_nombre	varchar(20,10)		not null 
) lock mode row;	
revoke all on "fobos".maqt002 from "public";

create unique index "fobos".pk_maqt002 on "fobos".maqt002(m02_provincia, m02_canton) in idxdbs;
create index "fobos".i01_fk_maqt002    on "fobos".maqt002(m02_provincia)             in idxdbs;

alter table "fobos".maqt002 add constraint primary key (m02_provincia, m02_canton);
alter table "fobos".maqt002 add constraint ( 
	foreign key (m02_provincia) references "fobos".maqt001
);


-- maqt003	** Zonas

create table "fobos".maqt003 (
	m03_compania	integer			not null,
	m03_zona	smallint		not null,
	m03_nombre	varchar(20,10)		not null,
	m03_atendido	varchar(30,15)		not null
) lock mode row;	
revoke all on "fobos".maqt003 from "public";

create unique index "fobos".pk_maqt003     on "fobos".maqt003(m03_compania, m03_zona) in idxdbs;
create        index "fobos".i01_fk_maqt003 on "fobos".maqt003(m03_compania)           in idxdbs;

alter table "fobos".maqt003 add constraint primary key (m03_compania, m03_zona);
alter table "fobos".maqt003 add constraint ( 
	foreign key (m03_compania) references "fobos".maqt000);

insert into "fobos".maqt003 values (1, 1, 'Zona 1', 'Matriz Guayaquil');
insert into "fobos".maqt003 values (1, 2, 'Zona 2', 'Sucursal Quito');
insert into "fobos".maqt003 values (1, 3, 'Zona 3', 'Puesto Loja');


-- maqt004  	** Cantones x Zonas

create table "fobos".maqt004 (
	m04_compania	integer			not null,
	m04_zona	smallint		not null,
	m04_provincia	smallint      		not null,
	m04_canton	smallint      		not null
) lock mode row;	
revoke all on "fobos".maqt004 from "public";

create unique index "fobos".pk_maqt004 on 
	"fobos".maqt004(m04_compania,  m04_zona,
		   	m04_provincia, m04_canton
) in idxdbs;
create  index "fobos".i01_fk_maqt004 on "fobos".maqt004(m04_compania, m04_zona) 
in idxdbs;
create  index "fobos".i02_fk_maqt004 on "fobos".maqt004(m04_provincia, m04_canton) in idxdbs;

alter table "fobos".maqt004 add constraint primary key (m04_compania, m04_zona,
				     m04_provincia, m04_canton
);
alter table "fobos".maqt004 add constraint ( 
	foreign key (m04_compania, m04_zona) references "fobos".maqt003);
alter table "fobos".maqt004 add constraint (
	foreign key (m04_provincia, m04_canton) references "fobos".maqt002);


-- maqt005	** Lineas (Marcas)

create table "fobos".maqt005 
  (
    m05_compania 	integer 		not null ,
    m05_linea 		char(5) 		not null ,
    m05_nombre 		varchar(20,10) 		not null ,
    m05_estado 		char(1) 		not null ,
    m05_usuario 	varchar(10,5) 		not null ,
    m05_fecing 		datetime year to second not null ,
    
    check (m05_estado IN ('A' ,'B' ))
  ) lock mode row;
revoke all on "fobos".maqt005 from "public";

create unique index "fobos".pk_maqt005 on "fobos".maqt005 
    (m05_compania, m05_linea) in idxdbs ;
create index "fobos".i01_fk_maqt005 on "fobos".maqt005 (m05_compania) 
    in idxdbs ;
create index "fobos".i02_fk_maqt005 on "fobos".maqt005 (m05_usuario) 
    in idxdbs ;

alter table "fobos".maqt005 add constraint primary key (m05_compania,
    m05_linea) ;
alter table "fobos".maqt005 add constraint (foreign key (m05_compania) 
    references "fobos".maqt000 );
alter table "fobos".maqt005 add constraint (foreign key (m05_usuario) 
    references "fobos".gent005 );


INSERT INTO maqt005 VALUES (1, 'KOMAT', 'KOMATSU', 'A', 'FOBOS', 
                            '2004-11-18 10:00:00');

-- maqt010	** Modelos

create table "fobos".maqt010 
  (
    m10_compania 	integer 		not null ,
    m10_modelo 		char(15) 		not null ,
    m10_linea 		char(5) 		not null ,
    m10_descripcion 	varchar(30,15) 		not null ,
    m10_usuario 	varchar(10,5) 		not null ,
    m10_fecing 		datetime year to second not null  
) lock mode row;
revoke all on "fobos".maqt010 from "public";

create unique index "fobos".pk_maqt010 on "fobos".maqt010 
    (m10_compania,m10_modelo) in idxdbs ;
create index "fobos".i01_fk_maqt010 on "fobos".maqt010 (m10_compania) 
    in idxdbs ;
create index "fobos".i02_fk_maqt010 on "fobos".maqt010 (m10_compania,
    m10_linea) in idxdbs ;
create index "fobos".i03_fk_maqt010 on "fobos".maqt010 (m10_usuario) 
    in idxdbs ;
alter table "fobos".maqt010 add constraint primary key (m10_compania,
    m10_modelo) ;
alter table "fobos".maqt010 add constraint (foreign key (m10_compania) 
    references "fobos".maqt000 );
alter table "fobos".maqt010 add constraint (foreign key (m10_compania,
    m10_linea) references "fobos".maqt005 );
alter table "fobos".maqt010 add constraint (foreign key (m10_usuario) 
    references "fobos".gent005 );


-- maqt011	** Modelos x Clientes

create table "fobos".maqt011 
  (
    	m11_compania 		integer 		not null,
    	m11_modelo 		char(15) 		not null,
	m11_secuencia		smallint		not null,
	m11_codcli		integer			not null,
        m11_serie 		char(25) 		not null,
    	m11_nuevo 		char(1)	 		not null,
    	m11_comentarios 	varchar(120,60) 	        ,
    	m11_estado 		char(1) 		not null,
    	m11_motor 		char(16),
    	m11_ano 		smallint 		not null,
    	m11_fecha_ent 		date                   	        ,
    	m11_provincia 		smallint		not null,
    	m11_canton 		smallint		not null,
	m11_ubicacion		varchar(60,30),
	m11_fecha_sgte_rev	date			        ,
	m11_garantia_meses	smallint		not null,
	m11_garantia_horas	smallint		not null,
    
    check (m11_nuevo IN ('S' ,'N' )),
    check (m11_estado IN ('A' ,'B' ,'P' ))
  );
revoke all on "fobos".maqt011 from "public";

create unique index "fobos".pk_maqt011 on "fobos".maqt011 
    (m11_compania,m11_modelo, m11_secuencia) in idxdbs;
create index "fobos".i01_fk_maqt011 on "fobos".maqt011 (m11_compania) 
    in idxdbs ;
create index "fobos".i02_fk_maqt011 on "fobos".maqt011 (m11_codcli) 
    in idxdbs ;
create index "fobos".i03_fk_maqt011 on "fobos".maqt011 (m11_compania,
    m11_modelo) in idxdbs;
create index "fobos".i04_fk_maqt011 on "fobos".maqt011 
	(m11_provincia, m11_canton) in idxdbs ;

alter table "fobos".maqt011 add constraint primary key (m11_compania,
    m11_modelo, m11_secuencia) ;
alter table "fobos".maqt011 add constraint (foreign key (m11_compania) 
    references "fobos".maqt000 );
alter table "fobos".maqt011 add constraint (foreign key (m11_codcli) 
    references "fobos".cxct001 );
alter table "fobos".maqt011 add constraint (foreign key (m11_compania, 
 	m11_modelo) references "fobos".maqt010 );
alter table "fobos".maqt011 add constraint (foreign key (m11_provincia, 
 	m11_canton) references "fobos".maqt002 );


-- maqt012	** Bitacora de Horometraje de Modelos x Clientes

create table "fobos".maqt012 
  (
    	m12_compania 		integer 		not null,
	m12_modelo		char(15)		not null,
	m12_secuencia		smallint		not null,
	m12_fecha		date			not null,
	m12_horometro		integer			not null,
    check (m12_horometro >= 0)
) lock mode row;

create unique index "fobos".pk_maqt012 on "fobos".maqt012
    (m12_compania,m12_modelo, m12_secuencia, m12_fecha) in idxdbs;
create        index "fobos".i01_fk_maqt012 on "fobos".maqt012
    (m12_compania,m12_modelo, m12_secuencia) in idxdbs;

alter table "fobos".maqt012 add constraint primary key (m12_compania,
    m12_modelo, m12_secuencia, m12_fecha) ;
alter table "fobos".maqt012 add constraint (foreign key (m12_compania,
	m12_modelo, m12_secuencia) references "fobos".maqt011 );

--- Tabla mailt001
create table mailt001 (
	e01_compania		integer		not null,
	e01_localidad		smallint	not null,
	e01_modulo		char(2)		NOT null,
	e01_mail_admin		varchar(40,20) 	not null
) lock mode row;

create unique index "fobos".pk_mailt001 on "fobos".mailt001
	(e01_compania, e01_localidad, e01_modulo) in idxdbs;

alter table "fobos".mailt001 add constraint primary key (e01_compania,
e01_localidad, e01_modulo);

insert into mailt001 values (1, 1, 'MA', 'omoran@diteca.com');
insert into mailt001 values (1, 1, 'RE', 'jparodi@diteca.com');
insert into mailt001 values (1, 1, 'TA', 'iromero@diteca.com');
insert into mailt001 values (1, 1, 'CG', 'pchonillo@diteca.com');
insert into mailt001 values (1, 1, 'CO', 'pchonillo@diteca.com');
insert into mailt001 values (1, 1, 'TE', 'pchonillo@diteca.com');
insert into mailt001 values (1, 1, 'CB', 'pchonillo@diteca.com');
insert into mailt001 values (1, 1, 'GE', 'systemguards@yahoo.com');

