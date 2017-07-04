select r02_compania cia_b, r02_localidad loc_b, r02_codigo bodega
	from rept002
	where r02_compania  in (1, 2)
	  and r02_estado     = 'A'
	  and r02_tipo      <> 'S'
	  and r02_area       = 'R'
	  and r02_localidad not in (4, 5)
	into temp tmp_bod;
select r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num,
	r19_bodega_ori bo, r19_bodega_dest bd, r19_referencia referen,
	date(r19_fecing) fecha
	from rept019
	where r19_compania    in (1, 2)
	  and r19_cod_tran     = 'TR'
	  and r19_bodega_ori  in (select bodega
					from tmp_bod
					where cia_b   = r19_compania
					  and bodega  = r19_bodega_ori
					  and loc_b  <> r19_localidad)
	  and extend(r19_fecing, year to month) >= '2007-01'
union
select r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num,
	r19_bodega_ori bo, r19_bodega_dest bd, r19_referencia referen,
	date(r19_fecing) fecha
	from rept019
	where r19_compania    in (1, 2)
	  and r19_cod_tran     = 'TR'
	  and r19_bodega_dest in (select bodega
					from tmp_bod
					where cia_b   = r19_compania
					  and bodega  = r19_bodega_dest
					  and loc_b  <> r19_localidad)
	  and extend(r19_fecing, year to month) >= '2007-01'
	into temp tmp_tr;
drop table tmp_bod;
select tmp_tr.*, r40_tipo_comp, r40_num_comp
	from tmp_tr, outer rept040
	where r40_compania  = cia
	  and r40_localidad = loc
	  and r40_cod_tran  = tp
	  and r40_num_tran  = num
	into temp t1;
drop table tmp_tr;
delete from t1
	where bo = '40'
	   or bd = '40';
select cia, loc, tp, num, bo, bd, referen, fecha, r40_tipo_comp, r40_num_comp,
	b13_tipo_comp tp2, b13_num_comp num2, count(*) num_reg
	from t1, outer ctbt013
	where b13_compania  = cia
	  and b13_tipo_comp = r40_tipo_comp
	  and b13_num_comp  = r40_num_comp
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	having count(*) < 2
	into temp t2;
drop table t1;
delete from t2 where tp2 is not null;
select count(*) tot_tr from t2;
select * from t2 order by fecha desc;
drop table t2;
