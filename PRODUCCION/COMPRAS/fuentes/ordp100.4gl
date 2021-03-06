------------------------------------------------------------------------------
-- Titulo           : ordp100.4gl - Compa��as Configuradas Ordenes de Compras
-- Elaboracion      : 14-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ordp100 base m�dulo commpa��a
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_cia		RECORD LIKE ordt000.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # par�metros correcto
	--CALL fgl_winmessage(vg_producto,'N�mero de par�metros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ordp100'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows	= 50
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
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_ord FROM "../forms/ordf100_1"
ELSE
	OPEN FORM f_ord FROM "../forms/ordf100_1c"
END IF
DISPLAY FORM f_ord
INITIALIZE rm_cia.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
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
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
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
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CALL fl_retorna_usuario()
INITIALIZE rm_cia.* TO NULL
LET rm_cia.c00_cuando_ret = 'P'
IF vg_gui = 0 THEN
	CALL muestra_cuandoret(rm_cia.c00_cuando_ret)
END IF
LET rm_cia.c00_estado     = 'A'
LET rm_cia.c00_react_mes  = 'S'
LET rm_cia.c00_valmin_mb  = 0
LET rm_cia.c00_valmin_ma  = 0
CLEAR tit_descripcion
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	INSERT INTO ordt000 VALUES (rm_cia.*)
	LET vm_num_rows = vm_num_rows + 1
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_cia.c00_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM ordt000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_cia.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE ordt000 SET c00_compania = rm_cia.c00_compania,
			   c00_cuando_ret = rm_cia.c00_cuando_ret,
			   c00_valmin_mb = rm_cia.c00_valmin_mb,
			   c00_valmin_ma = rm_cia.c00_valmin_ma,
			   c00_dias_react = rm_cia.c00_dias_react,
			   c00_react_mes = rm_cia.c00_react_mes
			WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
COMMIT WORK
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ordt000.c00_compania
DEFINE nom_aux		LIKE gent001.g01_razonsocial
DEFINE query		CHAR(400)
DEFINE expr_sql		CHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE cod_aux TO NULL
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON c00_compania, c00_cuando_ret, 
 	c00_valmin_mb, c00_valmin_ma, c00_dias_react, c00_react_mes
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(c00_compania) THEN
			CALL fl_ayuda_companias_compras()
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO c00_compania 
				DISPLAY nom_aux TO tit_descripcion 
			END IF 
	END IF
	AFTER FIELD c00_cuando_ret
		LET rm_cia.c00_cuando_ret = get_fldbuf(c00_cuando_ret)
		IF vg_gui = 0 THEN
			IF rm_cia.c00_cuando_ret IS NOT NULL THEN
				CALL muestra_cuandoret(rm_cia.c00_cuando_ret)
			ELSE
				CLEAR tit_cuando_ret
			END IF
		END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM ordt000 ' ||
		' WHERE ' || expr_sql CLIPPED ||
		' ORDER BY 1'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_cia.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos (flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE r_ord		RECORD LIKE ordt000.*
DEFINE cod_aux		LIKE ordt000.c00_compania
DEFINE nom_aux		LIKE gent001.g01_razonsocial

LET int_flag = 0
INITIALIZE r_ord.* TO NULL
INITIALIZE cod_aux TO NULL
DISPLAY BY NAME rm_cia.c00_valmin_mb, rm_cia.c00_valmin_ma
INPUT BY NAME rm_cia.c00_compania, rm_cia.c00_cuando_ret,
	rm_cia.c00_valmin_mb, rm_cia.c00_valmin_ma,
	rm_cia.c00_dias_react, rm_cia.c00_react_mes
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_cia.c00_compania, rm_cia.c00_cuando_ret,
			rm_cia.c00_valmin_mb, rm_cia.c00_valmin_ma,
			rm_cia.c00_dias_react, rm_cia.c00_react_mes)
	        THEN
        	       	LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
	                	RETURNING resp
        	      	IF resp = 'Yes' THEN
				LET int_flag = 1
                       		CLEAR FORM
	                       	RETURN
        	        END IF
		ELSE
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(c00_compania) THEN
			CALL fl_ayuda_compania() RETURNING cod_aux
			CALL fl_lee_compania(cod_aux) RETURNING rg_cia.* 
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cia.c00_compania = cod_aux
				DISPLAY cod_aux TO c00_compania 
				DISPLAY rg_cia.g01_razonsocial
					TO tit_descripcion 
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD c00_compania
		IF flag_mant = 'M' THEN 
			NEXT FIELD NEXT
		END IF
 	AFTER FIELD c00_compania
                IF rm_cia.c00_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_cia.c00_compania)
				RETURNING rg_cia.*
                        IF rg_cia.g01_compania IS NULL THEN
                                --CALL fgl_winmessage(vg_producto,'Compa��a no existe','exclamation')
				CALL fl_mostrar_mensaje('Compa��a no existe.','exclamation')
                                NEXT FIELD c00_compania
                        END IF
			DISPLAY rg_cia.g01_razonsocial TO tit_descripcion
			IF rg_cia.g01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD c00_compania
			END IF
			CALL fl_lee_compania_orden_compra(rm_cia.c00_compania)
				RETURNING r_ord.*
			IF rm_cia.c00_compania = r_ord.c00_compania THEN
				--CALL fgl_winmessage(vg_producto,'C�digo de comapa��a ya existe','exclamation')
				CALL fl_mostrar_mensaje('C�digo de comapa��a ya existe.','exclamation')
				NEXT FIELD c00_compania
                        END IF
                ELSE
			CLEAR tit_descripcion
                END IF
	AFTER FIELD c00_valmin_mb
		IF rm_cia.c00_valmin_mb IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base,
 							rm_cia.c00_valmin_mb)
				RETURNING rm_cia.c00_valmin_mb
			DISPLAY BY NAME rm_cia.c00_valmin_mb
		END IF

	BEFORE FIELD c00_valmin_ma
		IF rg_gen.g00_moneda_alt IS NULL THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD c00_valmin_ma
		IF rm_cia.c00_valmin_ma IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rg_gen.g00_moneda_alt,
 							rm_cia.c00_valmin_ma)
				RETURNING rm_cia.c00_valmin_ma
			DISPLAY BY NAME rm_cia.c00_valmin_ma
		END IF
	AFTER FIELD c00_cuando_ret
		IF vg_gui = 0 THEN
			IF rm_cia.c00_cuando_ret IS NOT NULL THEN
				CALL muestra_cuandoret(rm_cia.c00_cuando_ret)
			ELSE
				CLEAR tit_cuando_ret
			END IF
		END IF
