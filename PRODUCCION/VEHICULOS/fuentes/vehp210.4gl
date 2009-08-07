------------------------------------------------------------------------------
-- Titulo           : vehp210.4gl - Ingreso / Mantenimiento de Pedidos
-- Elaboracion      : 29-sep-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp210 base modulo compania localidad [num_ped]
--		Si (num_ped <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (num_ped = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_num_ped	LIKE veht034.v34_pedido
DEFINE vm_nivel_cta	LIKE ctbt001.b01_nivel

DEFINE vm_ind_arr   	SMALLINT

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v34		RECORD LIKE veht034.*
DEFINE rm_v35		RECORD LIKE veht035.*
DEFINE rm_pedido ARRAY[100] OF RECORD 
	cant		SMALLINT,
	modelo		LIKE veht035.v35_modelo,
	color		LIKE veht035.v35_cod_color,
	precio_unit	LIKE veht035.v35_precio_unit,
	total		LIKE veht035.v35_precio_unit
END RECORD



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
LET vg_proceso = 'vehp210'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

INITIALIZE vm_num_ped TO NULL
IF num_args() = 5 THEN
	LET vm_num_ped  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE dummy1		SMALLINT
DEFINE dummy2		SMALLINT

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_210 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_210 FROM '../forms/vehf210_1'
DISPLAY FORM f_210

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v34.* TO NULL
INITIALIZE rm_v35.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 1000

CALL setea_botones_f1()

IF vm_num_ped IS NOT NULL THEN
	CALL execute_query()
END IF

SELECT MAX(b01_nivel) INTO vm_nivel_cta FROM ctbt001
IF vm_nivel_cta IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha configurado el plan de cuentas.',
		'stop')
	EXIT PROGRAM
END IF

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
		IF vm_num_ped IS NOT NULL THEN  -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		CALL setea_botones_f1()
	COMMAND KEY('M') 'Modificar' 		'Modificar registro corriente.'
		CALL control_modificacion()
		CALL setea_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Detalle'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Detalle'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		CALL setea_botones_f1()
	COMMAND KEY('D') 'Detalle'		'Ver detalle de pedido.'
			CALL modifica_detalle('D')
				RETURNING dummy1, dummy2
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
		CALL actualiza_modelos()
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE num_elm 		SMALLINT
DEFINE i		SMALLINT
DEFINE j		SMALLINT

CLEAR FORM
INITIALIZE rm_v34.* TO NULL
INITIALIZE rm_v35.* TO NULL

-- INITIAL VALUES FOR THE RM_V34 RECORD
LET rm_v34.v34_fecing    = CURRENT
LET rm_v34.v34_usuario   = vg_usuario
LET rm_v34.v34_compania  = vg_codcia
LET rm_v34.v34_localidad = vg_codloc
LET rm_v34.v34_tipo      = 'I'
LET rm_v34.v34_moneda    = rg_gen.g00_moneda_base
LET rm_v34.v34_estado    = 'A'
DISPLAY 'ACTIVO' TO n_estado

-- INITIAL VALUES FOR THE RM_V35 RECORD
LET rm_v35.v35_compania  = vg_codcia
LET rm_v35.v35_localidad = vg_codloc
LET rm_v35.v35_estado    = 'A'

-- OTHER VALUES
LET rm_v34.v34_unid_liq  = 0
LET rm_v35.v35_flete     = 0.0
LET rm_v35.v35_costo_liq = 0.0

CALL muestra_etiquetas()

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET INT_FLAG = 0
LET num_elm = ingresa_detalles(1, 'I') 
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

LET rm_v34.v34_unid_ped = 0
FOR i = 1 TO num_elm
	LET rm_v34.v34_unid_ped = rm_v34.v34_unid_ped + rm_pedido[i].cant
END FOR

INSERT INTO veht034 VALUES(rm_v34.*)

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada

LET rm_v35.v35_pedido = rm_v34.v34_pedido
LET rm_v35.v35_secuencia = 0
FOR i = 1 TO num_elm
	FOR j = 1 TO rm_pedido[i].cant
		LET rm_v35.v35_secuencia   = rm_v35.v35_secuencia + 1
		LET rm_v35.v35_modelo      = rm_pedido[i].modelo
		LET rm_v35.v35_cod_color   = rm_pedido[i].color
		LET rm_v35.v35_precio_unit = rm_pedido[i].precio_unit
		INSERT INTO veht035 VALUES(rm_v35.*)
	END FOR
END FOR

LET INT_FLAG = 0

COMMIT WORK

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE num_elm 		SMALLINT
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE flag		SMALLINT
DEFINE r_dummy		RECORD LIKE veht035.* 
DEFINE intentar		SMALLINT
DEFINE done		SMALLINT
DEFINE resp 		CHAR(6)

INITIALIZE rm_v35.* TO NULL

-- INITIAL VALUES FOR THE RM_V35 RECORD
LET rm_v35.v35_compania  = vg_codcia
LET rm_v35.v35_localidad = vg_codloc
LET rm_v35.v35_estado    = 'A'

-- OTHER VALUES
LET rm_v35.v35_flete     = 0.0
LET rm_v35.v35_costo_liq = 0.0

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v34.v34_estado <> 'A' AND rm_v34.v34_estado <> 'R' THEN
	CALL fgl_winmessage(vg_producto, 'Registro no puede ser modificado',
			    'exclamation')
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht034 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v34.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL lee_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

LET flag = 0
DECLARE q_cont CURSOR FOR 
	SELECT * FROM veht035 
		WHERE v35_compania  = vg_codcia
		  AND v35_localidad = vg_codloc
		  AND v35_pedido    = rm_v34.v34_pedido
		  AND v35_estado <> 'A'
FOREACH q_cont INTO r_dummy.*
	IF r_dummy.v35_estado <> 'A' THEN
		LET flag = 1
		EXIT FOREACH
	END IF
END FOREACH
		  
IF NOT flag THEN
	LET num_elm = ingresa_detalles(vm_ind_arr, 'M')
	IF INT_FLAG THEN
		ROLLBACK WORK
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CLOSE q_upd
		RETURN
	END IF

	LET intentar = 1
	LET done = 0
	WHILE (intentar)
		WHENEVER ERROR CONTINUE
		DECLARE q_del CURSOR FOR
			SELECT * FROM veht035 
				WHERE v35_compania  = vg_codcia
	  	  	  	  AND v35_localidad = vg_codloc
	  	  	  	  AND v35_pedido    = rm_v34.v34_pedido
			FOR UPDATE
		WHENEVER ERROR STOP    
		IF STATUS < 0 THEN
			CALL fgl_winquestion(vg_producto, 
				     	     'Registro bloqueado por ' ||
			      	     	     'por otro usuario, desea ' ||
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
	IF intentar = 0 AND done = 0 THEN
		ROLLBACK WORK
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CLOSE q_upd
		RETURN
	END IF

	FOREACH q_del
		DELETE FROM veht035 WHERE CURRENT OF q_del
	END FOREACH
	
	LET rm_v35.v35_pedido = rm_v34.v34_pedido
	LET rm_v35.v35_secuencia = 0
	LET rm_v34.v34_unid_ped  = 0
	FOR i = 1 TO num_elm
		FOR j = 1 TO rm_pedido[i].cant
			LET rm_v34.v34_unid_ped    = rm_v34.v34_unid_ped + 1
			LET rm_v35.v35_secuencia   = rm_v35.v35_secuencia + 1
			LET rm_v35.v35_modelo      = rm_pedido[i].modelo
			LET rm_v35.v35_cod_color   = rm_pedido[i].color
			LET rm_v35.v35_precio_unit = rm_pedido[i].precio_unit
			INSERT INTO veht035 VALUES(rm_v35.*)
		END FOR
	END FOR
ELSE
	LET intentar = 1
	LET done = 0
	CALL modifica_detalle('I') RETURNING intentar, done
	IF INT_FLAG THEN
		ROLLBACK WORK
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CLOSE q_upd
		RETURN
	END IF
	IF intentar = 0 AND done = 0 THEN
		ROLLBACK WORK
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CLOSE q_upd
		RETURN
	END IF
END IF
SELECT SUM(v35_precio_unit) 
	INTO rm_v34.v34_tot_valor
	FROM veht035
	WHERE v35_compania  = vg_codcia
	  AND v35_localidad = vg_codloc
	  AND v35_pedido    = rm_v34.v34_pedido
LET rm_v34.v34_tot_valor = fl_retorna_precision_valor(rm_v34.v34_moneda,
						      rm_v34.v34_tot_valor)
UPDATE veht034 SET * = rm_v34.* WHERE CURRENT OF q_upd

COMMIT WORK
CLOSE q_upd
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE proveedor        LIKE cxpt001.p01_codprov, 
       nom_proveedor	LIKE cxpt001.p01_nomprov

DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_mon		RECORD LIKE gent013.*

LET INT_FLAG = 0
INPUT BY NAME rm_v34.v34_pedido,  rm_v34.v34_estado,    rm_v34.v34_proveedor,  
              rm_v34.v34_moneda,  rm_v34.v34_aux_cont,  rm_v34.v34_referencia, 
              rm_v34.v34_tipo,    rm_v34.v34_fec_envio, rm_v34.v34_fec_llegada,
	      rm_v34.v34_usuario, rm_v34.v34_fecing 
              WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v34_referencia, v34_tipo, 
              			     v34_proveedor, v34_fec_envio, 
				     v34_fec_llegada, v34_moneda, 
              			     v34_aux_cont 
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
		IF INFIELD(v34_proveedor) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia, 
						            vg_codloc) 
				RETURNING proveedor, nom_proveedor
			IF proveedor IS NOT NULL THEN
				LET rm_v34.v34_proveedor = proveedor
				DISPLAY BY NAME rm_v34.v34_proveedor
				DISPLAY nom_proveedor TO n_proveedor
			END IF
		END IF
		IF INFIELD(v34_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_v34.v34_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO v34_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(v34_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel_cta) 
				RETURNING r_b10.b10_cuenta, 
        				  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_v34.v34_aux_cont = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO v34_aux_cont
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			END IF	
		END IF
		LET INT_FLAG = 0	
	BEFORE INPUT
		CALL setea_botones_f1()
	BEFORE FIELD v34_pedido
		IF flag = 'M' THEN		
			NEXT FIELD v34_proveedor 
		END IF
	AFTER FIELD v34_aux_cont
		IF rm_v34.v34_aux_cont IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_v34.v34_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NOT NULL THEN
				IF r_b10.b10_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_cuenta
					NEXT FIELD v34_aux_cont
				END IF
				IF r_b10.b10_nivel <> vm_nivel_cta THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta debe ' ||
                               	                            'ser de nivel ' ||
                               	                            vm_nivel_cta || '.',   
                                       	                    'exclamation')
					CLEAR n_cuenta
					NEXT FIELD v34_aux_cont
				END IF
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			ELSE
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Cuenta no ' ||
                               	                            'existe',        
                                       	                    'exclamation')
					CLEAR n_cuenta
					NEXT FIELD v34_aux_cont
			END IF
		ELSE
			CLEAR n_cuenta
		END IF
	AFTER FIELD v34_proveedor
		IF rm_v34.v34_proveedor IS NULL THEN
			CLEAR n_proveedor
		ELSE
			CALL fl_lee_proveedor(rm_v34.v34_proveedor) 
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Proveedor no existe',      
                                       	    'exclamation')
				CLEAR n_proveedor
				NEXT FIELD v34_proveedor
			ELSE
				IF r_p01.p01_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Proveedor está ' ||
                               	                            'bloqueado',        
                                       	                    'exclamation')
					CLEAR n_proveedor
					NEXT FIELD v34_proveedor
				ELSE
					DISPLAY r_p01.p01_nomprov TO n_proveedor
				END IF
			END IF 
		END IF
	AFTER FIELD v34_moneda
		IF rm_v34.v34_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v34.v34_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD v34_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD v34_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
				END IF
			END IF 
		END IF
