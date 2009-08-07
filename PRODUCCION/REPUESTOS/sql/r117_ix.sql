select * from rept117, rept020
 where r117_compania  = 1
   and r117_localidad = 1
   and r117_cod_tran  = 'IX'
   and r117_pedido    = 'KP-2000-09'
   and r20_compania   = r117_compania
   and r20_localidad  = r117_localidad
   and r20_cod_tran   = r117_cod_tran
   and r20_num_tran   = r117_num_tran
   and r20_item       = r117_item
