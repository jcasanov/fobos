--------------------------------------------------------------------------------
-- Titulo           : rolp210.4gl - Generacion fondo de reserva          
-- Elaboracion      : 15-oct-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp210 base moódulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_r_rows	ARRAY [1000] OF RECORD
				fecha_ini	LIKE rolt038.n38_fecha_ini,
				fecha_fin	LIKE rolt038.n38_fecha_fin
			END RECORD
DEFINE rm_par		RECORD
				n38_fecha_ini	LIKE rolt038.n38_fecha_ini,
				n38_fecha_fin	LIKE rolt038.n38_fecha_fin,
				n38_estado	LIKE rolt038.n38_estado,
				n_estado	VARCHAR(15)
			END RECORD
DEFINE rm_scr		ARRAY[1000] OF RECORD 
				n38_cod_trab	LIKE rolt038.n38_cod_trab,
				n_trab		LIKE rolt030.n30_nombres,
				n38_ganado_per	LIKE rolt038.n38_ganado_per,
				n38_valor_fondo	LIKE rolt038.n38_valor_fondo
			END RECORD
DEFINE rm_nov		ARRAY[1000] OF RECORD 
				fecha_nov	DATE,
				novedad		VARCHAR(10)
			END RECORD
DEFINE vm_proceso	LIKE rolt005.n05_proceso
DEFINE pago_iess	LIKE rolt038.n38_pago_iess
DEFINE vm_fec_ult	LIKE rolt038.n38_fecha_fin
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n01		RECORD LIKE rolt001.*
DEFINE rm_n03		RECORD LIKE rolt003.*
DEFINE rm_n05		RECORD LIKE rolt005.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_num_nov	SMALLINT
DEFINE vm_filas_pant	INTEGER
DEFINE vm_numelm	INTEGER
DEFINE vm_maxelm	INTEGER
DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp210.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 6 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp210'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET vm_maxelm	= 1000
LET vm_proceso	= 'FR'
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf210_1"
DISPLAY FORM f_rol
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
INITIALIZE rm_n00.* TO NULL
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_moneda_pago IS NULL THEN
	CALL fl_mostrar_mensaje('No se han configurado parametros generales de roles.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING rm_n01.*
IF rm_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
        EXIT PROGRAM
END IF
IF rm_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no esta activa.', 'stop')
        EXIT PROGRAM
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
LET vm_fec_ult = NULL
SQL
	SELECT NVL(MAX(n38_fecha_fin), TODAY)
		INTO $vm_fec_ult
		FROM rolt038
		WHERE n38_compania = $vg_codcia
END SQL
CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
LET pago_iess   = 'S'
LET vm_num_rows = 0
MENU 'OPCIONES'
	BEFORE MENU
		CALL mostrar_botones()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Cerrar'
		HIDE OPTION 'Reabrir'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Detalle'
		IF rm_n05.n05_proceso = vm_proceso THEN
			HIDE OPTION 'Generar'
			IF rm_n05.n05_activo = 'S' THEN
				SHOW OPTION 'Generar'
			END IF
		ELSE
			IF rm_n05.n05_proceso IS NOT NULL THEN
				HIDE OPTION 'Generar'
			END IF
		END IF
		IF num_args() <> 3 THEN
			LET rm_par.n38_fecha_ini = arg_val(5)
			LET rm_par.n38_fecha_fin = arg_val(6)
			DISPLAY BY NAME rm_par.*
			CALL control_consulta()
			CALL control_detalle()
			EXIT PROGRAM
		END IF
	COMMAND KEY('G') 'Generar' 'Genera los registros de Fondo de Reserva.'
		CALL control_generar()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF rm_n05.n05_proceso IS NOT NULL THEN
			HIDE OPTION 'Generar'
			HIDE OPTION 'Reabrir'
			SHOW OPTION 'Cerrar'
			IF rm_n05.n05_activo = 'S' THEN
				SHOW OPTION 'Generar'
			END IF
		ELSE
			IF vm_num_rows > 0 THEN
				SHOW OPTION 'Reabrir'
			END IF
		END IF
		IF rm_par.n38_estado IS NOT NULL THEN
			IF rm_par.n38_estado = 'P' THEN
				HIDE OPTION 'Cerrar'
				SHOW OPTION 'Reabrir'
			ELSE
				SHOW OPTION 'Cerrar'
				HIDE OPTION 'Reabrir'
			END IF
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
		END IF
       	COMMAND KEY('X') 'Reabrir' 'Reabre el Fondo de Reserva Cerrado. '
		CALL control_reabrir()
		IF rm_par.n38_estado IS NOT NULL THEN
			IF rm_par.n38_estado = 'A' THEN
				SHOW OPTION 'Generar'
				HIDE OPTION 'Reabrir'
				SHOW OPTION 'Cerrar'
			ELSE
				HIDE OPTION 'Generar'
				IF vm_fec_ult = rm_par.n38_fecha_fin THEN
					SHOW OPTION 'Reabrir'
				ELSE
					HIDE OPTION 'Reabrir'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
		END IF
       	COMMAND KEY('U') 'Cerrar' 'Cierra el Fondo de Reserva Abierto. '
		CALL control_cerrar()
		IF rm_n05.n05_proceso IS NULL THEN
			HIDE OPTION 'Generar'
			IF vm_num_rows = 0 THEN
				SHOW OPTION 'Generar'
			END IF
			IF vm_num_rows > 0 THEN
				SHOW OPTION 'Reabrir'
			END IF
			HIDE OPTION 'Cerrar'
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Cerrar'
				HIDE OPTION 'Reabrir'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF vm_fec_ult = rm_par.n38_fecha_fin THEN
				SHOW OPTION 'Reabrir'
			ELSE
				HIDE OPTION 'Reabrir'
			END IF
			SHOW OPTION 'Cerrar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF rm_par.n38_estado IS NOT NULL THEN
			IF rm_par.n38_estado = 'A' THEN
				HIDE OPTION 'Reabrir'
				SHOW OPTION 'Cerrar'
			ELSE
				IF vm_fec_ult = rm_par.n38_fecha_fin THEN
					SHOW OPTION 'Reabrir'
				ELSE
					HIDE OPTION 'Reabrir'
				END IF
				HIDE OPTION 'Cerrar'
			END IF
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Detalle'
			{
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
			}
		END IF
	COMMAND KEY('D') 'Detalle' 'Consulta el detalle del registro actual. '
		CALL control_detalle()
	COMMAND KEY('I') 'Imprimir' 'Imprime un registro. '
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_par.n38_estado = 'A' THEN
			HIDE OPTION 'Reabrir'
			SHOW OPTION 'Cerrar'
		ELSE
			IF vm_fec_ult = rm_par.n38_fecha_fin THEN
				SHOW OPTION 'Reabrir'
			ELSE
				HIDE OPTION 'Reabrir'
			END IF
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
			{
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
			}
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_par.n38_estado = 'A' THEN
			HIDE OPTION 'Reabrir'
			SHOW OPTION 'Cerrar'
		ELSE
			IF vm_fec_ult = rm_par.n38_fecha_fin THEN
				SHOW OPTION 'Reabrir'
			ELSE
				HIDE OPTION 'Reabrir'
			END IF
			HIDE OPTION 'Cerrar'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Detalle'
			{
			IF vm_filas_pant < vm_numelm THEN
				SHOW OPTION 'Detalle'
			ELSE
				HIDE OPTION 'Detalle'
			END IF
			}
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'Código'                TO bt_cod_trab
DISPLAY 'Nombre Trabajador'     TO bt_nom_trab
DISPLAY 'Valor Ganado'          TO bt_ganado
DISPLAY 'Valor Fondo'           TO bt_valor_fondo

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
        LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_row_current)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
        LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_row_current)
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT

DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69

END FUNCTION



FUNCTION control_generar()
DEFINE resp		VARCHAR(6)
DEFINE mensaje		VARCHAR(250)
DEFINE estado		LIKE rolt038.n38_estado
DEFINE preguntar	SMALLINT

INITIALIZE rm_par.* TO NULL
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	EXIT PROGRAM
END IF
IF rm_n01.n01_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Compañía no esta activa.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso_roles(vm_proceso) RETURNING rm_n03.*
IF rm_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('Proceso no esta configurado.', 'stop')
	EXIT PROGRAM