END INPUT

END FUNCTION



FUNCTION ingresa_detalles(i, flag)

DEFINE flag 		CHAR(1)
DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE resp		CHAR(6)

DEFINE ind		SMALLINT
DEFINE total 		LIKE veht035.v35_precio_unit

DEFINE modelo 		LIKE veht035.v35_modelo

DEFINE r_v05		RECORD LIKE veht005.*
DEFINE r_v20		RECORD LIKE veht020.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_serveh RECORD
        v22_codigo_veh          LIKE veht022.v22_codigo_veh,
        v22_chasis              LIKE veht022.v22_chasis,
        v22_motor               LIKE veht022.v22_motor,
        v22_cod_color           LIKE veht022.v22_cod_color,
        v22_estado              LIKE veht022.v22_estado
        END RECORD
DEFINE continuar 	SMALLINT

INITIALIZE r_v22.* TO NULL
INITIALIZE r_serveh.* TO NULL

IF flag = 'I' THEN
	INITIALIZE rm_pedido[1].* TO NULL
END IF
CALL set_count(i)
INPUT ARRAY rm_pedido WITHOUT DEFAULTS FROM ra_pedido.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN 0
		END IF
	ON KEY(F2)
		IF INFIELD(v35_modelo) THEN
			CALL fl_ayuda_modelos_veh(vg_codcia)
				RETURNING r_v20.v20_modelo, r_v20.v20_linea
			IF r_v20.v20_modelo IS NOT NULL THEN
				CALL fl_lee_modelo_veh(vg_codcia, 
						       r_v20.v20_modelo)
							     RETURNING r_v20.*
				LET rm_pedido[i].modelo = r_v20.v20_modelo
				DISPLAY rm_pedido[i].modelo TO
					ra_pedido[j].v35_modelo
			END IF
		END IF
		IF INFIELD(v35_cod_color) THEN
			CALL fl_ayuda_colores(vg_codcia) 
				RETURNING r_v05.v05_cod_color, 
					  r_v05.v05_descri_base
			IF r_v05.v05_cod_color IS NOT NULL THEN
				LET rm_pedido[i].color = r_v05.v05_cod_color
				DISPLAY rm_pedido[i].color TO
					ra_pedido[j].v35_cod_color
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f1()
	BEFORE FIELD v35_modelo
		LET modelo = rm_pedido[i].modelo	
	AFTER  FIELD v35_modelo
		IF rm_pedido[i].modelo IS NOT NULL THEN
			CALL fl_lee_modelo_veh(vg_codcia, 
                                       	       rm_pedido[i].modelo)
							RETURNING r_v20.*
			IF r_v20.v20_modelo IS NULL THEN	
				CALL fgl_winmessage(vg_producto,
				            	    'Modelo no existe',
					    	    'exclamation')
				NEXT FIELD v35_modelo
			ELSE
				IF rm_pedido[i].precio_unit IS NULL OR
				   modelo <> rm_pedido[i].modelo  THEN
					LET rm_pedido[i].precio_unit = 
						r_v20.v20_prec_exfab *
						calcula_paridad(
							r_v20.v20_mon_prov,
							rm_v34.v34_moneda)
					IF rm_pedido[i].precio_unit IS NULL THEN
						LET rm_pedido[i].precio_unit = 0
					END IF
					LET rm_pedido[i].precio_unit =
						fl_retorna_precision_valor(
						       rm_v34.v34_moneda,
						       rm_pedido[i].precio_unit)
					DISPLAY rm_pedido[i].precio_unit TO
						ra_pedido[j].v35_precio_unit
				END IF
			END IF 
		END IF
	AFTER  FIELD v35_cod_color
		IF rm_pedido[i].color IS NOT NULL THEN
			CALL fl_lee_color_veh(vg_codcia, 
                                      	      rm_pedido[i].color)
							RETURNING r_v05.*
			IF r_v05.v05_cod_color IS NULL THEN	
				CALL fgl_winmessage(vg_producto,
				            	    'No existe color',
					    	    'exclamation')
				NEXT FIELD v35_cod_color
			END IF 
			LET ind = 1
			WHILE (ind <> (arr_count()))
			IF rm_pedido[i].modelo = rm_pedido[ind].modelo AND
			   rm_pedido[i].color  = rm_pedido[ind].color  AND 
			   ind <> i THEN 
				CALL fgl_winmessage(vg_producto,
                                                    'No puede realizar dos ' ||
                                                    'veces el mismo pedido ' ||
						    'en el mismo documento',
                                                    'exclamation')
				CLEAR ra_pedido[j].v35_cod_color
				INITIALIZE rm_pedido[i].color TO NULL
				NEXT FIELD v35_cod_color
			ELSE
				LET ind = ind + 1
			END IF
			END WHILE
		END IF
	AFTER  FIELD v35_precio_unit
		IF rm_pedido[i].precio_unit IS NULL AND 
		   rm_pedido[i].cant IS NULL THEN
			CLEAR ra_pedido[j].total
			INITIALIZE rm_pedido[i].total TO NULL
		ELSE
			LET rm_pedido[i].precio_unit =
				fl_retorna_precision_valor(rm_v34.v34_moneda,
						   rm_pedido[i].precio_unit)
			DISPLAY rm_pedido[i].precio_unit 
				TO ra_pedido[j].v35_precio_unit
			LET rm_pedido[i].total = 
				rm_pedido[i].cant * rm_pedido[i].precio_unit
			DISPLAY rm_pedido[i].total TO ra_pedido[j].total
		END IF
	AFTER  FIELD cant 
		IF rm_pedido[i].cant IS NULL AND 
		   rm_pedido[i].precio_unit THEN
			CLEAR ra_pedido[j].total
			INITIALIZE rm_pedido[i].total TO NULL
		ELSE
			LET rm_pedido[i].total = 
				rm_pedido[i].cant * rm_pedido[i].precio_unit
			DISPLAY rm_pedido[i].total TO ra_pedido[j].total
		END IF
	AFTER  ROW
		LET rm_pedido[i].total = 
			rm_pedido[i].cant * rm_pedido[i].precio_unit
		DISPLAY rm_pedido[i].total TO ra_pedido[j].total


		LET total = 0
		FOR ind = 1 TO arr_count()
			LET total = total + rm_pedido[ind].total
		END FOR
		LET rm_v34.v34_tot_valor = total
		DISPLAY BY NAME rm_v34.v34_tot_valor
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER INPUT
		LET ind = arr_count()
		FOR i = 1 TO ind
			IF i < ind AND rm_pedido[i].modelo IS NULL 
     		   		    OR rm_pedido[i].color  IS NULL 
				    OR rm_pedido[i].cant   IS NULL
				    OR rm_pedido[i].precio_unit IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                               		'Debe borrar las lineas que ' ||
                                        'deje en blanco',
					'exclamation')
				CONTINUE INPUT 
			END IF
		END FOR
		LET vm_ind_arr = arr_count()
