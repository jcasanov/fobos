SELECT b13_cuenta, b10_descripcion[1,20],
	NVL(SUM(b13_valor_base), 0) mov_neto_db, 0 mov_neto_cr
        FROM ctbt012, ctbt013, ctbt010
        WHERE b12_compania     = 1
          AND b12_estado      <> 'E'
          AND b12_moneda       = 'DO'
          AND b13_compania     = b12_compania
          AND b13_tipo_comp    = b12_tipo_comp
          AND b13_num_comp     = b12_num_comp
          AND b13_cuenta      between '41010101001' and '41010101004'
          AND b13_fec_proceso BETWEEN mdy(01,01,2005) AND today
          AND b13_valor_base  >= 0
	  and b10_compania     = b13_compania
	  and b10_cuenta       = b13_cuenta
        group by 1, 2
union all
SELECT b13_cuenta, b10_descripcion[1,20], 0 mov_neto_db,
	NVL(SUM(b13_valor_base), 0) mov_neto_cr
        FROM ctbt012, ctbt013, ctbt010
        WHERE b12_compania     = 1
          AND b12_estado      <> 'E'
          AND b12_moneda       = 'DO'
          AND b13_compania     = b12_compania
          AND b13_tipo_comp    = b12_tipo_comp
          AND b13_num_comp     = b12_num_comp
          AND b13_cuenta      between '41010101001' and '41010101004'
          AND b13_fec_proceso BETWEEN mdy(01,01,2005) AND today
          AND b13_valor_base   < 0
	  and b10_compania     = b13_compania
	  and b10_cuenta       = b13_cuenta
        group by 1, 2
	order by 1;
