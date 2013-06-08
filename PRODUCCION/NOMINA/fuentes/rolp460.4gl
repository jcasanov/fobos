--------------------------------------------------------------------------------
-- Titulo           : rolp460.4gl - Listado de Totales de Empleados
-- Elaboracion      : 02-Feb-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp460 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE vm_trab_t	LIKE rolt032.n32_cod_trab
DEFINE vm_depto_t	LIKE rolt032.n32_cod_depto
DEFINE tit_mes		VARCHAR(10)
DEFINE vm_agrupado	CHAR(1)
DEFINE vm_incluir_de	CHAR(1)
DEFINE vm_incluir_va	CHAR(1)
DEFINE vm_incluir_ut	CHAR(1)
DEFINE liq, liq_sub	SMALLINT
DEFINE vm_cabecera	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp460.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN		-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp460'
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
DEFINE resul	 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 17
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf460_1 FROM '../forms/rolf460_1'
ELSE
	OPEN FORM f_rolf460_1 FROM '../forms/rolf460_1c'
END IF
DISPLAY FORM f_rolf460_1
INITIALIZE rm_n32.*, vm_trab_t, vm_depto_t, vm_incluir_de, vm_incluir_va TO NULL
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.', 'stop')
	EXIT PROGRAM
END IF
LET vm_incluir_de = 'N'
LET vm_agrupado   = 'S'
LET vm_incluir_va = 'N'
LET vm_incluir_ut = 'N'
CALL cargar_datos_liq() RETURNING resul
IF resul THEN
	RETURN
END IF
WHILE TRUE
	CLEAR FORM
	INITIALIZE rm_n32.n32_cod_depto, rm_n32.n32_cod_trab TO NULL
	CALL mostrar_datos_liq(1)
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE rm_n32.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 1
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 1
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 1
END IF
LET rm_n32.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_n32.n32_mes_proceso = r_n01.n01_mes_proceso
CALL retorna_mes()
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
		WHERE n32_compania   = r_n05.n05_compania
		  AND n32_estado     <> 'E'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n32.n32_cod_liqrol  = r_n32.n32_cod_liqrol
LET rm_n32.n32_fecha_ini   = r_n32.n32_fecha_ini
LET rm_n32.n32_fecha_fin   = r_n32.n32_fecha_fin
LET rm_n32.n32_estado      = r_n32.n32_estado
LET rm_n32.n32_dias_trab   = r_n32.n32_dias_trab
LET rm_n32.n32_dias_falt   = r_n32.n32_dias_falt
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
CALL retorna_mes()
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq(flag)
DEFINE flag		SMALLINT
DEFINE r_g34		RECORD LIKE gent034.*

CALL retorna_mes()
DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_ano_proceso,
		rm_n32.n32_mes_proceso, tit_mes
CASE flag
	WHEN 0
		DISPLAY BY NAME rm_n32.n32_cod_depto, rm_n32.n32_sueldo,
				rm_n32.n32_dias_falt, rm_n32.n32_tot_gan
		CALL fl_lee_departamento(vg_codcia, rm_n32.n32_cod_depto)
			RETURNING r_g34.*
		DISPLAY BY NAME r_g34.g34_nombre
		CALL muestra_estado()
	WHEN 1
		DISPLAY BY NAME vm_agrupado
END CASE

END FUNCTION



FUNCTION muestra_estado()

DISPLAY BY NAME rm_n32.n32_estado
IF rm_n32.n32_estado = 'A' THEN
	DISPLAY 'EN PROCESO' TO tit_estado
END IF
IF rm_n32.n32_estado = 'C' THEN
	DISPLAY 'CERRADA'     TO tit_estado
END IF
IF rm_n32.n32_estado = 'E' THEN
	DISPLAY 'ELIMINADA'  TO tit_estado
END IF

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso

LET int_flag = 0
INPUT BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_ano_proceso,
	rm_n32.n32_mes_proceso, rm_n32.n32_cod_depto, rm_n32.n32_cod_trab,
	vm_incluir_de, vm_incluir_ut, vm_incluir_va, vm_agrupado
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
	AFTER FIELD n32_cod_liqrol
		IF rm_n32.n32_cod_liqrol <> 'TO' THEN
   			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n32_cod_liqrol
			END IF
		END IF
		CALL mostrar_fechas()
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
		CALL mostrar_fechas()
	AFTER FIELD n32_mes_proceso
		IF rm_n32.n32_cod_liqrol <> 'TO' THEN
			IF rm_n32.n32_cod_liqrol <> 'Q1' AND
			   rm_n32.n32_cod_liqrol <> 'Q2'
			THEN
				LET rm_n32.n32_mes_proceso = NULL
				DISPLAY BY NAME rm_n32.n32_mes_proceso
			END IF
		END IF
		IF rm_n32.n32_mes_proceso IS NOT NULL THEN
			CALL retorna_mes()
			DISPLAY BY NAME tit_mes
		ELSE
			CLEAR tit_mes
		END IF
		CALL mostrar_fechas()
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
		CALL mostrar_fechas()
		IF rm_n32.n32_cod_liqrol = 'TO' AND
		   rm_n32.n32_cod_trab IS NOT NULL
		THEN
			LET vm_incluir_de = 'N'
			LET vm_incluir_va = 'N'
		END IF
		IF rm_n32.n32_ano_proceso < rm_n90.n90_anio_ini_vac + 1 THEN
			LET vm_incluir_va = 'N'
		END IF
		IF rm_n32.n32_cod_trab IS NOT NULL OR
		   rm_n32.n32_cod_depto IS NOT NULL
		THEN
			LET vm_agrupado = 'N'
		END IF
		IF rm_n32.n32_mes_proceso <> 4 THEN
			LET vm_incluir_ut = 'N'
		END IF
		DISPLAY BY NAME vm_incluir_de, vm_incluir_ut, vm_incluir_va,
				vm_agrupado
END INPUT
LET vm_depto_t = rm_n32.n32_cod_depto
LET vm_trab_t  = rm_n32.n32_cod_trab

END FUNCTION



FUNCTION retorna_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_n32.n32_mes_proceso), 10)
	RETURNING tit_mes

END FUNCTION 



