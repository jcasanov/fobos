SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	n30_sexo AS genero,
	n30_sectorial AS ocupacion,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_gm@idsgye01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2013)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_gm@idsgye01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2013)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2013))), 0)
	AS cargas,
	((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
			THEN MDY(01, 01, 2013)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2013)
		    END)) * (SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM acero_gm@idsgye01:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2013)
		THEN MDY(01, 01, 2013)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2013)
	    END) + 1) AS dias,
	(SELECT CASE WHEN n42_tipo_pago = "T"
			THEN "A"
			ELSE "P"
		END
		FROM acero_gm@idsgye01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2013)
		  AND n42_fecha_fin = MDY(12,31,2013)
		  AND n42_cod_trab  = n30_cod_trab) AS tip_pag,
	"" AS jor_par_per,
	"" AS hor_jor_par_per,
	CASE WHEN n30_cod_trab = 138
		THEN "X"
	END AS discap,
	"1790008959001" AS ruc_cia,
	(SELECT n36_valor_bruto
		FROM acero_gm@idsgye01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DT'
		  AND n36_fecha_ini = MDY(12,01,2012)
		  AND n36_fecha_fin = MDY(11,30,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dt,
	(SELECT n36_valor_bruto
		FROM acero_gm@idsgye01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DC'
		  AND n36_fecha_ini = MDY(03,01,2012)
		  AND n36_fecha_fin = MDY(02,28,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dc,
	(SELECT n42_val_trabaj + n42_val_cargas
		FROM acero_gm@idsgye01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2012)
		  AND n42_fecha_fin = MDY(12,31,2012)
		  AND n42_cod_trab  = n30_cod_trab) AS val_ut_12,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2013
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2013
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	n30_sexo AS genero,
	n30_sectorial AS ocupacion,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_gm@idsgye01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2013)
			ELSE 0
		 END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_gm@idsgye01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2013)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2013))), 0)
	AS cargas,
	NVL(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) = n30_fecha_sal
		THEN 1
		END,
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			 END) - CASE WHEN MONTH(n30_fecha_sal) =
				MONTH(NVL(n30_fecha_reing, n30_fecha_ing))
					THEN 0 ELSE 1 END) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
					THEN MDY(01, 01, 2013)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2013)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
					THEN MDY(01, 01, 2013)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2013)
				END)) * (SELECT n00_dias_mes
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
				THEN MDY(01, 01, 2013)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM acero_gm@idsgye01:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2013)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2013)
						THEN MDY(01, 01, 2013)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2013)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2013)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2013)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2013)
						THEN MDY(01, 01, 2013)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2013)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2013, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END) AS dias,
	(SELECT CASE WHEN n42_tipo_pago = "T"
			THEN "A"
			ELSE "P"
		END
		FROM acero_gm@idsgye01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2013)
		  AND n42_fecha_fin = MDY(12,31,2013)
		  AND n42_cod_trab  = n30_cod_trab) AS tip_pag,
	"" AS jor_par_per,
	"" AS hor_jor_par_per,
	CASE WHEN n30_cod_trab = 138
		THEN "X"
	END AS discap,
	"1790008959001" AS ruc_cia,
	(SELECT n36_valor_bruto
		FROM acero_gm@idsgye01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DT'
		  AND n36_fecha_ini = MDY(12,01,2012)
		  AND n36_fecha_fin = MDY(11,30,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dt,
	(SELECT n36_valor_bruto
		FROM acero_gm@idsgye01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DC'
		  AND n36_fecha_ini = MDY(03,01,2012)
		  AND n36_fecha_fin = MDY(02,28,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dc,
	(SELECT n42_val_trabaj + n42_val_cargas
		FROM acero_gm@idsgye01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2012)
		  AND n42_fecha_fin = MDY(12,31,2012)
		  AND n42_cod_trab  = n30_cod_trab) AS val_ut_12,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE n30_compania                               = 1
	  AND n30_estado                                 = 'I'
	  AND YEAR(n30_fecha_sal)                       >= 2013
	  AND YEAR(n30_fecha_sal)                       <= YEAR(TODAY)
	  AND YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2013
	  AND n30_tipo_contr                             = 'F'
	  AND n30_tipo_trab                              = 'N'
	  AND n30_fec_jub                               IS NULL
UNION
SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	n30_sexo AS genero,
	n30_sectorial AS ocupacion,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_qm@idsuio01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2013)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_qm@idsuio01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2013)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2013))), 0)
	AS cargas,
	CASE WHEN n30_cod_trab = 424 THEN 282 ELSE
	((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
			THEN MDY(01, 01, 2013)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2013)
		    END)) * (SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM acero_qm@idsuio01:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2013)
		THEN MDY(01, 01, 2013)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2013)
	    END) + 1) END AS dias,
	(SELECT CASE WHEN n42_tipo_pago = "T"
			THEN "A"
			ELSE "P"
		END
		FROM acero_qm@idsuio01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2013)
		  AND n42_fecha_fin = MDY(12,31,2013)
		  AND n42_cod_trab  = n30_cod_trab) AS tip_pag,
	"" AS jor_par_per,
	"" AS hor_jor_par_per,
	CASE WHEN n30_cod_trab = 000
		THEN "X"
	END AS discap,
	"1790008959001" AS ruc_cia,
	(SELECT n36_valor_bruto
		FROM acero_qm@idsuio01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DT'
		  AND n36_fecha_ini = MDY(12,01,2012)
		  AND n36_fecha_fin = MDY(11,30,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dt,
	(SELECT n36_valor_bruto
		FROM acero_qm@idsuio01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DC'
		  AND n36_fecha_ini = MDY(03,01,2012)
		  AND n36_fecha_fin = MDY(02,28,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dc,
	(SELECT n42_val_trabaj + n42_val_cargas
		FROM acero_qm@idsuio01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2012)
		  AND n42_fecha_fin = MDY(12,31,2012)
		  AND n42_cod_trab  = n30_cod_trab) AS val_ut_12,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm@idsuio01:rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2013
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2013
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	n30_sexo AS genero,
	n30_sectorial AS ocupacion,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_qm@idsuio01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2013)
			ELSE 0
		 END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_qm@idsuio01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2013)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2013))), 0)
	AS cargas,
	NVL(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) = n30_fecha_sal
		THEN 1
		END,
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			 END) - CASE WHEN MONTH(n30_fecha_sal) =
				MONTH(NVL(n30_fecha_reing, n30_fecha_ing))
					THEN 0 ELSE 1 END) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
					THEN MDY(01, 01, 2013)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2013)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
					THEN MDY(01, 01, 2013)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2013)
				END)) * (SELECT n00_dias_mes
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2013)
				THEN MDY(01, 01, 2013)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM acero_qm@idsuio01:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2013)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2013)
						THEN MDY(01, 01, 2013)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2013)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2013)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2013)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2013)
						THEN MDY(01, 01, 2013)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2013)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2013)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2013)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2013)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2013, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END) AS dias,
	(SELECT CASE WHEN n42_tipo_pago = "T"
			THEN "A"
			ELSE "P"
		END
		FROM acero_qm@idsuio01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2013)
		  AND n42_fecha_fin = MDY(12,31,2013)
		  AND n42_cod_trab  = n30_cod_trab) AS tip_pag,
	"" AS jor_par_per,
	"" AS hor_jor_par_per,
	CASE WHEN n30_cod_trab = 000
		THEN "X"
	END AS discap,
	"1790008959001" AS ruc_cia,
	(SELECT n36_valor_bruto
		FROM acero_qm@idsuio01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DT'
		  AND n36_fecha_ini = MDY(12,01,2012)
		  AND n36_fecha_fin = MDY(11,30,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dt,
	(SELECT n36_valor_bruto
		FROM acero_qm@idsuio01:rolt036
		WHERE n36_compania  = n30_compania
		  AND n36_proceso   = 'DC'
		  AND n36_fecha_ini = MDY(03,01,2012)
		  AND n36_fecha_fin = MDY(02,28,2013)
		  AND n36_cod_trab  = n30_cod_trab) AS val_dc,
	(SELECT n42_val_trabaj + n42_val_cargas
		FROM acero_qm@idsuio01:rolt042
		WHERE n42_compania  = n30_compania
		  AND n42_proceso   = 'UT'
		  AND n42_fecha_ini = MDY(01,01,2012)
		  AND n42_fecha_fin = MDY(12,31,2012)
		  AND n42_cod_trab  = n30_cod_trab) AS val_ut_12,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm@idsuio01:rolt030
	WHERE n30_compania                               = 1
	  AND n30_estado                                 = 'I'
	  AND YEAR(n30_fecha_sal)                       >= 2013
	  AND YEAR(n30_fecha_sal)                       <= YEAR(TODAY)
	  AND YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2013
	  AND n30_tipo_contr                             = 'F'
	  AND n30_tipo_trab                              = 'N'
	  AND n30_fec_jub                               IS NULL
	  AND n30_cod_Trab                              <> 477
	ORDER BY n30_nombres;
