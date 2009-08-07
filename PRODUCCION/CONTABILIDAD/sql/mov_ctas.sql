unload to 'mov_ctas2.txt'
select b13_cuenta, b13_tipo_comp, b13_num_comp, b13_fec_proceso,
	   b12_glosa, b13_glosa, b13_valor_base
  from ctbt013, ctbt012
  where b13_compania = 1
    and b13_cuenta[1,1] in ('5','6')
{
    and b13_cuenta   in  ('51010101001',
                          '11030102001',
                          '11030102002',
                          '11030102003',
                          '11030132001')
}
    and b13_fec_proceso between mdy(01,01,2005) and mdy(09,30,2005)
    and b13_compania  = b12_compania
    and b13_tipo_comp = b12_tipo_comp
    and b13_num_comp  = b12_num_comp
    and b12_estado <> 'E'
	order by 1, 4
