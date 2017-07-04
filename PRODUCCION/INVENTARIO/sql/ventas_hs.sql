select r20_localidad, r20_cod_tran, r20_num_tran, r19_nomcli,
	extend(r20_fecing, year to month) fecha,
	r20_cant_ven, r20_item, r20_cant_ven * r20_precio -
	r20_val_descto valor_neto
	from rept019, rept020
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran     in ('FA', 'DF', 'AF')
	  and date(r19_fecing) between mdy(01,01,2003) and mdy(04,12,2005)
	  and r20_compania     = r19_compania
	  and r20_localidad    = r19_localidad
	  and r20_cod_tran     = r19_cod_tran
	  and r20_num_tran     = r19_num_tran
	into temp t1;
insert into t1
	select r20_localidad, r20_cod_tran, r20_num_tran, r19_nomcli,
		extend(r20_fecing, year to month) fecha,
		r20_cant_ven, r20_item, r20_cant_ven * r20_precio -
		r20_val_descto valor_neto
		from acero_gc:rept019, acero_gc:rept020
		where r19_compania     = 1
		  and r19_localidad    = 2
		  and r19_cod_tran     in ('FA', 'DF', 'AF')
		  and date(r19_fecing) between mdy(01,01,2003)
					   and mdy(04,12,2005)
		  and r20_compania     = r19_compania
		  and r20_localidad    = r19_localidad
		  and r20_cod_tran     = r19_cod_tran
		  and r20_num_tran     = r19_num_tran;
insert into t1
	select r20_localidad, r20_cod_tran, r20_num_tran, r19_nomcli,
		extend(r20_fecing, year to month) fecha,
		r20_cant_ven, r20_item, r20_cant_ven * r20_precio -
		r20_val_descto valor_neto
		from acero_qm:rept019, acero_qm:rept020
		where r19_compania     = 1
		  and r19_localidad    in (3,5)
		  and r19_cod_tran     in ('FA', 'DF', 'AF')
		  and date(r19_fecing) between mdy(01,01,2003)
					   and mdy(04,12,2005)
		  and r20_compania     = r19_compania
		  and r20_localidad    = r19_localidad
		  and r20_cod_tran     = r19_cod_tran
		  and r20_num_tran     = r19_num_tran;
insert into t1
	select r20_localidad, r20_cod_tran, r20_num_tran, r19_nomcli,
		extend(r20_fecing, year to month) fecha,
		r20_cant_ven, r20_item, r20_cant_ven * r20_precio -
		r20_val_descto valor_neto
		from acero_qs:rept019, acero_qs:rept020
		where r19_compania     = 1
		  and r19_localidad    = 4
		  and r19_cod_tran     in ('FA', 'DF', 'AF')
		  and date(r19_fecing) between mdy(01,01,2003)
					   and mdy(04,12,2005)
		  and r20_compania     = r19_compania
		  and r20_localidad    = r19_localidad
		  and r20_cod_tran     = r19_cod_tran
		  and r20_num_tran     = r19_num_tran;
update t1 set valor_neto = valor_neto * (-1)
	where r20_cod_tran in ('DF', 'AF');
select t1.*, r73_desc_marca marca
	from rept010, rept073, t1
	where r10_compania   = 1
	  and r10_marca     in ('MARKGR', 'MARKPE', 'GRUNDF')
	  and r73_compania   = r10_compania
	  and r73_marca      = r10_marca
	  and r20_item       = r10_codigo
	into temp t2;
drop table t1;
select r19_nomcli, fecha, marca, nvl(sum(r20_cant_ven), 0) cantidad,
	nvl(sum(valor_neto), 0) total
	from t2
	group by 1, 2, 3
	into temp t3;
drop table t2;
select count(*) hay_tot from t3;
unload to "ventas_hs.txt" select * from t3 order by 1 asc, 2 asc;
select * from t3 order by 1 asc, 2 asc;
drop table t3;
