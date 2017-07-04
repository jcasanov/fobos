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
select t1.*, r70_desc_sub linea
	from rept010, rept070, t1
	where r10_compania   = 1
	  and r10_linea      = '2'
	  and r10_sub_linea in ('22', '23', '26')
	  and r70_compania   = r10_compania
	  and r70_linea      = r10_linea
	  and r70_sub_linea  = r10_sub_linea
	  and r20_item       = r10_codigo
	into temp t2;
drop table t1;
select fecha, linea, nvl(sum(valor_neto), 0) total
	from t2
	group by 1, 2
	order by 1 asc, 2 asc;
select linea, r20_cod_tran, nvl(sum(valor_neto), 0) total_linea
	from t2
	group by 1, 2
	order by 1 asc, 2 desc, 3 asc;
select linea, nvl(sum(valor_neto), 0) total_linea
	from t2
	group by 1
	order by 1 asc, 2 asc;
drop table t2;