END IF 
CASE rm_n03.n03_frecuencia
	WHEN 'A'
		LET rm_par.n38_fecha_ini = MDY(rm_n03.n03_mes_ini,
				rm_n03.n03_dia_ini, rm_n01.n01_ano_proceso - 1)
		LET rm_par.n38_fecha_fin = MDY(rm_n03.n03_mes_fin,
				rm_n03.n03_dia_fin, rm_n01.n01_ano_proceso)
	WHEN 'M'
		LET rm_par.n38_fecha_ini = MDY(rm_n03.n03_mes_ini,
				rm_n03.n03_dia_ini, rm_n01.n01_ano_proceso)
		IF rm_n03.n03_mes_ini = 12 THEN
			LET rm_par.n38_fecha_ini = MDY(rm_n03.n03_mes_ini,
						rm_n03.n03_dia_ini,
						rm_n01.n01_ano_proceso - 1)
		END IF
		LET rm_par.n38_fecha_fin = rm_par.n38_fecha_ini
						+ 1 UNITS MONTH - 1 UNITS DAY
END CASE
DISPLAY BY NAME rm_par.*
SELECT n38_estado INTO estado
	FROM rolt038
	WHERE n38_compania  = vg_codcia
	  AND n38_fecha_ini = rm_par.n38_fecha_ini 
	  AND n38_fecha_fin = rm_par.n38_fecha_fin 
	  AND n38_pago_iess = "S"
	GROUP BY n38_estado
LET preguntar = 1
IF STATUS <> NOTFOUND THEN
	IF estado = 'P' THEN
		CALL fl_mostrar_mensaje('Ya se procesaron los valores del Fondo de Reserva.', 'stop')
		IF vm_num_rows = 0 THEN
			INITIALIZE rm_par.* TO NULL
			CLEAR FORM
			CALL mostrar_botones()
			CALL muestra_contadores(vm_row_current, vm_num_rows)
		ELSE
			CALL mostrar_registro(vm_row_current)
			CALL muestra_contadores(vm_row_current, vm_num_rows)
		END IF
		RETURN
	ELSE
		CALL fl_hacer_pregunta("Ya se han generado los registros del Fondo de Reserva. Desea regenerarlos?", "No") RETURNING resp	
		IF resp <> "Yes" THEN
			IF vm_num_rows = 0 THEN
				INITIALIZE rm_par.* TO NULL
				CLEAR FORM
				CALL mostrar_botones()
				CALL muestra_contadores(vm_row_current,
							vm_num_rows)
			ELSE
				CALL mostrar_registro(vm_row_current)
				CALL muestra_contadores(vm_row_current,
							vm_num_rows)
			END IF
			RETURN
		END IF
		LET preguntar = 0
	END IF
END IF
LET rm_par.n38_estado = 'A'
LET rm_par.n_estado   = 'ACTIVO'
DISPLAY BY NAME rm_par.*
IF preguntar THEN
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp <> 'Yes' THEN
		IF vm_num_rows = 0 THEN
			INITIALIZE rm_par.* TO NULL
			CLEAR FORM
			CALL mostrar_botones()
			CALL muestra_contadores(vm_row_current, vm_num_rows)
		ELSE
			CALL mostrar_registro(vm_row_current)
			CALL muestra_contadores(vm_row_current, vm_num_rows)
		END IF
		RETURN
	END IF
END IF
WHENEVER ERROR CONTINUE
DELETE FROM rolt038
	WHERE n38_compania  = vg_codcia
	  AND n38_fecha_ini = rm_par.n38_fecha_ini
	  AND n38_fecha_fin = rm_par.n38_fecha_fin
	  AND n38_pago_iess = "S"
