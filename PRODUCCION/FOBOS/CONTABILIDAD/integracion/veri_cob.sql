select j10_localidad, j10_tipo_destino, j10_num_destino, date(j10_fecha_pro),
	z40_codcli
	from cajt010, outer cxct040
	where j10_tipo_destino in ('PA','PG') and
		j10_compania      = z40_compania  and
		j10_localidad     = z40_localidad and
		j10_codcli        = z40_codcli    and
		j10_tipo_destino  = z40_tipo_doc  and
		j10_num_destino   = z40_num_doc
	order by 5
