unload to "nue_a10_qm_3.unl"
	select * from acero_qm@idsuio01:actt010
		where a10_compania    = 1
		  and a10_codigo_bien > 435
		order by 1, 2;
unload to "nue_a12_qm_3.unl"
	select * from acero_qm@idsuio01:actt012
		where a12_compania    = 1
		  and a12_codigo_tran = 'IN'
		  and a12_codigo_bien > 435
		order by 1, 2;
unload to "nue_a10_gm_3.unl"
	select * from acero_gm@idsgye01:actt010
		where a10_compania    = 1
		  and a10_codigo_bien > 317
		order by 1, 2;
unload to "nue_a12_gm_3.unl"
	select * from acero_gm@idsgye01:actt012
		where a12_compania    = 1
		  and a12_codigo_tran = 'IN'
		  and a12_codigo_bien > 317
		order by 1, 2;
