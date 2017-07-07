------------------------------------------------------------------------------
-- Titulo           : ctbp107.4gl - Mantenimiento de Códigos Distribución Ctas. 
-- Elaboracion      : 26-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp107 base módulo commpañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_ctb		RECORD LIKE ctbt016.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_elm	SMALLINT
DEFINE vm_num_elm	SMALLINT
DEFINE vm_total_por	DECIMAL(4,2)
DEFINE vm_r_rows	ARRAY [1000] OF LIKE ctbt016.b16_cta_master
DEFINE vm_cm 		ARRAY [1000] OF RECORD
				b16_cta_detail	LIKE ctbt016.b16_cta_detail,
				tit_detalle	LIKE ctbt010.b10_descripcion,
				b16_porcentaje	LIKE ctbt016.b16_porcentaje
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/ctbp107.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp107'
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
LET vm_max_elm	= 1000
OPEN WINDOW wf AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf107_1"
DISPLAY FORM f_ctb
CALL mostrar_botones_detalle()
INITIALIZE rm_ctb.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
       	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_elm > fgl_scr_size('vm_cm') THEN
			SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Detalle'
		END IF
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
		IF vm_num_elm > fgl_scr_size('vm_cm') THEN
			SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Detalle'
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
		IF vm_num_elm > fgl_scr_size('vm_cm') THEN
			SHOW OPTION 'Detalle'
		ELSE
			HIDE OPTION 'Detalle'
		END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
		CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_elm		SMALLINT
DEFINE indice		SMALLINT

CALL fl_retorna_usuario()
INITIALIZE rm_ctb.* TO NULL
LET vm_num_elm = 0
LET vm_total_por = 0
FOR indice = 1 TO vm_max_elm
	INITIALIZE vm_cm[indice].b16_cta_detail TO NULL
	LET vm_cm[indice].b16_porcentaje = 0
END FOR
CLEAR tit_master, tit_total_por
FOR indice = 1 TO fgl_scr_size('vm_cm')
	CLEAR vm_cm[indice].b16_cta_detail
	CLEAR vm_cm[indice].b16_porcentaje
	CLEAR vm_cm[indice].tit_detalle
END FOR
LET rm_ctb.b16_compania = vg_codcia
CALL leer_cabecera()
IF NOT int_flag THEN
	WHILE TRUE
		CALL leer_detalle() RETURNING num_elm
		IF num_elm = 0 AND NOT int_flag THEN
			CALL fgl_winmessage(vg_producto,'La cuenta de distribución debe tener al menos un detalle','info')
		ELSE
			IF vm_total_por = 100 OR int_flag THEN
				EXIT WHILE
			ELSE
				LET vm_total_por = 0
				CALL fgl_winmessage(vg_producto,'El total debe ser del 100 por ciento, para grabar','info')
			END IF
		END IF
	END WHILE
END IF
IF NOT int_flag THEN
	BEGIN WORK
	FOR indice = 1 TO num_elm
		INSERT INTO ctbt016 VALUES (rm_ctb.b16_compania,
					rm_ctb.b16_cta_master,
					vm_cm[indice].b16_cta_detail,
					vm_cm[indice].b16_porcentaje)
	END FOR
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = rm_ctb.b16_cta_master
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE num_elm		SMALLINT
DEFINE indice		SMALLINT
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM ctbt016
	WHERE b16_compania = vg_codcia
	AND b16_cta_master = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_ctb.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
LET vm_total_por = 0
CALL leer_detalle() RETURNING num_elm
IF NOT int_flag THEN
	DELETE FROM ctbt016 
		WHERE b16_compania = vg_codcia
		AND b16_cta_master = rm_ctb.b16_cta_master
	FOR indice = 1 TO arr_count()
		INSERT INTO ctbt016 VALUES (rm_ctb.b16_compania,
					rm_ctb.b16_cta_master,
					vm_cm[indice].b16_cta_detail,
					vm_cm[indice].b16_porcentaje)
	END FOR
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	COMMIT WORK
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END If
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ctbt016.b16_cta_master
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)