IF STATUS < 0 THEN
	CALL fl_mostrar_mensaje('No se pudo borrar detalle de '
				|| 'fonde de reserva (rolt038). '
				|| 'Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
BEGIN WORK
LET vm_num_nov = 0
MESSAGE 'Se estan calculando los valores del fondo de reserva. Por favor, espere...' 
CALL genera_novedades()
MESSAGE '' 
SELECT * INTO rm_n05.*
	FROM rolt005
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = vm_proceso
IF STATUS = NOTFOUND THEN
	INITIALIZE rm_n05.* TO NULL
	LET rm_n05.n05_compania   = vg_codcia
	LET rm_n05.n05_proceso    = vm_proceso
	LET rm_n05.n05_activo     = 'S'
	LET rm_n05.n05_fecini_act = CURRENT
	LET rm_n05.n05_fecfin_act = CURRENT
	LET rm_n05.n05_fec_ultcie = CURRENT
	LET rm_n05.n05_fec_cierre = CURRENT
	LET rm_n05.n05_usuario    = vg_codcia
	LET rm_n05.n05_fecing     = CURRENT
	INSERT INTO rolt005 VALUES (rm_n05.*) 
ELSE
	LET rm_n05.n05_activo     = 'S'
	UPDATE rolt005
		SET n05_activo     = 'S',
		    n05_fecini_act = NULL,
		    n05_fecfin_act = NULL
		WHERE n05_compania = vg_codcia
		  AND n05_proceso  = vm_proceso
END IF 
COMMIT WORK
LET mensaje = 'Se generaron ', vm_num_nov USING '##&', ' registros de ',
		'Fondo de Reserva. '
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION genera_novedades()
DEFINE r_n06 		RECORD LIKE rolt006.*
DEFINE r_n07 		RECORD LIKE rolt007.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n38		RECORD LIKE rolt038.*
DEFINE op		LIKE rolt004.n04_operacion
DEFINE rubro		LIKE rolt033.n33_cod_rubro
DEFINE valor 		LIKE rolt036.n36_ganado_real
DEFINE dsctos 		LIKE rolt036.n36_descuentos
DEFINE total_ganado  	LIKE rolt038.n38_ganado_per
DEFINE tot_ganado  	LIKE rolt038.n38_ganado_per
DEFINE tot_valor	LIKE rolt038.n38_valor_fondo
DEFINE fecha_ini	LIKE rolt038.n38_fecha_ini
DEFINE fecha_aux	LIKE rolt038.n38_fecha_ini
DEFINE valor_fec, dia	INTEGER
DEFINE dias_anio	INTEGER
DEFINE query		CHAR(2500)

LET query = 'SELECT * FROM rolt030 ',
		' WHERE n30_compania      = ', vg_codcia,
		'   AND n30_estado        = "A" ',
		'   AND n30_fecha_ing    <= "', rm_par.n38_fecha_fin, '"',
		'   AND n30_fecha_sal    IS NULL ',
		'   AND n30_tipo_contr    = "F" ',
		'   AND n30_fon_res_anio  = "S" ',
		' UNION ',
		' SELECT * FROM rolt030 ',
			' WHERE n30_compania      = ', vg_codcia,
			'   AND n30_estado        = "A" ',
			'   AND n30_fecha_reing  <= "',rm_par.n38_fecha_fin,'"',
			'   AND n30_fecha_sal    IS NOT NULL ',
			'   AND n30_fecha_reing   > n30_fecha_sal ',
			'   AND n30_tipo_contr    = "F" ',
			'   AND n30_fon_res_anio  = "S" ',
		' UNION ',
		' SELECT * FROM rolt030 ',
			' WHERE n30_compania      = ', vg_codcia,
			'   AND n30_estado        = "I" ',
			'   AND n30_fecha_sal    >= "',rm_par.n38_fecha_fin,'"',
			'   AND EXTEND(n30_fecha_sal,MONTH TO DAY) <> "02-28" ',
			'   AND EXTEND(n30_fecha_sal,MONTH TO DAY) <> "02-29" ',
			'   AND n30_tipo_contr    = "F" ',
			'   AND n30_fon_res_anio  = "S" ',
		' ORDER BY 4 '
PREPARE cons_fon FROM query
DECLARE q_trab CURSOR FOR cons_fon
CASE rm_n03.n03_frecuencia
	WHEN 'A' LET dias_anio = rm_n90.n90_dias_anio
	WHEN 'M'
		LET dias_anio = rm_n00.n00_dias_mes
		INITIALIZE r_n06.* TO NULL
		SELECT * INTO r_n06.*
			FROM rolt006
			WHERE n06_flag_ident = 'FM'
			  AND n06_estado     = 'A'
		IF r_n06.n06_cod_rubro IS NULL THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('No existe el rubro de calculo mensual del Fondo de Reserva.', 'stop')
			EXIT PROGRAM
		END IF
		CALL fl_lee_rubro_que_se_calcula(r_n06.n06_cod_rubro)
			RETURNING r_n07.*
END CASE
LET vm_numelm = 1
FOREACH q_trab INTO r_n30.*
	LET valor_fec = (rm_par.n38_fecha_fin - r_n30.n30_fecha_ing) + 1
	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET valor_fec = (rm_par.n38_fecha_fin - r_n30.n30_fecha_reing)
				 + 1
		IF r_n30.n30_fecha_sal IS NOT NULL THEN
			LET valor_fec = valor_fec +
				((r_n30.n30_fecha_sal - r_n30.n30_fecha_ing)+ 1)
		END IF
	END IF
	CASE rm_n03.n03_frecuencia
		WHEN 'A'
			IF valor_fec <= dias_anio THEN
				CONTINUE FOREACH
			END IF
		WHEN 'M'
			IF valor_fec <= rm_n90.n90_dias_anio THEN
				CONTINUE FOREACH
			END IF
	END CASE
	LET fecha_aux = NULL
	LET fecha_ini = rm_par.n38_fecha_ini
	LET valor_fec = valor_fec - dias_anio
	IF valor_fec > 0 AND valor_fec < rm_n90.n90_dias_anio THEN
		LET fecha_ini = r_n30.n30_fecha_ing
		IF r_n30.n30_fecha_reing IS NOT NULL THEN
			LET fecha_ini = r_n30.n30_fecha_reing
		END IF
		LET fecha_aux = fecha_ini
		LET dia       = 1
		IF DAY(fecha_ini) >= 15 THEN
			LET dia = 16
		END IF
		CASE rm_n03.n03_frecuencia
			WHEN 'A' LET fecha_ini = MDY(MONTH(fecha_ini), dia,
							YEAR(fecha_ini) + 1)
			WHEN 'M' LET fecha_ini =
						MDY(MONTH(rm_par.n38_fecha_fin),
						dia, YEAR(rm_par.n38_fecha_fin))
		END CASE
	END IF
	SELECT * FROM rolt032
		WHERE n32_compania   = vg_codcia
		  AND n32_fecha_ini >= fecha_ini
		  AND n32_fecha_fin <= rm_par.n38_fecha_fin 
		  AND n32_cod_trab   = r_n30.n30_cod_trab
		  AND n32_estado     = 'C'
		INTO TEMP tmp_cabecera
	DECLARE q_rub CURSOR FOR
        	SELECT n33_cod_rubro, n04_operacion,
			NVL(SUM(n33_valor), 0) AS valor
                	FROM tmp_cabecera, rolt033, rolt004, rolt007
                	WHERE n33_compania   = n32_compania
                	  AND n33_cod_liqrol = n32_cod_liqrol
                	  AND n33_fecha_ini  = n32_fecha_ini
                	  AND n33_fecha_fin  = n32_fecha_fin
                	  AND n33_cod_trab   = n32_cod_trab
                	  AND n04_compania   = n33_compania
                	  AND n04_proceso    = vm_proceso 
                	  AND n04_cod_rubro  = n33_cod_rubro
                	  AND n07_cod_rubro  = n33_cod_rubro
                	GROUP BY n33_cod_rubro, n04_operacion
	SELECT NVL(SUM(n32_tot_gan), 0)
		INTO total_ganado
		FROM tmp_cabecera
		WHERE n32_compania = vg_codcia
		  AND n32_cod_trab = r_n30.n30_cod_trab
	FOREACH q_rub INTO rubro, op, valor
		CASE op
			WHEN '+'
				LET total_ganado = total_ganado + valor
			WHEN '-'
				LET total_ganado = total_ganado - valor
		END CASE
	END FOREACH
	INITIALIZE r_n38.* TO NULL
	LET r_n38.n38_compania  = vg_codcia
	LET r_n38.n38_fecha_ini = rm_par.n38_fecha_ini
	LET r_n38.n38_fecha_fin = rm_par.n38_fecha_fin
	LET r_n38.n38_cod_trab  = r_n30.n30_cod_trab
	LET r_n38.n38_estado    = 'A'
	LET r_n38.n38_fecha_ing = r_n30.n30_fecha_ing
	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET r_n38.n38_fecha_ing = r_n30.n30_fecha_reing
	END IF
	CALL obtener_total_ganado_real(r_n30.n30_cod_trab, total_ganado,
					fecha_ini)
		RETURNING total_ganado
	LET r_n38.n38_ganado_per  = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					   total_ganado)
	CASE rm_n03.n03_frecuencia
		WHEN 'A'
			LET r_n38.n38_valor_fondo =
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
							(total_ganado / 12))
		WHEN 'M'
			LET r_n38.n38_valor_fondo =
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					(total_ganado * r_n07.n07_factor / 100))
{
			LET r_n38.n38_valor_fondo =
				fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
							(total_ganado / 12))
}
	END CASE
	LET r_n38.n38_moneda      = r_n30.n30_mon_sueldo
	LET r_n38.n38_paridad     = 1
	LET r_n38.n38_pago_iess   = 'S'
	LET r_n38.n38_usuario     = vg_usuario
	LET r_n38.n38_fecing      = CURRENT
		{--
		LET query = 'SELECT EXTEND(MDY(',
				MONTH(rm_par.n38_fecha_fin), ', ',
				DAY(rm_par.n38_fecha_fin), ', ',
				YEAR(rm_par.n38_fecha_fin), ')',
				', YEAR TO SECOND) + ',
				EXTEND(CURRENT, HOUR TO HOUR),
				' UNITS HOUR + ',
				EXTEND(CURRENT, MINUTE TO MINUTE),
				' UNITS MINUTE + ',
				EXTEND(CURRENT, SECOND TO SECOND),
				' UNITS SECOND fecha ',
				' FROM dual ',
				' INTO TEMP tmp_fec '
		PREPARE exec_fec FROM query
		EXECUTE exec_fec
		SELECT * INTO r_n38.n38_fecing FROM tmp_fec
		DROP TABLE tmp_fec
		--}
	IF r_n38.n38_valor_fondo = 0 THEN
		DROP TABLE tmp_cabecera
		CONTINUE FOREACH
	END IF
	INSERT INTO rolt038 VALUES (r_n38.*)
	LET rm_scr[vm_numelm].n38_cod_trab    = r_n38.n38_cod_trab
	LET rm_scr[vm_numelm].n_trab          = r_n30.n30_nombres
	LET rm_scr[vm_numelm].n38_ganado_per  = r_n38.n38_ganado_per
	LET rm_scr[vm_numelm].n38_valor_fondo = r_n38.n38_valor_fondo
	INITIALIZE rm_nov[vm_numelm].* TO NULL
	IF fecha_aux IS NOT NULL THEN
		LET rm_nov[vm_numelm].fecha_nov = fecha_aux
		LET rm_nov[vm_numelm].novedad   = 'ENTRADA'
		IF r_n30.n30_estado <> 'A' THEN
			LET rm_nov[vm_numelm].fecha_nov = r_n30.n30_fecha_sal
			LET rm_nov[vm_numelm].novedad   = 'SALIDA'
		END IF
	END IF
	LET vm_num_nov = vm_num_nov + 1
	DROP TABLE tmp_cabecera
	LET vm_numelm = vm_numelm + 1
END FOREACH
FREE q_trab
LET vm_numelm = vm_numelm - 1
IF vm_num_rows > 1 THEN
	LET vm_num_rows = vm_num_rows + 1
ELSE
	LET vm_num_rows = 1
END IF
LET vm_row_current                   = vm_num_rows
LET vm_r_rows[vm_num_rows].fecha_ini = rm_par.n38_fecha_ini
LET vm_r_rows[vm_num_rows].fecha_fin = rm_par.n38_fecha_fin
CALL muestra_detalle('N')
CALL muestra_contadores(vm_row_current, vm_num_rows)
	
END FUNCTION



