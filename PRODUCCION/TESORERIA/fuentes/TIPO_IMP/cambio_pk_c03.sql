begin work;

-------------- ELIMINACION DE INDICES POR FK DE LA TABLA ordt003 ---------------

drop index "fobos".i04_fk_cxpt005;
drop index "fobos".i03_fk_cxpt026;
drop index "fobos".i03_fk_cxpt028;
drop index "fobos".i03_fk_cajt014;
drop index "fobos".i04_fk_cxct008;
drop index "fobos".i05_fk_cxct009;
drop index "fobos".i01_fk_srit025;

--------------------------------------------------------------------------------


-------- ELIMINACION DE INDICES POR PK EN LAS TABLAS HIJAS DE ordt003  ---------

drop index "fobos".i01_pk_cxpt005;
drop index "fobos".i01_pk_cxpt026;
drop index "fobos".i01_pk_cajt014;
drop index "fobos".i01_pk_cxct008;
drop index "fobos".i01_pk_cxct009;
drop index "fobos".i01_pk_srit025;

--------------------------------------------------------------------------------


------------ ELIMINACION DE CONSTRAINTS POR FK DE LA TABLA ordt003 -------------

alter table "fobos".cxpt005 drop constraint "fobos".fk_04_cxpt005;
alter table "fobos".cxpt026 drop constraint "fobos".fk_03_cxpt026;
alter table "fobos".cajt014 drop constraint "fobos".fk_03_cajt014;
alter table "fobos".cxct008 drop constraint "fobos".fk_04_cxct008;
alter table "fobos".cxct009 drop constraint "fobos".fk_05_cxct009;
alter table "fobos".srit025 drop constraint "fobos".fk_01_srit025;

--------------------------------------------------------------------------------


------- ELIMINACION DE CONSTRAINTS POR PK EN LAS TABLAS HIJAS DE ordt003 -------

alter table "fobos".cxpt005 drop constraint "fobos".pk_cxpt005;
alter table "fobos".cxpt026 drop constraint "fobos".pk_cxpt026;
alter table "fobos".cxpt028 drop constraint "fobos".pk_cxpt028;
alter table "fobos".cajt014 drop constraint "fobos".pk_cajt014;
alter table "fobos".cxct008 drop constraint "fobos".pk_cxct008;
alter table "fobos".cxct009 drop constraint "fobos".pk_cxct009;
alter table "fobos".srit025 drop constraint "fobos".pk_srit025;

--------------------------------------------------------------------------------


---------------- ELIMINACION DE PRIMARY KEY DE LA TABLA ordt003 ----------------

drop index "fobos".i01_pk_ordt003;
alter table "fobos".ordt003 drop constraint "fobos".pk_ordt003;

--------------------------------------------------------------------------------


-------------- INSERTAR NUEVA COLUMNA PARA PK EN LA TABLA ordt003 --------------

alter table "fobos".ordt003
	add (c03_fecha			date		before c03_estado);

select c03_compania cia, c03_tipo_ret tip_ret, c03_porcentaje porc,
	c03_codigo_sri cod_sri, c03_fecha_ini_porc fec_ini
	from ordt003
	where c03_compania = 1
	into temp tmp_c03;

update "fobos".ordt003
	set c03_fecha = (select fec_ini
				from tmp_c03
				where cia     = c03_compania
				  and tip_ret = c03_tipo_ret
				  and porc    = c03_porcentaje
				  and cod_sri = c03_codigo_sri)
	where c03_compania = 1
	  and exists
		(select 1 from tmp_c03
			where cia     = c03_compania
			  and tip_ret = c03_tipo_ret
			  and porc    = c03_porcentaje
			  and cod_sri = c03_codigo_sri);

alter table "fobos".ordt003 drop c03_fecha_ini_porc;

rename column "fobos".ordt003.c03_fecha to c03_fecha_ini_porc;

alter table "fobos".ordt003
	modify (c03_fecha_ini_porc	date		not null);

--------------------------------------------------------------------------------


-------------- DEFINICION DE NUEVA PRIMARY KEY DE LA TABLA ordt003 -------------

