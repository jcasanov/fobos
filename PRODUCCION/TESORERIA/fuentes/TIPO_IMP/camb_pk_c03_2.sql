select c03_compania cia, c03_tipo_ret tip_ret, c03_porcentaje porc,
	c03_codigo_sri cod_sri, c03_fecha_ini_porc fec_ini
	from ordt003
	where c03_compania = 1
	into temp tmp_c03;

begin work;

-------------- INSERTAR NUEVA COLUMNA PARA FK EN LA TABLA cxct009 --------------

alter table "fobos".cxct009
	add (z09_fecha_ini_porc		date		before z09_codigo_pago);

set lock mode to wait 30;

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

commit work;

drop table tmp_c03;
