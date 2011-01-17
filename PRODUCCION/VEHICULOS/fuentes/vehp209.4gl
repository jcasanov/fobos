------------------------------------------------------------------------------
-- Titulo           : vehp209.4gl - Reservacion de Vehículos     
-- Elaboracion      : 26-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp209 base modulo compania localidad [num_reserv]
--		Si (num_reserv <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (num_reserv = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_num_reserv	LIKE veht033.v33_num_reserv

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v33		RECORD LIKE veht033.*

-- SOLO TIENE UN VALOR UTIL PARA LA MODIFICACION 
DEFINE vm_cod_ant	LIKE veht033.v33_codigo_veh 
				



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp209'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_num_reserv = 0
IF num_args() = 5 THEN
	LET vm_num_reserv  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_209 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_209 FROM '../forms/vehf209_1'
DISPLAY FORM f_209

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v33.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 1000

IF vm_num_reserv <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Eliminar'
		IF vm_num_reserv <> 0 THEN         -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
		    END IF
			IF fl_control_permiso_opcion('Eliminar') THEN			
				SHOW OPTION 'Eliminar'
		    END IF

		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
	COMMAND KEY('E') 'Eliminar'		'Eliminar un registro.'
		CALL control_eliminar()	
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
		    END IF
			IF fl_control_permiso_opcion('Eliminar') THEN			
				SHOW OPTION 'Eliminar'
		    END IF
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Eliminar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
		    END IF
			IF fl_control_permiso_opcion('Eliminar') THEN			
				SHOW OPTION 'Eliminar'
		    END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
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
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE resp 		CHAR(6)
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE row_curr		SMALLINT

CLEAR FORM
INITIALIZE rm_v33.* TO NULL

LET rm_v33.v33_fecing    = CURRENT
LET rm_v33.v33_usuario   = vg_usuario
LET rm_v33.v33_compania  = vg_codcia
LET rm_v33.v33_localidad = vg_codloc

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

SELECT MAX(v33_num_reserv) 
	INTO rm_v33.v33_num_reserv
	FROM veht033
	WHERE v33_compania  = vg_codcia
	  AND v33_localidad = vg_codloc
IF rm_v33.v33_num_reserv IS NULL THEN
	LET rm_v33.v33_num_reserv = 1 
ELSE
	LET rm_v33.v33_num_reserv = rm_v33.v33_num_reserv + 1 
END IF

INSERT INTO veht033 VALUES (rm_v33.*)
DISPLAY BY NAME rm_v33.v33_num_reserv

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada
CALL actualiza_serie('R', rm_v33.v33_codigo_veh) RETURNING done
IF done = 0 THEN
	ROLLBACK WORK
	LET vm_num_rows = vm_num_rows - 1
	LET vm_row_current = row_curr
	CLEAR FORM       
	RETURN
END IF
COMMIT WORK

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht033 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v33.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

-- POR SI ACASO CAMBIAN LA SERIE PARA LA CUAL SE HIZO LA RESERVACION
LET vm_cod_ant = rm_v33.v33_codigo_veh

CALL lee_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE veht033 SET * = rm_v33.* WHERE CURRENT OF q_upd

IF rm_v33.v33_codigo_veh = vm_cod_ant THEN
	CALL actualiza_serie('A', vm_cod_ant) RETURNING done
	IF done = 0 THEN
		ROLLBACK WORK
		CLEAR FORM       
		RETURN
	END IF
	CALL actualiza_serie('R', rm_v33.v33_codigo_veh) RETURNING done
	IF done = 0 THEN
		ROLLBACK WORK
		CLEAR FORM       
		RETURN
	END IF
END IF
COMMIT WORK
CLOSE q_upd
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)

DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE continuar  	SMALLINT

DEFINE cliente 		LIKE veht033.v33_codcli

DEFINE r_serveh RECORD
        codigo_veh          LIKE veht022.v22_codigo_veh,
        chasis              LIKE veht022.v22_chasis,
        modelo              LIKE veht022.v22_modelo,
        cod_color           LIKE veht022.v22_cod_color,
        bodega              LIKE veht022.v22_bodega
        END RECORD

DEFINE vendedor 	LIKE veht001.v01_vendedor,
       nom_vendedor	LIKE veht001.v01_nombres

DEFINE cod_cobranzas	LIKE cxct001.z01_codcli,
       nom_cliente	LIKE cxct001.z01_nomcli

DEFINE tipo_doc		LIKE cxct004.z04_tipo_doc,
       nom_doc		LIKE cxct004.z04_nombre

DEFINE valor_min	LIKE veht022.v22_precio

DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_v32		RECORD LIKE veht032.*
DEFINE r_cligen		RECORD LIKE cxct001.*

DEFINE r_favorcob RECORD
        nomcli          LIKE cxct001.z01_nomcli,
        tipo_doc        LIKE cxct021.z21_tipo_doc,
        num_doc         LIKE cxct021.z21_num_doc,
        saldo           LIKE cxct021.z21_saldo,
	moneda		LIKE gent013.g13_moneda,
        abreviacion     LIKE gent003.g03_abreviacion
END RECORD

LET INT_FLAG = 0
INPUT BY NAME rm_v33.v33_num_reserv, rm_v33.v33_codigo_veh, rm_v33.v33_nota,
	      rm_v33.v33_vendedor, rm_v33.v33_codcli, rm_v33.v33_moneda_doc,
	      rm_v33.v33_tipo_doc, rm_v33.v33_num_doc, rm_v33.v33_val_doc, 
              rm_v33.v33_usuario, rm_v33.v33_fecing WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_v33.v33_num_reserv, 
                                     rm_v33.v33_codigo_veh, rm_v33.v33_nota,
	                             rm_v33.v33_vendedor, rm_v33.v33_codcli, 
                                     rm_v33.v33_moneda_doc, rm_v33.v33_tipo_doc,
                                     rm_v33.v33_num_doc, rm_v33.v33_val_doc 
                                    ) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF INFIELD(v33_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, '00') 
				RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_v33.v33_codigo_veh = r_serveh.codigo_veh
				DISPLAY BY NAME rm_v33.v33_codigo_veh
				DISPLAY r_serveh.chasis TO serie_veh	
			END IF
		END IF
		IF INFIELD(v33_vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING vendedor, nom_vendedor
			IF vendedor IS NOT NULL THEN
				LET rm_v33.v33_vendedor = vendedor
				DISPLAY BY NAME rm_v33.v33_vendedor
				DISPLAY nom_vendedor TO n_vendedor
			END IF
		END IF
            	IF INFIELD(v33_codcli) THEN
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc) 
				RETURNING cod_cobranzas, nom_cliente
                  	LET rm_v33.v33_codcli = cod_cobranzas
                 	DISPLAY BY NAME rm_v33.v33_codcli  
			DISPLAY nom_cliente TO n_cliente
            	END IF
		IF INFIELD(v33_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('F') 
				RETURNING tipo_doc, nom_doc
			IF tipo_doc IS NOT NULL THEN
				LET rm_v33.v33_tipo_doc = tipo_doc
				DISPLAY BY NAME rm_v33.v33_tipo_doc
				DISPLAY nom_doc TO n_documento
			END IF
		END IF
		IF INFIELD(v33_num_doc) THEN
			IF rm_v33.v33_tipo_doc IS NULL THEN
				CALL fl_ayuda_doc_favor_cob(vg_codcia, 
					vg_codloc, rg_mod.g50_areaneg_def,
					rm_v33.v33_codcli, '00')
						RETURNING r_favorcob.*
			ELSE
				CALL fl_ayuda_doc_favor_cob(vg_codcia, 
					vg_codloc, rg_mod.g50_areaneg_def,
					rm_v33.v33_codcli, rm_v33.v33_tipo_doc)
						RETURNING r_favorcob.*
			END IF
			IF r_favorcob.num_doc IS NOT NULL THEN
				LET rm_v33.v33_num_doc  = r_favorcob.num_doc
				LET rm_v33.v33_tipo_doc = r_favorcob.tipo_doc
				LET rm_v33.v33_moneda_doc = r_favorcob.moneda
				LET rm_v33.v33_val_doc  = r_favorcob.saldo
				DISPLAY BY NAME rm_v33.v33_num_doc
				DISPLAY BY NAME rm_v33.v33_tipo_doc
				DISPLAY BY NAME rm_v33.v33_moneda_doc
				DISPLAY BY NAME rm_v33.v33_val_doc
			END IF
			CALL muestra_etiquetas()
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v33_codigo_veh
		IF rm_v33.v33_codigo_veh IS NULL THEN
			CLEAR serie_veh
		ELSE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					rm_v33.v33_codigo_veh)
						RETURNING r_v22.*
			IF r_v22.v22_chasis IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Serie no existe',
                                                    'exclamation')
				CLEAR serie_veh 
				NEXT FIELD v33_codigo_veh
			ELSE
				LET continuar = 1
				IF r_v22.v22_estado = 'F' THEN
					CALL fgl_winmessage(vg_producto,
							    'Esta serie ya ' ||
							    'ha sido facturada',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'P' OR 
				   r_v22.v22_estado = 'M' THEN
					CALL fgl_winmessage(vg_producto,
							    'No se puede '||
							    'reservar esta ' ||
                                                            'serie',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Serie bloqueada',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'R' AND  
				   rm_v33.v33_codigo_veh <> vm_cod_ant THEN
					CALL fgl_winmessage(vg_producto,
							    'Esta serie ya ' ||
                                   			    'ha sido reservada',                                                            'exclamation')
					LET continuar = 0
				END IF 
				IF continuar = 0 THEN
					CLEAR serie_veh 
					NEXT FIELD v33_codigo_veh
				END IF
				DISPLAY r_v22.v22_chasis TO serie_veh	
			END IF
		END IF
	AFTER FIELD v33_vendedor
		IF rm_v33.v33_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_v33.v33_vendedor)
				RETURNING r_v01.*
			IF r_v01.v01_vendedor IS NOT NULL THEN
				IF r_v01.v01_estado <> 'B' THEN
					DISPLAY r_v01.v01_nombres TO n_vendedor
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Vendedor está ' ||
                                                            'bloqueado',
							    'exclamation')
					CLEAR n_vendedor
					NEXT FIELD v33_vendedor
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Vendedor no existe',
						    'exclamation')
				CLEAR n_vendedor
				NEXT FIELD v33_vendedor
			END IF
		ELSE
			CLEAR n_vendedor
		END IF		 
	BEFORE FIELD v33_codcli
		LET cliente = rm_v33.v33_codcli
	AFTER FIELD v33_codcli
		IF rm_v33.v33_codcli IS NULL THEN
			CLEAR n_cliente
			INITIALIZE rm_v33.v33_tipo_doc TO NULL
			INITIALIZE rm_v33.v33_num_doc TO NULL
			INITIALIZE rm_v33.v33_val_doc TO NULL
			DISPLAY BY NAME rm_v33.v33_tipo_doc
			DISPLAY BY NAME rm_v33.v33_num_doc
			DISPLAY BY NAME rm_v33.v33_val_doc
			CLEAR n_documento
			ERROR 'Debe ingresar un cliente para continuar'
			NEXT FIELD v33_codcli
		ELSE
			IF cliente <> rm_v33.v33_codcli THEN
				INITIALIZE rm_v33.v33_tipo_doc TO NULL
				INITIALIZE rm_v33.v33_num_doc TO NULL
				INITIALIZE rm_v33.v33_val_doc TO NULL
				DISPLAY BY NAME rm_v33.v33_tipo_doc
				DISPLAY BY NAME rm_v33.v33_num_doc
				DISPLAY BY NAME rm_v33.v33_val_doc
				CLEAR n_documento
			END IF
			CALL fl_lee_cliente_general(rm_v33.v33_codcli) 
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente '||
                                                    'con ese código',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD v33_codcli
        		END IF   
			IF r_cligen.z01_estado = 'B' THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'El cliente '||
                                                    'está bloqueado',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD v33_codcli
			END IF
			LET rm_v33.v33_codcli = r_cligen.z01_codcli
        		DISPLAY BY NAME rm_v33.v33_codcli
			DISPLAY r_cligen.z01_nomcli TO n_cliente
		END IF
	AFTER FIELD v33_tipo_doc
		IF rm_v33.v33_tipo_doc IS NULL THEN
			CLEAR n_documento
		ELSE
			IF rm_v33.v33_tipo_doc <> 'PA' AND 
                           rm_v33.v33_tipo_doc <> 'NC' THEN
				CALL fgl_winmessage(vg_producto,
						    'El tipo de documento ' ||
                                                    'debe ser PA: Pago ' ||
						    'Anticipado o NC: Nota ' ||
						    'de Crédito',
						    'exclamation')
				CLEAR n_documento
				NEXT FIELD v33_tipo_doc
			END IF
			CALL fl_lee_tipo_doc(rm_v33.v33_tipo_doc) 
				RETURNING r_z04.*
			IF r_z04.z04_tipo_doc IS NULL THEN	
				CALL fgl_winmessage(vg_producto,
                                                    'Tipo de documento no ' ||
                                                    'existe',
						    'exclamation')
				CLEAR n_documento
				NEXT FIELD v33_tipo_doc
			ELSE
				IF r_z04.z04_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Tipo de ' ||
							    'documento ' ||
							    'está bloqueado',
							    'exclamation')
					CLEAR n_documento
					NEXT FIELD v33_tipo_doc
				END IF 
				DISPLAY r_z04.z04_nombre TO n_documento
			END IF 
		END IF
	BEFORE FIELD v33_num_doc 
		IF rm_v33.v33_codcli IS NULL THEN
			NEXT FIELD v33_codigo_veh 
		END IF
	AFTER INPUT
		INITIALIZE r_v32.* TO NULL
		SELECT veht032.* INTO r_v32.* FROM veht020, veht032
			WHERE v20_compania = vg_codcia
			  AND v20_modelo   = r_v22.v22_modelo
			  AND v32_compania = v20_compania
			  AND v32_linea    = v20_linea
		IF r_v32.v32_compania IS NOT NULL THEN
			LET valor_min = 
				r_v22.v22_precio * r_v32.v32_porc_min / 100 
			IF rm_v33.v33_val_doc < valor_min THEN
				CALL fgl_winmessage(vg_producto,
					'El anticipo debe ser el ' ||
					r_v32.v32_porc_min || 
					'% del valor del ' ||
					'vehículo.',
					'exclamation')
				CONTINUE INPUT
			END IF 
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_serveh RECORD
        codigo_veh          LIKE veht022.v22_codigo_veh,
        chasis              LIKE veht022.v22_chasis,
        modelo              LIKE veht022.v22_modelo,
        cod_color           LIKE veht022.v22_cod_color,
        bodega              LIKE veht022.v22_bodega
        END RECORD