FUNCTION obtener_total_ganado_real(cod_trab, total_ganado, fecha_ini)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE total_ganado	LIKE rolt032.n32_tot_gan
DEFINE fecha_ini, fec	LIKE rolt032.n32_fecha_ini
DEFINE fecha, fec_aux	LIKE rolt032.n32_fecha_fin
DEFINE valor		LIKE rolt032.n32_tot_gan
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE num_dias, dias	INTEGER
DEFINE factor_d		INTEGER

IF DAY(fecha_ini) = 1 THEN
	RETURN total_ganado
END IF
LET fecha = MDY(MONTH(fecha_ini), 01, YEAR(fecha_ini))
		+ 1 UNITS MONTH - 1 UNITS DAY
SELECT NVL(n32_tot_gan, 0)
	INTO valor
	FROM tmp_cabecera
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini   = fecha_ini
	  AND n32_fecha_fin   = fecha
	  AND n32_cod_trab    = cod_trab
LET total_ganado = total_ganado - valor
SELECT NVL(SUM(n32_tot_gan), 0)
	INTO valor
	FROM rolt032
	WHERE n32_compania     = vg_codcia
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_cod_trab     = cod_trab
	  AND n32_ano_proceso  = YEAR(fecha_ini)
	  AND n32_mes_proceso  = MONTH(fecha_ini)
	  AND n32_estado       = "C"
{--
IF vg_codloc = 1 THEN
	LET num_dias = fecha_ini - rm_par.n38_fecha_ini
	IF num_dias > 180 THEN
		IF num_dias < 300 THEN
			LET fecha_ini = MDY(12, DAY(fecha_ini),
						YEAR(fecha_ini) - 1)
		ELSE
			LET fecha_ini = MDY(01, 01,
						YEAR(fecha_ini)) - 1 UNITS DAY
		END IF
		LET num_dias = fecha_ini - rm_par.n38_fecha_ini
		IF num_dias > 180 THEN
			LET num_dias = 180
		END IF
		LET factor_d = 360
	ELSE
		LET factor_d = 180 - (fecha - fecha_ini) - 1
	END IF
	LET total_ganado = total_ganado + (valor * (num_dias / factor_d))
ELSE
--}
	CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
	LET fec = MDY(MONTH(r_n30.n30_fecha_ing), DAY(r_n30.n30_fecha_ing),
			YEAR(fecha))
	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET fec = MDY(MONTH(r_n30.n30_fecha_reing),
				DAY(r_n30.n30_fecha_reing), YEAR(fecha))
	END IF
	CASE rm_n03.n03_frecuencia
		WHEN 'A' LET fecha_ini = fec
		WHEN 'M' LET fecha_ini = MDY(MONTH(rm_par.n38_fecha_fin),
						DAY(fec),
						YEAR(rm_par.n38_fecha_fin))
	END CASE
	LET num_dias = (fecha - fecha_ini) + 1
	LET fec_aux  = MDY(MONTH(fecha_ini), 01, YEAR(fecha_ini))
	SELECT NVL(SUM(n32_tot_gan), 0)
		INTO valor
		FROM rolt032
		WHERE n32_compania     = vg_codcia
		  AND n32_cod_liqrol  IN ("Q1", "Q2")
		  AND n32_cod_trab     = cod_trab
		  AND n32_fecha_ini   >= fec_aux
		  AND n32_fecha_fin   <= fecha
		  AND n32_estado       = "C"
	LET dias = DAY(fecha)
	IF MONTH(fecha) = 2 THEN
		LET dias = rm_n00.n00_dias_mes
	END IF
	LET total_ganado = total_ganado + ((valor / dias) * num_dias)
--END IF
RETURN total_ganado
	
END FUNCTION



FUNCTION calcula_totales()
DEFINE i                SMALLINT
DEFINE val_ganado       LIKE rolt038.n38_ganado_per
DEFINE val_fondo       	LIKE rolt038.n38_valor_fondo
DEFINE tot_ganado   	LIKE rolt038.n38_ganado_per
DEFINE tot_fondo 	LIKE rolt038.n38_valor_fondo
                                                                                
LET tot_fondo  = 0
LET tot_ganado = 0
FOR i = 1 TO vm_numelm
	LET val_ganado = rm_scr[i].n38_ganado_per
	IF val_ganado IS NULL THEN
		LET val_ganado = 0
	END IF
        LET tot_ganado = tot_ganado + val_ganado
	LET val_fondo = rm_scr[i].n38_valor_fondo
	IF val_fondo IS NULL THEN
		LET val_fondo = 0
	END IF
        LET tot_fondo = tot_fondo + val_fondo
END FOR
RETURN tot_ganado, tot_fondo

END FUNCTION



FUNCTION control_detalle()
DEFINE tot_ganado	LIKE rolt038.n38_ganado_per
DEFINE tot_valor	LIKE rolt038.n38_valor_fondo
DEFINE num_row, j	SMALLINT

IF vm_num_rows = 0 THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_numelm)
	DISPLAY ARRAY rm_scr TO ra_scr.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			IF rm_par.n38_estado = 'P' THEN
				CONTINUE DISPLAY
			END IF
			IF control_insertar_empleado() THEN
				EXIT DISPLAY
			END IF
			LET int_flag = 0
		ON KEY(F6)
			IF rm_par.n38_estado = 'P' THEN
				CONTINUE DISPLAY
			END IF
			LET num_row = arr_curr()
			LET j       = scr_line()
			CALL control_modificar_registro(num_row, j)
			LET int_flag = 0
		ON KEY(F7)
			LET num_row = arr_curr()
			CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
						rm_scr[num_row].n38_cod_trab,
						rm_par.n38_fecha_ini,
						rm_par.n38_fecha_fin)
			LET int_flag = 0
		ON KEY(F8)
			CALL control_imprimir()
	        BEFORE DISPLAY
        	        --#CALL dialog.keysetlabel('ACCEPT','')
			IF rm_par.n38_estado = 'P' THEN
        	        	--#CALL dialog.keysetlabel('F5','')
                		--#CALL dialog.keysetlabel('F6','')
			ELSE
        	        	--#CALL dialog.keysetlabel('F5','Insertar')
                		--#CALL dialog.keysetlabel('F6','Modificar')
			END IF
        	        CALL calcula_totales() RETURNING tot_ganado, tot_valor
			DISPLAY BY NAME tot_ganado, tot_valor 
		BEFORE ROW
			LET num_row = arr_curr()
			CALL muestra_contadores_det(num_row, vm_numelm)
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL carga_trabajadores('F')
	CALL calcula_totales() RETURNING tot_ganado, tot_valor
	DISPLAY BY NAME tot_ganado, tot_valor 
END WHILE
CALL muestra_lineas_detalle()
CALL muestra_contadores_det(0, vm_numelm)

END FUNCTION



FUNCTION control_insertar_empleado()
DEFINE r_regemp		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				per_ini		LIKE rolt038.n38_fecha_ini,
				per_fin		LIKE rolt038.n38_fecha_fin,
				tot_gan		LIKE rolt038.n38_ganado_per,
				val_fon		LIKE rolt038.n38_valor_fondo
			END RECORD
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n38		RECORD LIKE rolt038.*
DEFINE fecha		DATE
DEFINE dias_a, dias_f	SMALLINT
DEFINE resul, i		SMALLINT

OPEN WINDOW w_rolf210_2 AT 08, 09
        WITH FORM '../forms/rolf210_2'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   BORDER)
