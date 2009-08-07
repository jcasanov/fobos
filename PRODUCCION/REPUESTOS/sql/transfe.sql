unload to "/tmp/stock_reserva"
select r20_num_tran transfe, r20_item, r10_nombre, r20_cant_ven
 from rept020, rept019, rept010
 where r20_compania = 1
   and r20_compania = r19_compania
   and r20_localidad= r19_localidad
   and r20_cod_tran = r19_cod_tran
   and r20_num_tran = r19_num_tran
   and r20_compania = r10_compania
   and r20_localidad= 1
   and r20_item     = r10_codigo
   and r20_cod_tran = 'TR'
   and DATE(r20_fecing)   < '01-01-2004'
   and r19_bodega_ori ='MA'
   and r19_bodega_dest='RR'
