begin work;

select * from rept021
	where r21_compania  = 1
	  and r21_localidad = 1
	  and r21_cod_tran  = 'FA'
	  and r21_num_tran  in (19953);

select * from rept023
	where r23_compania  = 1
	  and r23_localidad = 1
	  and r23_cod_tran  = 'FA'
	  and r23_num_tran  in (19953);

select * from rept019
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r19_num_tran  in (19953);

select * from cajt010
	where j10_compania     = 1
	  and j10_localidad    = 1
	  and j10_tipo_fuente  = 'PR'
	  and j10_tipo_destino = 'FA'
	  and j10_num_destino  in (19953);

select date(r20_fecing) fecha, r20_bodega, r20_linea, r20_rotacion,
	nvl(sum((r20_cant_ven * r20_precio) - r20_val_descto), 0) precio,
	nvl(sum(r20_costo * r20_cant_ven), 0) costo
	from rept020
	where r20_compania  = 1
	  and r20_localidad = 1
	  and r20_cod_tran  = 'FA'
	  and r20_num_tran  in (19953)
	group by 1, 2, 3, 4
	into temp t1;

update rept060 set r60_precio = r60_precio -
				(select precio from t1
				 where fecha        = r60_fecha
				   and r20_bodega   = r60_bodega
				   and r20_linea    = r60_linea
				   and r20_rotacion = r60_rotacion),
		   r60_costo  = r60_costo -
				(select costo from t1
				 where fecha        = r60_fecha
				   and r20_bodega   = r60_bodega
				   and r20_linea    = r60_linea
				   and r20_rotacion = r60_rotacion)
	where r60_compania = 1
	  and r60_vendedor = 15
	  and exists (select fecha, r20_bodega, r20_linea, r20_rotacion
			from t1
			where fecha        = r60_fecha
			  and r20_bodega   = r60_bodega
			  and r20_linea    = r60_linea
			  and r20_rotacion = r60_rotacion);

update rept060 set r60_precio = r60_precio +
				(select precio from t1
				 where fecha        = r60_fecha
				   and r20_bodega   = r60_bodega
				   and r20_linea    = r60_linea
				   and r20_rotacion = r60_rotacion),
		   r60_costo  = r60_costo +
				(select costo from t1
				 where fecha        = r60_fecha
				   and r20_bodega   = r60_bodega
				   and r20_linea    = r60_linea
				   and r20_rotacion = r60_rotacion)
	where r60_compania = 1
	  and r60_vendedor = 8
	  and exists (select fecha, r20_bodega, r20_linea, r20_rotacion
			from t1
			where fecha        = r60_fecha
			  and r20_bodega   = r60_bodega
			  and r20_linea    = r60_linea
			  and r20_rotacion = r60_rotacion);

drop table t1;

update rept021 set r21_vendedor = 8,
		   r21_usuario  = 'JENNGARC'
	where r21_compania  = 1
	  and r21_localidad = 1
	  and r21_cod_tran  = 'FA'
	  and r21_num_tran  in (19953);

update rept023 set r23_vendedor = 8,
		   r23_usuario  = 'JENNGARC'
	where r23_compania  = 1
	  and r23_localidad = 1
	  and r23_cod_tran  = 'FA'
	  and r23_num_tran  in (19953);

update rept019 set r19_vendedor = 8
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r19_num_tran  in (19953);

--
-- SOLO si la forma de pago es en efectivo hacer este update.
update cajt010 set j10_usuario  = 'JENNGARC'
	where j10_compania     = 1
	  and j10_localidad    = 1
	  and j10_tipo_fuente  = 'PR'
	  and j10_tipo_destino = 'FA'
	  and j10_num_destino  in (19953);
--
--

select * from rept021
	where r21_compania  = 1
	  and r21_localidad = 1
	  and r21_cod_tran  = 'FA'
	  and r21_num_tran  in (19953);

select * from rept023
	where r23_compania  = 1
	  and r23_localidad = 1
	  and r23_cod_tran  = 'FA'
	  and r23_num_tran  in (19953);

select * from rept019
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r19_num_tran  in (19953);

select * from cajt010
	where j10_compania     = 1
	  and j10_localidad    = 1
	  and j10_tipo_fuente  = 'PR'
	  and j10_tipo_destino = 'FA'
	  and j10_num_destino  in (19953);

commit work;
