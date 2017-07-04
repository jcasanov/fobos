select count(*) from rept025 a, cajt010 b
	where r25_compania    = 1
	  and r25_localidad   = 1
	  and j10_compania    = r25_compania
	  and j10_localidad   = r25_localidad
	  and j10_tipo_fuente = 'PR'
	  and j10_num_fuente  = r25_numprev;
select j10_usuario, count(*) cuantos
	from rept025 a, cajt010 b
	where r25_compania    = 1
	  and r25_localidad   = 1
	  and j10_compania    = r25_compania
	  and j10_localidad   = r25_localidad
	  and j10_tipo_fuente = 'PR'
	  and j10_num_fuente  = r25_numprev
	  and j10_valor       = 0
	group by 1
	order by 2 desc;