END INPUT

RETURN ind

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i 		SMALLINT
DEFINE query 		CHAR(250)
DEFINE filas_pant	SMALLINT


LET filas_pant = fgl_scr_size('ra_pedido')

FOR i = 1 TO filas_pant 
	INITIALIZE rm_pedido[i].* TO NULL
	CLEAR ra_pedido[i].*
END FOR

LET query = 'SELECT COUNT(*), v35_modelo, v35_cod_color, v35_precio_unit ',  
            '	FROM veht035 ',
	    '	WHERE v35_compania  = ', vg_codcia,
	    '	  AND v35_localidad = ', vg_codloc,
	    '     AND v35_pedido    = "', rm_v34.v34_pedido, '"',	
            '	GROUP BY v35_modelo, v35_cod_color, v35_precio_unit ',
            '	ORDER BY 2, 3'
PREPARE cons2 FROM query
DECLARE q_cons2 CURSOR FOR cons2
LET i = 1
FOREACH q_cons2 INTO rm_pedido[i].cant, rm_pedido[i].modelo, rm_pedido[i].color,
		     rm_pedido[i].precio_unit			
	LET rm_pedido[i].total = rm_pedido[i].cant * rm_pedido[i].precio_unit
	LET i = i + 1
        IF i > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	LET i = 0
	CLEAR FORM
	RETURN
