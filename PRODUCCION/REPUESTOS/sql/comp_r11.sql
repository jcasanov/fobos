select 'acero_gm' base, count(*) total_reg from acero_gm:rept011
	where r11_bodega in (select r02_codigo from acero_gm:rept002
				where r02_tipo      <> 'S'
				  and r02_area       = 'R'
				  and r02_localidad  = 1)
	into temp t1;
insert into t1
	select 'acero_gc' base, count(*) total_reg from acero_gc:rept011
		where r11_bodega in (select r02_codigo from acero_gc:rept002
					where r02_tipo      <> 'S'
					  and r02_area       = 'R'
					  and r02_localidad  = 2);
insert into t1
	select 'acero_qm' base, count(*) total_reg from acero_qm:rept011
		where r11_bodega in (select r02_codigo from acero_qm:rept002
					where r02_tipo      <> 'S'
					  and r02_area       = 'R'
					  and r02_localidad  = 3);
insert into t1
	select 'acero_qs' base, count(*) total_reg from acero_qs:rept011
		where r11_bodega in (select r02_codigo from acero_qs:rept002
					where r02_tipo      <> 'S'
					  and r02_area       = 'R'
					  and r02_localidad  = 4);
select * from t1;
select sum(total_reg) tot_r11_nac from t1;
drop table t1;
