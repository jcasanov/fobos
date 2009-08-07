select  r17_pedido, r17_item, r10_nombre, r17_peso
 from rept017, rept010
  where r17_compania = r10_compania
   and r17_compania  = 1
   and r17_item = r10_codigo
   and r17_pedido = 'KP-227-02'
