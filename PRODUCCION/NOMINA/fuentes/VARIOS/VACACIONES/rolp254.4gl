--------------------------------------------------------------------------------
-- Titulo              : rolp254.4gl -- Mantenimiento de Días Gozados
-- Elaboración         : 18-Ago-2007
-- Autor               : NPC
-- Formato de Ejecución: fglrun rolp254 Base Modulo Compañía
-- Ultima Correción    : 
-- Motivo Corrección   : 
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n39   	RECORD LIKE rolt039.*
DEFINE rm_n47   	RECORD LIKE rolt047.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_det		ARRAY [500] OF RECORD
				n47_cod_trab	LIKE rolt047.n47_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n47_dias_goza	LIKE rolt047.n47_dias_goza,
				anio_vac	SMALLINT,
				n47_dias_real	LIKE rolt047.n47_dias_real,
				n47_periodo_ini	LIKE rolt047.n47_periodo_ini,
				n47_periodo_fin	LIKE rolt047.n47_periodo_fin,
				n47_valor_pag	LIKE rolt047.n47_valor_pag,
				n47_valor_des	LIKE rolt047.n47_valor_des
			END RECORD
DEFINE rm_adi		ARRAY [500] OF RECORD
				c_trab		LIKE rolt030.n30_cod_trab,
				anio_p		SMALLINT
			END RECORD
DEFINE vm_proceso	LIKE rolt039.n39_proceso
DEFINE vm_vac_pag	LIKE rolt039.n39_proceso
DEFINE vm_estado	LIKE rolt032.n32_estado
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE tit_mes		VARCHAR(10)
DEFINE tot_valor_pag	DECIMAL(12,2)
DEFINE tot_valor_des	DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_cabecera	SMALLINT
DEFINE vm_consulta	CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp254.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp254'
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
DEFINE r_n03		RECORD LIKE rolt003.*

CALL fl_nivel_isolation()
LET vm_proceso = 'VA'
CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
LET vm_vac_pag = 'VP'
CALL fl_lee_proceso_roles(vm_vac_pag) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES PAGADAS en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
LET vm_num_rows = 0
LET vm_max_rows = 500
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf254_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		BORDER, MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf254_1 FROM '../forms/rolf254_1'
ELSE
	OPEN FORM f_rolf254_1 FROM '../forms/rolf254_1c'
END IF
DISPLAY FORM f_rolf254_1
INITIALIZE rm_n47.*, rm_n39.* TO NULL
LET vm_consulta = 'N'
DISPLAY "Cod."		TO tit_col1
DISPLAY "Empleados"	TO tit_col2
DISPLAY "DG"		TO tit_col3
DISPLAY "A.V."		TO tit_col4
DISPLAY "DR"		TO tit_col5
DISPLAY "Per. V. I."	TO tit_col6
DISPLAY "Per. V. F."	TO tit_col7
DISPLAY "Valor Gan."	TO tit_col8
DISPLAY "Valor Des."	TO tit_col9
CALL muestra_contadores(0, vm_num_rows)
CALL cargar_datos_liq() RETURNING resul
IF resul THEN
	RETURN
END IF
CALL mostrar_datos_liq()
LET vm_cabecera = 0
WHILE TRUE
	CALL borrar_detalle()
	IF vm_estado = 'C' OR vm_cabecera THEN
		CALL control_ingreso()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	CALL control_proceso()
	IF int_flag THEN
		IF NOT vm_cabecera THEN
			DROP TABLE tmp_dia_goz
			EXIT WHILE
		END IF
	END IF
	DROP TABLE tmp_dia_goz
END WHILE

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE rm_n47.* TO NULL
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
        CALL fl_mostrar_mensaje('Compañía no esta activa.', 'stop')
	RETURN 1
END IF
LET rm_n39.n39_ano_proceso = r_n01.n01_ano_proceso
LET rm_n39.n39_mes_proceso = r_n01.n01_mes_proceso
CALL retorna_mes()
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania   = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fec_cierre DESC
OPEN q_n05
FETCH q_n05 INTO r_n05.*
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   = r_n05.n05_compania
		  --AND n32_cod_liqrol = r_n05.n05_proceso
		  AND n32_estado     <> 'E'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n47.n47_cod_liqrol  = r_n32.n32_cod_liqrol
LET rm_n47.n47_fecha_ini   = r_n32.n32_fecha_ini
LET rm_n47.n47_fecha_fin   = r_n32.n32_fecha_fin
LET vm_estado              = r_n32.n32_estado
LET rm_n39.n39_ano_proceso = r_n32.n32_ano_proceso
LET rm_n39.n39_mes_proceso = r_n32.n32_mes_proceso
CALL retorna_mes()
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_g34		RECORD LIKE gent034.*

CALL retorna_mes()
DISPLAY BY NAME rm_n47.n47_cod_liqrol, rm_n47.n47_fecha_ini,
		rm_n47.n47_fecha_fin, rm_n39.n39_ano_proceso,
		rm_n39.n39_mes_proceso, tit_mes, vm_consulta
