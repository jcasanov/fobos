select b10_cuenta, b10_descripcion[1,20],
      (SELECT NVL(SUM(b13_valor_base), 0)
         FROM ctbt012, ctbt013
        WHERE b12_compania     = b10_compania
          AND b12_estado       <> 'E'
          AND b12_moneda       = 'DO'
          AND b13_compania     = b12_compania
          AND b13_tipo_comp    = b12_tipo_comp
          AND b13_num_comp     = b12_num_comp
          AND b13_cuenta       = b10_cuenta
          AND b13_fec_proceso BETWEEN mdy(01,01,2005) AND today
          AND b13_valor_base  >= 0) mov_neto_db,
	  (SELECT NVL(SUM(b13_valor_base), 0)
         FROM ctbt012, ctbt013
        WHERE b12_compania     = b10_compania
          AND b12_estado      <> 'E'
          AND b12_moneda       = 'DO'
          AND b13_compania     = b12_compania
          AND b13_tipo_comp    = b12_tipo_comp
          AND b13_num_comp     = b12_num_comp
          AND b13_cuenta       = b10_cuenta
          AND b13_fec_proceso BETWEEN mdy(01,01,2005) AND today
          AND b13_valor_base   < 0) mov_neto_cr
  from ctbt010
 where b10_compania   = 1
   and b10_cuenta       between '41010101001' and '41010101004'
   and b10_estado  = 'A'
 group by 1, 2, 3, 4  order by 1;
