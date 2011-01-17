-----------------------------------------------------------------------------
-- Titulo           : vehp201.4gl - Mantenimiento de Pre-venta  
-- Elaboracion      : 15-oct-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp201 base modulo compania localidad [numprev]
--		Si (numprev <> 0) el programa se esta ejcutando en modo de
--			solo consulta
--		Si (numprev = 0) el programa se esta ejecutando en forma 
--			independiente
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios		VARCHAR(12)

DEFINE vm_areaneg		LIKE gent020.g20_areaneg   
DEFINE vm_linea			LIKE veht003.v03_linea

DEFINE vm_numprev		LIKE veht026.v26_numprev

DEFINE vm_tipo_pago_cuotai	CHAR(1)

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA r_rows QUE TENDRA 250 ELEMENTOS
DEFINE vm_rows ARRAY[50] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS

DEFINE vm_max_rows	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_v26		RECORD LIKE veht026.*

DEFINE vm_ind_v27	SMALLINT
DEFINE rm_v27 ARRAY[100] OF RECORD
	codigo_veh  		LIKE veht027.v27_codigo_veh, 
	precio			LIKE veht027.v27_precio, 
	descuento		LIKE veht027.v27_descuento, 
	val_descto		LIKE veht027.v27_val_descto, 
	total			LIKE veht027.v27_precio
END RECORD

DEFINE vm_ind_docs	SMALLINT
DEFINE rm_docs ARRAY[100] OF RECORD
	tipo_doc 	LIKE veht029.v29_tipo_doc, 
	num_doc		LIKE veht029.v29_numdoc, 
	moneda		LIKE veht029.v29_moneda, 
	fecha  		LIKE cxct021.z21_fecha_emi,
	valor_doc	LIKE veht029.v29_valor, 
	valor_usar	LIKE veht029.v29_valor
END RECORD
DEFINE r_docs ARRAY[100] OF RECORD
	tipo_doc 	LIKE veht029.v29_tipo_doc, 
	num_doc		LIKE veht029.v29_numdoc, 
	moneda		LIKE veht029.v29_moneda, 
	fecha  		LIKE cxct021.z21_fecha_emi,
	valor_doc	LIKE veht029.v29_valor, 
	valor_usar	LIKE veht029.v29_valor
END RECORD


DEFINE vm_ind_cuotai		SMALLINT
DEFINE rm_cuotai ARRAY[100] OF RECORD
	dividendo		LIKE veht028.v28_dividendo, 
	capital			LIKE veht028.v28_val_cap, 
	interes			LIKE veht028.v28_val_int, 
	fecha			LIKE veht028.v28_fecha_vcto
END RECORD
DEFINE r_cuotai ARRAY[100] OF RECORD
	dividendo		LIKE veht028.v28_dividendo, 
	capital			LIKE veht028.v28_val_cap, 
	interes			LIKE veht028.v28_val_int, 
	fecha			LIKE veht028.v28_fecha_vcto
END RECORD

DEFINE vm_ind_financ		SMALLINT
DEFINE rm_financ ARRAY[100] OF RECORD
	dividendo		LIKE veht028.v28_dividendo,
	fecha			LIKE veht028.v28_fecha_vcto,
	capital			LIKE veht028.v28_val_cap,
	interes			LIKE veht028.v28_val_int,
	adicional		LIKE veht028.v28_val_adi
END RECORD
DEFINE r_financ ARRAY[100] OF RECORD
	dividendo		LIKE veht028.v28_dividendo,
	fecha			LIKE veht028.v28_fecha_vcto,
	capital			LIKE veht028.v28_val_cap,
	interes			LIKE veht028.v28_val_int,
	adicional		LIKE veht028.v28_val_adi
END RECORD

DEFINE vm_credito_directo	LIKE veht006.v06_cred_direct



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
LET vg_proceso = 'vehp201'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

LET vm_numprev = 0
IF num_args() = 5 THEN
	LET vm_numprev  = arg_val(5)
END IF

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_control_status_caja(vg_codcia, vg_codloc, 'P') RETURNING int_flag
IF int_flag <> 0 THEN
	RETURN