create unique index "fobos".i01_pk_ordt003
	on "fobos".ordt003
		(c03_compania, c03_tipo_ret, c03_porcentaje, c03_codigo_sri,
		 c03_fecha_ini_porc)
	in idxdbs;

alter table "fobos".ordt003
	add constraint
		primary key (c03_compania, c03_tipo_ret, c03_porcentaje,
				c03_codigo_sri, c03_fecha_ini_porc)
			constraint "fobos".pk_ordt003;

--------------------------------------------------------------------------------

drop table tmp_c03;

insert into "fobos".ordt003
	values (1, 'F', 0.10, 322, mdy(02, 01, 2009), "A",
		"Seguros y Reaseguros (Primas y Cesiones)",
		null, "N", null, null, null, null, "FOBOS", current);

insert into "fobos".ordt003
	values (1, 'F', 1.00, 309, mdy(02, 01, 2009), "A",
		"Servicios de Publicidad y Comunicacion",
		null, "N", null, null, null, null, "FOBOS", current);

insert into "fobos".ordt003
	values (1, 'F', 1.00, 310, mdy(02, 01, 2009), "A",
"Servicios Transporte Privado de Pasajeros o Servicio Publico Privado de Carga",
		null, "N", null, null, null, null, "FOBOS", current);

insert into "fobos".ordt003
	values (1, 'F', 1.00, 312, mdy(02, 01, 2009), "A",
		"Transferencia de Bienes Muebles de Naturaleza Corporal",
		null, "N", null, null, null, null, "FOBOS", current);

insert into "fobos".ordt003
	values (1, 'F', 2.00, 307, mdy(02, 01, 2009), "A",
		"Servicios Prodomina Mano de Obra",
		null, "N", null, null, null, null, "FOBOS", current);

insert into "fobos".ordt003
	values (1, 'F', 8.00, 303, mdy(02, 01, 2009), "A",
		"Servicios Honorarios Profesionales y Dietas",
		null, "N", null, null, null, null, "FOBOS", current);

select c03_compania cia, c03_tipo_ret tip_ret, c03_porcentaje porc,
	c03_codigo_sri cod_sri, c03_fecha_ini_porc fec_ini
	from ordt003
	where c03_compania = 1
	into temp tmp_c03;


-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA cxpt005 --------------

alter table "fobos".cxpt005
	add (p05_fecha_ini_porc		date);

update "fobos".cxpt005
	set p05_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia      = p05_compania
					  and tip_ret  = p05_tipo_ret
					  and porc     = p05_porcentaje
					  and cod_sri  = p05_codigo_sri
					  and fec_ini >= mdy(01,01,2009))
	where p05_compania = 1
	  and exists
		(select 1 from tmp_c03
			where cia      = p05_compania
			  and tip_ret  = p05_tipo_ret
			  and porc     = p05_porcentaje
			  and cod_sri  = p05_codigo_sri
			  and fec_ini >= mdy(01,01,2009));

update "fobos".cxpt005
	set p05_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia     = p05_compania
					  and tip_ret = p05_tipo_ret
					  and porc    = p05_porcentaje
					  and cod_sri = p05_codigo_sri)
	where p05_compania       = 1
	  and p05_fecha_ini_porc is null
	  and exists
		(select 1 from tmp_c03
			where cia     = p05_compania
			  and tip_ret = p05_tipo_ret
			  and porc    = p05_porcentaje
			  and cod_sri = p05_codigo_sri);

alter table "fobos".cxpt005
	modify (p05_fecha_ini_porc	date		not null);

--------------------------------------------------------------------------------


-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA cxpt026 --------------

alter table "fobos".cxpt026
	add (p26_fecha_ini_porc		date		before p26_valor_base);

select p26_compania cia_r, p26_localidad loc, p26_orden_pago ord_p,
	p26_secuencia sec, p26_tipo_ret tip_r, p26_porcentaje porc_r,
	p26_codigo_sri cod_s, date(p24_fecing) fecha
	from cxpt024, cxpt026
	where p24_compania      = 1
	  and date(p24_fecing) >= mdy(02,12,2009)
	  and p26_compania      = p24_compania 
	  and p26_localidad     = p24_localidad
	  and p26_orden_pago    = p24_orden_pago
