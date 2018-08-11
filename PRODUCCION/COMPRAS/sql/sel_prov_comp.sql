unload to "prov_mar05.txt" 
	select p01_num_doc, p01_nomprov, sum(c10_tot_compra - c10_flete -
		c10_tot_impto) val_neto, sum(c10_flete) flete,
		sum(c10_tot_impto) val_impto
		from ordt010, cxpt001
		where c10_compania   = 1
		  and c10_localidad  = 1
		  and c10_tipo_orden = 1
		  and c10_estado     = 'C'
		  and date(c10_fecha_fact)  between mdy(03,01,2005)
						and mdy(03,31,2005)
		  and p01_codprov    = c10_codprov
		  and p01_personeria = 'J'
		group by 1, 2
		order by 2;
