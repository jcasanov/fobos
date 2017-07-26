--------------------------------------------------------------------------------
-- Titulo           : repp242.4gl - Cambio de vendedor
-- Elaboracion      : 09-ene-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp242 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[10000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r98		RECORD LIKE rept098.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp242.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp242'
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
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
LET vm_max_rows = 10000
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 18
LET num_cols    = 80
IF vg_gui = 0 THEN        
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF                  
OPEN WINDOW w_repf242_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf242_1 FROM '../forms/repf242_1'
ELSE
	OPEN FORM f_repf242_1 FROM '../forms/repf242_1c'
END IF
DISPLAY FORM f_repf242_1
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Reversar'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Transaccion'
	COMMAND KEY('I') 'Cambiar Vendedor'	'Procesar nuevos registros.'
                CALL control_proceso()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF rm_r98.r98_estado = 'P' THEN
					SHOW OPTION 'Reversar'
				ELSE
					HIDE OPTION 'Reversar'
				END IF
				IF rm_r98.r98_cod_tran IS NULL THEN
					SHOW OPTION 'Detalle'
					HIDE OPTION 'Transaccion'
				ELSE
					HIDE OPTION 'Detalle'
					SHOW OPTION 'Transaccion'
				END IF
			END IF 
                ELSE
			IF rm_r98.r98_estado = 'P' THEN
				SHOW OPTION 'Reversar'
			ELSE
				HIDE OPTION 'Reversar'
			END IF
			IF rm_r98.r98_cod_tran IS NULL THEN
				SHOW OPTION 'Detalle'
				HIDE OPTION 'Transaccion'
			ELSE
				HIDE OPTION 'Detalle'
				SHOW OPTION 'Transaccion'
			END IF
			SHOW OPTION 'Retroceder'
                END IF
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF rm_r98.r98_estado = 'P' THEN
					SHOW OPTION 'Reversar'
				ELSE
					HIDE OPTION 'Reversar'
				END IF
				IF rm_r98.r98_cod_tran IS NULL THEN
					SHOW OPTION 'Detalle'
					HIDE OPTION 'Transaccion'
				ELSE
					HIDE OPTION 'Detalle'
					SHOW OPTION 'Transaccion'
				END IF
			END IF 
                ELSE
			IF rm_r98.r98_estado = 'P' THEN
				SHOW OPTION 'Reversar'
			ELSE
				HIDE OPTION 'Reversar'
			END IF
			IF rm_r98.r98_cod_tran IS NULL THEN
				SHOW OPTION 'Detalle'
				HIDE OPTION 'Transaccion'
			ELSE
				HIDE OPTION 'Detalle'
				SHOW OPTION 'Transaccion'
			END IF
                        SHOW OPTION 'Avanzar'
                END IF
        COMMAND KEY('X') 'Reversar'	'Reversa cambio de ventas.'
		CALL control_reversar()
		IF rm_r98.r98_estado = 'P' THEN
			SHOW OPTION 'Reversar'
		ELSE
			HIDE OPTION 'Reversar'
		END IF
        COMMAND KEY('D') 'Detalle'	'Muestra Detalle de transacciones.'
		CALL control_detalle()
        COMMAND KEY('T') 'Transaccion'	'Muestra Transaccion.'
		CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
				rm_r98.r98_cod_tran, rm_r98.r98_num_tran)
		LET int_flag = 0
	COMMAND KEY('A') 'Avanzar' 	'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_r98.r98_estado = 'P' THEN
			SHOW OPTION 'Reversar'
		ELSE
			HIDE OPTION 'Reversar'
		END IF
		IF rm_r98.r98_cod_tran IS NULL THEN
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Transaccion'
		ELSE
			HIDE OPTION 'Detalle'
			SHOW OPTION 'Transaccion'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF rm_r98.r98_estado = 'P' THEN
			SHOW OPTION 'Reversar'
		ELSE
			HIDE OPTION 'Reversar'
		END IF
		IF rm_r98.r98_cod_tran IS NULL THEN
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Transaccion'
		ELSE
			HIDE OPTION 'Detalle'
			SHOW OPTION 'Transaccion'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_proceso()
DEFINE num_aux		INTEGER
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(255)
DEFINE r_r01_ant	RECORD LIKE rept001.*
DEFINE r_r01_nue	RECORD LIKE rept001.*

CLEAR FORM
INITIALIZE rm_r98.* TO NULL
LET rm_r98.r98_compania  = vg_codcia
LET rm_r98.r98_localidad = vg_codloc
LET rm_r98.r98_usuario   = vg_usuario
LET rm_r98.r98_fecing    = CURRENT
DISPLAY BY NAME rm_r98.r98_usuario, rm_r98.r98_fecing
CALL lee_parametros()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
CALL fl_hacer_pregunta('Esta seguro de ejecutar este proceso ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 0
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET int_flag = 0
CALL ejecutar_proceso(rm_r98.r98_vend_ant, rm_r98.r98_vend_nue, 'P')
	RETURNING num_aux
IF num_aux < 0 THEN
	RETURN
END IF
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows  = 1
ELSE
	LET vm_num_rows  = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = num_aux
LET vm_row_current       = vm_num_rows
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_lee_vendedor_rep(rm_r98.r98_compania, rm_r98.r98_vend_ant)
	RETURNING r_r01_ant.*
CALL fl_lee_vendedor_rep(rm_r98.r98_compania, rm_r98.r98_vend_nue)
	RETURNING r_r01_nue.*
LET mensaje = 'Se pasaron ventas del vendedor ',
		r_r01_ant.r01_codigo USING "<<<<&", ' ',					r_r01_ant.r01_nombres CLIPPED, ' al vendedor ',
		r_r01_nue.r01_codigo USING "<<<<&", ' ',
		r_r01_nue.r01_nombres CLIPPED, '.'
IF rm_r98.r98_fecha_ini IS NOT NULL THEN
	LET mensaje = mensaje CLIPPED, ' En el período: ',
			rm_r98.r98_fecha_ini USING "dd-mm-yyyy", ' - ',
			rm_r98.r98_fecha_fin USING "dd-mm-yyyy", '.'
END IF
CALL fl_mostrar_mensaje(mensaje, 'info')
CALL fl_hacer_pregunta('Desea ver el detalle de este registro ?', 'Yes')
	RETURNING resp
IF resp = 'Yes' THEN
	CALL control_detalle()
END IF

END FUNCTION



FUNCTION ejecutar_proceso(vend_ant, vend_n, tipo_proc)
DEFINE vend_ant		LIKE rept098.r98_vend_ant
DEFINE vend_n		LIKE rept098.r98_vend_nue
DEFINE tipo_proc	LIKE rept098.r98_estado
DEFINE num_aux		INTEGER

BEGIN WORK
	CALL ejecutar_actualizaciones(vend_ant, vend_n, tipo_proc)
		RETURNING num_aux
	IF num_aux < 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		IF vm_num_rows = 0 THEN
			CLEAR FORM
		ELSE
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN num_aux
	END IF
WHENEVER ERROR STOP
COMMIT WORK
RETURN num_aux

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1500)
DEFINE query		CHAR(3000)
DEFINE r_z01		RECORD LIKE cxct001.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r98_vend_ant, r98_vend_nue, r98_fecha_ini,
	r98_fecha_fin, r98_num_tran, r98_codcli, r98_usuario, r98_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r98_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_r98.r98_codcli = r_z01.z01_codcli
				DISPLAY BY NAME rm_r98.r98_codcli
				DISPLAY r_z01.z01_nomcli TO tit_nomcli
			END IF 
		END IF
		LET int_flag = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept098 ',
		' WHERE r98_compania  = ', vg_codcia,
		'   AND r98_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 4 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r98.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE r_r19		RECORD LIKE rept019.*

