DROP PROCEDURE fp_dias360;

CREATE PROCEDURE fp_dias360 (fecha_ini DATE, fecha_fin DATE, metodo INT)
		RETURNING INT;

	DEFINE fec1, fec2		DATE;
	DEFINE fec_txt			CHAR(10);
	DEFINE num_anio, num_mes	INT;
	DEFINE dias, num_dias		INT;

	ON EXCEPTION IN (-1260)
		RETURN 0;
	END EXCEPTION;

	-- METODO: 1 (Método Europeo)	0 (Método EEUU - (NASD))
	IF DAY(fecha_ini) = 31 THEN
		LET fecha_ini = fecha_ini - 1 UNITS DAY;
	END IF;

	IF metodo = 1 THEN
		IF DAY(fecha_fin) = 31 THEN
			LET fecha_fin = fecha_fin - 1 UNITS DAY;
		END IF;
	END IF;

	IF metodo = 0 THEN
		LET fec2 = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
				+ 1 UNITS MONTH - 1 UNITS DAY;
		IF fecha_fin = fec2 AND DAY(fecha_ini) < 30 THEN
			LET fecha_fin = fec2 + 1 UNITS DAY;
		ELSE
			IF DAY(fecha_fin) = 31 THEN
				LET fecha_fin = fecha_fin - 1 UNITS DAY;
			END IF;
		END IF;
	END IF;

	LET num_mes = 0;

	IF EXTEND(fecha_ini, YEAR TO MONTH) = EXTEND(fecha_fin, YEAR TO MONTH)
	THEN
		LET num_dias = fecha_fin - fecha_ini + 1;
		IF num_dias > 30 THEN
			LET num_dias = 30;
		END IF;
		RETURN num_dias;
	END IF;

	LET fec1 = MDY(MONTH(fecha_ini), 01, YEAR(fecha_ini)) + 1 UNITS MONTH;
	LET fec2 = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin)) - 1 UNITS DAY;

	LET num_anio = 0;

	IF EXTEND(fec2, YEAR TO MONTH) = EXTEND(fec1, YEAR TO MONTH) THEN
		LET num_mes = 30;
	END IF;

	IF EXTEND(fec1, YEAR TO MONTH) > EXTEND(fec2, YEAR TO MONTH) THEN
		LET num_mes = 0;
	END IF;

	IF EXTEND(fec2, YEAR TO MONTH) > EXTEND(fec1, YEAR TO MONTH) THEN
		LET fec_txt  = (EXTEND(fec2, YEAR TO MONTH) -
				EXTEND(fec1, YEAR TO MONTH)) + 1 UNITS MONTH;

		LET num_anio = fec_txt[1, 5];
		LET num_mes  = fec_txt[7, 8];

		LET num_anio = num_anio * 360;
		LET num_mes  = num_mes * 30;
	END IF;

	LET num_dias = 30 - DAY(fecha_ini) + 1;
	IF num_dias < 0 THEN
		LET num_dias = 1;
	END IF;
	
	LET dias = DAY(fecha_fin);
	IF dias > 30 OR (EXTEND(fecha_fin, MONTH TO DAY) = "02-28" OR
	   EXTEND(fecha_fin, MONTH TO DAY) = "02-29")
	THEN
		LET dias = 30;
	END IF;

	LET num_dias = num_dias + dias;

	LET num_dias = num_dias + (num_anio + num_mes);

	RETURN num_dias;

END PROCEDURE;
