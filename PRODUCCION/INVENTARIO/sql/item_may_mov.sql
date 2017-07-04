select r20_localidad loc, r20_cod_tran ct, r20_bodega bd, r20_item item,
	count(*) tot_tran
	--from acero_gm@g_tanca:rept020
	from aceros:rept020
	where r20_compania  = 1
	  and r20_localidad = 1
	group by 1, 2, 3, 4
union
select r20_localidad loc, r20_cod_tran ct, r20_bodega bd, r20_item item,
	count(*) tot_tran
	--from acero_gc@g_tanca:rept020
	from acero_gc:rept020
	where r20_compania  = 1
	  and r20_localidad = 2
	group by 1, 2, 3, 4
union
select r20_localidad loc, r20_cod_tran ct, r20_bodega bd, r20_item item,
	count(*) tot_tran
	--from acero_qm@g_norte:rept020
	from acero_qm:rept020
	where r20_compania  = 1
	  and r20_localidad in (3, 5)
	group by 1, 2, 3, 4
union
select r20_localidad loc, r20_cod_tran ct, r20_bodega bd, r20_item item,
	count(*) tot_tran
	--from acero_qs@g_sur:rept020
	from acero_qs:rept020
	where r20_compania  = 1
	  and r20_localidad = 4
	group by 1, 2, 3, 4
union
select r20_localidad loc, r20_cod_tran ct, r20_bodega bd, r20_item item,
	count(*) tot_tran
	--from sermaco_gm@segye01:rept020
	from sermaco_gm:rept020
	where r20_compania  = 2
	  and r20_localidad = 6
	group by 1, 2, 3, 4
union
select r20_localidad loc, r20_cod_tran ct, r20_bodega bd, r20_item item,
	count(*) tot_tran
	--from sermaco_qm@seuio01:rept020
	from sermaco_qm:rept020
	where r20_compania  = 2
	  and r20_localidad = 7
	group by 1, 2, 3, 4
	into temp t1;

select ct, item, sum(tot_tran) tot_tran
	from t1, rept010
	where loc        = 1
	  and r10_codigo = item
	  and r10_marca  = 'POWERS'
	group by 1, 2;

select loc, item, sum(tot_tran) tot_tran
	from t1
	group by 1, 2
	into temp t2;

select loc, item, count(bd) tot_bd
	from t1
	group by 1, 2
	into temp t3;

drop table t1;

select loc, item, max(tot_tran) tot_tran
	from t2
	group by 1, 2
	into temp t4;

select loc l, item i, max(tot_tran) t
	from t2
	group by 1, 2
	into temp caca;

select loc, item, tot_tran
	from t2
	where tot_tran = (select max(t)
				from caca
				where l = loc)
	order by 3 desc, 1, 2;

drop table t2;
drop table caca;
drop table t4;

select loc, item, max(tot_bd) tot_bd
	from t3
	group by 1, 2
	into temp t5;

select loc l, item i, max(tot_bd) t
	from t3
	group by 1, 2
	into temp caca;

select loc, item, tot_bd
	from t5
	where tot_bd = (select max(t)
				from caca
				where l = loc)
	order by 3 desc, 1, 2;

drop table t3;
drop table caca;
drop table t5;
