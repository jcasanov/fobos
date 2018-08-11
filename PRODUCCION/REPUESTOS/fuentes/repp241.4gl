--------------------------------------------------------------------------------
-- Titulo           : repp241.4gl - Mantenimiento Guías de Remisión
-- Elaboracion      : 20-nov-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp241 base modulo compania localidad [num_guia]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[10000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_elementos	SMALLINT
DEFINE vm_ind_arr	SMALLINT
DEFINE vm_size_arr	SMALLINT
DEFINE vm_num_not	SMALLINT
DEFINE vm_max_not	SMALLINT
DEFINE rm_guia		ARRAY[600] OF RECORD
				r20_cod_tran	LIKE rept020.r20_cod_tran,
				r20_num_tran	LIKE rept020.r20_num_tran,
				r36_bodega_real	LIKE rept036.r36_bodega_real,
				r36_num_ord_des	LIKE rept036.r36_num_ord_des,
				r36_num_entrega	LIKE rept036.r36_num_entrega,
				r20_item	LIKE rept020.r20_item,
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r10_uni_med	LIKE rept010.r10_uni_med,
				r10_nombre	LIKE rept010.r10_nombre
			END RECORD
DEFINE rm_aux		ARRAY[600] OF RECORD
				r36_bodega	LIKE rept036.r36_bodega
			END RECORD
DEFINE rm_nota		ARRAY[100] OF RECORD
				r36_num_ord_des	LIKE rept036.r36_num_ord_des,
				r36_bodega	LIKE rept036.r36_bodega,
				r36_num_entrega	LIKE rept036.r36_num_entrega,
				r36_bodega_real	LIKE rept036.r36_bodega_real,
				r36_fec_entrega	LIKE rept036.r36_fec_entrega,
				r36_entregar_a	LIKE rept036.r36_entregar_a,
				total_ne	DECIMAL(8,2),
				seleccionar_ne	CHAR(1)
			END RECORD
DEFINE rm_r00	 	RECORD LIKE rept000.*
DEFINE rm_r95		RECORD LIKE rept095.*
DEFINE rm_r96		RECORD LIKE rept096.*
DEFINE rm_r97		RECORD LIKE rept097.*
DEFINE cod_tran1	LIKE rept097.r97_cod_tran
DEFINE cod_tran2	LIKE rept097.r97_cod_tran



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp241.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp241'
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
IF num_args() = 4 THEN
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_compania_repuestos(vg_codcia)  RETURNING rm_r00.*                
LET cod_tran1     = 'FA'
LET cod_tran2     = 'TR'
LET vm_max_rows   = 10000
LET vm_elementos  = 600
LET vm_max_not    = 100
LET lin_menu      = 0          
LET row_ini       = 3          
LET num_rows      = 22         
LET num_cols      = 80         
IF vg_gui = 0 THEN        
	LET lin_menu = 1                                                        
	LET row_ini  = 2
	LET num_rows = 22 
	LET num_cols = 78 
END IF                  
OPEN WINDOW w_repp241 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf241_1 FROM '../forms/repf241_1'
ELSE
	OPEN FORM f_repf241_1 FROM '../forms/repf241_1c'
END IF
DISPLAY FORM f_repf241_1
CALL control_mostrar_botones()
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar Guía'
		HIDE OPTION 'Factura'
		HIDE OPTION 'Ver Detalle'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
                HIDE OPTION 'Imprimir'
		IF num_args() = 5 THEN
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Ingresar'
                	HIDE OPTION 'Imprimir'
			HIDE OPTION 'Ver Detalle'
			CALL control_consulta()
			CALL control_ver_detalle()
			EXIT MENU
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		HIDE OPTION 'Imprimir'
                CALL control_ingreso()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF rm_r95.r95_estado = 'A' THEN
					SHOW OPTION 'Eliminar Guía'
					SHOW OPTION 'Modificar'
				ELSE
					HIDE OPTION 'Eliminar Guía'
					HIDE OPTION 'Modificar'
				END IF
				SHOW OPTION 'Ver Detalle'
				IF rm_r97.r97_compania IS NOT NULL THEN
					SHOW OPTION 'Factura'
				ELSE
					HIDE OPTION 'Factura'
				END IF
			END IF 
                ELSE
			IF rm_r95.r95_estado = 'A' THEN
				SHOW OPTION 'Eliminar Guía'
				SHOW OPTION 'Modificar'
			ELSE
				HIDE OPTION 'Eliminar Guía'
				HIDE OPTION 'Modificar'
			END IF
			SHOW OPTION 'Ver Detalle'
			IF rm_r97.r97_compania IS NOT NULL THEN
				SHOW OPTION 'Factura'
			ELSE
				HIDE OPTION 'Factura'
			END IF
			SHOW OPTION 'Retroceder'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
        COMMAND KEY('M') 'Modificar'		'Modifica una Guía Activa.'
		CALL control_modificacion()
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
		HIDE OPTION 'Imprimir'
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
			IF vm_num_rows = 1 THEN
				IF rm_r95.r95_estado = 'A' THEN
					SHOW OPTION 'Eliminar Guía'
					SHOW OPTION 'Modificar'
				ELSE
					HIDE OPTION 'Eliminar Guía'
					HIDE OPTION 'Modificar'
				END IF
				SHOW OPTION 'Ver Detalle'
				IF rm_r97.r97_compania IS NOT NULL THEN
					SHOW OPTION 'Factura'
				ELSE
					HIDE OPTION 'Factura'
				END IF
			END IF 
                ELSE
			IF rm_r97.r97_compania IS NOT NULL THEN
				SHOW OPTION 'Factura'
			ELSE
				HIDE OPTION 'Factura'
			END IF
			IF rm_r95.r95_estado = 'A' THEN
				SHOW OPTION 'Eliminar Guía'
				SHOW OPTION 'Modificar'
			ELSE
				HIDE OPTION 'Eliminar Guía'
				HIDE OPTION 'Modificar'
			END IF
			SHOW OPTION 'Ver Detalle'
                        SHOW OPTION 'Avanzar'
                END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
        COMMAND KEY('E') 'Eliminar Guía'	'Elimina una Guía Activa.'
		CALL control_eliminacion()
        COMMAND KEY('P') 'Imprimir'		'Imprime Devolución/Anulación.'
        	CALL imprimir()
        COMMAND KEY('F') 'Factura'		'Muestra la Factura.'
		CALL control_ver_transaccion(0)
	COMMAND KEY('V') 'Ver Detalle' 		'Ver Detalle de la Transacción.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF 
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			IF rm_r95.r95_estado = 'A' THEN
				SHOW OPTION 'Eliminar Guía'
				SHOW OPTION 'Modificar'
			ELSE
				HIDE OPTION 'Eliminar Guía'
				HIDE OPTION 'Modificar'
			END IF
			SHOW OPTION 'Ver Detalle'
			IF rm_r97.r97_compania IS NOT NULL THEN
				SHOW OPTION 'Factura'
			ELSE
				HIDE OPTION 'Factura'
			END IF
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			IF rm_r95.r95_estado = 'A' THEN
				SHOW OPTION 'Eliminar Guía'
				SHOW OPTION 'Modificar'
			ELSE
				HIDE OPTION 'Eliminar Guía'
				HIDE OPTION 'Modificar'
			END IF
			SHOW OPTION 'Ver Detalle'
			IF rm_r97.r97_compania IS NOT NULL THEN
				SHOW OPTION 'Factura'
			ELSE
				HIDE OPTION 'Factura'
			END IF
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			IF rm_r95.r95_estado = 'A' THEN
				SHOW OPTION 'Eliminar Guía'
				SHOW OPTION 'Modificar'
			ELSE
				HIDE OPTION 'Eliminar Guía'
				HIDE OPTION 'Modificar'
			END IF
			SHOW OPTION 'Ver Detalle'
			IF rm_r97.r97_compania IS NOT NULL THEN
				SHOW OPTION 'Factura'
			ELSE
				HIDE OPTION 'Factura'
			END IF
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			IF rm_r95.r95_estado = 'A' THEN
				SHOW OPTION 'Eliminar Guía'
				SHOW OPTION 'Modificar'
			ELSE
				HIDE OPTION 'Eliminar Guía'
				HIDE OPTION 'Modificar'
			END IF
			SHOW OPTION 'Ver Detalle'
			IF rm_r97.r97_compania IS NOT NULL THEN
				SHOW OPTION 'Factura'
			ELSE
				HIDE OPTION 'Factura'
			END IF
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_rows > 0 THEN
			SHOW OPTION 'Imprimir'
		END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_repp241
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER
DEFINE mensaje		VARCHAR(100)
DEFINE r_g02		RECORD LIKE gent002.*

CLEAR FORM
CALL control_mostrar_botones()
INITIALIZE rm_r95.*, rm_r96.*, rm_r97.* TO NULL
LET rm_r95.r95_compania      = vg_codcia
LET rm_r95.r95_localidad     = vg_codloc
LET rm_r95.r95_estado        = 'A'
LET rm_r95.r95_motivo        = 'V'
LET rm_r95.r95_entre_local   = 'N'
LET rm_r95.r95_fecha_initras = vg_fecha
LET rm_r95.r95_fecha_emi     = vg_fecha
LET rm_r95.r95_usuario       = vg_usuario
LET rm_r95.r95_fecing        = fl_current()
DISPLAY BY NAME rm_r95.r95_usuario, rm_r95.r95_fecing
CALL muestra_estado()
CALL muestra_motivo()
CALL lee_cabecera()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_mostrar_botones()
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
CALL lee_detalle()
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_mostrar_botones()
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
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
LET mensaje = 'Se generó Guía de Remisión No. ',
		rm_r95.r95_guia_remision USING "<<<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1500)
DEFINE query		CHAR(3000)
DEFINE r_r95		RECORD LIKE rept095.*

CLEAR FORM
CALL control_mostrar_botones()
IF num_args() = 4 THEN
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r95_guia_remision, r95_estado,
		r95_num_sri, r95_autoriz_sri, r95_fecha_initras,
		r95_fecha_fintras, r95_motivo, r95_fecha_emi, r95_punto_part,
		r95_persona_guia, r95_persona_dest, r95_persona_id,
		r95_pers_id_dest, r95_punto_lleg, r95_usuario, r95_fecing
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r95_guia_remision) THEN
			CALL fl_ayuda_guias_remision(vg_codcia, vg_codloc, 'T')
				RETURNING r_r95.r95_guia_remision
		      	IF r_r95.r95_guia_remision IS NOT NULL THEN
				CALL fl_lee_guias_remision(vg_codcia, vg_codloc,
							r_r95.r95_guia_remision)
					RETURNING r_r95.*
				DISPLAY BY NAME r_r95.r95_guia_remision,
						r_r95.r95_estado,
						r_r95.r95_persona_dest
				LET rm_r95.r95_estado = r_r95.r95_estado
				CALL muestra_estado()
		      	END IF
		END IF
		LET int_flag = 0
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		CALL control_mostrar_botones()
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = ' r95_guia_remision = ', arg_val(5)
END IF
LET query = 'SELECT *, ROWID FROM rept095 ',
		' WHERE r95_compania  = ', vg_codcia,
		'   AND r95_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r95.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 5 THEN
		EXIT PROGRAM
	END IF
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CLEAR FORM
	CALL control_mostrar_botones()
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_modificacion()

