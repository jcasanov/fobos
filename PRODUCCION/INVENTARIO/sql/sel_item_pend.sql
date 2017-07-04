select r10_codigo[1,7], r10_nombre[1,15], 0 stock_pend,
	(select nvl(sum(r11_stock_act), 0)
		from rept011
		where r11_compania =  r10_compania
		  and r11_bodega   in (select r02_codigo from rept002
					where r02_compania =  r11_compania
					  --and r02_estado   =  'A'
					  and r02_tipo     <> 'S')
		  and r11_item     =  r10_codigo) stock_tot,
	(select nvl(sum(r11_stock_act), 0)
		from rept011
		where r11_compania =  r10_compania
		  and r11_bodega   in (select r02_codigo from rept002
					where r02_compania  =  r11_compania
					  and r02_localidad in (1, 2)
					  --and r02_localidad in (3, 4, 5)
					  --and r02_estado    =  'A'
					  and r02_tipo      <> 'S')
		  and r11_item     =  r10_codigo) stock_loc,
	r10_stock_max, r10_stock_min
	from rept010
	where r10_compania = 1
	  and r10_estado   = 'A'
	group by 1, 2, 3, 4, 5, 6, 7
	into temp t1;
{
select * from t1
	where stock_loc > 0
	order by 1;
}
drop table t1;
