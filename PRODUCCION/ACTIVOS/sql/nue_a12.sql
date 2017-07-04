unload to "nue_a12_gm.unl"
	select * from acero_gm@idsgye01:actt012
		where a12_compania     = 1
		  and a12_codigo_bien >= 313
		  and a12_codigo_tran  = "IN"
		order by 1, 2;
unload to "nue_a12_qm.unl"
	select * from acero_qm@idsuio01:actt012
		where a12_compania     = 1
		  and a12_codigo_bien in (430, 431, 432, 433)
		  and a12_codigo_tran  = "IN"
		order by 1, 2;