union
select p26_compania cia_r, p26_localidad loc, p26_orden_pago ord_p,
	p26_secuencia sec, p26_tipo_ret tip_r, p26_porcentaje porc_r,
	p26_codigo_sri cod_s, date(p24_fecing) fecha
	from cxpt024, cxpt026
	where p24_compania     = 1
	  and date(p24_fecing) < mdy(02,12,2009)
	  and p26_compania     = p24_compania 
	  and p26_localidad    = p24_localidad
	  and p26_orden_pago   = p24_orden_pago
	into temp t1;

select cia_r cia, loc, ord_p, sec, tip_r tip_ret, porc_r porc, cod_s cod_sri,
	fec_ini
	from t1, tmp_c03
	where fecha   >= mdy(02,12,2009)
	  and tip_ret  = tip_r
	  and porc     = porc_r
	  and cod_sri  = cod_s
	  and fec_ini >= mdy(01,01,2009)
	into temp tmp_p26;

insert into tmp_p26
	select cia_r, loc, ord_p, sec, tip_r, porc_r, cod_s, fec_ini
		from t1, tmp_c03
		where tip_ret = tip_r
		  and porc    = porc_r
		  and cod_sri = cod_s
		  and fec_ini < mdy(01,01,2009)
		  and not exists
			(select 1 from tmp_p26 a
				where a.cia     = t1.cia_r
				  and a.loc     = t1.loc
				  and a.ord_p   = t1.ord_p
				  and a.sec     = t1.sec
				  and a.tip_ret = t1.tip_r
				  and a.porc    = t1.porc_r
				  and a.cod_sri = t1.cod_s);

drop table t1;

update "fobos".cxpt026
	set p26_fecha_ini_porc = (select fec_ini
					from tmp_p26
					where cia      = p26_compania
					  and loc      = p26_localidad
					  and ord_p    = p26_orden_pago
					  and sec      = p26_secuencia
					  and tip_ret  = p26_tipo_ret
					  and porc     = p26_porcentaje
					  and cod_sri  = p26_codigo_sri)
	where p26_compania = 1
	  and exists
		(select 1 from tmp_p26
			where cia      = p26_compania
			  and loc      = p26_localidad
			  and ord_p    = p26_orden_pago
			  and sec      = p26_secuencia
			  and tip_ret  = p26_tipo_ret
			  and porc     = p26_porcentaje
			  and cod_sri  = p26_codigo_sri);

drop table tmp_p26;

alter table "fobos".cxpt026
	modify (p26_fecha_ini_porc	date		not null);

--------------------------------------------------------------------------------


-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA cxpt028 --------------

alter table "fobos".cxpt028
	add (p28_fecha_ini_porc		date		before p28_valor_base);

select p28_compania cia, p28_localidad loc, p28_num_ret num_ret,
	p28_secuencia sec, p28_tipo_ret tip_ret, p28_porcentaje porc,
	p28_codigo_sri cod_sri, fec_ini
	from cxpt027, cxpt028, tmp_c03
	where p27_compania      = 1
	  and date(p27_fecing) >= mdy(02,12,2009)
	  and p28_compania      = p27_compania 
	  and p28_localidad     = p27_localidad
	  and p28_num_ret       = p27_num_ret
	  and tip_ret           = p28_tipo_ret
	  and porc              = p28_porcentaje
	  and cod_sri           = p28_codigo_sri
	  and fec_ini          >= mdy(01,01,2009)
union
select p28_compania cia, p28_localidad loc, p28_num_ret num_ret,
	p28_secuencia sec, p28_tipo_ret tip_ret, p28_porcentaje porc,
	p28_codigo_sri cod_sri, fec_ini
	from cxpt027, cxpt028, tmp_c03
	where p27_compania     = 1
	  and date(p27_fecing) < mdy(02,12,2009)
	  and p28_compania     = p27_compania 
	  and p28_localidad    = p27_localidad
	  and p28_num_ret      = p27_num_ret
	  and tip_ret          = p28_tipo_ret
	  and porc             = p28_porcentaje
	  and cod_sri          = p28_codigo_sri
	  and fec_ini          < mdy(01,01,2009)
	into temp tmp_p28;