LET int_flag = 0
CLEAR FORM
CALL mostrar_botones_detalle()
INITIALIZE cod_aux TO NULL
CONSTRUCT BY NAME expr_sql ON b16_cta_master
	ON KEY(F2)
	IF INFIELD(b16_cta_master) THEN
		CALL fl_ayuda_distribucion_cuentas(vg_codcia)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b16_cta_master 
			DISPLAY nom_aux TO tit_master
		END IF 
	END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL mostrar_botones_detalle()
	END IF
	RETURN
END IF
LET query = 'SELECT UNIQUE b16_cta_master FROM ctbt016
		WHERE b16_compania = ' || vg_codcia ||
		' AND ' || expr_sql CLIPPED
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL mostrar_botones_detalle()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE mas_aux		LIKE ctbt016.b16_cta_master
DEFINE det_aux		LIKE ctbt016.b16_cta_detail
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE maxnivel		LIKE ctbt001.b01_nivel
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*

OPTIONS INPUT NO WRAP
LET int_flag = 0
LET maxnivel = 0
INITIALIZE r_ctb_aux.* TO NULL
INPUT BY NAME rm_ctb.b16_cta_master
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        IF field_touched(rm_ctb.b16_cta_master) THEN
               	LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
              	IF resp = 'Yes' THEN
			LET vm_total_por = 0
			LET int_flag = 1
                       	CLEAR FORM
			CALL mostrar_botones_detalle()
                       	RETURN
                END IF
	ELSE
		RETURN
	END IF
	ON KEY(F2)
	IF INFIELD(b16_cta_master) THEN
		CALL fl_ayuda_cuenta_contable(vg_codcia,6)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			LET rm_ctb.b16_cta_master = cod_aux
			DISPLAY BY NAME rm_ctb.b16_cta_master 
			DISPLAY nom_aux TO tit_master
		END IF 
	END IF
	AFTER FIELD b16_cta_master
		IF rm_ctb.b16_cta_master IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia,rm_ctb.b16_cta_master)
				RETURNING r_ctb_aux.*
			IF r_ctb_aux.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'La cuenta no existe','exclamation')
				NEXT FIELD rm_ctb.b16_cta_master
			END IF
			DECLARE q_up1 CURSOR FOR SELECT b16_cta_master
				FROM ctbt016
				WHERE b16_compania = vg_codcia AND
					b16_cta_master = rm_ctb.b16_cta_master
			OPEN q_up1
			FETCH q_up1 INTO mas_aux
			IF rm_ctb.b16_cta_master = mas_aux THEN
				CALL fgl_winmessage(vg_producto,'La cuenta ya es de distribución','exclamation')
				NEXT FIELD rm_ctb.b16_cta_master
			END IF
			DECLARE q_up2 CURSOR FOR SELECT b16_cta_detail
				FROM ctbt016
				WHERE b16_compania = vg_codcia AND 
					b16_cta_detail = rm_ctb.b16_cta_master
			OPEN q_up2
			FETCH q_up2 INTO det_aux
			IF rm_ctb.b16_cta_master = det_aux THEN
				CALL fgl_winmessage(vg_producto,'La cuenta ya es de detalle','exclamation')
				NEXT FIELD rm_ctb.b16_cta_master
			END IF
			DISPLAY r_ctb_aux.b10_descripcion TO tit_master
			SELECT MAX(b01_nivel) INTO maxnivel FROM ctbt001
			IF r_ctb_aux.b10_permite_mov = 'N' THEN
				CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
				NEXT FIELD rm_ctb.b16_cta_master
			END IF
			IF r_ctb_aux.b10_tipo_cta <> 'R' THEN
				CALL fgl_winmessage(vg_producto,'La cuenta debe ser de resultado','exclamation')
				NEXT FIELD rm_ctb.b16_cta_master
			END IF
		ELSE
			CLEAR tit_master
		END IF 
END INPUT
FREE q_up1
FREE q_up2
RETURN

END FUNCTION



