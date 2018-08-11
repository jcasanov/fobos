SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS localidad,
	n30_cod_trab AS codigo,
        n30_nombres AS empleados,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_est_civil = "C" THEN "CASADO"
	     WHEN n30_est_civil = "S" THEN "SOLTERO"
	     WHEN n30_est_civil = "U" THEN "UNION LIBRE"
	     WHEN n30_est_civil = "V" THEN "VIUDO"
	     WHEN n30_est_civil = "D" THEN "DIVORCIADO"
	END AS est_civil,
        n31_tipo_carga AS tip_c,
        n31_cod_trab_e AS cod_ace,
        n31_nombres AS carga,
        n31_fecha_nacim AS fec_nacim,
        n31_secuencia AS orden,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM rolt030, OUTER rolt031
        WHERE n30_compania = 1
          AND n30_estado   = 'A'
          AND n31_compania = n30_compania
          AND n31_cod_trab = n30_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS localidad,
	n30_cod_trab AS codigo,
        n30_nombres AS empleados,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_est_civil = "C" THEN "CASADO"
	     WHEN n30_est_civil = "S" THEN "SOLTERO"
	     WHEN n30_est_civil = "U" THEN "UNION LIBRE"
	     WHEN n30_est_civil = "V" THEN "VIUDO"
	     WHEN n30_est_civil = "D" THEN "DIVORCIADO"
	END AS est_civil,
        n31_tipo_carga AS tip_c,
        n31_cod_trab_e AS cod_ace,
        n31_nombres AS carga,
        n31_fecha_nacim AS fec_nacim,
        n31_secuencia AS orden,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM rolt030, rolt031
        WHERE n30_compania         = 1
          AND n30_estado           = 'I'
          AND YEAR(n30_fecha_sal) >= 2013
          AND n31_compania         = n30_compania
          AND n31_cod_trab         = n30_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS localidad,
	n30_cod_trab AS codigo,
        n30_nombres AS empleados,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_est_civil = "C" THEN "CASADO"
	     WHEN n30_est_civil = "S" THEN "SOLTERO"
	     WHEN n30_est_civil = "U" THEN "UNION LIBRE"
	     WHEN n30_est_civil = "V" THEN "VIUDO"
	     WHEN n30_est_civil = "D" THEN "DIVORCIADO"
	END AS est_civil,
        n31_tipo_carga AS tip_c,
        n31_cod_trab_e AS cod_ace,
        n31_nombres AS carga,
        n31_fecha_nacim AS fec_nacim,
        n31_secuencia AS orden,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM acero_qm@idsuio01:rolt030, OUTER acero_qm@idsuio01:rolt031
        WHERE n30_compania = 1
          AND n30_estado   = 'A'
          AND n31_compania = n30_compania
          AND n31_cod_trab = n30_cod_trab
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS localidad,
	n30_cod_trab AS codigo,
        n30_nombres AS empleados,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_est_civil = "C" THEN "CASADO"
	     WHEN n30_est_civil = "S" THEN "SOLTERO"
	     WHEN n30_est_civil = "U" THEN "UNION LIBRE"
	     WHEN n30_est_civil = "V" THEN "VIUDO"
	     WHEN n30_est_civil = "D" THEN "DIVORCIADO"
	END AS est_civil,
        n31_tipo_carga AS tip_c,
        n31_cod_trab_e AS cod_ace,
        n31_nombres AS carga,
        n31_fecha_nacim AS fec_nacim,
        n31_secuencia AS orden,
        CASE WHEN n30_estado = 'A'
                THEN "ACTIVO"
                ELSE "INACTIVO"
        END AS estado
        FROM acero_qm@idsuio01:rolt030, acero_qm@idsuio01:rolt031
        WHERE n30_compania         = 1
          AND n30_estado           = 'I'
          AND YEAR(n30_fecha_sal) >= 2013
          AND n31_compania         = n30_compania
          AND n31_cod_trab         = n30_cod_trab
        ORDER BY 1 ASC, 4 ASC, 3 ASC;
