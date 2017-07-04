CREATE TEMP TABLE tmp_det
        (
		codcli			INTEGER,
		nomcli			VARCHAR(100,50),
                z20_localidad           SMALLINT,
                z20_tipo_doc            CHAR(2),
                num_doc                 VARCHAR(20),
                z20_fecha_emi           DATE,
                z20_fecha_vcto          DATE,
                z20_valor_cap           DECIMAL(12,2),
                z20_saldo_cap           DECIMAL(12,2),
                valor_ret               DECIMAL(12,2),
                cheq                    CHAR(1),
                z20_num_doc             CHAR(15),
                z20_dividendo           SMALLINT,
                r38_num_sri             CHAR(16),
                z20_cod_tran            CHAR(2),
                z20_num_tran            DECIMAL(15,0),
                num_r_sri               CHAR(16),
                r38_tipo_fuente         CHAR(2),
                num_fuente              INTEGER
        );

select z20_codcli codcli, z01_nomcli cliente
	FROM cxct020, cxct001
	WHERE z20_compania     = 1
	  AND z20_localidad    = 1
	  AND z20_areaneg      = 1
	  AND z20_moneda       = "DO"
	  AND z20_linea        = "ACERO"
	  AND z20_saldo_cap    > 0
	  AND z20_dividendo    = 1
	  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) >=
		EXTEND(DATE(TODAY - 46 UNITS DAY), YEAR TO MONTH)
	  AND NOT EXISTS
		(SELECT 1 FROM cajt014
			WHERE j14_compania  = z20_compania
			  AND j14_localidad = z20_localidad
			  AND j14_tipo_fue  = "PR"
			  AND j14_cod_tran  = z20_cod_tran
			  AND j14_num_tran  = z20_num_tran)
	  AND z01_codcli       = z20_codcli
union
select z20_codcli codcli, z01_nomcli cliente
	FROM cxct020, cxct001
	WHERE z20_compania     = 1
	  AND z20_localidad    = 1
	  AND z20_areaneg      = 1
	  AND z20_moneda       = "DO"
	  AND z20_linea        = "ACERO"
	  AND z20_saldo_cap    = 0
	  AND z20_dividendo    = 1
	  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) >=
		EXTEND(DATE(TODAY - 46 UNITS DAY), YEAR TO MONTH)
	  AND NOT EXISTS
		(SELECT 1 FROM cajt014
			WHERE j14_compania  = z20_compania
			  AND j14_localidad = z20_localidad
			  AND j14_tipo_fue  = "PR"
			  AND j14_cod_tran  = z20_cod_tran
			  AND j14_num_tran  = z20_num_tran)
	  AND z01_codcli       = z20_codcli
union
select j10_codcli codcli, j10_nomcli cliente
	FROM cajt010, cajt011
	WHERE j10_compania        =  1
	  AND j10_localidad       =  1
	  AND j10_tipo_fuente     = "PR"
	  AND j10_tipo_destino    = "FA"
	  AND EXTEND(j10_fecha_pro, YEAR TO MONTH) >=
		EXTEND(DATE(TODAY - 46 UNITS DAY), YEAR TO MONTH)
	  AND j11_compania        = j10_compania
	  AND j11_localidad       = j10_localidad
	  AND j11_tipo_fuente     = j10_tipo_fuente
	  AND j11_num_fuente      = j10_num_fuente
	  AND j11_codigo_pago    NOT IN
		(SELECT j01_codigo_pago
			FROM cajt001
			WHERE j01_compania  = j10_compania
			  AND j01_retencion = "S")
	  AND NOT EXISTS
		(SELECT 1 FROM cajt014
			WHERE j14_compania  = j10_compania
			  AND j14_localidad = j10_localidad
			  AND j14_tipo_fue  = "PR"
			  AND j14_cod_tran  = j10_tipo_destino
			  AND j14_num_tran  = j10_num_destino)
	into temp tmp_cli;

INSERT INTO tmp_det
	SELECT codcli, cliente, z20_localidad, z20_tipo_doc, TRIM(z20_num_doc)
		|| "-" || LPAD(z20_dividendo, 2, 0) num_doc, z20_fecha_emi,
		z20_fecha_vcto, z20_valor_cap, z20_saldo_cap, 0.00 valor_ret,
		"N" cheq, z20_num_doc, z20_dividendo, r38_num_sri,z20_cod_tran,
		z20_num_tran, r38_num_sri num_r_sri, r38_tipo_fuente, ""
		FROM cxct020, rept038, tmp_cli
		WHERE z20_compania     = 1
		  AND z20_localidad    = 1
		  AND z20_areaneg      = 1
		  AND z20_moneda       = "DO"
		  AND z20_linea        = "ACERO"
		  AND z20_saldo_cap    > 0
		  AND z20_dividendo    = 1
		  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) >=
			EXTEND(DATE(TODAY - 46 UNITS DAY), YEAR TO MONTH)
		  AND NOT EXISTS
			(SELECT 1 FROM cajt014
				WHERE j14_compania  = z20_compania
				  AND j14_localidad = z20_localidad
				  AND j14_tipo_fue  = "PR"
				  AND j14_cod_tran  = z20_cod_tran
				  AND j14_num_tran  = z20_num_tran)
		  AND NOT EXISTS
			(SELECT 1 FROM rept019
				WHERE r19_compania   = z20_compania
				  AND r19_localidad  = z20_localidad
				  AND r19_cod_tran  IN ("DF", "AF")
				  AND r19_tipo_dev   = z20_cod_tran
				  AND r19_num_dev    = z20_num_tran)
		  AND r38_compania     = z20_compania
		  AND r38_localidad    = z20_localidad
		  AND r38_tipo_doc    IN ("FA", "NV")
		  AND r38_tipo_fuente  = "PR"
		  AND r38_cod_tran     = z20_cod_tran
		  AND r38_num_tran     = z20_num_tran
		  AND codcli           = z20_codcli;

