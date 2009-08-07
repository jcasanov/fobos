unload  to '/tmp/facturas_taller'
select t23_nom_cliente, ' ' numero, date(t23_fec_factura), t23_tot_neto
	from talt023
	where t23_compania  = 1
  	  and t23_localidad = 1
	  and t23_estado = 'F'
	  and date(t23_fec_factura) between mdy(07, 01, 2003)
					and mdy(12, 31, 2003)
	order by 3