FUNCTION mostrar_fechas()

IF rm_n32.n32_cod_liqrol <> 'TO' THEN
	CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso)
		RETURNING rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin
ELSE
	LET rm_n32.n32_fecha_ini = MDY(rm_n32.n32_mes_proceso, 01,
					rm_n32.n32_ano_proceso)
	LET rm_n32.n32_fecha_fin = rm_n32.n32_fecha_ini + 1 UNITS MONTH
					- 1 UNITS DAY
END IF
IF rm_n32.n32_mes_proceso IS NULL AND
  (rm_n32.n32_cod_liqrol = 'Q1' OR rm_n32.n32_cod_liqrol = 'Q2' OR
   rm_n32.n32_cod_liqrol = 'TO')
THEN
	LET rm_n32.n32_fecha_ini = MDY(01, 01, rm_n32.n32_ano_proceso)
	LET rm_n32.n32_fecha_fin = rm_n32.n32_fecha_ini + 1 UNITS YEAR
					- 1 UNITS DAY
END IF
DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin

END FUNCTION 



FUNCTION control_reporte()
DEFINE r_rep		RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_domicilio	LIKE rolt030.n30_domicilio,
				n30_telef_domic	LIKE rolt030.n30_telef_domic,
				g31_nombre	LIKE gent031.g31_nombre,
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_rep2		RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_domicilio	LIKE rolt030.n30_domicilio,
				n32_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n32_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_rep3		RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_domicilio	LIKE rolt030.n30_domicilio,
				n39_valor_vaca	LIKE rolt039.n39_valor_vaca,
				n39_descto_iess	LIKE rolt039.n39_descto_iess,
				netovaca	DECIMAL(12,2),
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE query		CHAR(10000)
DEFINE expr_col		CHAR(3000)
DEFINE expr_col2	CHAR(2000)
DEFINE expr_col3	CHAR(3000)
DEFINE expr_cod		VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_dpto	VARCHAR(100)
DEFINE expr_ciu		VARCHAR(100)
DEFINE expr_grp		VARCHAR(50)
DEFINE expr_ord		VARCHAR(50)
DEFINE tabla		VARCHAR(10)
DEFINE comando		VARCHAR(100)
DEFINE f_dt_i, f_dt_f	DATE
DEFINE f_dc_i, f_dc_f	DATE
DEFINE resp		CHAR(6)

LET expr_col2 = 'NVL(SUM(n32_tot_ing), 0) tot_ing, NVL(SUM(n32_tot_egr), 0)',
		' tot_egr, NVL(SUM(n32_tot_neto), 0) tot_neto, n32_cod_depto,',
		' g34_nombre '
LET expr_grp  = ' GROUP BY 1, 2, 3, 4, 5, 13, 14 '
IF vm_incluir_de = 'S' THEN
	CALL fl_lee_proceso_roles('DC') RETURNING r_n03.*
	LET f_dc_i    = MDY(r_n03.n03_mes_ini, r_n03.n03_dia_ini,
				rm_n32.n32_ano_proceso - 1)
	LET f_dc_f    = MDY(r_n03.n03_mes_fin, r_n03.n03_dia_fin,
				rm_n32.n32_ano_proceso)
	CALL fl_lee_proceso_roles('DT') RETURNING r_n03.*
	LET f_dt_i    = MDY(r_n03.n03_mes_ini, r_n03.n03_dia_ini,
				rm_n32.n32_ano_proceso - 1)
	LET f_dt_f    = MDY(r_n03.n03_mes_fin, r_n03.n03_dia_fin,
				rm_n32.n32_ano_proceso)
	LET expr_col2 = 'NVL((SELECT SUM(n36_valor_bruto) FROM rolt036 ',
				' WHERE n36_compania  = n32_compania ',
				'   AND n36_proceso   = "DT" ',
				'   AND n36_fecha_ini = "', f_dt_i, '"',
				'   AND n36_fecha_fin = "', f_dt_f, '"',
				'   AND n36_cod_trab  = n32_cod_trab),0) v_dt,',
			'NVL((SELECT SUM(n36_valor_bruto) FROM rolt036 ',
				' WHERE n36_compania  = n32_compania ',
				'   AND n36_proceso   = "DC" ',
				'   AND n36_fecha_ini = "', f_dc_i, '"',
				'   AND n36_fecha_fin = "', f_dc_f, '"',
				'   AND n36_cod_trab  = n32_cod_trab),0) v_dc,',
			'NVL((SELECT SUM(n36_valor_bruto) FROM rolt036 ',
				' WHERE n36_compania  = n32_compania ',
				'   AND n36_proceso   = "DT" ',
				'   AND n36_fecha_ini = "', f_dt_i, '"',
				'   AND n36_fecha_fin = "', f_dt_f, '"',
				'   AND n36_cod_trab  = n32_cod_trab), 0) + ',
			'NVL((SELECT SUM(n36_valor_bruto) FROM rolt036 ',
				' WHERE n36_compania  = n32_compania ',
				'   AND n36_proceso   = "DC" ',
				'   AND n36_fecha_ini = "', f_dc_i, '"',
				'   AND n36_fecha_fin = "', f_dc_f, '"',
				'   AND n36_cod_trab  = n32_cod_trab),0) v_ne,',
			' n32_cod_depto, g34_nombre '
	LET expr_grp  = ' GROUP BY 1, 2, 3, 4, 5, 11, 10, 12, 13, 14 '
END IF
LET expr_col3 =	' n30_telef_domic, g31_nombre,',
		' NVL(SUM(n32_sueldo) / 2, 0) sueldo, '