END IF

LET vm_ind_arr = i

IF vm_ind_arr < filas_pant THEN
	LET filas_pant = vm_ind_arr
END IF

FOR i = 1 TO filas_pant   
	DISPLAY rm_pedido[i].* TO ra_pedido[i].*
END FOR

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE proveedor		LIKE cxpt001.p01_codprov,
       nom_proveedor		LIKE cxpt001.p01_nomprov

DEFINE r_mon			RECORD LIKE gent013.*
DEFINE r_p01			RECORD LIKE cxpt001.*
DEFINE r_b10			RECORD LIKE ctbt010.*
DEFINE r_v34			RECORD LIKE veht034.*

CLEAR FORM

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v34_pedido, v34_estado, v34_proveedor, v34_moneda, v34_aux_cont,  
	   v34_referencia, v34_tipo, v34_fec_envio, v34_fec_llegada, 
	   v34_usuario 
	ON KEY(F2)
		IF INFIELD(v34_pedido) THEN
			CALL fl_ayuda_pedidos_vehiculos(vg_codcia, vg_codloc, 
							'P')
				RETURNING r_v34.v34_pedido, r_v34.v34_estado,
					  r_v34.v34_fec_envio, 
					  r_v34.v34_fec_llegada
			IF r_v34.v34_pedido IS NOT NULL THEN
				LET rm_v34.v34_pedido      = r_v34.v34_pedido
				DISPLAY rm_v34.v34_pedido TO v34_pedido
			END IF		
		END IF
		IF INFIELD(v34_proveedor) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,
							    vg_codloc) 
				RETURNING proveedor, nom_proveedor
			IF proveedor IS NOT NULL THEN
				LET rm_v34.v34_proveedor = proveedor
				DISPLAY BY NAME rm_v34.v34_proveedor
				DISPLAY nom_proveedor TO n_proveedor
			END IF
		END IF
		IF INFIELD(v34_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_v34.v34_moneda = r_mon.g13_moneda
				DISPLAY r_mon.g13_moneda TO v34_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		IF INFIELD(v34_aux_cont) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel_cta) 
				RETURNING r_b10.b10_cuenta, 
        				  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_v34.v34_aux_cont = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta TO v34_aux_cont
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			END IF	
		END IF
		LET INT_FLAG = 0
	BEFORE CONSTRUCT
		CALL setea_botones_f1()
	AFTER FIELD v34_aux_cont
		LET rm_v34.v34_aux_cont = GET_FLDBUF(v34_aux_cont)
		IF rm_v34.v34_aux_cont IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_v34.v34_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NOT NULL THEN
				IF r_b10.b10_estado = 'B' THEN
					CLEAR n_cuenta
				END IF
				IF r_b10.b10_nivel <> vm_nivel_cta THEN
					CLEAR n_cuenta
				END IF
				DISPLAY r_b10.b10_descripcion TO n_cuenta
			ELSE
					CLEAR n_cuenta
			END IF
		ELSE
			CLEAR n_cuenta
		END IF
	AFTER FIELD v34_proveedor
		LET rm_v34.v34_proveedor = GET_FLDBUF(v34_proveedor)
		IF rm_v34.v34_proveedor IS NULL THEN
			CLEAR n_proveedor
		ELSE
			CALL fl_lee_proveedor(rm_v34.v34_proveedor) 
				RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN	
				CLEAR n_proveedor
			ELSE
				IF r_p01.p01_estado = 'B' THEN
					CLEAR n_proveedor
				ELSE
					DISPLAY r_p01.p01_nomprov TO n_proveedor
				END IF
			END IF 
		END IF
	AFTER FIELD v34_moneda
		LET rm_v34.v34_moneda = GET_FLDBUF(v34_moneda)
		IF rm_v34.v34_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v34.v34_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CLEAR n_moneda
			ELSE
				IF r_mon.g13_estado = 'B' THEN
					CLEAR n_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
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

