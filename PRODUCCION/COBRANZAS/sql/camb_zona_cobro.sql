SELECT r19_codcli AS codigo,
	r19_nomcli AS cliente,
	r01_nombres AS vendedor
	FROM rept019, rept001, cxct001
	WHERE r19_compania  = 1
	  AND r19_localidad = 1
	  AND r19_cod_tran  = "FA"
	  AND r19_cont_cred = "R"
	  AND r01_compania  = r19_compania
	  AND r01_codigo    = r19_vendedor
	  AND z01_codcli    = r19_codcli
	GROUP BY 1, 2, 3
	into temp t1;

begin work;

	update cxct002
		set z02_zona_cobro = null
		where 1 = 1;

	update cxct002
		set z02_zona_cobro = 4
		where z02_compania = 1
		  and z02_codcli   in (select codigo from t1);

commit work;

drop table t1;