IF vm_incluir_va = 'S' THEN
	LET expr_col3 = ' NVL((SELECT SUM(n39_valor_vaca + n39_valor_adic) ',
			' FROM rolt039 ',
			' WHERE n39_compania    = n32_compania ',
			'   AND n39_proceso     IN ("VP", "VA") ',
			'   AND n39_cod_trab    = n32_cod_trab ',
			'   AND n39_periodo_ini = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso - 1, ')',
			'   AND n39_periodo_fin = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso, ') - ',
						'1 UNITS DAY), 0) val_v, ',
			' NVL((SELECT SUM(n39_descto_iess) FROM rolt039 ',
			' WHERE n39_compania    = n32_compania ',
			'   AND n39_proceso     IN ("VP", "VA") ',
			'   AND n39_cod_trab    = n32_cod_trab ',
			'   AND n39_periodo_ini = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso - 1, ')',
			'   AND n39_periodo_fin = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso, ') - ',
						'1 UNITS DAY), 0) val_vd, ',
			' NVL((SELECT SUM(n39_valor_vaca + n39_valor_adic) ',
			' FROM rolt039 ',
			' WHERE n39_compania    = n32_compania ',
			'   AND n39_proceso     IN ("VP", "VA") ',
			'   AND n39_cod_trab    = n32_cod_trab ',
			'   AND n39_periodo_ini = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso - 1, ')',
			'   AND n39_periodo_fin = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso, ') - ',
						'1 UNITS DAY), 0) - ',
			' NVL((SELECT SUM(n39_descto_iess) FROM rolt039 ',
			' WHERE n39_compania    = n32_compania ',
			'   AND n39_proceso     IN ("VP", "VA") ',
			'   AND n39_cod_trab    = n32_cod_trab ',
			'   AND n39_periodo_ini = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso - 1, ')',
			'   AND n39_periodo_fin = MDY(MONTH(n30_fecha_ing), ',
			'DAY(n30_fecha_ing), ', rm_n32.n32_ano_proceso, ') - ',
						'1 UNITS DAY), 0) val_vn, '
	LET expr_grp  = ' GROUP BY 1, 2, 3, 4, 5, 6, 13, 14 '
	IF vm_incluir_de = 'S' THEN
		LET expr_grp  = ' GROUP BY 1, 2, 3, 4, 5, 6, 10, 11, 12, 13, 14'
	END IF
END IF
LET expr_cod = '   AND n32_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"'
IF rm_n32.n32_cod_liqrol = 'TO' THEN
	LET expr_cod = '   AND n32_cod_liqrol IN ("Q1", "Q2") '
END IF
LET tabla     = ', gent031'
LET expr_trab = NULL
LET expr_col  =	expr_col3 CLIPPED,
		'NVL(SUM(n32_tot_gan),0) tot_gan,',
		' NVL(SUM(n32_tot_gan * (n13_porc_trab / 100)), 0) aporte, ',
		'NVL(SUM(n32_tot_gan - (n32_tot_gan * (n13_porc_trab ',
		'/ 100))), 0) subtotal, ',
		expr_col2 CLIPPED
LET expr_ciu  = '   AND g31_ciudad      = n30_ciudad_nac '
LET expr_ord  = ' ORDER BY n30_nombres '
IF vm_agrupado = 'S' THEN
	LET expr_ord  = ' ORDER BY g34_nombre, n30_nombres '
END IF
IF vm_trab_t IS NOT NULL THEN
	LET tabla     = NULL
	LET expr_trab = '   AND n32_cod_trab    = ', vm_trab_t
	LET expr_col  = ' n32_fecha_ini, n32_fecha_fin, ',
			'n32_sueldo / 2 sueldo, n32_tot_gan tot_gan, ',
			'n32_tot_gan * (n13_porc_trab / 100) aporte, ',
			'n32_tot_gan - (n32_tot_gan * (n13_porc_trab / 100)) ',
			'subtotal, n32_tot_ing, n32_tot_egr, n32_tot_neto, ',
			'n32_cod_depto, g34_nombre '
	LET expr_ciu  = NULL
	LET expr_grp  = NULL
	LET expr_ord  = ' ORDER BY n30_nombres, 5 '
	IF vm_agrupado = 'S' THEN
		LET expr_ord  = ' ORDER BY g34_nombre, n30_nombres, 5 '
	END IF
END IF
LET expr_dpto = NULL
IF vm_depto_t IS NOT NULL THEN
	LET expr_dpto = '   AND n32_cod_depto   = ', vm_depto_t
END IF
LET query = 'SELECT n30_cod_trab, n30_nombres, n30_domicilio,',
			expr_col CLIPPED,
		' FROM rolt032, rolt030, rolt013', tabla CLIPPED, ', gent034 ',
		' WHERE n32_compania    = ', vg_codcia,
		expr_cod CLIPPED,
		'   AND n32_fecha_ini  >= "', rm_n32.n32_fecha_ini, '"',
		'   AND n32_fecha_fin  <= "', rm_n32.n32_fecha_fin, '"',
		expr_trab CLIPPED,
		expr_dpto CLIPPED,
		'   AND n30_compania    = n32_compania ',
		'   AND n30_cod_trab    = n32_cod_trab ',
		'   AND n13_cod_seguro  = n30_cod_seguro ',
		expr_ciu CLIPPED,
		'   AND g34_compania    = n32_compania ',
		'   AND g34_cod_depto   = n32_cod_depto ',
		expr_grp CLIPPED,
		' INTO TEMP tmp_emp '
PREPARE exec_rep FROM query
EXECUTE exec_rep
LET query = 'SELECT * FROM tmp_emp ', expr_ord CLIPPED
IF vm_incluir_de = 'S' AND vm_incluir_va = 'N' THEN
	LET query = 'SELECT n30_cod_trab, n30_nombres, n30_domicilio,',
				' n30_telef_domic, g31_nombre, sueldo,tot_gan,',
				' aporte,subtotal, v_dt, v_dc,subtotal + v_ne,',
				' n32_cod_depto, g34_nombre ',
			' FROM tmp_emp ',
			expr_ord CLIPPED
END IF
IF vm_incluir_de = 'S' AND vm_incluir_va = 'S' THEN
	LET query = 'SELECT n30_cod_trab, n30_nombres, n30_domicilio,',
				' val_v, val_vd, val_vn, tot_gan, aporte,',
				' subtotal,v_dt,v_dc,val_vn + subtotal + v_ne,',
				' n32_cod_depto, g34_nombre ',
			' FROM tmp_emp ',
			expr_ord CLIPPED
END IF
PREPARE cons_tmp FROM query
DECLARE q_exec_rep CURSOR FOR cons_tmp
CALL fl_hacer_pregunta('Desea generar también el archivo .XML ?', 'No')
	RETURNING resp
