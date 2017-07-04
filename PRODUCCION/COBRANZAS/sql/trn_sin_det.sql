select z22_localidad as loc,
	z22_codcli as cli,
	z01_nomcli[1, 30] as nom,
	z22_tipo_trn as tp,
	z22_num_trn as num,
	date(z22_fecha_emi) as fecpro
	from cxct022, cxct001
	where z22_compania = 1
	  and z01_codcli   = z22_codcli
	  and not exists
		(select 1 from cxct023
			where z23_compania  = z22_compania
			  and z23_localidad = z22_localidad
			  and z23_codcli    = z22_codcli
			  and z23_tipo_trn  = z22_tipo_trn
			  and z23_num_trn   = z22_num_trn)
	order by 6 desc;
