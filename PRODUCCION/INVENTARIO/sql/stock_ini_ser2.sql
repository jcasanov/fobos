select r20_localidad loc, r20_cod_tran tp, r20_item item, r10_marca marca,
	nvl(sum(r20_cant_ven), 0) cant,
	case when r20_cod_tran = 'A+'
		then nvl(sum(r20_costo), 0)
		else nvl(sum(r20_costo), 0) * (-1)
	end costo
	from sermaco_gm@acgyede:rept020, sermaco_gm@acgyede:rept010
	where r20_compania  = 2
	  and r20_localidad = 6
	  and ((r20_cod_tran = 'A+' and r20_num_tran between 1 and 13)
	   or  (r20_cod_tran = 'A-' and r20_num_tran in(1, 3, 5, 6)))
	  and r10_compania  = r20_compania
	  and r10_codigo    = r20_item
	group by 1, 2, 3, 4
union
	select r20_localidad loc, r20_cod_tran tp, r20_item item,
		r10_marca marca, nvl(sum(r20_cant_ven), 0) cant,
		case when r20_cod_tran = 'A+'
			then nvl(sum(r20_costo), 0)
			else nvl(sum(r20_costo), 0) * (-1)
		end costo
		from sermaco_qm@acgyede:rept020, sermaco_qm@acgyede:rept010
		where r20_compania  = 2
		  and r20_localidad = 7
		  and r20_cod_tran  = 'A+'
		  and r20_num_tran between 1 and 25
		  and r10_compania  = r20_compania
		  and r10_codigo    = r20_item
		group by 1, 2, 3, 4
	into temp t1;
select loc loc1, marca, nvl(round(sum(cant * costo), 2), 0) total_loc1
	from t1
	group by 1, 2
	order by 1, 2;
select loc, tp, marca, nvl(round(sum(cant * costo), 2), 0) total_loc
	from t1
	group by 1, 2, 3
	into temp t2;
drop table t1;
select loc, marca, nvl(round(sum(total_loc), 2), 0) total_loc
	from t2
	group by 1, 2
	order by 1;
select loc, nvl(round(sum(total_loc), 2), 0) total_loc
	from t2
	group by 1
	order by 1;
drop table t2;