IF resp = 'Yes' THEN
	CALL generar_archivo_xml()
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	DROP TABLE tmp_emp
	RETURN
END IF
LET liq = 0
IF vm_trab_t IS NULL THEN
	IF vm_incluir_va = 'N' THEN
		START REPORT reporte_empleados TO PIPE comando
		FOREACH q_exec_rep INTO r_rep.*, cod_depto
			OUTPUT TO REPORT reporte_empleados(r_rep.*, cod_depto)
			LET liq = liq + 1
		END FOREACH
		FINISH REPORT reporte_empleados
	ELSE
		START REPORT reporte_empleados3 TO PIPE comando
		FOREACH q_exec_rep INTO r_rep3.*, cod_depto
			OUTPUT TO REPORT reporte_empleados3(r_rep3.*, cod_depto)
			LET liq = liq + 1
		END FOREACH
		FINISH REPORT reporte_empleados3
	END IF
ELSE
	START REPORT reporte_empleados2 TO PIPE comando
	FOREACH q_exec_rep INTO r_rep2.*, cod_depto
		OUTPUT TO REPORT reporte_empleados2(r_rep2.*, cod_depto)
		LET liq = liq + 1
	END FOREACH
	FINISH REPORT reporte_empleados2
END IF
IF liq = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF
DROP TABLE tmp_emp

END FUNCTION 



REPORT reporte_empleados(r_rep, cod_depto)
DEFINE r_rep		RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_domicilio	LIKE rolt030.n30_domicilio,
				n30_telef_domic	LIKE rolt030.n30_telef_domic,
				g31_nombre	LIKE gent031.g31_nombre,
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE r_tot		RECORD
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE nom_depto	VARCHAR(36)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(30)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario	= "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', "LISTADO TOTALES GANADO DE LOS EMPLEADOS",
					80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial CLIPPED,
	      COLUMN 154, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 041, titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 061, "** PERIODO     : ", rm_n32.n32_fecha_ini
			USING "dd-mm-yyyy", " - ", rm_n32.n32_fecha_fin
			USING "dd-mm-yyyy"
	IF vm_depto_t IS NOT NULL THEN
		CALL fl_lee_departamento(vg_codcia, vm_depto_t)
			RETURNING r_g34.*
		PRINT COLUMN 061, "** DEPARTAMENTO: ", vm_depto_t
			USING "<<&&", " ", r_g34.g34_nombre CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
			1 SPACES, TIME,
	      COLUMN 142, usuario CLIPPED
	PRINT COLUMN 001,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "COD.",
	      COLUMN 009, "E M P L E A D O S",
	      COLUMN 033, "DIRECCION DOMIC.",
	      COLUMN 053, "TELEFONO",
	      COLUMN 062, "  CIUDAD",
	      COLUMN 073, "SUELDO QUIN.",
	      COLUMN 086, "TOT.GAN. MES",
	      COLUMN 099, "APORT IESS",
	      COLUMN 110, "    SUBTOTAL";
	IF vm_incluir_de = 'N' THEN
		PRINT COLUMN 123, "TOTAL INGRES",
		      COLUMN 136, "TOTAL EGRESO";
	ELSE
		PRINT COLUMN 123, "DECIMO TERC.",
		      COLUMN 136, "DECIMO CUAR.";
	END IF
	PRINT COLUMN 149, "  TOTAL NETO"
	PRINT COLUMN 001,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	IF vm_agrupado = 'S' THEN
		LET vm_cabecera = 1
	END IF

BEFORE GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		IF NOT vm_cabecera OR PAGENO > 1 THEN
			SKIP 1 LINES
		END IF
		NEED 7 LINES
		CALL fl_lee_departamento(vg_codcia, cod_depto) RETURNING r_g34.*
		LET nom_depto  = '** ', r_g34.g34_nombre CLIPPED, ' **'
		PRINT COLUMN 001, nom_depto
		LET vm_cabecera          = 0
		LET liq_sub              = 0
		LET r_tot.n30_sueldo_mes = 0
		LET r_tot.n32_tot_gan    = 0
		LET r_tot.valor_aporte   = 0
		LET r_tot.subtotal       = 0
		LET r_tot.n32_tot_ing    = 0
		LET r_tot.n32_tot_egr    = 0
		LET r_tot.n32_tot_neto   = 0
	END IF

ON EVERY ROW
	IF vm_agrupado = 'S' THEN
		NEED 6 LINES
	ELSE
		NEED 3 LINES
	END IF
	PRINT COLUMN 001, r_rep.n30_cod_trab		USING "<<&&",
	      COLUMN 006, r_rep.n30_nombres[1, 24]	CLIPPED,
	      COLUMN 031, r_rep.n30_domicilio[1, 21]	CLIPPED,
	      COLUMN 053, r_rep.n30_telef_domic[1, 8]	CLIPPED,
	      COLUMN 062, r_rep.g31_nombre[1, 10]	CLIPPED,
	      COLUMN 073, r_rep.n30_sueldo_mes		USING "#,###,##&.##",
	      COLUMN 086, r_rep.n32_tot_gan		USING "#,###,##&.##",
	      COLUMN 099, r_rep.valor_aporte		USING "###,##&.##",
	      COLUMN 110, r_rep.subtotal		USING "#,###,##&.##",
	      COLUMN 123, r_rep.n32_tot_ing		USING "#,###,##&.##",
	      COLUMN 136, r_rep.n32_tot_egr		USING "#,###,##&.##",
	      COLUMN 149, r_rep.n32_tot_neto		USING "#,###,##&.##"
	IF vm_agrupado = 'S' THEN
		LET liq_sub              = liq_sub + 1
		LET r_tot.n30_sueldo_mes = r_tot.n30_sueldo_mes +
						r_rep.n30_sueldo_mes
		LET r_tot.n32_tot_gan    = r_tot.n32_tot_gan + r_rep.n32_tot_gan
		LET r_tot.valor_aporte   = r_tot.valor_aporte +
						r_rep.valor_aporte
		LET r_tot.subtotal       = r_tot.subtotal + r_rep.subtotal
		LET r_tot.n32_tot_ing    = r_tot.n32_tot_ing + r_rep.n32_tot_ing
		LET r_tot.n32_tot_egr    = r_tot.n32_tot_egr + r_rep.n32_tot_egr
		LET r_tot.n32_tot_neto   = r_tot.n32_tot_neto +
						r_rep.n32_tot_neto
	END IF