LET query = 'SELECT *, ROWID FROM veht034 ',  
            '	WHERE v34_compania  = ', vg_codcia, 
	    '	  AND v34_localidad = ', vg_codloc,
	    '     AND ', expr_sql,	 	
	    ' 	ORDER BY 1, 2, 3' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v34.*, vm_rows[vm_num_rows]
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

SELECT * INTO rm_v34.* FROM veht034 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v34.v34_pedido,
		rm_v34.v34_estado,
		rm_v34.v34_tipo,       
		rm_v34.v34_referencia,
		rm_v34.v34_proveedor,
		rm_v34.v34_fec_envio,
		rm_v34.v34_fec_llegada,
		rm_v34.v34_moneda,
		rm_v34.v34_tot_valor,
		rm_v34.v34_aux_cont,
		rm_v34.v34_usuario,
		rm_v34.v34_fecing
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()
CALL setea_botones_f1()

END FUNCTION



FUNCTION muestra_contadores()

--DISPLAY '  ' TO n_estado
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

DEFINE nom_estado		CHAR(9)
DEFINE r_p01			RECORD LIKE cxpt001.*
DEFINE r_g13			RECORD LIKE gent013.*
DEFINE r_b10			RECORD LIKE ctbt010.*

CASE rm_v34.v34_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'R' LET nom_estado = 'RECIBIDO'
	WHEN 'L' LET nom_estado = 'LIQUIDADO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
