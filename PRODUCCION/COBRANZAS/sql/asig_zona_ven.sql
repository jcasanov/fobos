select r19_codcli as codcli,
	r19_nomcli as nomcli,
	r01_nombres[1, 30] as vend,
	count(r19_codcli) as cuantos
	from rept019, rept001
	where r19_compania   = 1
	  and r19_localidad  = 1
	  and r19_cod_tran  in ("FA", "DF", "AF")
	  and r19_codcli    is not null
	  and r19_codcli    <> 99
	  and r19_vendedor  in (25, 70, 69, 58, 8, 68, 63, 10, 37, 36, 72, 75,
				14, 15, 49, 17, 18, 41)
	  and r01_compania   = r19_compania
	  and r01_codigo     = r19_vendedor
	group by 1, 2, 3
	having count(r19_codcli) = 1;
