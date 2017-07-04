select r34_compania, r34_localidad, r34_bodega, r34_num_ord_des,
	nvl(sum(r35_cant_des), 0) cant_des, nvl(sum(r35_cant_ent), 0) cant_ent
	from rept034, rept035
	where r34_compania    = 1
	  and r34_localidad   = 1
	  and r34_estado      = 'A'
	  and r35_compania    = r34_compania
	  and r35_localidad   = r34_localidad
	  and r35_bodega      = r34_bodega
	  and r35_num_ord_des = r34_num_ord_des
	group by 1, 2, 3, 4
	having nvl(sum(r35_cant_des), 0) = 0
	into temp t1;
select unique r34_compania cia, r34_localidad loc, r34_bodega bod,
	r34_num_ord_des num_od
	from t1
	into temp t2;
drop table t1;
begin work;
update rept034 set r34_estado = 'E'
	where exists (select * from t2
			where cia    = r34_compania
			  and loc    = r34_localidad
			  and bod    = r34_bodega
			  and num_od = r34_num_ord_des);
drop table t2;
commit work;
