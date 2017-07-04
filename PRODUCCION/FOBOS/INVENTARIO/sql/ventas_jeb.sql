select r20_cod_tran, r20_num_tran, extend(r20_fecing, year to month) fecha,
	r20_item, r20_cant_ven * r20_precio - r20_val_descto valor_neto
	from rept020
	where r20_compania   = 1
	  and r20_localidad  = 1
	  and r20_cod_tran  in ('FA', 'DF', 'AF')
	  and date(r20_fecing) between mdy(01,01,2005) and mdy(03,31,2005)
	into temp t1;
insert into t1
	select r20_cod_tran, r20_num_tran, extend(r20_fecing, year to month)
		fecha, r20_item, r20_cant_ven * r20_precio - r20_val_descto
		valor_neto
		from acero_gc:rept020
		where r20_compania   = 1
		  and r20_localidad  = 2
		  and r20_cod_tran  in ('FA', 'DF', 'AF')
		  and date(r20_fecing) between mdy(01,01,2005)
					   and mdy(03,31,2005);
update t1 set valor_neto = valor_neto * (-1)
	where r20_cod_tran in ('DF', 'AF');
select t1.*, r73_desc_marca r10_marca
	from rept010, rept073, t1
	where r10_compania = 1
	  and r10_marca   in ('GORMAN', 'GRUNDF', 'MARKPE', 'MARKGR', 'GRUNDF',
				'MYERS')
	  and r73_compania = r10_compania
	  and r73_marca    = r10_marca
	  and r20_item     = r10_codigo
	into temp t2;
drop table t1;
select fecha, r10_marca, nvl(sum(valor_neto), 0) total
	from t2
	group by 1, 2
	into temp t3;
drop table t2;
select * from t3 order by 1 asc, 2 asc;
select r10_marca, nvl(sum(total), 0) total_mar
	from t3
	group by 1
	order by 1 asc, 2 asc;
drop table t3;
