--------------------------------------------------------------------------------
-- Titulo               : rolp106.4gl -- Mantenimiento de Rubros Fijos
-- Elaboración          : 17-Feb-2007
-- Autor                : NPC
-- Formato de Ejecución : fglrun rolp106 Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_n10   	RECORD LIKE rolt010.*
DEFINE rm_det		ARRAY [500] OF RECORD
				n10_cod_trab	LIKE rolt010.n10_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				n10_fecha_ini	LIKE rolt010.n10_fecha_ini,
				n10_fecha_fin	LIKE rolt010.n10_fecha_fin,
				n10_valor	LIKE rolt010.n10_valor
			END RECORD
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_total		DECIMAL(12,2)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp106.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp106'
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

CALL fl_nivel_isolation()
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
OPEN WINDOW w_rolf106_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu, BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf106_1 FROM '../forms/rolf106_1'
ELSE
	OPEN FORM f_rolf106_1 FROM '../forms/rolf106_1c'
END IF
DISPLAY FORM f_rolf106_1
INITIALIZE rm_n10.* TO NULL
DISPLAY "Cod."		TO tit_col1
DISPLAY "Empleados"	TO tit_col2
DISPLAY "Fecha Ini."	TO tit_col3
DISPLAY "Fecha Fin."	TO tit_col4
DISPLAY "Valor"		TO tit_col5
CALL muestra_contadores(0, vm_num_rows)
WHILE TRUE
	CALL borrar_detalle()
	CALL control_ingreso()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_proceso()
	DROP TABLE tmp_rub_emp
