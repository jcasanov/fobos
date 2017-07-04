set isolation to dirty read;

select r10_compania cia, "GYE" loc, r10_codigo item, r10_nombre descrip
	from acero_gm@idsgye01:rept010
	where r10_compania  = 1
	  and r10_marca    in ("ECERAM", "RIALTO")
	  and r10_estado    = "A"
	  and (r10_nombre   like "%Exportaci�n%"
	   or  r10_nombre   like "%Exportacion%"
	   or  r10_nombre   like "%EXPORTACI�N%"
	   or  r10_nombre   like "%EXPORTACION%"
	   or  r10_nombre   like "%Standard%"
	   or  r10_nombre   like "%St�ndard%"
	   or  r10_nombre   like "%STANDARD%"
	   or  r10_nombre   like "%ST�NDARD%")
union
select r10_compania cia, "UIO" loc, r10_codigo item, r10_nombre descrip
	from acero_qm@idsuio01:rept010
	where r10_compania  = 1
	  and r10_marca    in ("ECERAM", "RIALTO")
	  and r10_estado    = "A"
	  and (r10_nombre   like "%Exportaci�n%"
	   or  r10_nombre   like "%Exportacion%"
	   or  r10_nombre   like "%EXPORTACI�N%"
	   or  r10_nombre   like "%EXPORTACION%"
	   or  r10_nombre   like "%Standard%"
	   or  r10_nombre   like "%St�ndard%"
	   or  r10_nombre   like "%STANDARD%"
	   or  r10_nombre   like "%ST�NDARD%")
	into temp t1;

select loc, count(*) tot_item from t1 group by 1 order by 1;

unload to "camb_desc_riaece.unl" select * from t1 order by 1, 2;

select cia, loc, item, replace(descrip, "Exportaci�n", "Primera") descrip
	from t1
	into temp t2;
drop table t1;

select cia, loc, item, replace(descrip, "Exportacion", "Primera") descrip
	from t2
	into temp t1;
drop table t2;

select cia, loc, item, replace(descrip, "EXPORTACI�N", "PRIMERA") descrip
	from t1
	into temp t2;
drop table t1;

select cia, loc, item, replace(descrip, "EXPORTACION", "PRIMERA") descrip
	from t2
	into temp t1;
drop table t2;

select cia, loc, item, replace(descrip, "Standard", "Segunda") descrip
	from t1
	into temp t2;
drop table t1;

select cia, loc, item, replace(descrip, "St�ndard", "Segunda") descrip
	from t2
	into temp t1;
drop table t2;

select cia, loc, item, replace(descrip, "STANDARD", "SEGUNDA") descrip
	from t1
	into temp t2;
drop table t1;

select cia, loc, item, replace(descrip, "ST�NDARD", "SEGUNDA") descrip
	from t2
	into temp t1;
drop table t2;

--select loc, item, descrip from t1 order by 1, 2;

begin work;

	update acero_gm@idsgye01:rept010
		set r10_nombre = (select descrip
					from t1
					where cia  = r10_compania
					  and loc  = "GYE"
					  and item = r10_codigo)
		where r10_compania  = 1
		  and r10_estado    = "A"
		  and r10_marca    in ("ECERAM", "RIALTO")
		  and r10_codigo   in (select item
					from t1
					where loc = "GYE");

	update acero_qm@idsuio01:rept010
		set r10_nombre = (select descrip
					from t1
					where cia  = r10_compania
					  and loc  = "UIO"
					  and item = r10_codigo)
		where r10_compania  = 1
		  and r10_estado    = "A"
		  and r10_marca    in ("ECERAM", "RIALTO")
		  and r10_codigo   in (select item
					from t1
					where loc = "UIO");

--rollback work;
commit work;

drop table t1;