LET int_flag = 0
INPUT BY NAME rm_r98.r98_vend_ant, rm_r98.r98_vend_nue, rm_r98.r98_fecha_ini,
		rm_r98.r98_fecha_fin, rm_r98.r98_num_tran, rm_r98.r98_codcli
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_r98.r98_vend_ant, rm_r98.r98_vend_nue,
				 rm_r98.r98_fecha_ini, rm_r98.r98_fecha_fin,
				 rm_r98.r98_num_tran, rm_r98.r98_codcli)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r98_vend_ant) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_r98.r98_vend_ant = r_r01.r01_codigo
				DISPLAY BY NAME rm_r98.r98_vend_ant
				DISPLAY r_r01.r01_nombres TO tit_vend_ant
			END IF
		END IF
		IF INFIELD(r98_vend_nue) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F')
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_r98.r98_vend_nue = r_r01.r01_codigo
				DISPLAY BY NAME rm_r98.r98_vend_nue
				DISPLAY r_r01.r01_nombres TO tit_vend_nue
			END IF
		END IF
		IF INFIELD(r98_num_tran) THEN
			IF rm_r98.r98_vend_ant IS NULL OR
			   rm_r98.r98_fecha_ini IS NOT NULL OR
			   rm_r98.r98_fecha_fin IS NOT NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,'FA')
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							vg_codloc,
							r_r19.r19_cod_tran,
							r_r19.r19_num_tran)
					RETURNING r_r19.*
				LET rm_r98.r98_cod_tran = r_r19.r19_cod_tran
				LET rm_r98.r98_num_tran = r_r19.r19_num_tran
				DISPLAY BY NAME rm_r98.r98_cod_tran,
						rm_r98.r98_num_tran
		      	END IF
		END IF
		IF INFIELD(r98_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_r98.r98_codcli = r_z01.z01_codcli
				DISPLAY BY NAME rm_r98.r98_codcli
				DISPLAY r_z01.z01_nomcli TO tit_nomcli
			END IF 
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r98_vend_ant
		IF rm_r98.r98_vend_ant IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_ant)
				RETURNING r_r01.*
			IF r_r01.r01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.', 'exclamation')
				CLEAR tit_vend_ant
				NEXT FIELD r98_vend_ant
			END IF
			DISPLAY r_r01.r01_nombres TO tit_vend_ant
			IF NOT trans_vend(rm_r98.r98_vend_ant) THEN
				CALL fl_mostrar_mensaje('Vendedor no tiene ventas.', 'exclamation')
				NEXT FIELD r98_vend_ant
			END IF
		ELSE
			CLEAR tit_vend_ant
		END IF
	AFTER FIELD r98_vend_nue
		IF rm_r98.r98_vend_nue IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_nue)
				RETURNING r_r01.*
			IF r_r01.r01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.', 'exclamation')
				CLEAR tit_vend_nue
				NEXT FIELD r98_vend_nue
			END IF
			DISPLAY r_r01.r01_nombres TO tit_vend_nue
			IF r_r01.r01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r98_vend_nue
			END IF
		ELSE
			CLEAR tit_vend_nue
		END IF
	AFTER FIELD r98_fecha_ini
		IF rm_r98.r98_fecha_ini IS NOT NULL THEN
			IF rm_r98.r98_fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD r98_fecha_ini
			END IF
		END IF
	AFTER FIELD r98_fecha_fin
		IF rm_r98.r98_fecha_fin IS NOT NULL THEN
			IF rm_r98.r98_fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD r98_fecha_fin
			END IF
		END IF
	AFTER FIELD r98_num_tran
		IF rm_r98.r98_vend_ant IS NULL OR
		   rm_r98.r98_fecha_ini IS NOT NULL OR
		   rm_r98.r98_fecha_fin IS NOT NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_r98.r98_num_tran IS NOT NULL THEN
			LET rm_r98.r98_cod_tran = 'FA'
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc, rm_r98.r98_cod_tran,
						rm_r98.r98_num_tran)
				RETURNING r_r19.*
			IF r_r19.r19_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Factura no existe.', 'exclamation')
				NEXT FIELD r98_num_tran
			END IF
			IF r_r19.r19_vendedor <> rm_r98.r98_vend_ant THEN
				CALL fl_mostrar_mensaje('Esta factura no pertenece al vendedor que se quiere cambiar.', 'exclamation')
				NEXT FIELD r98_num_tran
			END IF
		ELSE
			LET rm_r98.r98_cod_tran = NULL
			LET rm_r98.r98_num_tran = NULL
		END IF
		DISPLAY BY NAME rm_r98.r98_cod_tran, rm_r98.r98_num_tran
	AFTER FIELD r98_codcli
		IF rm_r98.r98_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_r98.r98_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD r98_codcli
			END IF
			DISPLAY r_z01.z01_nomcli TO tit_nomcli
			IF rm_r98.r98_codcli = rm_r00.r00_codcli_tal THEN
				CALL fl_mostrar_mensaje('El código del cliente no puede ser el del consumidor final.', 'exclamation')
				NEXT FIELD r98_codcli
			END IF
		ELSE
			CLEAR tit_nomcli
		END IF
	AFTER INPUT
		IF rm_r98.r98_vend_nue = rm_r98.r98_vend_ant THEN
			CALL fl_mostrar_mensaje('Para pasar las ventas de un vendedor a otro, estos deben tener códigos diferentes.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF rm_r98.r98_fecha_ini IS NOT NULL THEN
			IF rm_r98.r98_fecha_fin IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha final.', 'exclamation')
				NEXT FIELD r98_fecha_fin
			END IF
		END IF
		IF rm_r98.r98_fecha_fin IS NOT NULL THEN
			IF rm_r98.r98_fecha_ini IS NULL THEN
				CALL fl_mostrar_mensaje('Digite la fecha inicial.', 'exclamation')
				NEXT FIELD r98_fecha_ini
			END IF
		END IF
		IF rm_r98.r98_fecha_ini IS NOT NULL AND
		   rm_r98.r98_fecha_fin IS NOT NULL THEN
			IF rm_r98.r98_fecha_ini > rm_r98.r98_fecha_fin THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha final.', 'exclamation')
				NEXT FIELD r98_fecha_ini
			END IF
		END IF
		IF rm_r98.r98_fecha_ini IS NOT NULL AND
		   rm_r98.r98_fecha_fin IS NOT NULL THEN
			LET rm_r98.r98_cod_tran = NULL
			LET rm_r98.r98_num_tran = NULL
			DISPLAY BY NAME rm_r98.r98_cod_tran, rm_r98.r98_num_tran
		END IF
		IF rm_r98.r98_codcli IS NOT NULL THEN
			IF NOT valido_cliente() THEN
				NEXT FIELD r98_codcli
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION valido_cliente()
DEFINE cuantos		INTEGER
DEFINE mensaje		VARCHAR(255)
DEFINE r_r01		RECORD LIKE rept001.*

CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_ant) RETURNING r_r01.*
SELECT COUNT(*) INTO cuantos
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  IN ("FA", "NV", "DF", "AF")
	  AND r19_codcli    = rm_r98.r98_codcli
	  AND r19_vendedor  = rm_r98.r98_vend_ant
