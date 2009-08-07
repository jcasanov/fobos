select c13_numero_oc, c10_estado, c13_num_ret, p28_num_ret
	from ordt010, ordt013, cxpt028
	where c10_estado in ('C','E') and c10_compania = c13_compania and
		c10_localidad = c13_localidad and
		c10_numero_oc = c13_numero_oc and
		c13_compania = p28_compania and
		c13_localidad = p28_localidad and
		c13_factura   = p28_num_doc and
		c10_codprov   = p28_codprov and
		p28_tipo_doc  = 'FA'
