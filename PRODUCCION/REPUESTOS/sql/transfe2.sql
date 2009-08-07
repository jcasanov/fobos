select month(r19_fecing) as mes, r20_num_tran transfe, r20_item, 
       SUBSTR(r10_nombre,1,12),  r20_cant_ven 
 from rept020, rept019, rept010
 where r19_compania  = 1
   and r19_localidad = 2
   and r19_cod_tran = 'TR'
   and r19_bodega_ori ='MA'
   and r19_bodega_dest='QT'
   and DATE(r19_fecing) BETWEEN MDY(1, 1, 2004) AND MDY(9, 30, 2004)
   and r20_compania = r19_compania
   and r20_localidad= r19_localidad
   and r20_cod_tran = r19_cod_tran
   and r20_num_tran = r19_num_tran
   and r10_compania = r20_compania
   and r10_codigo   = r20_item  
 order by 1, 3
