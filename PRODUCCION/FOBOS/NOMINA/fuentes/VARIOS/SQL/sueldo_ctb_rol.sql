--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

SELECT EXTEND(b12_fec_proceso, YEAR TO MONTH) AS fecha, b13_cuenta AS cuenta,
	b10_descripcion AS nombre,NVL(ROUND(SUM(b13_valor_base), 2),0) AS valor
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania           = 1
	  AND b12_estado            <> 'E'
	  AND YEAR(b12_fec_proceso)  = 2008
	  AND b13_compania           = b12_compania
	  AND b13_tipo_comp          = b12_tipo_comp
	  AND b13_num_comp           = b12_num_comp
	  AND (b13_cuenta           MATCHES '510101*'
	  AND  b13_cuenta           NOT MATCHES '51010104*')
	  AND b13_valor_base        <> 0
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3
	INTO TEMP tmp_ctb;
SELECT cuenta, nombre, NVL(ROUND(SUM(valor), 2), 0) AS total
	FROM tmp_ctb
	GROUP BY 1, 2
	ORDER BY 1;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

SELECT 'RO' cd,EXTEND(MDY(n32_mes_proceso, 01, n32_ano_proceso), YEAR TO MONTH)
	AS fec_rol, n32_cod_depto AS cod_dep, g34_nombre AS departamento,
	NVL(ROUND(SUM(n33_valor), 2), 0) AS valor_rol
	{--
	NVL(ROUND(SUM(CASE WHEN (n33_cod_rubro NOT IN
				(SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident IN ('VV'))
				AND n32_cod_trab NOT IN
				(SELECT UNIQUE n47_cod_trab
				FROM rolt047, rolt039
				WHERE n47_compania    = n32_compania
				  AND n47_cod_liqrol  = n32_cod_liqrol
				  AND n47_fecha_ini   = n32_fecha_ini
				  AND n47_fecha_fin   = n32_fecha_fin
				  AND n47_cod_trab    = n32_cod_trab
				  AND n39_compania    = n47_compania
				  AND n39_proceso     = n47_proceso
				  AND n39_cod_trab    = n47_cod_trab
				  AND n39_periodo_ini =	n47_periodo_ini
				  AND n39_periodo_fin =	n47_periodo_fin
				  AND n39_ano_proceso = n32_ano_proceso
				  AND n39_mes_proceso = n32_mes_proceso))
				THEN n33_valor
				ELSE 0
			END), 2), 0) AS valor_rol
	--}
	FROM rolt032, rolt033, gent034
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = 2008
	  AND n32_estado      <> 'E'
	  AND n33_compania     = n32_compania
	  AND n33_cod_liqrol   = n32_cod_liqrol
	  AND n33_fecha_ini    = n32_fecha_ini
	  AND n33_fecha_fin    = n32_fecha_fin
	  AND n33_cod_trab     = n32_cod_trab
	  AND n33_cod_rubro   IN (SELECT n08_rubro_base
					FROM rolt008
					WHERE n08_cod_rubro =
						(SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = 'AP'))
	  AND n33_valor        > 0
	  AND n33_det_tot      = 'DI'
	  AND n33_cant_valor   = 'V'
	  AND g34_compania     = n32_compania
	  AND g34_cod_depto    = n32_cod_depto
	GROUP BY 1, 2, 3, 4
	UNION
	SELECT 'VA' cd, EXTEND(MDY(MONTH(n39_fecing), 01, YEAR(n39_fecing)),
		YEAR TO MONTH) AS fec_rol, n39_cod_depto AS cod_dep, g34_nombre
		AS departamento, NVL(ROUND(SUM(n39_valor_vaca +
					CASE WHEN n39_gozar_adic = 'S'
						THEN n39_valor_adic
						ELSE 0
					END), 2), 0) AS valor_rol
		FROM rolt039, gent034
		WHERE n39_compania     = 1
		  AND n39_proceso      = 'VA'
		  AND n39_ano_proceso  = 2008
		  AND n39_estado       = 'P'
		  AND g34_compania     = n39_compania
		  AND g34_cod_depto    = n39_cod_depto
		GROUP BY 1, 2, 3, 4
	INTO TEMP tmp_rol;
SELECT cod_dep, departamento, NVL(ROUND(SUM(valor_rol), 2), 0) AS total_dep
	FROM tmp_rol
	GROUP BY 1, 2
	ORDER BY 2;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

SELECT NVL(ROUND(SUM(valor), 2), 0) AS total_sueldo FROM tmp_ctb;
SELECT NVL(ROUND(SUM(valor_rol), 2), 0) AS total_rol FROM tmp_rol;

SELECT fec_rol, NVL(ROUND(SUM(valor_rol), 2), 0) AS total_dep_mes
	FROM tmp_rol
	GROUP BY 1
	INTO TEMP t1;

SELECT fecha, NVL(ROUND(SUM(valor), 2), 0) AS total_ctb_mes
	FROM tmp_ctb
	GROUP BY 1
	INTO TEMP t2;

SELECT fec_rol, total_dep_mes, total_ctb_mes, ROUND(total_dep_mes -
	total_ctb_mes, 2) AS diferencia
	FROM t1, t2
	WHERE fec_rol = fecha
	INTO TEMP t3;

DROP TABLE t1;
DROP TABLE t2;

SELECT * FROM t3 ORDER BY 1;

SELECT NVL(ROUND(SUM(total_dep_mes), 2), 0) AS total_rol,
	NVL(ROUND(SUM(total_ctb_mes), 2), 0) AS total_ctb,
	NVL(ROUND(SUM(diferencia), 2), 0) AS diferencia
	FROM t3;

DROP TABLE t3;

DROP TABLE tmp_ctb;
DROP TABLE tmp_rol;