END IF	
CALL fl_chequeo_mes_proceso_veh(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
LET vm_max_rows     = 1000
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_201 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_201 FROM '../forms/vehf201_1'
DISPLAY FORM f_201

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v26.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 250  

INITIALIZE vm_linea, vm_areaneg TO NULL
LET vm_tipo_pago_cuotai = 'C'

IF vm_numprev <> 0 THEN
	CALL execute_query()
END IF

MENU 'OPCIONES'
	BEFORE MENU
		CALL setea_botones_f1()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Bloquear/Activar'
		IF vm_numprev <> 0 THEN         -- Se ejecuta en modo de solo
			HIDE OPTION 'Ingresar'  -- consulta
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Detalle'
		END IF
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
		    END IF
			IF fl_control_permiso_opcion('Bloquear') THEN
				SHOW OPTION 'Bloquear/Activar'
			END IF

			SHOW OPTION 'Detalle'

		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Detalle'
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
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
		    END IF
			IF fl_control_permiso_opcion('Bloquear') THEN
				SHOW OPTION 'Bloquear/Activar'
			END IF
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			IF fl_control_permiso_opcion('Modificar') THEN			
				SHOW OPTION 'Modificar'
		    END IF
			IF fl_control_permiso_opcion('Bloquear') THEN
				SHOW OPTION 'Bloquear/Activar'
			END IF
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Detalle'

		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		CALL setea_botones_f1()
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()
		INITIALIZE vm_linea TO NULL
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
		INITIALIZE vm_linea TO NULL
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('D') 'Detalle'		'Muestra detalle de la preventa'
		CALL consulta_detalle() 
	COMMAND KEY('B') 'Bloquear/Activar'     'Bloquea o activa registro.'
		CALL control_bloquea_activa()
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

DEFINE num_elm		SMALLINT
DEFINE done    		SMALLINT

DEFINE num_rows 	SMALLINT

INITIALIZE rm_v26.* TO NULL
INITIALIZE vm_linea, vm_areaneg TO NULL

LET rm_v26.v26_fecing      = CURRENT
LET rm_v26.v26_usuario     = vg_usuario
LET rm_v26.v26_compania    = vg_codcia
LET rm_v26.v26_localidad   = vg_codloc
LET rm_v26.v26_cont_cred   = 'R'
LET rm_v26.v26_estado      = 'A'
DISPLAY 'ACTIVO' TO n_estado

LET rm_v26.v26_moneda      = rg_gen.g00_moneda_base
LET rm_v26.v26_tot_bruto   = 0
LET rm_v26.v26_tot_neto    = 0
LET rm_v26.v26_tot_dscto   = 0
LET rm_v26.v26_tot_costo   = 0
LET rm_v26.v26_tot_pa_nc   = 0
LET rm_v26.v26_sdo_credito = 0
LET rm_v26.v26_cuotai_fin  = 0   
LET rm_v26.v26_int_saldo   = 0

INITIALIZE rm_v27[1].* TO NULL

FOR num_elm = 1 TO 100
	INITIALIZE rm_docs[num_elm].valor_usar TO NULL
END FOR 

LET vm_ind_v27    = 0
LET vm_ind_cuotai = 0
LET vm_ind_financ = 0
LET vm_ind_docs   = 0

CLEAR FORM
CALL muestra_contadores()

CALL lee_datos('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET num_elm = ingresa_detalle('I')
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
		INITIALIZE rm_v26.* TO NULL
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

BEGIN WORK

IF vm_tipo_pago_cuotai = 'C' THEN
	INITIALIZE rm_v26.v26_num_cuotaif,
		   rm_v26.v26_int_cuotaif
		TO NULL 
END IF

SELECT MAX(v26_numprev) INTO rm_v26.v26_numprev
	FROM veht026
	WHERE v26_compania  = vg_codcia
	  AND v26_localidad = vg_codloc
IF rm_v26.v26_numprev IS NULL THEN
	LET rm_v26.v26_numprev = 1
ELSE
	LET rm_v26.v26_numprev = rm_v26.v26_numprev + 1
END IF

INSERT INTO veht026 VALUES (rm_v26.*)

DISPLAY BY NAME rm_v26.v26_numprev

LET num_rows = vm_num_rows 

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
						-- procesada

LET done = graba_detalle_preventa()
IF NOT done THEN
	ROLLBACK WORK
	LET vm_num_rows = num_rows
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
		INITIALIZE rm_v26.* TO NULL
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET done = aplica_pa_nc()
IF NOT done THEN
	ROLLBACK WORK
	LET vm_num_rows = num_rows
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
		INITIALIZE rm_v26.* TO NULL
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

IF rm_v26.v26_cont_cred <> 'C' OR vm_tipo_pago_cuotai <> 'C' THEN
	-- Ambos cuota inicial y plan de financiamiento
	LET done = registra_vencimientos()
	IF NOT done THEN
		ROLLBACK WORK
		LET vm_num_rows = num_rows
		IF vm_num_rows = 0 THEN
			CLEAR FORM
			CALL muestra_contadores()
			INITIALIZE rm_v26.* TO NULL
		ELSE		
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
END IF
LET done = actualiza_caja()
IF NOT done THEN
	ROLLBACK WORK
	LET vm_num_rows = num_rows
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
		INITIALIZE rm_v26.* TO NULL
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
COMMIT WORK

LET vm_row_current = vm_num_rows

CALL muestra_contadores()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

DEFINE done 		SMALLINT
DEFINE num_elm		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v26.v26_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
			    'No puede modificar este registro',
			    'exclamation')
	RETURN
END IF 

CALL lee_muestra_registro(vm_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM veht026 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_v26.*
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
LET num_elm = ingresa_detalle('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
		INITIALIZE rm_v26.* TO NULL
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

UPDATE veht026 SET * = rm_v26.* WHERE CURRENT OF q_upd

LET done = graba_detalle_preventa()
IF NOT done THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

LET done = aplica_pa_nc()
IF NOT done THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

IF rm_v26.v26_cont_cred <> 'C' OR vm_tipo_pago_cuotai <> 'C' THEN
	-- Ambos cuota inicial y plan de financiamiento
	LET done = registra_vencimientos()
	IF NOT done THEN
		ROLLBACK WORK
		CLEAR FORM
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
	END IF
END IF
LET done = actualiza_caja()
IF NOT done THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE flag 		CHAR(1)
DEFINE resp 		CHAR(6)

DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_z00		RECORD LIKE cxct000.*

DEFINE saldo_venc	LIKE cxct030.z30_saldo_venc
DEFINE moneda		LIKE cxct030.z30_moneda

LET INT_FLAG = 0
INPUT BY NAME rm_v26.v26_numprev, rm_v26.v26_estado, rm_v26.v26_codcli,    
	      rm_v26.v26_vendedor, rm_v26.v26_moneda, rm_v26.v26_paridad, 
              rm_v26.v26_bodega, rm_v26.v26_cont_cred,
	      rm_v26.v26_usuario, rm_v26.v26_fecing 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v26_numprev, v26_codcli, v26_vendedor, 
				     v26_cont_cred, v26_moneda  
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
		IF INFIELD(v26_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING r_v02.v02_bodega, r_v02.v02_nombre
			IF r_v02.v02_bodega IS NOT NULL THEN
				LET rm_v26.v26_bodega = r_v02.v02_bodega
				DISPLAY BY NAME rm_v26.v26_bodega
				DISPLAY r_v02.v02_nombre TO n_bodega
			END IF
		END IF
            	IF INFIELD(v26_vendedor) THEN
         	  	CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING r_v01.v01_vendedor, r_v01.v01_nombres
                  	LET rm_v26.v26_vendedor = r_v01.v01_vendedor
                 	DISPLAY BY NAME rm_v26.v26_vendedor  
			DISPLAY r_v01.v01_nombres TO n_vendedor
            	END IF
            	IF INFIELD(v26_codcli) THEN
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc) 
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
                  		LET rm_v26.v26_codcli = r_z01.z01_codcli
                 		DISPLAY BY NAME rm_v26.v26_codcli  
				DISPLAY r_z01.z01_nomcli TO n_cliente
			END IF
            	END IF
		IF INFIELD(v26_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_v26.v26_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_v26.v26_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f1()
	AFTER FIELD v26_bodega
		IF rm_v26.v26_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_veh(vg_codcia, rm_v26.v26_bodega)
				RETURNING r_v02.*
			IF r_v02.v02_bodega IS NOT NULL THEN
				IF r_v02.v02_estado <> 'B' THEN
					IF r_v02.v02_factura = 'N' THEN
						CALL fgl_winmessage(vg_producto,
						     'No se pueden emitir ' ||
						     'facturas en esta bodega',
						     'exclamation')
						CLEAR n_bodega
						NEXT FIELD v26_bodega
					END IF
					DISPLAY r_v02.v02_nombre TO n_bodega
				ELSE
					CALL fgl_winmessage(vg_producto,
						            'Bodega está ' ||
                                                            'bloqueada',
							    'exclamation')
					CLEAR n_bodega  
					NEXT FIELD v26_bodega
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Bodega no existe',
						    'exclamation')
				CLEAR n_bodega
				NEXT FIELD v26_bodega
			END IF
		ELSE
			CLEAR n_bodega
		END IF		 
	AFTER FIELD v26_codcli      
		IF rm_v26.v26_codcli IS NULL THEN
			CLEAR n_cliente
		ELSE
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
				rm_v26.v26_codcli) RETURNING r_z02.*
			IF r_z02.z02_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente ' ||
                                                    'con ese código en esta ' ||
						    'localidad.',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD v26_codcli     
			END IF
			CALL fl_lee_cliente_general(rm_v26.v26_codcli) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente '||
                                                    'con ese código',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD v26_codcli     
        		END IF   
			IF r_z01.z01_estado = 'B' THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'El cliente '||
                                                    'está bloqueado',
                                                    'exclamation')
				CLEAR n_cliente
				NEXT FIELD v26_codcli      
			END IF
			LET rm_v26.v26_codcli = r_z01.z01_codcli
        		DISPLAY BY NAME rm_v26.v26_codcli     
			DISPLAY r_z01.z01_nomcli TO n_cliente
			DISPLAY r_z01.z01_paga_impto TO iva
			IF r_z01.z01_paga_impto = 'S' THEN
				DISPLAY rg_gen.g00_porc_impto TO porc_iva
			ELSE
				DISPLAY 0 TO porc_iva
			END IF
		END IF
	AFTER FIELD v26_vendedor
		IF rm_v26.v26_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_veh(vg_codcia, rm_v26.v26_vendedor)
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
					NEXT FIELD v26_vendedor
				END IF
			ELSE
				CALL fgl_winmessage(vg_producto,
					            'Vendedor no existe',
						    'exclamation')
				CLEAR n_vendedor
				NEXT FIELD v26_vendedor
			END IF
		ELSE
			CLEAR n_vendedor
		END IF
	AFTER FIELD v26_moneda
		IF rm_v26.v26_moneda IS NULL THEN
			CLEAR n_moneda
		ELSE
			CALL fl_lee_moneda(rm_v26.v26_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN	
				CALL FGL_WINMESSAGE(vg_producto, 
                             		            'Moneda no existe',        
                                        	    'exclamation')
				CLEAR n_moneda
				NEXT FIELD v26_moneda
			ELSE
				IF  r_mon.g13_moneda <> rg_gen.g00_moneda_base
				AND r_mon.g13_moneda <> rg_gen.g00_moneda_alt
				THEN
					CALL fgl_winmessage(vg_producto,
							    'La moneda debe ' ||
							    'ser la moneda ' ||
							    'base o la ' ||
							    'moneda alterna',
							    'exclamation')
					CLEAR n_moneda
					LET rm_v26.v26_moneda = 
						rg_gen.g00_moneda_base
					DISPLAY BY NAME rm_v26.v26_moneda
					NEXT FIELD v26_moneda
				END IF
				IF r_mon.g13_estado = 'B' THEN
					CALL FGL_WINMESSAGE(vg_producto, 
                            		 	            'Moneda está ' ||
                               	                            'bloqueada',        
                                       	                    'exclamation')
					CLEAR n_moneda
					NEXT FIELD v26_moneda
				ELSE
					DISPLAY r_mon.g13_nombre TO n_moneda
					LET rm_v26.v26_precision = 
						r_mon.g13_decimales

					LET rm_v26.v26_paridad =
						calcula_paridad(
							rm_v26.v26_moneda,
							rg_gen.g00_moneda_base)
					IF rm_v26.v26_paridad IS NULL THEN
						LET rm_v26.v26_moneda =
							rg_gen.g00_moneda_base
						DISPLAY BY NAME 
							rm_v26.v26_moneda
						LET rm_v26.v26_paridad =
							calcula_paridad(
						   	     rm_v26.v26_moneda,							      rg_gen.g00_moneda_base)
					END IF
					DISPLAY BY NAME rm_v26.v26_paridad
					CALL muestra_etiquetas()
				END IF
			END IF 
		END IF
	AFTER INPUT
		IF rm_v26.v26_bodega IS NULL THEN
			NEXT FIELD v26_bodega
		END IF
		CALL fl_retorna_saldo_vencido(vg_codcia, rm_v26.v26_codcli) 
			RETURNING moneda, saldo_venc
		IF saldo_venc > 0 THEN
			CALL fl_lee_moneda(moneda) RETURNING r_mon.*
			CALL fgl_winmessage(vg_producto,
				'El cliente tiene un saldo vencido ' ||
				'de ' || saldo_venc || ' en la ' ||
				'moneda ' || r_mon.g13_nombre || '.',
				'info')	
		END IF	
		CALL muestra_etiquetas()
END INPUT

END FUNCTION



FUNCTION control_consulta()

DEFINE expr_sql			VARCHAR(500)
DEFINE query			VARCHAR(600)

DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_mon		RECORD LIKE gent013.*

DEFINE r_prev RECORD
	numprev		LIKE veht026.v26_numprev,
	nomcli		LIKE cxct001.z01_nomcli, 
	estado		LIKE veht026.v26_estado
END RECORD

CLEAR FORM
CALL muestra_contadores()

CALL setea_botones_f1()

LET INT_FLAG = 0
CONSTRUCT BY NAME expr_sql 
	ON v26_numprev, v26_estado, v26_codcli, v26_vendedor, v26_reserva, 
	   v26_cont_cred, v26_moneda, v26_bodega, v26_paridad, v26_tot_bruto, 
	   v26_tot_dscto, v26_tot_neto, v26_codigo_plan, v26_cod_tran, 
	   v26_num_tran, v26_usuario 
	ON KEY(F2)
		IF INFIELD(v26_numprev) THEN
			CALL fl_ayuda_preventas_veh(vg_codcia, vg_codloc, 'M')
				RETURNING r_prev.* 
			IF r_prev.numprev IS NOT NULL THEN
				LET rm_v26.v26_numprev = r_prev.numprev
				DISPLAY BY NAME rm_v26.v26_numprev
			END IF
		END IF
		IF INFIELD(v26_bodega) THEN
			CALL fl_ayuda_bodegas_veh(vg_codcia) 
				RETURNING r_v02.v02_bodega, r_v02.v02_nombre
			IF r_v02.v02_bodega IS NOT NULL THEN
				LET rm_v26.v26_bodega = r_v02.v02_bodega
				DISPLAY BY NAME rm_v26.v26_bodega
				DISPLAY r_v02.v02_nombre TO n_bodega
			END IF
		END IF
            	IF INFIELD(v26_vendedor) THEN
         	  	CALL fl_ayuda_vendedores_veh(vg_codcia) 
				RETURNING r_v01.v01_vendedor, r_v01.v01_nombres
                  	LET rm_v26.v26_vendedor = r_v01.v01_vendedor
                 	DISPLAY BY NAME rm_v26.v26_vendedor  
			DISPLAY r_v01.v01_nombres TO n_vendedor
            	END IF
            	IF INFIELD(v26_codcli) THEN
         	  	CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc) 
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
                  	LET rm_v26.v26_codcli = r_z01.z01_codcli
                 	DISPLAY BY NAME rm_v26.v26_codcli  
			DISPLAY r_z01.z01_nomcli TO n_cliente
            	END IF
		IF INFIELD(v26_moneda) THEN
			CALL fl_ayuda_monedas() 
				RETURNING r_mon.g13_moneda, r_mon.g13_nombre, 
					  r_mon.g13_decimales 
			IF r_mon.g13_moneda IS NOT NULL THEN
				LET rm_v26.v26_moneda = r_mon.g13_moneda
				DISPLAY BY NAME rm_v26.v26_moneda
				DISPLAY r_mon.g13_nombre TO n_moneda
			END IF	
		END IF
		LET INT_FLAG = 0
END CONSTRUCT

IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL muestra_contadores()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET query = 'SELECT *, ROWID FROM veht026 ',  
            '	WHERE v26_compania  = ', vg_codcia, 
	    '	  AND v26_localidad = ', vg_codloc,
	    '     AND ', expr_sql,
	    '	ORDER BY 1, 2, 3'  
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_v26.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CLEAR FORM
	CALL muestra_contadores()
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_bloquea_activa()

DEFINE resp    	CHAR(6)
DEFINE estado	CHAR(1)

LET int_flag = 0
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL lee_muestra_registro(vm_rows[vm_row_current])

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp = 'Yes' THEN
	WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM veht026 
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_v26.*
	IF status < 0 THEN
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF

	LET estado = 'B'
	IF rm_v26.v26_estado <> 'A' THEN
		LET estado = 'A'
	END IF

	UPDATE veht026 SET v26_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	CLOSE q_del
	WHENEVER ERROR STOP
	LET int_flag = 0 
	
	CALL fl_mensaje_registro_modificado()

	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF

SELECT * INTO rm_v26.* FROM veht026 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_v26.v26_numprev,
		rm_v26.v26_estado,    
		rm_v26.v26_codcli,    
		rm_v26.v26_vendedor,  
		rm_v26.v26_cont_cred,      
		rm_v26.v26_bodega,
		rm_v26.v26_moneda,     
		rm_v26.v26_paridad,      
		rm_v26.v26_tot_bruto,
		rm_v26.v26_tot_dscto,      
		rm_v26.v26_tot_neto,     
		rm_v26.v26_cuotai_fin,   
		rm_v26.v26_int_cuotaif, 
		rm_v26.v26_num_cuotaif,    
		rm_v26.v26_codigo_plan,  
		rm_v26.v26_num_vctos, 
		rm_v26.v26_int_saldo,  
		rm_v26.v26_cod_tran, 
		rm_v26.v26_num_tran, 
		rm_v26.v26_reserva,       
		rm_v26.v26_usuario,
		rm_v26.v26_fecing  

LET vm_ind_v27 = lee_detalle()
CALL lee_datos_pa_nc()
CALL lee_datos_cuotai()
IF rm_v26.v26_cont_cred = 'R' THEN
	CALL lee_datos_forma_pago()
END IF

CALL setea_botones_f1()

CALL muestra_valores()
CALL muestra_detalle()
CALL muestra_etiquetas()
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_valores()

DEFINE total_neto	LIKE veht026.v26_tot_neto
DEFINE sdo_credito	LIKE veht026.v26_sdo_credito
DEFINE anticipos	LIKE veht026.v26_tot_pa_nc
DEFINE resto_pa_nc	LIKE veht026.v26_tot_pa_nc

LET total_neto = rm_v26.v26_tot_neto                

LET anticipos = 0
IF vm_tipo_pago_cuotai = 'F' THEN
	LET sdo_credito = total_neto - rm_v26.v26_cuotai_fin 
			  - rm_v26.v26_tot_pa_nc
	IF rm_v26.v26_tot_pa_nc >= 0 THEN
		LET resto_pa_nc = rm_v26.v26_tot_pa_nc
	END IF
ELSE
	LET sdo_credito = total_neto - rm_v26.v26_tot_pa_nc
	IF rm_v26.v26_tot_pa_nc >= rm_v26.v26_cuotai_fin THEN
		LET anticipos = rm_v26.v26_cuotai_fin
		LET resto_pa_nc = rm_v26.v26_tot_pa_nc - rm_v26.v26_cuotai_fin
	ELSE
		LET anticipos = rm_v26.v26_tot_pa_nc
		LET resto_pa_nc = 0
	END IF
END IF

DISPLAY BY NAME resto_pa_nc,     
		rm_v26.v26_cuotai_fin,   
		sdo_credito,
		anticipos,
		total_neto   

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY '  ' TO vm_row_current1
CLEAR vm_row_current1

DISPLAY vm_row_current, vm_num_rows TO vm_row_current2, vm_num_rows2 
DISPLAY vm_row_current, vm_num_rows TO vm_row_current1, vm_num_rows1 

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

DEFINE i		SMALLINT
DEFINE subtotal		LIKE veht026.v26_tot_neto
DEFINE iva     		LIKE veht026.v26_tot_neto
DEFINE nom_estado	CHAR(9)

DEFINE r_v06		RECORD LIKE veht006.*
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_v01		RECORD LIKE veht001.*
DEFINE r_v02		RECORD LIKE veht002.*

CASE rm_v26.v26_estado
	WHEN 'A' LET nom_estado = 'ACTIVO'
	WHEN 'B' LET nom_estado = 'BLOQUEADO'
	WHEN 'P' LET nom_estado = 'PROCESADO'
	WHEN 'F' LET nom_estado = 'FACTURADO'
END CASE
DISPLAY nom_estado   TO n_estado

LET subtotal = 0
FOR i = 1 TO vm_ind_v27
	IF rm_v27[i].total IS NOT NULL THEN
		LET subtotal = subtotal + rm_v27[i].total
	END IF	
END FOR
DISPLAY subtotal TO subtotal

CALL fl_lee_cliente_general(rm_v26.v26_codcli) RETURNING r_z01.*
DISPLAY r_z01.z01_nomcli TO n_cliente
DISPLAY r_z01.z01_paga_impto TO iva
IF r_z01.z01_paga_impto = 'S' THEN
	DISPLAY rg_gen.g00_porc_impto TO porc_iva
	LET iva = subtotal * (rg_gen.g00_porc_impto / 100)
ELSE
	CLEAR porc_iva
	LET iva = 0
END IF
DISPLAY iva      TO valor_iva

CALL fl_lee_vendedor_veh(vg_codcia, rm_v26.v26_vendedor) RETURNING r_v01.*
DISPLAY r_v01.v01_nombres TO n_vendedor

CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_v27[1].codigo_veh)
	RETURNING r_v22.*
CALL etiquetas_vehiculo(r_v22.*)

CALL fl_lee_plan_financiamiento(vg_codcia, rm_v26.v26_codigo_plan)
	RETURNING r_v06.*
DISPLAY r_v06.v06_nonbre_plan TO n_plan

CALL fl_lee_bodega_veh(vg_codcia, rm_v26.v26_bodega) RETURNING r_v02.*
DISPLAY r_v02.v02_nombre TO n_bodega

