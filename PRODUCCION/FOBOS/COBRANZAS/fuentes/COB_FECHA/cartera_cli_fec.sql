select z22_referencia, z22_fecha_emi, z22_total_cap, z22_total_int,
	z22_total_mora, cxct023.*
	from cxct023, cxct022
	where z23_compania  = 1
	  and z23_localidad = 1
	  and z23_codcli    = 2844
	  and z23_tipo_doc  = 'FA'
	  and z23_num_doc   = 186
	  and z22_compania  = z23_compania
	  and z22_localidad = z23_localidad
	  and z22_codcli    = z23_codcli
	  and z22_tipo_trn  = z23_tipo_trn
	  and z22_num_trn   = z23_num_trn
	order by z22_fecha_emi;
