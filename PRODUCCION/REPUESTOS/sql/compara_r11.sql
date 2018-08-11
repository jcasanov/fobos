select r11_compania codcia, r11_bodega bd_gye, r11_item item_gye
	from acero_qm:rept011
	where r11_compania  = 1
	  and r11_bodega   in (select r02_codigo from acero_qm:rept002
				where r02_compania   = 1
				  and r02_localidad in (3,5)
				  and r02_tipo      <> 'S'
				  and r02_area       = 'R')
	into temp t1;
select count(*) hay_t1 from t1;
select bd_gye, item_gye, r11_bodega, r11_item
	from t1, outer acero_gc:rept011
	where r11_compania = codcia
	  and r11_bodega   = bd_gye
	  and r11_item     = item_gye
	into temp t2;
select count(*) hay_t2 from t2;
drop table t1;
delete from t2 where r11_bodega is not null;
select count(*) hay_t2_d from t2;
select * from t2;
unload to "r11_qm.txt"
	select a.* from acero_qm:rept011 a, t2
		where a.r11_compania = 1
		  and a.r11_bodega   = bd_gye
		  and a.r11_item     = item_gye;
drop table t2;