CALL fl_lee_moneda(rm_v26.v26_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda
-- Muestra la paridad de la moneda
LET rm_v26.v26_precision = r_g13.g13_decimales
LET rm_v26.v26_paridad = calcula_paridad(rm_v26.v26_moneda,
 				rg_gen.g00_moneda_base)
IF rm_v26.v26_paridad IS NULL THEN
	LET rm_v26.v26_moneda = rg_gen.g00_moneda_base
	DISPLAY BY NAME rm_v26.v26_moneda
	LET rm_v26.v26_paridad = calcula_paridad(rm_v26.v26_moneda,
					rg_gen.g00_moneda_base)
END IF
DISPLAY BY NAME rm_v26.v26_paridad

END FUNCTION



FUNCTION lee_detalle()

DEFINE i		SMALLINT
DEFINE dummy		LIKE veht003.v03_linea
DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_v27		RECORD LIKE veht027.*

DECLARE q_det CURSOR FOR
	SELECT v27_codigo_veh, v27_precio, v27_descuento, v27_val_descto 
		FROM veht027
		WHERE v27_compania  = vg_codcia
		  AND v27_localidad = vg_codloc  
		  AND v27_numprev   = rm_v26.v26_numprev

LET i = 1
FOREACH q_det INTO rm_v27[i].codigo_veh, rm_v27[i].precio, rm_v27[i].descuento,
                   rm_v27[i].val_descto
	LET rm_v27[i].total = rm_v27[i].precio - rm_v27[i].val_descto	
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

IF i > 0 THEN
	CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					rm_v27[1].codigo_veh)
		RETURNING r_v22.*
	CALL valida_linea(r_v22.v22_modelo) RETURNING dummy
END IF

RETURN i

END FUNCTION



FUNCTION etiquetas_vehiculo(r_v22)

DEFINE r_v22		RECORD LIKE veht022.*

IF r_v22.v22_codigo_veh IS NULL THEN
	CLEAR serie
	CLEAR modelo
	CLEAR color
ELSE
	DISPLAY r_v22.v22_chasis    TO serie
	DISPLAY r_v22.v22_modelo    TO modelo
	DISPLAY r_v22.v22_cod_color TO color
END IF

END FUNCTION



FUNCTION ingresa_detalle(flag)

DEFINE flag		CHAR(1)
DEFINE i 		SMALLINT
DEFINE j 		SMALLINT
DEFINE ind  	 	SMALLINT
DEFINE continuar	SMALLINT
DEFINE salir    	SMALLINT
DEFINE resp		CHAR(6)

DEFINE saldo 		LIKE veht026.v26_sdo_credito

DEFINE veh		LIKE veht027.v27_codigo_veh

DEFINE r_v22		RECORD LIKE veht022.* 
DEFINE r_v33		RECORD LIKE veht033.* 
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_v01		RECORD LIKE veht001.*

DEFINE r_serveh RECORD
        v22_codigo_veh          LIKE veht022.v22_codigo_veh,
        v22_chasis              LIKE veht022.v22_chasis,
        v22_modelo              LIKE veht022.v22_modelo,
        v22_cod_color           LIKE veht022.v22_cod_color,
        v22_bodega              LIKE veht022.v22_bodega
END RECORD

DISPLAY BY NAME rm_v26.v26_tot_bruto,
		rm_v26.v26_tot_dscto,
		rm_v26.v26_tot_neto
DISPLAY 0 TO valor_iva
DISPLAY 0 TO subtotal

