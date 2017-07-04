set isolation to dirty read;
	select 'acero_qm' base, count(*) total_reg from rept011
		where r11_bodega in (select r02_codigo from rept002
					where r02_tipo      <> 'S'
					  and r02_area       = 'R'
					  and r02_localidad  = 3)
	into temp t1;
select * from t1;
--select sum(total_reg) tot_r11_nac from t1;
drop table t1;
