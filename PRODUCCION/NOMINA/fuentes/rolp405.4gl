--------------------------------------------------------------------------------
-- Titulo           : rolp405.4gl - Impresión recibos de pagos de roles
-- Elaboracion      : 19-Jul-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp405 base módulo compañía
-- 			[año] [mes] [liqrol] [[agrupado]] [[depto]] [[cod_trab]]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_n33		RECORD LIKE rolt033.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE vm_cod_depto	LIKE rolt032.n32_cod_depto
DEFINE vm_cod_trab	LIKE rolt032.n32_cod_trab
DEFINE n1, n2, fin_arch	INTEGER
DEFINE num_liq, tot_liq	INTEGER
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE tit_mes		VARCHAR(10)
DEFINE tot_sueldo	DECIMAL(14,2)
DEFINE tot_ganado	DECIMAL(14,2)
DEFINE tot_descontar	DECIMAL(14,2)
DEFINE vm_agrupado	CHAR(1)
DEFINE vm_imprimir	CHAR(1)
DEFINE vm_imprimir_emp	CHAR(1)
DEFINE vm_impr_total	CHAR(1)
DEFINE vm_lineas_impr	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp405.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 7 AND num_args() <> 8 AND num_args() <> 9
THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp405'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE comando		CHAR(100)
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*

CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	EXIT PROGRAM
END IF
IF rm_loc.g02_localidad = 1 OR rm_loc.g02_localidad = 6 THEN
	LET vm_lineas_impr = 33
END IF
IF rm_loc.g02_localidad = 3 OR rm_loc.g02_localidad = 7 THEN
	LET vm_lineas_impr = 44
END IF
CREATE TEMP TABLE temp_ing_rub(
		cod_trab		INTEGER,
		cod_rub			CHAR(3),
		nombre			VARCHAR(15,10),
		valor_aux		DECIMAL(12,2),
		valor			DECIMAL(12,2),
		orden			INTEGER,
		depto			SMALLINT
	)
CREATE TEMP TABLE temp_des_rub(
		cod_trab		INTEGER,
		cod_rub			CHAR(3),
		nombre			VARCHAR(15,10),
		valor_aux		DECIMAL(12,2),
		valor			DECIMAL(12,2),
		orden			INTEGER,
		det_tot			CHAR(2)
	)
LET vm_imprimir     = 'N'
LET vm_imprimir_emp = 'N'
LET vm_impr_total   = 'N'
IF num_args() <> 3 THEN
	CALL control_reporte_llamada()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 16
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf405_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf405_1 FROM "../forms/rolf405_1"
ELSE
	OPEN FORM f_rolf405_1 FROM "../forms/rolf405_1c"
END IF
DISPLAY FORM f_rolf405_1
INITIALIZE rm_n32.* TO NULL
LET vm_agrupado            = 'S'
LET rm_n32.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_n32.n32_mes_proceso = r_n01.n01_mes_proceso
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fec_cierre DESC
OPEN q_n05
FETCH q_n05 INTO r_n05.*
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania  = r_n05.n05_compania
		  AND n32_estado   <> 'E'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n32.n32_cod_liqrol  = r_n32.n32_cod_liqrol
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
CALL fl_retorna_nombre_mes(rm_n32.n32_mes_proceso) RETURNING tit_mes
DISPLAY BY NAME tit_mes
CLOSE q_ultliq
FREE q_ultliq
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL preparar_tablas()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL control_reporte(comando)
	CLEAR g34_nombre, n30_nombres
	DELETE FROM temp_ing_rub
	DELETE FROM temp_des_rub
END WHILE
DROP TABLE temp_ing_rub
DROP TABLE temp_des_rub
CLOSE WINDOW w_rolf405_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_reporte_llamada()
DEFINE comando		CHAR(100)

INITIALIZE rm_n32.* TO NULL
LET rm_n32.n32_ano_proceso = arg_val(4)
LET rm_n32.n32_mes_proceso = arg_val(5)
LET rm_n32.n32_cod_liqrol  = arg_val(6)
LET vm_agrupado            = arg_val(7)
IF rm_n32.n32_cod_liqrol = 'XX' THEN
	LET rm_n32.n32_fecha_ini   = arg_val(4)
	LET rm_n32.n32_fecha_fin   = arg_val(5)
	LET rm_n32.n32_ano_proceso = YEAR(rm_n32.n32_fecha_fin)
	LET rm_n32.n32_mes_proceso = MONTH(rm_n32.n32_fecha_fin)
END IF
IF num_args() = 8 THEN
	LET rm_n32.n32_cod_depto = arg_val(8)
	LET vm_cod_depto         = rm_n32.n32_cod_depto
	LET vm_cod_trab          = NULL
END IF
IF num_args() = 9 THEN
	LET rm_n32.n32_cod_depto = arg_val(8)
	LET rm_n32.n32_cod_trab  = arg_val(9)
	LET vm_cod_depto         = rm_n32.n32_cod_depto
	LET vm_cod_trab          = rm_n32.n32_cod_trab
	LET vm_imprimir_emp      = 'S'
END IF
IF rm_n32.n32_cod_depto = 0 THEN
	LET rm_n32.n32_cod_depto = NULL
	LET vm_cod_depto         = NULL
END IF
IF vm_agrupado = 'T' THEN
	LET vm_agrupado     = 'N'
	LET vm_impr_total   = 'S'
	LET vm_imprimir_emp = 'N'
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	DROP TABLE temp_ing_rub
	DROP TABLE temp_des_rub
	RETURN
END IF
CALL preparar_tablas()
IF int_flag THEN
	DROP TABLE temp_ing_rub
	DROP TABLE temp_des_rub
	RETURN
END IF
CALL control_reporte(comando)
DROP TABLE temp_ing_rub
DROP TABLE temp_des_rub