INITIALIZE r_regemp.* TO NULL
LET r_regemp.per_ini = rm_par.n38_fecha_ini
LET r_regemp.per_fin = rm_par.n38_fecha_fin
LET int_flag = 0
INPUT BY NAME r_regemp.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab,
					  r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET r_regemp.cod_trab = r_n30.n30_cod_trab
				LET r_regemp.nom_trab = r_n30.n30_nombres
				DISPLAY BY NAME r_regemp.cod_trab,
						r_regemp.nom_trab
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD per_ini
		LET fecha = r_regemp.per_ini
	BEFORE FIELD per_fin
		LET fecha = r_regemp.per_fin
	AFTER FIELD cod_trab
		IF r_regemp.cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							r_regemp.cod_trab)
				RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el codigo de este empleado en la Compania.','exclamation')
				NEXT FIELD cod_trab
			END IF
			LET r_regemp.nom_trab = r_n30.n30_nombres
			DISPLAY BY NAME r_regemp.nom_trab
			LET resul = 0
			FOR i = 1 TO vm_numelm
				IF r_n30.n30_cod_trab = rm_scr[i].n38_cod_trab
				THEN
					LET resul = 1
					EXIT FOR
				END IF
			END FOR
			IF resul THEN
				CALL fl_mostrar_mensaje('Este empleado ya tiene generado su fondo de reserva para este periodo.','exclamation')
				NEXT FIELD cod_trab
			END IF
			IF r_n30.n30_fecha_ing > rm_par.n38_fecha_fin THEN
				CALL fl_mostrar_mensaje('La fecha de ingreso de este empleado es mayor que la fecha final del fondo de reserva.', 'exclamation')
				NEXT FIELD cod_trab
			END IF
			IF r_n30.n30_fecha_reing IS NULL THEN
				LET dias_f = (rm_par.n38_fecha_fin -
						r_n30.n30_fecha_ing) + 1
			ELSE
				LET dias_a = (r_n30.n30_fecha_sal -
						r_n30.n30_fecha_ing) + 1
				LET dias_f = (rm_par.n38_fecha_fin -
						r_n30.n30_fecha_reing) + 1
				LET dias_f = dias_f + dias_a
			END IF
			IF dias_f <= rm_n90.n90_dias_anio THEN
				CALL fl_mostrar_mensaje('Este empleado no cumple con el numero de dias requeridos para el calculo del fondo de reserva.', 'exclamation')
				--NEXT FIELD cod_trab
			END IF
			CALL retorna_fondo_empleado(r_regemp.*)
				RETURNING r_regemp.*
		ELSE
			INITIALIZE r_regemp.* TO NULL
			CLEAR _regemp.*
			LET r_regemp.per_ini = rm_par.n38_fecha_ini
			LET r_regemp.per_fin = rm_par.n38_fecha_fin
			DISPLAY BY NAME r_regemp.*
		END IF
	AFTER FIELD per_ini
		IF r_regemp.per_ini IS NULL THEN
			LET r_regemp.per_ini = fecha
		END IF
		IF r_regemp.per_ini < rm_par.n38_fecha_ini OR
		   r_regemp.per_ini > rm_par.n38_fecha_fin
		THEN
			CALL fl_mostrar_mensaje('La fecha inicial debe estar dentro del periodo del fondo de reserva activo.', 'exclamation')
			NEXT FIELD per_ini
		END IF
		CALL retorna_fondo_empleado(r_regemp.*) RETURNING r_regemp.*
	AFTER FIELD per_fin
		IF r_regemp.per_fin IS NULL THEN
			LET r_regemp.per_fin = fecha
		END IF
		IF r_regemp.per_fin < rm_par.n38_fecha_ini OR
		   r_regemp.per_fin > rm_par.n38_fecha_fin
		THEN
			CALL fl_mostrar_mensaje('La fecha final debe estar dentro del periodo del fondo de reserva activo.', 'exclamation')
			NEXT FIELD per_fin
		END IF
		CALL retorna_fondo_empleado(r_regemp.*) RETURNING r_regemp.*
	AFTER INPUT
		IF r_regemp.per_fin < r_regemp.per_ini THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser mayor que la fecha inicial.', 'exclamation')
			CONTINUE INPUT
		END IF
		CALL retorna_fondo_empleado(r_regemp.*) RETURNING r_regemp.*
END INPUT
IF NOT int_flag THEN
	INITIALIZE r_n38.* TO NULL
	LET r_n38.n38_compania  = vg_codcia
	LET r_n38.n38_fecha_ini = rm_par.n38_fecha_ini
	LET r_n38.n38_fecha_fin = rm_par.n38_fecha_fin
	LET r_n38.n38_cod_trab  = r_regemp.cod_trab
	LET r_n38.n38_estado    = 'A'
	LET r_n38.n38_fecha_ing = r_n30.n30_fecha_ing
	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		LET r_n38.n38_fecha_ing = r_n30.n30_fecha_reing
	END IF
	CALL obtener_total_ganado_real(r_n30.n30_cod_trab, r_regemp.tot_gan,
					r_regemp.per_ini)
		RETURNING r_regemp.tot_gan
	LET r_n38.n38_ganado_per  = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					   r_regemp.tot_gan)
	LET r_n38.n38_valor_fondo = 
		fl_retorna_precision_valor(r_n30.n30_mon_sueldo,
					   r_regemp.tot_gan / 12)
	LET r_n38.n38_moneda      = r_n30.n30_mon_sueldo
	LET r_n38.n38_paridad     = 1
	LET r_n38.n38_pago_iess   = 'S'
	LET r_n38.n38_usuario     = vg_usuario
	LET r_n38.n38_fecing      = CURRENT
	INSERT INTO rolt038 VALUES (r_n38.*)
	LET r_regemp.val_fon      = r_n38.n38_valor_fondo
	CALL fl_mensaje_registro_ingresado()
	LET resul    = 1
ELSE
	LET int_flag = 0
	LET resul    = 0
END IF
CLOSE WINDOW w_rolf210_2
RETURN resul

END FUNCTION



FUNCTION retorna_fondo_empleado(r_regemp)
DEFINE r_regemp		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				per_ini		LIKE rolt038.n38_fecha_ini,
				per_fin		LIKE rolt038.n38_fecha_fin,
				tot_gan		LIKE rolt038.n38_ganado_per,
				val_fon		LIKE rolt038.n38_valor_fondo
			END RECORD
DEFINE valor		LIKE rolt038.n38_ganado_per
DEFINE per_i		LIKE rolt038.n38_fecha_ini
DEFINE per_f		LIKE rolt038.n38_fecha_fin
DEFINE dia		SMALLINT

IF DAY(r_regemp.per_ini) < 15 THEN
	LET dia = 1
ELSE
	LET dia = 15
END IF
LET per_i = MDY(MONTH(r_regemp.per_ini), dia, YEAR(r_regemp.per_ini))
IF DAY(r_regemp.per_fin) < 15 THEN
	LET dia = 15
ELSE
	LET dia = DAY(MDY(MONTH(r_regemp.per_fin), 01, YEAR(r_regemp.per_fin))
			+ 1 UNITS MONTH - 1 UNITS DAY)
END IF
LET per_f = MDY(MONTH(r_regemp.per_fin), dia, YEAR(r_regemp.per_fin))
SELECT NVL(SUM(n32_tot_gan), 0)
	INTO r_regemp.tot_gan
	FROM rolt032
	WHERE n32_compania   = vg_codcia
	  AND n32_fecha_ini >= per_i
	  AND n32_fecha_fin <= per_f
	  AND n32_cod_trab   = r_regemp.cod_trab
	  AND n32_estado     = 'C'
IF r_regemp.per_ini > per_i THEN
	SQL
	SELECT FIRST 1 NVL((NVL(n32_sueldo, n30_sueldo_mes) / n00_dias_mes), 0)
		INTO $valor
		FROM rolt032, rolt030, rolt000
		WHERE n32_compania   = $vg_codcia
		  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
				EXTEND($per_i, YEAR TO MONTH)
		  AND n32_fecha_ini <= $r_regemp.per_ini
		  AND n32_cod_trab   = $r_regemp.cod_trab
		  AND n32_estado     = 'C'
		  AND n30_compania   = n32_compania
		  AND n30_cod_trab   = n32_cod_trab
		  AND n00_serial     = n30_compania
	END SQL
	IF valor IS NOT NULL THEN
		LET r_regemp.tot_gan = r_regemp.tot_gan +
				(valor * (r_regemp.per_ini - per_i))
	END IF
ELSE
	SQL
	SELECT FIRST 1 NVL((NVL(n32_sueldo, n30_sueldo_mes) / n00_dias_mes), 0)
		INTO $valor
		FROM rolt032, rolt030, rolt000
		WHERE n32_compania   = $vg_codcia
		  AND n32_fecha_ini >= $per_i
		  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
				EXTEND($r_regemp.per_ini, YEAR TO MONTH)
		  AND n32_cod_trab   = $r_regemp.cod_trab
		  AND n32_estado     = 'C'
		  AND n30_compania   = n32_compania
		  AND n30_cod_trab   = n32_cod_trab
		  AND n00_serial     = n30_compania
	END SQL
	IF valor IS NOT NULL THEN
		LET r_regemp.tot_gan = r_regemp.tot_gan +
				(valor * (per_i - r_regemp.per_ini))
	END IF