IF cuantos = 0 THEN
	LET mensaje = 'Este cliente no tiene ventas con el vendedor ',
			r_r01.r01_codigo USING "<<<<&", ' ',
			r_r01.r01_nombres CLIPPED, '.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
IF rm_r98.r98_fecha_ini IS NULL THEN
	RETURN 1
END IF
SELECT COUNT(*) INTO cuantos
	FROM rept019
	WHERE r19_compania     = vg_codcia
	  AND r19_localidad    = vg_codloc
	  AND r19_cod_tran     IN ("FA", "NV", "DF", "AF")
	  AND r19_codcli       = rm_r98.r98_codcli
	  AND r19_vendedor     = rm_r98.r98_vend_ant
	  AND DATE(r19_fecing) BETWEEN rm_r98.r98_fecha_ini
				   AND rm_r98.r98_fecha_fin
IF cuantos = 0 THEN
	LET mensaje = 'Este cliente no tiene ventas con el vendedor ',
			r_r01.r01_codigo USING "<<<<&", ' ',
			r_r01.r01_nombres CLIPPED, ' para este período.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
IF rm_r98.r98_num_tran IS NULL THEN
	RETURN 1
END IF
SELECT COUNT(*) INTO cuantos
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = rm_r98.r98_cod_tran
	  AND r19_num_tran  = rm_r98.r98_num_tran
	  AND r19_codcli    = rm_r98.r98_codcli
	  AND r19_vendedor  = rm_r98.r98_vend_ant
IF cuantos = 0 THEN
	LET mensaje = 'La factura debe ser tanto del cliente como del vendedor.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION ejecutar_actualizaciones(vend_ant, vend_n, tipo_proc)
DEFINE vend_ant		LIKE rept098.r98_vend_ant
DEFINE vend_n		LIKE rept098.r98_vend_nue
DEFINE tipo_proc	LIKE rept098.r98_estado
DEFINE query		CHAR(3500)
DEFINE expr_clie	VARCHAR(100)
DEFINE expr_tran	VARCHAR(400)
DEFINE expr_fech	VARCHAR(200)
DEFINE expr_sql		VARCHAR(400)
DEFINE tabla		VARCHAR(10)
DEFINE mensaje		VARCHAR(255)
DEFINE cuantos, num_aux	INTEGER
DEFINE r_r01		RECORD LIKE rept001.*

CALL fl_lee_vendedor_rep(vg_codcia, vend_n) RETURNING r_r01.*
LET expr_tran = '   AND (r19_cod_tran  IN ("FA", "DF", "AF") ',
		'    OR (r19_cod_tran = "TR" AND r19_tipo_dev IS NOT NULL)) '
IF rm_r98.r98_num_tran IS NOT NULL THEN
	LET expr_tran = '   AND r19_cod_tran  = "', rm_r98.r98_cod_tran, '"',
			'   AND r19_num_tran  = ', rm_r98.r98_num_tran
END IF
LET expr_fech = NULL
IF rm_r98.r98_fecha_ini IS NOT NULL THEN
	LET expr_fech = '   AND DATE(r19_fecing) BETWEEN "',
							rm_r98.r98_fecha_ini,
						'"  AND "',rm_r98.r98_fecha_fin,
						'"'
END IF
LET expr_clie = NULL
IF rm_r98.r98_codcli IS NOT NULL THEN
	LET expr_clie = '   AND r19_codcli    = ', rm_r98.r98_codcli
END IF
CASE tipo_proc
	WHEN "P"
		LET tabla    = NULL
		LET expr_sql = ' WHERE r19_compania  = ', vg_codcia,
			  	'   AND r19_localidad = ', vg_codloc
	WHEN "R"
		CALL bloqueo_activacion_vend_ant(tipo_proc)
		LET tabla     = 'rept099,'
		LET expr_sql = ' WHERE r99_compania  = ', rm_r98.r98_compania,
				'   AND r99_localidad = ', rm_r98.r98_localidad,
				'   AND r99_vend_ant  = ', rm_r98.r98_vend_ant,
				'   AND r99_vend_nue  = ', rm_r98.r98_vend_nue,
				'   AND r99_secuencia = ', rm_r98.r98_secuencia,
				'   AND r19_compania  = r99_compania ',
				'   AND r19_localidad = r99_localidad ',
				'   AND r19_cod_tran  = r99_cod_tran ',
				'   AND r19_num_tran  = r99_num_tran '
END CASE
LET query = 'SELECT DATE(r20_fecing) fecha, r20_bodega, r20_linea, ',
			'r20_rotacion,',
			' CASE WHEN r20_cod_tran = "FA" OR r20_cod_tran = "TR"',
				' THEN NVL(SUM((r20_cant_ven * r20_precio)',
				' - r20_val_descto), 0) ',
				' ELSE NVL(SUM((r20_cant_ven * r20_precio)',
				' - r20_val_descto), 0) * (-1) ',
			' END precio, ',
			' CASE WHEN r20_cod_tran = "FA" OR r20_cod_tran = "TR"',
				' THEN NVL(SUM(r20_costo * r20_cant_ven), 0)',
				' ELSE NVL(SUM(r20_costo * r20_cant_ven), 0)',
					' * (-1)',
			' END costo, ', vend_n, ' vend_nue, "',
			r_r01.r01_user_owner CLIPPED,'" usua_ven,r20_compania,',
			' r20_localidad, r20_cod_tran, r20_num_tran,',
			' r19_moneda moneda, r19_cont_cred,',
			' r19_vendedor vend_old ',
		' FROM ', tabla CLIPPED, ' rept019, rept020 ',
		expr_sql CLIPPED,
		expr_tran CLIPPED,
		expr_clie CLIPPED,
		'   AND r19_vendedor  = ', vend_ant,
		expr_fech CLIPPED,
	  	'   AND r20_compania  = r19_compania ',
	  	'   AND r20_localidad = r19_localidad ',
	  	'   AND r20_cod_tran  = r19_cod_tran ',
	  	'   AND r20_num_tran  = r19_num_tran ',
		' GROUP BY 1, 2, 3, 4, 7, 8, 9, 10, 11, 12, 13, 14, 15 ',
		' INTO TEMP tmp_vtas '