update "fobos".cxpt028
	set p28_fecha_ini_porc = (select fec_ini
					from tmp_p28
					where cia     = p28_compania
					  and loc     = p28_localidad
					  and num_ret = p28_num_ret
					  and sec     = p28_secuencia
					  and tip_ret = p28_tipo_ret
					  and porc    = p28_porcentaje
					  and cod_sri = p28_codigo_sri)
	where p28_compania = 1
	  and exists
		(select 1 from tmp_p28
			where cia     = p28_compania
			  and loc     = p28_localidad
			  and num_ret = p28_num_ret
			  and sec     = p28_secuencia
			  and tip_ret = p28_tipo_ret
			  and porc    = p28_porcentaje
			  and cod_sri = p28_codigo_sri);

drop table tmp_p28;

--alter table "fobos".cxpt028 modify (p28_fecha_ini_porc date not null);

--------------------------------------------------------------------------------


-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA cajt014 --------------

alter table "fobos".cajt014
	add (j14_fec_ini_porc		date		before j14_base_imp);

update "fobos".cajt014
	set j14_fec_ini_porc = (select fec_ini
					from tmp_c03
					where cia      = j14_compania
					  and tip_ret  = j14_tipo_ret
					  and porc     = j14_porc_ret
					  and cod_sri  = j14_codigo_sri
					  and fec_ini >= mdy(01,01,2009))
	where j14_compania      = 1
	  and date(j14_fecing) >= mdy(02,12,2009)
	  and exists
		(select 1 from tmp_c03
			where cia      = j14_compania
			  and tip_ret  = j14_tipo_ret
			  and porc     = j14_porc_ret
			  and cod_sri  = j14_codigo_sri
			  and fec_ini >= mdy(01,01,2009));

update "fobos".cajt014
	set j14_fec_ini_porc = (select fec_ini
					from tmp_c03
					where cia     = j14_compania
					  and tip_ret = j14_tipo_ret
					  and porc    = j14_porc_ret
					  and cod_sri = j14_codigo_sri
					  and fec_ini < mdy(01,01,2009))
	where j14_compania      = 1
	  and (date(j14_fecing) < mdy(02,12,2009)
	   or  j14_fec_ini_porc is null)
	  and exists
		(select 1 from tmp_c03
			where cia     = j14_compania
			  and tip_ret = j14_tipo_ret
			  and porc    = j14_porc_ret
			  and cod_sri = j14_codigo_sri
			  and fec_ini < mdy(01,01,2009));

alter table "fobos".cajt014
	modify (j14_fec_ini_porc	date		not null);

--------------------------------------------------------------------------------


-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA cxct008 --------------

alter table "fobos".cxct008
	add (z08_fecha_ini_porc		date		before z08_defecto);

update "fobos".cxct008
	set z08_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia      = z08_compania
					  and tip_ret  = z08_tipo_ret
					  and porc     = z08_porcentaje
					  and cod_sri  = z08_codigo_sri
					  and fec_ini >= mdy(01,01,2009))
	where z08_compania      = 1
	  and date(z08_fecing) >= mdy(02,12,2009)
	  and exists
		(select 1 from tmp_c03
			where cia      = z08_compania
			  and tip_ret  = z08_tipo_ret
			  and porc     = z08_porcentaje
			  and cod_sri  = z08_codigo_sri
			  and fec_ini >= mdy(01,01,2009));

update "fobos".cxct008
	set z08_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia     = z08_compania
					  and tip_ret = z08_tipo_ret
					  and porc    = z08_porcentaje
					  and cod_sri = z08_codigo_sri
					  and fec_ini < mdy(01,01,2009))
	where z08_compania        = 1
	  and (date(z08_fecing)   < mdy(02,12,2009)
	   or  z08_fecha_ini_porc is null)
	  and exists
		(select 1 from tmp_c03
			where cia     = z08_compania
			  and tip_ret = z08_tipo_ret
			  and porc    = z08_porcentaje
			  and cod_sri = z08_codigo_sri
			  and fec_ini < mdy(01,01,2009));