AFTER GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		NEED 5 LINES
		PRINT COLUMN 073, "------------",
		      COLUMN 086, "------------",
		      COLUMN 099, "----------",
		      COLUMN 110, "------------",
		      COLUMN 123, "------------",
		      COLUMN 136, "------------",
		      COLUMN 149, "------------"
		PRINT COLUMN 003, "SUBTOT. REG. ", liq USING "<<<&&",
		      COLUMN 057, "SUBTOTALES ==>  ",
		      COLUMN 073, r_tot.n30_sueldo_mes	USING "#,###,##&.##",
		      COLUMN 086, r_tot.n32_tot_gan	USING "#,###,##&.##",
		      COLUMN 099, r_tot.valor_aporte	USING "###,##&.##",
		      COLUMN 110, r_tot.subtotal	USING "#,###,##&.##",
		      COLUMN 123, r_tot.n32_tot_ing	USING "#,###,##&.##",
		      COLUMN 136, r_tot.n32_tot_egr	USING "#,###,##&.##",
		      COLUMN 149, r_tot.n32_tot_neto	USING "#,###,##&.##"
	END IF

ON LAST ROW
	IF vm_agrupado = 'S' THEN
		NEED 3 LINES
		SKIP 1 LINES
	ELSE
		NEED 2 LINES
	END IF
	PRINT COLUMN 073, "------------",
	      COLUMN 086, "------------",
	      COLUMN 099, "----------",
	      COLUMN 110, "------------",
	      COLUMN 123, "------------",
	      COLUMN 136, "------------",
	      COLUMN 149, "------------"
	PRINT COLUMN 003, "TOT. REGISTROS ", liq USING "<<<&&",
	      COLUMN 060, "TOTALES ==>  ",
	      COLUMN 073, SUM(r_rep.n30_sueldo_mes)	USING "#,###,##&.##",
	      COLUMN 086, SUM(r_rep.n32_tot_gan)	USING "#,###,##&.##",
	      COLUMN 099, SUM(r_rep.valor_aporte)	USING "###,##&.##",
	      COLUMN 110, SUM(r_rep.subtotal)		USING "#,###,##&.##",
	      COLUMN 123, SUM(r_rep.n32_tot_ing)	USING "#,###,##&.##",
	      COLUMN 136, SUM(r_rep.n32_tot_egr)	USING "#,###,##&.##",
	      COLUMN 149, SUM(r_rep.n32_tot_neto)	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



REPORT reporte_empleados2(r_rep, cod_depto)
DEFINE r_rep		RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_domicilio	LIKE rolt030.n30_domicilio,
				n32_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n32_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE r_tot		RECORD
				n30_sueldo_mes	LIKE rolt030.n30_sueldo_mes,
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE nom_depto	VARCHAR(36)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(30)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario	= "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', "LISTADO TOTALES GANADO DE LOS EMPLEADOS",
					80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial CLIPPED,
	      COLUMN 154, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 041, titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 061, "** PERIODO     : ", rm_n32.n32_fecha_ini
			USING "dd-mm-yyyy", " - ", rm_n32.n32_fecha_fin
			USING "dd-mm-yyyy"
	IF vm_depto_t IS NOT NULL THEN
		CALL fl_lee_departamento(vg_codcia, vm_depto_t)
			RETURNING r_g34.*
		PRINT COLUMN 061, "** DEPARTAMENTO: ", vm_depto_t
			USING "<<&&", " ", r_g34.g34_nombre CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
			1 SPACES, TIME,
	      COLUMN 142, usuario CLIPPED
	PRINT COLUMN 001,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "COD.",
	      COLUMN 009, "E M P L E A D O S",
	      COLUMN 030, "DIRECCION DOMIC.",
	      COLUMN 051, "FECHA INI.",
	      COLUMN 062, "FECHA FIN.",
	      COLUMN 073, "SUELDO QUIN.",
	      COLUMN 086, "TOT.GAN. MES",
	      COLUMN 099, "APORT IESS",
	      COLUMN 110, "    SUBTOTAL",
	      COLUMN 123, "TOTAL INGRES",
	      COLUMN 136, "TOTAL EGRESO",
	      COLUMN 149, "  TOTAL NETO"
	PRINT COLUMN 001,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	IF vm_agrupado = 'S' THEN
		LET vm_cabecera = 1
	END IF

BEFORE GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		IF NOT vm_cabecera OR PAGENO > 1 THEN
			SKIP 1 LINES
		END IF
		NEED 7 LINES
		CALL fl_lee_departamento(vg_codcia, cod_depto) RETURNING r_g34.*
		LET nom_depto  = '** ', r_g34.g34_nombre CLIPPED, ' **'
		PRINT COLUMN 001, nom_depto
		LET vm_cabecera          = 0
		LET liq_sub              = 0
		LET r_tot.n30_sueldo_mes = 0
		LET r_tot.n32_tot_gan    = 0
		LET r_tot.valor_aporte   = 0
		LET r_tot.subtotal       = 0
		LET r_tot.n32_tot_ing    = 0
		LET r_tot.n32_tot_egr    = 0
		LET r_tot.n32_tot_neto   = 0
	END IF