END WHILE

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_rows
	INITIALIZE rm_det[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size('rm_det')
	CLEAR rm_det[i].*
END FOR
CLEAR n10_usuario, n10_fecing, num_row, max_row, vm_total

END FUNCTION



FUNCTION control_ingreso()

LET rm_n10.n10_compania = vg_codcia
LET rm_n10.n10_usuario  = vg_usuario
LET rm_n10.n10_fecing   = CURRENT
DISPLAY BY NAME rm_n10.n10_fecing, rm_n10.n10_usuario
CALL lee_datos()

END FUNCTION



FUNCTION lee_datos()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE resp      	CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_n10.n10_cod_liqrol, rm_n10.n10_cod_rubro
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n10.n10_cod_liqrol, rm_n10.n10_cod_rubro)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF       	
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n10_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n10.n10_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n10.n10_cod_liqrol,
						r_n03.n03_nombre
			END IF
		END IF
                IF INFIELD(n10_cod_rubro) THEN
                        CALL fl_ayuda_rubros_generales_roles('00', 'T', 'T', 
                                                             'S', 'T', 'T')
                                RETURNING r_n06.n06_cod_rubro, 
					  r_n06.n06_nombre 
                        IF r_n06.n06_cod_rubro IS NOT NULL THEN
                                LET rm_n10.n10_cod_rubro = r_n06.n06_cod_rubro
				DISPLAY BY NAME rm_n10.n10_cod_rubro,
						r_n06.n06_nombre
                        END IF
                END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	 AFTER FIELD n10_cod_liqrol
		IF rm_n10.n10_cod_liqrol IS NOT NULL THEN
			CALL fl_lee_proceso_roles(rm_n10.n10_cod_liqrol)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('El Proceso no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD n10_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			IF r_n03.n03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                        	NEXT FIELD n10_cod_liqrol
			END IF
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n10_cod_rubro
		IF rm_n10.n10_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubro_roles(rm_n10.n10_cod_rubro)
				RETURNING r_n06.*
			IF r_n06.n06_cod_rubro IS NULL THEN
				CALL fl_mostrar_mensaje('Rubro no existe.', 'exclamation')
				NEXT FIELD n10_cod_rubro
			END IF
			DISPLAY BY NAME r_n06.n06_nombre
			IF r_n06.n06_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n10_cod_rubro
			END IF
			IF r_n06.n06_ing_usuario = 'N' THEN
				CALL fl_mostrar_mensaje('El rubro no puede ser ingresado por el usuario.', 'exclamation')
				NEXT FIELD n10_cod_rubro
			END IF
			SELECT * FROM rolt009
				WHERE n09_compania  = vg_codcia
				  AND n09_cod_rubro = rm_n10.n10_cod_rubro
				  AND n09_estado    = 'B'
			IF STATUS <> NOTFOUND THEN
				CALL fl_mostrar_mensaje('El rubro no puede ser ingresado, porque esta bloqueado en la tabla rolt009.', 'exclamation')
				NEXT FIELD n10_cod_rubro
			END IF
		ELSE
			CLEAR n06_nombre
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_proceso()
DEFINE query		CHAR(800)

DECLARE q_ing CURSOR FOR
	SELECT * FROM rolt010
		WHERE n10_compania   = vg_codcia
		  AND n10_cod_liqrol = rm_n10.n10_cod_liqrol
		  AND n10_cod_rubro  = rm_n10.n10_cod_rubro
OPEN q_ing
FETCH q_ing INTO rm_n10.*
CLOSE q_ing
FREE q_ing
DISPLAY BY NAME rm_n10.n10_fecing, rm_n10.n10_usuario
CALL cargar_detalle()
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF
CALL lee_detalle()
IF int_flag THEN
	RETURN
END IF
BEGIN WORK
	DELETE FROM rolt010
		WHERE n10_compania   = vg_codcia
		  AND n10_cod_liqrol = rm_n10.n10_cod_liqrol
		  AND n10_cod_rubro  = rm_n10.n10_cod_rubro
		  AND n10_cod_trab   = (SELECT c_tra FROM tmp_rub_emp
						WHERE lq      = n10_cod_liqrol
						  AND rub     = n10_cod_rubro
						  AND c_tra   = n10_cod_trab)
	LET query = 'INSERT INTO rolt010 ',
			'(n10_compania, n10_cod_rubro, n10_cod_trab, ',
				'n10_cod_liqrol, n10_fecha_ini, n10_fecha_fin,',
				'n10_valor, n10_usuario, n10_fecing) ',
			' SELECT ', vg_codcia, ', rub, c_tra, lq, fec_ini, ',
				'fec_fin, val_det, "', vg_usuario CLIPPED,
				'", CURRENT ',
			' FROM tmp_rub_emp ',
			' WHERE val_det > 0 '
	PREPARE ins_reg FROM query
	EXECUTE ins_reg
COMMIT WORK
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		CHAR(1000)

LET query = 'SELECT NVL(n10_cod_liqrol, "', rm_n10.n10_cod_liqrol, '") lq, ',
		'NVL(n10_cod_rubro, ', rm_n10.n10_cod_rubro, ') rub, ',
			'n30_cod_trab c_tra, n30_nombres nom_trab, ',
			'n10_fecha_ini fec_ini, n10_fecha_fin fec_fin, ',
			'NVL(n10_valor, 0) val_det ',
		' FROM rolt030, OUTER rolt010 ',
		' WHERE n30_compania   = ', vg_codcia,
		'   AND n30_estado     = "A" ',
		'   AND n10_compania   = n30_compania ',
		'   AND n10_cod_rubro  = ', rm_n10.n10_cod_rubro,
		'   AND n10_cod_trab   = n30_cod_trab ',
		'   AND n10_cod_liqrol = "', rm_n10.n10_cod_liqrol, '"',
		' INTO TEMP tmp_rub_emp '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DECLARE q_car CURSOR FOR
	SELECT c_tra, nom_trab, fec_ini, fec_fin, val_det
		FROM tmp_rub_emp
		ORDER BY nom_trab
LET vm_num_rows = 1
FOREACH q_car INTO rm_det[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1

END FUNCTION



FUNCTION lee_detalle()
DEFINE i, j, salir	SMALLINT
DEFINE resp		CHAR(6)

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
LET int_flag = 0
LET salir    = 0
CALL calcula_total()
WHILE NOT salir
	CALL set_count(vm_num_rows)
	INPUT ARRAY rm_det WITHOUT DEFAULTS FROM rm_det.*
		ON KEY(INTERRUPT)
        		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		BEFORE INPUT
	        	--#CALL dialog.keysetlabel('INSERT','')
        		--#CALL dialog.keysetlabel('DELETE','')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores(i, vm_num_rows)
		BEFORE INSERT
			LET salir = 0
			EXIT INPUT
		AFTER FIELD n10_fecha_ini
			IF FIELD_TOUCHED(n10_fecha_ini) THEN
				IF rm_det[i].n10_fecha_ini IS NULL THEN
					LET rm_det[i].n10_fecha_fin = NULL
					DISPLAY rm_det[i].n10_fecha_fin
						TO rm_det[j].n10_fecha_fin
				END IF
			END IF
			IF rm_det[i].n10_fecha_fin IS NOT NULL THEN
				IF rm_det[i].n10_fecha_ini IS NULL THEN
					CALL fl_mostrar_mensaje('Digite la fecha inicial tambien.', 'exclamation')
					NEXT FIELD n10_fecha_ini
				END IF
			END IF
			IF rm_det[i].n10_fecha_ini IS NOT NULL THEN
				IF FIELD_TOUCHED(n10_fecha_ini) THEN
					CALL retorna_fecha_inicial(i, j)
					CALL retorna_fecha_final(i, j)
				END IF
			END IF
			IF rm_det[i].n10_fecha_ini IS NOT NULL THEN
				IF rm_det[i].n10_fecha_fin IS NOT NULL THEN
					IF rm_det[i].n10_fecha_ini >=
					   rm_det[i].n10_fecha_fin
					THEN
						CALL fl_mostrar_mensaje('La fecha inicial debe ser menor a la fecha final.', 'exclamation')
						NEXT FIELD n10_fecha_ini
					END IF
				END IF
			END IF
		AFTER FIELD n10_fecha_fin
			IF FIELD_TOUCHED(n10_fecha_fin) THEN
				IF rm_det[i].n10_fecha_fin IS NULL THEN
					LET rm_det[i].n10_fecha_ini = NULL
					DISPLAY rm_det[i].n10_fecha_ini
						TO rm_det[j].n10_fecha_ini
				END IF
			END IF
			IF rm_det[i].n10_fecha_ini IS NOT NULL THEN
				IF rm_det[i].n10_fecha_fin IS NULL THEN
					CALL fl_mostrar_mensaje('Digite la fecha final.', 'exclamation')
					NEXT FIELD n10_fecha_fin
				END IF
			END IF
			IF rm_det[i].n10_fecha_fin IS NOT NULL THEN
				IF FIELD_TOUCHED(n10_fecha_fin) THEN
					CALL retorna_fecha_inicial(i, j)
					CALL retorna_fecha_final(i, j)
				END IF
			END IF
			IF rm_det[i].n10_fecha_ini IS NOT NULL THEN
				IF rm_det[i].n10_fecha_fin IS NOT NULL THEN
					IF rm_det[i].n10_fecha_ini >=
					   rm_det[i].n10_fecha_fin
					THEN
						CALL fl_mostrar_mensaje('La fecha final debe ser mayor a la fecha inicial.', 'exclamation')
						NEXT FIELD n10_fecha_fin
					END IF
				END IF
			END IF
		AFTER FIELD n10_valor
			IF rm_det[i].n10_valor IS NOT NULL THEN
				UPDATE tmp_rub_emp
					SET val_det = rm_det[i].n10_valor
					WHERE lq    = rm_n10.n10_cod_liqrol
					  AND rub   = rm_n10.n10_cod_rubro
					  AND c_tra = rm_det[i].n10_cod_trab
			ELSE
				LET rm_det[i].n10_valor = 0
				DISPLAY rm_det[i].* TO rm_det[j].*
			END IF		
			CALL calcula_total()
		AFTER INPUT 
			CALL calcula_total()
			LET salir = 1
	END INPUT
	IF int_flag = 1 THEN
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION retorna_fecha_inicial(i, j)
DEFINE i, j		SMALLINT
DEFINE fecha		DATE
DEFINE dia_i		SMALLINT
DEFINE r_n03		RECORD LIKE rolt003.*

CALL fl_lee_proceso_roles(rm_n10.n10_cod_liqrol) RETURNING r_n03.*
IF r_n03.n03_dia_ini IS NOT NULL THEN
	LET dia_i = r_n03.n03_dia_ini
ELSE
	LET dia_i = 1
END IF
LET rm_det[i].n10_fecha_ini = MDY(MONTH(rm_det[i].n10_fecha_ini),
					dia_i, YEAR(rm_det[i].n10_fecha_ini))
DISPLAY rm_det[i].n10_fecha_ini TO rm_det[j].n10_fecha_ini
UPDATE tmp_rub_emp
	SET fec_ini = rm_det[i].n10_fecha_ini
	WHERE lq    = rm_n10.n10_cod_liqrol
	  AND rub   = rm_n10.n10_cod_rubro
	  AND c_tra = rm_det[i].n10_cod_trab

END FUNCTION



FUNCTION retorna_fecha_final(i, j)
DEFINE i, j		SMALLINT
DEFINE fecha		DATE
DEFINE dia_f, dia_a	SMALLINT
DEFINE mes, anio	SMALLINT

IF rm_det[i].n10_fecha_fin IS NOT NULL THEN
	LET dia_a = DAY(rm_det[i].n10_fecha_fin)
	LET mes   = MONTH(rm_det[i].n10_fecha_fin) + 1
	LET anio  = YEAR(rm_det[i].n10_fecha_fin)
	IF mes > 12 THEN
		LET mes  = 1
		LET anio = anio + 1
	END IF
	LET fecha = MDY(mes, 01, anio)
ELSE
	LET fecha = rm_det[i].n10_fecha_ini + 1 UNITS MONTH
	LET dia_a = DAY(fecha)
END IF
LET fecha = MDY(MONTH(fecha), 01, YEAR(fecha)) - 1 UNITS DAY
LET dia_f = DAY(fecha)
IF rm_n10.n10_cod_liqrol = 'Q1' THEN
	LET dia_f = 15
END IF
IF rm_n10.n10_cod_liqrol = 'ME' AND dia_a = 15 THEN
	LET dia_f = dia_a
END IF
IF rm_det[i].n10_fecha_fin IS NOT NULL THEN
	LET rm_det[i].n10_fecha_fin = MDY(MONTH(rm_det[i].n10_fecha_fin), dia_f,
					YEAR(rm_det[i].n10_fecha_fin))
ELSE
	LET rm_det[i].n10_fecha_fin = MDY(MONTH(fecha), dia_f, YEAR(fecha))
END IF
DISPLAY rm_det[i].n10_fecha_fin TO rm_det[j].n10_fecha_fin
UPDATE tmp_rub_emp
	SET fec_fin = rm_det[i].n10_fecha_fin
	WHERE lq    = rm_n10.n10_cod_liqrol
	  AND rub   = rm_n10.n10_cod_rubro
	  AND c_tra = rm_det[i].n10_cod_trab

END FUNCTION



FUNCTION calcula_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_rows
	LET vm_total = vm_total + rm_det[i].n10_valor
END FOR
DISPLAY BY NAME vm_total

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
