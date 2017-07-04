begin work;

	update actt010
		set a10_cod_depto = 22
		where a10_compania   = 1
		  and a10_estado    in ("S", "D", "A")
		  and a10_grupo_act  = 1
		  and a10_cod_depto <> 22;

	update actt010
		set a10_cod_depto = 23
		where a10_compania   = 1
		  and a10_estado    in ("S", "D", "A")
		  and a10_grupo_act  = 2
		  and a10_cod_depto <> 23;

	update actt010
		set a10_cod_depto = 24
		where a10_compania   = 1
		  and a10_estado    in ("S", "D", "A")
		  and a10_grupo_act  = 3
		  and a10_cod_depto <> 24;

	update actt010
		set a10_cod_depto = 27
		where a10_compania   = 1
		  and a10_estado    in ("S", "D", "A")
		  and a10_grupo_act  = 4
		  and a10_cod_depto <> 27;

	update actt010
		set a10_cod_depto = 25
		where a10_compania   = 1
		  and a10_estado    in ("S", "D", "A")
		  and a10_grupo_act  = 5
		  and a10_cod_depto <> 25;

	update actt010
		set a10_cod_depto = 26
		where a10_compania   = 1
		  and a10_estado    in ("S", "D", "A")
		  and a10_grupo_act  = 6
		  and a10_cod_depto <> 26;

	update actt010
		set a10_cod_depto = 28
		where a10_compania   = 1
		  and a10_estado    in ("S", "D", "A")
		  and a10_grupo_act  = 7
		  and a10_cod_depto <> 28;

commit work;