alter table "fobos".cxct008
	modify (z08_fecha_ini_porc	date		not null);

--------------------------------------------------------------------------------


-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA cxct009 --------------

alter table "fobos".cxct009
	add (z09_fecha_ini_porc		date		before z09_codigo_pago);

update "fobos".cxct009
	set z09_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia      = z09_compania
					  and tip_ret  = z09_tipo_ret
					  and porc     = z09_porcentaje
					  and cod_sri  = z09_codigo_sri
					  and fec_ini >= mdy(01,01,2009))
	where z09_compania      = 1
	  and date(z09_fecing) >= mdy(02,12,2009)
	  and exists
		(select 1 from tmp_c03
			where cia      = z09_compania
			  and tip_ret  = z09_tipo_ret
			  and porc     = z09_porcentaje
			  and cod_sri  = z09_codigo_sri
			  and fec_ini >= mdy(01,01,2009))
	  and z09_cont_cred = 'C';

update "fobos".cxct009
	set z09_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia     = z09_compania
					  and tip_ret = z09_tipo_ret
					  and porc    = z09_porcentaje
					  and cod_sri = z09_codigo_sri
					  and fec_ini < mdy(01,01,2009))
	where z09_compania        = 1
	  and (date(z09_fecing)   < mdy(02,12,2009)
	   or  z09_fecha_ini_porc is null)
	  and exists
		(select 1 from tmp_c03
			where cia     = z09_compania
			  and tip_ret = z09_tipo_ret
			  and porc    = z09_porcentaje
			  and cod_sri = z09_codigo_sri
			  and fec_ini < mdy(01,01,2009))
	  and z09_cont_cred = 'C';

update "fobos".cxct009
	set z09_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia      = z09_compania
					  and tip_ret  = z09_tipo_ret
					  and porc     = z09_porcentaje
					  and cod_sri  = z09_codigo_sri
					  and fec_ini >= mdy(01,01,2009))
	where z09_compania      = 1
	  and date(z09_fecing) >= mdy(02,12,2009)
	  and exists
		(select 1 from tmp_c03
			where cia      = z09_compania
			  and tip_ret  = z09_tipo_ret
			  and porc     = z09_porcentaje
			  and cod_sri  = z09_codigo_sri
			  and fec_ini >= mdy(01,01,2009))
	  and z09_cont_cred = 'R';

update "fobos".cxct009
	set z09_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia     = z09_compania
					  and tip_ret = z09_tipo_ret
					  and porc    = z09_porcentaje
					  and cod_sri = z09_codigo_sri
					  and fec_ini < mdy(01,01,2009))
	where z09_compania        = 1
	  and (date(z09_fecing)   < mdy(02,12,2009)
	   or  z09_fecha_ini_porc is null)
	  and exists
		(select 1 from tmp_c03
			where cia     = z09_compania
			  and tip_ret = z09_tipo_ret
			  and porc    = z09_porcentaje
			  and cod_sri = z09_codigo_sri
			  and fec_ini < mdy(01,01,2009))
	  and z09_cont_cred = 'R';

alter table "fobos".cxct009
	modify (z09_fecha_ini_porc	date		not null);

--------------------------------------------------------------------------------


-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA srit025 --------------

alter table "fobos".srit025
	add (s25_fecha_ini_porc		date		before s25_cliprov);

update "fobos".srit025
	set s25_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia      = s25_compania
					  and tip_ret  = s25_tipo_ret
					  and porc     = s25_porcentaje
					  and cod_sri  = s25_codigo_sri
					  and fec_ini >= mdy(01,01,2009))
	where s25_compania      = 1
	  and date(s25_fecing) >= mdy(02,12,2009)
	  and exists
		(select 1 from tmp_c03
			where cia      = s25_compania
			  and tip_ret  = s25_tipo_ret
			  and porc     = s25_porcentaje
			  and cod_sri  = s25_codigo_sri
			  and fec_ini >= mdy(01,01,2009));

