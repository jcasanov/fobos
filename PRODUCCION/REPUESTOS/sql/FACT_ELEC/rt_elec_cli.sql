SELECT g01_razonsocial AS razonsocial, g02_numruc AS ruc,
 LPAD(g02_serie_cia, 3, 0) AS estab,
 LPAD(g02_serie_loc, 3, 0) AS ptoemi,
 LPAD(NVL(TRIM(j14_num_ret_sri[9, 21]), 0), 9, 0) AS secuencial,
 g02_direccion AS dirmatriz,
 TO_CHAR(j14_fecha_emi, "%d/%m/%Y") AS fechaemision,
 z01_direccion1 AS direstablecimiento,
 "5368" AS contribuyenteespecial,
 "SI" AS obligadocontabilidad,
 CASE WHEN z01_codcli =
 (SELECT r00_codcli_tal FROM rept000 WHERE r00_compania = j14_compania)
 THEN "07"
 ELSE (SELECT s03_codigo FROM srit003
	 WHERE s03_compania     = j14_compania
	   AND s03_cod_ident    = z01_tipo_doc_id
	   AND YEAR(s03_fecing) < 2007)
 END AS tipoidentificacio,
 j14_razon_social AS razonsocialcompra,
 CASE WHEN z01_codcli = (SELECT r00_codcli_tal
			 FROM rept000
			 WHERE r00_compania = j14_compania)
	 THEN "9999999999999"
	 ELSE j14_cedruc
 END AS identificacioncom,
 TO_CHAR(TODAY, "%m/%Y") AS periodofiscal,
 CASE WHEN j14_tipo_ret = "F" THEN 1 ELSE 2 END AS codigoiva,
 CASE WHEN j14_tipo_ret = "I"
	 THEN CASE WHEN j14_porc_ret = 30 THEN "1"
	           WHEN j14_porc_ret = 70 THEN "2"
	           WHEN j14_porc_ret = 100 THEN "3"
	 ELSE ""
	END
	 ELSE ""
 END AS codigoretencion,
 j14_base_imp AS baseimponible,
 j14_porc_ret AS porcentajereten,
 j14_valor_ret AS valorreten,
 "01" AS codsustento,
 j14_num_fact_sri[1, 3] || j14_num_fact_sri[5, 7] ||
 LPAD(TRIM(j14_num_fact_sri[9, 21]), 9, 0) AS numfacsri,
 TO_CHAR(j14_fec_emi_fact, "%d/%m/%Y") AS fecemifact,
 z02_email AS emailcli
 FROM cajt014, cajt010, cxct001, cxct002, gent002, gent001
 WHERE j14_compania    =           1
  AND j14_localidad   =      1
  AND j14_tipo_fuente = "OT"
   AND j14_num_fuente  =        3330
  AND j10_compania    = j14_compania
   AND j10_localidad   = j14_localidad
   AND j10_tipo_fuente = j14_tipo_fuente
   AND j10_num_fuente  = j14_num_fuente
   AND z02_compania    = j10_compania
   AND z02_localidad   = j10_localidad
   AND z02_codcli      = j10_codcli
   AND z01_codcli      = z02_codcli
   AND g02_compania    = z02_compania
   AND g02_localidad   = z02_localidad
   AND g01_compania    = g02_compania
