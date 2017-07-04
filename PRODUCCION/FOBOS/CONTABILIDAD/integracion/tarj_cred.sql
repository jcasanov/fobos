select g10_nombre, g10_codcobr, z02_aux_clte_mb
	from gent010, cxct002
	where g10_codcobr = z02_codcli