LET saldo = 0
LET salir = 0
WHILE NOT salir
LET INT_FLAG = 0
LET j = 1
CALL set_count(vm_ind_v27)
INPUT ARRAY rm_v27 WITHOUT DEFAULTS FROM ra_v27.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F7)
		LET saldo = rm_v26.v26_sdo_credito
		CALL pa_nc(flag)
		LET INT_FLAG = 0
		CALL calcula_saldo()
		IF saldo <> rm_v26.v26_sdo_credito THEN
			IF vm_ind_financ > 0 AND rm_v26.v26_cont_cred = 'R' THEN
				CALL vencimientos_saldo(rm_financ[1].fecha, 30)
			END IF 
		END IF
		LET saldo = rm_v26.v26_sdo_credito
		CALL muestra_valores()
		DISPLAY BY NAME rm_v26.v26_cont_cred,
				rm_v26.v26_num_cuotaif,
				rm_v26.v26_int_cuotaif,
			   	rm_v26.v26_codigo_plan,
			   	rm_v26.v26_num_vctos,
			   	rm_v26.v26_int_saldo,
			   	rm_v26.v26_reserva
	ON KEY(F6)
		IF rm_v26.v26_tot_pa_nc = rm_v26.v26_tot_neto THEN
			CALL fgl_winmessage(vg_producto, 
					    'No hay saldo a financiar', 
					    'exclamation')
		ELSE
			LET saldo = rm_v26.v26_sdo_credito
			CALL control_cuotaif(flag)
			CALL calcula_saldo()
			IF saldo <> rm_v26.v26_sdo_credito THEN
				IF vm_ind_financ > 0 THEN
					CALL vencimientos_saldo(
						rm_financ[1].fecha, 
						30)
				END IF 
			END IF
			LET saldo = rm_v26.v26_sdo_credito
		END IF
		LET INT_FLAG = 0
		DISPLAY BY NAME	rm_v26.v26_num_cuotaif,
				rm_v26.v26_int_cuotaif
		CALL muestra_valores()
	ON KEY(F5)
		IF rm_v26.v26_tot_pa_nc = rm_v26.v26_tot_neto THEN
			CALL fgl_winmessage(vg_producto, 
					    'No hay saldo a financiar', 
					    'exclamation')
		ELSE
			CALL calcula_saldo()
			CALL forma_pago(flag)
			CALL calcula_saldo()
			CALL muestra_valores()
			LET saldo = rm_v26.v26_sdo_credito
		END IF		
		LET INT_FLAG = 0
		CALL muestra_etiquetas()
		DISPLAY BY NAME rm_v26.v26_codigo_plan,
				rm_v26.v26_int_saldo,
				rm_v26.v26_num_vctos,
				rm_v26.v26_reserva
	ON KEY(F2)
		IF INFIELD(v27_codigo_veh) THEN
			CALL fl_ayuda_serie_veh(vg_codcia, vg_codloc, 
						rm_v26.v26_bodega) 
				RETURNING r_serveh.*
			IF r_serveh.v22_codigo_veh IS NOT NULL THEN
				LET rm_v27[i].codigo_veh = 
					r_serveh.v22_codigo_veh
				CALL fl_lee_cod_vehiculo_veh(vg_codcia, 
					vg_codloc, r_serveh.v22_codigo_veh)
						RETURNING r_v22.*
				CALL etiquetas_vehiculo(r_v22.*)
				DISPLAY rm_v27[i].codigo_veh
					TO ra_v27[j].v27_codigo_veh
			END IF
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT 
		CALL calcula_totales(vm_ind_v27)
		CALL setea_botones_f1()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					     rm_v27[i].codigo_veh)
							RETURNING r_v22.*
		CALL etiquetas_vehiculo(r_v22.*)
	BEFORE FIELD v27_codigo_veh
		LET veh = rm_v27[i].codigo_veh
		LET saldo = rm_v26.v26_sdo_credito
	AFTER FIELD v27_codigo_veh
		INITIALIZE r_v22.* TO NULL
		IF rm_v27[i].codigo_veh IS NULL THEN
			CALL etiquetas_vehiculo(r_v22.*)
			CALL blanquea_fila(i, j)
			CONTINUE INPUT            
		ELSE
			LET ind = 1
			WHILE (ind <> (arr_count()))
			IF rm_v27[i].codigo_veh = rm_v27[ind].codigo_veh 
			AND ind <> i THEN 
				CALL fgl_winmessage(vg_producto,
                                                    'No puede pre-vender ' ||
						    'el mismo ' ||		
                                                    'vehículo dos veces',
                                                    'exclamation')
				CALL etiquetas_vehiculo(r_v22.*)
				CALL blanquea_fila(i, j)
				NEXT FIELD v27_codigo_veh 
			ELSE
				LET ind = ind + 1
			END IF
			END WHILE
			CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc,
			               rm_v27[i].codigo_veh)
						RETURNING r_v22.*
			IF r_v22.v22_codigo_veh IS NULL THEN
				CALL fgl_winmessage(vg_producto,
                                                    'Código vehículo no existe',
                                                    'exclamation')
				CALL etiquetas_vehiculo(r_v22.*)
				CALL blanquea_fila(i, j)
				NEXT FIELD v27_codigo_veh 
			ELSE
				LET continuar = 1
				IF r_v22.v22_estado = 'P' THEN
					CALL fgl_winmessage(vg_producto,
							    'No puede '||
							    'realizar ' ||
                                                            'transacciones ' ||
							    'sobre este ' ||
							    'vehículo',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'F' THEN
					CALL fgl_winmessage(vg_producto,
							    'Esta vehículo ' ||
							    'ya ha sido ' || 
							    'facturado',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'B' THEN
					CALL fgl_winmessage(vg_producto,
							    'Vehículo ' ||
							    'bloqueado',
 		                                            'exclamation')
					LET continuar = 0
				END IF 
				IF rm_v26.v26_bodega <> r_v22.v22_bodega 
					THEN
					CALL fgl_winmessage(vg_producto,
							    'Vehículo no ' ||
							    'existe' ||
							    ' en esta bodega',
							    'exclamation')
					LET continuar = 0
				END IF 
				IF r_v22.v22_estado = 'R' THEN
-----------------
					SELECT * INTO r_v33.*
						FROM veht033
						WHERE v33_compania = vg_codcia
						  AND v33_localidad = vg_codloc
						  AND v33_codigo_veh = 
							rm_v27[i].codigo_veh
-----------------
					IF r_v33.v33_codcli <> rm_v26.v26_codcli
					OR r_v33.v33_vendedor <>
						rm_v26.v26_vendedor 
					THEN
					CALL fl_lee_cliente_general(
						r_v33.v33_codcli)
						RETURNING r_z01.*
					CALL fl_lee_vendedor_veh(vg_codcia,
						r_v33.v33_vendedor)
						RETURNING r_v01.*
						CALL fgl_winmessage(vg_producto,
							'Este vehículo ha ' ||
							'sido reservado por '||
							r_v01.v01_nombres ||
							' para el cliente ' ||
							r_z01.z01_nomcli,
							'exclamation')
						LET continuar = 0
					END IF
				END IF
				IF continuar = 0 THEN
					INITIALIZE r_v22.* TO NULL
					CALL etiquetas_vehiculo(r_v22.*)
					CALL blanquea_fila(i, j)
					NEXT FIELD v27_codigo_veh
				END IF
				IF rm_v26.v26_moneda <> r_v22.v22_moneda_prec
				THEN
					CALL fgl_winmessage(vg_producto,
						            'El precio de ' ||
							    'este vehículo ' ||
						            'está ' ||
							    'en una moneda '||
							    'distinta a la ' ||
							    'del documento',
							    'exclamation')
					CALL blanquea_fila(i, j)
					NEXT FIELD v27_codigo_veh	 
				END IF	
				IF vm_linea <> valida_linea(r_v22.v22_modelo)
				THEN
					CALL fgl_winmessage(vg_producto,
							    'No puede vender '||							    'vehículos que '||
							    'pertenezcan a '||
							    'diferentes ' || 
							    'lineas en la '||
							    'misma pre-venta',
							    'exclamation')
					IF arr_count() = 1 THEN
						INITIALIZE vm_linea TO NULL
					END IF
					CALL blanquea_fila(i, j)
					NEXT FIELD v27_codigo_veh	 
				END IF
				CALL etiquetas_vehiculo(r_v22.*)
				LET rm_v27[i].precio = r_v22.v22_precio 
				DISPLAY rm_v27[i].precio TO ra_v27[j].v27_precio
				IF veh <> rm_v27[i].codigo_veh
 				OR rm_v27[i].total IS NULL 
				THEN
					LET rm_v27[i].total = rm_v27[i].precio
					DISPLAY rm_v27[i].total
							TO ra_v27[j].total
				END IF
				CALL calcula_totales(arr_count())
				CALL calcula_saldo()
				IF saldo <> rm_v26.v26_sdo_credito THEN
					LET vm_ind_financ = 0
				END IF
			END IF
		END IF
	AFTER FIELD v27_descuento
		IF rm_v27[i].descuento IS NULL THEN 
			CONTINUE INPUT
		END IF
		-- IS NOT NULL
		IF rm_v27[i].val_descto >= rm_v27[i].precio THEN
			CALL fgl_winmessage(vg_producto,
 					    'El descuento excede al valor ' ||
					    'de la pre-venta',
					    'exclamation')
			NEXT FIELD v27_descuento
		END IF
		LET rm_v27[i].val_descto = 
			(rm_v27[i].descuento * rm_v27[i].precio) / 100
		DISPLAY rm_v27[i].val_descto TO ra_v27[j].v27_val_descto
		LET rm_v27[i].total = rm_v27[i].precio - rm_v27[i].val_descto
		DISPLAY rm_v27[i].total TO ra_v27[j].total
		CALL calcula_totales(arr_count())
	AFTER FIELD v27_val_descto
		IF rm_v27[i].val_descto IS NULL THEN
			CONTINUE INPUT
		END IF
		-- IS NOT NULL
		IF rm_v27[i].val_descto >= rm_v27[i].precio THEN
			CALL fgl_winmessage(vg_producto,
 					    'El descuento excede al valor ' ||
					    'de la pre-venta',
					    'exclamation')
			NEXT FIELD v27_val_descto
		END IF
		LET rm_v27[i].val_descto = 
			fl_retorna_precision_valor(rm_v26.v26_moneda,
						    rm_v27[i].val_descto)
		LET rm_v27[i].descuento =
			(100 * rm_v27[i].val_descto) / rm_v27[i].precio
		LET rm_v27[i].total = rm_v27[i].precio - rm_v27[i].val_descto
		DISPLAY rm_v27[i].total TO ra_v27[j].total
		DISPLAY rm_v27[i].descuento TO ra_v27[j].v27_descuento
		CALL calcula_totales(arr_count())
	BEFORE INSERT
		INITIALIZE r_v22.* TO NULL
		CALL etiquetas_vehiculo(r_v22.*)
		CALL blanquea_fila(i, j)
		CALL calcula_totales(arr_count())
	AFTER DELETE
		LET vm_ind_v27 = arr_count()
		IF vm_ind_v27 = 0 THEN
			INITIALIZE vm_linea TO NULL
			INITIALIZE vm_ind_docs TO NULL
			INITIALIZE vm_ind_v27 TO NULL
			INITIALIZE vm_ind_cuotai TO NULL
			INITIALIZE vm_ind_financ TO NULL
		END IF
		CALL calcula_totales(arr_count())
		EXIT INPUT
	AFTER INPUT
		CALL calcula_totales(arr_count())
		IF rm_v26.v26_cuotai_fin = 0 AND vm_tipo_pago_cuotai = 'F' THEN
			LET vm_tipo_pago_cuotai = 'C'
			INITIALIZE rm_v26.v26_int_cuotaif,
				   rm_v26.v26_num_cuotaif
				TO NULL
		END IF
		IF rm_v26.v26_cont_cred = 'C' THEN
			IF vm_tipo_pago_cuotai = 'C' 
			AND rm_v26.v26_cuotai_fin > 0
			THEN
				IF rm_v26.v26_tot_pa_nc <> rm_v26.v26_tot_neto 
				THEN
					CALL fgl_winmessage(vg_producto,
						'El total de pagos ' ||
						'anticipados debe '  ||
						'ser igual al total '||
						'neto de la factura',
						'exclamation')
					CALL calcula_saldo()
					CONTINUE INPUT
				END IF
				LET rm_v26.v26_cuotai_fin  = 0
				INITIALIZE rm_v26.v26_num_cuotaif TO NULL
				INITIALIZE rm_v26.v26_int_cuotaif TO NULL
			END IF
			IF vm_tipo_pago_cuotai = 'F' THEN
				IF (rm_v26.v26_tot_pa_nc + 
				    rm_v26.v26_cuotai_fin)
				<> rm_v26.v26_tot_neto 
				THEN
					CALL fgl_winmessage(vg_producto,
						'El total de pagos ' ||
						'anticipados mas la cuota ' ||
						'inicial debe '  ||
						'ser igual al total '||
						'neto de la factura',
						'exclamation')
					CALL calcula_saldo()
					CONTINUE INPUT
				END IF
			END IF
			INITIALIZE rm_v26.v26_reserva     TO NULL
			LET rm_v26.v26_sdo_credito = 0
			INITIALIZE rm_v26.v26_codigo_plan TO NULL
			INITIALIZE rm_v26.v26_num_vctos TO NULL
			LET rm_v26.v26_int_saldo   = 0
		END IF
		IF rm_v26.v26_cont_cred = 'R' THEN
			IF vm_tipo_pago_cuotai = 'C' THEN
				IF rm_v26.v26_tot_pa_nc < rm_v26.v26_cuotai_fin
				THEN
					CALL fgl_winmessage(vg_producto,
						'El total de pagos '   ||
						'anticipados debe '    ||
						'ser mayor o igual a ' ||
						'la cuota inicial',
						'exclamation')
					CALL calcula_saldo()
					CONTINUE INPUT
				END IF
			END IF
			IF vm_ind_financ = 0 THEN
				CALL fgl_winmessage(vg_producto,
					'No se han generado los dividendos ' ||
					'de la forma de pago',
					'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		LET salir = 1
		LET vm_ind_v27 = arr_count()
END INPUT
IF INT_FLAG THEN
	RETURN 0
END IF
END WHILE

RETURN i

END FUNCTION
	


FUNCTION blanquea_fila(i, j)

DEFINE i 		SMALLINT
DEFINE j		SMALLINT

INITIALIZE rm_v27[i].* TO NULL
LET rm_v27[i].descuento  = 0
LET rm_v27[i].val_descto = 0
DISPLAY rm_v27[i].* TO ra_v27[j].*

END FUNCTION



FUNCTION lee_datos_pa_nc()

DEFINE i		SMALLINT
DEFINE j		SMALLINT

DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_v29		RECORD LIKE veht029.*

DECLARE q_read_v29 CURSOR FOR
	SELECT * FROM veht029
		WHERE v29_compania  = vg_codcia
		  AND v29_localidad = vg_codloc
		  AND v29_numprev   = rm_v26.v26_numprev

DECLARE q_read_z21 CURSOR FOR
	SELECT * FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
		  AND z21_codcli    = rm_v26.v26_codcli
		  AND z21_areaneg   = vm_areaneg
		  AND z21_moneda    = rm_v26.v26_moneda
		  AND z21_saldo     > 0		
		ORDER BY z21_fecha_emi 

LET vm_ind_docs = 1
FOREACH q_read_z21 INTO r_z21.*
	LET rm_docs[vm_ind_docs].tipo_doc  = r_z21.z21_tipo_doc
	LET rm_docs[vm_ind_docs].num_doc   = r_z21.z21_num_doc
	LET rm_docs[vm_ind_docs].moneda    = r_z21.z21_moneda	
	LET rm_docs[vm_ind_docs].fecha     = r_z21.z21_fecha_emi
	LET rm_docs[vm_ind_docs].valor_doc = r_z21.z21_saldo
	INITIALIZE rm_docs[vm_ind_docs].valor_usar TO NULL
	LET vm_ind_docs = vm_ind_docs + 1
	IF vm_ind_docs > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH

LET vm_ind_docs = vm_ind_docs - 1
LET j = vm_ind_docs

FOREACH q_read_v29 INTO r_v29.* 
	FOR i = 1 TO vm_ind_docs 
		IF rm_docs[i].tipo_doc = r_v29.v29_tipo_doc 
		AND rm_docs[i].num_doc = r_v29.v29_numdoc 
		THEN
			LET rm_docs[i].valor_usar = r_v29.v29_valor 
			CONTINUE FOREACH
		END IF
	END FOR
	LET j = j + 1
	LET rm_docs[j].tipo_doc  = r_v29.v29_tipo_doc
	LET rm_docs[j].num_doc   = r_v29.v29_numdoc
	LET rm_docs[j].moneda    = r_v29.v29_moneda	
	INITIALIZE rm_docs[j].fecha TO NULL 
	INITIALIZE rm_docs[j].valor_doc TO NULL 
	LET rm_docs[i].valor_usar = r_v29.v29_valor 
END FOREACH

LET vm_ind_docs = j

END FUNCTION



FUNCTION valida_linea(modelo)

DEFINE modelo		LIKE veht020.v20_modelo

DEFINE r_v03		RECORD LIKE veht003.*
DEFINE r_v20		RECORD LIKE veht020.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g03		RECORD LIKE gent003.*

CALL fl_lee_modelo_veh(vg_codcia, modelo) RETURNING r_v20.*

IF vm_linea IS NULL THEN
	CALL fl_lee_linea_veh(vg_codcia, r_v20.v20_linea) RETURNING r_v03.*
	CALL fl_lee_grupo_linea(vg_codcia, r_v03.v03_grupo_linea) 
		RETURNING r_g20.*
	CALL fl_lee_area_negocio(vg_codcia, r_g20.g20_areaneg)
		RETURNING r_g03.*

	IF r_g03.g03_modulo <> vg_modulo THEN
		CALL fgl_winmessage(vg_producto,
			'La línea del vehículo no pertenece al área ' ||
			'de negocios de Vehículos.',
			'stop')
		EXIT PROGRAM
	END IF

	LET vm_linea   = r_v20.v20_linea
	LET vm_areaneg = r_g20.g20_areaneg 
END IF				

RETURN r_v20.v20_linea

END FUNCTION



FUNCTION pa_nc(flag)

DEFINE flag		CHAR(1)
DEFINE i		SMALLINT 
DEFINE j		SMALLINT 
DEFINE salir		SMALLINT 
DEFINE resp		CHAR(6)

DEFINE resto		LIKE veht026.v26_tot_pa_nc

DEFINE r_z21		RECORD LIKE cxct021.*

IF rm_v26.v26_tot_neto <= 0 OR rm_v26.v26_tot_neto IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
			    'No hay valor para cancelar',
			    'exclamation')
	RETURN
END IF

IF vm_ind_docs > 0 THEN
	FOR i = 1 TO vm_ind_docs 
		LET r_docs[i].* = rm_docs[i].*
	END FOR
END IF

OPEN WINDOW w_201_3 AT 07,07 WITH 14 ROWS, 68 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
OPEN FORM f_201_3 FROM '../forms/vehf201_3'
DISPLAY FORM f_201_3


IF flag = 'I' OR flag = 'M' THEN

DECLARE q_read_doc CURSOR FOR
	SELECT * FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
		  AND z21_codcli    = rm_v26.v26_codcli
		  AND z21_areaneg   = vm_areaneg
		  AND z21_moneda    = rm_v26.v26_moneda
		  AND z21_saldo     > 0		
		ORDER BY z21_fecha_emi 

LET i = 1
FOREACH q_read_doc INTO r_z21.*
	LET r_docs[i].tipo_doc   = r_z21.z21_tipo_doc 
	LET r_docs[i].num_doc    = r_z21.z21_num_doc
	LET r_docs[i].moneda     = r_z21.z21_moneda
	LET r_docs[i].fecha      = r_z21.z21_fecha_emi
	LET r_docs[i].valor_doc  = r_z21.z21_saldo
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH	
	END IF
END FOREACH
LET i = i - 1
LET vm_ind_docs = i

IF i = 0 THEN
	CALL fgl_winmessage(vg_producto,
			    'No hay documentos a favor para este cliente',
			    'exclamation')
	LET rm_v26.v26_tot_pa_nc = 0
	CLOSE WINDOW w_201_3
	RETURN
END IF

END IF

CALL calcula_pa_nc(vm_ind_docs)

IF flag = 'C' OR rm_v26.v26_estado <> 'A' THEN
	CALL setea_botones_f3()
	CALL set_count(vm_ind_docs)
	DISPLAY ARRAY r_docs TO ra_docs.*
	CLOSE WINDOW w_201_3
	RETURN
END IF

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
	
LET salir = 0
WHILE NOT salir
LET INT_FLAG = 0
CALL set_count(vm_ind_docs)
INPUT ARRAY r_docs WITHOUT DEFAULTS FROM ra_docs.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')
		CALL setea_botones_f3()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line() 
	AFTER ROW
		CALL calcula_pa_nc(vm_ind_docs)
	AFTER FIELD valor_usar
		IF r_docs[i].valor_usar > r_docs[i].valor_doc THEN
			CALL fgl_winmessage(vg_producto,
					    'El saldo del documento es ' ||
					    'insuficiente', 'exclamation')
			NEXT FIELD valor_usar
		END IF
		CALL calcula_pa_nc(vm_ind_docs)
	BEFORE INSERT
		EXIT INPUT
	BEFORE DELETE
		EXIT INPUT
	AFTER INPUT 
		CALL calcula_pa_nc(vm_ind_docs)
		IF rm_v26.v26_tot_pa_nc > rm_v26.v26_tot_neto THEN
			CALL fgl_winmessage(vg_producto,
				'El total de los pagos anticipados ' ||
				'aplicados es mayor al total de la ' ||
				'factura',
				'exclamation') 
			CONTINUE INPUT
		END IF
		IF rm_v26.v26_tot_pa_nc = rm_v26.v26_tot_neto THEN
			IF rm_v26.v26_cont_cred = 'R'
			OR vm_tipo_pago_cuotai = 'F'
			 THEN
				CALL fgl_winquestion(vg_producto,
					'El total de los pagos anticipados ' ||
					'aplicados es igual al total de la ' ||
					'factura, desea cancelar todo ' ||
				        'al contado', 'No', 'Yes|No',
					'question', 1) RETURNING resp 
				IF resp = 'Yes' THEN
					LET rm_v26.v26_cont_cred = 'C'
					LET vm_tipo_pago_cuotai  = 'C'
					LET rm_v26.v26_sdo_credito = 0
					LET rm_v26.v26_cuotai_fin  = 0
					LET rm_v26.v26_int_saldo   = 0
					INITIALIZE rm_v26.v26_num_cuotaif,
						   rm_v26.v26_int_cuotaif,
						   rm_v26.v26_codigo_plan,
						   rm_v26.v26_num_vctos,
						   rm_v26.v26_reserva
						TO NULL
				ELSE
					CONTINUE INPUT
				END IF	
			END IF
		END IF
		IF rm_v26.v26_cont_cred = 'R' AND vm_tipo_pago_cuotai = 'F' THEN
			IF rm_v26.v26_tot_pa_nc = 
				(rm_v26.v26_tot_neto - rm_v26.v26_cuotai_fin)
			THEN
				CALL fgl_winquestion(vg_producto,
					'El total de los pagos anticipados ' ||
					'aplicados es igual al saldo de la ' ||
					'factura, desea cancelar el saldo ' ||
				        'al contado', 'No', 'Yes|No',
					'question', 1) RETURNING resp 
				IF resp = 'Yes' THEN
					LET rm_v26.v26_cont_cred = 'C'
					LET rm_v26.v26_sdo_credito = 0
					LET rm_v26.v26_int_saldo   = 0
					INITIALIZE rm_v26.v26_codigo_plan,
						   rm_v26.v26_num_vctos,
						   rm_v26.v26_reserva
						TO NULL
				END IF
			END IF 
		END IF
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_201_3
	RETURN
END IF
END WHILE

CLOSE WINDOW w_201_3

FOR i = 1 TO vm_ind_docs
	LET rm_docs[i].* = r_docs[i].*
END FOR

END FUNCTION



FUNCTION calcula_pa_nc(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i 		SMALLINT

LET rm_v26.v26_tot_pa_nc = 0
FOR i = 1 TO num_elm
	IF r_docs[i].valor_usar IS NOT NULL THEN
		LET rm_v26.v26_tot_pa_nc = 
			rm_v26.v26_tot_pa_nc + r_docs[i].valor_usar
	END IF
END FOR

CALL calcula_saldo()
DISPLAY BY NAME rm_v26.v26_tot_pa_nc,
		rm_v26.v26_cuotai_fin,
		rm_v26.v26_sdo_credito	

END FUNCTION



FUNCTION calcula_totales(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i 		SMALLINT

DEFINE r_v22		RECORD LIKE veht022.*
DEFINE r_z01		RECORD LIKE cxct001.*

DEFINE bruto		LIKE veht026.v26_tot_bruto
DEFINE subtotal		LIKE veht026.v26_tot_neto 
DEFINE dscto		LIKE veht026.v26_tot_dscto
DEFINE costo		LIKE veht026.v26_tot_costo
DEFINE neto		LIKE veht026.v26_tot_neto
DEFINE iva 		LIKE veht026.v26_tot_dscto

DEFINE neto_ant		LIKE veht026.v26_tot_neto

LET bruto    = 0
LET subtotal = 0
LET dscto    = 0
LET costo    = 0
LET neto     = 0
LET neto_ant = rm_v26.v26_tot_neto

FOR i = 1 TO num_elm 
	IF rm_v27[i].precio IS NOT NULL THEN
		LET bruto = bruto + rm_v27[i].precio
	END IF
	IF rm_v27[i].val_descto IS NOT NULL THEN
		LET dscto = dscto + rm_v27[i].val_descto
	END IF
	IF rm_v27[i].total IS NOT NULL THEN
		LET subtotal = subtotal + rm_v27[i].total
	END IF	

	CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, rm_v27[i].codigo_veh)
		RETURNING r_v22.*
	IF r_v22.v22_costo_ing IS NOT NULL THEN
		LET costo = costo + (r_v22.v22_costo_ing * 
					calcula_paridad(r_v22.v22_moneda_ing,
							rm_v26.v26_moneda))
	END IF
	IF r_v22.v22_cargo_ing IS NOT NULL THEN
		LET costo = costo + (r_v22.v22_cargo_ing *
					calcula_paridad(r_v22.v22_moneda_ing,
							rm_v26.v26_moneda))
	END IF
	IF r_v22.v22_costo_adi IS NOT NULL THEN
		LET costo = costo + (r_v22.v22_costo_adi *
					calcula_paridad(r_v22.v22_moneda_ing,
							rm_v26.v26_moneda))
	END IF
END FOR

CALL fl_lee_cliente_general(rm_v26.v26_codcli) RETURNING r_z01.*
IF r_z01.z01_paga_impto = 'S' THEN
	LET iva = subtotal * (rg_gen.g00_porc_impto / 100)
ELSE
	LET iva = 0
END IF
LET neto = subtotal + iva

LET rm_v26.v26_tot_bruto  = bruto   
LET rm_v26.v26_tot_dscto  = dscto
LET rm_v26.v26_tot_neto   = neto
LET rm_v26.v26_tot_costo  = costo

DISPLAY subtotal TO subtotal
DISPLAY iva TO valor_iva

DISPLAY BY NAME	rm_v26.v26_tot_bruto,
		rm_v26.v26_tot_dscto,
		rm_v26.v26_tot_neto

CALL calcula_saldo()
CALL muestra_valores()

END FUNCTION



FUNCTION calcula_saldo()

DEFINE saldo 		LIKE veht026.v26_sdo_credito

IF rm_v26.v26_cont_cred = 'C' THEN
	LET rm_v26.v26_sdo_credito = 0
	INITIALIZE rm_v26.v26_num_vctos, rm_v26.v26_int_saldo TO NULL
	RETURN
END IF

LET rm_v26.v26_sdo_credito = rm_v26.v26_tot_neto - rm_v26.v26_cuotai_fin 

LET saldo = 0
IF vm_tipo_pago_cuotai = 'F' THEN
	LET saldo = rm_v26.v26_tot_pa_nc
ELSE
	IF rm_v26.v26_tot_pa_nc >= rm_v26.v26_cuotai_fin THEN
		LET saldo = rm_v26.v26_tot_pa_nc - rm_v26.v26_cuotai_fin
	END IF
END IF

LET rm_v26.v26_sdo_credito = rm_v26.v26_sdo_credito - saldo

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

LET filas_pant = fgl_scr_size('ra_v27')

FOR i = 1 TO filas_pant 
	INITIALIZE rm_v27[i].* TO NULL
	CLEAR ra_v27[i].*
END FOR

LET i = lee_detalle()
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF

LET vm_ind_v27 = i

IF vm_ind_v27 < filas_pant THEN
	LET filas_pant = vm_ind_v27
END IF

FOR i = 1 TO filas_pant   
	DISPLAY rm_v27[i].* TO ra_v27[i].*
END FOR

END FUNCTION



FUNCTION muestra_cuota_det()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

LET filas_pant = fgl_scr_size('ra_cuotai')

FOR i = 1 TO filas_pant 
	CLEAR ra_cuotai[i].*
END FOR

IF vm_ind_cuotai < filas_pant THEN
	LET filas_pant = vm_ind_cuotai
END IF

FOR i = 1 TO filas_pant   
	DISPLAY rm_cuotai[i].* TO ra_cuotai[i].*
END FOR

CALL total_dividendo_cuotai()

END FUNCTION



FUNCTION muestra_forma_pago_det()

DEFINE i		SMALLINT
DEFINE filas_pant	SMALLINT

DEFINE dummy		LIKE veht026.v26_sdo_credito

LET filas_pant = fgl_scr_size('ra_financ')

FOR i = 1 TO filas_pant 
	CLEAR ra_financ[i].*
END FOR

IF vm_ind_financ < filas_pant THEN
	LET filas_pant = vm_ind_financ
END IF

FOR i = 1 TO filas_pant   
	DISPLAY rm_financ[i].* TO ra_financ[i].*
END FOR

DISPLAY BY NAME rm_v26.v26_reserva

CALL total_dividendo_pagos() RETURNING dummy

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



FUNCTION control_cuotaif(flag)

DEFINE flag		CHAR(1)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE salir		SMALLINT
DEFINE fila 		SMALLINT
DEFINE resp		CHAR(6)
DEFINE val_div		LIKE veht028.v28_val_cap
DEFINE saldo		LIKE veht028.v28_val_cap
DEFINE resto		LIKE veht026.v26_cuotai_fin
DEFINE fecha_ant	LIKE veht028.v28_fecha_vcto
DEFINE val_cap_ant	LIKE veht028.v28_val_cap

DEFINE modified 	SMALLINT

DEFINE cuotai_ant	LIKE veht026.v26_cuotai_fin
DEFINE num_ant		LIKE veht026.v26_num_cuotaif
DEFINE int_ant		LIKE veht026.v26_int_cuotaif
DEFINE tipo_pago_ant    LIKE veht026.v26_cont_cred

IF flag = 'C' AND rm_v26.v26_cuotai_fin = 0 THEN 
	CALL fgl_winmessage(vg_producto,
		'No se dio cuota inicial en esta preventa.',
		'exclamation')
	RETURN
END IF

IF rm_v26.v26_tot_neto <= 0 OR rm_v26.v26_tot_neto IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
			    'No hay valor a financiar.',
			    'exclamation')
	RETURN
END IF

OPEN WINDOW w_201_2 AT 7,12 WITH 17 ROWS, 63 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_201_2 FROM '../forms/vehf201_2'
DISPLAY FORM f_201_2

IF vm_ind_cuotai > 0 THEN
	CALL muestra_cuota_det()
	FOR i = 1 TO vm_ind_cuotai
		LET r_cuotai[i].* = rm_cuotai[i].*
	END FOR
END IF

IF rm_v26.v26_codigo_plan IS NULL THEN
	IF rm_v26.v26_cuotai_fin IS NULL THEN
		LET rm_v26.v26_cuotai_fin = 0	
	END IF
END IF
IF vm_tipo_pago_cuotai = 'C' THEN
	LET rm_v26.v26_num_cuotaif = 1
	LET rm_v26.v26_int_cuotaif = 0
END IF

LET INT_FLAG = 0
INPUT BY NAME rm_v26.v26_cuotai_fin, rm_v26.v26_num_cuotaif, 
	      rm_v26.v26_int_cuotaif, vm_tipo_pago_cuotai 
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(v26_cuotai_fin, v26_num_cuotaif, 
				     v26_int_cuotaif, vm_tipo_pago_cuotai) 
		THEN
			EXIT INPUT
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		CALL setea_botones_f2()
		LET cuotai_ant    = rm_v26.v26_cuotai_fin
		LET num_ant       = rm_v26.v26_num_cuotaif
		LET int_ant       = rm_v26.v26_int_cuotaif
		LET tipo_pago_ant = vm_tipo_pago_cuotai
		IF flag = 'C' THEN
			LET modified = 0
			EXIT INPUT
		END IF
	AFTER FIELD v26_cuotai_fin
		IF rm_v26.v26_cuotai_fin IS NULL THEN
			CONTINUE INPUT
		END IF
		IF rm_v26.v26_cuotai_fin > 
			(rm_v26.v26_tot_neto - rm_v26.v26_tot_pa_nc)
		THEN
			CALL fgl_winmessage(vg_producto,
					    'El valor de la cuota inicial ' ||
					    'no puede ser mayor que el ' ||
					    'valor de la deuda',
					    'exclamation')
			NEXT FIELD v26_cuotai_fin
		END IF
		IF rm_v26.v26_codigo_plan IS NOT NULL 
		AND cuotai_ant > rm_v26.v26_cuotai_fin 
		THEN
			LET rm_v26.v26_cuotai_fin = cuotai_ant
			CALL fgl_winmessage(vg_producto,
					'Debido al plan de financiamiento ' ||
					'que escogio la cuota inicial no '  ||
					'no puede ser menor a ' || cuotai_ant,
					'exclamation')
			DISPLAY BY NAME rm_v26.v26_cuotai_fin
		END IF
	AFTER FIELD vm_tipo_pago_cuotai
		IF vm_tipo_pago_cuotai = 'C' THEN
			LET rm_v26.v26_num_cuotaif = 1
			LET rm_v26.v26_int_cuotaif = 0
			DISPLAY BY NAME rm_v26.v26_num_cuotaif,
					rm_v26.v26_int_cuotaif
		END IF
	BEFORE FIELD v26_num_cuotaif
		IF vm_tipo_pago_cuotai = 'C' THEN
			NEXT FIELD vm_tipo_pago_cuotai
		END IF
	BEFORE FIELD v26_int_cuotaif
		IF vm_tipo_pago_cuotai = 'C' THEN
			NEXT FIELD vm_tipo_pago_cuotai
		END IF
	AFTER INPUT 
		IF vm_tipo_pago_cuotai = 'F' THEN
			IF rm_v26.v26_cuotai_fin = 0 THEN
				LET vm_tipo_pago_cuotai = 'C'
				LET rm_v26.v26_num_cuotaif = 1
				LET rm_v26.v26_int_cuotaif = 0
				DISPLAY BY NAME vm_tipo_pago_cuotai,
						rm_v26.v26_num_cuotaif,
						rm_v26.v26_int_cuotaif
			END IF
		END IF
		IF rm_v26.v26_num_cuotaif <= 0 
		OR rm_v26.v26_num_cuotaif IS NULL 
		THEN
			CONTINUE INPUT
		END IF
		IF rm_v26.v26_int_cuotaif < 0 
		OR rm_v26.v26_int_cuotaif IS NULL 
		THEN
			CONTINUE INPUT
		END IF
		LET modified = 0
		IF cuotai_ant <> rm_v26.v26_cuotai_fin 
		OR num_ant    <> rm_v26.v26_num_cuotaif
		OR int_ant    <> rm_v26.v26_int_cuotaif
		OR vm_tipo_pago_cuotai <> tipo_pago_ant THEN
			LET modified = 1
		END IF 
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_201_2
	IF vm_ind_cuotai > 0 THEN	
		LET rm_v26.v26_cuotai_fin  = cuotai_ant
		LET rm_v26.v26_num_cuotaif = num_ant
		LET rm_v26.v26_int_cuotaif = int_ant
		LET vm_tipo_pago_cuotai    = tipo_pago_ant
	END IF
	IF vm_tipo_pago_cuotai = 'C' THEN
		INITIALIZE rm_v26.v26_num_cuotaif, 
			   rm_v26.v26_int_cuotaif 
			TO NULL
	END IF
	RETURN
END IF
IF modified OR vm_tipo_pago_cuotai = 'C' THEN
	LET resto = rm_v26.v26_cuotai_fin
	LET saldo = rm_v26.v26_cuotai_fin
	LET val_div = rm_v26.v26_cuotai_fin / rm_v26.v26_num_cuotaif
	FOR i = 1 TO rm_v26.v26_num_cuotaif	
		LET r_cuotai[i].dividendo = i
		LET r_cuotai[i].capital   = val_div
		LET resto = resto - val_div
		LET r_cuotai[i].interes   = 
			saldo * (rm_v26.v26_int_cuotaif / 100) * (1/12)
		LET saldo = saldo - val_div
		IF vm_tipo_pago_cuotai = 'F' THEN
			LET r_cuotai[i].fecha     = 
				calcula_fecha_vcmto(i, TODAY + 
						    obtener_dias(month(TODAY),
						    year(TODAY)), NULL)
		ELSE
			INITIALIZE r_cuotai[i].fecha TO NULL
		END IF
	END FOR
	LET i = i - 1
	IF resto <> 0 THEN
		LET r_cuotai[i].capital =
			r_cuotai[i].capital + resto 
	END IF
	LET vm_ind_cuotai = i
END IF

IF flag = 'C' OR rm_v26.v26_estado <> 'A' OR rm_v26.v26_int_cuotaif > 0 
OR vm_tipo_pago_cuotai = 'C' THEN
	CALL total_dividendo_cuotai()
	CALL set_count(vm_ind_cuotai)
	DISPLAY ARRAY r_cuotai TO ra_cuotai.*
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT', '')
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	CLOSE WINDOW w_201_2
	IF vm_tipo_pago_cuotai = 'C' THEN
		INITIALIZE rm_v26.v26_num_cuotaif, 
			   rm_v26.v26_int_cuotaif 
			TO NULL
	END IF
	RETURN
END IF

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31

LET salir = 0
WHILE NOT salir
LET INT_FLAG = 0
LET j = 1
CALL set_count(vm_ind_cuotai)
INPUT ARRAY r_cuotai WITHOUT DEFAULTS FROM ra_cuotai.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')
		CALL setea_botones_f2()
		CALL total_dividendo_cuotai()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	AFTER FIELD v28_val_cap
		CALL total_dividendo_cuotai()
	BEFORE INSERT 
		EXIT INPUT
	BEFORE DELETE
		EXIT INPUT
	AFTER INPUT 
		CALL total_dividendo_cuotai()
		LET val_div = 0
		FOR i = vm_ind_cuotai TO 1 STEP -1
			IF r_cuotai[i].capital IS NOT NULL 
			AND r_cuotai[i].capital > 0 THEN
				LET val_div = val_div + r_cuotai[i].capital
			ELSE
				CALL fgl_winmessage(vg_producto,
					    'No puede dejar cuotas con ' ||
					    'valor cero',
					    'exclamation')
				CONTINUE INPUT
			END IF
			IF r_cuotai[i].fecha IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					    'Debe ingresar una fecha ' ||
					    'en todas las cuotas',
					    'exclamation')
				CONTINUE INPUT
			END IF
			IF i > 1 THEN 
				IF r_cuotai[i].fecha < r_cuotai[i-1].fecha 
				THEN
					CALL fgl_winmessage(vg_producto,
					    'Una o varias de las fechas ' ||
					    'no concuerdan con el orden ' ||
					    'de los pagos',
					    'exclamation')
					CONTINUE INPUT
				END IF
			END IF
		END FOR
		IF val_div <> rm_v26.v26_cuotai_fin THEN
			CALL fgl_winmessage(vg_producto,
					    'La suma de los dividendos ' ||
					    'es diferente al valor de la ' ||
					    'cuota inicial',
					    'exclamation')
			CONTINUE INPUT
		END IF 
		LET salir = 1
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_201_2
	IF vm_ind_cuotai > 0 THEN	
		LET rm_v26.v26_cuotai_fin  = cuotai_ant
		LET rm_v26.v26_num_cuotaif = num_ant
		LET rm_v26.v26_int_cuotaif = int_ant
		LET vm_tipo_pago_cuotai    = tipo_pago_ant
		LET vm_ind_cuotai = 0
	END IF
	IF vm_tipo_pago_cuotai = 'C' THEN
		INITIALIZE rm_v26.v26_num_cuotaif, 
			   rm_v26.v26_int_cuotaif 
			TO NULL
	END IF
	RETURN
END IF
END WHILE

IF vm_tipo_pago_cuotai = 'C' THEN
	INITIALIZE rm_v26.v26_num_cuotaif, rm_v26.v26_int_cuotaif TO NULL
END IF

CLOSE WINDOW w_201_2

FOR i = 1 TO vm_ind_cuotai
	LET rm_cuotai[i].* = r_cuotai[i].*
END FOR

END FUNCTION



FUNCTION calcula_fecha_vcmto(num_div, fecha_ini, dias)
	
DEFINE dias 		SMALLINT
DEFINE i 		SMALLINT
DEFINE num_div 		LIKE veht028.v28_dividendo
DEFINE fecha		LIKE veht028.v28_fecha_vcto
DEFINE fecha_ini	LIKE veht028.v28_fecha_vcto

LET fecha = fecha_ini    

IF rm_v26.v26_codigo_plan IS NOT NULL THEN
	FOR i = 2 TO num_div
		LET fecha = fecha + obtener_dias(month(fecha), year(fecha))
	END FOR
ELSE
	FOR i = 2 TO num_div
		IF dias IS NOT NULL THEN
			LET fecha = fecha + dias
		ELSE
			LET fecha = 
				fecha + obtener_dias(month(fecha), year(fecha))
		END IF
	END FOR 
END IF

RETURN fecha         

END FUNCTION



FUNCTION obtener_dias(mes, anho)

DEFINE mes 		SMALLINT
DEFINE anho		SMALLINT

DEFINE fecha		DATE

IF (mes < 0 OR mes > 12) OR (mes IS NULL) THEN
	RETURN 0
END IF

IF mes = 12 THEN
	LET fecha = mdy('01', '01', (anho + 1))
ELSE
	LET fecha = mdy((mes + 1), '01', (anho + 1))
END IF

LET fecha = fecha - 1

RETURN day(fecha)

END FUNCTION



FUNCTION graba_detalle_preventa()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE i		SMALLINT

DEFINE r_v27		RECORD LIKE veht027.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_v27 CURSOR FOR
			SELECT * FROM veht027
				WHERE v27_compania  = vg_codcia         
				  AND v27_localidad = vg_codloc          
				  AND v27_numprev   = rm_v26.v26_numprev
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

FOREACH q_v27
	DELETE FROM veht027 WHERE CURRENT OF q_v27         
END FOREACH

LET r_v27.v27_compania  = vg_codcia
LET r_v27.v27_localidad = vg_codloc
LET r_v27.v27_numprev   = rm_v26.v26_numprev

FOR i = 1 TO vm_ind_v27
	LET r_v27.v27_codigo_veh = rm_v27[i].codigo_veh
	LET r_v27.v27_precio     = rm_v27[i].precio
	LET r_v27.v27_descuento  = rm_v27[i].descuento
	LET r_v27.v27_val_descto = rm_v27[i].val_descto

	INSERT INTO veht027 VALUES (r_v27.*)
END FOR 

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()

DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fgl_winquestion(vg_producto, 
		     'Registro bloqueado por otro usuario, desea ' ||
                     'intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
				RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso()
		 RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF

RETURN intentar

END FUNCTION



FUNCTION forma_pago(flag)

DEFINE flag		CHAR(1)
DEFINE resp 		CHAR(6)
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE fila		SMALLINT
DEFINE salir		SMALLINT
DEFINE val_div		LIKE veht028.v28_val_cap
DEFINE saldo		LIKE veht028.v28_val_cap
DEFINE fecha_ant	LIKE veht028.v28_fecha_vcto
DEFINE val_cap_ant	LIKE veht028.v28_val_cap

DEFINE modified		SMALLINT
DEFINE plan		LIKE veht026.v26_codigo_plan

DEFINE fecha      	LIKE veht028.v28_fecha_vcto
DEFINE interes    	LIKE veht026.v26_int_saldo

DEFINE primer_pago	LIKE veht028.v28_fecha_vcto
DEFINE dias		SMALLINT
DEFINE dias_ant		SMALLINT

DEFINE cuotai_ant	LIKE veht026.v26_cuotai_fin

DEFINE num_ant		LIKE veht026.v26_num_vctos

DEFINE dummy		LIKE veht026.v26_sdo_credito

DEFINE r_v06		RECORD LIKE veht006.*

IF rm_v26.v26_tot_neto <= 0 OR rm_v26.v26_tot_neto IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
			    'No hay valor a financiar',
			    'exclamation')
	RETURN
END IF

IF rm_v26.v26_cont_cred = 'C' THEN
	CALL fgl_winquestion(vg_producto,
			     'La operación se está realizando al ' ||
			     'contado, si entra a esta opción la ' ||
			     'operación se realizará a crédito, ' ||
			     'desea continuar', 'No', 'Yes|No|Cancel',
			     'question', 1) RETURNING resp
	IF resp = 'Yes' THEN
		LET rm_v26.v26_cont_cred = 'R'
		DISPLAY BY NAME rm_v26.v26_cont_cred
	ELSE  
		RETURN
	END IF
END IF

OPEN WINDOW w_201_4 AT 04,02 WITH 21 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MESSAGE LINE LAST)
OPEN FORM f_201_4 FROM '../forms/vehf201_4'
DISPLAY FORM f_201_4