END CASE
DISPLAY nom_estado   TO n_estado

CALL fl_lee_proveedor(rm_v34.v34_proveedor) RETURNING r_p01.*
DISPLAY r_p01.p01_nomprov TO n_proveedor

CALL fl_lee_moneda(rm_v34.v34_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

CALL fl_lee_cuenta(vg_codcia, rm_v34.v34_aux_cont) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO n_cuenta

END FUNCTION



FUNCTION modifica_detalle(flag)

DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE query 		CHAR(250)
DEFINE resp  		CHAR(6)
DEFINE flag  		CHAR(1)
DEFINE filas_pant	SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done     	SMALLINT
DEFINE salir    	SMALLINT
DEFINE mensaje 		CHAR(40)

DEFINE r_v05		RECORD LIKE veht005.*
DEFINE color		LIKE veht005.v05_cod_color
DEFINE precio		LIKE veht035.v35_precio_unit 

DEFINE r_detail ARRAY[1000] OF RECORD
	secuencia		LIKE veht035.v35_secuencia, 
	modelo			LIKE veht035.v35_modelo, 
	color			LIKE veht035.v35_cod_color, 
	precio_unit		LIKE veht035.v35_precio_unit, 
	estado			LIKE veht035.v35_estado, 
	n_estado		CHAR(9)
END RECORD

OPEN WINDOW w_210_2 AT 14,2 WITH 07 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		BORDER)
OPEN FORM f_210_2 FROM '../forms/vehf210_2'
DISPLAY FORM f_210_2


