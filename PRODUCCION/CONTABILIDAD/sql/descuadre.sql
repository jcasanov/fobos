select b13_tipo_comp, b13_num_comp, sum(b13_valor_base)
  from ctbt012, ctbt013
  where b12_compania = b13_compania
    and b12_tipo_comp = b13_tipo_comp
    and b12_num_comp  = b13_num_comp
    and b12_estado <> 'E'
--    and month(b12_fec_proceso) = 9
    and year(b12_fec_proceso) = 2004
  group by 1,2
   having sum(b13_valor_base) <> 0