FUNCTION leer_detalle()
DEFINE resp		CHAR(6)
DEFINE i,j		SMALLINT
DEFINE mas_aux		LIKE ctbt016.b16_cta_master
DEFINE det_aux		LIKE ctbt016.b16_cta_detail
DEFINE cod_aux		LIKE ctbt010.b10_cuenta
DEFINE nom_aux		LIKE ctbt010.b10_descripcion
DEFINE maxnivel		LIKE ctbt001.b01_nivel
DEFINE r_grp		RECORD LIKE ctbt002.*
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*

INITIALIZE r_grp.* TO NULL
INITIALIZE r_ctb_aux.* TO NULL
LET i = 1
CALL mostrar_total()
CALL set_count(vm_num_elm)
LET int_flag = 0
IF vm_total_por < 100 THEN
	INPUT ARRAY vm_cm
		WITHOUT DEFAULTS FROM vm_cm.*
		ON KEY(INTERRUPT)
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
              		IF resp = 'Yes' THEN
				LET vm_total_por = 0
				LET i = i - 1
				LET int_flag = 1
        	       		CLEAR FORM
				CALL mostrar_botones_detalle()
                       		RETURN i
                	END IF
		ON KEY(F2)
			IF INFIELD(b16_cta_detail) THEN
				CALL fl_ayuda_cuenta_contable(vg_codcia,6)
					RETURNING cod_aux, nom_aux
				LET int_flag = 0
				IF cod_aux IS NOT NULL THEN
					LET vm_cm[i].b16_cta_detail = cod_aux
					DISPLAY cod_aux 
						TO vm_cm[j].b16_cta_detail 
					DISPLAY nom_aux TO vm_cm[j].tit_detalle
				END IF 
			END IF
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
		AFTER FIELD b16_cta_detail
			IF vm_cm[i].b16_cta_detail IS NOT NULL THEN
				CALL fl_lee_grupo_cuenta(vg_codcia,vm_cm[i].b16_cta_detail[1,1])
					RETURNING r_grp.*
				IF r_grp.b02_grupo_cta IS NULL THEN
					CALL fgl_winmessage(vg_producto,'Grupo de cuenta incorrecto','exclamation')				
					NEXT FIELD b16_cta_detail
				END IF
				CALL fl_lee_cuenta(vg_codcia,vm_cm[i].b16_cta_detail)
					RETURNING r_ctb_aux.*
				IF r_ctb_aux.b10_cuenta IS NULL THEN
					CALL fgl_winmessage(vg_producto,'La cuenta no existe','exclamation')
					NEXT FIELD b16_cta_detail
				END IF
				IF vm_cm[i].b16_cta_detail
				= rm_ctb.b16_cta_master THEN
					CALL fgl_winmessage(vg_producto,'Error: No puede especificar la misma cuenta de distribución','exclamation')
					NEXT FIELD b16_cta_detail
				END IF
				FOR j = 1 TO arr_count()
					IF i <> j AND vm_cm[i].b16_cta_detail
					= vm_cm[j].b16_cta_detail THEN
						CALL fgl_winmessage(vg_producto,'Error: No puede repetir la misma cuenta de detalle','exclamation')
						NEXT FIELD b16_cta_detail
					END IF
				END FOR
				DECLARE q_up3 CURSOR FOR SELECT b16_cta_master
					FROM ctbt016
					WHERE b16_compania = vg_codcia AND
					b16_cta_master = vm_cm[i].b16_cta_detail
				OPEN q_up3
				FETCH q_up3 INTO mas_aux
				IF STATUS <> NOTFOUND THEN
					CALL fgl_winmessage(vg_producto,'La cuenta ya es de distribución','exclamation')
					NEXT FIELD b16_cta_detail
				END IF
				DISPLAY r_ctb_aux.b10_descripcion
					TO vm_cm[i].tit_detalle
				SELECT MAX(b01_nivel) INTO maxnivel FROM ctbt001
				IF r_ctb_aux.b10_permite_mov = 'N' THEN
					CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
					NEXT FIELD b16_cta_detail
				END IF
				IF r_ctb_aux.b10_tipo_cta <> 'R' THEN
					CALL fgl_winmessage(vg_producto,'La cuenta debe ser de resultado','exclamation')
					NEXT FIELD b16_cta_detail
				END IF
			ELSE
				CLEAR vm_cm[i].tit_detalle
				CLEAR vm_cm[j].b16_porcentaje
				LET vm_cm[i].b16_porcentaje = 0
				CALL sacar_total()
			END IF 
		AFTER FIELD b16_porcentaje
			CALL sacar_total()
		AFTER DELETE
			CALL sacar_total()
		AFTER INPUT
			CALL sacar_total()
			IF vm_total_por <> 100 THEN
				CALL fgl_winmessage(vg_producto,'El total de porcentaje debe ser igual a 100','exclamation')
				NEXT FIELD b16_porcentaje
			END IF
	END INPUT