END FUNCTION



FUNCTION lee_parametros()
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*

CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre
LET int_flag = 0
INPUT BY NAME rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso,
	rm_n32.n32_cod_liqrol, rm_n32.n32_cod_depto, rm_n32.n32_cod_trab,
	vm_agrupado, vm_imprimir, vm_imprimir_emp, vm_impr_total
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(n32_mes_proceso) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET rm_n32.n32_mes_proceso = mes_aux
				DISPLAY BY NAME rm_n32.n32_mes_proceso, tit_mes
			END IF
                END IF
		IF INFIELD(n32_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n32.n32_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n32.n32_cod_liqrol,
						r_n03.n03_nombre  
			END IF
		END IF
		IF INFIELD(n32_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_n32.n32_cod_depto = r_g34.g34_cod_depto
                                DISPLAY BY NAME rm_n32.n32_cod_depto,
						r_g34.g34_nombre
                        END IF
                END IF
		IF INFIELD(n32_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n32.n32_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n32.n32_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD n32_ano_proceso
		LET anio = rm_n32.n32_ano_proceso
	BEFORE FIELD n32_mes_proceso
		LET mes = rm_n32.n32_mes_proceso
	AFTER FIELD n32_ano_proceso
		IF rm_n32.n32_ano_proceso IS NOT NULL THEN
			IF rm_n32.n32_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n32_ano_proceso
			END IF
		ELSE
			LET rm_n32.n32_ano_proceso = anio
			DISPLAY BY NAME rm_n32.n32_ano_proceso
		END IF
	AFTER FIELD n32_mes_proceso
		IF rm_n32.n32_mes_proceso IS NULL THEN
			LET rm_n32.n32_mes_proceso = mes
			DISPLAY BY NAME rm_n32.n32_mes_proceso
		END IF
		CALL fl_retorna_nombre_mes(rm_n32.n32_mes_proceso)
			RETURNING tit_mes
		DISPLAY BY NAME tit_mes
	AFTER FIELD n32_cod_liqrol
		IF rm_n32.n32_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n32_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n32_cod_depto
                IF rm_n32.n32_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_n32.n32_cod_depto)
                                RETURNING r_g34.*
                        IF r_g34.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Departamento no existe.','exclamation')
                                NEXT FIELD n32_cod_depto
                        END IF
                        DISPLAY BY NAME r_g34.g34_nombre
		ELSE
			CLEAR g34_nombre
                END IF
	AFTER FIELD n32_cod_trab
		IF rm_n32.n32_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n32.n32_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n32_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
		ELSE
			CLEAR n30_nombres
		END IF
	AFTER INPUT
		IF rm_n32.n32_cod_trab IS NULL THEN
			LET vm_imprimir = 'N'
			DISPLAY BY NAME vm_imprimir
		END IF
		IF vm_imprimir = 'S' THEN
			LET vm_agrupado = 'N'
			DISPLAY BY NAME vm_agrupado
		END IF
		IF vm_imprimir_emp = 'S' THEN
			LET vm_agrupado   = 'N'
			LET vm_imprimir   = 'N'
			LET vm_impr_total = 'N'
			DISPLAY BY NAME vm_agrupado, vm_imprimir, vm_impr_total
			IF rm_n32.n32_cod_trab IS NULL THEN
				CALL fl_mostrar_mensaje('Digite el código del empleado.', 'exclamation')
				NEXT FIELD n32_cod_trab
			END IF
		END IF
END INPUT
LET vm_cod_depto = rm_n32.n32_cod_depto
LET vm_cod_trab  = rm_n32.n32_cod_trab

END FUNCTION


   
FUNCTION preparar_tablas()
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n32		RECORD
				n32_compania	LIKE rolt032.n32_compania,
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n32_cod_depto	LIKE rolt032.n32_cod_depto,
				n32_orden	LIKE rolt032.n32_orden,
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_n33		RECORD
				n33_cod_rubro	LIKE rolt033.n33_cod_rubro,
				n33_orden	LIKE rolt033.n33_orden,
				n33_det_tot	LIKE rolt033.n33_det_tot,
				n33_imprime_0	LIKE rolt033.n33_imprime_0,
				n33_cant_valor	LIKE rolt033.n33_cant_valor,
				n33_horas_porc	LIKE rolt033.n33_horas_porc,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE query		CHAR(2000)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_lq		VARCHAR(100)

IF rm_n32.n32_cod_liqrol <> 'XX' THEN
	CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso)
		RETURNING fecha_ini, fecha_fin
ELSE
	LET fecha_ini = rm_n32.n32_fecha_ini
	LET fecha_fin = rm_n32.n32_fecha_fin
END IF
LET expr_depto = NULL
IF rm_n32.n32_cod_depto IS NOT NULL AND vm_imprimir = 'N' THEN
	LET expr_depto = '   AND a.n32_cod_depto    = ', rm_n32.n32_cod_depto
END IF
LET expr_trab = NULL
IF rm_n32.n32_cod_trab IS NOT NULL AND vm_imprimir = 'N'
   OR vm_imprimir_emp = 'S'
THEN
	LET expr_trab = '   AND a.n32_cod_trab    = ', rm_n32.n32_cod_trab
END IF
LET expr_lq = '   AND a.n32_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"'
IF rm_n32.n32_cod_liqrol = 'XX' THEN
	LET expr_lq = '   AND a.n32_cod_liqrol IN ("Q1", "Q2") '
END IF
LET query = 'SELECT a.n32_compania, a.n32_cod_trab, a.n32_cod_depto, ',
		' CASE WHEN "', rm_n32.n32_cod_liqrol, '" <> "XX" ',
			' THEN a.n32_orden ',
			' ELSE 1 ',
		' END, NVL(SUM(a.n32_tot_ing), 0), ',
		'NVL(SUM(a.n32_tot_egr), 0), NVL(SUM(a.n32_tot_neto), 0) ',
		' FROM rolt032 a ',
		' WHERE a.n32_compania    = ', vg_codcia,
			expr_lq CLIPPED,
		'   AND a.n32_fecha_ini  >= "', fecha_ini, '"',
		'   AND a.n32_fecha_fin  <= "', fecha_fin, '"',
		expr_depto CLIPPED,
		expr_trab CLIPPED,
		'   AND a.n32_estado     <> "E" ',
		' GROUP BY 1, 2, 3, 4 ',
		' ORDER BY 4'
PREPARE cons FROM query
DECLARE q_rolt032 CURSOR FOR cons
OPEN q_rolt032
FETCH q_rolt032 INTO r_n32.*
IF STATUS = NOTFOUND THEN
	CLOSE q_rolt032
	FREE q_rolt032
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
LET expr_lq = '   AND n33_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"'
IF rm_n32.n32_cod_liqrol = 'XX' THEN
	LET expr_lq = '   AND n33_cod_liqrol IN ("Q1", "Q2") '
END IF
FOREACH q_rolt032 INTO r_n32.*
	LET query = 'SELECT n33_cod_rubro, n33_orden, n33_det_tot, ',
			'n33_imprime_0, n33_cant_valor, ',
			'NVL(SUM(n33_horas_porc), 0), ',
			'NVL(SUM(n33_valor), 0)',
			' FROM rolt033 ',
			' WHERE n33_compania    = ', r_n32.n32_compania,
				expr_lq CLIPPED,
			'   AND n33_fecha_ini  >= "', fecha_ini, '"',
			'   AND n33_fecha_fin  <= "', fecha_fin, '"',
			'   AND n33_cod_trab    = ', r_n32.n32_cod_trab,
			' GROUP BY 1, 2, 3, 4, 5 '
	PREPARE tmp_det_n FROM query
	DECLARE q_n33 CURSOR FOR tmp_det_n
	FOREACH q_n33 INTO r_n33.*
		IF r_n33.n33_imprime_0 = 'N' THEN
			IF r_n33.n33_valor = 0 THEN
	  			IF r_n33.n33_horas_porc IS NULL OR
					r_n33.n33_horas_porc = 0
				THEN
					CONTINUE FOREACH
				END IF
			END IF
		END IF
		IF r_n33.n33_cant_valor <> 'V' THEN
			CONTINUE FOREACH
		END IF
		CALL fl_lee_rubro_roles(r_n33.n33_cod_rubro) RETURNING r_n06.*
		IF r_n06.n06_flag_ident = 'DC' THEN
			CONTINUE FOREACH
		END IF
		IF r_n33.n33_det_tot = 'DI' THEN
			INSERT INTO temp_ing_rub
				VALUES(r_n32.n32_cod_trab, r_n33.n33_cod_rubro,
					r_n06.n06_nombre_abr,
					r_n33.n33_horas_porc, r_n33.n33_valor,
					r_n33.n33_orden, r_n32.n32_cod_depto)
		END IF
		IF r_n33.n33_det_tot = 'DE' OR r_n33.n33_det_tot = 'TE' OR
		   r_n33.n33_det_tot = 'TI' OR r_n33.n33_det_tot = 'TN' THEN
			INSERT INTO temp_des_rub
				VALUES(r_n32.n32_cod_trab, r_n33.n33_cod_rubro,
					r_n06.n06_nombre_abr,
					r_n33.n33_horas_porc, r_n33.n33_valor,
					r_n33.n33_orden, r_n33.n33_det_tot)
		END IF
	END FOREACH
	INSERT INTO temp_des_rub
			VALUES(r_n32.n32_cod_trab, r_n33.n33_cod_rubro,
				"TOTAL INGRESOS", NULL, r_n32.n32_tot_ing,
				r_n33.n33_orden, 'TI')
	INSERT INTO temp_des_rub
			VALUES(r_n32.n32_cod_trab, r_n33.n33_cod_rubro,
				"TOTAL DESCUENTOS", NULL, r_n32.n32_tot_egr,
				r_n33.n33_orden, 'TE')
	INSERT INTO temp_des_rub
			VALUES(r_n32.n32_cod_trab, r_n33.n33_cod_rubro,
				"TOTAL A RECIBIR", NULL, r_n32.n32_tot_neto,
				r_n33.n33_orden, 'TN')
END FOREACH
SELECT COUNT(*) INTO n1 FROM temp_ing_rub
SELECT COUNT(*) INTO n2 FROM temp_des_rub WHERE det_tot = 'DE'
IF n1 = 0 AND n2 = 0 THEN
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

END FUNCTION



FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE cod_traba	LIKE rolt032.n32_cod_trab
DEFINE r_n32		RECORD
				n32_compania	LIKE rolt032.n32_compania,
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n32_cod_depto	LIKE rolt032.n32_cod_depto,
				n32_estado	LIKE rolt032.n32_estado,
				n32_moneda	LIKE rolt032.n32_moneda,
				n32_dias_falt	LIKE rolt032.n32_dias_falt,
				n32_sueldo	LIKE rolt032.n32_sueldo,
				n32_tot_gan	LIKE rolt032.n32_tot_gan
			END RECORD
DEFINE r_ing		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				cod_rub		LIKE rolt033.n33_cod_rubro,
				nombre		LIKE rolt003.n03_nombre_abr,
				valor_aux	LIKE rolt033.n33_horas_porc,
				valor		LIKE rolt033.n33_valor,
				orden		LIKE rolt033.n33_orden,
				depto		LIKE rolt032.n32_cod_depto
			END RECORD
DEFINE r_des		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				cod_rub		LIKE rolt033.n33_cod_rubro,
				nombre		LIKE rolt003.n03_nombre_abr,
				valor_aux	LIKE rolt033.n33_horas_porc,
				valor		LIKE rolt033.n33_valor,
				orden		LIKE rolt033.n33_orden,
				det_tot		LIKE rolt033.n33_det_tot
			END RECORD
DEFINE nom		LIKE rolt030.n30_nombres
DEFINE dep		LIKE gent034.g34_nombre
DEFINE expr_orden	CHAR(50)
DEFINE query		CHAR(1500)
DEFINE tl1, tl2		INTEGER

LET expr_orden = ' ORDER BY g34_nombre, n30_nombres'
IF vm_agrupado = 'N' THEN
	LET expr_orden = ' ORDER BY n30_nombres'
END IF
LET query = 'SELECT UNIQUE cod_trab, n30_nombres, g34_nombre ',
		' FROM temp_ing_rub, rolt030, gent034 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND cod_trab      = n30_cod_trab ',
		'   AND n30_compania  = g34_compania ',
		'   AND n30_cod_depto = g34_cod_depto ',
		expr_orden CLIPPED
PREPARE tmp_t1 FROM query
DECLARE q_t1 CURSOR FOR tmp_t1
IF vm_imprimir = 'S' THEN
	FOREACH q_t1 INTO cod_traba, nom, dep
		IF rm_n32.n32_cod_trab = cod_traba THEN
			EXIT FOREACH
		END IF
		DELETE FROM temp_ing_rub WHERE cod_trab = cod_traba
		DELETE FROM temp_des_rub WHERE cod_trab = cod_traba
	END FOREACH
END IF
START REPORT reporte_liq_rubros TO PIPE comando
--START REPORT reporte_liq_rubros TO FILE "liqrol.txt"
SELECT COUNT(DISTINCT cod_trab) INTO tl1 FROM temp_ing_rub
SELECT COUNT(DISTINCT cod_trab) INTO tl2 FROM temp_des_rub
LET tot_liq = tl1
IF tl2 > tl1 THEN
	LET tot_liq = tl2
END IF
LET fin_arch      = 0
LET num_liq       = 0
LET tot_sueldo    = 0
LET tot_ganado    = 0
LET tot_descontar = 0
FOREACH q_t1 INTO cod_traba, nom, dep
	IF rm_n32.n32_cod_liqrol <> 'XX' THEN
		CALL fl_lee_liquidacion_roles(vg_codcia, rm_n32.n32_cod_liqrol,
						fecha_ini, fecha_fin, cod_traba)
			RETURNING rm_n32.*
	ELSE
		LET query = 'SELECT a.n32_compania, a.n32_cod_trab, ',
				'a.n32_cod_depto, a.n32_estado, a.n32_moneda, ',
				'NVL(SUM(a.n32_dias_falt), 0), ',
				'NVL(SUM(a.n32_sueldo / ',
				' CASE WHEN "', rm_n32.n32_cod_liqrol,
						'" = "XX" ',
				' THEN ',
				' (SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab) ',
				' ELSE 1 ',
				' END), 0), ',
				'NVL(SUM(a.n32_tot_gan), 0) ',
				' FROM rolt032 a ',
				' WHERE a.n32_compania    = ', vg_codcia,
				'   AND a.n32_cod_liqrol IN ("Q1", "Q2") ',
				'   AND a.n32_fecha_ini  >= "', fecha_ini, '"',
				'   AND a.n32_fecha_fin  <= "', fecha_fin, '"',
				'   AND a.n32_cod_trab    = ', cod_traba,
				'   AND a.n32_estado     <> "E" ',
				' GROUP BY 1, 2, 3, 4, 5 '
		PREPARE reg_trab FROM query
		DECLARE q_reg_trab CURSOR FOR reg_trab
		OPEN q_reg_trab
		FETCH q_reg_trab INTO r_n32.*
		CLOSE q_reg_trab
		FREE q_reg_trab
		LET rm_n32.n32_compania  = r_n32.n32_compania
		LET rm_n32.n32_cod_trab	 = r_n32.n32_cod_trab
		LET rm_n32.n32_cod_depto = r_n32.n32_cod_depto
		LET rm_n32.n32_estado    = r_n32.n32_estado
		LET rm_n32.n32_moneda    = r_n32.n32_moneda
		LET rm_n32.n32_dias_falt = r_n32.n32_dias_falt
		LET rm_n32.n32_sueldo    = r_n32.n32_sueldo
		LET rm_n32.n32_tot_gan   = r_n32.n32_tot_gan
	END IF
	OUTPUT TO REPORT reporte_liq_rubros(cod_traba)
END FOREACH
FINISH REPORT reporte_liq_rubros
LET rm_n32.n32_cod_depto = NULL
LET rm_n32.n32_cod_trab  = NULL

END FUNCTION



REPORT reporte_liq_rubros(cod_traba)
DEFINE cod_traba	LIKE rolt032.n32_cod_trab
DEFINE r_ing		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				cod_rub		LIKE rolt033.n33_cod_rubro,
				nombre		LIKE rolt003.n03_nombre_abr,
				valor_aux	LIKE rolt033.n33_horas_porc,
				valor		LIKE rolt033.n33_valor,
				orden		LIKE rolt033.n33_orden,
				depto		LIKE rolt032.n32_cod_depto
			END RECORD
DEFINE r_des		RECORD
				cod_trab	LIKE rolt033.n33_cod_trab,
				cod_rub		LIKE rolt033.n33_cod_rubro,
				nombre		LIKE rolt003.n03_nombre_abr,
				valor_aux	LIKE rolt033.n33_horas_porc,
				valor		LIKE rolt033.n33_valor,
				orden		LIKE rolt033.n33_orden,
				det_tot		LIKE rolt033.n33_det_tot
			END RECORD
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_cen		RECORD LIKE tr_cesantia.*
DEFINE cod_r_i, cod_r_d	LIKE rolt033.n33_cod_rubro
DEFINE ord_i, ord_d	LIKE rolt033.n33_orden
DEFINE tot_val_i_a	DECIMAL(14,2)
DEFINE tot_val_d_a	DECIMAL(14,2)
DEFINE tot_val_i	DECIMAL(14,2)
DEFINE tot_val_d	DECIMAL(14,2)
DEFINE i, lim		INTEGER
DEFINE suel_t, val_rep	VARCHAR(15)
DEFINE tot_gan		VARCHAR(15)
DEFINE val_i, val_d	VARCHAR(10)
DEFINE nom_est		VARCHAR(10)
DEFINE mensaje		VARCHAR(80)
DEFINE titulo		VARCHAR(80)
DEFINE forma_pago	VARCHAR(31)
DEFINE nom_depto	VARCHAR(36)
DEFINE encont		SMALLINT
DEFINE lineas, postit	SMALLINT
DEFINE escape, act_des	SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	0
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	2
	PAGE LENGTH	vm_lineas_impr

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_des	= 0
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_trabajador_roles(vg_codcia, cod_traba) RETURNING r_n30.*
	CALL fl_lee_moneda(rm_n32.n32_moneda) RETURNING r_g13.*
	CALL fl_lee_departamento(rm_n32.n32_compania, rm_n32.n32_cod_depto)
		RETURNING r_g34.*
	CALL retorna_estado(rm_n32.n32_estado) RETURNING nom_est
	CALL retorna_forma_pago(r_n30.n30_cod_trab) RETURNING forma_pago
	LET suel_t  = rm_n32.n32_sueldo  USING "--,---,--&.##"
	LET tot_gan = rm_n32.n32_tot_gan USING "--,---,--&.##"
	--print '&k2S' 		-- Letra condensada
	--print ASCII escape;
	--print ASCII act_comp
	IF NOT fin_arch AND vm_impr_total = 'N' THEN
		LET tot_sueldo = tot_sueldo + rm_n32.n32_sueldo
		LET tot_ganado = tot_ganado + rm_n32.n32_tot_gan
		LET nom_depto  = '** ', r_g34.g34_nombre CLIPPED, ' **'
		LET postit     = 96 - LENGTH(nom_depto) + 1
		print ASCII escape;
		print ASCII act_neg;
		print ASCII escape;
		print ASCII act_12cpi
		PRINT COLUMN 001, rm_cia.g01_razonsocial,
		      COLUMN postit, nom_depto
		PRINT COLUMN 042, "RECIBO DE PAGO"
		SKIP 1 LINES
		PRINT COLUMN 001, "NOMBRE(", r_n30.n30_cod_trab
						USING "&&&&", "): ",
				r_n30.n30_nombres[1,36];
		IF rm_n32.n32_cod_liqrol <> 'XX' THEN
			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
				RETURNING r_n03.*
			PRINT COLUMN 055, "LIQUIDACION : ",
				rm_n32.n32_cod_liqrol, " ",
				r_n03.n03_nombre_abr
		ELSE
			PRINT COLUMN 055, "LIQUIDACION: TODAS LAS LIQUID."
		END IF
		PRINT COLUMN 001, "SUELDO MENS.: ", r_g13.g13_simbolo CLIPPED,
			" ", fl_justifica_titulo('I', suel_t, 15),
		      COLUMN 055, "PERIODO     : ",fecha_ini USING "dd-mm-yyyy",
				' - ', fecha_fin USING "dd-mm-yyyy"
		PRINT COLUMN 001, "FORMA PAGO  : ", forma_pago,
		      COLUMN 055, "ESTADO LIQ. : ", nom_est
		PRINT COLUMN 001, "TOTAL GANADO: ", r_g13.g13_simbolo CLIPPED,
			" ", fl_justifica_titulo('I', tot_gan, 15);
		IF rm_n32.n32_dias_falt > 0 THEN
			PRINT COLUMN 055, "DIAS FALTADO: ",
				rm_n32.n32_dias_falt USING "<<<<&"
		ELSE
			PRINT COLUMN 055, " "
		END IF
		SKIP 1 LINES
		PRINT COLUMN 001, "INGRESOS    : ",
		      COLUMN 052, "DESCUENTOS     : ",
		      COLUMN 078, DATE(TODAY) USING 'dd-mm-yyyy', 1 SPACES, TIME
		PRINT "------------------------------------------------------------------------------------------------";
		print ASCII escape;
		print ASCII des_neg
	ELSE
		IF vm_imprimir_emp = 'N' THEN
			IF vm_impr_total = 'S' THEN
				IF rm_n32.n32_cod_liqrol <> 'XX' THEN
					SELECT COUNT(*),SUM(n32_sueldo),
						SUM(n32_tot_gan)
					INTO num_liq, tot_sueldo, tot_ganado
					FROM rolt032
					WHERE n32_compania   = vg_codcia
					  AND n32_cod_liqrol =
							rm_n32.n32_cod_liqrol
					  AND n32_fecha_ini  = fecha_ini
					  AND n32_fecha_fin  = fecha_fin
					  AND n32_estado     <> 'E'
					  AND n32_cod_trab
						IN (SELECT UNIQUE cod_trab
							FROM temp_ing_rub)
				ELSE
					SELECT SUM(n32_sueldo), SUM(n32_tot_gan)
					INTO tot_sueldo, tot_ganado
					FROM rolt032
					WHERE n32_compania    = vg_codcia
					  AND n32_cod_liqrol IN ('Q1', 'Q2')
					  AND n32_fecha_ini  >= fecha_ini
					  AND n32_fecha_fin  <= fecha_fin
					  AND n32_estado     <> 'E'
					  AND n32_cod_trab
						IN (SELECT UNIQUE cod_trab
							FROM temp_ing_rub)
				END IF
			END IF
			LET suel_t  = tot_sueldo USING "--,---,--&.##"
			LET tot_gan = tot_ganado USING "--,---,--&.##"
			print ASCII escape;
			print ASCII act_neg;
			print ASCII escape;
			print ASCII act_12cpi
			PRINT COLUMN 001, rm_cia.g01_razonsocial
			PRINT COLUMN 037, "RECIBO DE PAGO - TOTALES"
			SKIP 1 LINES
			IF rm_n32.n32_cod_liqrol = 'XX' THEN
				CALL retorna_num_liq() RETURNING num_liq
			END IF
			PRINT COLUMN 001, "TOTALES     : No. de Liquidaciones ",
				num_liq USING "<<<#&";
			IF rm_n32.n32_cod_liqrol <> 'XX' THEN
				PRINT COLUMN 055, "LIQUIDACION: ",
					rm_n32.n32_cod_liqrol, " ",
					r_n03.n03_nombre_abr
			ELSE
				PRINT COLUMN 055,
					"LIQUIDACION: TODAS LAS LIQUID."
			END IF
			PRINT COLUMN 001, "TOTAL SUELDO: ",
					r_g13.g13_simbolo CLIPPED,
				" ", fl_justifica_titulo('I', suel_t, 15),
			      COLUMN 055, "PERIODO    : ",
					fecha_ini USING "dd-mm-yyyy",
				' - ', fecha_fin USING "dd-mm-yyyy"
			PRINT COLUMN 001, "TOTAL GANADO: ",
					r_g13.g13_simbolo CLIPPED,
				" ", fl_justifica_titulo('I', tot_gan, 15)
			SKIP 2 LINES
			PRINT COLUMN 001, "INGRESOS    : ",
			      COLUMN 052, "DESCUENTOS    : ",
			      COLUMN 078, DATE(TODAY) USING 'dd-mm-yyyy',
					1 SPACES, TIME
			PRINT "------------------------------------------------------------------------------------------------";
			print ASCII escape;
			print ASCII des_neg
		END IF
	END IF

ON EVERY ROW
	IF vm_impr_total = 'S' THEN
		RETURN
	END IF
	DECLARE q_ing1 CURSOR FOR
		SELECT * FROM temp_ing_rub
			WHERE cod_trab = cod_traba
			ORDER BY orden
	DECLARE q_des1 CURSOR FOR
		SELECT * FROM temp_des_rub
			WHERE cod_trab = cod_traba
			  AND det_tot = 'DE'
			ORDER BY orden
	OPEN q_ing1
	OPEN q_des1
	SELECT COUNT(*) INTO n1 FROM temp_ing_rub
		WHERE cod_trab = cod_traba
	SELECT COUNT(*) INTO n2 FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'DE'
	LET lim = n1
	IF n2 > n1 THEN
		LET lim = n2
	END IF
	FOR i = 1 TO lim
		INITIALIZE r_ing.*, r_des.* TO NULL
		FETCH q_ing1 INTO r_ing.*
		FETCH q_des1 INTO r_des.*
		LET val_i = NULL
		IF r_ing.valor_aux > 0 THEN
			LET val_i = r_ing.valor_aux	USING "###.##"
		END IF
		LET val_d = NULL
		IF r_des.valor_aux > 0 THEN
			LET val_d = r_des.valor_aux	USING "###.##"
		END IF
		PRINT COLUMN 001, r_ing.cod_rub		USING "&&&",
		      COLUMN 005, r_ing.nombre,
		      COLUMN 023, val_i,
		      COLUMN 033, r_ing.valor		USING "--,---,--&.##",
		      COLUMN 052, r_des.cod_rub		USING "&&&",
		      COLUMN 056, r_des.nombre,
		      COLUMN 074, val_d,
		      COLUMN 084, r_des.valor		USING "--,---,--&.##"
	END FOR
	CLOSE q_ing1
	CLOSE q_des1
	FREE q_ing1
	FREE q_des1
	SKIP 1 LINES
	PRINT COLUMN 033, "-------------",
	      COLUMN 084, "-------------"
	SELECT * INTO r_des.* FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'TI'
	PRINT COLUMN 001, r_des.nombre,
      	      COLUMN 033, r_des.valor		USING "--,---,--&.##";
	SELECT * INTO r_des.* FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'TE'
	PRINT COLUMN 052, r_des.nombre,
              COLUMN 084, r_des.valor		USING "--,---,--&.##"
	SKIP 1 LINES
	SELECT * INTO r_des.* FROM temp_des_rub
		WHERE cod_trab = cod_traba
		  AND det_tot = 'TN'
	PRINT COLUMN 001, ASCII escape, ASCII act_neg;
	PRINT COLUMN 001, r_des.nombre,
	      COLUMN 033, 2 SPACES, r_des.valor	USING "--,---,--&.##",
	                  ASCII escape, ASCII des_neg, 2 SPACES;
	DECLARE q_desxqui CURSOR FOR SELECT * FROM temp_ing_rub
		WHERE cod_trab = cod_traba
	INITIALIZE r_ing.* TO NULL
	LET encont = 0
	FOREACH q_desxqui INTO r_ing.*
		CALL fl_lee_rubro_roles(r_ing.cod_rub) RETURNING r_n06.*
		IF r_n06.n06_flag_ident = 'SI' THEN
			LET encont = 1
			EXIT FOREACH
		END IF
	END FOREACH
	PRINT 4 SPACES, "DESCONTAR PROX. QUINCENA";
	IF encont THEN
		LET tot_descontar = tot_descontar + r_ing.valor
		PRINT 8 SPACES, r_ing.valor	USING "--,---,--&.##"
	ELSE
		PRINT 8 SPACES, "0.00"		USING "--,---,--&.##"
	END IF
	PRINT COLUMN 033, ASCII escape, ASCII act_neg;
	PRINT COLUMN 033, "=============",
			  ASCII escape, ASCII des_neg
	SKIP 2 LINES
	PRINT COLUMN 001, "RECIBI CONFORME: _________________________";
	IF vg_codloc = 3 THEN
		INITIALIZE r_cen.* TO NULL
		IF rm_n32.n32_cod_liqrol <> 'XX' THEN
			SELECT * INTO r_cen.*
				FROM tr_cesantia
				WHERE compania   = rm_n32.n32_compania
				  AND cod_liqrol = rm_n32.n32_cod_liqrol
				  AND anio_cen   = rm_n32.n32_ano_proceso
				  AND mes_cen    = rm_n32.n32_mes_proceso
				  AND cod_trab   = rm_n32.n32_cod_trab
		ELSE
			DECLARE q_cesan CURSOR FOR
				SELECT * FROM tr_cesantia
				WHERE compania   = rm_n32.n32_compania
				  AND anio_cen   = rm_n32.n32_ano_proceso
				  AND mes_cen    = rm_n32.n32_mes_proceso
				  AND cod_trab   = rm_n32.n32_cod_trab
			OPEN q_cesan
			FETCH q_cesan INTO r_cen.*
			CLOSE q_cesan
			FREE q_cesan
		END IF
		IF r_cen.compania IS NOT NULL THEN
			PRINT " "
			SKIP 1 LINES
			{--
			PRINT COLUMN 001, "FONDO CESANTIA AL ",
				r_cen.fecha_repar USING 'dd-mm-yyyy',' VALOR: ',
				r_cen.valor_repar USING "-,---,--&.##", '   ',
				'PROXIMA REPARTICION DE INTERESES ',
				r_cen.fecha_prox USING 'dd-mm-yyyy';
			--}
			LET val_rep = r_cen.valor_repar USING "-,---,--&.##"
			PRINT COLUMN 001, "FONDO CESANTIA AL ",
				r_cen.fecha_repar USING 'dd-mm-yyyy',': USD ',
				val_rep USING "<<<<<<<<&.##", '. ',
				'PROXIMA RENOVACION DE POLIZA: ',
				r_cen.fecha_prox USING 'dd-mm-yyyy';
		END IF
	END IF
	--print ASCII escape;
	--print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi
	LET num_liq = num_liq + 1
	IF num_liq = tot_liq THEN
		LET fin_arch = 1
	END IF
	LET lineas  = vm_lineas_impr - LINENO
	SKIP lineas LINES

ON LAST ROW
	IF vm_imprimir_emp = 'S' THEN
		RETURN
	END IF
	print ASCII escape;
	print ASCII act_12cpi
	DECLARE q_ing1_t CURSOR FOR
		SELECT UNIQUE cod_rub, orden FROM temp_ing_rub ORDER BY orden
	DECLARE q_des1_t CURSOR FOR
		SELECT UNIQUE cod_rub, orden FROM temp_des_rub
			WHERE det_tot = 'DE'
			ORDER BY orden
	OPEN q_ing1_t
	OPEN q_des1_t
	SELECT COUNT(DISTINCT cod_rub) INTO n1 FROM temp_ing_rub
	SELECT COUNT(DISTINCT cod_rub) INTO n2 FROM temp_des_rub
		WHERE det_tot = 'DE'
	LET lim = n1
	IF n2 > n1 THEN
		LET lim = n2
	END IF
	FOR i = 1 TO lim
		INITIALIZE r_ing.*, r_des.*, cod_r_i, cod_r_d TO NULL
		FETCH q_ing1_t INTO cod_r_i, ord_i
		FETCH q_des1_t INTO cod_r_d, ord_d
		LET val_i     = NULL
		LET tot_val_i = NULL
		IF cod_r_i IS NOT NULL THEN
			DECLARE q_ing1_t2 CURSOR FOR
				SELECT * FROM temp_ing_rub
					WHERE cod_rub = cod_r_i
					ORDER BY orden
			LET tot_val_i_a = 0
			LET tot_val_i   = 0
			FOREACH q_ing1_t2 INTO r_ing.*
				LET tot_val_i_a = tot_val_i_a + r_ing.valor_aux
				LET tot_val_i   = tot_val_i   + r_ing.valor
			END FOREACH
			IF tot_val_i_a > 0 THEN
				LET val_i = tot_val_i_a		USING "#,###.##"
			END IF
		END IF
		LET val_d     = NULL
		LET tot_val_d = NULL
		IF cod_r_d IS NOT NULL THEN
			DECLARE q_des1_t2 CURSOR FOR
				SELECT * FROM temp_des_rub
					WHERE cod_rub = cod_r_d
					  AND det_tot = 'DE'
					ORDER BY orden
			LET tot_val_d_a = 0
			LET tot_val_d   = 0
			FOREACH q_des1_t2 INTO r_des.*
				LET tot_val_d_a = tot_val_d_a + r_des.valor_aux
				LET tot_val_d   = tot_val_d   + r_des.valor
			END FOREACH
			IF tot_val_d_a > 0 THEN
				LET val_d = tot_val_d_a		USING "###.##"
			END IF
		END IF
		PRINT COLUMN 001, r_ing.cod_rub		USING "&&&",
		      COLUMN 005, r_ing.nombre,
		      COLUMN 023, val_i,
		      COLUMN 033, tot_val_i		USING "--,---,--&.##",
		      COLUMN 052, r_des.cod_rub		USING "&&&",
		      COLUMN 056, r_des.nombre,
		      --COLUMN 074, val_d,
		      COLUMN 084, tot_val_d		USING "--,---,--&.##"
	END FOR
	CLOSE q_ing1_t
	CLOSE q_des1_t
	FREE q_ing1_t
	FREE q_des1_t
	--SKIP 1 LINES
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 033, "-------------",
	      COLUMN 084, "-------------"
	SELECT nombre, SUM(valor) INTO r_des.nombre, r_des.valor
		FROM temp_des_rub
		WHERE det_tot = 'TI'
		GROUP BY nombre
	PRINT COLUMN 001, r_des.nombre,
      	      COLUMN 033, r_des.valor		USING "--,---,--&.##";
	SELECT nombre, SUM(valor) INTO r_des.nombre, r_des.valor
		FROM temp_des_rub
		WHERE det_tot = 'TE'
		GROUP BY nombre
	PRINT COLUMN 052, r_des.nombre,
              COLUMN 084, r_des.valor		USING "--,---,--&.##"
	SKIP 1 LINES
	SELECT nombre, SUM(valor) INTO r_des.nombre, r_des.valor
		FROM temp_des_rub
		WHERE det_tot = 'TN'
		GROUP BY nombre
	PRINT COLUMN 001, r_des.nombre,
	      COLUMN 033, r_des.valor	USING "--,---,--&.##",
	                  --ASCII escape, ASCII des_neg, 2 SPACES;
	      COLUMN 052, "DESCONTAR PROX. QUINCENA",
	      COLUMN 084, tot_descontar	USING "--,---,--&.##"
	--PRINT COLUMN 033, ASCII escape, ASCII act_neg;
	PRINT COLUMN 033, "============="
	CALL sacar_totales('T') RETURNING r_des.valor
	IF r_des.valor > 0 THEN
		PRINT COLUMN 001, "TOTAL DE DEPOSITO A CUENTA",
		      COLUMN 033, r_des.valor	USING "--,---,--&.##"
	END IF
	CALL sacar_totales('E') RETURNING r_des.valor
	IF r_des.valor > 0 THEN
		PRINT COLUMN 001, "TOTAL EN EFECTIVO",
		      COLUMN 033, r_des.valor	USING "--,---,--&.##"
	END IF
	CALL sacar_totales('C') RETURNING r_des.valor
	IF r_des.valor > 0 THEN
		PRINT COLUMN 001, "TOTAL EN CHEQUE",
		      COLUMN 033, r_des.valor	USING "--,---,--&.##"
	END IF
	print ASCII escape;
	print ASCII des_neg;
	--print ASCII escape;
	--print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION sacar_totales(tipo)
DEFINE tipo		CHAR(1)
DEFINE tot_valor	DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_lq		VARCHAR(100)

LET expr_depto = NULL
IF vm_cod_depto IS NOT NULL AND vm_imprimir = 'N' THEN
	LET expr_depto = '   AND n32_cod_depto   = ', vm_cod_depto
END IF
LET expr_trab = NULL
IF vm_cod_trab IS NOT NULL AND vm_imprimir = 'N' THEN
	LET expr_trab = '   AND n32_cod_trab   = ', vm_cod_trab
END IF
LET expr_lq = '   AND n32_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"'
IF rm_n32.n32_cod_liqrol = 'XX' THEN
	LET expr_lq = '   AND n32_cod_liqrol IN ("Q1", "Q2") '
END IF
LET query = 'SELECT NVL(SUM(n32_tot_neto), 0) FROM rolt032 ',
		' WHERE n32_compania    = ', vg_codcia,
			expr_lq CLIPPED,
		'   AND n32_fecha_ini  >= "', fecha_ini, '"',
		'   AND n32_fecha_fin  <= "', fecha_fin, '"',
		expr_trab CLIPPED,
		expr_depto CLIPPED,
		'   AND n32_estado     <> "E"',
		'   AND n32_tipo_pago   = "', tipo, '"'
PREPARE tot1 FROM query
DECLARE q_tot CURSOR FOR tot1
OPEN q_tot
FETCH q_tot INTO tot_valor
CLOSE q_tot
FREE q_tot
RETURN tot_valor

END FUNCTION



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rolt032.n32_estado

CASE estado
	WHEN 'A'
		RETURN "EN PROCESO"
	WHEN 'C'
		RETURN "CERRADO"
	WHEN 'E'
		RETURN "ELIMINADO"
END CASE

END FUNCTION



FUNCTION retorna_forma_pago(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE forma_pago	VARCHAR(31)

CALL fl_lee_trabajador_roles(vg_codcia, cod_trab) RETURNING r_n30.*
CASE r_n30.n30_tipo_pago
	WHEN 'E'
		LET forma_pago = 'EFECTIVO'
	WHEN 'C'
		LET forma_pago = 'CHEQUE'
	WHEN 'T'
		LET forma_pago = 'DEPOSITO A CTA. ',
				r_n30.n30_cta_trabaj CLIPPED
END CASE
RETURN forma_pago

END FUNCTION



FUNCTION retorna_num_liq()

SELECT n32_cod_trab, n32_cod_liqrol, COUNT(*) num_lq
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN ('Q1', 'Q2')
	  AND n32_fecha_ini  >= fecha_ini
	  AND n32_fecha_fin  <= fecha_fin
	  AND n32_estado     <> 'E'
	  AND n32_cod_trab   IN (SELECT UNIQUE cod_trab FROM temp_ing_rub)
	GROUP BY 1, 2
	INTO TEMP t1
SELECT SUM(num_lq)
	INTO num_liq
	FROM t1
DROP TABLE t1
RETURN num_liq

END FUNCTION