END IF
IF r_regemp.per_fin > per_f THEN
	SQL
	SELECT FIRST 1 NVL((NVL(n32_sueldo, n30_sueldo_mes) / n00_dias_mes), 0)
		INTO $valor
		FROM rolt032, rolt030, rolt000
		WHERE n32_compania   = $vg_codcia
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
				EXTEND($per_f, YEAR TO MONTH)
		  AND n32_fecha_ini <= $r_regemp.per_fin
		  AND n32_cod_trab   = $r_regemp.cod_trab
		  AND n32_estado     = 'C'
		  AND n30_compania   = n32_compania
		  AND n30_cod_trab   = n32_cod_trab
		  AND n00_serial     = n30_compania
	END SQL
	IF valor IS NOT NULL THEN
		LET r_regemp.tot_gan = r_regemp.tot_gan +
				(valor * (r_regemp.per_fin - per_f))
	END IF
ELSE
	SQL
	SELECT FIRST 1 NVL((NVL(n32_sueldo, n30_sueldo_mes) / n00_dias_mes), 0)
		INTO $valor
		FROM rolt032, rolt030, rolt000
		WHERE n32_compania   = $vg_codcia
		  AND n32_fecha_ini >= $per_f
		  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
				EXTEND($r_regemp.per_fin, YEAR TO MONTH)
		  AND n32_cod_trab   = $r_regemp.cod_trab
		  AND n32_estado     = 'C'
		  AND n30_compania   = n32_compania
		  AND n30_cod_trab   = n32_cod_trab
		  AND n00_serial     = n30_compania
	END SQL
	IF valor IS NOT NULL THEN
		LET r_regemp.tot_gan = r_regemp.tot_gan +
				(valor * (per_f - r_regemp.per_fin))
	END IF
END IF
LET r_regemp.val_fon = r_regemp.tot_gan / 12
DISPLAY BY NAME r_regemp.*
RETURN r_regemp.*

END FUNCTION



FUNCTION control_modificar_registro(num_row, j)
DEFINE num_row, j	SMALLINT
DEFINE tot_ganado	LIKE rolt038.n38_ganado_per
DEFINE tot_valor	LIKE rolt038.n38_valor_fondo
DEFINE t_g		LIKE rolt038.n38_ganado_per

LET int_flag = 0
INPUT rm_scr[num_row].n38_ganado_per
	WITHOUT DEFAULTS FROM ra_scr[j].n38_ganado_per
	BEFORE FIELD n38_ganado_per
		LET t_g = rm_scr[num_row].n38_ganado_per
	AFTER FIELD n38_ganado_per
		IF rm_scr[num_row].n38_ganado_per IS NULL THEN
			LET rm_scr[num_row].n38_ganado_per = t_g
			DISPLAY rm_scr[num_row].n38_ganado_per
				TO ra_scr[j].n38_ganado_per
		END IF
		IF rm_scr[num_row].n38_ganado_per <= 0 THEN
			LET rm_scr[num_row].n38_ganado_per = t_g
			DISPLAY rm_scr[num_row].n38_ganado_per
				TO ra_scr[j].n38_ganado_per
		END IF
		IF rm_scr[num_row].n38_ganado_per < t_g - 100 THEN
			CALL fl_mostrar_mensaje('No puede disminuir en mas de $100.00 el total ganado. Por favor llame al administrador.', 'exclamation')
			LET rm_scr[num_row].n38_ganado_per = t_g
			DISPLAY rm_scr[num_row].n38_ganado_per
				TO ra_scr[j].n38_ganado_per
			NEXT FIELD n38_ganado_per
		END IF
		LET rm_scr[num_row].n38_valor_fondo =
					rm_scr[num_row].n38_ganado_per / 12
		DISPLAY rm_scr[num_row].n38_valor_fondo
			TO ra_scr[j].n38_valor_fondo
END INPUT
IF int_flag THEN
	LET rm_scr[num_row].n38_ganado_per = t_g
	DISPLAY rm_scr[num_row].n38_ganado_per TO ra_scr[j].n38_ganado_per
	LET int_flag = 0
ELSE
	UPDATE rolt038
		SET n38_ganado_per  = rm_scr[num_row].n38_ganado_per,
		    n38_valor_fondo = rm_scr[num_row].n38_valor_fondo
		WHERE n38_compania  = vg_codcia 
		  AND n38_fecha_ini = rm_par.n38_fecha_ini
		  AND n38_fecha_fin = rm_par.n38_fecha_fin
		  AND n38_cod_trab  = rm_scr[num_row].n38_cod_trab
		  AND n38_pago_iess = "S"
	CALL fl_mensaje_registro_modificado()
END IF
CALL calcula_totales() RETURNING tot_ganado, tot_valor
DISPLAY BY NAME tot_ganado, tot_valor 

END FUNCTION



FUNCTION control_imprimir()
DEFINE valor_enf	LIKE rolt033.n33_valor
DEFINE comando          VARCHAR(255)
DEFINE i		SMALLINT
DEFINE resp		CHAR(6)

LET comando = 'umask 0002; fglrun rolp412 ', vg_base, ' ', vg_modulo, ' ',
		vg_codcia, ' ', rm_par.n38_fecha_ini, ' ', rm_par.n38_fecha_fin,
		' > fondo_reser.txt '  
RUN comando
LET resp = NULL
IF (rm_par.n38_fecha_fin - rm_par.n38_fecha_ini + 1) < rm_n90.n90_dias_anio THEN
	LET int_flag = 0
	CALL fl_hacer_pregunta('Desea imprimir Fondo Reserva del Rol ?', 'No')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL carga_trabajadores('R')
		IF vm_numelm = 0 THEN
			CALL fl_mensaje_consulta_sin_registros()
			CALL carga_trabajadores('F')
			RETURN
		END IF
	END IF
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT report_reserva TO PIPE comando
SELECT n33_cod_trab, NVL(SUM(n33_valor), 0) val_enf
	FROM rolt033
	WHERE n33_compania    = vg_codcia
	  AND n33_cod_liqrol IN ("Q1", "Q2")
	  AND n33_fecha_ini  >= rm_par.n38_fecha_ini
	  AND n33_fecha_fin  <= rm_par.n38_fecha_fin
	  AND n33_cod_rubro  IN (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = "VE")
	  AND n33_valor       > 0
	GROUP BY 1
	INTO TEMP t1
FOR i = 1 TO vm_numelm
	LET valor_enf = 0
	SELECT NVL(val_enf, 0)
		INTO valor_enf
		FROM t1
		WHERE n33_cod_trab = rm_scr[i].n38_cod_trab
	IF valor_enf > 0 THEN
		LET rm_nov[i].fecha_nov = NULL
		LET rm_nov[i].novedad   = "ENFERMEDAD"
	END IF
	OUTPUT TO REPORT report_reserva(rm_scr[i].*, rm_nov[i].*)
END FOR
FINISH REPORT report_reserva
DROP TABLE t1
IF resp IS NOT NULL THEN
	IF resp = 'Yes' THEN
		CALL carga_trabajadores('F')
	END IF
END IF

END FUNCTION



