select r20_cod_tran, r20_num_tran, r20_item, r10_nombre[1, 25], r20_cant_ven,
       r20_costo, (r20_cant_ven * r20_costo)
  from rept020, rept010
 where r20_compania  = 1
   and r20_localidad = 1
   and r20_cod_tran  = 'IM'
   and date(r20_fecing) between mdy(01, 01, 2006) and mdy(04, 19, 2006)
   and r10_compania = r20_compania
   and r10_codigo   = r20_item
ORDER BY 1, 2, 3
