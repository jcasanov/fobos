select r11_compania codcia, r11_bodega bd_gye, r11_item item_gye, r02_localidad
	from rept011, rept002
	where r11_compania   = 1
	  and r02_compania   = r11_compania
	  and r02_codigo     = r11_bodega
	  and r02_localidad in (1,2,3,4,5)
	  and r02_tipo      <> 'S'
	  and r02_area       = 'R'
	into temp t1;
select count(*) tot_rept011 from t1;
select r02_localidad, count(*) tot_rept011_loc from t1 group by 1 order by 1;
--select unique r02_localidad, bd_gye from t1 into temp t_bod;
drop table t1;
select r02_localidad, count(*) tot_bd
	from rept002
        where r02_compania  = 1
          and r02_tipo      <> 'S'
          and r02_area       = 'R'
	group by 1
	order by 1;
