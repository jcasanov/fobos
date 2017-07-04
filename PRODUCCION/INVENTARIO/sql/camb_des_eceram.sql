set isolation to dirty read;

select r10_compania cia, "GYE" loc, r10_codigo item, r10_nombre descripcion
	from acero_gm@idsgye01:rept010
	where  r10_compania = 1
	  and  r10_estado   = "A"
	  and  r10_marca    = "ECERAM"
	  and (r10_nombre   matches "*exportación*"
	   or  r10_nombre   matches "*standard*"
	   or  r10_nombre   matches "*comercial*"
	   or  r10_nombre   matches "*exportacion*"
	   or  r10_nombre   matches "*EXPORTACIÓN*"
	   or  r10_nombre   matches "*STANDARD*"
	   or  r10_nombre   matches "*COMERCIAL*"
	   or  r10_nombre   matches "*EXPORTACION*")
union
select r10_compania cia, "UIO" loc, r10_codigo item, r10_nombre descripcion
	from acero_qm@idsuio01:rept010
	where  r10_compania = 1
	  and  r10_estado   = "A"
	  and  r10_marca    = "ECERAM"
	  and (r10_nombre   matches "*exportación*"
	   or  r10_nombre   matches "*standard*"
	   or  r10_nombre   matches "*comercial*"
	   or  r10_nombre   matches "*exportacion*"
	   or  r10_nombre   matches "*EXPORTACIÓN*"
	   or  r10_nombre   matches "*STANDARD*"
	   or  r10_nombre   matches "*COMERCIAL*"
	   or  r10_nombre   matches "*EXPORTACION*")
	into temp t1;

select loc, count(*) tot_item from t1 group by 1 order by 1;

unload to "camb_des_eceram.unl" select * from t1 order by 1, 2;

select cia, loc, item,
	trim(replace(descripcion, "exportación", "primera")) descripcion
	from t1
	into temp t2;

drop table t1;

select cia, loc, item,
	trim(replace(descripcion, "standard", "estandar")) descripcion
	from t2
	into temp t1;

drop table t2;

select cia, loc, item,
	trim(replace(descripcion, "comercial", "segunda")) descripcion
	from t1
	into temp t2;

drop table t1;

select cia, loc, item,
	trim(replace(descripcion, "exportacion", "primera")) descripcion
	from t2
	into temp t1;

drop table t2;

select cia, loc, item,
	trim(replace(descripcion, "EXPORTACIÓN", "PRIMERA")) descripcion
	from t1
	into temp t2;

drop table t1;

select cia, loc, item,
	trim(replace(descripcion, "STANDARD", "ESTANDAR")) descripcion
	from t2
	into temp t1;

drop table t2;

select cia, loc, item,
	trim(replace(descripcion, "COMERCIAL", "SEGUNDA")) descripcion
	from t1
	into temp t2;

drop table t1;

select cia, loc, item,
	trim(replace(descripcion, "EXPORTACION", "PRIMERA")) descripcion
	from t2
	into temp t1;

drop table t2;

--select loc, item, descripcion from t1 order by 1, 2;

begin work;

	update acero_gm@idsgye01:rept010
		set r10_nombre = (select descripcion
					from t1
					where cia  = r10_compania
					  and loc  = "GYE"
					  and item = r10_codigo)
		where r10_compania  = 1
		  and r10_estado    = "A"
		  and r10_marca     = "ECERAM"
		  and r10_codigo   in (select item
					from t1
					where loc = "GYE");

	update acero_qm@idsuio01:rept010
		set r10_nombre = (select descripcion
					from t1
					where cia  = r10_compania
					  and loc  = "UIO"
					  and item = r10_codigo)
		where r10_compania  = 1
		  and r10_estado    = "A"
		  and r10_marca     = "ECERAM"
		  and r10_codigo   in (select item
					from t1
					where loc = "UIO");

commit work;

drop table t1;
