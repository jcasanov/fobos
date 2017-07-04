select p22_localidad as loc,
	p22_codprov as prov,
	p01_nomprov[1, 30] as nom,
	p22_tipo_trn as tp,
	p22_num_trn as num,
	date(p22_fecha_emi) as fecpro
	from cxpt022, cxpt001
	where p22_compania = 1
	  and p01_codprov   = p22_codprov
	  and not exists
		(select 1 from cxpt023
			where p23_compania  = p22_compania
			  and p23_localidad = p22_localidad
			  and p23_codprov   = p22_codprov
			  and p23_tipo_trn  = p22_tipo_trn
			  and p23_num_trn   = p22_num_trn)
	order by 6 desc;
