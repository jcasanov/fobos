select r87_item item, max(r87_secuencia) secuencia
	from rept087
	where r87_compania  = 2
	  and r87_localidad = 7
	group by 1
	into temp t1;

select r87_item, r87_precio_act, r87_precio_ant, r87_usu_camprec,
	r87_fec_camprec
	from rept087
	where r87_compania  = 2
	  and r87_localidad = 7
	  and r87_item      in (select item from t1)
	  and r87_secuencia = (select secuencia from t1 where item = r87_item)
	into temp t2;

drop table t1;

select count(*) total_r87 from rept087;
select count(*) total_item from t2;

select r10_codigo, r87_item
	from t2, outer rept010
	where r10_codigo   = r87_item
	  and r10_compania = 2
	into temp caca;
delete from caca where r10_codigo is not null;
select * from caca;
drop table caca;

select r10_marca, r87_item
	from t2, rept010
	where r10_codigo   = r87_item
	  and r10_compania = 2
	into temp t3;
select r10_marca, count(*) total_marca from t3 group by 1 order by 2 desc;
drop table t3;

begin work;

update rept010
	set r10_precio_mb   = (select r87_precio_act from t2
				where r87_item = r10_codigo),
	    r10_precio_ant  = (select r87_precio_ant from t2
				where r87_item = r10_codigo),
	    r10_fec_camprec = (select r87_fec_camprec from t2
				where r87_item = r10_codigo)
	where r10_compania = 2
	  and r10_codigo   = (select r87_item from t2
				where r87_item = r10_codigo);

commit work;

drop table t2;
