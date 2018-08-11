--drop table t1;
select r60_vendedor vend, extend(r60_fecha, year to month) mes,
	sum(r60_precio) venta
	from rept060
	where r60_vendedor in (61,79)
	  and r60_fecha    > mdy(11,01,2006)
	group by 1, 2
	into temp t1;
select vend, round(sum(venta), 2) tot_vta from t1 group by 1;
select * from t1 order by 1 desc, 2;
drop table t1;