PREPARE exec_tmp_vtas FROM query
EXECUTE exec_tmp_vtas
SELECT COUNT(*) INTO cuantos FROM tmp_vtas
IF cuantos = 0 THEN
	DROP TABLE tmp_vtas
	CALL fl_lee_vendedor_rep(rm_r98.r98_compania,vend_ant) RETURNING r_r01.*
	LET mensaje = 'No se ha encontrado ninguna venta del vendedor ',
			r_r01.r01_codigo USING "<<<<&", ' ',
			r_r01.r01_nombres CLIPPED, '.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	RETURN -1
END IF
IF NOT actualizo_rept060(vend_ant, vend_n, 1) THEN
	DROP TABLE tmp_vtas
	RETURN -1
END IF
IF NOT actualizo_rept060(vend_ant, vend_n, 2) THEN
	DROP TABLE tmp_vtas
	RETURN -1
END IF
SELECT UNIQUE r20_compania, r20_localidad, r20_cod_tran, r20_num_tran, vend_nue,
	usua_ven, r19_cont_cred, vend_old
	FROM tmp_vtas
	INTO TEMP tmp_tran
DROP TABLE tmp_vtas
IF NOT actualizo_ventas('21', 1) THEN
	DROP TABLE tmp_tran
	RETURN -1
END IF
IF NOT actualizo_ventas('23', 1) THEN
	DROP TABLE tmp_tran
	RETURN -1
END IF
IF NOT actualizo_ventas('19', 0) THEN
	DROP TABLE tmp_tran
	RETURN -1
END IF
IF NOT actualizo_cajt010() THEN
	DROP TABLE tmp_tran
	RETURN -1
END IF
CASE tipo_proc
	WHEN "P"
		CALL generar_registro_cambio() RETURNING num_aux
		CALL bloqueo_activacion_vend_ant(tipo_proc)
	WHEN "R"
		IF NOT actualizo_rept098(tipo_proc) THEN
			DROP TABLE tmp_tran
			RETURN -1
		END IF
		LET num_aux = 0
END CASE
DROP TABLE tmp_tran
RETURN num_aux

END FUNCTION



FUNCTION actualizo_rept060(vend_ant, vend_n, que_hacer)
DEFINE vend_ant		LIKE rept098.r98_vend_ant
DEFINE vend_n		LIKE rept098.r98_vend_nue
DEFINE que_hacer	SMALLINT
DEFINE resul		SMALLINT
DEFINE query		CHAR(3000)
DEFINE signo		CHAR(1)
DEFINE vendedor		LIKE rept019.r19_vendedor
DEFINE tot_prec		LIKE rept060.r60_precio
DEFINE tot_cost		LIKE rept060.r60_costo

CASE que_hacer
	WHEN 1
		LET signo    = '-'
		LET vendedor = vend_ant
	WHEN 2
		LET signo    = '+'
		LET vendedor = vend_n
END CASE
LET resul = 0
SET LOCK MODE TO WAIT 4
WHENEVER ERROR CONTINUE
WHILE TRUE
	LET query = 'UPDATE rept060 ',
		' SET r60_precio = r60_precio ', signo,
				' (SELECT NVL(SUM(precio), 0) FROM tmp_vtas ',
				'  WHERE fecha        = r60_fecha ',
				'    AND r20_bodega   = r60_bodega ',
				'    AND r20_linea    = r60_linea ',
				'    AND r20_rotacion = r60_rotacion ',
				'    AND r20_cod_tran <> "TR"), ',
		    ' r60_costo  = r60_costo ', signo,
				' (SELECT NVL(SUM(costo), 0) FROM tmp_vtas ',
				'  WHERE fecha        = r60_fecha ',
				'    AND r20_bodega   = r60_bodega ',
				'    AND r20_linea    = r60_linea ',
				'    AND r20_rotacion = r60_rotacion ',
				'    AND r20_cod_tran <> "TR") ',
		' WHERE r60_compania = ', vg_codcia,
		'   AND r60_vendedor = ', vendedor,
		'   AND EXISTS (SELECT fecha, r20_bodega, r20_linea, ',
					'r20_rotacion ',
				' FROM tmp_vtas ',
				' WHERE fecha        = r60_fecha ',
				'   AND r20_bodega   = r60_bodega ',
				'   AND r20_linea    = r60_linea ',
				'   AND r20_rotacion = r60_rotacion ',
				'   AND r20_cod_tran <> "TR") '
	PREPARE exec_up_r60 FROM query
	EXECUTE exec_up_r60
	IF STATUS < 0 THEN
		IF muestra_mensaje_error_continuar_r60(vendedor, 'actualizar',
			'actualización', STATUS)
		THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
	IF STATUS = NOTFOUND THEN
		LET resul = 0
		CASE que_hacer
			WHEN 1
				IF muestra_mensaje_error_continuar_r60(vendedor,
					'encontrar', 'búsqueda', STATUS)
				THEN
					CONTINUE WHILE
				END IF
			WHEN 2
				CALL insertar_rept060(vendedor) RETURNING resul
				WHENEVER ERROR CONTINUE
		END CASE
		EXIT WHILE
	END IF
	CASE que_hacer
		WHEN 1
		LET resul = 1
		SELECT NVL(SUM(r60_precio), 0), NVL(SUM(r60_costo), 0)
			INTO tot_prec, tot_cost
			FROM rept060
			WHERE r60_compania = vg_codcia
			  AND r60_vendedor = vendedor
			  AND EXISTS (SELECT fecha, r20_bodega, r20_linea,
					r20_rotacion
					FROM tmp_vtas
					WHERE fecha        = r60_fecha
					  AND r20_bodega   = r60_bodega
					  AND r20_linea    = r60_linea
					  AND r20_rotacion = r60_rotacion
					  AND r20_cod_tran <> "TR")
		IF tot_prec = 0 AND tot_cost = 0 THEN
			WHENEVER ERROR CONTINUE
			WHILE TRUE
				DELETE FROM rept060
					WHERE r60_compania = vg_codcia
					  AND r60_vendedor = vendedor
					  AND EXISTS (SELECT fecha, r20_bodega,
							r20_linea, r20_rotacion
						FROM tmp_vtas
						WHERE fecha        = r60_fecha
						  AND r20_bodega   = r60_bodega
						  AND r20_linea    = r60_linea
						  AND r20_rotacion =r60_rotacion
						  AND r20_cod_tran <> "TR")
				IF STATUS = 0 THEN
					LET resul = 1
					EXIT WHILE
				END IF
				IF muestra_mensaje_error_continuar_r60(vendedor,
						'eliminar', 'eliminación', STATUS)
				THEN
					CONTINUE WHILE
				ELSE
					LET resul = 0
					EXIT WHILE
				END IF
			END WHILE
			WHENEVER ERROR STOP
		END IF
		WHEN 2
			IF NOT insertar_rept060(vendedor) THEN
				EXIT WHILE
			END IF
			WHENEVER ERROR CONTINUE
			LET resul = 1
	END CASE
	EXIT WHILE
END WHILE
SET LOCK MODE TO NOT WAIT
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION insertar_rept060(vendedor)
DEFINE vendedor		LIKE rept001.r01_codigo
DEFINE resul		SMALLINT