ON EVERY ROW
	IF vm_agrupado = 'S' THEN
		NEED 6 LINES
	ELSE
		NEED 3 LINES
	END IF
	PRINT COLUMN 001, r_rep.n30_cod_trab		USING "<<&&",
	      COLUMN 006, r_rep.n30_nombres[1, 24]	CLIPPED,
	      COLUMN 029, r_rep.n30_domicilio[1, 19]	CLIPPED,
	      COLUMN 051, r_rep.n32_fecha_ini		USING "dd-mm-yyyy",
	      COLUMN 062, r_rep.n32_fecha_fin		USING "dd-mm-yyyy",
	      COLUMN 073, r_rep.n30_sueldo_mes		USING "#,###,##&.##",
	      COLUMN 086, r_rep.n32_tot_gan		USING "#,###,##&.##",
	      COLUMN 099, r_rep.valor_aporte		USING "###,##&.##",
	      COLUMN 110, r_rep.subtotal		USING "#,###,##&.##",
	      COLUMN 123, r_rep.n32_tot_ing		USING "#,###,##&.##",
	      COLUMN 136, r_rep.n32_tot_egr		USING "#,###,##&.##",
	      COLUMN 149, r_rep.n32_tot_neto		USING "#,###,##&.##"
	IF vm_agrupado = 'S' THEN
		LET liq_sub              = liq_sub + 1
		LET r_tot.n30_sueldo_mes = r_tot.n30_sueldo_mes +
						r_rep.n30_sueldo_mes
		LET r_tot.n32_tot_gan    = r_tot.n32_tot_gan + r_rep.n32_tot_gan
		LET r_tot.valor_aporte   = r_tot.valor_aporte +
						r_rep.valor_aporte
		LET r_tot.subtotal       = r_tot.subtotal + r_rep.subtotal
		LET r_tot.n32_tot_ing    = r_tot.n32_tot_ing + r_rep.n32_tot_ing
		LET r_tot.n32_tot_egr    = r_tot.n32_tot_egr + r_rep.n32_tot_egr
		LET r_tot.n32_tot_neto   = r_tot.n32_tot_neto +
						r_rep.n32_tot_neto
	END IF

AFTER GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		NEED 5 LINES
		PRINT COLUMN 073, "------------",
		      COLUMN 086, "------------",
		      COLUMN 099, "----------",
		      COLUMN 110, "------------",
		      COLUMN 123, "------------",
		      COLUMN 136, "------------",
		      COLUMN 149, "------------"
		PRINT COLUMN 003, "SUBTOT. REG. ", liq USING "<<<&&",
		      COLUMN 057, "SUBTOTALES ==>  ",
		      COLUMN 073, r_tot.n30_sueldo_mes	USING "#,###,##&.##",
		      COLUMN 086, r_tot.n32_tot_gan	USING "#,###,##&.##",
		      COLUMN 099, r_tot.valor_aporte	USING "###,##&.##",
		      COLUMN 110, r_tot.subtotal	USING "#,###,##&.##",
		      COLUMN 123, r_tot.n32_tot_ing	USING "#,###,##&.##",
		      COLUMN 136, r_tot.n32_tot_egr	USING "#,###,##&.##",
		      COLUMN 149, r_tot.n32_tot_neto	USING "#,###,##&.##"
	END IF

ON LAST ROW
	IF vm_agrupado = 'S' THEN
		NEED 3 LINES
		SKIP 1 LINES
	ELSE
		NEED 2 LINES
	END IF
	PRINT COLUMN 073, "------------",
	      COLUMN 086, "------------",
	      COLUMN 099, "----------",
	      COLUMN 110, "------------",
	      COLUMN 123, "------------",
	      COLUMN 136, "------------",
	      COLUMN 149, "------------"
	PRINT COLUMN 003, "TOT. REGISTROS ", liq USING "<<<&&",
	      COLUMN 060, "TOTALES ==>  ",
	      COLUMN 073, SUM(r_rep.n30_sueldo_mes)	USING "#,###,##&.##",
	      COLUMN 086, SUM(r_rep.n32_tot_gan)	USING "#,###,##&.##",
	      COLUMN 099, SUM(r_rep.valor_aporte)	USING "###,##&.##",
	      COLUMN 110, SUM(r_rep.subtotal)		USING "#,###,##&.##",
	      COLUMN 123, SUM(r_rep.n32_tot_ing)	USING "#,###,##&.##",
	      COLUMN 136, SUM(r_rep.n32_tot_egr)	USING "#,###,##&.##",
	      COLUMN 149, SUM(r_rep.n32_tot_neto)	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



REPORT reporte_empleados3(r_rep, cod_depto)
DEFINE r_rep		RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n30_domicilio	LIKE rolt030.n30_domicilio,
				n39_valor_vaca	LIKE rolt039.n39_valor_vaca,
				n39_descto_iess	LIKE rolt039.n39_descto_iess,
				netovaca	DECIMAL(12,2),
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE cod_depto	LIKE gent034.g34_cod_depto
DEFINE r_tot		RECORD
				n39_valor_vaca	LIKE rolt039.n39_valor_vaca,
				n39_descto_iess	LIKE rolt039.n39_descto_iess,
				netovaca	DECIMAL(12,2),
				n32_tot_gan	LIKE rolt032.n32_tot_gan,
				valor_aporte	DECIMAL(12,2),
				subtotal	DECIMAL(12,2),
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE nom_depto	VARCHAR(36)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(30)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario	= "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', "LISTADO TOTALES GANADO DE LOS EMPLEADOS",
					80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial CLIPPED,
	      COLUMN 154, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 041, titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 061, "** PERIODO     : ", rm_n32.n32_fecha_ini
			USING "dd-mm-yyyy", " - ", rm_n32.n32_fecha_fin
			USING "dd-mm-yyyy"
	IF vm_depto_t IS NOT NULL THEN
		CALL fl_lee_departamento(vg_codcia, vm_depto_t)
			RETURNING r_g34.*
		PRINT COLUMN 061, "** DEPARTAMENTO: ", vm_depto_t
			USING "<<&&", " ", r_g34.g34_nombre CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
			1 SPACES, TIME,
	      COLUMN 142, usuario CLIPPED
	PRINT COLUMN 001,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "COD.",
	      COLUMN 008, "E M P L E A D O S",
	      COLUMN 030, "DIRECCION DOMIC.",
	      COLUMN 049, "VALOR VACAC.",
	      COLUMN 062, "DSCTO. VACA.",
	      COLUMN 073, "SUBTOTAL VA.",
	      COLUMN 086, "TOT.GAN. MES",
	      COLUMN 099, "APORT IESS",
	      COLUMN 110, "    SUBTOTAL";
	IF vm_incluir_de = 'N' THEN
		PRINT COLUMN 123, "TOTAL INGRES",
		      COLUMN 136, "TOTAL EGRESO";
	ELSE
		PRINT COLUMN 123, "DECIMO TERC.",
		      COLUMN 136, "DECIMO CUAR.";
	END IF
	PRINT COLUMN 149, "  TOTAL NETO"
	PRINT COLUMN 001,  "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	IF vm_agrupado = 'S' THEN
		LET vm_cabecera = 1
	END IF

