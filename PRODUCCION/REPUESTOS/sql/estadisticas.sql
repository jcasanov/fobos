   unload to '/tmp/xx'
 select r12_item ITEM, SUBSTR(r10_nombre,1,15) DESCRIPCION,
                       SUBSTR(r19_nomcli,1,10),
--MAX(r12_fecha),
  SUM(r12_uni_venta - r12_uni_dev) UNIDADES,
  SUM(r12_val_venta - r12_val_dev) VALOR
  from rept012, rept010, rept019, rept020
 where r12_compania = 1
   and r12_compania = r10_compania
   and r12_item = r10_codigo
   and r12_compania = r19_compania
   and r19_compania = r20_compania
   and r19_localidad= r20_localidad
   and r19_cod_tran = r20_cod_tran
   and r19_num_tran = r20_num_tran
   and r12_bodega = 'MA'
   and r12_val_dev =  0
   and r12_fecha BETWEEN  '01-01-2002' AND '12-31-2002'
   and r12_item = r20_item
   GROUP BY 1,2,3
   order by 1
