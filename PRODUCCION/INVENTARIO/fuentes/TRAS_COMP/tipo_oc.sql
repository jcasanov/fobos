begin work;

	insert into gent050
		(g50_modulo, g50_nombre, g50_estado, g50_areaneg_def,
		 g50_usuario, g50_fecing)
		values ("CI", "COMPOSICION DE ITEMS", "A", "", "FOBOS",current);

	insert into ordt001
		(c01_tipo_orden, c01_nombre, c01_estado, c01_ing_bodega,
		 c01_bien_serv, c01_modulo, c01_porc_retf_b, c01_porc_retf_s,
		 c01_porc_reti_b, c01_porc_reti_s, c01_gendia_auto,
		 c01_aux_cont, c01_aux_ot_proc, c01_aux_ot_cost, c01_aux_ot_vta,
		 c01_aux_ot_dvta, c01_usuario, c01_fecing)
		select 0, "GASTOS MATERIALES EXTERNOS PARA COMPOSICION ITEMS",
			"A", a.c01_ing_bodega, a.c01_bien_serv, "CI",
			a.c01_porc_retf_b, a.c01_porc_retf_s, a.c01_porc_reti_b,
			a.c01_porc_reti_s, a.c01_gendia_auto, a.c01_aux_cont,
			a.c01_aux_ot_proc, a.c01_aux_ot_cost, a.c01_aux_ot_vta,
			a.c01_aux_ot_dvta, "FOBOS", current
			from ordt001 a
			where a.c01_tipo_orden = 3;

	insert into srit023
		(s23_compania, s23_tipo_orden, s23_sustento_sri, s23_secuencia,
		 s23_aux_cont, s23_tributa, s23_usuario, s23_fecing)
		select a.s23_compania,
			(select max(c01_tipo_orden)
				from ordt001),
			a.s23_sustento_sri, a.s23_secuencia, a.s23_aux_cont,
			a.s23_tributa, "FOBOS", current
			from srit023 a
			where a.s23_compania   in (1, 2)
			  and a.s23_tipo_orden = 3;

	insert into srit024
		(s24_compania, s24_codigo, s24_porcentaje_ice, s24_codigo_impto,
		 s24_tipo_orden, s24_aux_cont, s24_usuario, s24_fecing)
		select a.s24_compania, a.s24_codigo, a.s24_porcentaje_ice,
			a.s24_codigo_impto,
			(select max(c01_tipo_orden)
				from ordt001),
			a.s24_aux_cont, "FOBOS", current
			from srit024 a
			where a.s24_compania   in (1, 2)
			  and a.s24_tipo_orden = 3;

--rollback work;
commit work;