LET dias = 30
LET primer_pago = 
	calcula_fecha_vcmto(1, TODAY + obtener_dias(month(TODAY), year(TODAY)),
			    NULL)
IF vm_ind_financ > 0 THEN
	IF flag = 'M' OR flag = 'C' THEN
		IF vm_ind_financ > 1 AND rm_v26.v26_int_saldo > 0 THEN
			LET dias = rm_financ[2].fecha - rm_financ[1].fecha
		END IF
		LET primer_pago = rm_financ[1].fecha
	END IF
	CALL muestra_forma_pago_det()
END IF

LET INT_FLAG = 0
INPUT BY NAME rm_v26.v26_codigo_plan, rm_v26.v26_cuotai_fin, 
	      rm_v26.v26_num_vctos, rm_v26.v26_int_saldo, primer_pago, dias 
	WITHOUT DEFAULTS 
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(v26_codigo_plan) THEN
			EXIT INPUT
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(v26_codigo_plan) THEN
			CALL fl_ayuda_planes_finan_veh(vg_codcia) 
				RETURNING r_v06.v06_codigo_plan,
					  r_v06.v06_nonbre_plan 
			IF r_v06.v06_codigo_plan IS NOT NULL THEN
				LET rm_v26.v26_codigo_plan =
					r_v06.v06_codigo_plan
				CALL etiquetas_forma_pago()
			END IF 
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		CALL setea_botones_f4()
		IF rm_v26.v26_codigo_plan IS NOT NULL THEN
			CALL etiquetas_forma_pago()
		END IF
		LET plan  = rm_v26.v26_codigo_plan
		LET fecha = primer_pago
		LET interes = rm_v26.v26_int_saldo
		LET dias_ant = dias
		LET num_ant = rm_v26.v26_num_vctos
		LET cuotai_ant = rm_v26.v26_cuotai_fin
		CALL calcula_saldo()
		DISPLAY BY NAME rm_v26.v26_sdo_credito
		IF flag = 'C' THEN
			LET modified = 0
			EXIT INPUT
		END IF
	BEFORE FIELD v26_codigo_plan
		LET plan = rm_v26.v26_codigo_plan
	AFTER FIELD v26_codigo_plan
		IF rm_v26.v26_codigo_plan IS NULL THEN
			CLEAR n_plan
			CONTINUE INPUT
		END IF

		CALL fl_lee_plan_financiamiento(vg_codcia, 
			rm_v26.v26_codigo_plan)	RETURNING r_v06.*

		IF r_v06.v06_codigo_plan IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				            'Plan no existe',
					    'exclamation')
			CLEAR n_plan
			NEXT FIELD v26_codigo_plan
		END IF
		IF r_v06.v06_estado = 'B' THEN
			CALL fgl_winmessage(vg_producto,
				            'Plan está bloqueado',
					    'exclamation')
			CLEAR n_plan
			NEXT FIELD v26_codigo_plan
		END IF
		IF plan <> rm_v26.v26_codigo_plan OR plan IS NULL THEN
			CALL fgl_winmessage(vg_producto,
				    'Este plan de financiamiento requiere ' ||
				    'que se de una cuota inicial del ' ||
				    r_v06.v06_porc_inic || '% del total ' ||
				    'de la factura',
				    'exclamation')
		END IF	
		LET rm_v26.v26_cuotai_fin = 
			rm_v26.v26_tot_neto * (r_v06.v06_porc_inic / 100)
		LET rm_v26.v26_cuotai_fin =	
			fl_retorna_precision_valor(rm_v26.v26_moneda, 
						   rm_v26.v26_cuotai_fin)
		LET vm_tipo_pago_cuotai = 'C'
		LET vm_ind_financ = 0
		LET vm_credito_directo = r_v06.v06_cred_direct
		IF r_v06.v06_cred_direct = 'N' THEN
			LET rm_v26.v26_num_vctos = 1
		END IF
		CALL etiquetas_forma_pago()
		DISPLAY BY NAME rm_v26.v26_cuotai_fin, dias,
				rm_v26.v26_num_vctos
		CALL calcula_saldo()
		DISPLAY BY NAME rm_v26.v26_sdo_credito
	BEFORE FIELD v26_cuotai_fin
		IF rm_v26.v26_codigo_plan IS NOT NULL THEN
			NEXT FIELD v26_num_vctos
		END IF
	AFTER FIELD v26_cuotai_fin
		CALL calcula_saldo()
		DISPLAY BY NAME rm_v26.v26_sdo_credito
	AFTER FIELD primer_pago
		IF primer_pago < TODAY THEN
			NEXT FIELD primer_pago
		END IF
	BEFORE FIELD dias
		IF rm_v26.v26_codigo_plan IS NOT NULL THEN
			NEXT FIELD v26_codigo_plan
		END IF
	BEFORE FIELD v26_int_saldo
		IF rm_v26.v26_codigo_plan IS NOT NULL THEN
			NEXT FIELD primer_pago
		END IF
	BEFORE FIELD v26_num_vctos
		IF rm_v26.v26_codigo_plan IS NOT NULL THEN
			NEXT FIELD primer_pago
		END IF
	BEFORE FIELD primer_pago
		IF rm_v26.v26_codigo_plan IS NOT NULL THEN
			IF vm_credito_directo = 'N' THEN
				NEXT FIELD dias   
			END IF     
		END IF
	AFTER FIELD v26_num_vctos
		IF rm_v26.v26_num_vctos <= 0 THEN
			CALL fgl_winmessage(vg_producto,
				'El número de vencimientos debe ser ' ||
				'mayor a cero',
				'exclamation')
			NEXT FIELD v26_num_vctos
		END IF
	AFTER INPUT
		IF rm_v26.v26_num_vctos IS NULL THEN
			NEXT FIELD v26_num_vctos
		END IF
		CALL calcula_saldo()
		DISPLAY BY NAME rm_v26.v26_sdo_credito
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_201_4
	RETURN    