REPORT report_reserva(r_rol)
DEFINE r_rol		RECORD
				cod_trab	LIKE rolt038.n38_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				ganado		LIKE rolt038.n38_ganado_per,
				valor_neto	LIKE rolt038.n38_valor_fondo,
				fecha_nov	DATE,
				novedad		VARCHAR(10)
			END RECORD
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i, long          SMALLINT
DEFINE fecha            DATE
DEFINE est		LIKE rolt038.n38_estado
DEFINE estado		VARCHAR(30)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	96 
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(modulo) RETURNING r_g50.*
        LET modulo      = "MODULO: ", r_g50.g50_nombre CLIPPED
        LET long        = LENGTH(modulo)
        LET usuario     = 'USUARIO: ', vg_usuario
        CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
        CALL fl_justifica_titulo('C', 'LISTADO FONDO DE RESERVA', 24)
                RETURNING titulo
	print ASCII escape;
	print ASCII act_12cpi
        PRINT COLUMN 001, rm_cia.g01_razonsocial,
              COLUMN 086, "PAGINA: ", PAGENO USING "&&&"
        PRINT COLUMN 001, modulo CLIPPED,
              COLUMN 037, titulo CLIPPED,
              COLUMN 090, UPSHIFT(vg_proceso) CLIPPED
        SKIP 1 LINES
	DECLARE q_est CURSOR FOR
		SELECT n38_estado FROM rolt038
			WHERE n38_compania  = vg_codcia          
			  AND n38_fecha_ini = rm_par.n38_fecha_ini
			  AND n38_fecha_fin = rm_par.n38_fecha_fin
			GROUP BY 1
      	OPEN q_est
	FETCH q_est INTO est
	CASE est 
		WHEN 'A'
			LET estado = 'EN PROCESO'
		WHEN 'P'
			LET estado = 'PROCESADO'
	END CASE
	CLOSE q_est
	FREE  q_est
        PRINT COLUMN 032, "** PERIODO: ", rm_par.n38_fecha_ini
		USING "dd-mm-yyyy", " - ", rm_par.n38_fecha_fin
		USING "dd-mm-yyyy",
	      COLUMN 076, fl_justifica_titulo('D', "** ESTADO: " || estado, 21)
        SKIP 1 LINES
        PRINT COLUMN 001, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy",
                         1 SPACES, TIME,
              COLUMN 078, fl_justifica_titulo('D', usuario, 19)
        PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 012, "E M P L E A D O S",
	      COLUMN 049, fl_justifica_titulo('D', "TOTAL GANADO", 13),
	      COLUMN 063, fl_justifica_titulo('D', "VALOR FONDO", 12),
	      COLUMN 076, "FECHA NOV.",
	      COLUMN 087, "NOVEDAD"
        PRINT COLUMN 001, '------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rol.cod_trab	USING '<<<&&&',
	      COLUMN 008, r_rol.nom_trab[1, 40]	CLIPPED,
	      COLUMN 049, r_rol.ganado		USING '##,###,##&.##',
	      COLUMN 063, r_rol.valor_neto	USING '#,###,##&.##',
	      COLUMN 076, r_rol.fecha_nov	USING 'dd-mm-yyyy',
	      COLUMN 087, r_rol.novedad		CLIPPED

ON LAST ROW 
	NEED 2 LINES
	PRINT COLUMN 049, '-------------',
	      COLUMN 063, '------------'
	PRINT COLUMN 003, 'No. Liq. ', vm_numelm USING "<<<<#&",
	      COLUMN 037, 'TOTALES ==> ',
	      COLUMN 049, SUM(r_rol.ganado)	USING '##,###,##&.##',
	      COLUMN 063, SUM(r_rol.valor_neto)	USING '#,###,##&.##'
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION control_consulta()
DEFINE query            VARCHAR(800)
DEFINE expr_sql         VARCHAR(400)
DEFINE exp_pi           VARCHAR(100)
DEFINE num_reg          INTEGER

INITIALIZE exp_pi TO NULL
IF num_args() = 3 THEN
	INITIALIZE pago_iess TO NULL
	CLEAR FORM
	INITIALIZE rm_par.* TO NULL
	LET int_flag = 0
	CALL mostrar_botones()
	CONSTRUCT BY NAME expr_sql ON n38_fecha_ini, n38_fecha_fin, n38_estado,
					n38_pago_iess
			BEFORE CONSTRUCT
				DISPLAY "S" TO n38_pago_iess
			AFTER FIELD n38_pago_iess
				LET pago_iess = GET_FLDBUF(n38_pago_iess)
	END CONSTRUCT
	IF pago_iess IS NULL THEN
		LET exp_pi    = '   AND n38_pago_iess = "S"'
		LET pago_iess = 'S'
	END IF
	IF int_flag THEN
	        IF vm_row_current > 0 THEN
	                CALL mostrar_registro(vm_row_current)
	        ELSE
	                CLEAR FORM
	                INITIALIZE rm_par.* TO NULL
	                CALL mostrar_botones()
	        END IF
	        RETURN
	END IF
ELSE
	LET expr_sql = 'n38_fecha_ini = "', rm_par.n38_fecha_ini, '"',
			'   AND n38_fecha_fin = "', rm_par.n38_fecha_fin, '"'
END IF
LET query = 'SELECT n38_fecha_ini, n38_fecha_fin',
		' FROM rolt038 ',
		' WHERE n38_compania  = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		exp_pi CLIPPED,
		' GROUP BY  1, 2 ',
		' ORDER BY 1 DESC'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows].* 
        LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
        LET int_flag = 0
        INITIALIZE rm_par.* TO NULL
        CALL fl_mensaje_consulta_sin_registros()
	IF num_args() <> 3 THEN
		EXIT PROGRAM
	END IF
        CLEAR FORM
        CALL mostrar_botones()
        LET vm_row_current = 0
ELSE
        LET vm_row_current = 1
        CALL mostrar_registro(vm_row_current)
        CALL muestra_contadores(vm_row_current, vm_num_rows)
END IF

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_mon            RECORD LIKE gent013.*
DEFINE num_registro     INTEGER
DEFINE r_n38            RECORD LIKE rolt038.*

IF vm_num_rows <= 0 THEN
        RETURN
END IF
INITIALIZE rm_par.* TO NULL
SELECT n38_fecha_ini, n38_fecha_fin, n38_estado 
	INTO rm_par.n38_fecha_ini, rm_par.n38_fecha_fin, rm_par.n38_estado
 	FROM rolt038 
	WHERE n38_compania  = vg_codcia 
 	  AND n38_fecha_ini = vm_r_rows[num_registro].fecha_ini
 	  AND n38_fecha_fin = vm_r_rows[num_registro].fecha_fin
	  AND n38_pago_iess = pago_iess
	GROUP BY 1, 2, 3
IF STATUS = NOTFOUND THEN
        CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' 
					|| vm_row_current,'exclamation')
        RETURN
END IF
CASE rm_par.n38_estado
        WHEN 'A'
                LET rm_par.n_estado = 'ACTIVO'
        WHEN 'P'
                LET rm_par.n_estado = 'PROCESADO'
END CASE
DISPLAY BY NAME rm_par.*
CALL muestra_detalle('C')

END FUNCTION



FUNCTION muestra_detalle(opcion)
DEFINE opcion 			CHAR(1)
DEFINE tot_ganado		LIKE rolt038.n38_ganado_per
DEFINE tot_valor		LIKE rolt038.n38_valor_fondo
DEFINE num_row			SMALLINT

IF opcion = 'C' THEN
	CALL carga_trabajadores('F')
END IF
LET int_flag = 0
CALL set_count(vm_numelm)
DISPLAY ARRAY rm_scr TO ra_scr.*
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT DISPLAY
	ON KEY(F5)
		LET num_row = arr_curr()
		CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
						rm_scr[num_row].n38_cod_trab,
						rm_par.n38_fecha_ini,
						rm_par.n38_fecha_fin)
		LET int_flag = 0
	BEFORE DISPLAY
                --#CALL dialog.keysetlabel('F5','Detalle Tot. Gan.')
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		CALL calcula_totales() RETURNING tot_ganado, tot_valor
		DISPLAY BY NAME tot_ganado, tot_valor
		EXIT DISPLAY
	BEFORE ROW
		LET num_row = arr_curr()
		CALL muestra_contadores_det(num_row, vm_numelm)
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY
CALL muestra_lineas_detalle()
CALL muestra_contadores_det(0, vm_numelm)

END FUNCTION



FUNCTION carga_trabajadores(flag)
DEFINE flag		CHAR(1)
DEFINE query		CHAR(2600)
DEFINE tabla		VARCHAR(15)
DEFINE pre		CHAR(2)
DEFINE expr_col		CHAR(1200)
DEFINE expr_join	CHAR(600)
DEFINE expr_iess	VARCHAR(100)
DEFINE fec_ini, fec_fin	DATE

