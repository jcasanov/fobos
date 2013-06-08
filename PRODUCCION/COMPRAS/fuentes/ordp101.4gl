--------------------------------------------------------------------------------
-- Titulo           : ordp101.4gl - Mantenimiento de Tipos Ordenes de Compras
-- Elaboracion      : 13-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ordp101 base módulo commpañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_c01		RECORD LIKE ordt001.*
DEFINE rm_s24		RECORD LIKE srit024.*
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER
DEFINE rm_sust		ARRAY [50] OF RECORD
				s23_secuencia	LIKE srit023.s23_secuencia,
				s23_sustento_sri LIKE srit023.s23_sustento_sri,
				s06_descripcion	LIKE srit006.s06_descripcion,
				s23_aux_cont	LIKE srit023.s23_aux_cont,
				b10_descripcion	LIKE ctbt010.b10_descripcion,
				s23_tributa	LIKE srit023.s23_tributa
			END RECORD
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE quitar_ice	SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp101.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ordp101'
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
LET vm_max_det  = 50
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
OPEN WINDOW w_ordf101_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_ordf101_1 FROM "../forms/ordf101_1"
ELSE
	OPEN FORM f_ordf101_1 FROM "../forms/ordf101_1c"
END IF
DISPLAY FORM f_ordf101_1
INITIALIZE rm_c01.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Sustento SRI'
		HIDE OPTION 'Configuracion ICE'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Sustento SRI'
			SHOW OPTION 'Configuracion ICE'
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
			SHOW OPTION 'Sustento SRI'
			SHOW OPTION 'Configuracion ICE'
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Sustento SRI'
				HIDE OPTION 'Configuracion ICE'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Sustento SRI'
			SHOW OPTION 'Configuracion ICE'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('X') 'Sustento SRI' 'Control de sustento SRI. '
		CALL control_sustento(1)
	COMMAND KEY('Y') 'Configuracion ICE' 'Control de configuracion ICE. '
		CALL control_ice()
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER

CALL fl_retorna_usuario()
INITIALIZE rm_c01.* TO NULL
CLEAR tit_modulo, tit_aux_cont, tit_ot_proc, tit_ot_cost, tit_ot_vta,
	tit_ot_dvta
LET rm_c01.c01_gendia_auto = 'N'
LET rm_c01.c01_ing_bodega  = 'N'
LET rm_c01.c01_bien_serv   = 'B'
IF vg_gui = 0 THEN
	CALL muestra_bienserv(rm_c01.c01_bien_serv)
END IF
LET rm_c01.c01_estado      = 'A'
LET rm_c01.c01_porc_retf_b = 0
LET rm_c01.c01_porc_retf_s = 0
LET rm_c01.c01_porc_reti_b = 0
LET rm_c01.c01_porc_reti_s = 0
LET rm_c01.c01_usuario     = vg_usuario
LET rm_c01.c01_fecing      = CURRENT
CALL muestra_estado()
IF NOT ingreso_datos() THEN
	RETURN
END IF
LET rm_c01.c01_fecing     = CURRENT
LET rm_c01.c01_tipo_orden = 0
BEGIN WORK
	INSERT INTO ordt001 VALUES (rm_c01.*)
	LET rm_c01.c01_tipo_orden = SQLCA.SQLERRD[2]
	LET num_aux               = SQLCA.SQLERRD[6]
	CALL grabar_sustento()
	IF int_flag THEN
		ROLLBACK WORK
		CALL mostrar_salir()
		RETURN
	END IF
COMMIT WORK
LET vm_num_rows    = vm_num_rows + 1
LET vm_row_current = vm_num_rows
DISPLAY BY NAME rm_c01.c01_fecing, rm_c01.c01_tipo_orden
LET vm_r_rows[vm_row_current] = num_aux
CALL mostrar_registro(vm_r_rows[vm_num_rows])	
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
IF rm_c01.c01_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_up CURSOR FOR
		SELECT * FROM ordt001
			WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_up
	FETCH q_up INTO rm_c01.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	IF NOT ingreso_datos() THEN
		ROLLBACK WORK
		RETURN
	END IF
	UPDATE ordt001 SET * = rm_c01.* WHERE CURRENT OF q_up
	CALL grabar_sustento()
COMMIT WORK
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE ordt001.c01_tipo_orden
DEFINE nom_aux		LIKE ordt001.c01_nombre
DEFINE mcod_aux		LIKE gent050.g50_modulo
DEFINE mnom_aux		LIKE gent050.g50_nombre
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE query		CHAR(1200)
DEFINE expr_sql		CHAR(800)
DEFINE num_reg		INTEGER

