select r34_bodega, r34_num_ord_des, nvl(sum(r35_cant_des), 0) cant_des,
	nvl(sum(r35_cant_ent), 0) cant_ent
	from rept034, rept035
	where r34_compania    = 1
	  and r34_localidad   = 1
	  and r34_estado      = 'A'
	  and r35_compania    = r34_compania
	  and r35_localidad   = r34_localidad
	  and r35_bodega      = r34_bodega
	  and r35_num_ord_des = r34_num_ord_des
	group by 1, 2
	having nvl(sum(r35_cant_des), 0) = 0
	into temp t1;
select r34_bodega, r34_num_ord_des, count(*) hay_por_bd
	from t1
	group by 1, 2
	into temp t2;
select nvl(sum(hay_por_bd), 0) total_od	from t2;
select r34_bodega, nvl(sum(hay_por_bd), 0) total_od_bd
	from t2
	group by 1
	order by 1;
drop table t2;
select unique r34_bodega, r34_num_ord_des from t1 order by 1, 2;
drop table t1;
