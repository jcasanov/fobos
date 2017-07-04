begin work;

	insert into rolt048
		(n48_compania, n48_ano_proceso, n48_mes_proceso, n48_cod_trab,
		 n48_estado, n48_moneda, n48_val_jub_pat, n48_paridad,
		 n48_tipo_pago, n48_bco_empresa, n48_cta_empresa,
		 n48_cta_trabaj, n48_usuario, n48_fecing)
		select n48_compania, 2010, 12, n48_cod_trab, "P", n48_moneda,
			n48_val_jub_pat, n48_paridad, "C", "", "", "", "FOBOS",
			extend(mdy(12, 01, 2010) + 1 units month - 1 units day,
				year to second)
			from rolt048
			where n48_compania    = 1
			  and n48_ano_proceso = 2011
			  and n48_mes_proceso = 3;

	insert into rolt048
		(n48_compania, n48_ano_proceso, n48_mes_proceso, n48_cod_trab,
		 n48_estado, n48_moneda, n48_val_jub_pat, n48_paridad,
		 n48_tipo_pago, n48_bco_empresa, n48_cta_empresa,
		 n48_cta_trabaj, n48_usuario, n48_fecing)
		select n48_compania, 2011, 01, n48_cod_trab, "P", n48_moneda,
			n48_val_jub_pat, n48_paridad, "C", "", "", "", "FOBOS",
			extend(mdy(12, 01, 2010) + 1 units month - 1 units day,
				year to second)
			from rolt048
			where n48_compania    = 1
			  and n48_ano_proceso = 2011
			  and n48_mes_proceso = 3;

	insert into rolt048
		(n48_compania, n48_ano_proceso, n48_mes_proceso, n48_cod_trab,
		 n48_estado, n48_moneda, n48_val_jub_pat, n48_paridad,
		 n48_tipo_pago, n48_bco_empresa, n48_cta_empresa,
		 n48_cta_trabaj, n48_usuario, n48_fecing)
		select n48_compania, 2011, 02, n48_cod_trab, "P", n48_moneda,
			n48_val_jub_pat, n48_paridad, "C", "", "", "", "FOBOS",
			extend(mdy(12, 01, 2010) + 1 units month - 1 units day,
				year to second)
			from rolt048
			where n48_compania    = 1
			  and n48_ano_proceso = 2011
			  and n48_mes_proceso = 3;

--rollback work;
commit work;