LET int_flag = 0
INITIALIZE cod_aux, mcod_aux TO NULL
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON c01_estado, c01_tipo_orden, c01_nombre,
	c01_ing_bodega, c01_bien_serv, c01_gendia_auto, c01_modulo,
	c01_porc_retf_b, c01_porc_retf_s, c01_porc_reti_b, c01_porc_reti_s,
	c01_aux_cont, c01_aux_ot_proc, c01_aux_ot_cost, c01_aux_ot_vta,
	c01_aux_ot_dvta, c01_usuario, c01_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(c01_tipo_orden) THEN
			CALL fl_ayuda_tipos_ordenes_compras('T')
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO c01_tipo_orden 
				DISPLAY nom_aux TO c01_nombre
			END IF 
		END IF
		IF INFIELD(c01_modulo) THEN
			CALL fl_ayuda_modulos()
				RETURNING mcod_aux, mnom_aux
			LET int_flag = 0
			IF mcod_aux IS NOT NULL THEN
				DISPLAY mcod_aux TO c01_modulo 
				DISPLAY mnom_aux TO tit_modulo
			END IF 
		END IF
		IF INFIELD(c01_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_cont = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_cont
				DISPLAY r_b10.b10_descripcion TO tit_aux_cont
			END IF
		END IF
		IF INFIELD(c01_aux_ot_proc) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_proc = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_proc
				DISPLAY r_b10.b10_descripcion TO tit_ot_proc
			END IF
		END IF
		IF INFIELD(c01_aux_ot_cost) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_cost = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_cost
				DISPLAY r_b10.b10_descripcion TO tit_ot_cost
			END IF
		END IF
		IF INFIELD(c01_aux_ot_vta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_vta = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_vta
				DISPLAY r_b10.b10_descripcion TO tit_ot_vta
			END IF
		END IF
		IF INFIELD(c01_aux_ot_dvta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_dvta = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_dvta
				DISPLAY r_b10.b10_descripcion TO tit_ot_dvta
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD c01_bien_serv
		LET rm_c01.c01_bien_serv = GET_FLDBUF(c01_bien_serv)
		IF vg_gui = 0 THEN
			IF rm_c01.c01_bien_serv IS NOT NULL THEN
				CALL muestra_bienserv(rm_c01.c01_bien_serv)
			ELSE
				CLEAR tit_bien_serv
			END IF
		END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	CALL mostrar_salir()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM ordt001 ',
		' WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_c01.*, num_reg
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
	RETURN
END IF
LET vm_row_current = 1
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_s06		RECORD LIKE srit006.*
DEFINE mcod_aux		LIKE gent050.g50_modulo
DEFINE mnom_aux		LIKE gent050.g50_nombre

INITIALIZE mcod_aux TO NULL
DISPLAY BY NAME rm_c01.c01_ing_bodega,  rm_c01.c01_bien_serv,
		rm_c01.c01_tipo_orden,  rm_c01.c01_gendia_auto, 
		rm_c01.c01_porc_retf_b, rm_c01.c01_porc_retf_s, 	
		rm_c01.c01_porc_reti_b, rm_c01.c01_porc_reti_s, 
		rm_c01.c01_usuario, 	rm_c01.c01_fecing
LET int_flag = 0
INPUT BY NAME rm_c01.c01_nombre, rm_c01.c01_ing_bodega,  rm_c01.c01_bien_serv,
	rm_c01.c01_gendia_auto,  rm_c01.c01_modulo,      rm_c01.c01_porc_retf_b,
        rm_c01.c01_porc_retf_s,  rm_c01.c01_porc_reti_b, rm_c01.c01_porc_reti_s,
	rm_c01.c01_aux_cont,     rm_c01.c01_aux_ot_proc, rm_c01.c01_aux_ot_cost,
	rm_c01.c01_aux_ot_vta,   rm_c01.c01_aux_ot_dvta
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_c01.c01_nombre, rm_c01.c01_ing_bodega,
				 rm_c01.c01_bien_serv, rm_c01.c01_gendia_auto, 
				 rm_c01.c01_modulo,  rm_c01.c01_porc_retf_b,
				 rm_c01.c01_porc_retf_s, rm_c01.c01_porc_reti_b,
				 rm_c01.c01_porc_reti_s, rm_c01.c01_aux_cont,
				 rm_c01.c01_aux_ot_proc, rm_c01.c01_aux_ot_cost,
				 rm_c01.c01_aux_ot_vta,  rm_c01.c01_aux_ot_dvta)
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
		IF INFIELD(c01_modulo) THEN
			CALL fl_ayuda_modulos()
				RETURNING mcod_aux, mnom_aux
			LET int_flag = 0
			IF mcod_aux IS NOT NULL THEN
				LET rm_c01.c01_modulo = mcod_aux
				DISPLAY BY NAME rm_c01.c01_modulo 
				DISPLAY mnom_aux TO tit_modulo
			END IF 
		END IF
		IF INFIELD(c01_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_cont = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_cont
				DISPLAY r_b10.b10_descripcion TO tit_aux_cont
			END IF
		END IF
		IF INFIELD(c01_aux_ot_proc) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_proc = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_proc
				DISPLAY r_b10.b10_descripcion TO tit_ot_proc
			END IF
		END IF
		IF INFIELD(c01_aux_ot_cost) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_cost = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_cost
				DISPLAY r_b10.b10_descripcion TO tit_ot_cost
			END IF
		END IF
		IF INFIELD(c01_aux_ot_vta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_vta = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_vta
				DISPLAY r_b10.b10_descripcion TO tit_ot_vta
			END IF
		END IF
		IF INFIELD(c01_aux_ot_dvta) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			LET int_flag = 0
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_c01.c01_aux_ot_dvta = r_b10.b10_cuenta
				DISPLAY BY NAME rm_c01.c01_aux_ot_dvta
				DISPLAY r_b10.b10_descripcion TO tit_ot_dvta
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD c01_modulo 
		IF rm_c01.c01_modulo IS NOT NULL THEN
			CALL fl_lee_modulo(rm_c01.c01_modulo)
				RETURNING rg_mod.*
			IF rg_mod.g50_modulo IS NULL  THEN
				--CALL fgl_winmessage(vg_producto,'Módulo no existe','exclamation')
				CALL fl_mostrar_mensaje('Módulo no existe.','exclamation')
				NEXT FIELD c01_modulo
			ELSE
				DISPLAY rg_mod.g50_nombre TO tit_modulo
			END IF
		ELSE
			CLEAR tit_modulo
		END IF
	AFTER FIELD c01_bien_serv
		IF vg_gui = 0 THEN
			IF rm_c01.c01_bien_serv IS NOT NULL THEN
				CALL muestra_bienserv(rm_c01.c01_bien_serv)
			ELSE
				CLEAR tit_bien_serv
			END IF
		END IF
	AFTER FIELD c01_aux_cont
                IF rm_c01.c01_aux_cont IS NOT NULL THEN
			CALL validar_cuenta(rm_c01.c01_aux_cont, 0, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD c01_aux_cont
			END IF
		ELSE
			CLEAR tit_aux_cont
                END IF
	AFTER FIELD c01_aux_ot_proc
                IF rm_c01.c01_aux_ot_proc IS NOT NULL THEN
			CALL validar_cuenta(rm_c01.c01_aux_ot_proc, 0, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD c01_aux_ot_proc
			END IF
		ELSE
			CLEAR tit_ot_proc
                END IF
	AFTER FIELD c01_aux_ot_cost
                IF rm_c01.c01_aux_ot_cost IS NOT NULL THEN
			CALL validar_cuenta(rm_c01.c01_aux_ot_cost, 0, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD c01_aux_ot_cost
			END IF
		ELSE
			CLEAR tit_ot_cost
                END IF
	AFTER FIELD c01_aux_ot_vta
                IF rm_c01.c01_aux_ot_vta IS NOT NULL THEN
			CALL validar_cuenta(rm_c01.c01_aux_ot_vta, 0, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD c01_aux_ot_vta
			END IF
		ELSE
			CLEAR tit_ot_vta
                END IF
	AFTER FIELD c01_aux_ot_dvta
                IF rm_c01.c01_aux_ot_dvta IS NOT NULL THEN
			CALL validar_cuenta(rm_c01.c01_aux_ot_dvta, 0, 5)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD c01_aux_ot_dvta
			END IF
		ELSE
			CLEAR tit_ot_dvta
                END IF
	AFTER INPUT
		IF rm_c01.c01_bien_serv <> 'B' THEN
			LET rm_c01.c01_ing_bodega = 'N'
			DISPLAY BY NAME rm_c01.c01_ing_bodega
		END IF
		IF rm_c01.c01_bien_serv = 'B' THEN
			LET rm_c01.c01_porc_retf_s = 0
			LET rm_c01.c01_porc_reti_s = 0
		END IF
		IF rm_c01.c01_bien_serv = 'S' THEN
			LET rm_c01.c01_porc_retf_b = 0
			LET rm_c01.c01_porc_reti_b = 0
		END IF
		DISPLAY BY NAME rm_c01.c01_porc_retf_b, rm_c01.c01_porc_retf_s,
				rm_c01.c01_porc_reti_b, rm_c01.c01_porc_reti_s
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont, i, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE i, flag		SMALLINT
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY r_cta.b10_descripcion TO tit_aux_cont
	WHEN 2
		DISPLAY r_cta.b10_descripcion TO tit_ot_proc
	WHEN 3
		DISPLAY r_cta.b10_descripcion TO tit_ot_cost
	WHEN 4
		DISPLAY r_cta.b10_descripcion TO tit_ot_vta
	WHEN 5
		DISPLAY r_cta.b10_descripcion TO tit_ot_dvta
	WHEN 6
		LET rm_sust[i].b10_descripcion = r_cta.b10_descripcion
	WHEN 7
		DISPLAY BY NAME r_cta.b10_descripcion
END CASE
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del ultimo.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION ingreso_datos()

CALL leer_datos()
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 0
END IF
CALL control_sustento(0)
IF int_flag THEN
	CALL mostrar_salir()
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION mostrar_salir()

CLEAR FORM
IF vm_row_current > 0 THEN
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

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
DEFINE nrow             SMALLINT

LET nrow = 20
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_cta            RECORD LIKE ctbt010.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_c01.* FROM ordt001 WHERE ROWID=num_registro	
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_c01.c01_tipo_orden, rm_c01.c01_nombre, rm_c01.c01_ing_bodega,
		rm_c01.c01_bien_serv, rm_c01.c01_gendia_auto, rm_c01.c01_modulo,
		rm_c01.c01_porc_retf_b, rm_c01.c01_porc_retf_s,
		rm_c01.c01_porc_reti_b, rm_c01.c01_porc_reti_s,
		rm_c01.c01_aux_cont, rm_c01.c01_aux_ot_proc,
		rm_c01.c01_aux_ot_cost, rm_c01.c01_aux_ot_vta,
		rm_c01.c01_aux_ot_dvta, rm_c01.c01_usuario, rm_c01.c01_fecing
CALL fl_lee_modulo(rm_c01.c01_modulo) RETURNING rg_mod.*
DISPLAY rg_mod.g50_nombre TO tit_modulo
CALL fl_lee_cuenta(vg_codcia, rm_c01.c01_aux_cont) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_aux_cont
CALL fl_lee_cuenta(vg_codcia, rm_c01.c01_aux_ot_proc) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_ot_proc
CALL fl_lee_cuenta(vg_codcia, rm_c01.c01_aux_ot_cost) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_ot_cost
CALL fl_lee_cuenta(vg_codcia, rm_c01.c01_aux_ot_vta) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_ot_vta
CALL fl_lee_cuenta(vg_codcia, rm_c01.c01_aux_ot_dvta) RETURNING r_cta.*
DISPLAY r_cta.b10_descripcion TO tit_ot_dvta
CALL muestra_estado()
IF vg_gui = 0 THEN
	CALL muestra_bienserv(rm_c01.c01_bien_serv)
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_ba CURSOR FOR
		SELECT * FROM ordt001
			WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_ba
	FETCH q_ba INTO rm_c01.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF	
	WHENEVER ERROR STOP
	LET int_flag = 0
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
	IF confir <> 'Yes' THEN
		ROLLBACK WORK
		RETURN
	END IF
	CALL bloquea_activa_registro()
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mostrar_mensaje('Registro ha sido bloqueado.', 'info')

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		LIKE ordt001.c01_estado

CASE rm_c01.c01_estado
	WHEN 'A'
		LET estado = 'B'
	WHEN 'B'
		LET estado = 'A'
END CASE
UPDATE ordt001 SET c01_estado = estado WHERE CURRENT OF q_ba
LET rm_c01.c01_estado = estado
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()

DISPLAY BY NAME rm_c01.c01_estado
IF rm_c01.c01_estado = 'A' THEN
	DISPLAY 'ACTIVO'    TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF

END FUNCTION



FUNCTION control_sustento(flag)
DEFINE flag		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 5
LET num_rows = 18
LET num_cols = 79
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_ordf101_2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_ordf101_2 FROM "../forms/ordf101_2"
ELSE
	OPEN FORM f_ordf101_2 FROM "../forms/ordf101_2c"
END IF
DISPLAY FORM f_ordf101_2
CALL botones_sustento()
CALL borrar_detalle_sustento()
CALL cargar_detalle_sustento()
CALL leer_detalle_sustento()
IF flag THEN
	IF NOT int_flag THEN
		BEGIN WORK
			CALL grabar_sustento()
		COMMIT WORK
		CALL fl_mostrar_mensaje('Sustentos actualizados para este tipo de orden de compra.', 'info')
	END IF
END IF
CLOSE WINDOW w_ordf101_2
RETURN

END FUNCTION



FUNCTION botones_sustento()

DISPLAY "Sec."		TO tit_col1
DISPLAY "Sust."		TO tit_col2
DISPLAY "Descripcion"	TO tit_col3
DISPLAY "Cuenta"	TO tit_col4
DISPLAY "Nombre Cuenta"	TO tit_col5
DISPLAY "T"		TO tit_col6

END FUNCTION



FUNCTION borrar_detalle_sustento()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_det
	INITIALIZE rm_sust[i].* TO NULL
END FOR
FOR i = 1 TO fgl_scr_size("rm_sust")
	CLEAR rm_sust[i].*
END FOR
CLEAR sustento_sri, tit_sustento_sri, tipo_orden, descripcion, num_row, max_row,
	s23_usuario, s23_fecing

END FUNCTION



FUNCTION cargar_detalle_sustento()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_s06		RECORD LIKE srit006.*
DEFINE r_s23		RECORD LIKE srit023.*

DECLARE q_s23 CURSOR FOR
	SELECT * FROM srit023
		WHERE s23_compania   = vg_codcia
		  AND s23_tipo_orden = rm_c01.c01_tipo_orden
		ORDER BY s23_secuencia
LET vm_num_det = 1
FOREACH q_s23 INTO r_s23.*
	INITIALIZE r_s06.* TO NULL
	SELECT * INTO r_s06.*
		FROM srit006
		WHERE s06_compania = vg_codcia
		  AND s06_codigo   = r_s23.s23_sustento_sri
	CALL fl_lee_cuenta(vg_codcia, r_s23.s23_aux_cont) RETURNING r_b10.*
	LET rm_sust[vm_num_det].s23_secuencia    = r_s23.s23_secuencia
	LET rm_sust[vm_num_det].s23_sustento_sri = r_s23.s23_sustento_sri
	LET rm_sust[vm_num_det].s06_descripcion  = r_s06.s06_descripcion
	LET rm_sust[vm_num_det].s23_aux_cont     = r_s23.s23_aux_cont
	LET rm_sust[vm_num_det].b10_descripcion  = r_b10.b10_descripcion
	LET rm_sust[vm_num_det].s23_tributa      = r_s23.s23_tributa
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det > 0 THEN
	CALL mostrar_detalle_sustento()
END IF

END FUNCTION



FUNCTION leer_detalle_sustento()
DEFINE resp		CHAR(6)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_s06		RECORD LIKE srit006.*
DEFINE i, j, resul	SMALLINT

IF vm_num_det = 0 THEN
	LET vm_num_det = 1
END IF
LET int_flag = 0
CALL set_count(vm_num_det)
INPUT ARRAY rm_sust WITHOUT DEFAULTS FROM rm_sust.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(s23_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_sust[i].s23_aux_cont   = r_b10.b10_cuenta
				LET rm_sust[i].b10_descripcion=
							r_b10.b10_descripcion
				DISPLAY rm_sust[i].s23_aux_cont TO
					rm_sust[j].s23_aux_cont
				DISPLAY rm_sust[i].b10_descripcion TO
					rm_sust[j].b10_descripcion
			END IF
		END IF
		IF INFIELD(s23_sustento_sri) THEN
			CALL fl_ayuda_sustentos_sri(vg_codcia)
				RETURNING r_s06.s06_codigo,r_s06.s06_descripcion
			IF r_s06.s06_codigo IS NOT NULL THEN
				LET rm_sust[i].s23_sustento_sri =
							r_s06.s06_codigo
				LET rm_sust[i].s06_descripcion  =
							r_s06.s06_descripcion
				DISPLAY rm_sust[i].s23_sustento_sri TO
					rm_sust[j].s23_sustento_sri
				DISPLAY rm_sust[i].s06_descripcion TO
					rm_sust[j].s06_descripcion
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE ROW
		LET i          = arr_curr()
		LET j          = scr_line()
		LET vm_num_det = arr_count()
		IF i > vm_num_det THEN
			LET vm_num_det = vm_num_det + 1
		END IF
		CALL mostrar_linea_detalle_sustento(i, j)
	AFTER FIELD s23_sustento_sri
		IF rm_sust[i].s23_sustento_sri IS NOT NULL THEN
			IF NOT valido_sustento_sri(i, j) THEN
				NEXT FIELD s23_sustento_sri
			END IF
			CALL mostrar_linea_detalle_sustento(i, j)
		END IF
	AFTER FIELD s23_aux_cont
                IF rm_sust[i].s23_aux_cont IS NOT NULL THEN
			CALL validar_cuenta(rm_sust[i].s23_aux_cont, i, 6)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD s23_aux_cont
			END IF
			CALL mostrar_linea_detalle_sustento(i, j)
		ELSE
			LET rm_sust[i].b10_descripcion = NULL
			DISPLAY rm_sust[i].b10_descripcion TO
				rm_sust[j].b10_descripcion
                END IF
	AFTER INPUT
		LET vm_num_det = arr_count()
		IF vm_num_det = 0 THEN
			CONTINUE INPUT
		END IF
		IF NOT valido_codigos_repetidos() THEN
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION grabar_sustento()
DEFINE i		SMALLINT

DELETE FROM srit023
	WHERE s23_compania   = vg_codcia
	  AND s23_tipo_orden = rm_c01.c01_tipo_orden
FOR i = 1 TO vm_num_det
	INSERT INTO srit023
		VALUES(vg_codcia, rm_c01.c01_tipo_orden,
			rm_sust[i].s23_sustento_sri, rm_sust[i].s23_secuencia,
			rm_sust[i].s23_aux_cont, rm_sust[i].s23_tributa,
			vg_usuario, CURRENT)
END FOR

END FUNCTION



FUNCTION valido_sustento_sri(i, j)
DEFINE i, j		SMALLINT
DEFINE r_s06		RECORD LIKE srit006.*

INITIALIZE r_s06.* TO NULL
SELECT * INTO r_s06.*
	FROM srit006
	WHERE s06_compania = vg_codcia
	  AND s06_codigo   = rm_sust[i].s23_sustento_sri
IF r_s06.s06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Este codigo de sustento no existe.', 'exclamation')
	RETURN 0
END IF
{
CASE r_s06.s06_tributa
	WHEN 'S'
		IF rm_c01.c01_aux_cont IS NULL THEN
			CALL fl_mostrar_mensaje('El codigo de sustento tiene credito tributario. Debe tener un auxiliar contable para IVA este tipo de orden.', 'exclamation')
			RETURN 0
		END IF
	WHEN 'N'
		IF rm_c01.c01_aux_cont IS NOT NULL THEN
			CALL fl_mostrar_mensaje('El codigo de sustento NO tiene credito tributario. No debe tener auxiliar contable para IVA el tipo de orden.', 'exclamation')
			RETURN 0
		END IF
END CASE
}
LET rm_sust[i].s23_sustento_sri = r_s06.s06_codigo
LET rm_sust[i].s06_descripcion  = r_s06.s06_descripcion
LET rm_sust[i].s23_tributa      = r_s06.s06_tributa
CALL mostrar_linea_detalle_sustento(i, j)
RETURN 1

END FUNCTION



FUNCTION valido_codigos_repetidos()
DEFINE i, j, c_s, c_n	SMALLINT
DEFINE resul		SMALLINT

LET resul = 1
FOR i = 1 TO vm_num_det - 1
	FOR j = i + 1 TO vm_num_det
		IF rm_sust[i].s23_sustento_sri = rm_sust[j].s23_sustento_sri
		THEN
			CALL fl_mostrar_mensaje('El codigo ' || rm_sust[i].s23_sustento_sri || ' esta repetido una o mas veces. Por favor corrijalo.', 'exclamation')
			LET resul = 0
			EXIT FOR
		END IF
	END FOR
	IF NOT resul THEN
		EXIT FOR
	END IF
END FOR
LET c_s = 0
LET c_n = 0
FOR i = 1 TO vm_num_det
	IF rm_sust[i].s23_tributa = 'S' THEN
		LET c_s = c_s + 1
	END IF
	IF rm_sust[i].s23_tributa = 'N' THEN
		LET c_n = c_n + 1
	END IF
END FOR
IF (c_s > 1) OR (c_n > 1) THEN
	CALL fl_mostrar_mensaje('Solamente puede ingresar un solo codigo de sustento sujeto de credito y/o NO sujeto de credito. Por favor corrijalo.', 'exclamation')
	LET resul = 0
END IF
RETURN resul

END FUNCTION



FUNCTION mostrar_linea_detalle_sustento(i, j)
DEFINE i, j		SMALLINT

LET rm_sust[i].s23_secuencia = i
DISPLAY rm_sust[i].* TO rm_sust[j].*
CALL mostrar_etiquetas(i)

END FUNCTION



FUNCTION mostrar_detalle_sustento()
DEFINE i, lim		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_sust')
	CLEAR rm_sust[i].*
END FOR
LET lim = vm_num_det
IF lim > fgl_scr_size('rm_sust') THEN
	LET lim = fgl_scr_size('rm_sust')
END IF
FOR i = 1 TO lim
	DISPLAY rm_sust[i].* TO rm_sust[i].*
END FOR
CALL mostrar_etiquetas(1)

END FUNCTION



FUNCTION mostrar_etiquetas(i)
DEFINE i		SMALLINT
DEFINE r_s23		RECORD LIKE srit023.*

DISPLAY rm_sust[i].s23_sustento_sri TO sustento_sri
DISPLAY rm_sust[i].s06_descripcion  TO tit_sustento_sri
DISPLAY rm_c01.c01_tipo_orden       TO tipo_orden
DISPLAY rm_c01.c01_nombre           TO descripcion
INITIALIZE r_s23.* TO NULL
SELECT * INTO r_s23.*
	FROM srit023
	WHERE s23_compania     = vg_codcia
	  AND s23_tipo_orden   = rm_c01.c01_tipo_orden
	  AND s23_sustento_sri = rm_sust[i].s23_sustento_sri
	  AND s23_secuencia    = rm_sust[i].s23_secuencia
IF r_s23.s23_usuario IS NULL THEN
	LET r_s23.s23_usuario = vg_usuario
	LET r_s23.s23_fecing  = CURRENT
END IF
DISPLAY BY NAME r_s23.s23_usuario, r_s23.s23_fecing
CALL muestra_contadores_sust(i, vm_num_det)

END FUNCTION



FUNCTION muestra_contadores_sust(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_ice()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE palabra		VARCHAR(10)
DEFINE r_b10		RECORD LIKE ctbt010.*

LET lin_menu = 0
LET row_ini  = 6
LET num_rows = 15
LET num_cols = 79
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 5
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_ordf101_3 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_ordf101_3 FROM "../forms/ordf101_3"
ELSE
	OPEN FORM f_ordf101_3 FROM "../forms/ordf101_3c"
END IF
DISPLAY FORM f_ordf101_3
CLEAR FORM
INITIALIZE rm_s24.* TO NULL
DECLARE q_s24 CURSOR FOR
	SELECT * FROM srit024
		WHERE s24_compania   = vg_codcia
		  AND s24_tipo_orden = rm_c01.c01_tipo_orden
OPEN q_s24
FETCH q_s24 INTO rm_s24.*
CLOSE q_s24
FREE q_s24
IF rm_s24.s24_compania IS NOT NULL THEN
	CALL setear_porc_ice(rm_s24.s24_compania, rm_s24.s24_codigo,
			rm_s24.s24_porcentaje_ice, rm_s24.s24_codigo_impto)
	CALL fl_lee_cuenta(vg_codcia, rm_s24.s24_aux_cont) RETURNING r_b10.*
	DISPLAY BY NAME r_b10.b10_descripcion
ELSE
	LET rm_s24.s24_compania = vg_codcia
	LET rm_s24.s24_usuario  = vg_usuario
	LET rm_s24.s24_fecing   = CURRENT
END IF
LET rm_s24.s24_tipo_orden = rm_c01.c01_tipo_orden
DISPLAY rm_c01.c01_tipo_orden TO tipo_orden
DISPLAY rm_c01.c01_nombre     TO descripcion
DISPLAY BY NAME rm_s24.s24_usuario, rm_s24.s24_fecing
LET quitar_ice = 0
CALL leer_ice()
IF NOT int_flag THEN
	BEGIN WORK
		LET rm_s24.s24_fecing = CURRENT
		DELETE FROM srit024
			WHERE s24_compania       = vg_codcia
			  AND s24_codigo         = rm_s24.s24_codigo
			  AND s24_porcentaje_ice = rm_s24.s24_porcentaje_ice
			  AND s24_codigo_impto   = rm_s24.s24_codigo_impto
			  AND s24_tipo_orden     = rm_c01.c01_tipo_orden
		LET palabra = 'eliminado'
		IF NOT quitar_ice THEN
			INSERT INTO srit024 VALUES(rm_s24.*)
			LET palabra = 'asignado'
		END IF
	COMMIT WORK
	CALL fl_mostrar_mensaje('Porcentaje ICE ' || palabra CLIPPED || ' para este tipo de orden de compra.', 'info')
END IF
CLOSE WINDOW w_ordf101_3
RETURN

END FUNCTION



FUNCTION leer_ice()
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_s10		RECORD LIKE srit010.*
DEFINE cod_aux		LIKE srit010.s10_codigo

LET int_flag = 0
INPUT BY NAME rm_s24.s24_codigo, rm_s24.s24_aux_cont
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_s24.s24_codigo, rm_s24.s24_aux_cont) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
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
		IF INFIELD(s24_codigo) THEN
			CALL fl_ayuda_porc_ice(vg_codcia)
				RETURNING r_s10.s10_codigo,
					r_s10.s10_porcentaje_ice,
					r_s10.s10_codigo_impto
			IF r_s10.s10_codigo IS NOT NULL THEN
				CALL setear_porc_ice(vg_codcia,r_s10.s10_codigo,
						r_s10.s10_porcentaje_ice,
						r_s10.s10_codigo_impto)
			END IF
		END IF
		IF INFIELD(s24_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_s24.s24_aux_cont = r_b10.b10_cuenta
				DISPLAY BY NAME rm_s24.s24_aux_cont,
						r_b10.b10_descripcion
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF rm_s24.s24_codigo IS NOT NULL THEN
			CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET quitar_ice = 1
				LET int_flag   = 0
				EXIT INPUT
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#IF rm_s24.s24_codigo IS NOT NULL THEN
			--#CALL dialog.keysetlabel("F5","Quitar ICE")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","")
		--#END IF
	BEFORE FIELD s24_codigo
		LET cod_aux = rm_s24.s24_codigo
	AFTER FIELD s24_codigo
		IF rm_s24.s24_codigo IS NULL THEN
			LET rm_s24.s24_codigo = cod_aux
			CALL setear_porc_ice(rm_s24.s24_compania,
						rm_s24.s24_codigo,
						rm_s24.s24_porcentaje_ice,
						rm_s24.s24_codigo_impto)
		END IF
		CALL fl_lee_conf_ice(rm_s24.s24_compania, rm_s24.s24_codigo,
					rm_s24.s24_porcentaje_ice,
					rm_s24.s24_codigo_impto)
			RETURNING r_s10.*
		IF r_s10.s10_compania IS NULL THEN
			CALL fl_mostrar_mensaje('Codigo de ICE no existe en la compania.', 'exclamation')
			NEXT FIELD s24_codigo
		END IF
		CALL setear_porc_ice(r_s10.s10_compania,
					r_s10.s10_codigo,
					r_s10.s10_porcentaje_ice,
					r_s10.s10_codigo_impto)
	AFTER FIELD s24_aux_cont
                IF rm_s24.s24_aux_cont IS NOT NULL THEN
			CALL validar_cuenta(rm_s24.s24_aux_cont, 0, 7)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD s24_aux_cont
			END IF
		ELSE
			CLEAR b10_descripcion
                END IF
END INPUT

END FUNCTION



FUNCTION setear_porc_ice(codcia, codigo, porc, codimp)
DEFINE codcia		LIKE srit010.s10_compania
DEFINE codigo		LIKE srit010.s10_codigo
DEFINE porc		LIKE srit010.s10_porcentaje_ice
DEFINE codimp		LIKE srit010.s10_codigo_impto
DEFINE r_s10		RECORD LIKE srit010.*

CALL fl_lee_conf_ice(codcia, codigo, porc, codimp) RETURNING r_s10.*
LET rm_s24.s24_codigo         = r_s10.s10_codigo
LET rm_s24.s24_porcentaje_ice = r_s10.s10_porcentaje_ice
LET rm_s24.s24_codigo_impto   = r_s10.s10_codigo_impto
DISPLAY BY NAME rm_s24.s24_codigo, rm_s24.s24_porcentaje_ice,
		rm_s24.s24_codigo_impto, r_s10.s10_descripcion

END FUNCTION



FUNCTION muestra_bienserv(bienserv)
DEFINE bienserv		CHAR(1)

CASE bienserv
	WHEN 'B'
		DISPLAY 'BIENES' TO tit_bien_serv
	WHEN 'S'
		DISPLAY 'SERVICIOS' TO tit_bien_serv
	WHEN 'T'
		DISPLAY 'BIENES Y SERVICIOS' TO tit_bien_serv
	OTHERWISE
		CLEAR c01_bien_serv, tit_bien_serv
END CASE

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