END IF


IF rm_v26.v26_codigo_plan IS NULL THEN
	INITIALIZE plan TO NULL
	INITIALIZE vm_credito_directo TO NULL
ELSE
	LET vm_credito_directo = r_v06.v06_cred_direct
END IF

IF dias_ant <> dias THEN
	INITIALIZE fecha TO NULL
END IF

IF vm_ind_financ = 0 OR num_ant <> rm_v26.v26_num_vctos 
OR cuotai_ant <> rm_v26.v26_cuotai_fin 
THEN 
	CALL vencimientos_saldo(primer_pago, dias)
ELSE
	IF interes <> rm_v26.v26_int_saldo OR fecha <> primer_pago 
	OR cuotai_ant <> rm_v26.v26_cuotai_fin THEN
		LET saldo = rm_v26.v26_sdo_credito
		LET val_div = saldo / rm_v26.v26_num_vctos
		FOR i = 1 TO rm_v26.v26_num_vctos
			IF fecha <> primer_pago THEN
				LET rm_financ[i].fecha = 
					calcula_fecha_vcmto(i, primer_pago, 
					dias)
			END IF
			LET rm_financ[i].interes = 
				saldo * (rm_v26.v26_int_saldo / 100) * 
				(dias / 360)
			LET saldo = saldo - val_div
		END FOR 
		LET vm_ind_financ = i - 1
	END IF