LET filas_pant = fgl_scr_size('ra_detail')

FOR i = 1 TO filas_pant 
	INITIALIZE r_detail[i].* TO NULL
	CLEAR ra_detail[i].*
END FOR

LET query = 'SELECT v35_secuencia, v35_modelo, v35_cod_color, ',
	    '	    v35_precio_unit, v35_estado ',  
            '	FROM veht035 ',
	    '	WHERE v35_compania  = ', vg_codcia,
	    '	  AND v35_localidad = ', vg_codloc,
	    '     AND v35_pedido    = "', rm_v34.v34_pedido, '"',	
            '	ORDER BY 1'
PREPARE cons3 FROM query
DECLARE q_cons3 CURSOR FOR cons3
LET i = 1
FOREACH q_cons3 INTO r_detail[i].secuencia, r_detail[i].modelo, 
	             r_detail[i].color, r_detail[i].precio_unit,
		     r_detail[i].estado			
	CASE r_detail[i].estado
		WHEN 'A' LET r_detail[i].n_estado = 'ACTIVO'
		WHEN 'R' LET r_detail[i].n_estado = 'RECIBIDO'
		WHEN 'L' LET r_detail[i].n_estado = 'LIQUIDADO'
		WHEN 'P' LET r_detail[i].n_estado = 'PROCESADO'
	END CASE
	LET i = i + 1
        IF i > 1000 THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	CLEAR FORM
	CLOSE WINDOW w_210_2
	RETURN 0, 0
END IF

IF rm_v34.v34_estado = 'L' OR flag = 'D' THEN
	CALL setea_botones_f2()
	CALL set_count(i)
	DISPLAY ARRAY r_detail TO ra_detail.*
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
	END DISPLAY
	CLEAR FORM
	CLOSE WINDOW w_210_2
	RETURN 0, 0
END IF


LET salir = 0
WHILE NOT salir
CALL setea_botones_f2()
LET INT_FLAG = 0
LET j = 1
CALL set_count(i)
INPUT ARRAY r_detail WITHOUT DEFAULTS FROM ra_detail.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(v35_cod_color) THEN
			CALL fl_ayuda_colores(vg_codcia) 
				RETURNING r_v05.v05_cod_color, 
					  r_v05.v05_descri_base
			IF r_v05.v05_cod_color IS NOT NULL THEN
				LET r_detail[i].color = r_v05.v05_cod_color
				DISPLAY r_detail[i].color TO
					ra_detail[j].v35_cod_color
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE FIELD v35_cod_color
		LET color  = r_detail[i].color
	AFTER  FIELD v35_cod_color
		IF r_detail[i].color IS NOT NULL THEN
			CALL fl_lee_color_veh(vg_codcia, r_detail[i].color)
				RETURNING r_v05.*
			IF r_v05.v05_cod_color IS NULL THEN	
				CALL fgl_winmessage(vg_producto,
				            	    'No existe color',
					    	    'exclamation')
				NEXT FIELD v35_cod_color
			END IF 
		END IF
		IF color <> r_detail[i].color AND r_detail[i].estado <> 'A' THEN
			LET r_detail[i].color  = color
			DISPLAY color TO ra_detail[j].v35_cod_color
			CASE r_detail[i].estado
				WHEN 'R' LET mensaje = 'El vehículo ya ha ' ||
						       'sido recibido'	
				WHEN 'L' LET mensaje = 'El vehículo ya ha ' ||
						       'sido liquidado'	
				WHEN 'P' LET mensaje = 'El vehículo ya ha ' ||
						       'sido procesado'	
			END CASE
			CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
		END IF
	BEFORE FIELD v35_precio_unit
		LET precio = r_detail[i].precio_unit
	AFTER  FIELD v35_precio_unit
		IF precio <> r_detail[i].precio_unit AND 
		   r_detail[i].estado <> 'A' THEN
			LET r_detail[i].precio_unit = precio
			DISPLAY precio TO ra_detail[j].v35_precio_unit
			CASE r_detail[i].estado
				WHEN 'R' LET mensaje = 'El vehículo ya ha ' ||
						       'sido recibido'	
				WHEN 'L' LET mensaje = 'El vehículo ya ha ' ||
						       'sido liquidado'	
				WHEN 'P' LET mensaje = 'El vehículo ya ha ' ||
						       'sido procesado'	
			END CASE
			CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
		END IF
	BEFORE INSERT
		IF i = arr_count() THEN
			LET i = arr_count() - 1
		ELSE
			LET i = arr_count()
		END IF
		EXIT INPUT
	AFTER DELETE
		LET i = arr_count() 
		EXIT INPUT
	BEFORE INPUT 
		CALL dialog.keysetlabel('INSERT', '')
	BEFORE ROW 
		LET i = arr_curr()
		LET j = scr_line()
	AFTER INPUT
		LET i = arr_count()
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_210_2
	RETURN 0, 0   
