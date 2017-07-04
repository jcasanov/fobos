select r02_codigo from rept002
	where r02_compania  =  1
	  and r02_localidad =  1
	  and r02_estado    =  'A'
	  and r02_area      =  'R'
	  and r02_tipo      <> 'S'
	into temp tmp_bod;

unload to "ctbt040_2.unl"
	select * from ctbt040
		where b40_compania  =  1
		  and b40_bodega    in (select * from tmp_bod);

drop table tmp_bod;