INSERT INTO tmp_det
	SELECT codcli, cliente, z20_localidad, z20_tipo_doc, TRIM(z20_num_doc)
		|| "-" || LPAD(z20_dividendo, 2, 0) num_doc, z20_fecha_emi,
		z20_fecha_vcto, z20_valor_cap, z20_saldo_cap, 0.00 valor_ret,
		"N" cheq, z20_num_doc, z20_dividendo, r38_num_sri,z20_cod_tran,
		z20_num_tran, r38_num_sri num_r_sri, r38_tipo_fuente, ""
		FROM cxct020, rept038, tmp_cli
		WHERE z20_compania     = 1
		  AND z20_localidad    = 1
		  AND z20_areaneg      = 1
		  AND z20_moneda       = "DO"
		  AND z20_linea        = "ACERO"
		  AND z20_saldo_cap    = 0
		  AND z20_dividendo    = 1
		  AND EXTEND(z20_fecha_emi, YEAR TO MONTH) >=
			EXTEND(DATE(TODAY - 46 UNITS DAY), YEAR TO MONTH)
		  AND NOT EXISTS
			(SELECT 1 FROM cajt014
				WHERE j14_compania  = z20_compania
				  AND j14_localidad = z20_localidad
				  AND j14_tipo_fue  = "PR"
				  AND j14_cod_tran  = z20_cod_tran
				  AND j14_num_tran  = z20_num_tran)
		  AND NOT EXISTS
			(SELECT 1 FROM rept019
				WHERE r19_compania   = z20_compania
				  AND r19_localidad  = z20_localidad
				  AND r19_cod_tran  IN ("DF", "AF")
				  AND r19_tipo_dev   = z20_cod_tran
				  AND r19_num_dev    = z20_num_tran)
		  AND r38_compania     = z20_compania
		  AND r38_localidad    = z20_localidad
		  AND r38_tipo_doc    IN ("FA", "NV")
		  AND r38_tipo_fuente  = "PR"
		  AND r38_cod_tran     = z20_cod_tran
		  AND r38_num_tran     = z20_num_tran
		  AND codcli           = z20_codcli;

INSERT INTO tmp_det
	SELECT UNIQUE codcli, cliente, j10_localidad z20_localidad, "FA"
		z20_tipo_doc, TRIM(j10_num_destino) || "-01" num_doc,
		DATE(j10_fecha_pro) z20_fecha_emi, "", j10_valor z20_valor_cap,
		0.00, 0.00 valor_ret, "N" cheq, j10_num_destino z20_num_doc, 1
		z20_dividendo, r38_num_sri, j10_tipo_destino z20_cod_tran,
		j10_num_destino z20_num_tran, r38_num_sri num_r_sri,
		j10_tipo_fuente, j10_num_fuente num_fuente
		FROM cajt010, cajt011, rept038, tmp_cli
		WHERE j10_compania        =  1
		  AND j10_localidad       =  1
		  AND j10_tipo_fuente     = "PR"
		  AND j10_tipo_destino    = "FA"
		  AND EXTEND(j10_fecha_pro, YEAR TO MONTH) >=
			EXTEND(DATE(TODAY - 46 UNITS DAY), YEAR TO MONTH)
		  AND r38_compania        = j10_compania
		  AND r38_localidad       = j10_localidad
		  AND r38_tipo_doc       IN ("FA", "NV")
		  AND r38_tipo_fuente     = j10_tipo_fuente
		  AND r38_cod_tran        = j10_tipo_destino
		  AND r38_num_tran        = j10_num_destino
		  AND j11_compania        = j10_compania
		  AND j11_localidad       = j10_localidad
		  AND j11_tipo_fuente     = j10_tipo_fuente
		  AND j11_num_fuente      = j10_num_fuente
		  AND j11_codigo_pago    NOT IN
			(SELECT j01_codigo_pago
				FROM cajt001
				WHERE j01_compania  = j10_compania
				  AND j01_retencion = "S")
		  AND NOT EXISTS
			(SELECT 1 FROM cajt014
				WHERE j14_compania  = j10_compania
				  AND j14_localidad = j10_localidad
				  AND j14_tipo_fue  = "PR"
				  AND j14_cod_tran  = j10_tipo_destino
				  AND j14_num_tran  = j10_num_destino)
		  AND codcli           = j10_codcli;

select count(unique codcli) tot_det from tmp_det;

select unique codcli, nomcli
	from tmp_det
	where z20_saldo_cap = 0
union
select unique codcli, nomcli
	from tmp_det
	where z20_saldo_cap > 0
	into temp t1;

select count(*) tot_t1 from t1;
select * from t1 order by 2;

drop table t1;
drop table tmp_cli;
drop table tmp_det;
