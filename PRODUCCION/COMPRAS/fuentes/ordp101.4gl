------------------------------------------------------------------------------
-- Titulo           : ordp101.4gl - Mantenimiento de Tipos Ordenes de Compras
-- Elaboracion      : 13-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ordp101 base módulo commpañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ord		RECORD LIKE ordt001.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp101.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'ordp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 50
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ord FROM "../forms/ordf101_1"
DISPLAY FORM f_ord
INITIALIZE rm_ord.* TO NULL
LET vm_num_rows    = 0
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
INITIALIZE rm_ord.* TO NULL
CLEAR tit_modulo
LET rm_ord.c01_gendia_auto = 'N'
LET rm_ord.c01_ing_bodega  = 'N'
LET rm_ord.c01_bien_serv   = 'B'
LET rm_ord.c01_estado      = 'A'
LET rm_ord.c01_porc_retf_b = 0
LET rm_ord.c01_porc_retf_s = 0
LET rm_ord.c01_porc_reti_b = 0
LET rm_ord.c01_porc_reti_s = 0
LET rm_ord.c01_usuario     = vg_usuario
LET rm_ord.c01_fecing      = CURRENT
CALL muestra_estado()
CALL leer_datos()
IF NOT int_flag THEN
	LET rm_ord.c01_fecing  = CURRENT
	LET rm_ord.c01_tipo_orden = 0
	INSERT INTO ordt001 VALUES (rm_ord.*)
	LET vm_num_rows = vm_num_rows + 1
	LET vm_row_current = vm_num_rows
	LET rm_ord.c01_tipo_orden = SQLCA.SQLERRD[2] 
	DISPLAY BY NAME rm_ord.c01_fecing, rm_ord.c01_tipo_orden
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
IF rm_ord.c01_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM ordt001
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_ord.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos()
IF NOT int_flag THEN
	UPDATE ordt001 SET * = rm_ord.* WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	COMMIT WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
WHENEVER ERROR STOP
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ordt001.c01_tipo_orden
DEFINE nom_aux		LIKE ordt001.c01_nombre
DEFINE mcod_aux		LIKE gent050.g50_modulo
DEFINE mnom_aux		LIKE gent050.g50_nombre
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE cod_aux, mcod_aux TO NULL
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON c01_estado, c01_tipo_orden, c01_nombre, 
				c01_ing_bodega, 
	c01_bien_serv, c01_gendia_auto, c01_modulo, c01_porc_retf_b, 
        c01_porc_retf_s, c01_porc_reti_b, c01_porc_reti_s, c01_usuario   
	ON KEY(F2)
	IF infield(c01_tipo_orden) THEN
		CALL fl_ayuda_tipos_ordenes_compras()
		RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO c01_tipo_orden 
			DISPLAY nom_aux TO c01_nombre
		END IF 
	END IF
	IF infield(c01_modulo) THEN
		CALL fl_ayuda_modulos()
		RETURNING mcod_aux, mnom_aux
		LET int_flag = 0
		IF mcod_aux IS NOT NULL THEN
			DISPLAY mcod_aux TO c01_modulo 
			DISPLAY mnom_aux TO tit_modulo
		END IF 
	END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM ordt001 WHERE ' || expr_sql || ' ORDER BY 1,2'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_ord.*, num_reg
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



FUNCTION leer_datos ()
DEFINE resp		CHAR(6)
DEFINE mcod_aux		LIKE gent050.g50_modulo
DEFINE mnom_aux		LIKE gent050.g50_nombre

INITIALIZE mcod_aux TO NULL
DISPLAY BY NAME rm_ord.c01_ing_bodega,  rm_ord.c01_bien_serv,
		rm_ord.c01_tipo_orden,  rm_ord.c01_gendia_auto, 
		rm_ord.c01_porc_retf_b, rm_ord.c01_porc_retf_s, 	
		rm_ord.c01_porc_reti_b, rm_ord.c01_porc_reti_s, 
		rm_ord.c01_usuario, 	rm_ord.c01_fecing