LET tabla     = NULL
LET pre       = '38'
LET expr_col  = ' n38_ganado_per, n38_valor_fondo, ',
		'CASE WHEN n30_estado = "A" ',
			'THEN ',
				'CASE WHEN (YEAR(n', pre, '_fecha_ini) = ',
					'YEAR(n', pre, '_fecha_ing)) OR ',
					'(n', pre, '_fecha_ini <= n', pre,
					'_fecha_ing) ',
					'THEN n', pre, '_fecha_ing ',
				'END ',
			'ELSE ',
				'CASE WHEN (YEAR(n', pre, '_fecha_fin) = ',
					'YEAR(n30_fecha_sal)) OR ',
					'(n', pre,
					'_fecha_fin >= n30_fecha_sal) ',
					'THEN n30_fecha_sal ',
				'END ',
		'END, ',
		'CASE WHEN n30_estado = "A" ',
			'THEN ',
				'CASE WHEN (YEAR(n', pre, '_fecha_ini) = ',
					'YEAR(n', pre, '_fecha_ing)) OR ',
					'(n', pre, '_fecha_ini <= n', pre,
					'_fecha_ing) ',
					'THEN "ENTRADA" ',
				'END ',
			'ELSE ',
				'CASE WHEN (YEAR(n', pre, '_fecha_fin) = ',
					'YEAR(n30_fecha_sal)) OR ',
					'(n', pre,
					'_fecha_fin >= n30_fecha_sal) ',
					'THEN "SALIDA" ',
				'END ',
		'END '
LET expr_join = NULL
LET fec_ini   = rm_par.n38_fecha_ini
LET fec_fin   = rm_par.n38_fecha_fin
LET expr_iess = '   AND n38_pago_iess = "', pago_iess, '"'
IF flag = 'R' THEN
	LET expr_iess = '   AND n38_pago_iess = "N" '
	{
	LET tabla     = ', rolt033 '
	LET pre       = '32'
	LET expr_col  = ' n33_valor * 100 / (SELECT n07_factor ',
			'FROM rolt007 WHERE n07_cod_rubro = n33_cod_rubro), ',
			'n33_valor, "", ""'
	LET expr_join = '   AND n33_compania   = n32_compania ',
			'   AND n33_cod_liqrol = n32_cod_liqrol ',
			'   AND n33_fecha_ini  = n32_fecha_ini ',
			'   AND n33_fecha_fin  = n32_fecha_fin ',
			'   AND n33_cod_trab   = n32_cod_trab ',
			'   AND n33_cod_rubro  = (SELECT n06_cod_rubro ',
						'FROM rolt006 ',
						'WHERE n06_flag_ident = "FM")',
			'   AND n33_valor      > 0 '
	LET fec_ini   = rm_par.n38_fecha_fin + 1 UNITS DAY
	LET fec_fin   = fec_ini + 14 UNITS DAY
	}
END IF
LET query = 'SELECT n', pre, '_cod_trab, n30_nombres, ',
		expr_col CLIPPED,
            ' FROM rolt0', pre, tabla CLIPPED, ', rolt030 ',
            ' WHERE n', pre, '_compania   = ', vg_codcia,
	    '   AND n', pre, '_fecha_ini  = "', fec_ini, '"',
	    '   AND n', pre, '_fecha_fin  = "', fec_fin, '"',
		expr_join CLIPPED,
		expr_iess CLIPPED,
	    '   AND n30_compania   = n', pre, '_compania ',
	    '   AND n30_cod_trab   = n', pre, '_cod_trab ',
            ' ORDER BY n30_nombres '
PREPARE cons1 FROM query
DECLARE q_trab2 CURSOR FOR cons1
LET vm_numelm = 1
FOREACH q_trab2 INTO rm_scr[vm_numelm].*, rm_nov[vm_numelm].*
        LET vm_numelm = vm_numelm + 1
        IF vm_numelm > vm_maxelm THEN
                CALL fl_mensaje_arreglo_incompleto()
                EXIT PROGRAM
        END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i, lim		SMALLINT

FOR i = 1 TO fgl_scr_size('ra_scr')
	CLEAR ra_scr[i].*
END FOR
LET lim = vm_numelm
IF lim > fgl_scr_size('ra_scr') THEN
	LET lim = fgl_scr_size('ra_scr')
END IF
FOR i = 1 TO lim
	DISPLAY rm_scr[i].* TO ra_scr[i].*
END FOR

END FUNCTION


FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row		SMALLINT
DEFINE max_row		SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_reabrir()
DEFINE r_n38		RECORD LIKE rolt038.*
DEFINE r_n53		RECORD LIKE rolt053.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_row_current)
IF rm_par.n38_estado = 'A' THEN
	CALL fl_mostrar_mensaje('El Fondo de Reserva ya esta ABIERTO.', 'exclamation')
	RETURN
END IF
INITIALIZE r_n53.* TO NULL
SELECT * INTO r_n53.*
	FROM rolt053
	WHERE n53_compania   = vg_codcia
	  AND n53_cod_liqrol = vm_proceso
	  AND n53_fecha_ini  = rm_par.n38_fecha_ini
	  AND n53_fecha_fin  = rm_par.n38_fecha_fin
IF r_n53.n53_compania IS NOT NULL THEN
	CALL fl_mostrar_mensaje('No puede REABRIR este Fondo de Reserva, porque esta contabilizado.', 'exclamation')
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_reab CURSOR FOR
	SELECT * FROM rolt038
	        WHERE n38_compania  = vg_codcia
		  AND n38_fecha_ini = rm_par.n38_fecha_ini
		  AND n38_fecha_fin = rm_par.n38_fecha_fin
		  AND n38_pago_iess = "S"
        FOR UPDATE
OPEN q_reab
FETCH q_reab INTO r_n38.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        WHENEVER ERROR STOP
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
WHENEVER ERROR STOP
UPDATE rolt038
	SET n38_estado = 'A' 
	WHERE n38_compania  = vg_codcia 
	  AND n38_fecha_ini = rm_par.n38_fecha_ini
	  AND n38_fecha_fin = rm_par.n38_fecha_fin
	  AND n38_pago_iess = "S"
UPDATE rolt005
	SET n05_activo     = 'S',
	    n05_fecini_act = NULL,
	    n05_fecfin_act = NULL
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = rm_n05.n05_proceso
	  AND n05_activo   = 'N'
COMMIT WORK
CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
CALL mostrar_registro(vm_row_current)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mostrar_mensaje('Fondo de Reserva ha sido REABIERTO.', 'info')

END FUNCTION



FUNCTION control_cerrar()
DEFINE r_n38		RECORD LIKE rolt038.*
DEFINE resp		VARCHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_row_current)
IF rm_par.n38_estado = 'P' THEN
	CALL fl_mostrar_mensaje('El Fondo de Reserva ya esta CERRADO.', 'exclamation')
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'No' THEN
        LET int_flag = 0
        RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_cerr CURSOR FOR
	SELECT * FROM rolt038
	        WHERE n38_compania  = vg_codcia
		  AND n38_fecha_ini = rm_par.n38_fecha_ini
		  AND n38_fecha_fin = rm_par.n38_fecha_fin
		  AND n38_pago_iess = "S"
        FOR UPDATE
OPEN q_cerr
FETCH q_cerr INTO r_n38.*
IF STATUS < 0 THEN
        ROLLBACK WORK
        WHENEVER ERROR STOP
        CALL fl_mensaje_bloqueo_otro_usuario()
        RETURN
END IF
WHENEVER ERROR STOP
UPDATE rolt038
	SET n38_estado = 'P' 
	WHERE n38_compania  = vg_codcia 
	  AND n38_fecha_ini = rm_par.n38_fecha_ini
	  AND n38_fecha_fin = rm_par.n38_fecha_fin
	  AND n38_pago_iess = "S"
UPDATE rolt005
	SET n05_activo     = 'N',
	    n05_fecini_act = rm_par.n38_fecha_ini,
	    n05_fecfin_act = rm_par.n38_fecha_fin
	WHERE n05_compania = vg_codcia
	  AND n05_proceso  = rm_n05.n05_proceso
	  AND n05_activo   = 'S'
COMMIT WORK
CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
CALL mostrar_registro(vm_row_current)
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mostrar_mensaje('Fondo de Reserva ha sido CERRADO.', 'info')

END FUNCTION