END IF

END WHILE

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
	DECLARE q_det CURSOR FOR 
		SELECT * FROM veht035 
			WHERE v35_compania  = vg_codcia
		  	  AND v35_localidad = vg_codloc
		  	  AND v35_pedido    = rm_v34.v34_pedido
	FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		CALL fgl_winquestion(vg_producto, 
				     'Registro bloqueado por ' ||
			      	     'por otro usuario, desea ' ||
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
IF intentar = 0 AND done = 0 THEN
	CLOSE WINDOW w_210_2
	RETURN intentar, done
END IF

LET i = 1
FOREACH q_det INTO rm_v35.*
	IF rm_v35.v35_estado <> 'A' THEN
		LET i = i + 1
		CONTINUE FOREACH
	END IF	
	IF r_detail[i].secuencia = rm_v35.v35_secuencia THEN
		LET rm_v35.v35_cod_color = r_detail[i].color
		LET rm_v35.v35_precio_unit = r_detail[i].precio_unit
		UPDATE veht035 SET * = rm_v35.* WHERE CURRENT OF q_det
		LET i = i + 1
		CONTINUE FOREACH
	END IF
	IF r_detail[i].secuencia > rm_v35.v35_secuencia OR 
	   r_detail[i].secuencia IS NULL THEN
		LET rm_v34.v34_unid_ped = rm_v34.v34_unid_ped - 1
		DELETE FROM veht035 WHERE CURRENT OF q_det
		CONTINUE FOREACH
	END IF
END FOREACH
LET i = i - 1

CLOSE WINDOW w_210_2

RETURN intentar, done 

END FUNCTION



FUNCTION control_mostrar_det()

CALL set_count(vm_ind_arr)
DISPLAY ARRAY rm_pedido TO ra_pedido.*
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
				    'para esta moneda',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION setea_botones_f1()

DISPLAY 'Cant.' TO bt_cant
DISPLAY 'Modelo' TO bt_modelo
DISPLAY 'Cod. Color' TO bt_color
DISPLAY 'Precio Fábrica' TO bt_fob
DISPLAY 'Total' TO bt_total

END FUNCTION



FUNCTION setea_botones_f2()

DISPLAY 'Sec.' TO bt_sec
DISPLAY 'Modelo' TO bt_modelo
DISPLAY 'Cod. Color' TO bt_color
DISPLAY 'Precio Fábrica' TO bt_fob
DISPLAY 'Estado' TO bt_estado

END FUNCTION



FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht034
	WHERE v34_compania  = vg_codcia
	  AND v34_localidad = vg_codloc
	  AND v34_pedido    = vm_num_ped
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe pedido.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION actualiza_modelos()

DEFINE modelo		LIKE veht020.v20_modelo
DEFINE compania  	LIKE veht020.v20_compania
DEFINE cantidad		SMALLINT

BEGIN WORK

DECLARE q_v20 CURSOR FOR
	SELECT v20_compania, v20_modelo, COUNT(v35_modelo)
		FROM veht020, OUTER veht035
		WHERE v35_compania = v20_compania
		  AND v35_modelo   = v20_modelo
		  AND v35_estado IN ('A', 'R', 'L')
		GROUP BY v20_compania , v20_modelo
		
FOREACH q_v20 INTO compania, modelo, cantidad
	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT 3

	DECLARE q_ped2 CURSOR FOR
		SELECT v20_pedidos FROM veht020
			WHERE v20_compania = compania
			  AND v20_modelo   = modelo
		FOR UPDATE OF v20_pedidos

	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR STOP
	OPEN  q_ped2
	FETCH q_ped2
	IF STATUS < 0 THEN
		CALL fgl_winmessage(vg_producto, 
			'No se pudo actualizar el contador de pedidos.',
			'stop')
		ROLLBACK WORK 
		RETURN
	END IF

	UPDATE veht020 SET v20_pedidos = cantidad WHERE CURRENT OF q_ped2
	CLOSE q_ped2
	FREE  q_ped2
END FOREACH
FREE q_ped2

COMMIT WORK

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