END FUNCTION



FUNCTION control_eliminacion()
DEFINE resp		CHAR(6)

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r95.r95_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Solo se pueden eliminar guías de remisión que esten con estado ACTIVA.', 'exclamation')
	RETURN
END IF
CALL fl_hacer_pregunta('Esta seguro de ELIMINAR esta Guía de Remisión ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_elim CURSOR FOR
	SELECT * FROM rept095
		WHERE r95_compania      = rm_r95.r95_compania
		  AND r95_localidad     = rm_r95.r95_localidad
		  AND r95_guia_remision = rm_r95.r95_guia_remision
		FOR UPDATE
OPEN q_elim
FETCH q_elim INTO rm_r95.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de esta guía de remisión. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
UPDATE rept095 SET r95_estado = 'E' WHERE CURRENT OF q_elim
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo ELIMINAR la guía de remisión. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
COMMIT WORK
WHENEVER ERROR STOP
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mostrar_mensaje('La Guía de Remisión ha sido Eliminada OK.', 'info')

END FUNCTION



FUNCTION lee_cabecera()
DEFINE query		CHAR(600)
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE fecha_ini	LIKE rept095.r95_fecha_initras
DEFINE fecha_emi	LIKE rept095.r95_fecha_emi
DEFINE persona_id	LIKE rept095.r95_persona_id
DEFINE pers_id_dest	LIKE rept095.r95_pers_id_dest
DEFINE r_r19		RECORD LIKE rept019.*

LET int_flag = 0
INPUT BY NAME rm_r97.r97_cod_tran, rm_r97.r97_num_tran, rm_r95.r95_num_sri,
		rm_r95.r95_autoriz_sri, rm_r95.r95_fecha_initras,
		rm_r95.r95_fecha_fintras,rm_r95.r95_motivo,rm_r95.r95_fecha_emi,
		rm_r95.r95_punto_part, rm_r95.r95_persona_guia,
		rm_r95.r95_persona_dest, rm_r95.r95_placa,rm_r95.r95_persona_id,
		rm_r95.r95_pers_id_dest, rm_r95.r95_punto_lleg
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_r97.r97_cod_tran, rm_r97.r97_num_tran,
			rm_r95.r95_num_sri, rm_r95.r95_autoriz_sri,
			rm_r95.r95_fecha_initras, rm_r95.r95_fecha_fintras,
			rm_r95.r95_motivo, rm_r95.r95_fecha_emi,
			rm_r95.r95_punto_part, rm_r95.r95_persona_guia,
			rm_r95.r95_persona_dest, rm_r95.r95_placa,
			rm_r95.r95_persona_id, rm_r95.r95_pers_id_dest,
			rm_r95.r95_punto_lleg)
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
		IF INFIELD(r97_num_tran) THEN
			CALL fl_ayuda_transaccion_rep(vg_codcia, vg_codloc,
						      rm_r97.r97_cod_tran)
				RETURNING r_r19.r19_cod_tran, 
					  r_r19.r19_num_tran,
					  r_r19.r19_nomcli
		      	IF r_r19.r19_num_tran IS NOT NULL THEN
				CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
							vg_codloc,
							rm_r97.r97_cod_tran,
							r_r19.r19_num_tran)
					RETURNING r_r19.*
				LET rm_r97.r97_cod_tran = r_r19.r19_cod_tran
				LET rm_r97.r97_num_tran = r_r19.r19_num_tran
				DISPLAY BY NAME rm_r97.r97_num_tran
		      	END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF INFIELD(r97_num_tran) THEN
			IF rm_r97.r97_cod_tran = cod_tran1 THEN
				CALL control_ver_transaccion(0)
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD r95_fecha_initras
		LET fecha_ini = rm_r95.r95_fecha_initras
	BEFORE FIELD r95_fecha_emi
		LET fecha_emi = rm_r95.r95_fecha_emi
	BEFORE FIELD r95_persona_id
		LET persona_id = rm_r95.r95_persona_id
	BEFORE FIELD r95_pers_id_dest
		LET pers_id_dest = rm_r95.r95_pers_id_dest
	AFTER FIELD r97_cod_tran
		IF rm_r97.r97_cod_tran IS NOT NULL THEN
			IF rm_r97.r97_cod_tran <> cod_tran1 AND
			   rm_r97.r97_cod_tran <> cod_tran2
			THEN
				CALL fl_mostrar_mensaje('Solo puede digitar (FA) para FACTURAS ó (TR) para TRANSFERENCIAS.', 'exclamation')
				NEXT FIELD r97_cod_tran
			END IF
		END IF
	AFTER FIELD r97_num_tran
		IF rm_r97.r97_cod_tran IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_r97.r97_num_tran IS NOT NULL THEN
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc, rm_r97.r97_cod_tran,
						rm_r97.r97_num_tran)
				RETURNING r_r19.*
		END IF
		IF rm_r97.r97_cod_tran = cod_tran1 THEN
                	IF r_r19.r19_num_tran IS NULL THEN
				CALL fl_mostrar_mensaje('La Factura no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD r97_num_tran
			END IF
			IF r_r19.r19_tipo_dev IS NOT NULL THEN
				IF factura_totalmente_dev(r_r19.*) THEN
					CALL fl_mostrar_mensaje('A esta Factura no se le puede generar Guía de Remisión, porque ha sido totalmente Devuelta/Anulada.', 'exclamation')
					NEXT FIELD r97_num_tran
				END IF
			END IF
			IF r_r19.r19_ord_trabajo IS NOT NULL THEN
				CALL fl_mostrar_mensaje('A esta Factura no se le puede generar Guía de Remisión, porque pertenece al Taller.', 'exclamation')
				NEXT FIELD r97_num_tran
			END IF
			IF NOT tiene_nota_entrega(r_r19.r19_cod_tran,
							r_r19.r19_num_tran)
			THEN
				CALL fl_mostrar_mensaje('A esta Factura no se le puede generar Guía de Remisión, porque no tiene alguna nota de entrega.', 'exclamation')
				NEXT FIELD r97_num_tran
			END IF
			IF NOT tiene_guia_remision(r_r19.r19_cod_tran,
							r_r19.r19_num_tran)
			THEN
				CALL fl_mostrar_mensaje('A esta Factura no se le puede generar Guía de Remisión, porque ya tiene.', 'exclamation')
				NEXT FIELD r97_num_tran
			END IF
			SELECT UNIQUE TRIM(r19_nomcli) per_dest,
				r19_cedruc per_id,
				TRIM(r36_entregar_en) punto_lleg
				FROM rept034, rept036, rept019
				WHERE r34_compania    = vg_codcia
		                  AND r34_localidad   = vg_codloc
		                  AND r34_cod_tran    = rm_r97.r97_cod_tran
		                  AND r34_num_tran    = rm_r97.r97_num_tran
		                  AND r36_compania    = r34_compania
		                  AND r36_localidad   = r34_localidad
		                  AND r36_bodega      = r34_bodega
		                  AND r36_num_ord_des = r34_num_ord_des
		                  AND r19_compania    = r34_compania
		                  AND r19_localidad   = r34_localidad
		                  AND r19_cod_tran    = r34_cod_tran
		                  AND r19_num_tran    = r34_num_tran
				INTO TEMP t1
		END IF
		IF rm_r97.r97_cod_tran = cod_tran2 THEN
                	IF r_r19.r19_num_tran IS NULL THEN
				CALL fl_mostrar_mensaje('Transferencia no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD r97_num_tran
			END IF
			LET rm_r95.r95_motivo = 'N'
			LET query = 'SELECT UNIQUE g01_razonsocial per_dest,',
					' g02_numruc per_id, TRIM(g02_nombre)',
					' || " " || TRIM(g02_direccion)',
					' punto_lleg ',
					' FROM rept019, rept002, gent002,',
						' gent001 ',
					' WHERE r19_compania  = ', vg_codcia,
					'   AND r19_localidad = ', vg_codloc,
					'   AND r19_cod_tran  ="',cod_tran2,'"',
					'   AND r19_num_tran  = ',
							rm_r97.r97_num_tran,
					'   AND r02_compania  = r19_compania ',
					'   AND r02_codigo    =r19_bodega_dest',
					'   AND g02_compania  = r02_compania ',
					'   AND g02_localidad = r02_localidad ',
					'   AND g01_compania  = g02_compania ',
					' INTO TEMP t1 '
			PREPARE tmp_dat FROM query
			EXECUTE tmp_dat
		END IF
		SELECT per_dest, per_id, punto_lleg
			INTO rm_r95.r95_persona_dest, rm_r95.r95_pers_id_dest,
				rm_r95.r95_punto_lleg
			FROM t1
		DROP TABLE t1
		DISPLAY BY NAME rm_r95.r95_persona_dest,rm_r95.r95_pers_id_dest,
				rm_r95.r95_punto_lleg
		CALL muestra_motivo()
	AFTER FIELD r95_fecha_initras
		IF rm_r95.r95_fecha_initras IS NULL THEN
			LET rm_r95.r95_fecha_initras = fecha_ini
			DISPLAY BY NAME rm_r95.r95_fecha_initras
		END IF
		IF rm_r95.r95_fecha_initras < vg_fecha THEN
			CALL fl_mostrar_mensaje('La fecha de iniciación del traslado no puede ser menor a la fecha de hoy.', 'exclamation')
			NEXT FIELD r95_fecha_initras
		END IF
	AFTER FIELD r95_num_sri
		IF LENGTH(rm_r95.r95_num_sri) < 14 THEN
			CALL fl_mostrar_mensaje('El número del SRI ingresado es incorrecto.', 'exclamation')
			NEXT FIELD r95_num_sri
		END IF
		IF rm_r95.r95_num_sri[1, 2] <> '00' OR
		   rm_r95.r95_num_sri[5, 6] <> '00' THEN
			CALL fl_mostrar_mensaje('El prefijo de venta o del local estan incorrectos en el número del SRI ingresado.', 'exclamation')
			NEXT FIELD r95_num_sri
		END IF
		IF rm_r95.r95_num_sri[4, 4] <> '-' OR
		   rm_r95.r95_num_sri[8, 8] <> '-' THEN
			CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
			NEXT FIELD r95_num_sri
		END IF
	AFTER FIELD r95_fecha_fintras
		IF rm_r95.r95_fecha_fintras IS NOT NULL THEN
			IF rm_r95.r95_fecha_fintras < vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha de terminación del traslado no puede ser menor a la fecha de hoy.', 'exclamation')
				NEXT FIELD r95_fecha_fintras
			END IF
		END IF
	AFTER FIELD r95_motivo
		CALL muestra_motivo()
		IF rm_r97.r97_cod_tran IS NULL THEN
			LET rm_r95.r95_motivo = 'N'
			DISPLAY BY NAME rm_r95.r95_motivo
		END IF
		IF rm_r95.r95_motivo = 'N' THEN
			LET rm_r95.r95_entre_local = 'S'
		ELSE
			LET rm_r95.r95_entre_local = 'N'
		END IF
	AFTER FIELD r95_fecha_emi
		IF rm_r95.r95_fecha_emi IS NULL THEN
			LET rm_r95.r95_fecha_emi = fecha_emi
			DISPLAY BY NAME rm_r95.r95_fecha_emi
		END IF
		IF rm_r95.r95_fecha_emi < vg_fecha THEN
			CALL fl_mostrar_mensaje('La fecha de emisión no puede ser menor a la fecha de hoy.', 'exclamation')
			NEXT FIELD r95_fecha_emi
		END IF
	AFTER FIELD r95_persona_id
		IF persona_id IS NOT NULL AND rm_r95.r95_persona_id IS NULL THEN
			LET rm_r95.r95_persona_id = persona_id
			DISPLAY BY NAME rm_r95.r95_persona_id
		END IF
		IF rm_r95.r95_persona_id IS NOT NULL THEN
			CALL fl_validar_cedruc_dig_ver(rm_r95.r95_persona_id)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r95_persona_id
			END IF
		END IF
	AFTER FIELD r95_pers_id_dest
		IF pers_id_dest IS NOT NULL AND rm_r95.r95_pers_id_dest IS NULL
		THEN
			LET rm_r95.r95_pers_id_dest = pers_id_dest
			DISPLAY BY NAME rm_r95.r95_pers_id_dest
		END IF
		IF rm_r95.r95_pers_id_dest IS NOT NULL THEN
			CALL fl_validar_cedruc_dig_ver(rm_r95.r95_pers_id_dest)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r95_pers_id_dest
			END IF
		END IF
	AFTER INPUT
		IF rm_r95.r95_fecha_fintras IS NOT NULL THEN
			IF rm_r95.r95_fecha_initras > rm_r95.r95_fecha_fintras
			THEN
				CALL fl_mostrar_mensaje('La fecha de iniciación del traslado no puede ser mayor a la fecha de terminación.', 'exclamation')
				NEXT FIELD r95_fecha_initras
			END IF
		END IF
END INPUT
IF NOT int_flag THEN
	CALL muestra_detalle('I')
END IF

END FUNCTION



FUNCTION factura_totalmente_dev(r_r19)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE tot_cant_fac	LIKE rept020.r20_cant_ven
DEFINE tot_cant_dev	LIKE rept020.r20_cant_ven

SELECT NVL(SUM(r20_cant_ven), 0)
	INTO tot_cant_fac
	FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = r_r19.r19_cod_tran
	  AND r20_num_tran  = r_r19.r19_num_tran
SELECT NVL(SUM(r20_cant_ven), 0)
	INTO tot_cant_dev
	FROM rept019, rept020
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_tipo_dev  = r_r19.r19_cod_tran
	  AND r19_num_dev   = r_r19.r19_num_tran
	  AND r20_compania  = r19_compania
	  AND r20_localidad = r19_localidad
	  AND r20_cod_tran  = r19_cod_tran
	  AND r20_num_tran  = r19_num_tran
IF tot_cant_fac = tot_cant_dev THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION tiene_nota_entrega(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE r_r36		RECORD LIKE rept036.*
DEFINE tiene		SMALLINT

DECLARE q_r34 CURSOR FOR
	SELECT * FROM rept034
		WHERE r34_compania  =  vg_codcia
		  AND r34_localidad =  vg_codloc
		  AND r34_cod_tran  =  cod_tran
		  AND r34_num_tran  =  num_tran
		  AND r34_estado    <> 'E'
LET tiene = 0
FOREACH q_r34 INTO r_r34.*
	DECLARE q_r36 CURSOR FOR
		SELECT * FROM rept036
			WHERE r36_compania    =  r_r34.r34_compania
			  AND r36_localidad   =  r_r34.r34_localidad
			  AND r36_bodega      =  r_r34.r34_bodega
			  AND r36_num_ord_des =  r_r34.r34_num_ord_des
			  AND r36_estado      <> 'E'
	OPEN q_r36
	FETCH q_r36 INTO r_r36.*
	IF STATUS <> NOTFOUND THEN
		LET tiene = 1
	END IF
	CLOSE q_r36
	FREE q_r36
	IF tiene THEN
		EXIT FOREACH
	END IF
END FOREACH
RETURN tiene

END FUNCTION



FUNCTION tiene_guia_remision(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE tiene		SMALLINT

IF cod_tran = cod_tran2 THEN
	SELECT * FROM rept097
		WHERE r97_compania  = vg_codcia
		  AND r97_localidad = vg_codloc
		  AND r97_cod_tran  = cod_tran
		  AND r97_num_tran  = num_tran
	IF STATUS = NOTFOUND THEN
		RETURN 0
	ELSE
		RETURN 1
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION lee_detalle()
DEFINE resp		CHAR(6)
DEFINE i, j, k, max_row	SMALLINT
DEFINE in_array		SMALLINT
DEFINE salir, num	SMALLINT
DEFINE item_anterior	LIKE rept020.r20_item
DEFINE r_r10		RECORD LIKE rept010.*

LET vm_size_arr = fgl_scr_size('rm_guia')
LET i = 1          
LET j = 1        
LET salir    = 0 
LET in_array = 0
WHILE NOT salir
	LET int_flag = 0
	CALL set_count(vm_ind_arr) 
	INPUT ARRAY rm_guia WITHOUT DEFAULTS FROM rm_guia.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp      
			IF resp = 'Yes' THEN
				LET int_flag = 1
				LET salir    = 1 
				EXIT INPUT
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			IF in_array THEN              
				--#CALL dialog.setcurrline(j, k)
				LET i = k      # POSICION CORRIENTE EN EL ARRAY
				LET in_array = 0     
				NEXT FIELD r20_item 
			END IF                     
		BEFORE ROW
			LET i = arr_curr()  # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()  # POSICION CORRIENTE EN LA PANTALLA
			LET max_row = arr_count()
			IF i > max_row THEN
				LET max_row = max_row + 1
			END IF
			LET item_anterior = rm_guia[i].r20_item  
			IF rm_guia[i].r20_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, rm_guia[i].r20_item)
					RETURNING r_r10.*
				CALL muestra_etiquetas_det(i, max_row, i)
			ELSE
				CLEAR nom_item, descrip_3, nom_marca
			END IF
			LET num = arr_count()
		AFTER DELETE	                                   
			LET k = i - j + 1                         
		BEFORE FIELD r20_item                       
			LET item_anterior = rm_guia[i].r20_item  
		AFTER FIELD r20_item, r20_cant_ven                
	    		IF rm_guia[i].r20_item IS NULL AND
	    		   rm_guia[i].r20_cant_ven IS NOT NULL THEN
	    		   	LET rm_guia[i].r20_cant_ven = NULL
				CLEAR rm_guia[j].r20_cant_ven
                       		CALL fl_mostrar_mensaje('Digite item primero.','exclamation')
                       		NEXT FIELD r20_item
			END IF
	    		IF rm_guia[i].r20_item IS NOT NULL THEN
     				CALL fl_lee_item(vg_codcia, rm_guia[i].r20_item)
					RETURNING r_r10.*            
                       		IF r_r10.r10_codigo IS NULL THEN    
                       			CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                       			NEXT FIELD r20_item
                       		END IF	 	
				CALL muestra_etiquetas_det(i, max_row, i)
                       		IF r_r10.r10_estado = 'B' THEN           
                       			CALL fl_mostrar_mensaje('El Item está con status bloqueado.','exclamation')           
                       			NEXT FIELD r20_item 
                       		END IF                     
                       	END IF                     
		AFTER ROW
			IF NOT numero_filas_correcto(arr_count()) THEN
				LET int_flag = int_flag
			END IF
		AFTER INPUT
			LET k = i - j + 1                  
			IF NOT numero_filas_correcto(arr_count()) THEN
				NEXT FIELD r20_item
			END IF
			LET vm_ind_arr = arr_count()
			LET salir = 1 
	END INPUT 
	IF salir THEN
		EXIT WHILE
	END IF
END WHILE          

END FUNCTION



FUNCTION numero_filas_correcto(k) 
DEFINE k		INTEGER

IF k > rm_r00.r00_numlin_fact THEN
	CALL fl_mostrar_mensaje('El número de líneas máximo permitido por factura/proforma es de '||rm_r00.r00_numlin_fact|| '.' || ' Elimine líneas o abandone el ingreso.','exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r95.* FROM rept095 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', row
END IF
INITIALIZE rm_r97.* TO NULL
SELECT * INTO rm_r97.*
	FROM rept097
	WHERE r97_compania      = rm_r95.r95_compania
	  AND r97_localidad     = rm_r95.r95_localidad
	  AND r97_guia_remision = rm_r95.r95_guia_remision
	  AND r97_cod_tran      = cod_tran1
DISPLAY BY NAME rm_r95.r95_guia_remision, rm_r95.r95_estado,rm_r97.r97_cod_tran,
		rm_r97.r97_num_tran, rm_r95.r95_num_sri, rm_r95.r95_autoriz_sri,
		rm_r95.r95_fecha_initras, rm_r95.r95_fecha_fintras,
		rm_r95.r95_motivo,rm_r95.r95_fecha_emi, rm_r95.r95_punto_part,
		rm_r95.r95_persona_guia, rm_r95.r95_persona_dest,
		rm_r95.r95_persona_id, rm_r95.r95_placa,rm_r95.r95_pers_id_dest,
		rm_r95.r95_punto_lleg, rm_r95.r95_usuario, rm_r95.r95_fecing
CALL muestra_estado()
CALL muestra_motivo()
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_detalle('C')

END FUNCTION



FUNCTION muestra_detalle(flag)
DEFINE flag		CHAR(1)
DEFINE query 		CHAR(1500)
DEFINE tot_lineas, i	SMALLINT
DEFINE cod_tran		LIKE rept020.r20_cod_tran
DEFINE orden		LIKE rept020.r20_orden

LET vm_size_arr = fgl_scr_size('rm_guia')
FOR i = 1 TO vm_size_arr
	INITIALIZE rm_guia[i].*, rm_aux[i].* TO NULL
	CLEAR rm_guia[i].*
END FOR
CASE flag
	WHEN 'I'
		SELECT * FROM rept034, rept036
			WHERE r34_compania    = vg_codcia
			  AND r34_localidad   = vg_codloc
			  AND r34_cod_tran    = rm_r97.r97_cod_tran
			  AND r34_num_tran    = rm_r97.r97_num_tran
			  AND r36_compania    = r34_compania
			  AND r36_localidad   = r34_localidad
			  AND r36_bodega      = r34_bodega
			  AND r36_num_ord_des = r34_num_ord_des
			INTO TEMP tmp_r96
		SELECT r20_compania r96_compania, r20_localidad r96_localidad,
			r36_bodega_real, r36_num_ord_des, r36_num_entrega
			r96_num_entrega, r20_cod_tran r97_cod_tran,
			r20_num_tran r97_num_tran, r20_bodega r96_bodega
			FROM rept020, OUTER tmp_r96
			WHERE r20_compania    = vg_codcia
			  AND r20_localidad   = vg_codloc
			  AND r20_cod_tran    = rm_r97.r97_cod_tran
			  AND r20_num_tran    = rm_r97.r97_num_tran
			  AND r34_compania    = r20_compania
			  AND r34_localidad   = r20_localidad
			  AND r34_cod_tran    = r20_cod_tran
			  AND r34_num_tran    = r20_num_tran
			INTO TEMP tmp_guia
	WHEN 'C'
		SELECT * FROM rept096, rept036
			WHERE r96_compania      = vg_codcia
			  AND r96_localidad     = vg_codloc
			  AND r96_guia_remision = rm_r95.r95_guia_remision
			  AND r36_compania      = r96_compania
			  AND r36_localidad     = r96_localidad
			  AND r36_bodega        = r96_bodega
			  AND r36_num_entrega   = r96_num_entrega
			INTO TEMP tmp_r96
		SELECT r96_compania, r96_localidad, r36_bodega_real,
			r36_num_ord_des, r96_num_entrega, r97_cod_tran,
			r97_num_tran, r96_bodega
			FROM rept097, OUTER tmp_r96
			WHERE r97_compania      = vg_codcia
			  AND r97_localidad     = vg_codloc
			  AND r97_guia_remision = rm_r95.r95_guia_remision
			  AND r96_compania      = r97_compania
			  AND r96_localidad     = r97_localidad
			  AND r96_guia_remision = r97_guia_remision
			INTO TEMP tmp_guia
END CASE
DROP TABLE tmp_r96
LET query = 'SELECT r97_cod_tran, r97_num_tran, r36_bodega_real, ',
		'r36_num_ord_des, r96_num_entrega, r37_item, ',
		'NVL(SUM(r37_cant_ent), 0) r37_cant_ent, r10_uni_med, ',
		'r10_nombre, r96_bodega ',
		' FROM tmp_guia, rept037, rept010 ',
		' WHERE r37_compania    = r96_compania ',
		'   AND r37_localidad   = r96_localidad ',
		'   AND r37_bodega      = r96_bodega ',
		'   AND r37_num_entrega = r96_num_entrega ',
		'   AND r10_compania    = r37_compania ',
		'   AND r10_codigo      = r37_item ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 8, 9, 10 ',
		' ORDER BY r36_num_ord_des, r96_num_entrega '
SELECT UNIQUE r97_cod_tran INTO cod_tran FROM tmp_guia
IF cod_tran = cod_tran2 THEN
	LET query = 'SELECT r97_cod_tran, r97_num_tran, r20_bodega, ',
			'"" r36_num_ord_des, "" r96_num_entrega, r20_item, ',
			'r20_cant_ven, r10_uni_med, r10_nombre, r20_bodega ',
			'bodega, r20_orden ',
			' FROM rept097, rept020, rept010 ',
			' WHERE r97_compania      = ', vg_codcia,
			'   AND r97_localidad     = ', vg_codloc,
			'   AND r97_cod_tran      = "', cod_tran, '"',
			'   AND r97_guia_remision = ', rm_r95.r95_guia_remision,
			'   AND r20_compania      = r97_compania ',
			'   AND r20_localidad     = r97_localidad ',
			'   AND r20_cod_tran      = r97_cod_tran ',
			'   AND r20_num_tran      = r97_num_tran ',
			'   AND r10_compania      = r20_compania ',
			'   AND r10_codigo        = r20_item ',
			' ORDER BY r20_orden '
END IF
LET query = query CLIPPED, ' INTO TEMP t1 '
PREPARE tmp_t1 FROM query
EXECUTE tmp_t1
DROP TABLE tmp_guia
SELECT COUNT(*) INTO tot_lineas FROM t1
IF tot_lineas = 0 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('Guía de Remisión no tiene detalle.', 'exclamation')
	RETURN
END IF
DECLARE q_guia CURSOR FOR SELECT * FROM t1
LET i = 1
FOREACH q_guia INTO rm_guia[i].*, rm_aux[i].*, orden
	LET i = i + 1
        IF i > vm_elementos THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	DROP TABLE t1
	CALL fl_mostrar_mensaje('Guía de Remisión no tiene detalle.', 'exclamation')
	LET i = 0
	CLEAR FORM
	CALL control_mostrar_botones()
	RETURN
END IF
LET vm_ind_arr = i
IF vm_ind_arr <= vm_size_arr THEN 
	LET vm_size_arr = vm_ind_arr
END IF 
FOR i = 1 TO vm_size_arr 
	DISPLAY rm_guia[i].* TO rm_guia[i].*
END FOR 
CALL muestra_etiquetas_det(0, vm_ind_arr, 1)
DROP TABLE t1

END FUNCTION



FUNCTION control_ver_detalle()
DEFINE i, j, ver_trans	SMALLINT
DEFINE ver_fact		SMALLINT

LET i = 0
IF vg_gui = 0 THEN
	LET i = 1
END IF
CALL muestra_contadores_det(i, vm_ind_arr)
CALL set_count(vm_ind_arr)
DISPLAY ARRAY rm_guia TO rm_guia.*
        ON KEY(INTERRUPT)
		CALL muestra_etiquetas_det(0, vm_ind_arr, 1)
		LET int_flag = 1
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		IF rm_r97.r97_compania IS NOT NULL THEN
			CALL control_ver_transaccion(0)
			LET int_flag = 0
		END IF
	ON KEY(F6)
		IF rm_r97.r97_compania IS NULL THEN
			LET i = arr_curr()
			CALL control_ver_transaccion(i)
			LET int_flag = 0
		END IF
	ON KEY(F7)
		IF rm_r97.r97_compania IS NOT NULL THEN
			LET i = arr_curr()
			CALL ver_orden_despacho(i)
			LET int_flag = 0
		END IF
	ON KEY(F8)
		IF rm_r97.r97_compania IS NOT NULL THEN
			LET i = arr_curr()
			CALL ver_nota_entrega(i)
			LET int_flag = 0
		END IF
	ON KEY(F9)
        	CALL imprimir()
		LET int_flag = 0
	ON KEY(RETURN)
		LET i = arr_curr()
        	LET j = scr_line()
		CALL muestra_etiquetas_det(i, vm_ind_arr, i)
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel('RETURN','')
	--#BEFORE ROW
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_etiquetas_det(i, vm_ind_arr, i)
		--#IF rm_r97.r97_compania IS NOT NULL THEN
			--#CALL dialog.keysetlabel("F5","Factura")
			--#CALL dialog.keysetlabel("F6","")
			--#CALL dialog.keysetlabel("F7","Orden Despacho")
			--#CALL dialog.keysetlabel("F8","Nota de Entrega")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","")
			--#CALL dialog.keysetlabel("F6","Transferencia")
			--#CALL dialog.keysetlabel("F7","")
			--#CALL dialog.keysetlabel("F8","")
		--#END IF
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY
CALL muestra_contadores_det(0, vm_ind_arr)

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



FUNCTION muestra_etiquetas_det(i, ind1, ind2)
DEFINE i, ind1, ind2	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, ind1)
CALL fl_lee_item(vg_codcia, rm_guia[ind2].r20_item) RETURNING r_r10.*  
CALL muestra_descripciones(rm_guia[ind2].r20_item, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
DISPLAY r_r10.r10_nombre TO nom_item 

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO descrip_3
DISPLAY r_r10.r10_marca      TO nom_marca

END FUNCTION



FUNCTION muestra_estado()
DEFINE tit_estado	VARCHAR(15)

LET tit_estado = NULL
CASE rm_r95.r95_estado
	WHEN 'A' LET tit_estado = 'ACTIVA'
	WHEN 'C' LET tit_estado = 'CERRADA'
	WHEN 'E' LET tit_estado = 'ELIMINADA'
END CASE
DISPLAY BY NAME rm_r95.r95_estado, tit_estado

END FUNCTION



FUNCTION muestra_motivo()
DEFINE tit_motivo	VARCHAR(35)

LET tit_motivo = NULL
CASE rm_r95.r95_motivo
	WHEN 'V' LET tit_motivo = 'VENTA'
	WHEN 'D' LET tit_motivo = 'DEVOLUCION'
	WHEN 'I' LET tit_motivo = 'IMPORTACION'
	WHEN 'N' LET tit_motivo = 'TRANSFERENCIAS ENTRE LOCALIDADES'
END CASE
DISPLAY BY NAME rm_r95.r95_motivo, tit_motivo

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_mostrar_botones()

--#DISPLAY "TP"			TO tit_col1
--#DISPLAY "Número"		TO tit_col2
--#DISPLAY "BD"			TO tit_col3
--#DISPLAY "Ord. D."		TO tit_col4
--#DISPLAY "N. Ent."		TO tit_col5
--#DISPLAY "Item"		TO tit_col6
--#DISPLAY "Cantidad"		TO tit_col7
--#DISPLAY "U. Med."		TO tit_col8
--#DISPLAY "Descripción"	TO tit_col9

END FUNCTION



FUNCTION control_ver_transaccion(i)
DEFINE i		SMALLINT
DEFINE cod_tran		LIKE rept097.r97_cod_tran
DEFINE num_tran		LIKE rept097.r97_num_tran

LET cod_tran = rm_r97.r97_cod_tran
LET num_tran = rm_r97.r97_num_tran
IF i > 0 THEN
	LET cod_tran = cod_tran2
	LET num_tran = rm_guia[i].r20_num_tran
END IF
CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc, cod_tran, num_tran)

END FUNCTION



FUNCTION ver_orden_despacho(i)
DEFINE i		SMALLINT
DEFINE run_prog		CHAR(10)
DEFINE comando		VARCHAR(200)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando  = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog CLIPPED,
		' repp231 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' "', rm_guia[i].r20_cod_tran, '" ',
		rm_guia[i].r20_num_tran, ' "C" "T" "', rm_aux[i].r36_bodega,
		'" ', rm_guia[i].r36_num_ord_des
RUN comando

END FUNCTION


 
FUNCTION ver_nota_entrega(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog, 'repp314 ',
		vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' "',
		rm_aux[i].r36_bodega, '" ', rm_guia[i].r36_num_entrega, ' "E"'
RUN comando

END FUNCTION



FUNCTION imprimir()
DEFINE run_prog		CHAR(10)
DEFINE comando		VARCHAR(200)
DEFINE cod_tran		LIKE rept097.r97_cod_tran

LET cod_tran = rm_r97.r97_cod_tran
IF rm_r97.r97_compania IS NULL THEN
	LET cod_tran = cod_tran2
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando  = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS',
		vg_separador, 'fuentes', vg_separador, run_prog CLIPPED,
		' repp434 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' ',
		vg_codloc, ' ', rm_r95.r95_guia_remision, ' "', cod_tran, '" '
RUN comando

END FUNCTION



FUNCTION mostrar_notas_entrega()
DEFINE r_nota		RECORD
				r36_num_ord_des	LIKE rept036.r36_num_ord_des,
				r36_bodega	LIKE rept036.r36_bodega,
				r36_num_entrega	LIKE rept036.r36_num_entrega,
				r36_bodega_real	LIKE rept036.r36_bodega_real,
				r36_fec_entrega	LIKE rept036.r36_fec_entrega,
				r36_entregar_a	LIKE rept036.r36_entregar_a,
				total_ne	DECIMAL(8,2),
				seleccionar_ne	CHAR(1)
			END RECORD
DEFINE i, j, cont	SMALLINT
DEFINE col_ini, salir	SMALLINT
DEFINE fil_max		SMALLINT
DEFINE col_max		SMALLINT
DEFINE cant_dev		DECIMAL(8,2)
DEFINE total		DECIMAL(8,2)
DEFINE r_r19		RECORD LIKE rept019.*

CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, rm_r97.r97_cod_tran,
					rm_r97.r97_num_tran)
	RETURNING r_r19.*
DECLARE q_notas CURSOR FOR
	SELECT r36_num_ord_des, r36_bodega, r36_num_entrega, r36_bodega_real,
		r36_fec_entrega, r36_entregar_a, NVL(SUM(r37_cant_ent), 0), "N"
 		FROM rept034, rept036, rept037
		WHERE r34_compania    =  vg_codcia
		  AND r34_localidad   =  vg_codloc
		  AND r34_cod_tran    =  r_r19.r19_cod_tran
		  AND r34_num_tran    =  r_r19.r19_num_tran
		  AND r34_estado      <> 'E'
		  AND r36_compania    =  r34_compania
		  AND r36_localidad   =  r34_localidad
		  AND r36_bodega      =  r34_bodega
		  AND r36_num_ord_des =  r34_num_ord_des
		  AND r37_compania    =  r36_compania
		  AND r37_localidad   =  r36_localidad
		  AND r37_bodega      =  r36_bodega
		  AND r37_num_entrega =  r36_num_entrega
		GROUP BY 1, 2, 3, 4, 5, 6, 8
		ORDER BY r36_fec_entrega DESC
LET i     = 1
LET total = 0
FOREACH q_notas INTO r_nota.*
	LET cant_dev = 0
	IF r_r19.r19_tipo_dev = 'DF' THEN
		SELECT NVL(SUM(r20_cant_ven), 0)
			INTO cant_dev
			FROM rept036, rept037, rept034, rept019, rept020
			WHERE r36_compania    = vg_codcia
			  AND r36_localidad   = vg_codloc
			  AND r36_bodega      = r_nota.r36_bodega
			  AND r36_num_entrega = r_nota.r36_num_entrega
			  AND r37_compania    = r36_compania
			  AND r37_localidad   = r36_localidad
			  AND r37_bodega      = r36_bodega
			  AND r37_num_entrega = r36_num_entrega
			  AND r34_compania    = r36_compania
			  AND r34_localidad   = r36_localidad
			  AND r34_bodega      = r36_bodega
			  AND r34_num_ord_des = r36_num_ord_des
			  AND r19_compania    = r34_compania
			  AND r19_localidad   = r34_localidad
			  AND r19_cod_tran    = r34_cod_tran
			  AND r19_num_tran    = r34_num_tran
			  AND r19_tipo_dev    = 'DF'
			  AND r20_compania    = r19_compania
			  AND r20_localidad   = r19_localidad
			  AND r20_cod_tran    = r19_tipo_dev
			  AND r20_num_tran    = r19_num_dev
			  AND r20_bodega      = r37_bodega
			  AND r20_item        = r37_item
	END IF
	LET rm_nota[i].r36_num_ord_des = r_nota.r36_num_ord_des
	LET rm_nota[i].r36_bodega      = r_nota.r36_bodega
	LET rm_nota[i].r36_num_entrega = r_nota.r36_num_entrega
	LET rm_nota[i].r36_bodega_real = r_nota.r36_bodega_real
	LET rm_nota[i].r36_fec_entrega = r_nota.r36_fec_entrega
	LET rm_nota[i].r36_entregar_a  = r_nota.r36_entregar_a
	LET rm_nota[i].total_ne        = r_nota.total_ne - cant_dev
	LET rm_nota[i].seleccionar_ne  = r_nota.seleccionar_ne
	LET total                      = total + rm_nota[i].total_ne
	LET i = i + 1
	IF i > vm_max_not THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	RETURN
END IF
LET vm_num_not = i
LET col_ini    = 05
LET fil_max    = 18
LET col_max    = 72
IF vg_gui = 0 THEN
	LET col_ini = 02
	LET fil_max = 16
	LET col_max = 74
END IF
OPEN WINDOW w_repf241_2 AT 04, col_ini WITH fil_max ROWS, col_max COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf241_2 FROM '../forms/repf241_2'
ELSE
	OPEN FORM f_repf241_2 FROM '../forms/repf241_2c'
END IF
DISPLAY FORM f_repf241_2
--#DISPLAY "Ord. D."		TO tit_col1
--#DISPLAY "BD"			TO tit_col2
--#DISPLAY "Not. E."		TO tit_col3
--#DISPLAY "BE"			TO tit_col4
--#DISPLAY "Fecha Ent."		TO tit_col5
--#DISPLAY "Entregado A"	TO tit_col6
--#DISPLAY "Cantidad"		TO tit_col7
--#DISPLAY "C"			TO tit_col8
DISPLAY BY NAME r_r19.r19_codcli, r_r19.r19_nomcli, r_r19.r19_cod_tran,
		r_r19.r19_num_tran, r_r19.r19_fecing, total
OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
LET salir = 1
WHILE salir
	LET int_flag = 0
	CALL set_count(vm_num_not)
	INPUT ARRAY rm_nota WITHOUT DEFAULTS FROM rm_nota.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CONTINUE INPUT
       		ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_num_not)
		BEFORE INSERT
			EXIT INPUT
		AFTER INPUT
			LET cont = 0
			FOR i = 1 TO vm_num_not
				IF rm_nota[i].seleccionar_ne = 'N' THEN
					LET cont = cont + 1
				END IF
			END FOR
			IF cont = vm_num_not THEN
				CALL fl_mostrar_mensaje('Al menos debe seleccionar una Nota de Entrega.', 'exclamation')
				CONTINUE INPUT
			END IF
			LET salir = 0
	END INPUT
	IF NOT salir THEN
		EXIT WHILE
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf241_2
RETURN

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



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Factura'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Transferencia'            AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Orden Despacho'           AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Nota de Entrega'          AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F9>      Imprimir Guía Remisión'   AT a,2
DISPLAY  'F9' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