LET resul = 0
WHILE TRUE
	WHENEVER ERROR CONTINUE
	INSERT INTO rept060
		(r60_compania, r60_fecha, r60_bodega, r60_vendedor, r60_moneda,
		 r60_linea, r60_rotacion, r60_precio, r60_costo)
		SELECT r20_compania, fecha, r20_bodega, vend_nue, moneda,
			r20_linea, r20_rotacion, NVL(SUM(precio),0),
			NVL(SUM(costo), 0)
			FROM tmp_vtas
			WHERE r20_cod_tran <> "TR"
			  AND NOT EXISTS (SELECT * FROM rept060
					WHERE r60_compania = vg_codcia
					  AND r60_vendedor = vend_nue
					  AND r60_fecha    = fecha
					  AND r60_bodega   = r20_bodega
					  AND r60_linea    = r20_linea
					  AND r60_rotacion = r20_rotacion)
			GROUP BY 1, 2, 3, 4, 5, 6, 7
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF muestra_mensaje_error_continuar_r60(vendedor, 'insertar','insersión', STATUS)
	THEN
		CONTINUE WHILE
	ELSE
		EXIT WHILE
	END IF
END WHILE
WHENEVER ERROR STOP
RETURN resul

END FUNCTION


 
FUNCTION actualizo_ventas(prefi, act_usua)
DEFINE prefi		CHAR(2)
DEFINE act_usua		SMALLINT
DEFINE query		CHAR(4000)
DEFINE expr_join	CHAR(400)
DEFINE expr_usua	CHAR(600)
DEFINE comp		CHAR(4)
DEFINE resul		SMALLINT

LET expr_join = ' FROM tmp_tran ',
		' WHERE r20_compania  = r', prefi, '_compania ',
		'   AND r20_localidad = r', prefi, '_localidad ',
		'   AND r20_cod_tran  = r', prefi, '_cod_tran ',
		'   AND r20_num_tran  = r', prefi, '_num_tran) '
LET expr_usua = NULL
IF act_usua THEN
	LET expr_usua = ',    r', prefi, '_usuario  = (SELECT usua_ven ',
							expr_join CLIPPED
END IF
IF prefi <> '19' THEN
	CASE prefi
		WHEN '21' LET comp = 'prof'
		WHEN '23' LET comp = 'prev'
	END CASE
	LET query = 'SELECT r', prefi, '_compania cia, r', prefi, '_localidad',
			' loc, r', prefi, '_num', comp, ' num ',
			' FROM rept0', prefi,
			' WHERE r', prefi, '_cod_tran IS NOT NULL ',
			'   AND EXISTS (SELECT r20_compania, r20_localidad, ',
						'r20_cod_tran, r20_num_tran ',
					expr_join CLIPPED,
			' INTO TEMP tmp_vta '
	PREPARE exec_tmp_up_vta FROM query
	EXECUTE exec_tmp_up_vta
END IF
LET resul = 0
SET LOCK MODE TO WAIT 2
WHENEVER ERROR CONTINUE
WHILE TRUE
	LET query = 'UPDATE rept0', prefi,
			' SET r', prefi, '_vendedor = (SELECT vend_nue ',
							expr_join CLIPPED,
							expr_usua CLIPPED
	IF prefi = '19' THEN
		LET query = query CLIPPED,
			' WHERE r', prefi, '_cod_tran IS NOT NULL ',
			'   AND EXISTS (SELECT r20_compania, r20_localidad, ',
						'r20_cod_tran, r20_num_tran ',
					expr_join CLIPPED
	ELSE
		LET query = query CLIPPED,
			' WHERE r', prefi, '_compania  = ', vg_codcia,
			'   AND r', prefi, '_localidad = ', vg_codloc,
			'   AND r', prefi, '_num', comp, ' = ',
				'(SELECT num FROM tmp_vta ',
				' WHERE cia = r', prefi, '_compania',
				'   AND loc = r', prefi, '_localidad ',
				'   AND num = r', prefi, '_num', comp, ')'
	END IF
	PREPARE exec_up_vta FROM query
	EXECUTE exec_up_vta
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF STATUS < 0 THEN
		IF muestra_mensaje_error_continuar_vta(prefi, expr_join,
						'actualizar', 'actualización', STATUS)
		THEN
			CONTINUE WHILE
		END IF
	END IF
	IF STATUS = NOTFOUND THEN
		IF muestra_mensaje_error_continuar_vta(prefi, expr_join,
						'encontrar', 'búsqueda', STATUS)
		THEN
			CONTINUE WHILE
		END IF
	END IF
	EXIT WHILE
END WHILE
SET LOCK MODE TO NOT WAIT
WHENEVER ERROR STOP
IF prefi <> '19' THEN
	DROP TABLE tmp_vta
END IF
RETURN resul

END FUNCTION



FUNCTION actualizo_cajt010()
DEFINE resul		SMALLINT
DEFINE cuantos		INTEGER

SELECT COUNT(*) INTO cuantos
	FROM tmp_tran
	WHERE r20_cod_tran  IN ("FA", "NV", "DF", "AF")
	  AND r19_cont_cred = "C"
IF cuantos = 0 THEN
	RETURN 1
END IF
LET resul = 0
WHENEVER ERROR CONTINUE
WHILE TRUE
	UPDATE cajt010
		SET j10_usuario = (SELECT usua_ven FROM tmp_tran
					WHERE r20_compania  = j10_compania
					  AND r20_localidad = j10_localidad
					  AND r19_cont_cred = "C"
					  AND r20_cod_tran  = j10_tipo_destino
					  AND r20_num_tran  = j10_num_destino)
		WHERE j10_tipo_fuente = "PR"
		  AND j10_valor       > 0
		  AND EXISTS (SELECT r20_compania, r20_localidad, r20_cod_tran,
					r20_num_tran
				FROM tmp_tran
				WHERE r20_compania  = j10_compania
				  AND r20_localidad = j10_localidad
				  AND r19_cont_cred = "C"
				  AND r20_cod_tran  = j10_tipo_destino
				  AND r20_num_tran  = j10_num_destino)
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF STATUS < 0 THEN
		IF muestra_mensaje_error_continuar_j10('actualizar',
			'actualización', STATUS)
		THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
	IF STATUS = NOTFOUND THEN
		IF muestra_mensaje_error_continuar_j10('encontrar', 'búsqueda', STATUS)
		THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
END WHILE
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION actualizo_rept098(estado)
DEFINE estado		LIKE rept098.r98_estado
DEFINE r_r98		RECORD LIKE rept098.*
DEFINE resul		SMALLINT