update "fobos".srit025
	set s25_fecha_ini_porc = (select fec_ini
					from tmp_c03
					where cia     = s25_compania
					  and tip_ret = s25_tipo_ret
					  and porc    = s25_porcentaje
					  and cod_sri = s25_codigo_sri
					  and fec_ini < mdy(01,01,2009))
	where s25_compania        = 1
	  and (date(s25_fecing)   < mdy(02,12,2009)
	   or  s25_fecha_ini_porc is null)
	  and exists
		(select 1 from tmp_c03
			where cia     = s25_compania
			  and tip_ret = s25_tipo_ret
			  and porc    = s25_porcentaje
			  and cod_sri = s25_codigo_sri
			  and fec_ini < mdy(01,01,2009));

alter table "fobos".srit025
	modify (s25_fecha_ini_porc	date		not null);

--------------------------------------------------------------------------------


drop table tmp_c03;


-------- DEFINICION DE INDICES POR PK EN LAS TABLAS HIJAS DE ordt003 -----------

create unique index "fobos".i01_pk_cxpt005
	on "fobos".cxpt005
		(p05_compania, p05_codprov, p05_tipo_ret, p05_porcentaje,
		 p05_codigo_sri, p05_fecha_ini_porc)
	in idxdbs;

create unique index "fobos".i01_pk_cxpt026
	on "fobos".cxpt026
		(p26_compania, p26_localidad, p26_orden_pago, p26_secuencia,
		 p26_tipo_ret, p26_porcentaje, p26_codigo_sri,
		 p26_fecha_ini_porc)
	in idxdbs;

create unique index "fobos".i01_pk_cxct008
	on "fobos".cxct008
		(z08_compania, z08_codcli, z08_tipo_ret, z08_porcentaje,
		 z08_codigo_sri, z08_fecha_ini_porc)
	in idxdbs;

create unique index "fobos".i01_pk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_codcli, z09_tipo_ret, z09_porcentaje,
		 z09_codigo_sri, z09_fecha_ini_porc, z09_codigo_pago,
		 z09_cont_cred)
	in idxdbs;

create unique index "fobos".i01_pk_srit025
	on "fobos".srit025
		(s25_compania, s25_tipo_ret, s25_porcentaje, s25_codigo_sri,
		 s25_fecha_ini_porc, s25_cliprov)
	in idxdbs;

--------------------------------------------------------------------------------


--------------- DEFINICION DE INDICES POR FK DE LA TABLA ordt003 ---------------

create index "fobos".i04_fk_cxpt005
	on "fobos".cxpt005
		(p05_compania, p05_tipo_ret, p05_porcentaje, p05_codigo_sri,
		 p05_fecha_ini_porc)
	in idxdbs;

create index "fobos".i03_fk_cxpt026
	on "fobos".cxpt026
		(p26_compania, p26_tipo_ret, p26_porcentaje, p26_codigo_sri,
		 p26_fecha_ini_porc)
	in idxdbs;

create index "fobos".i03_fk_cxpt028
	on "fobos".cxpt028
		(p28_compania, p28_tipo_ret, p28_porcentaje, p28_codigo_sri,
		 p28_fecha_ini_porc)
	in idxdbs;

create index "fobos".i03_fk_cajt014
	on "fobos".cajt014
		(j14_compania, j14_tipo_ret, j14_porc_ret, j14_codigo_sri,
		 j14_fec_ini_porc)
	in idxdbs;

create index "fobos".i04_fk_cxct008
	on "fobos".cxct008
		(z08_compania, z08_tipo_ret, z08_porcentaje, z08_codigo_sri,
		 z08_fecha_ini_porc)
	in idxdbs;

create index "fobos".i05_fk_cxct009
	on "fobos".cxct009
		(z09_compania, z09_tipo_ret, z09_porcentaje, z09_codigo_sri,
		 z09_fecha_ini_porc)
	in idxdbs;

create index "fobos".i01_fk_srit025
	on "fobos".srit025
		(s25_compania, s25_tipo_ret, s25_porcentaje, s25_codigo_sri,
		 s25_fecha_ini_porc)
	in idxdbs;