LET int_flag = 0
INPUT BY NAME rm_ord.c01_nombre, rm_ord.c01_ing_bodega,  rm_ord.c01_bien_serv,
	rm_ord.c01_gendia_auto,  rm_ord.c01_modulo,      rm_ord.c01_porc_retf_b,
        rm_ord.c01_porc_retf_s,  rm_ord.c01_porc_reti_b, rm_ord.c01_porc_reti_s
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        IF field_touched(rm_ord.c01_nombre, rm_ord.c01_ing_bodega,
		rm_ord.c01_bien_serv, rm_ord.c01_gendia_auto, 
		rm_ord.c01_modulo,
		rm_ord.c01_porc_retf_b, rm_ord.c01_porc_retf_s,
		rm_ord.c01_porc_reti_b, rm_ord.c01_porc_reti_s)
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
	ON KEY(F2)
	IF infield(c01_modulo) THEN
		CALL fl_ayuda_modulos()
		RETURNING mcod_aux, mnom_aux
		LET int_flag = 0
		IF mcod_aux IS NOT NULL THEN
			LET rm_ord.c01_modulo = mcod_aux
			DISPLAY BY NAME rm_ord.c01_modulo 
			DISPLAY mnom_aux TO tit_modulo
		END IF 
	END IF
	AFTER FIELD c01_modulo 
		IF rm_ord.c01_modulo IS NOT NULL THEN
			CALL fl_lee_modulo(rm_ord.c01_modulo)
				RETURNING rg_mod.*
			IF rg_mod.g50_modulo IS NULL  THEN
				CALL fgl_winmessage(vg_producto,'Módulo no existe','exclamation')
				NEXT FIELD c01_modulo
			ELSE
				DISPLAY rg_mod.g50_nombre TO tit_modulo
			END IF
		ELSE
			CLEAR tit_modulo
		END IF
	AFTER INPUT
		IF rm_ord.c01_bien_serv <> 'B' THEN
			LET rm_ord.c01_ing_bodega = 'N'
			DISPLAY BY NAME rm_ord.c01_ing_bodega
		END IF
		IF rm_ord.c01_bien_serv = 'B' THEN
			LET rm_ord.c01_porc_retf_s = 0
			LET rm_ord.c01_porc_reti_s = 0
		END IF
		IF rm_ord.c01_bien_serv = 'S' THEN
			LET rm_ord.c01_porc_retf_b = 0
			LET rm_ord.c01_porc_reti_b = 0
		END IF
		DISPLAY BY NAME rm_ord.c01_porc_retf_b, rm_ord.c01_porc_retf_s,
				rm_ord.c01_porc_reti_b, rm_ord.c01_porc_reti_s
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
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_ord.* FROM ordt001 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_ord.c01_tipo_orden, rm_ord.c01_nombre,
			rm_ord.c01_ing_bodega, rm_ord.c01_bien_serv,
			rm_ord.c01_gendia_auto,
			rm_ord.c01_modulo, rm_ord.c01_porc_retf_b,
			rm_ord.c01_porc_retf_s, rm_ord.c01_porc_reti_b,
			rm_ord.c01_porc_reti_s, rm_ord.c01_usuario,
			rm_ord.c01_fecing
	CALL fl_lee_modulo(rm_ord.c01_modulo) RETURNING rg_mod.*
	DISPLAY rg_mod.g50_nombre TO tit_modulo
	CALL muestra_estado()
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
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR SELECT * FROM ordt001
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_ord.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	WHENEVER ERROR STOP
	CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado	CHAR(1)

IF rm_ord.c01_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado
	LET estado = 'A'
END IF
DISPLAY estado TO c01_estado
UPDATE ordt001 SET c01_estado = estado WHERE CURRENT OF q_ba
LET rm_ord.c01_estado = estado

END FUNCTION



FUNCTION muestra_estado()
IF rm_ord.c01_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF
DISPLAY BY NAME rm_ord.c01_estado

END FUNCTION



FUNCTION validar_parametros()

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