LET resul = 0
WHENEVER ERROR CONTINUE
WHILE TRUE
	DECLARE q_up CURSOR FOR
		SELECT * FROM rept098
			WHERE r98_compania  = rm_r98.r98_compania
			  AND r98_localidad = rm_r98.r98_localidad
			  AND r98_vend_ant  = rm_r98.r98_vend_ant
			  AND r98_vend_nue  = rm_r98.r98_vend_nue
			  AND r98_secuencia = rm_r98.r98_secuencia
			FOR UPDATE
	OPEN q_up
	FETCH q_up INTO r_r98.*
	IF STATUS < 0 THEN
		CLOSE q_up
		FREE q_up
		IF muestra_mensaje_error_continuar_r98('actualizar',
			'actualización', STATUS)
		THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
	IF STATUS = NOTFOUND THEN
		CLOSE q_up
		FREE q_up
		IF muestra_mensaje_error_continuar_r98('encontrar', 'búsqueda', STATUS)
		THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
	UPDATE rept098 SET r98_estado = estado WHERE CURRENT OF q_up
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF STATUS < 0 THEN
		CLOSE q_up
		FREE q_up
		IF muestra_mensaje_error_continuar_r98('actualizar',
			'actualización', STATUS)
		THEN
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
END WHILE
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION generar_registro_cambio()
DEFINE r_r99		RECORD LIKE rept099.*
DEFINE num_aux		INTEGER

WHILE TRUE
	SELECT NVL(MAX(r98_secuencia) + 1, 1)
		INTO rm_r98.r98_secuencia
		FROM rept098
		WHERE r98_compania  = rm_r98.r98_compania
		  AND r98_localidad = rm_r98.r98_localidad
		  AND r98_vend_ant  = rm_r98.r98_vend_ant
		  AND r98_vend_nue  = rm_r98.r98_vend_nue
	LET rm_r98.r98_estado = "P"
	LET rm_r98.r98_fecing = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO rept098 VALUES (rm_r98.*)
	IF STATUS = 0 THEN
		LET num_aux = SQLCA.SQLERRD[6]
		EXIT WHILE
	END IF
	WHENEVER ERROR STOP
END WHILE
IF rm_r98.r98_num_tran IS NOT NULL THEN
	--DROP TABLE tmp_tran
	RETURN num_aux
END IF
INITIALIZE r_r99.* TO NULL
DECLARE q_tran CURSOR FOR
	SELECT r20_cod_tran, r20_num_tran FROM tmp_tran ORDER BY 1, 2
LET r_r99.r99_compania  = rm_r98.r98_compania
LET r_r99.r99_localidad = rm_r98.r98_localidad
LET r_r99.r99_vend_ant  = rm_r98.r98_vend_ant
LET r_r99.r99_vend_nue  = rm_r98.r98_vend_nue
LET r_r99.r99_secuencia = rm_r98.r98_secuencia
LET r_r99.r99_orden     = 1
FOREACH q_tran INTO r_r99.r99_cod_tran, r_r99.r99_num_tran
	INSERT INTO rept099 VALUES (r_r99.*)
	LET r_r99.r99_orden = r_r99.r99_orden + 1
END FOREACH
RETURN num_aux

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_r60(vendedor, palabra,palabra2,val_sta)
DEFINE vendedor		LIKE rept019.r19_vendedor
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE val_sta		INTEGER
DEFINE varusu		VARCHAR(100)
DEFINE usuario		LIKE gent005.g05_usuario

DECLARE q_blo CURSOR FOR
	SELECT UNIQUE s.username
		FROM sysmaster:syslocks l, sysmaster:syssessions s
		WHERE (type   = "IX" OR type = "U")
		  AND sid     <> DBINFO("sessionid")
		  AND owner   = sid
		  AND tabname = "rept060"
		  AND rowidlk IN
			(SELECT ROWID FROM rept060
			WHERE r60_compania = vg_codcia
			  AND r60_vendedor = vendedor
			  AND EXISTS (SELECT fecha, r20_bodega, r20_linea,
					r20_rotacion
					FROM tmp_vtas
					WHERE fecha        = r60_fecha
					  AND r20_bodega   = r60_bodega
					  AND r20_linea    = r60_linea
					  AND r20_rotacion = r60_rotacion
					  AND r20_cod_tran <> "TR"))
LET varusu = NULL
FOREACH q_blo INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
IF varusu IS NULL THEN
	RETURN mensaje_error_db(val_sta, 'rept060')
END IF
RETURN mensaje_error(vendedor, palabra, palabra2, 'estadísticas', varusu)

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_vta(prefi, expr_join,palabra,palabra2,
						val_sta)
DEFINE prefi		CHAR(2)
DEFINE expr_join	CHAR(400)
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE val_sta		INTEGER
DEFINE query		CHAR(3000)
DEFINE expr_sql		CHAR(400)
DEFINE varusu		VARCHAR(100)
DEFINE palabra3		VARCHAR(20)
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE vendedor		LIKE rept019.r19_vendedor

LET expr_sql = NULL
--IF prefi <> '21' THEN
	LET expr_sql = 	'   AND rowidlk IN ',
			' (SELECT ROWID FROM rept0', prefi,
			' WHERE EXISTS (SELECT r20_compania, r20_localidad, ',
						'r20_cod_tran, r20_num_tran ',
					expr_join CLIPPED, ')'
--END IF
LET query = 'SELECT UNIQUE s.username ',
		' FROM sysmaster:syslocks l, sysmaster:syssessions s ',
		' WHERE type    = "U" OR type = "IX" ',
		'   AND sid     <> DBINFO("sessionid") ',
		'   AND owner   = sid ',
		'   AND tabname = "rept0', prefi, '"',
		expr_sql CLIPPED
PREPARE cons_blo2 FROM query
DECLARE q_blo2 CURSOR FOR cons_blo2
LET varusu = NULL
FOREACH q_blo2 INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
IF varusu IS NULL THEN
	RETURN mensaje_error_db(val_sta, 'rept0' || prefi)
END IF
SELECT UNIQUE vend_old INTO vendedor FROM tmp_tran
CASE prefi
	WHEN '21' LET palabra3 = 'proformas'
	WHEN '23' LET palabra3 = 'preventas'
	WHEN '19' LET palabra3 = 'transacciones'
END CASE
RETURN mensaje_error(vendedor, palabra, palabra2, palabra3, varusu)

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_j10(palabra, palabra2, val_sta)
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE val_sta		INTEGER
DEFINE varusu		VARCHAR(100)
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE vendedor		LIKE rept019.r19_vendedor

DECLARE q_blo3 CURSOR FOR
	SELECT UNIQUE s.username
		FROM sysmaster:syslocks l, sysmaster:syssessions s
		WHERE (type   = "IX" OR type = "U")
		  AND sid     <> DBINFO("sessionid")
		  AND owner   = sid
		  AND tabname = "cajt010"
		  AND rowidlk IN
			(SELECT ROWID FROM cajt010
			WHERE j10_tipo_fuente = "PR"
			  AND j10_valor       > 0
			  AND EXISTS (SELECT r20_compania, r20_localidad,
					r20_cod_tran, r20_num_tran
					FROM tmp_tran
					WHERE r20_compania  = j10_compania
					  AND r20_localidad = j10_localidad
					  AND r19_cont_cred = "C"
					  AND r20_cod_tran  = j10_tipo_destino
					  AND r20_num_tran  = j10_num_destino))
LET varusu = NULL
FOREACH q_blo3 INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
IF varusu IS NULL THEN
	RETURN mensaje_error_db(val_sta, 'cajt010')