DEFINE vendedor 	LIKE veht001.v01_vendedor,
       nom_vendedor	LIKE veht001.v01_nombres

DEFINE cod_cobranzas	LIKE cxct001.z01_codcli,
       nom_cliente	LIKE cxct001.z01_nomcli

DEFINE tipo_doc		LIKE cxct004.z04_tipo_doc,
       nom_doc  	LIKE cxct004.z04_nombre

DEFINE g13_moneda     	LIKE gent013.g13_moneda, 
       nombre		LIKE gent013.g13_nombre,  
       decimales	LIKE gent013.g13_decimales 

DEFINE r_reserv RECORD
        nro      	LIKE veht033.v33_num_reserv,
        codigo_veh      LIKE veht033.v33_codigo_veh,
        vendedor        LIKE veht001.v01_nombres
        END RECORD

DEFINE r_favorcob RECORD
        nomcli          LIKE cxct001.z01_nomcli,
        tipo_doc        LIKE cxct021.z21_tipo_doc,
        num_doc         LIKE cxct021.z21_num_doc,
        saldo           LIKE cxct021.z21_saldo,
	moneda		LIKE gent013.g13_moneda,
        abreviacion     LIKE gent003.g03_abreviacion
        END RECORD

DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_cligen		RECORD LIKE cxct001.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
        ON v33_num_reserv, v33_codigo_veh, v33_nota, v33_vendedor, v33_codcli, 
           v33_tipo_doc, v33_num_doc, v33_moneda_doc, v33_val_doc
        ON KEY(F2)
		IF INFIELD(v33_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, '00') 
				RETURNING r_serveh.*
			IF r_serveh.codigo_veh IS NOT NULL THEN
				LET rm_v33.v33_codigo_veh = r_serveh.codigo_veh
				DISPLAY BY NAME rm_v33.v33_codigo_veh
				DISPLAY r_serveh.chasis TO serie_veh	
			END IF
		END IF
		IF INFIELD(v33_vendedor) THEN
			CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING vendedor, nom_vendedor
			IF vendedor IS NOT NULL THEN
				LET rm_v33.v33_vendedor = vendedor
				DISPLAY BY NAME rm_v33.v33_vendedor
				DISPLAY nom_vendedor TO n_vendedor
			END IF
		END IF
            	IF INFIELD(v33_codcli) THEN
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc) 
				RETURNING cod_cobranzas, nom_cliente
                  	LET rm_v33.v33_codcli = cod_cobranzas
                 	DISPLAY BY NAME rm_v33.v33_codcli  
			DISPLAY nom_cliente TO n_cliente
            	END IF
		IF INFIELD(v33_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('F') 
				RETURNING tipo_doc, nom_doc
			IF tipo_doc IS NOT NULL THEN
				LET rm_v33.v33_tipo_doc = tipo_doc
				DISPLAY BY NAME rm_v33.v33_tipo_doc
				DISPLAY nom_doc TO n_documento
			END IF
		END IF
		IF INFIELD(v33_num_reserv) THEN
			CALL fl_reservaciones(vg_codcia, vg_codloc) 
				RETURNING r_reserv.*
			IF r_reserv.nro IS NOT NULL THEN
				LET rm_v33.v33_num_reserv = r_reserv.nro
				LET rm_v33.v33_codigo_veh = r_reserv.codigo_veh
				DISPLAY BY NAME rm_v33.v33_num_reserv
				DISPLAY BY NAME rm_v33.v33_codigo_veh
			END IF
		END IF
		IF INFIELD(v33_num_doc) THEN
			IF rm_v33.v33_tipo_doc IS NULL THEN
				CALL fl_ayuda_doc_favor_cob(vg_codcia, 
					vg_codloc, rg_mod.g50_areaneg_def,
					rm_v33.v33_codcli, '00')
						RETURNING r_favorcob.*
			ELSE
				CALL fl_ayuda_doc_favor_cob(vg_codcia, 
					vg_codloc, rg_mod.g50_areaneg_def,
					rm_v33.v33_codcli, rm_v33.v33_tipo_doc)
						RETURNING r_favorcob.*
			END IF
			IF r_favorcob.num_doc IS NOT NULL THEN
				LET rm_v33.v33_num_doc  = r_favorcob.num_doc
				LET rm_v33.v33_tipo_doc = r_favorcob.tipo_doc
				LET rm_v33.v33_moneda_doc = r_favorcob.moneda
				LET rm_v33.v33_val_doc  = r_favorcob.saldo
				DISPLAY BY NAME rm_v33.v33_num_doc
				DISPLAY BY NAME rm_v33.v33_tipo_doc
				DISPLAY BY NAME rm_v33.v33_moneda_doc
				DISPLAY BY NAME rm_v33.v33_val_doc
			END IF
			CALL muestra_etiquetas()
		END IF
		IF INFIELD(v33_moneda_doc) THEN
			CALL fl_ayuda_monedas() 
				RETURNING g13_moneda, nombre, decimales 
			IF g13_moneda IS NOT NULL THEN
				LET rm_v33.v33_moneda_doc = g13_moneda
				DISPLAY BY NAME rm_v33.v33_moneda_doc
				DISPLAY nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	AFTER FIELD v33_codigo_veh
		LET rm_v33.v33_codigo_veh = GET_FLDBUF(v33_codigo_veh)
		IF rm_v33.v33_codigo_veh IS NULL THEN
			CLEAR serie_veh
		ELSE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					rm_v33.v33_codigo_veh)
						RETURNING r_v22.*
			IF r_v22.v22_chasis IS NULL THEN
				CLEAR serie_veh 
			ELSE
				IF r_v22.v22_estado = 'F' OR 
				   r_v22.v22_estado = 'P' OR
				   r_v22.v22_estado = 'B' THEN
					CLEAR serie_veh 
				END IF
				DISPLAY r_v22.v22_chasis TO serie_veh	
			END IF
		END IF
	AFTER FIELD v33_vendedor
		LET rm_v33.v33_vendedor = GET_FLDBUF(v33_vendedor)
		IF rm_v33.v33_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_v33.v33_vendedor)
				RETURNING r_v01.*
			IF r_v01.v01_vendedor IS NOT NULL THEN
				IF r_v01.v01_estado <> 'B' THEN
					DISPLAY r_v01.v01_nombres TO n_vendedor
				ELSE
					CLEAR n_vendedor
				END IF
			ELSE
				CLEAR n_vendedor
			END IF
		ELSE
			CLEAR n_vendedor
		END IF		 
	AFTER FIELD v33_codcli
		LET rm_v33.v33_codcli = GET_FLDBUF(v33_codcli)
		IF rm_v33.v33_codcli IS NULL THEN
			CLEAR n_cliente
		ELSE
			CALL fl_lee_cliente_general(rm_v33.v33_codcli) 
				RETURNING r_cligen.*
			IF r_cligen.z01_codcli IS NULL THEN
				CLEAR n_cliente
        		END IF   
			IF r_cligen.z01_estado = 'B' THEN
				CLEAR n_cliente
			END IF
			LET rm_v33.v33_codcli = r_cligen.z01_codcli
        		DISPLAY BY NAME rm_v33.v33_codcli
			DISPLAY r_cligen.z01_nomcli TO n_cliente
		END IF
	AFTER FIELD v33_tipo_doc
		LET rm_v33.v33_tipo_doc = GET_FLDBUF(v33_tipo_doc)
		IF rm_v33.v33_tipo_doc IS NULL THEN
			CLEAR n_documento
		ELSE
			CALL fl_lee_tipo_doc(rm_v33.v33_tipo_doc) 
				RETURNING r_z04.*
			IF r_z04.z04_tipo_doc IS NULL THEN	
				CLEAR n_documento
			ELSE
				DISPLAY r_z04.z04_nombre TO n_documento
			END IF 
		END IF
	AFTER FIELD v33_moneda_doc
		LET rm_v33.v33_moneda_doc = GET_FLDBUF(v33_moneda_doc)
		LET rm_v33.v33_moneda_doc = GET_FLDBUF(v33_moneda_doc)
		IF rm_v33.v33_moneda_doc IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v33.v33_moneda_doc) 
				RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF r_g13.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_g13.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht033 ',
	    '	WHERE v33_compania  = ', vg_codcia, 
	    '	  AND v33_localidad = ', vg_codloc, 
	    '	  AND ', expr_sql,
	    ' 	ORDER BY 1, 2' 

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v33.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v33.* FROM veht033 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
			    'El registro fue eliminado, por favor vuelva ' ||
                            'a consultar',
			    'exclamation')
