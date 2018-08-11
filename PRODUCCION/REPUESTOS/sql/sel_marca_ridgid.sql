select r21_compania, r21_localidad, r21_numprof, r21_fecing
	from acero_gm:rept021
	where r21_compania     = 1
	  and r21_localidad    = 1
	  and r21_cod_tran     is null
	  and r21_num_ot       is null
	  and r21_num_presup   is null
	  and date(r21_fecing) between mdy(01,15,2005) and mdy(02,10,2005)
	into temp t1;
insert into t1
	select r21_compania, r21_localidad, r21_numprof, r21_fecing
		from acero_gc:rept021
		where r21_compania     = 1
		  and r21_localidad    = 2
		  and r21_cod_tran     is null
		  and r21_num_ot       is null
		  and r21_num_presup   is null
		  and date(r21_fecing) between mdy(01,15,2005)
					   and mdy(02,10,2005);
insert into t1
	select r21_compania, r21_localidad, r21_numprof, r21_fecing
		from acero_qm:rept021
		where r21_compania     = 1
		  and r21_localidad    in (3, 5)
		  and r21_cod_tran     is null
		  and r21_num_ot       is null
		  and r21_num_presup   is null
		  and date(r21_fecing) between mdy(01,15,2005)
					   and mdy(02,10,2005);
insert into t1
	select r21_compania, r21_localidad, r21_numprof, r21_fecing
		from acero_qs:rept021
		where r21_compania     = 1
		  and r21_localidad    = 4
		  and r21_cod_tran     is null
		  and r21_num_ot       is null
		  and r21_num_presup   is null
		  and date(r21_fecing) between mdy(01,15,2005)
					   and mdy(02,10,2005);
select r21_fecing, r21_localidad, r22_numprof, r22_item, r22_cantidad,
	r22_porc_descto, r22_precio, r10_marca, r10_linea, r10_sub_linea,
	r10_cod_grupo, r10_cod_clase,
	sum((r22_precio * r22_cantidad) - r22_val_descto) valor
	from t1, acero_gm:rept022, acero_gm:rept010
	where r21_localidad    = 1
	  and r22_compania     = r21_compania
	  and r22_localidad    = r21_localidad
	  and r22_numprof      = r21_numprof
	  and r10_compania     = r22_compania
	  and r10_codigo       = r22_item
	  and r10_marca        = 'RIDGID'
	group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	into temp t2;
insert into t2
	select r21_fecing, r21_localidad, r22_numprof, r22_item, r22_cantidad,
		r22_porc_descto, r22_precio, r10_marca, r10_linea,
		r10_sub_linea, r10_cod_grupo, r10_cod_clase,
		sum((r22_precio * r22_cantidad) - r22_val_descto) valor
		from t1, acero_gc:rept022, acero_gc:rept010
		where r21_localidad    = 2
		  and r22_compania     = r21_compania
		  and r22_localidad    = r21_localidad
		  and r22_numprof      = r21_numprof
		  and r10_compania     = r22_compania
		  and r10_codigo       = r22_item
		  and r10_marca        = 'RIDGID'
		group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
insert into t2
	select r21_fecing, r21_localidad, r22_numprof, r22_item, r22_cantidad,
		r22_porc_descto, r22_precio, r10_marca, r10_linea,
		r10_sub_linea, r10_cod_grupo, r10_cod_clase,
		sum((r22_precio * r22_cantidad) - r22_val_descto) valor
		from t1, acero_qm:rept022, acero_qm:rept010
		where r21_localidad    in (3, 5)
		  and r22_compania     = r21_compania
		  and r22_localidad    = r21_localidad
		  and r22_numprof      = r21_numprof
		  and r10_compania     = r22_compania
		  and r10_codigo       = r22_item
		  and r10_marca        = 'RIDGID'
		group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
insert into t2
	select r21_fecing, r21_localidad, r22_numprof, r22_item, r22_cantidad,
		r22_porc_descto, r22_precio, r10_marca, r10_linea,
		r10_sub_linea, r10_cod_grupo, r10_cod_clase,
		sum((r22_precio * r22_cantidad) - r22_val_descto) valor
		from t1, acero_qs:rept022, acero_qs:rept010
		where r21_localidad    = 4
		  and r22_compania     = r21_compania
		  and r22_localidad    = r21_localidad
		  and r22_numprof      = r21_numprof
		  and r10_compania     = r22_compania
		  and r10_codigo       = r22_item
		  and r10_marca        = 'RIDGID'
		group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
drop table t1;
select sum(valor) tot_valor from t2;
drop table t2;
{
select r21_fecing, r21_localidad, r22_numprof, r22_item, r22_cantidad,
	r22_porc_descto, r22_precio, r72_desc_clase, r10_nombre, r73_desc_marca,
	r01_nombres, valor
	from t2, rept072, rept073 
}