ELSE
	CALL fgl_winmessage(vg_producto,'Ya no puede ingresar más detalles para esta cuenta de distribución','info')
END IF
LET i = arr_count()
RETURN i

END FUNCTION



FUNCTION sacar_total()
DEFINE i	SMALLINT

LET vm_total_por = 0
FOR i = 1 TO arr_count()
	LET vm_total_por = vm_total_por	+ vm_cm[i].b16_porcentaje
END FOR
CALL mostrar_total()

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*
DEFINE num_registro	LIKE ctbt016.b16_cta_master

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM ctbt016
		WHERE b16_compania = vg_codcia
		AND b16_cta_master = num_registro	
	OPEN q_dt
	FETCH q_dt INTO rm_ctb.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_ctb.b16_cta_master
	CALL fl_lee_cuenta(vg_codcia,rm_ctb.b16_cta_master)
		RETURNING r_ctb_aux.*
	DISPLAY r_ctb_aux.b10_descripcion TO tit_master
	CALL muestra_detalle(num_registro)
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE r_ctb_aux	RECORD LIKE ctbt010.*
DEFINE num_reg		LIKE ctbt016.b16_cta_master
DEFINE query		VARCHAR(400)
DEFINE i		SMALLINT

LET int_flag = 0
FOR i = 1 TO fgl_scr_size('vm_cm')
	INITIALIZE vm_cm[i].* TO NULL
	CLEAR vm_cm[i].*
END FOR
INITIALIZE r_ctb_aux.* TO NULL
LET i = 1
LET query = 'SELECT b16_cta_detail,b16_porcentaje FROM ctbt016
		WHERE b16_compania = ' || vg_codcia || ' AND '
		|| 'b16_cta_master = ' || num_reg 
		|| ' ORDER BY 1'
PREPARE cons1 FROM query	
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_elm = 0
LET vm_total_por = 0
FOREACH q_cons1 INTO vm_cm[i].b16_cta_detail, vm_cm[i].b16_porcentaje
	LET vm_num_elm = vm_num_elm + 1
	LET vm_total_por = vm_total_por + vm_cm[i].b16_porcentaje
	CALL fl_lee_cuenta(vg_codcia,vm_cm[i].b16_cta_detail)
		RETURNING r_ctb_aux.*
	IF r_ctb_aux.b10_cuenta IS NOT NULL THEN
		LET vm_cm[i].tit_detalle = r_ctb_aux.b10_descripcion
	END IF
	LET i = i + 1
        IF vm_num_elm > vm_max_elm THEN
		LET vm_num_elm = vm_num_elm - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
IF vm_num_elm > 0 THEN
	LET int_flag = 0
	FOR i = 1 TO fgl_scr_size('vm_cm')
		DISPLAY vm_cm[i].* TO vm_cm[i].*
	END FOR
END IF
IF int_flag THEN
	INITIALIZE vm_cm[1].* TO NULL
	RETURN
END IF
CALL mostrar_total()

END FUNCTION



FUNCTION muestra_detalle_arr()

CALL set_count(vm_num_elm)
DISPLAY ARRAY vm_cm TO vm_cm.*
	BEFORE DISPLAY
		--#CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION mostrar_total()

DISPLAY vm_total_por TO tit_total_por

END FUNCTION



FUNCTION mostrar_botones_detalle()

DISPLAY 'Cuentas'     TO tit_col1
DISPLAY 'Descripción' TO tit_col2
DISPLAY 'Porcent.'    TO tit_col3

END FUNCTION



FUNCTION no_validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