BEFORE GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		IF NOT vm_cabecera OR PAGENO > 1 THEN
			SKIP 1 LINES
		END IF
		NEED 7 LINES
		CALL fl_lee_departamento(vg_codcia, cod_depto) RETURNING r_g34.*
		LET nom_depto  = '** ', r_g34.g34_nombre CLIPPED, ' **'
		PRINT COLUMN 001, nom_depto
		LET vm_cabecera          = 0
		LET liq_sub              = 0
		LET r_tot.n39_valor_vaca = 0
		LET r_tot.n39_descto_iess= 0
		LET r_tot.netovaca       = 0
		LET r_tot.n32_tot_gan    = 0
		LET r_tot.valor_aporte   = 0
		LET r_tot.subtotal       = 0
		LET r_tot.n32_tot_ing    = 0
		LET r_tot.n32_tot_egr    = 0
		LET r_tot.n32_tot_neto   = 0
	END IF

ON EVERY ROW
	IF vm_agrupado = 'S' THEN
		NEED 6 LINES
	ELSE
		NEED 3 LINES
	END IF
	PRINT COLUMN 001, r_rep.n30_cod_trab		USING "<<&&",
	      COLUMN 006, r_rep.n30_nombres[1, 22]	CLIPPED,
	      COLUMN 029, r_rep.n30_domicilio[1, 19]	CLIPPED,
	      COLUMN 049, r_rep.n39_valor_vaca		USING "#,###,##&.##",
	      COLUMN 062, r_rep.n39_descto_iess		USING "###,##&.##",
	      COLUMN 073, r_rep.netovaca		USING "#,###,##&.##",
	      COLUMN 086, r_rep.n32_tot_gan		USING "#,###,##&.##",
	      COLUMN 099, r_rep.valor_aporte		USING "###,##&.##",
	      COLUMN 110, r_rep.subtotal		USING "#,###,##&.##",
	      COLUMN 123, r_rep.n32_tot_ing		USING "#,###,##&.##",
	      COLUMN 136, r_rep.n32_tot_egr		USING "#,###,##&.##",
	      COLUMN 149, r_rep.n32_tot_neto		USING "#,###,##&.##"
	IF vm_agrupado = 'S' THEN
		LET liq_sub              = liq_sub + 1
		LET r_tot.n39_valor_vaca = r_tot.n39_valor_vaca +
						r_rep.n39_valor_vaca
		LET r_tot.n39_descto_iess= r_tot.n39_descto_iess +
						r_rep.n39_descto_iess
		LET r_tot.netovaca       = r_tot.netovaca + r_rep.netovaca
		LET r_tot.n32_tot_gan    = r_tot.n32_tot_gan + r_rep.n32_tot_gan
		LET r_tot.valor_aporte   = r_tot.valor_aporte +
						r_rep.valor_aporte
		LET r_tot.subtotal       = r_tot.subtotal + r_rep.subtotal
		LET r_tot.n32_tot_ing    = r_tot.n32_tot_ing + r_rep.n32_tot_ing
		LET r_tot.n32_tot_egr    = r_tot.n32_tot_egr + r_rep.n32_tot_egr
		LET r_tot.n32_tot_neto   = r_tot.n32_tot_neto +
						r_rep.n32_tot_neto
	END IF

AFTER GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		NEED 5 LINES
		PRINT COLUMN 049, "------------",
		      COLUMN 062, "----------",
		      COLUMN 073, "------------",
		      COLUMN 086, "------------",
		      COLUMN 099, "----------",
		      COLUMN 110, "------------",
		      COLUMN 123, "------------",
		      COLUMN 136, "------------",
		      COLUMN 149, "------------"
		PRINT COLUMN 003, "SUBTOT. REG. ", liq USING "<<<&&",
		      COLUMN 033, "SUBTOTALES ==>  ",
		      COLUMN 049, r_tot.n39_valor_vaca	USING "#,###,##&.##",
		      COLUMN 062, r_tot.n39_descto_iess	USING "###,##&.##",
		      COLUMN 073, r_tot.netovaca	USING "#,###,##&.##",
		      COLUMN 086, r_tot.n32_tot_gan	USING "#,###,##&.##",
		      COLUMN 099, r_tot.valor_aporte	USING "###,##&.##",
		      COLUMN 110, r_tot.subtotal	USING "#,###,##&.##",
		      COLUMN 123, r_tot.n32_tot_ing	USING "#,###,##&.##",
		      COLUMN 136, r_tot.n32_tot_egr	USING "#,###,##&.##",
		      COLUMN 149, r_tot.n32_tot_neto	USING "#,###,##&.##"
	END IF

ON LAST ROW
	IF vm_agrupado = 'S' THEN
		NEED 3 LINES
		SKIP 1 LINES
	ELSE
		NEED 2 LINES
	END IF
	PRINT COLUMN 049, "------------",
	      COLUMN 062, "----------",
	      COLUMN 073, "------------",
	      COLUMN 086, "------------",
	      COLUMN 099, "----------",
	      COLUMN 110, "------------",
	      COLUMN 123, "------------",
	      COLUMN 136, "------------",
	      COLUMN 149, "------------"
	PRINT COLUMN 003, "TOT. REGISTROS ", liq USING "<<<&&",
	      COLUMN 036, "TOTALES ==>  ",
	      COLUMN 049, SUM(r_rep.n39_valor_vaca)	USING "#,###,##&.##",
	      COLUMN 062, SUM(r_rep.n39_descto_iess)	USING "###,##&.##",
	      COLUMN 073, SUM(r_rep.netovaca)		USING "#,###,##&.##",
	      COLUMN 086, SUM(r_rep.n32_tot_gan)	USING "#,###,##&.##",
	      COLUMN 099, SUM(r_rep.valor_aporte)	USING "###,##&.##",
	      COLUMN 110, SUM(r_rep.subtotal)		USING "#,###,##&.##",
	      COLUMN 123, SUM(r_rep.n32_tot_ing)	USING "#,###,##&.##",
	      COLUMN 136, SUM(r_rep.n32_tot_egr)	USING "#,###,##&.##",
	      COLUMN 149, SUM(r_rep.n32_tot_neto)	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION generar_archivo_xml()
