select r31_ano, r31_mes, r31_bodega, r31_item, r31_stock
  from rept031
 where r31_compania = 1
   and r31_ano = 2008
   and r31_bodega = 'MA'
   and r31_item = 'KP20C'
 order by 1, 2, 3, 4