CALL fl_lee_proceso_roles(rm_n47.n47_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_rows
	INITIALIZE rm_det[i].*, rm_adi[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_det')
	CLEAR rm_det[i].*
END FOR
CLEAR num_row, max_row, tot_valor_pag, tot_valor_des, nom_trab

END FUNCTION



FUNCTION control_ingreso()

LET rm_n47.n47_compania = vg_codcia
LET rm_n47.n47_proceso  = vm_proceso
LET rm_n47.n47_usuario  = vg_usuario
LET rm_n47.n47_fecing   = CURRENT
CALL lee_datos()

END FUNCTION



FUNCTION lee_datos()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE anio		LIKE rolt039.n39_ano_proceso
DEFINE mes		LIKE rolt039.n39_mes_proceso
DEFINE mes_aux		LIKE rolt039.n39_mes_proceso
DEFINE resp      	CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_n47.n47_cod_liqrol, rm_n39.n39_ano_proceso,
	rm_n39.n39_mes_proceso, vm_consulta
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n47.n47_cod_liqrol, rm_n39.n39_ano_proceso,
				 rm_n39.n39_mes_proceso, vm_consulta)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF       	
	ON KEY(F2)
		IF INFIELD(n47_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n47.n47_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n47.n47_cod_liqrol,
						r_n03.n03_nombre
			END IF
		END IF
		IF INFIELD(n39_mes_proceso) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET rm_n39.n39_mes_proceso = mes_aux
				DISPLAY BY NAME rm_n39.n39_mes_proceso, tit_mes
			END IF
                END IF
	BEFORE FIELD n39_ano_proceso
		LET anio = rm_n39.n39_ano_proceso
	BEFORE FIELD n39_mes_proceso
		LET mes = rm_n39.n39_mes_proceso
	AFTER FIELD n47_cod_liqrol
		IF rm_n47.n47_cod_liqrol IS NOT NULL THEN
			CALL fl_lee_proceso_roles(rm_n47.n47_cod_liqrol)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('El Proceso no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD n47_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			IF r_n03.n03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                        	NEXT FIELD n47_cod_liqrol
			END IF
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n39_ano_proceso
		IF rm_n39.n39_ano_proceso IS NOT NULL THEN
			IF rm_n39.n39_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n39_ano_proceso
			END IF
		ELSE
			LET rm_n39.n39_ano_proceso = anio
			DISPLAY BY NAME rm_n39.n39_ano_proceso
		END IF
		CALL mostrar_fechas()
	AFTER FIELD n39_mes_proceso
		IF rm_n39.n39_mes_proceso IS NULL THEN
			LET rm_n39.n39_mes_proceso = mes
			DISPLAY BY NAME rm_n39.n39_mes_proceso
		END IF
		CALL retorna_mes()
		DISPLAY BY NAME tit_mes
		CALL mostrar_fechas()
	AFTER INPUT
		INITIALIZE r_n32.* TO NULL
		DECLARE q_liqact CURSOR FOR
			SELECT * FROM rolt032
				WHERE n32_compania   = vg_codcia
				  AND n32_cod_liqrol = rm_n47.n47_cod_liqrol
				  AND n32_fecha_ini  = rm_n47.n47_fecha_ini
				  AND n32_fecha_fin  = rm_n47.n47_fecha_fin
				ORDER BY n32_fecha_fin DESC
		OPEN q_liqact
		FETCH q_liqact INTO r_n32.*
		IF r_n32.n32_compania IS NULL THEN
			CALL fl_mostrar_mensaje('Liquidación no se ha generado todavía.', 'exclamation')
			--CONTINUE INPUT
		END IF
		LET vm_estado = r_n32.n32_estado
END INPUT

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_proceso()
DEFINE c_trab		LIKE rolt030.n30_cod_trab
DEFINE query		CHAR(1500)
DEFINE cuantos		INTEGER
DEFINE flag, i		SMALLINT

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 2
LET vm_columna_2 = 4
LET rm_orden[2]  = 'ASC'
CALL preparar_query()
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	IF vm_estado = 'A' THEN
		LET int_flag = 1
	END IF
END IF
IF (vm_estado IS NOT NULL AND vm_estado = 'C') OR vm_consulta = 'S' THEN
	WHILE TRUE
		CALL cargar_detalle()
		CALL mostrar_detalle()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END WHILE
	RETURN
END IF
CALL lee_detalle()
IF int_flag THEN
	RETURN
END IF
SELECT COUNT(*) INTO cuantos
	FROM rolt047
	WHERE n47_compania   = vg_codcia
	  AND n47_cod_liqrol = rm_n47.n47_cod_liqrol
	  AND n47_fecha_ini  = rm_n47.n47_fecha_ini
	  AND n47_fecha_fin  = rm_n47.n47_fecha_fin
	  AND n47_estado     = "A"
IF tot_valor_pag = 0 AND cuantos = 0 THEN
	CALL fl_mostrar_mensaje('No se proceso ninguna vacacion con dias gozados, para cruzar con el rol.', 'info')
	RETURN
END IF
BEGIN WORK
	DELETE FROM rolt047
		WHERE n47_compania   = vg_codcia
		  AND n47_cod_liqrol = rm_n47.n47_cod_liqrol
		  AND n47_fecha_ini  = rm_n47.n47_fecha_ini
		  AND n47_fecha_fin  = rm_n47.n47_fecha_fin
		  AND n47_cod_trab   = (SELECT UNIQUE c_tra
						FROM tmp_dia_goz
						WHERE c_tra = n47_cod_trab
						  AND a_pro =
							YEAR(n47_periodo_fin))
		  AND n47_estado     = "A"
	LET query = 'INSERT INTO rolt047 ',
			'(n47_compania, n47_proceso, n47_cod_trab, ',
			'n47_periodo_ini, n47_periodo_fin, n47_secuencia, ',
			'n47_fecini_vac, n47_fecfin_vac, n47_estado, ',
			'n47_max_dias, n47_dias_real, n47_dias_goza, ',
			'n47_cod_liqrol, n47_fecha_ini, n47_fecha_fin, ',
			'n47_valor_pag, n47_valor_des, n47_usuario,n47_fecing)',
			' SELECT ', vg_codcia, ', "', vm_proceso, '", c_tra, ',
				'per_ini, per_fin, ',
				'NVL((SELECT MAX(a.n47_secuencia) + 1 ',
				'FROM rolt047 a ',
				'WHERE a.n47_compania    = ', vg_codcia,
				'  AND a.n47_proceso     = "', vm_proceso, '"',
				'  AND a.n47_cod_trab    = c_tra ',
				'  AND a.n47_periodo_ini = per_ini ',
				'  AND a.n47_periodo_fin = per_fin), 1), ',
				'fec_ini, fec_fin, "A", d_g, d_r, d_g, "',
				rm_n47.n47_cod_liqrol, '", ',
				'"', rm_n47.n47_fecha_ini, '", ',
				'"', rm_n47.n47_fecha_fin, '", val_p, val_d, ',
				'"', vg_usuario CLIPPED, '", CURRENT ',
			' FROM tmp_dia_goz ',
			' WHERE val_p IS NOT NULL ',
			'   AND val_d IS NOT NULL '
	PREPARE ins_reg FROM query
	EXECUTE ins_reg
COMMIT WORK
LET c_trab = NULL
FOR i = 1 TO vm_num_rows
	IF rm_det[i].n47_valor_pag IS NULL OR rm_det[i].n47_valor_des IS NULL
	THEN
		SELECT COUNT(*) INTO cuantos
			FROM tmp_dia_goz
			WHERE c_tra = rm_det[i].n47_cod_trab
			  AND a_pro = rm_adi[i].anio_p
		IF cuantos = 0 THEN
			CONTINUE FOR
		END IF
	END IF
	LET flag = 0
	IF c_trab IS NULL OR c_trab <> rm_det[i].n47_cod_trab THEN
		LET c_trab = rm_det[i].n47_cod_trab
		LET flag   = 1
	END IF
	IF vm_estado = 'A' THEN
		CALL regenerar_novedades(rm_det[i].n47_cod_trab, flag)
		CALL regenerar_novedades(rm_det[i].n47_cod_trab, 0)
	END IF
END FOR
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION preparar_query()
DEFINE query		CHAR(1500)

LET query = 'SELECT n30_cod_trab c_tra, n30_nombres nom_trab, ',
			'n47_dias_goza d_g, YEAR(n47_periodo_fin) a_vac, ',
			'n47_dias_real d_r, n47_periodo_ini per_ini, ',
			'n47_periodo_fin per_fin, n47_valor_pag val_p, ',
			'n47_valor_des val_d, n47_fecini_vac fec_ini, ',
			'n47_fecfin_vac fec_fin, YEAR(n47_periodo_fin) a_pro ',
		' FROM rolt030, OUTER rolt047 ',
		' WHERE n30_compania   = ', vg_codcia,
		'   AND n30_estado     = "A" ',
		'   AND n30_tipo_trab  = "N" ',
		'   AND n47_compania   = n30_compania ',
		'   AND n47_cod_liqrol = "', rm_n47.n47_cod_liqrol, '"',
		'   AND n47_fecha_ini  = "', rm_n47.n47_fecha_ini, '"',
		'   AND n47_fecha_fin  = "', rm_n47.n47_fecha_fin, '"',
		'   AND n47_cod_trab   = n30_cod_trab ',
		' INTO TEMP tmp_dia_goz '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
CALL cargar_detalle()

END FUNCTION



FUNCTION cargar_detalle()
DEFINE i		SMALLINT
DEFINE query		VARCHAR(200)

FOR i = 1 TO vm_max_rows
	INITIALIZE rm_det[i].*, rm_adi[i].* TO NULL
END FOR
LET query = 'SELECT c_tra, nom_trab, d_g, a_vac, d_r, per_ini, per_fin, ',
			'val_p, val_d',
		' FROM tmp_dia_goz ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ', ',
			      vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE tmp_d FROM query	
DECLARE q_car CURSOR FOR tmp_d
LET vm_num_rows = 1
FOREACH q_car INTO rm_det[vm_num_rows].*
	LET rm_adi[vm_num_rows].c_trab = rm_det[vm_num_rows].n47_cod_trab
	LET rm_adi[vm_num_rows].anio_p = rm_det[vm_num_rows].anio_vac
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1

END FUNCTION



FUNCTION lee_detalle()
DEFINE i, j, l, salir	SMALLINT
DEFINE tot_d_g, k	SMALLINT
DEFINE mensaje		VARCHAR(250)
DEFINE resp		CHAR(6)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE d_real		LIKE rolt047.n47_dias_real

CALL fl_lee_proceso_roles(rm_n47.n47_cod_liqrol) RETURNING r_n03.*
LET int_flag = 0
LET salir    = 0
CALL calcula_total()
WHILE NOT salir
	CALL cargar_detalle()
	CALL set_count(vm_num_rows)
	INPUT ARRAY rm_det WITHOUT DEFAULTS FROM rm_det.*
		ON KEY(INTERRUPT)
        		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag    = 1
				LET vm_cabecera = 0
				EXIT INPUT
			END IF
		ON KEY(F5)
			LET int_flag    = 1
			LET vm_cabecera = 1
			EXIT INPUT
		ON KEY(F6)
			LET i = arr_curr()
			CALL ver_comprobante_vacaciones(i, 'C')
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			CALL ver_comprobante_vacaciones(i, 'G')
			LET int_flag = 0
		ON KEY(F8)
			LET i = arr_curr()
			CALL ver_liquidacion(i, 'L')
			LET int_flag = 0
		ON KEY(F9)
			LET i = arr_curr()
			IF NOT (rm_det[i].n47_dias_goza IS NOT NULL AND
				rm_det[i].anio_vac IS NOT NULL)
			THEN
				CONTINUE INPUT
			END IF
			IF NOT otra_vacacion(i) THEN
				LET int_flag = 0
				CONTINUE INPUT
			END IF
			FOR l = 1 TO vm_num_rows
				IF NOT (rm_det[l].n47_dias_goza IS NOT NULL AND
					rm_det[l].anio_vac IS NOT NULL)
				THEN
					CONTINUE FOR
				END IF
				CALL actualizar_temporal(l, 1)
				LET rm_adi[l].anio_p = rm_det[l].anio_vac
			END FOR
			LET int_flag = 0
			LET salir    = 0
			EXIT INPUT
		ON KEY(F10)
			LET i = arr_curr()
			LET rm_det[i].n47_dias_goza = NULL
			LET rm_det[i].anio_vac      = NULL
			CALL borrar_detalle_dias_gozo(i, j)
		BEFORE INPUT
	        	--#CALL dialog.keysetlabel('INSERT','')
        		--#CALL dialog.keysetlabel('DELETE','')
        		--#CALL dialog.keysetlabel('F10','Borrar Vacacion')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_etiquetas(i)
			IF rm_det[i].n47_dias_goza IS NOT NULL AND
			   rm_det[i].anio_vac IS NOT NULL
			THEN
        			CALL dialog.keysetlabel('F9','Vacacion Adicional')
			ELSE
        			CALL dialog.keysetlabel('F9','')
			END IF
		BEFORE INSERT
			--LET salir = 0
			--EXIT INPUT
			CANCEL INSERT
		BEFORE DELETE
			CANCEL DELETE
		BEFORE FIELD n47_dias_real
			LET d_real = rm_det[i].n47_dias_real
		AFTER FIELD n47_dias_goza, anio_vac
			IF NOT calcular_dias_gozo(i, j, 0) THEN
				NEXT FIELD anio_vac
			END IF
		AFTER FIELD n47_dias_real
			IF rm_det[i].n47_dias_real IS NULL THEN
				LET rm_det[i].n47_dias_real = d_real
				DISPLAY rm_det[i].n47_dias_real TO
					rm_det[j].n47_dias_real
			END IF
			IF rm_det[i].n47_dias_real > rm_det[i].n47_dias_goza
			THEN
				CALL fl_mostrar_mensaje('Los dias reales de vacaciones no puede ser mayor que los dias a gozar.', 'exclamation')
				NEXT FIELD n47_dias_real
			END IF
			IF NOT calcular_dias_gozo(i, j, 0) THEN
				NEXT FIELD anio_vac
			END IF
		AFTER ROW
			IF NOT calcular_dias_gozo(i, j, 1) THEN
				NEXT FIELD anio_vac
			END IF
		AFTER INPUT
			FOR l = 1 TO vm_num_rows
				IF NOT (rm_det[l].n47_dias_goza IS NOT NULL AND
					rm_det[l].anio_vac IS NOT NULL)
				THEN
					CONTINUE FOR
				END IF
				LET rm_adi[l].anio_p = rm_det[l].anio_vac
				LET tot_d_g = rm_det[l].n47_dias_goza
				FOR k = 1 TO vm_num_rows
					IF (rm_det[l].n47_cod_trab =
					    rm_det[k].n47_cod_trab) AND
					   (l <> k)
					THEN
						LET tot_d_g = tot_d_g +
							rm_det[k].n47_dias_goza
					END IF
				END FOR
				IF tot_d_g > rm_n00.n00_dias_vacac THEN
					LET mensaje = 'Los dias de vacaciones',
						' para el empleado: ',
						rm_det[i].n47_cod_trab
						USING "<<<<&", ' ',
						rm_det[i].n30_nombres CLIPPED,
						' son mayor a ',
						rm_n00.n00_dias_vacac
						USING "<<<&", ' que es el',
						' maximo de dias vacaciones',
						' permitido.'
					CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
			CALL calcula_total()
			LET salir = 1
	END INPUT
	IF int_flag = 1 THEN
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION calcular_dias_gozo(i, j, flag)
DEFINE i, j, flag	SMALLINT
DEFINE resul		SMALLINT

LET resul = 1
IF rm_det[i].anio_vac IS NOT NULL AND rm_det[i].n47_dias_goza IS NOT NULL THEN
	IF NOT genera_detalle_dias_gozo(i, j, 'U') THEN
		CALL borrar_detalle_dias_gozo(i, j)
		LET resul = 0
	END IF
ELSE
	IF flag THEN
		LET rm_det[i].n47_dias_goza = NULL
		LET rm_det[i].anio_vac      = NULL
	END IF
	CALL borrar_detalle_dias_gozo(i, j)
END IF
IF rm_det[i].anio_vac IS NOT NULL AND resul THEN
	CALL valida_tiempo_vac(rm_det[i].n47_cod_trab, rm_det[i].anio_vac)
		RETURNING resul
END IF
RETURN resul

END FUNCTION



FUNCTION genera_detalle_dias_gozo(i, j, flag)
DEFINE i, j		SMALLINT
DEFINE flag		CHAR(1)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE dias_gozo	LIKE rolt039.n39_dias_goza
DEFINE mensaje		VARCHAR(250)

INITIALIZE r_n39.* TO NULL
DECLARE q_n39 CURSOR FOR
	SELECT * FROM rolt039
		WHERE n39_compania    = vg_codcia
		  AND n39_proceso     = vm_proceso
		  AND n39_cod_trab    = rm_det[i].n47_cod_trab
		  AND n39_ano_proceso = rm_det[i].anio_vac
		ORDER BY n39_periodo_fin DESC
OPEN q_n39
FETCH q_n39 INTO r_n39.*
CLOSE q_n39
FREE q_n39
IF r_n39.n39_compania IS NULL THEN
	DECLARE q_n39_2 CURSOR FOR
		SELECT * FROM rolt039
			WHERE n39_compania    = vg_codcia
			  AND n39_proceso     = vm_vac_pag
			  AND n39_cod_trab    = rm_det[i].n47_cod_trab
			  AND n39_ano_proceso = rm_det[i].anio_vac
			ORDER BY n39_periodo_fin DESC
	OPEN q_n39_2
	FETCH q_n39_2 INTO r_n39.*
	CLOSE q_n39_2
	FREE q_n39_2
	IF r_n39.n39_compania IS NOT NULL THEN
		LET mensaje = 'Las'
	ELSE
		LET mensaje = 'No existe registro de'
	END IF
	LET mensaje = mensaje CLIPPED, ' vacaciones para el empleado: ',
			rm_det[i].n47_cod_trab USING "<<<<&", ' ',
			rm_det[i].n30_nombres CLIPPED, ' en el año ',
			rm_det[i].anio_vac USING "&&&&"
	IF r_n39.n39_compania IS NOT NULL THEN
		LET mensaje = mensaje CLIPPED, ' son PAGADAS y no pueden ser ',
				'GOZADAS.'
	ELSE
		LET mensaje = mensaje CLIPPED, '.'
	END IF
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
IF r_n39.n39_estado = 'A' THEN
	LET mensaje = 'El registro de vacaciones del empleado: ',
			rm_det[i].n47_cod_trab USING "<<<<&", ' ',
			rm_det[i].n30_nombres CLIPPED, ' para el año ',
			rm_det[i].anio_vac USING "&&&&", ', no esta cerrado.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
IF r_n39.n39_tipo = 'P' THEN
	LET mensaje = 'Las vacaciones del empleado: ',
			rm_det[i].n47_cod_trab USING "<<<<&", ' ',
			rm_det[i].n30_nombres CLIPPED, ' para el año ',
			rm_det[i].anio_vac USING "&&&&", ', no tiene días ',
			'para gozar.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
{-
LET dias_gozo = r_n39.n39_dias_vac
IF r_n39.n39_gozar_adic = 'S' THEN
	LET dias_gozo = dias_gozo + r_n39.n39_dias_adi
END IF
--}
LET dias_gozo = r_n39.n39_dias_vac + r_n39.n39_dias_adi
LET dias_gozo = dias_gozo - r_n39.n39_dias_goza - tot_dias_n47(r_n39.*)
IF rm_det[i].n47_dias_goza - dias_gozo > 0 THEN
	LET mensaje = 'Las vacaciones del empleado: ',
			rm_det[i].n47_cod_trab USING "<<<<&", ' ',
			rm_det[i].n30_nombres CLIPPED, ' para el año ',
			rm_det[i].anio_vac USING "&&&&", ', ya tiene ',
			r_n39.n39_dias_goza USING "<<<<<&", ' días gozados',
			' y no puede ingresar ', rm_det[i].n47_dias_goza
			USING "<<<<<&", ' días para gozar. Tiene ',
			dias_gozo USING "<<<<<&", ' dias disponibles.'
	CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
	RETURN 0
END IF
IF rm_det[i].n47_dias_real IS NULL THEN
	LET rm_det[i].n47_dias_real = rm_det[i].n47_dias_goza
END IF
LET rm_det[i].n47_periodo_ini = r_n39.n39_periodo_ini
LET rm_det[i].n47_periodo_fin = r_n39.n39_periodo_fin
LET rm_det[i].n47_valor_pag   = calcula_valor_vacaciones(r_n39.*, i, vm_proceso)
LET rm_det[i].n47_valor_des   = calcula_valor_vacaciones(r_n39.*, i, 'XV')
CASE flag
	WHEN 'U'
		CALL actualizar_temporal(i, 1)
		DISPLAY rm_det[i].* TO rm_det[j].*
		CALL calcula_total()
	WHEN 'I'
		CALL actualizar_temporal(i, 0)
END CASE
RETURN 1

END FUNCTION



FUNCTION borrar_detalle_dias_gozo(i, j)
DEFINE i, j		SMALLINT

LET rm_det[i].n47_dias_real   = NULL
LET rm_det[i].n47_periodo_ini = NULL
LET rm_det[i].n47_periodo_fin = NULL
LET rm_det[i].n47_valor_pag   = NULL
LET rm_det[i].n47_valor_des   = NULL
CALL actualizar_temporal(i, 1)
DISPLAY rm_det[i].* TO rm_det[j].*
CALL calcula_total()

END FUNCTION



FUNCTION valida_tiempo_vac(cod_trab, anio_vac)
DEFINE cod_trab		LIKE rolt047.n47_cod_trab
DEFINE anio_vac		SMALLINT
DEFINE query		CHAR(600)
DEFINE fecha		DATE
DEFINE tiempo_max	INTEGER
DEFINE mensaje		VARCHAR(200)
DEFINE resul		SMALLINT

LET resul = 1
SELECT n39_perfin_real
	INTO fecha
	FROM rolt039
	WHERE n39_compania    = vg_codcia
	  AND n39_proceso     = vm_proceso
	  AND n39_cod_trab    = cod_trab
	  AND n39_ano_proceso = anio_vac
IF STATUS = NOTFOUND THEN
	RETURN resul
END IF
LET query = 'SELECT TRUNC((NVL(',
		'(SELECT MAX(n39_perfin_real) ',
			'FROM rolt039 ',
			'WHERE n39_compania  = ', vg_codcia,
			'  AND n39_proceso  IN ("', vm_proceso, '", "',
						vm_vac_pag, '") ',
			'  AND n39_cod_trab  = ', cod_trab,
			'  AND n39_estado    = "P"), TODAY) - DATE("',
			fecha, '")) / ', rm_n90.n90_dias_anio, ') + 1 val_t ',
			' FROM dual ',
			' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT val_t INTO tiempo_max FROM t1
DROP TABLE t1
IF tiempo_max > rm_n90.n90_tiem_max_vac THEN
	LET mensaje = 'Estas vacaciones tienen mas de ',
			rm_n90.n90_tiem_max_vac USING "<<<&",
			' años, ya no se las puede gozar.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	LET resul = 0
END IF
RETURN resul

END FUNCTION



FUNCTION calcula_valor_vacaciones(r_n39, i, flag_ident)
DEFINE i, j		SMALLINT
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE val_vac		LIKE rolt039.n39_valor_vaca
DEFINE valor		LIKE rolt033.n33_valor
DEFINE tot_dias		SMALLINT

LET valor = 0
IF r_n39.n39_estado = 'P' AND r_n39.n39_tipo = 'G' THEN
	LET tot_dias = r_n39.n39_dias_vac
	LET val_vac  = r_n39.n39_valor_vaca
	IF r_n39.n39_gozar_adic = 'S' THEN
		LET tot_dias = tot_dias + r_n39.n39_dias_adi
		LET val_vac  = val_vac  + r_n39.n39_valor_adic
	END IF
	LET valor = ((val_vac + r_n39.n39_otros_ing) / tot_dias) *
			rm_det[i].n47_dias_goza
	IF flag_ident = 'XV' THEN
		CALL fl_lee_trabajador_roles(r_n39.n39_compania,
						r_n39.n39_cod_trab)
			RETURNING r_n30.*
		CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
		LET valor = valor - (valor * r_n13.n13_porc_trab / 100)
	END IF
END IF
RETURN valor

END FUNCTION



FUNCTION actualizar_temporal(i, flag)
DEFINE i, flag		SMALLINT
DEFINE query		CHAR(800)
DEFINE expr_up		CHAR(600)
DEFINE expr_ani		VARCHAR(100)
DEFINE fecha_fin	DATE
DEFINE encont, l	SMALLINT

LET fecha_fin = rm_n47.n47_fecha_ini + rm_det[i].n47_dias_goza UNITS DAY
		- 1 UNITS DAY
IF flag THEN
	LET expr_up = ' SET d_g     = ', rm_det[i].n47_dias_goza, ', ',
			'     a_vac   = ', rm_det[i].anio_vac, ', ',
			'     d_r     = ', rm_det[i].n47_dias_real, ', ',
			'     per_ini = "', rm_det[i].n47_periodo_ini, '", ',
			'     per_fin = "', rm_det[i].n47_periodo_fin, '", ',
			'     val_p   = ', rm_det[i].n47_valor_pag, ', ',
			'     val_d   = ', rm_det[i].n47_valor_des, ', ',
			'     fec_ini = "', rm_n47.n47_fecha_ini, '", ',
			'     fec_fin = "', fecha_fin, '", ',
			'     a_pro   = ', rm_det[i].anio_vac
	LET expr_ani = '   AND (a_vac = ', rm_det[i].anio_vac,
			'    OR  a_vac IS NULL) '
	IF rm_det[i].n47_dias_goza IS NULL THEN
		LET expr_up = ' SET d_g     = NULL, ',
				'     a_vac   = ', rm_det[i].anio_vac, ', ',
				'     d_r     = NULL, ',
				'     per_ini = NULL, ',
				'     per_fin = NULL, ',
				'     val_p   = NULL, ',
				'     val_d   = NULL, ',
				'     fec_ini = NULL, ',
				'     fec_fin = NULL '
	END IF
	IF rm_det[i].anio_vac IS NULL THEN
		LET expr_up = ' SET d_g     = ', rm_det[i].n47_dias_goza, ', ',
				'     a_vac   = NULL, ',
				'     d_r     = NULL, ',
				'     per_ini = NULL, ',
				'     per_fin = NULL, ',
				'     val_p   = NULL, ',
				'     val_d   = NULL, ',
				'     fec_ini = NULL, ',
				'     fec_fin = NULL '
		LET expr_ani = '   AND a_pro IS NOT NULL '
		LET encont   = 0
		FOR l = 1 TO vm_num_rows
			IF (rm_det[i].n47_cod_trab = rm_det[l].n47_cod_trab) AND
			   (i <> l)
			THEN
				IF rm_adi[l].anio_p IS NOT NULL THEN
					LET encont = 1
					EXIT FOR
				END IF
			END IF
		END FOR
		IF encont THEN
			LET expr_ani = '   AND a_pro = ', rm_adi[i].anio_p
		END IF
	END IF
	{--
	IF rm_det[i].n47_dias_goza IS NOT NULL AND
	   rm_det[i].anio_vac IS NOT NULL AND
	   rm_det[i].n47_dias_real IS NULL
	THEN
		LET expr_up = ' SET d_g     = ', rm_det[i].n47_dias_goza, ', ',
				'     a_vac   = ', rm_det[i].anio_vac, ', ',
				'     d_r     = NULL, ',
				'     per_ini = NULL, ',
				'     per_fin = NULL, ',
				'     val_p   = NULL, ',
				'     val_d   = NULL, ',
				'     fec_ini = NULL, ',
				'     fec_fin = NULL '
		IF rm_adi[i].anio_p IS NOT NULL THEN
			LET expr_ani = '   AND a_pro = ', rm_adi[i].anio_p
		END IF
	END IF
	IF rm_det[i].n47_dias_goza IS NULL AND rm_det[i].anio_vac IS NULL THEN
	--}
	IF rm_det[i].n47_dias_real IS NULL THEN
		LET expr_up = ' SET d_g     = NULL, ',
				'     a_vac   = NULL, ',
				'     d_r     = NULL, ',
				'     per_ini = NULL, ',
				'     per_fin = NULL, ',
				'     val_p   = NULL, ',
				'     val_d   = NULL, ',
				'     fec_ini = NULL, ',
				'     fec_fin = NULL '
		IF rm_adi[i].anio_p IS NOT NULL THEN
			LET expr_ani = '   AND a_pro = ', rm_adi[i].anio_p
		END IF
	END IF
	LET query = 'UPDATE tmp_dia_goz ',
			expr_up CLIPPED,
			' WHERE  c_tra = ', rm_det[i].n47_cod_trab,
			expr_ani CLIPPED
	PREPARE exec_up_tmp FROM query
	EXECUTE exec_up_tmp
ELSE
	INSERT INTO tmp_dia_goz
		VALUES(rm_det[i].*, rm_n47.n47_fecha_ini, fecha_fin,
			rm_det[i].anio_vac)
END IF

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE i, j, col	SMALLINT

CALL calcula_total()
LET int_flag = 0
CALL set_count(vm_num_rows)
DISPLAY ARRAY rm_det TO rm_det.*
       	ON KEY(INTERRUPT)   
		LET int_flag    = 1
		LET vm_cabecera = 0
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET int_flag    = 1
		LET vm_cabecera = 1
		EXIT DISPLAY
	ON KEY(F6)
		LET i = arr_curr()
		CALL ver_comprobante_vacaciones(i, 'C')
		LET int_flag = 0
	ON KEY(F7)
		LET i = arr_curr()
		CALL ver_comprobante_vacaciones(i, 'G')
		LET int_flag = 0
	ON KEY(F8)
		LET i = arr_curr()
		CALL ver_liquidacion(i, 'L')
		LET int_flag = 0
	ON KEY(F15)
		LET col = 1
		EXIT DISPLAY
	ON KEY(F16)
		LET col = 2
		EXIT DISPLAY
	ON KEY(F17)
		LET col = 3
		EXIT DISPLAY
	ON KEY(F18)
		LET col = 4
		EXIT DISPLAY
	ON KEY(F19)
		LET col = 5
		EXIT DISPLAY
	ON KEY(F20)
		LET col = 6
		EXIT DISPLAY
	ON KEY(F21)
		LET col = 7
		EXIT DISPLAY
	ON KEY(F22)
		LET col = 8
		EXIT DISPLAY
	ON KEY(F23)
		LET col = 9
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_etiquetas(i)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF int_flag = 1 THEN
	RETURN
END IF
IF col <> vm_columna_1 THEN
	LET vm_columna_2           = vm_columna_1 
	LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
	LET vm_columna_1           = col 
END IF
IF rm_orden[vm_columna_1] = 'ASC' THEN
	LET rm_orden[vm_columna_1] = 'DESC'
ELSE
	LET rm_orden[vm_columna_1] = 'ASC'
END IF

END FUNCTION



FUNCTION muestra_etiquetas(i)
DEFINE i		SMALLINT

CALL muestra_contadores(i, vm_num_rows)
DISPLAY rm_det[i].n30_nombres TO nom_trab

END FUNCTION



FUNCTION calcula_total()
DEFINE i		SMALLINT

LET tot_valor_pag = 0
LET tot_valor_des = 0
FOR i = 1 TO vm_num_rows
	IF rm_det[i].n47_valor_pag IS NULL OR rm_det[i].n47_valor_des IS NULL
	THEN
		CONTINUE FOR
	END IF
	LET tot_valor_pag = tot_valor_pag + rm_det[i].n47_valor_pag
	LET tot_valor_des = tot_valor_des + rm_det[i].n47_valor_des
END FOR
DISPLAY BY NAME tot_valor_pag, tot_valor_des

END FUNCTION



FUNCTION retorna_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_n39.n39_mes_proceso), 10)
	RETURNING tit_mes

END FUNCTION 



FUNCTION mostrar_fechas()

CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n47.n47_cod_liqrol,
				rm_n39.n39_ano_proceso, rm_n39.n39_mes_proceso)
	RETURNING rm_n47.n47_fecha_ini, rm_n47.n47_fecha_fin