--------------------------------------------------------------------------------


-------- DEFINICION DE CONSTRAINTS POR PK EN LAS TABLAS HIJAS DE ordt003 -------

alter table "fobos".cxpt005
	add constraint
		primary key (p05_compania, p05_codprov, p05_tipo_ret,
				p05_porcentaje, p05_codigo_sri,
				p05_fecha_ini_porc)
		constraint "fobos".pk_cxpt005;

alter table "fobos".cxpt026
	add constraint
		primary key (p26_compania, p26_localidad, p26_orden_pago,
				p26_secuencia, p26_tipo_ret, p26_porcentaje,
				p26_codigo_sri, p26_fecha_ini_porc)
		constraint "fobos".pk_cxpt026;

alter table "fobos".cxct008
	add constraint
		primary key (z08_compania, z08_codcli, z08_tipo_ret,
				z08_porcentaje, z08_codigo_sri,
				z08_fecha_ini_porc)
		constraint "fobos".pk_cxct008;

alter table "fobos".cxct009
	add constraint
		primary key (z09_compania, z09_codcli, z09_tipo_ret,
				z09_porcentaje, z09_codigo_sri,
				z09_fecha_ini_porc, z09_codigo_pago,
				z09_cont_cred)
		constraint "fobos".pk_cxct009;

alter table "fobos".srit025
	add constraint
		primary key (s25_compania, s25_tipo_ret, s25_porcentaje,
				s25_codigo_sri, s25_fecha_ini_porc, s25_cliprov)
		constraint "fobos".pk_srit025;

--------------------------------------------------------------------------------


------------ DEFINICION DE CONSTRAINTS POR FK DE LA TABLA ordt003 --------------

alter table "fobos".cxpt005
	add constraint
		(foreign key (p05_compania, p05_tipo_ret, p05_porcentaje,
				p05_codigo_sri, p05_fecha_ini_porc)
		 references "fobos".ordt003
		 constraint "fobos".fk_04_cxpt005);

alter table "fobos".cxpt026
	add constraint
		(foreign key (p26_compania, p26_tipo_ret, p26_porcentaje,
				p26_codigo_sri, p26_fecha_ini_porc)
		 references "fobos".ordt003
		 constraint "fobos".fk_03_cxpt026);

alter table "fobos".cxpt028
	add constraint
		(foreign key (p28_compania, p28_tipo_ret, p28_porcentaje,
				p28_codigo_sri, p28_fecha_ini_porc)
		 references "fobos".ordt003
		 constraint "fobos".fk_03_cxpt028);

alter table "fobos".cajt014
	add constraint
		(foreign key (j14_compania, j14_tipo_ret, j14_porc_ret,
				j14_codigo_sri, j14_fec_ini_porc)
		 references "fobos".ordt003
		 constraint "fobos".fk_03_cajt014);

alter table "fobos".cxct008
	add constraint
		(foreign key (z08_compania, z08_tipo_ret, z08_porcentaje,
				z08_codigo_sri, z08_fecha_ini_porc)
		 references "fobos".ordt003
		 constraint "fobos".fk_04_cxct008);

alter table "fobos".cxct009
	add constraint
		(foreign key (z09_compania, z09_tipo_ret, z09_porcentaje,
				z09_codigo_sri, z09_fecha_ini_porc)
		 references "fobos".ordt003
		 constraint "fobos".fk_05_cxct009);

alter table "fobos".srit025
	add constraint
		(foreign key (s25_compania, s25_tipo_ret, s25_porcentaje,
				s25_codigo_sri, s25_fecha_ini_porc)
		 references "fobos".ordt003
		 constraint "fobos".fk_01_srit025);

--------------------------------------------------------------------------------


------------ ACTUALIZACION DE LA FECHA FIN EN LA TABLA ordt003 -----------------

update "fobos".ordt003
	set c03_fecha_fin_porc = mdy(12,31,2008)
	where year(c03_fecha_ini_porc) = 2003
	  and c03_fecha_fin_porc       is null;

--------------------------------------------------------------------------------

commit work;
--rollback work;
