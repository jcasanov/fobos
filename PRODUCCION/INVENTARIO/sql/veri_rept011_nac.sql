select count(*) acero_gm_rept011
	from rept011
	where r11_bodega in (select r02_codigo from rept002
				where r02_compania  = 1
				  and r02_localidad in (1,2,3,4,5)
				  and r02_tipo      <> 'S'
				  and r02_area       = 'R');
select count(*) tot_rept010 from rept010;
select r02_localidad, count(*) tot_bd
	from rept002
        where r02_compania  = 1
          and r02_tipo      <> 'S'
          and r02_area       = 'R'
	group by 1
	order by 1;