END IF
SELECT UNIQUE vend_old INTO vendedor FROM tmp_tran
RETURN mensaje_error(vendedor, palabra, palabra2, 'formas de pago', varusu)

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_r98(palabra, palabra2, val_sta)
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE val_sta		INTEGER
DEFINE varusu		VARCHAR(100)
DEFINE usuario		LIKE gent005.g05_usuario
DEFINE vendedor		LIKE rept019.r19_vendedor

DECLARE q_blo5 CURSOR FOR
	SELECT UNIQUE s.username
		FROM sysmaster:syslocks l, sysmaster:syssessions s
		WHERE (type   = "IX" OR type = "U")
		  AND sid     <> DBINFO("sessionid")
		  AND owner   = sid
		  AND tabname = "rept098"
		  AND rowidlk IN
			(SELECT ROWID FROM rept098
				WHERE r98_compania  = rm_r98.r98_compania
				  AND r98_localidad = rm_r98.r98_localidad
				  AND r98_vend_ant  = rm_r98.r98_vend_ant
				  AND r98_vend_nue  = rm_r98.r98_vend_nue
				  AND r98_secuencia = rm_r98.r98_secuencia)
LET varusu = NULL
FOREACH q_blo5 INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
IF varusu IS NULL THEN
	RETURN mensaje_error_db(val_sta, 'rept098')
END IF
SELECT UNIQUE vend_old INTO vendedor FROM tmp_tran
RETURN mensaje_error(vendedor, palabra, palabra2, 'reversaciones', varusu)

END FUNCTION



FUNCTION bloqueo_activacion_vend_ant(tipo_proc)
DEFINE tipo_proc	LIKE rept098.r98_estado
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(255)
DEFINE palabra1		VARCHAR(10)
DEFINE palabra2		VARCHAR(10)
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE estado		LIKE rept001.r01_estado

IF trans_vend(rm_r98.r98_vend_ant) THEN
	RETURN
END IF
CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_ant) RETURNING r_r01.*
IF r_r01.r01_estado = 'A' AND tipo_proc = 'R' THEN
	RETURN
END IF
LET palabra1 = 'bloquear'
LET palabra2 = 'bloqueado'
IF r_r01.r01_estado = 'B' THEN
	LET palabra1 = 'activar'
	LET palabra2 = 'activado'
END IF
LET mensaje = 'Desea ', palabra1 CLIPPED, ' el vendedor ',
		r_r01.r01_codigo USING "<<<<&", ' ', r_r01.r01_nombres CLIPPED,
		' ?'
LET int_flag = 0
CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 0
	RETURN
END IF
LET resul = 0
WHILE TRUE
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR
		SELECT * FROM rept001 
			WHERE r01_compania = r_r01.r01_compania
			  AND r01_codigo   = r_r01.r01_codigo
			FOR UPDATE
	OPEN q_del
	FETCH q_del INTO r_r01.*
	IF STATUS = 0 THEN
		LET resul = 1
		EXIT WHILE
	END IF
	IF STATUS < 0 THEN
		IF muestra_mensaje_error_continuar_bloven(r_r01.r01_codigo,
								palabra1, STATUS)
		THEN
			CLOSE q_del
			FREE q_del
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
	IF STATUS = NOTFOUND THEN
		IF muestra_mensaje_error_continuar_bloven(r_r01.r01_codigo,
								palabra1, STATUS)
		THEN
			CLOSE q_del
			FREE q_del
			CONTINUE WHILE
		END IF
		EXIT WHILE
	END IF
	WHENEVER ERROR STOP
END WHILE
IF resul = 0 THEN
	CLOSE q_del
	FREE q_del
	RETURN
END IF
LET estado = 'B'
IF r_r01.r01_estado <> 'A' THEN
	LET estado = 'A'
END IF
UPDATE rept001 SET r01_estado = estado WHERE CURRENT OF q_del
LET mensaje = 'El vendedor ', r_r01.r01_codigo USING "<<<<&", ' ',
		r_r01.r01_nombres CLIPPED, ' ha sido ',
		palabra2 CLIPPED, ' OK.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION muestra_mensaje_error_continuar_bloven(vendedor, palabra, val_sta)
DEFINE vendedor		LIKE rept019.r19_vendedor
DEFINE palabra		VARCHAR(15)
DEFINE val_sta		INTEGER
DEFINE resp		CHAR(6)
DEFINE varusu		VARCHAR(100)
DEFINE mensaje		CHAR(300)
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE usuario		LIKE gent005.g05_usuario

DECLARE q_blo4 CURSOR FOR
	SELECT UNIQUE s.username
		FROM sysmaster:syslocks l, sysmaster:syssessions s
		WHERE (type   = "IX" OR type = "U")
		  AND sid     <> DBINFO("sessionid")
		  AND owner   = sid
		  AND tabname = "rept001"
		  AND rowidlk IN (SELECT ROWID FROM rept001
					WHERE r01_compania = vg_codcia
					  AND r01_codigo   = vendedor)
LET varusu = NULL
FOREACH q_blo4 INTO usuario
	IF varusu IS NULL THEN
		LET varusu = UPSHIFT(usuario) CLIPPED
	ELSE
		LET varusu = varusu CLIPPED, ' ', UPSHIFT(usuario) CLIPPED
	END IF
END FOREACH
IF varusu IS NULL THEN
	RETURN mensaje_error_db(val_sta, 'rept001')
END IF
CALL fl_lee_vendedor_rep(vg_codcia, vendedor) RETURNING r_r01.*
LET mensaje = 'El vendedor ', r_r01.r01_codigo USING "<<<<&", ' ',
		r_r01.r01_nombres CLIPPED, ' esta siendo ',
		'bloqueado por el(los) usuario(s) ', varusu CLIPPED,
		'. Desea intentar nuevamente este bloqueo ?'
CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
IF resp = 'Yes' THEN
	RETURN 1
END IF
LET mensaje = 'No se ha podido ', palabra CLIPPED, ' el registro ',
		'del vendedor ', r_r01.r01_codigo USING "<<<<&", ' ',
		r_r01.r01_nombres CLIPPED, '. LLAME AL ADMINISTRADOR.'
CALL fl_mostrar_mensaje(mensaje, 'stop')
RETURN 0

END FUNCTION



FUNCTION mensaje_error(vendedor, palabra, palabra2, palabra3, varusu)
DEFINE vendedor		LIKE rept019.r19_vendedor
DEFINE palabra		VARCHAR(15)
DEFINE palabra2		VARCHAR(15)
DEFINE palabra3		VARCHAR(20)
DEFINE varusu		VARCHAR(100)
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(255)
DEFINE r_r01		RECORD LIKE rept001.*

CALL fl_lee_vendedor_rep(vg_codcia, vendedor) RETURNING r_r01.*
LET mensaje = 'Las ', palabra3 CLIPPED, ' del vendedor ',
		r_r01.r01_codigo USING "<<<<&", ' ', r_r01.r01_nombres CLIPPED,
		' estan siendo bloqueadas por el(los) usuario(s) ',
		varusu CLIPPED, '. Desea intentar nuevamente esta ',
		palabra2 CLIPPED, ' ?'
