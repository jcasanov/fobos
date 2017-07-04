unload to "nue_a10_gm.unl"
	select * from acero_gm@idsgye01:actt010
		where a10_compania     = 1
		  and a10_codigo_bien >= 313
		order by 1, 2;
unload to "nue_a10_qm.unl"
	select * from acero_qm@idsuio01:actt010
		where a10_compania     = 1
		  and a10_codigo_bien in (430, 431, 432, 433)
		order by 1, 2;
