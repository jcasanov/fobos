set isolation to dirty read;
select r19_compania cia, r19_localidad loc, r19_cod_tran tp, r19_num_tran num
	from rept019
	where r19_compania    in (1, 2)
	  and r19_cod_tran    not in ('FA', 'AF', 'DF')
	  and r19_bodega_ori  in (select r02_codigo
					from rept002
					where r02_compania  = r19_compania
					  and r02_localidad not in(4, 5)) 
	  and r19_bodega_dest in (select r02_codigo
					from rept002
					where r02_compania  = r19_compania
					  and r02_localidad not in(4, 5)) 
	  and year(r19_fecing) = 2007
	into temp t1;
select t1.*, r40_tipo_comp, r40_num_comp
	from t1, rept040
	where r40_compania  = cia
	  and r40_localidad = loc
	  and r40_cod_tran  = tp
	  and r40_num_tran  = num
	into temp t2;
drop table t1;
select extend(b13_fec_proceso, year to month) fecha, tp, b13_cuenta cuenta,
	b13_tipo_comp tp2, b13_num_comp num_c, b12_estado e, 0 t_cta
	from t2, ctbt012, ctbt013
	where b12_compania           = cia
	  and b12_tipo_comp          = r40_tipo_comp
	  and b12_num_comp           = r40_num_comp
	  and b12_estado            <> 'E'
	  and year(b12_fec_proceso)  = 2007
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta            matches '61*'
	  --and b13_cuenta            in ('61010101003', '61010103003')
union
select extend(b13_fec_proceso, year to month) fecha, tp, b13_cuenta cuenta,
	b13_tipo_comp tp2, b13_num_comp num_c, b12_estado e,
	(select count(*)
		from ctbt013 b
		where b.b13_compania  = b12_compania
		  and b.b13_tipo_comp = b12_tipo_comp
		  and b.b13_num_comp  = b12_num_comp) t_cta
	from t2, ctbt012, ctbt013
	where b12_compania           = cia
	  and b12_tipo_comp          = r40_tipo_comp
	  and b12_num_comp           = r40_num_comp
	  and b12_estado            <> 'E'
	  and year(b12_fec_proceso)  = 2007
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	into temp t1;
drop table t2;
delete from t1 where t_cta > 1;
select fecha, tp, cuenta, count(*) tot_reg
	from t1
	group by 1, 2, 3
	order by 1;
select fecha, tp, cuenta, t_cta, count(*) tot_reg
	from t1
	group by 1, 2, 3, 4
	order by 4, 1;
select * from t1 order by fecha, num_c;
drop table t1;