END INPUT

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
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_cia.* FROM ordt000 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		--CALL fgl_winmessage(vg_producto,'No existe registro con �ndice: ' || vm_row_current,'exclamation')
		CALL fl_mostrar_mensaje('No existe registro con �ndice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_cia.c00_compania,
			rm_cia.c00_cuando_ret,
			rm_cia.c00_valmin_mb,
			rm_cia.c00_valmin_ma,
			rm_cia.c00_dias_react,
			rm_cia.c00_react_mes
	CALL fl_lee_compania(rm_cia.c00_compania) RETURNING rg_cia.*
	DISPLAY rg_cia.g01_razonsocial TO tit_descripcion
	CALL muestra_estado()
	IF vg_gui = 0 THEN
		CALL muestra_cuandoret(rm_cia.c00_cuando_ret)
	END IF
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM ordt000
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_cia.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
CAll fl_mensaje_seguro_ejecutar_proceso()
RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_cia.c00_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_cia
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_cia
	LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE ordt000 SET c00_estado = estado WHERE CURRENT OF q_ba
LET rm_cia.c00_estado = estado

END FUNCTION



FUNCTION muestra_estado()
IF rm_cia.c00_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_cia
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_cia
END IF
DISPLAY rm_cia.c00_estado TO tit_est

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



FUNCTION muestra_cuandoret(cuandoret)
DEFINE cuandoret	CHAR(1)

CASE cuandoret
	WHEN 'C'
		DISPLAY 'COMPRA' TO tit_cuando_ret
	WHEN 'P'
		DISPLAY 'PAGO' TO tit_cuando_ret
	OTHERWISE
		CLEAR c00_cuando_ret, tit_cuando_ret
END CASE

END FUNCTION