END IF

-- Si el flag = 'C' (estoy en consulta) o estado es diferente de 'A' 
-- (la preventa a pasado por algun proceso) muestro la Reserva, los 
-- datos de los vencimientos y hago un RETURN.
-- Si el codigo del plan es nulo entonces solo muestro los datos de
-- los vencimientos y continuo con el ingreso

IF flag = 'C' OR rm_v26.v26_estado <> 'A' 
OR rm_v26.v26_codigo_plan IS NOT NULL 
OR rm_v26.v26_int_saldo > 0 
THEN
	IF flag = 'C' OR rm_v26.v26_estado <> 'A' THEN 
		DISPLAY BY NAME rm_v26.v26_reserva
	END IF
	DISPLAY primer_pago TO primer_pago
	LET INT_FLAG = 0
	CALL total_dividendo_pagos() RETURNING dummy
	CALL setea_botones_f4()
	CALL set_count(vm_ind_financ)
	DISPLAY ARRAY rm_financ TO ra_financ.*
		ON KEY(INTERRUPT)
			IF flag = 'C' THEN
				EXIT DISPLAY
			END IF
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT DISPLAY
			END IF
	END DISPLAY
	IF INT_FLAG THEN
		CLOSE WINDOW w_201_4
		RETURN
	END IF
	IF flag = 'C' OR rm_v26.v26_estado <> 'A' THEN 
		CLOSE WINDOW w_201_4
		RETURN
	END IF
END IF

LET salir = 0
WHILE NOT salir

LET INT_FLAG = 0
LET i = 1
LET j = 1

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31

CALL set_count(vm_ind_financ)
INPUT ARRAY rm_financ WITHOUT DEFAULTS FROM ra_financ.*
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT
		END IF
	BEFORE INPUT
		CALL dialog.keysetlabel('INSERT', '')
		CALL dialog.keysetlabel('DELETE', '')

		CALL total_dividendo_pagos() RETURNING dummy
		IF rm_v26.v26_codigo_plan IS NOT NULL 
		OR rm_v26.v26_int_saldo > 0 
		THEN
			LET salir = 1
			EXIT INPUT
		END IF
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
	BEFORE FIELD v28_fecha_vcto
		LET fecha = rm_financ[i].fecha 
	AFTER FIELD v28_fecha_vcto
		IF rm_financ[i].fecha IS NULL THEN
			LET rm_financ[i].fecha = fecha
			DISPLAY rm_financ[i].fecha 
				TO ra_financ[j].v28_fecha_vcto
		END IF
	AFTER FIELD v28_val_cap
		CALL total_dividendo_pagos() RETURNING dummy 
	AFTER FIELD v28_val_adi
		CALL total_dividendo_pagos() RETURNING dummy 
	BEFORE INSERT
		EXIT INPUT	
	BEFORE DELETE
		EXIT INPUT
	AFTER INPUT
		IF rm_v26.v26_sdo_credito <> total_dividendo_pagos() THEN
			CALL fgl_winmessage(vg_producto,
					    'La suma de los dividendos ' ||
					    'es diferente al valor del ' ||
					    'saldo a cubrir',
					    'exclamation')
			CONTINUE INPUT
		END IF
		LET val_div = 0
		FOR i = vm_ind_financ TO 1 STEP -1
			IF rm_financ[i].capital IS NOT NULL THEN
				LET val_div = val_div + rm_financ[i].capital
			ELSE
				CALL fgl_winmessage(vg_producto,
					    'No puede dejar cuotas con ' ||
					    'valor cero',
					    'exclamation')
				CONTINUE INPUT
			END IF
			IF rm_financ[i].fecha IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					    'Debe ingresar una fecha ' ||
					    'en todas las cuotas',
					    'exclamation')
				CONTINUE INPUT
			END IF
			IF i > 1 THEN 
				IF rm_financ[i].fecha < rm_financ[i-1].fecha 
				THEN
					CALL fgl_winmessage(vg_producto,
					    'Una o varias de las fechas ' ||
					    'no concuerdan con el orden ' ||
					    'de los pagos',
					    'exclamation')
					CONTINUE INPUT
				END IF
			END IF
		END FOR
		LET salir = 1	
END INPUT
IF INT_FLAG THEN
	CLOSE WINDOW w_201_4
	RETURN
END IF

END WHILE

OPTIONS INPUT NO WRAP
LET INT_FLAG = 0
INPUT BY NAME rm_v26.v26_reserva WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			EXIT INPUT     
		END IF
END INPUT
IF INT_FLAG THEN
	OPTIONS INPUT WRAP
	CLOSE WINDOW w_201_4
	RETURN
END IF
OPTIONS INPUT WRAP

CLOSE WINDOW w_201_4

END FUNCTION



FUNCTION total_dividendo_pagos()

DEFINE tot_adi 		LIKE veht028.v28_val_adi
DEFINE tot_cap		LIKE veht028.v28_val_cap
DEFINE tot_int		LIKE veht028.v28_val_int

DEFINE i 		SMALLINT

LET tot_adi = 0 
LET tot_cap = 0 
LET tot_int = 0 

FOR i = 1 TO vm_ind_financ
	IF rm_financ[i].capital IS NOT NULL THEN
		LET tot_cap = tot_cap + rm_financ[i].capital
	END IF
	IF rm_financ[i].interes IS NOT NULL THEN
		LET tot_int = tot_int + rm_financ[i].interes
	END IF
	IF rm_financ[i].adicional IS NOT NULL THEN
		LET tot_adi = tot_adi + rm_financ[i].adicional
	END IF
END FOR 

DISPLAY BY NAME tot_adi, tot_cap, tot_int

RETURN tot_adi + tot_cap

END FUNCTION



FUNCTION total_dividendo_cuotai()

DEFINE tot_cap		LIKE veht028.v28_val_cap
DEFINE tot_int		LIKE veht028.v28_val_int

DEFINE i 		SMALLINT

LET tot_cap = 0 
LET tot_int = 0 

FOR i = 1 TO vm_ind_cuotai
	IF r_cuotai[i].capital IS NOT NULL THEN
		LET tot_cap = tot_cap + r_cuotai[i].capital
	END IF
	IF r_cuotai[i].interes IS NOT NULL THEN
		LET tot_int = tot_int + r_cuotai[i].interes
	END IF
END FOR 

DISPLAY BY NAME tot_cap, tot_int

END FUNCTION



FUNCTION vencimientos_saldo(primer_pago, dias) 

DEFINE dias 		SMALLINT
DEFINE primer_pago	LIKE veht028.v28_fecha_vcto
DEFINE val_div		LIKE veht028.v28_val_cap
DEFINE saldo		LIKE veht028.v28_val_cap
DEFINE i 		SMALLINT

DEFINE r_v07		RECORD LIKE veht007.*

IF vm_credito_directo = 'N' THEN
	LET rm_v26.v26_num_vctos = 1
	LET rm_financ[1].dividendo = 1
	LET rm_financ[1].capital = rm_v26.v26_sdo_credito
	LET rm_financ[1].interes = 0
	LET rm_financ[1].adicional = 0
	LET rm_financ[1].fecha   = 
		TODAY + obtener_dias(month(TODAY), year(TODAY))
	LET vm_ind_financ = 1
	RETURN
END IF

LET saldo = rm_v26.v26_sdo_credito
LET val_div = saldo / rm_v26.v26_num_vctos
FOR i = 1 TO rm_v26.v26_num_vctos
	LET rm_financ[i].dividendo = i
	LET rm_financ[i].fecha = calcula_fecha_vcmto(i, primer_pago, dias)
	IF rm_v26.v26_codigo_plan IS NOT NULL THEN
		CALL fl_lee_coeficiente_veh(vg_codcia, 
			rm_v26.v26_codigo_plan, i) 
			RETURNING r_v07.*
		IF r_v07.v07_coefi_adic IS NOT NULL THEN
			LET rm_financ[i].adicional = 
				saldo * r_v07.v07_coefi_adic
		ELSE
			LET rm_financ[i].adicional = 0
		END IF
		LET rm_financ[i].interes = saldo * r_v07.v07_coefi_letra 
	ELSE
		LET rm_financ[i].interes = 
			saldo * (rm_v26.v26_int_saldo / 100) * (dias / 360) 
		LET rm_financ[i].adicional = 0
	END IF
	IF i = rm_v26.v26_num_vctos THEN
		LET rm_financ[i].capital = saldo
	ELSE	
		LET rm_financ[i].capital = val_div
	END IF
	LET saldo = saldo - (val_div + rm_financ[i].adicional)
END FOR 
LET vm_ind_financ = i - 1

END FUNCTION



FUNCTION etiquetas_forma_pago()

DEFINE r_v06		RECORD LIKE veht006.*

CALL fl_lee_plan_financiamiento(vg_codcia, rm_v26.v26_codigo_plan)
	RETURNING r_v06.*
LET rm_v26.v26_codigo_plan = r_v06.v06_codigo_plan 

IF vm_credito_directo = 'N' THEN
	LET rm_v26.v26_num_vctos = 1
ELSE
	SELECT MAX(v07_num_meses) INTO rm_v26.v26_num_vctos 
		FROM veht007
		WHERE v07_compania = vg_codcia
		  AND v07_codigo_plan = rm_v26.v26_codigo_plan      
END IF
LET rm_v26.v26_int_saldo   = r_v06.v06_tasa_finan 
	
DISPLAY BY NAME rm_v26.v26_codigo_plan,
		rm_v26.v26_num_vctos,
		rm_v26.v26_int_saldo
DISPLAY r_v06.v06_nonbre_plan TO n_plan

END FUNCTION



FUNCTION aplica_pa_nc()

DEFINE intentar		SMALLINT
DEFINE done 		SMALLINT
DEFINE i 		SMALLINT

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_v29		RECORD LIKE veht029.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_v29 CURSOR FOR
			SELECT * FROM veht029
				WHERE v29_compania  = vg_codcia         
				  AND v29_localidad = vg_codloc          
				  AND v29_numprev   = rm_v26.v26_numprev
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

FOREACH q_v29
	DELETE FROM veht029 WHERE CURRENT OF q_v29
END FOREACH

LET r_v29.v29_compania  = vg_codcia
LET r_v29.v29_localidad = vg_codloc
LET r_v29.v29_numprev   = rm_v26.v26_numprev