DISPLAY BY NAME rm_n47.n47_fecha_ini, rm_n47.n47_fecha_fin

END FUNCTION 



FUNCTION regenerar_novedades(cod_trab, flag)
DEFINE cod_trab		LIKE rolt039.n39_cod_trab
DEFINE flag		SMALLINT
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE mensaje		VARCHAR(200)
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005 
	WHERE n05_compania = vg_codcia
	  AND n05_activo   = 'S'
IF r_n05.n05_compania IS NOT NULL THEN
	IF r_n05.n05_proceso[1,1] = 'M' OR r_n05.n05_proceso[1,1] = 'Q' OR
	   r_n05.n05_proceso[1,1] = 'S' THEN
		CALL fl_lee_trabajador_roles(vg_codcia, cod_trab)
			RETURNING r_n30.*
		LET mensaje = 'Se va a regenerar novedad de ',r_n05.n05_proceso,
				' ', r_n05.n05_fecini_act USING "dd-mm-yyyy",
				' - ', r_n05.n05_fecfin_act USING "dd-mm-yyyy",
				' para el trabajador ', cod_trab USING "&&&&",
				' ', r_n30.n30_nombres CLIPPED
		IF flag THEN
			CALL fl_mostrar_mensaje(mensaje, 'info')
		END IF
		LET prog  = 'rolp203 '
		LET param = ' X ', cod_trab
		CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)
	END IF
