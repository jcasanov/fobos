select c03_compania cia, c03_tipo_ret tip_ret, c03_porcentaje porc,
	c03_codigo_sri cod_sri, c03_fecha_ini_porc fec_ini
	from ordt003
	where c03_compania = 1
	into temp tmp_c03;

begin work;

-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA srit025 --------------

alter table "fobos".srit025
	add (s25_fecha_ini_porc		date		before s25_cliprov);

set lock mode to wait 30;

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