CALL fl_hacer_pregunta(mensaje, 'Yes') RETURNING resp
IF resp = 'Yes' THEN
	RETURN 1
END IF
LET mensaje = 'No se han podido ', palabra CLIPPED, ' registros de las ',
		palabra3 CLIPPED, ' del vendedor ', r_r01.r01_codigo
		USING "<<<<&", ' ', r_r01.r01_nombres CLIPPED,
		'. LLAME AL ADMINISTRADOR.'
CALL fl_mostrar_mensaje(mensaje, 'stop')
RETURN 0

END FUNCTION



FUNCTION mensaje_error_db(val_sta, tabla)
DEFINE val_sta		INTEGER
DEFINE tabla		VARCHAR(10)
DEFINE mensaje		VARCHAR(255)

LET mensaje = 'Se ha producido el error No. ', val_sta USING "-------&",
		' en la base de datos, tabla ', tabla CLIPPED,
		'. POR FAVOR LLAME AL ADMINISTRADOR.'
CALL fl_mostrar_mensaje(mensaje, 'stop')
RETURN 0

END FUNCTION



FUNCTION trans_vend(vendedor)
DEFINE vendedor		LIKE rept001.r01_codigo
DEFINE cuantos		INTEGER

SELECT COUNT(*) INTO cuantos
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_vendedor  = vendedor
IF cuantos > 0 THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r01		RECORD LIKE rept001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r98.* FROM rept098 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', row
END IF
DISPLAY BY NAME rm_r98.r98_estado, rm_r98.r98_vend_ant, rm_r98.r98_vend_nue,
		rm_r98.r98_fecha_ini, rm_r98.r98_fecha_fin, rm_r98.r98_cod_tran,
		rm_r98.r98_num_tran, rm_r98.r98_secuencia, rm_r98.r98_codcli,
		rm_r98.r98_usuario, rm_r98.r98_fecing
CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_ant) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO tit_vend_ant
CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_nue) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO tit_vend_nue
CALL fl_lee_cliente_general(rm_r98.r98_codcli) RETURNING r_z01.*
DISPLAY r_z01.z01_nomcli TO tit_nomcli
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()

CASE rm_r98.r98_estado
	WHEN 'P' DISPLAY "PROCESADO" TO tit_estado
	WHEN 'R' DISPLAY "REVERSADO" TO tit_estado
END CASE
DISPLAY BY NAME rm_r98.r98_estado

END FUNCTION



FUNCTION control_reversar()
DEFINE resp		CHAR(6)
DEFINE num_aux		INTEGER

CALL fl_hacer_pregunta('Desea REVERSAR este registro ?', 'No') RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 0
	RETURN
END IF
LET int_flag = 0
CALL ejecutar_proceso(rm_r98.r98_vend_nue, rm_r98.r98_vend_ant, 'R')
	RETURNING num_aux
IF num_aux < 0 THEN
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('Registro reversado OK.', 'info')
CALL fl_hacer_pregunta('Desea ver el detalle de este registro ?', 'Yes')
	RETURNING resp
IF resp = 'Yes' THEN
	CALL control_detalle()
END IF

END FUNCTION



FUNCTION control_detalle()
DEFINE r_det		ARRAY[10000] OF RECORD
				r99_cod_tran	LIKE rept099.r99_cod_tran,
				r99_num_tran	LIKE rept099.r99_num_tran,
				r19_fecing	DATE,
				r19_nomcli	LIKE rept019.r19_nomcli,
				r19_tot_neto	LIKE rept019.r19_tot_neto
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_orden 		ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_row, max_row	SMALLINT
DEFINE col, i		SMALLINT
DEFINE total		DECIMAL(14,2)
DEFINE query		CHAR(1500)
DEFINE r_r01		RECORD LIKE rept001.*

LET max_row  = 10000
LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 19
LET num_cols = 65
IF vg_gui = 0 THEN        
	LET lin_menu = 1
	LET row_ini  = 5
	LET num_rows = 20
	LET num_cols = 66
END IF                  
OPEN WINDOW w_repf242_2 AT row_ini, 08 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf242_2 FROM '../forms/repf242_2'
ELSE
	OPEN FORM f_repf242_2 FROM '../forms/repf242_2c'
END IF
DISPLAY FORM f_repf242_2
--#DISPLAY "TP"		TO tit_col1
--#DISPLAY "Número"	TO tit_col2
--#DISPLAY "Fecha"	TO tit_col3
--#DISPLAY "Clientes"	TO tit_col4
--#DISPLAY "Total Neto"	TO tit_col5
DISPLAY BY NAME rm_r98.r98_vend_ant, rm_r98.r98_vend_nue, rm_r98.r98_fecha_ini,
		rm_r98.r98_fecha_fin
CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_ant) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO tit_vend_ant
CALL fl_lee_vendedor_rep(vg_codcia, rm_r98.r98_vend_nue) RETURNING r_r01.*
DISPLAY r_r01.r01_nombres TO tit_vend_nue
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3] = 'DESC'
LET columna_1  = 3
LET columna_2  = 2
WHILE TRUE
	LET query = 'SELECT r99_cod_tran, r99_num_tran, DATE(r19_fecing),',
				'r19_nomcli, ',
			' CASE WHEN r99_cod_tran = "FA" ',
				'THEN r19_tot_bruto - r19_tot_dscto ',
				'ELSE (r19_tot_bruto - r19_tot_dscto) * (-1)',
			' END ',
			' FROM rept099, rept019 ',
			' WHERE r99_compania  = ', rm_r98.r98_compania,
			'   AND r99_localidad = ', rm_r98.r98_localidad,
			'   AND r99_vend_ant  = ', rm_r98.r98_vend_ant,
			'   AND r99_vend_nue  = ', rm_r98.r98_vend_nue,
			'   AND r99_secuencia = ', rm_r98.r98_secuencia,
			'   AND r19_compania  = r99_compania ',
			'   AND r19_localidad = r99_localidad ',
			'   AND r19_cod_tran  = r99_cod_tran ',
			'   AND r19_num_tran  = r99_num_tran ',
			' ORDER BY ', columna_1, ' ', r_orden[columna_1],
				', ', columna_2, ' ', r_orden[columna_2]
	PREPARE cons_r99 FROM query
	DECLARE q_r99 CURSOR FOR cons_r99
	LET i     = 1
	LET total = 0
	FOREACH q_r99 INTO r_det[i].*
		LET total = total + r_det[i].r19_tot_neto
		LET i     = i + 1
		IF i > max_row THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	LET num_row = i
	DISPLAY BY NAME total
	LET int_flag = 0
	CALL set_count(num_row)
	DISPLAY ARRAY r_det TO r_det.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
				r_det[i].r99_cod_tran, r_det[i].r99_num_tran)
			LET int_flag = 0
		ON KEY(F15)
			LET col      = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET col      = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col      = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET col      = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET col      = 5
			LET int_flag = 2
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#CALL mostrar_contadores_det(i, num_row)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel("RETURN","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> columna_1 THEN
		LET columna_2          = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1          = col 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_repf242_2
LET int_flag = 0
RETURN

END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