FOR i = 1 TO vm_ind_docs
	LET r_v29.v29_tipo_doc  = rm_docs[i].tipo_doc
	LET r_v29.v29_numdoc    = rm_docs[i].num_doc
	LET r_v29.v29_moneda    = rm_docs[i].moneda
	LET r_v29.v29_paridad   = 1 
	CALL fl_lee_moneda(r_v29.v29_moneda) RETURNING r_g13.*
	LET r_v29.v29_precision = r_g13.g13_decimales
	LET r_v29.v29_valor     = rm_docs[i].valor_usar

	IF r_v29.v29_valor IS NOT NULL THEN
		INSERT INTO veht029 VALUES (r_v29.*)
	END IF
END FOR 

RETURN done

END FUNCTION



FUNCTION registra_vencimientos()

DEFINE done    		SMALLINT
DEFINE intentar		SMALLINT

DEFINE i        	SMALLINT

DEFINE r_v28		RECORD LIKE veht028.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_v28 CURSOR FOR
			SELECT * FROM veht028
				WHERE v28_compania  = vg_codcia         
				  AND v28_localidad = vg_codloc          
				  AND v28_numprev   = rm_v26.v26_numprev
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE

IF NOT intentar AND NOT done THEN
	RETURN done
END IF

FOREACH q_v28
	DELETE FROM veht028 WHERE CURRENT OF q_v28
END FOREACH


IF vm_tipo_pago_cuotai = 'F' THEN
	FOR i = 1 TO vm_ind_cuotai
		INITIALIZE r_v28.* TO NULL
		LET r_v28.v28_compania  = vg_codcia
		LET r_v28.v28_localidad = vg_codloc
		LET r_v28.v28_numprev   = rm_v26.v26_numprev
		LET r_v28.v28_tipo      = 'I'
		LET r_v28.v28_val_adi   = 0
		LET r_v28.v28_dividendo  = rm_cuotai[i].dividendo
		LET r_v28.v28_fecha_vcto = rm_cuotai[i].fecha
		LET r_v28.v28_val_cap    = rm_cuotai[i].capital
		LET r_v28.v28_val_int    = rm_cuotai[i].interes
	
		INSERT INTO veht028 VALUES (r_v28.*)
	END FOR 
END IF

IF rm_v26.v26_cont_cred = 'R' THEN
	FOR i = 1 TO vm_ind_financ
		INITIALIZE r_v28.* TO NULL	
		LET r_v28.v28_compania  = vg_codcia
		LET r_v28.v28_localidad = vg_codloc
		LET r_v28.v28_numprev   = rm_v26.v26_numprev
		LET r_v28.v28_tipo      = 'V'
		LET r_v28.v28_dividendo  = rm_financ[i].dividendo
		LET r_v28.v28_fecha_vcto = rm_financ[i].fecha
		LET r_v28.v28_val_cap    = rm_financ[i].capital
		LET r_v28.v28_val_int    = rm_financ[i].interes
		IF rm_financ[i].adicional IS NULL THEN
			LET r_v28.v28_val_adi    = 0                      
		ELSE
			LET r_v28.v28_val_adi    = rm_financ[i].adicional 
		END IF

		INSERT INTO veht028 VALUES (r_v28.*)
	END FOR 
END IF

RETURN done

END FUNCTION



FUNCTION consulta_detalle()

DEFINE flag 		CHAR(1)
DEFINE i 		SMALLINT
DEFINE r_v22		RECORD LIKE veht022.*

LET flag = 'C'

CALL set_count(vm_ind_v27)
DISPLAY ARRAY rm_v27 TO ra_v27.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F7)
		CALL lee_datos_pa_nc()
-- OjO
-- Deben mostrarse solo los documentos que si se aplicaron en la preventa
		FOR i = 1 TO vm_ind_docs
			IF rm_docs[i].valor_usar <> 0 THEN
				EXIT FOR
			END IF
		END FOR
		IF i <= vm_ind_docs THEN
			CALL pa_nc(flag)
		ELSE
			CALL fgl_winmessage(vg_producto,
				'No se han aplicado pagos anticipados',
				'exclamation')
		END IF
		LET INT_FLAG = 0
	ON KEY(F6)
		CALL lee_datos_cuotai()
		CALL control_cuotaif(flag)
		LET INT_FLAG = 0
	ON KEY(F5)
		IF rm_v26.v26_cont_cred = 'C' THEN
			CALL fgl_winmessage(vg_producto,
				'La transacción se realizó al contado',
				'exclamation')
		ELSE  
			CALL lee_datos_forma_pago()
			CALL forma_pago(flag)
		END IF
		LET INT_FLAG = 0
	BEFORE ROW
		LET i = arr_curr()
		CALL fl_lee_cod_vehiculo_veh(vg_codcia, vg_codloc, 
					     rm_v27[i].codigo_veh)
			RETURNING r_v22.*
		CALL etiquetas_vehiculo(r_v22.*)
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
		CALL calcula_totales(vm_ind_v27)
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION lee_datos_forma_pago()

DEFINE r_v28		RECORD LIKE veht028.*

IF rm_v26.v26_cont_cred <> 'R' THEN
	LET vm_ind_financ = 0
	RETURN
END IF

DECLARE q_read_v28_v CURSOR FOR
	SELECT * FROM veht028
		WHERE v28_compania  = vg_codcia
		  AND v28_localidad = vg_codloc
		  AND v28_numprev   = rm_v26.v26_numprev
		  AND v28_tipo      = 'V'

LET vm_ind_financ = 1
FOREACH q_read_v28_v INTO r_v28.*

	LET rm_financ[vm_ind_financ].dividendo = r_v28.v28_dividendo	
	LET rm_financ[vm_ind_financ].fecha     = r_v28.v28_fecha_vcto	
	LET rm_financ[vm_ind_financ].capital   = r_v28.v28_val_cap
	LET rm_financ[vm_ind_financ].interes   = r_v28.v28_val_int
	LET rm_financ[vm_ind_financ].adicional = r_v28.v28_val_adi 

	LET vm_ind_financ = vm_ind_financ + 1
	IF vm_ind_financ > 100 THEN
		EXIT FOREACH
	END IF 
END FOREACH

LET vm_ind_financ = vm_ind_financ - 1

END FUNCTION



FUNCTION lee_datos_cuotai()

DEFINE r_v28		RECORD LIKE veht028.*

DECLARE q_read_v28_i CURSOR FOR
	SELECT * FROM veht028
		WHERE v28_compania  = vg_codcia
		  AND v28_localidad = vg_codloc
		  AND v28_numprev   = rm_v26.v26_numprev
		  AND v28_tipo      = 'I'

LET vm_ind_cuotai = 1
FOREACH q_read_v28_i INTO r_v28.*
	LET rm_cuotai[vm_ind_cuotai].dividendo = r_v28.v28_dividendo	
	LET rm_cuotai[vm_ind_cuotai].fecha     = r_v28.v28_fecha_vcto	
	LET rm_cuotai[vm_ind_cuotai].capital   = r_v28.v28_val_cap
	LET rm_cuotai[vm_ind_cuotai].interes   = r_v28.v28_val_int

	LET vm_ind_cuotai = vm_ind_cuotai + 1
	IF vm_ind_cuotai > 100 THEN
		EXIT FOREACH
	END IF 
END FOREACH

LET vm_ind_cuotai = vm_ind_cuotai - 1

IF vm_ind_cuotai > 0 THEN
	LET vm_tipo_pago_cuotai = 'F'
END IF
IF vm_ind_cuotai = 0 THEN
	LET vm_tipo_pago_cuotai = 'C'
	LET vm_ind_cuotai = 1

	LET rm_cuotai[vm_ind_cuotai].dividendo = 1	
	INITIALIZE rm_cuotai[vm_ind_cuotai].fecha TO NULL       
	LET rm_cuotai[vm_ind_cuotai].capital   = rm_v26.v26_cuotai_fin
	LET rm_cuotai[vm_ind_cuotai].interes   = 0 
END IF

END FUNCTION


-- No deberia estar actualizando a caja (cajt010)
-- Eso deberia hacerlo el proceso de aprobacion de preventas
-- Eventualmente esta funcion sera retirada de aqui
-- Es llamada en las lineas 343 y 445
FUNCTION actualiza_caja()

DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_upd		RECORD LIKE cajt010.*

CALL fl_lee_cliente_general(rm_v26.v26_codcli) RETURNING r_z01.*

LET intentar = 1
LET done = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_j10 CURSOR FOR
			SELECT * FROM cajt010
				WHERE j10_compania    = vg_codcia      
				  AND j10_localidad   = vg_codloc       
				  AND j10_tipo_fuente = 'PV'
				  AND j10_num_fuente  =	rm_v26.v26_numprev
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF

OPEN q_j10
FETCH q_j10 INTO r_j10.*
	IF STATUS = NOTFOUND THEN
		-- El registro no existe, hay que grabarlo
		LET r_j10.j10_areaneg   = vm_areaneg
		LET r_j10.j10_codcli    = rm_v26.v26_codcli
		LET r_j10.j10_nomcli    = r_z01.z01_nomcli
		LET r_j10.j10_moneda    = rm_v26.v26_moneda
		IF vm_tipo_pago_cuotai = 'C' THEN
			LET r_j10.j10_valor = rm_v26.v26_tot_neto -
					      rm_v26.v26_sdo_credito -
					      rm_v26.v26_tot_pa_nc
		ELSE
			LET r_j10.j10_valor = rm_v26.v26_tot_neto -
					      (rm_v26.v26_sdo_credito +
					       rm_v26.v26_cuotai_fin) -
					      rm_v26.v26_tot_pa_nc 
		END IF
		LET r_j10.j10_fecha_pro = CURRENT
		LET r_j10.j10_usuario   = vg_usuario 
		LET r_j10.j10_fecing    = CURRENT
		LET r_j10.j10_compania    = vg_codcia
		LET r_j10.j10_localidad   = vg_codloc
		LET r_j10.j10_tipo_fuente = 'PV'
		LET r_j10.j10_num_fuente  = rm_v26.v26_numprev
		LET r_j10.j10_estado      = 'A'

		INITIALIZE r_j10.j10_codigo_caja,   
		 	   r_j10.j10_tipo_destino, 
		 	   r_j10.j10_num_destino,     
		 	   r_j10.j10_referencia,     
		 	   r_j10.j10_banco,         
			   r_j10.j10_numero_cta,   
			   r_j10.j10_tip_contable,
			   r_j10.j10_num_contable
			TO NULL    
                                                                
		INSERT INTO cajt010 VALUES(r_j10.*)
	ELSE
		LET r_j10.j10_areaneg   = vm_areaneg
		LET r_j10.j10_codcli    = rm_v26.v26_codcli
		LET r_j10.j10_nomcli    = r_z01.z01_nomcli
		LET r_j10.j10_moneda    = rm_v26.v26_moneda
		IF vm_tipo_pago_cuotai = 'C' THEN
			LET r_j10.j10_valor = rm_v26.v26_tot_neto -
					      rm_v26.v26_sdo_credito -
					      rm_v26.v26_tot_pa_nc
		ELSE
			LET r_j10.j10_valor = rm_v26.v26_tot_neto -
					      (rm_v26.v26_sdo_credito +
					       rm_v26.v26_cuotai_fin) -
					      rm_v26.v26_tot_pa_nc 
		END IF

		LET r_j10.j10_fecha_pro = CURRENT
		LET r_j10.j10_usuario   = vg_usuario 
		LET r_j10.j10_fecing    = CURRENT
	
		UPDATE cajt010 SET * = r_j10.* WHERE CURRENT OF q_j10
	END IF
CLOSE q_j10

RETURN done

END FUNCTION


FUNCTION execute_query()

LET vm_num_rows = 1
LET vm_row_current = 1

SELECT ROWID INTO vm_rows[vm_num_rows]
	FROM veht026
	WHERE v26_compania  = vg_codcia
	  AND v26_localidad = vg_codloc
	  AND v26_numprev    = vm_numprev
IF STATUS = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe preventa.', 
		'exclamation')
	EXIT PROGRAM
ELSE
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF

END FUNCTION



-- forma: vehf201_1.per
FUNCTION setea_botones_f1()

DISPLAY 'Código Veh.'  TO bt_codigo_veh
DISPLAY 'Precio Venta' TO bt_precio_venta
DISPLAY 'Dscto.'       TO bt_dscto 
DISPLAY 'Val. Dscto.'  TO bt_val_dscto
DISPLAY 'Total'        TO bt_total

END FUNCTION



-- forma: vehf201_2.per
FUNCTION setea_botones_f2()

DISPLAY 'Nro.'        TO bt_nro_vctos
DISPLAY 'Capital'     TO bt_capital     
DISPLAY 'Interés'     TO bt_interes
DISPLAY 'Fecha Vcto.' TO bt_fecha_vcto

END FUNCTION



-- forma: vehf201_3.per
FUNCTION setea_botones_f3()

DISPLAY 'Documento'       TO bt_documento 
DISPLAY 'M.'              TO bt_moneda      
DISPLAY 'Fec. Emi.'       TO bt_fec_emi
DISPLAY 'Saldo Doc.'      TO bt_saldo_doc
DISPLAY 'Valor a Aplicar' TO bt_valor_uti

END FUNCTION



-- forma: vehf201_4.per
FUNCTION setea_botones_f4()

DISPLAY 'No'              TO bt_nro
DISPLAY 'Fecha Vcto.'     TO bt_fecha_vcto  
DISPLAY 'Valor Cuota'     TO bt_val_cuota
DISPLAY 'Valor Interés'   TO bt_val_int  
DISPLAY 'Valor Adicional' TO bt_val_adi

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
