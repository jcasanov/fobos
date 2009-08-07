select sum(r12_uni_venta),
       sum(r12_uni_dev),
       sum(r12_uni_deman),
       sum(r12_uni_perdi),
       sum(r12_val_venta),
       sum(r12_val_dev)
  from rept012
  where month(r12_fecha) = 2

