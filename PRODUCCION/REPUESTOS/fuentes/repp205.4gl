------------------------------------------------------------------------------
-- Titulo           : repp205.4gl - Confirmaci�n de Pedidos
-- Elaboracion      : 09-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp205 base m�dulo compa��a localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_rep		RECORD LIKE rept016.*
DEFINE rm_rep2		RECORD LIKE rept017.*
DEFINE vm_num_rows      SMALLINT
DEFINE vm_row_current   SMALLINT
DEFINE vm_max_rows      SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp205'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_mas AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_mas FROM "../forms/repf205_1"
DISPLAY FORM f_mas
INITIALIZE rm_rep.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Confirmar'
		HIDE OPTION 'Pedido'
	COMMAND KEY('M') 'Confirmar' 'Confirma el pedido corriente. '
                CALL control_confirmacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
			
				SHOW OPTION 'Confirmar'
				SHOW OPTION 'Pedido'			
                       
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
                                HIDE OPTION 'Confirmar'
				HIDE OPTION 'Pedido'
                        END IF
                ELSE
                        SHOW OPTION 'Avanzar'                      
						SHOW OPTION 'Confirmar'		
						SHOW OPTION 'Pedido'
		
                END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	 COMMAND KEY('P') 'Pedido' 'Muestra el pedido actual. '
		CALL ver_pedido()
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



FUNCTION control_confirmacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_rep.r16_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,'Registro ya ha sido confirmado.','exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rept016
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_rep.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos()
IF NOT int_flag THEN
	UPDATE rept016 SET r16_fec_llegada  = rm_rep.r16_fec_llegada,
			   r16_estado       = 'C'
		WHERE CURRENT OF q_up
	UPDATE rept017 SET r17_estado = 'C'
		WHERE r17_compania  = vg_codcia
		  AND r17_localidad = vg_codloc
		  AND r17_pedido    = rm_rep.r16_pedido
	DECLARE q_item CURSOR FOR 
		SELECT * FROM rept017
			WHERE r17_compania  = vg_codcia
		          AND r17_localidad = vg_codloc
		          AND r17_pedido    = rm_rep.r16_pedido
		FOR UPDATE
	FOREACH q_item INTO rm_rep2.*
		UPDATE rept010 SET r10_cantped = r10_cantped
						+ rm_rep2.r17_cantped
			WHERE r10_compania = vg_codcia
			  AND r10_codigo   = rm_rep2.r17_item
	END FOREACH
	COMMIT WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	CALL fgl_winmessage(vg_producto,'Registro confirmado Ok.','info')
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
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER
DEFINE codpe_aux	LIKE rept016.r16_pedido
DEFINE codp_aux		LIKE cxpt002.p02_codprov
DEFINE nomp_aux		LIKE cxpt001.p01_nomprov
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE r_cxp2		RECORD LIKE cxpt002.*

CLEAR FORM
INITIALIZE codpe_aux, codp_aux, mone_aux TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r16_pedido, r16_proveedor,
	r16_fec_envio, r16_fec_llegada, r16_moneda
	ON KEY(F2)
		IF infield(r16_pedido) THEN
			CALL fl_ayuda_pedidos_rep(vg_codcia,vg_codloc,'A','T')
				RETURNING codpe_aux
			LET int_flag = 0
			IF codpe_aux IS NOT NULL THEN
				DISPLAY codpe_aux TO r16_pedido
			END IF
		END IF
		IF infield(r16_proveedor) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING codp_aux, nomp_aux
			LET int_flag = 0
			IF codp_aux IS NOT NULL THEN
				CALL fl_lee_proveedor_localidad(vg_codcia,
							vg_codloc,codp_aux)
					RETURNING r_cxp2.*
				DISPLAY codp_aux TO r16_proveedor
				DISPLAY nomp_aux TO tit_proveedor
			END IF
		END IF
		IF infield(r16_moneda) THEN
                        CALL fl_ayuda_monedas()
                                RETURNING mone_aux, nomm_aux, deci_aux
                        LET int_flag = 0
                        IF mone_aux IS NOT NULL THEN
                                DISPLAY mone_aux TO r16_moneda
                                DISPLAY nomm_aux TO tit_mon_bas
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
LET query = 'SELECT *, ROWID FROM rept016
		WHERE r16_compania  = ' || vg_codcia ||
		' AND r16_localidad = ' || vg_codloc ||
		' AND ' || expr_sql CLIPPED||
		' AND r16_estado    = "A"'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_rep.*, num_reg
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
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE fec_llegada	LIKE rept016.r16_fec_llegada

LET int_flag = 0
INPUT BY NAME rm_rep.r16_fec_llegada
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_rep.r16_fec_llegada) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
	BEFORE FIELD r16_fec_llegada
		LET fec_llegada = rm_rep.r16_fec_llegada
	AFTER FIELD r16_fec_llegada
		IF rm_rep.r16_fec_llegada IS NOT NULL THEN
			IF rm_rep.r16_fec_llegada < TODAY
			OR rm_rep.r16_fec_llegada < rm_rep.r16_fec_envio THEN
				CALL fgl_winmessage(vg_producto,'La fecha de llegada es incorrecta.','exclamation')
				NEXT FIELD r16_fec_llegada
			END IF
		ELSE
			LET rm_rep.r16_fec_llegada = fec_llegada
			DISPLAY BY NAME rm_rep.r16_fec_llegada
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
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_reg)
DEFINE num_reg		INTEGER
DEFINE r_cxp		RECORD LIKE cxpt001.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_cta		RECORD LIKE ctbt010.*

IF vm_num_rows > 0 THEN
        SELECT * INTO rm_rep.* FROM rept016 WHERE ROWID = num_reg
        IF STATUS = NOTFOUND THEN
        	CALL fgl_winmessage (vg_producto,'No existe registro con �ndice: ' || vm_row_current,'exclamation')
                RETURN
        END IF	
	DISPLAY BY NAME rm_rep.r16_pedido, rm_rep.r16_proveedor,
			rm_rep.r16_fec_envio, rm_rep.r16_fec_llegada,
			rm_rep.r16_moneda
	CALL fl_lee_proveedor(rm_rep.r16_proveedor) RETURNING r_cxp.*
	DISPLAY r_cxp.p01_nomprov TO tit_proveedor
        CALL fl_lee_moneda(rm_rep.r16_moneda) RETURNING r_mon.*
        DISPLAY r_mon.g13_nombre TO tit_mon_bas
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_estado()
                                                                                
IF rm_rep.r16_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado_rep
END IF
IF rm_rep.r16_estado = 'C' THEN
        DISPLAY 'CONFIRMADO' TO tit_estado_rep
END IF
IF rm_rep.r16_estado = 'R' THEN
        DISPLAY 'RECIBIDO' TO tit_estado_rep
END IF
IF rm_rep.r16_estado = 'L' THEN
        DISPLAY 'LIQUIDADO' TO tit_estado_rep
END IF
IF rm_rep.r16_estado = 'P' THEN
        DISPLAY 'PROCESADO' TO tit_estado_rep
END IF
DISPLAY BY NAME rm_rep.r16_estado
                                                                                
END FUNCTION



FUNCTION ver_pedido()

IF rm_rep.r16_pedido IS NULL THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
	vg_separador, 'fuentes', vg_separador, '; fglrun repp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia,' ', vg_codloc, ' ',
	'"', rm_rep.r16_pedido, '"'
RUN vm_nuevoprog

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