END IF

END FUNCTION


 
FUNCTION ver_comprobante_vacaciones(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)

IF rm_det[i].n47_periodo_ini IS NULL THEN
	RETURN
END IF
LET param = ' "P" "', vm_proceso, '" ', rm_det[i].n47_cod_trab
IF flag <> 'L' THEN
	LET param = param CLIPPED, ' "', rm_det[i].n47_periodo_ini, '" "',
			rm_det[i].n47_periodo_fin, '"'
	IF flag = 'G' THEN
		LET param = param CLIPPED, ' "G"'
	END IF
END IF
CALL ejecuta_comando('NOMINA', vg_modulo, 'rolp252 ', param)

END FUNCTION


 
FUNCTION ver_liquidacion(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*

CALL fl_lee_liquidacion_roles(vg_codcia, rm_n47.n47_cod_liqrol,
				rm_n47.n47_fecha_ini, rm_n47.n47_fecha_fin,
				rm_det[i].n47_cod_trab)
	RETURNING r_n32.*
CALL fl_lee_trabajador_roles(vg_codcia, rm_det[i].n47_cod_trab)
	RETURNING r_n30.*
LET prog = 'rolp303 '
CASE flag
	WHEN 'T'
		LET param = ' "', rm_n47.n47_cod_liqrol, '" ',
				'"', rm_n47.n47_fecha_ini, '" ',
				'"', rm_n47.n47_fecha_fin, '" "N" ',
				r_n32.n32_cod_depto
	WHEN 'L'
		LET param = ' "', rm_n47.n47_cod_liqrol, '" ',
				'"', rm_n47.n47_fecha_ini, '" ',
				'"', rm_n47.n47_fecha_fin, '" "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
	WHEN 'I'
		LET prog  = 'rolp405 '
		LET param = ' ', YEAR(r_n32.n32_fecha_ini), ' ',
				MONTH(r_n32.n32_fecha_ini), ' "',
				r_n32.n32_cod_liqrol, '"', ' "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
		IF r_n30.n30_estado = 'J' THEN
			LET prog  = 'rolp404 '
			LET param = ' ', YEAR(r_n32.n32_fecha_ini), ' ',
					MONTH(r_n32.n32_fecha_ini)
		END IF
END CASE
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION otra_vacacion(i)
DEFINE i		SMALLINT
DEFINE r_par		RECORD
				n47_cod_trab	LIKE rolt047.n47_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				anio_vac	SMALLINT,
				n47_dias_goza	LIKE rolt047.n47_dias_goza,
				n47_dias_real	LIKE rolt047.n47_dias_real
			END RECORD
DEFINE d_real		LIKE rolt047.n47_dias_real
DEFINE resul		SMALLINT

LET resul = 0
OPEN WINDOW w_rolf254_2 AT 07, 12 WITH FORM "../forms/rolf254_2" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
INITIALIZE r_par.* TO NULL
LET r_par.n47_cod_trab = rm_det[i].n47_cod_trab
LET r_par.n30_nombres  = rm_det[i].n30_nombres
LET int_flag = 0
INPUT BY NAME r_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE FIELD n47_dias_real
		LET d_real = r_par.n47_dias_real
	AFTER FIELD n47_dias_goza, anio_vac
		IF NOT valida_tiempo_vac(r_par.n47_cod_trab, r_par.anio_vac)
		THEN
			NEXT FIELD anio_vac
		END IF
	AFTER FIELD n47_dias_real
		IF r_par.n47_dias_real IS NULL THEN
			LET r_par.n47_dias_real = d_real
			DISPLAY BY NAME r_par.n47_dias_real
		END IF
		IF r_par.n47_dias_real > r_par.n47_dias_goza THEN
			CALL fl_mostrar_mensaje('Los dias reales de vacaciones no puede ser mayor que los dias a gozar.', 'exclamation')
			NEXT FIELD n47_dias_real
		END IF
		IF NOT valida_tiempo_vac(r_par.n47_cod_trab, r_par.anio_vac)
		THEN
			NEXT FIELD anio_vac
		END IF
	AFTER INPUT
		LET resul = 1
END INPUT
IF resul THEN
	INITIALIZE rm_det[vm_num_rows + 1].* TO NULL
	LET rm_det[vm_num_rows + 1].n47_cod_trab  = r_par.n47_cod_trab
	LET rm_det[vm_num_rows + 1].n30_nombres   = r_par.n30_nombres
	LET rm_det[vm_num_rows + 1].n47_dias_goza = r_par.n47_dias_goza
	LET rm_det[vm_num_rows + 1].anio_vac      = r_par.anio_vac
	LET rm_det[vm_num_rows + 1].n47_dias_real = r_par.n47_dias_real
	CALL genera_detalle_dias_gozo(vm_num_rows + 1, 0, 'I') RETURNING resul
END IF
CLOSE WINDOW w_rolf254_2
RETURN resul

END FUNCTION



FUNCTION tot_dias_n47(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE tot_dias		SMALLINT

LET tot_dias = 0
SELECT NVL(SUM(a.n47_dias_goza), 0) INTO tot_dias
	FROM rolt047 a
	WHERE a.n47_compania    = r_n39.n39_compania
	  AND a.n47_proceso     = r_n39.n39_proceso
	  AND a.n47_cod_trab    = r_n39.n39_cod_trab
	  AND a.n47_periodo_ini = r_n39.n39_periodo_ini
	  AND a.n47_periodo_fin = r_n39.n39_periodo_fin
	  AND NOT EXISTS
		(SELECT 1 FROM rolt047 b
			WHERE b.n47_compania    = a.n47_compania
			  AND b.n47_proceso     = a.n47_proceso
			  AND b.n47_cod_trab    = a.n47_cod_trab
			  AND b.n47_periodo_ini = a.n47_periodo_ini
			  AND b.n47_periodo_fin = a.n47_periodo_fin
			  AND b.n47_cod_liqrol  = rm_n47.n47_cod_liqrol
			  AND b.n47_fecha_ini   = rm_n47.n47_fecha_ini
			  AND b.n47_fecha_fin   = rm_n47.n47_fecha_fin)
	  AND a.n47_estado      = "A"
RETURN tot_dias

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo, vg_separador,
		'fuentes', vg_separador, run_prog, prog, vg_base, ' ', mod, ' ',
		vg_codcia, ' ', param
RUN comando

END FUNCTION
