set isolation to dirty read;

select r02_localidad loc_b, r02_codigo bod
	from rept002
	where r02_compania in (1, 2)
	  and r02_estado    = "A"
	  and r02_tipo      = "S"
	  and r02_area      = "R"
	into temp tmp_bod;

select unique r20_compania cia, r20_localidad loc, r20_cod_tran tp,
	r20_num_tran num,
	r19_tipo_dev tt, r19_num_dev num_d, r19_bodega_ori bd_o,
	r19_bodega_dest bd_d, r20_item item,
	case when r19_bodega_ori  = (select bod from tmp_bod
					where loc_b = r20_localidad)
		then r20_cant_ven * (-1)
	     when r19_bodega_dest = (select bod from tmp_bod
					where loc_b = r20_localidad)
		then r20_cant_ven
		else 0.00
	end cant
	from rept020, rept019
	where  r20_compania    in (1, 2)
	  and  r20_cod_tran     = "TR"
	  and  r19_compania     = r20_compania
	  and  r19_localidad    = r20_localidad
	  and  r19_cod_tran     = r20_cod_tran
	  and  r19_num_tran     = r20_num_tran
	  and (r19_bodega_ori   = (select bod from tmp_bod
					where loc_b = r20_localidad)
	   or  r19_bodega_dest  = (select bod from tmp_bod
					where loc_b = r20_localidad))
	into temp tmp_tr;

select unique r20_compania cia_f, r20_localidad loc_f, r20_cod_tran tp_f,
	r20_num_tran num_f, r20_bodega bd_f, r20_item item_f,
	case when r20_cod_tran = "FA"
		then r20_cant_ven
		else r20_cant_ven * (-1)
	end cant_f,
	r19_tipo_dev tt_f, r19_num_dev dev_f, tp, num, cant
	from tmp_tr, rept019, rept020
	where r19_compania  = cia
	  and r19_localidad = loc
	  and r19_cod_tran  = tt
	  and r19_num_tran  = num_d
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and r20_bodega    = (select bod from tmp_bod
				where loc_b = r20_localidad)
	  and r20_item      = item
	into temp tmp_fac;

drop table tmp_bod;
drop table tmp_tr;

select a.cia_f cia_d, a.loc_f loc_d, a.tp_f tp_d, a.num_f fac_d, a.bd_f bod_d,
	a.item_f item_d, a.cant_f, round(nvl(sum(a.cant), 0), 2) cant_tr
	from tmp_fac a
	where a.tp_f = "FA"
	group by 1, 2, 3, 4, 5, 6, 7
union
select a.cia_f cia_d, a.loc_f loc_d, a.tt_f tp_d, a.dev_f fac_d, a.bd_f bod_d,
	a.item_f item_d, a.cant_f, round(nvl(sum(a.cant), 0), 2) cant_tr
	from tmp_fac a
	where a.tp_f <> "FA"
	group by 1, 2, 3, 4, 5, 6, 7
	into temp tmp_dat;

select cia_d, loc_d, tp_d, fac_d, bod_d, item_d,
	round(nvl(sum(cant_f), 0), 2) cant_f,
	round(nvl(sum(cant_tr), 0), 2) cant_tr
	from tmp_dat
	group by 1, 2, 3, 4, 5, 6
	into temp t1;

drop table tmp_dat;

select cia_d, loc_d, tp_d, fac_d, bod_d, item_d
	from t1
	where cant_tr  > cant_f
	  and cant_tr <> 0
	into temp t2;

drop table t1;

select * from tmp_fac
	where exists
		(select 1 from t2
			where cia_d  = cia_f
			  and loc_d  = loc_f
			  and tp_d   = tp_f
			  and fac_d  = num_f
			  and bod_d  = bd_f
			  and item_d = item_f)
	into temp t3;

drop table t2;
drop table tmp_fac;

select count(unique item_f) tot_ite_dif from t3;
select count(*) tot_fac_dif from t3;
select item_f, count(*) tot_tra
	from t3
	group by 1
	order by 2 desc, 1;

select unique item_f
	from t3
	order by 1;

select * from t3
	order by 6, 1, 2, 3, 4;

drop table t3;