--	CLEAR FORM
--	LET vm_num_rows = 0
--	LET vm_row_current = 0
	RETURN
END IF

DISPLAY BY NAME rm_v33.v33_num_reserv,
                rm_v33.v33_codigo_veh,
		rm_v33.v33_nota,
		rm_v33.v33_vendedor,
		rm_v33.v33_codcli,
		rm_v33.v33_moneda_doc,
		rm_v33.v33_tipo_doc,
		rm_v33.v33_num_doc,
		rm_v33.v33_val_doc,
		rm_v33.v33_usuario,
		rm_v33.v33_fecing
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()

--DISPLAY '   ' TO n_estado
--CLEAR n_estado

DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 68 

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



FUNCTION muestra_etiquetas()

DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_v01		RECORD LIKE veht001.* 
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_v33.v33_codigo_veh) 
	RETURNING r_v22.*
DISPLAY r_v22.v22_chasis TO serie_veh

CALL fl_lee_vendedor_veh(vg_codcia, rm_v33.v33_vendedor) RETURNING r_v01.*
DISPLAY r_v01.v01_nombres TO n_vendedor

CALL fl_lee_cliente_general(rm_v33.v33_codcli)	RETURNING r_z01.*
DISPLAY r_z01.z01_nomcli TO n_cliente