DEFINE r_det		RECORD
				numruc		LIKE gent002.g02_numruc,
				cedula		LIKE rolt030.n30_num_doc_id,
				empleado	LIKE rolt030.n30_nombres,
				tipo		SMALLINT,
				direccion	LIKE rolt030.n30_domicilio,
				dirnumer	VARCHAR(4),
				ciudad		LIKE gent002.g02_ciudad,
				dirciud		INTEGER,
				dirprov		VARCHAR(2),
				telefono	LIKE rolt030.n30_telef_domic,
				numero		SMALLINT,
				tot_gan		LIKE rolt032.n32_tot_gan,
				val_iess	DECIMAL(12,2),
				baseimp		DECIMAL(14,2),
				valor_ret	DECIMAL(12,2),
				anio		SMALLINT,
				num_ret		SMALLINT
			END RECORD
DEFINE query		CHAR(2000)
DEFINE unavez		SMALLINT

--RUN '> empleados.xml'
LET query = 'SELECT g02_numruc, b.n30_num_doc_id, a.n30_nombres, 2,',
		' a.n30_domicilio, "", g02_ciudad,',
		' CASE WHEN g02_ciudad = 1  THEN 1090150',
		'      WHEN g02_ciudad = 45 THEN 1090150',
		'      ELSE 0',
		' END,',
		' CASE WHEN g02_ciudad = 1  THEN "09"',
		'      WHEN g02_ciudad = 45 THEN "02"',
		'      ELSE "00"',
		' END,',
		' a.n30_telef_domic, 1, tot_gan, aporte, subtotal, 0.00,',
		rm_n32.n32_ano_proceso, ', 0 ',
		' FROM tmp_emp a, rolt030 b, gent002 ',
		' WHERE b.n30_compania = ', vg_codcia,
		'   AND b.n30_cod_trab = a.n30_cod_trab ',
		'   AND g02_compania   = b.n30_compania ',
		'   AND g02_localidad  = ', vg_codloc,
		' ORDER BY 2 '
PREPARE cons_xml FROM query
DECLARE q_cons_xml CURSOR FOR cons_xml
DISPLAY '<?xml version="1.0" encoding="UTF-8"?>'
DISPLAY '<!--Created by Liquid XML Data Binding Libraries '
DISPLAY '(www.liquid-technologies.com) for Servicio de Rentas Internas-->'
DISPLAY '<renta xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
LET unavez = 1
FOREACH q_cons_xml INTO r_det.*
	IF unavez THEN
		DISPLAY '<numRuc>', r_det.numruc CLIPPED, '</numRuc>'
		DISPLAY '<año>', r_det.anio USING "&&&&", '</año>'
		DISPLAY '<retRelDep>'
		LET unavez = 0
	END IF
	DISPLAY '<datRetRelDep>'
	DISPLAY '<ideRDEP>', r_det.cedula CLIPPED, '</ideRDEP>'
	DISPLAY '<desIdeRDEP>', r_det.empleado CLIPPED, '</desIdeRDEP>'
	DISPLAY '<tipDocRDEP>', r_det.tipo USING "<<&", '</tipDocRDEP>'
	DISPLAY '<dirCal>', r_det.direccion CLIPPED, '</dirCal>'
	DISPLAY '<dirNum>', r_det.dirnumer CLIPPED, '</dirNum>'
	DISPLAY '<dirCiu>', r_det.dirciud USING "<<<<<<<<<&", '</dirCiu>'
	DISPLAY '<dirProv>', r_det.dirprov CLIPPED, '</dirProv>'
	DISPLAY '<tel>', r_det.telefono CLIPPED, '</tel>'
	DISPLAY '<sisSalNet>', r_det.numero USING "<<&", '</sisSalNet>'
	DISPLAY '<valIngLiq>',r_det.tot_gan USING "#,###,##&.##", '</valIngLiq>'
	DISPLAY '<apoPerIess>',r_det.val_iess USING "###,##&.##",'</apoPerIess>'
	DISPLAY '<basImp>', r_det.baseimp USING "#,###,##&.##", '</basImp>'
	DISPLAY '<valRet>', r_det.valor_ret USING "#,###,##&.##", '</valRet>'
	DISPLAY '<añoRet>', r_det.anio USING "&&&&", '</añoRet>'
	DISPLAY '<numRet>', r_det.num_ret USING "<<&", '</numRet>'
	DISPLAY '</datRetRelDep>'
END FOREACH
DISPLAY '</retRelDep>'
DISPLAY 'retOtrCon/>'
DISPLAY '</renta>'
LET query = "OUTPUT TO 'xyz.xml' WITHOUT HEADINGS ",
		" SELECT ",
"'<empleado>',",
"'<tipoDocumento>' || '2' || '</tipoDocumento>',",
"'<descripcionDocumento>' || 'CEDULA' || '</descripcionDocumento>',",
"'<identificacion>' || trim(n30_num_doc_id) || '</identificacion>',",
"'<descripcion>' || '.' || '</descripcion>',",
"'<telefono>' || nvl(trim(n30_telef_domic), '') || '</telefono>',",
"'<calle>' || nvl(trim(n30_domicilio), '') || '</calle>',",
"'<numero>' || '09' || '</numero>',",
"'<codigoProvincia>' || '9' || '</codigoProvincia>',",
"'<descripcionProvincia>' || 'GUAYAS' || '</descripcionProvincia>',",
"'<codigoCiudad>' || '1090150' || '</codigoCiudad>',",
"'<descripcionCiudad>' || 'GUAYAQUIL' || '</descripcionCiudad>',",
"'</empleado>'",
" FROM rolt030",
" WHERE n30_estado = 'A'"
PREPARE exec_arch FROM query
EXECUTE exec_arch
CALL fl_mostrar_mensaje('Archivo XML de empleados generado OK.', 'info')

END FUNCTION
