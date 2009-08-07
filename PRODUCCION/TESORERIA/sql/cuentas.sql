select b13_num_comp, b13_cuenta from ctbt013
where b13_compania = 1
  and b13_tipo_comp = 'EG'
  and b13_num_comp in (select p24_num_contable from cxpt024
			where p24_compania = b13_compania
			  and p24_orden_pago = ?
			  and p24_num_contable is not null)
