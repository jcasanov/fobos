select r19_num_tran num_cen, r90_numtra_fin num_jtm,
	extend(r20_fecing, year to day) fecha,
	round(sum(r20_cant_ven * r20_costo), 2) costo
	from rept020, rept019, aceros:rept090
	where r20_compania       = 1
	  and r20_localidad      = 2
	  and r20_cod_tran       = 'TR'
	  and r19_compania       = r20_compania
	  and r19_localidad      = r20_localidad
	  and r19_cod_tran       = r20_cod_tran
	  and r19_num_tran       = r20_num_tran
	  and r19_bodega_ori     = '70'
	  and r19_bodega_dest   in (select r02_codigo
					from rept002
					where r02_compania  = r20_compania
					  and r02_localidad = 1)
	  and (r19_referencia   like '%TRA%'
	   or  r19_referencia   like 'TRA*'
	   or  r19_referencia   like '%SAL%'
	   or  r19_referencia   like '%HER%'
	   or  r19_referencia   like '%STO%'
	   or  r19_referencia   like '%COR%')
	  and year(r19_fecing)  >= 2008
	  and r90_compania       = r19_compania
	  and r90_localidad      = r19_localidad
	  and r90_cod_tran          = r19_cod_tran
	  and r90_num_tran          = r19_num_tran
	  and year(r90_fecing_fin) >= 2009
	group by 1, 2, 3
	into temp t1;
select round(sum(costo), 2) tot_costo from t1;
select count(*) tot_tr from t1;
select * from t1 order by 3, 2;
drop table t1;