CALL fl_lee_tipo_doc(rm_v33.v33_tipo_doc) RETURNING r_z04.*
DISPLAY r_z04.z04_nombre TO n_documento

CALL fl_lee_moneda(rm_v33.v33_moneda_doc) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

END FUNCTION



FUNCTION control_eliminar()

DEFINE done 		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DELETE FROM veht033 WHERE ROWID = vm_rows[vm_row_current] 
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL actualiza_serie('A', rm_v33.v33_codigo_veh) RETURNING done
IF done = 0 THEN
	ROLLBACK WORK
	RETURN
END IF
COMMIT WORK

CALL fl_mensaje_registro_modificado()
LET vm_row_current = 0
LET vm_num_rows    = 0
CALL muestra_contadores()
CLEAR FORM

END FUNCTION



-- REPITE HASTA QUE PUEDA ACTUALIZAR LA TABLA DE SERIES DE VEHICULOS
-- O HASTA QUE EL USUARIO DECIDA NO VOLVERLO A INTENTAR
FUNCTION actualiza_serie(estado, codigo_veh)

DEFINE estado		LIKE veht022.v22_estado
DEFINE codigo_veh	LIKE veht022.v22_codigo_veh
DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE resp 		CHAR(6)

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		UPDATE veht022 
			SET v22_estado = estado       
			WHERE v22_compania   = vg_codcia
			  AND v22_localidad  = vg_codloc
			  AND v22_codigo_veh = codigo_veh
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		CALL fgl_winquestion(vg_producto, 
				     'Registro bloqueado por ' ||
			      	     'otro usuario, desea ' ||
                                     'intentarlo nuevamente', 'No',
        			     'Yes|No', 'question', 1)
						RETURNING resp
		IF resp = 'No' THEN
			CALL fl_mensaje_abandonar_proceso()
				 RETURNING resp
			IF resp = 'Yes' THEN
				LET intentar = 0
				LET done = 0
			END IF	
		END IF
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

RETURN done

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht033
	WHERE v33_compania   = vg_codcia
	  AND v33_localidad  = vg_codloc
	  AND v33_num_reserv = vm_num_reserv
	  	  
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe reservación.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
