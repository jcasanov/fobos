select r20_compania cia, r20_localidad loc, r20_cod_tran tp, r20_num_tran num,
	round(nvl(sum(r20_cant_ven * r20_costo), 0), 2) cos_tot
	from rept020, rept019
	where  r20_compania    = 1
	  and  r20_localidad   = 1
	  and  r20_cod_tran    = 'TR'
	  and  r19_compania    = r20_compania
	  and  r19_localidad   = r20_localidad
	  and  r19_cod_tran    = r20_cod_tran
	  and  r19_num_tran    = r20_num_tran
	  and (r19_bodega_ori  = '99'
	   or  r19_bodega_dest = '99')
	group by 1, 2, 3, 4
	into temp tmp_tr;

select tp, num, date(r19_fecing) fecha, cos_tot, r19_tot_costo cos_r19
	from tmp_tr, rept019
	where r19_compania   = cia
	  and r19_localidad  = loc
	  and r19_cod_tran   = tp
	  and r19_num_tran   = num
	  and r19_tot_costo <> cos_tot
union
select tp, num, date(r19_fecing) fecha, cos_tot, r19_tot_neto cos_r19
	from tmp_tr, rept019
	where r19_compania   = cia
	  and r19_localidad  = loc
	  and r19_cod_tran   = tp
	  and r19_num_tran   = num
	  and r19_tot_neto  <> cos_tot
	into temp t1;

drop table tmp_tr;

select year(fecha) anio, count(*) tot_reg
	from t1
	group by 1
	order by 1;

select count(*) tot_reg from t1;

select * from t1
	order by 1, 2, 3;

drop table t1;
