begin work;

select b40_costo_venta, count(*) hay_cos_vta
	from ctbt040 group by 1 order by 2;

select b40_ajustes, count(*) hay_aj_vta from ctbt040 group by 1 order by 2;

update ctbt040 set b40_ajustes = b40_costo_venta
	where b40_costo_venta in ('61010101001', '61010103001');

select b40_ajustes, count(*) hay_aj_vta from ctbt040 group by 1 order by 2;

commit work;

select * from ctbt040;
