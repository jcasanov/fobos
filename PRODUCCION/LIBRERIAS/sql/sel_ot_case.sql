select t23_orden, case when t23_estado = 'A' or t23_estado = 'C'
			then 'proforma'
			when t23_estado = 'F' or t23_estado = 'D'
			then 'factura'
			else 'cero'
			end case
	from talt023
	where t23_compania  = 1
	  and t23_localidad = 1
	order by 1 desc;
