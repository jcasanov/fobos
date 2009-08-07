-----------------------------------------------------------------------------
-- Titulo           : vehp216.4gl - Aprobación de Pre-ventas
-- Elaboracion      : 15-dic-2001
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp216 base modulo compania localidad 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios		VARCHAR(12)

DEFINE vm_areaneg		LIKE gent020.g20_areaneg   
DEFINE vm_linea			LIKE veht003.v03_linea
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

DEFINE vm_ind_cuotai		SMALLINT
DEFINE rm_cuotai ARRAY[100] OF RECORD
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

DEFINE vm_credito_directo	LIKE veht006.v06_cred_direct



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN			-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'vehp216'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
LET vg_codloc   = arg_val(4)

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
OPEN WINDOW w_216 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_216 FROM '../forms/vehf216_1'
DISPLAY FORM f_216

LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_v26.* TO NULL
CALL muestra_contadores()

LET vm_max_rows = 250  

INITIALIZE vm_linea, vm_areaneg TO NULL
LET vm_tipo_pago_cuotai = 'C'

MENU 'OPCIONES'
	BEFORE MENU
		CALL setea_botones_f1()
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Aprobar'
		HIDE OPTION 'Detalle'
	COMMAND KEY('P') 'Aprobar' 		'Modificar registro corriente.'
		CALL control_aprueba()
		CALL setea_botones_f1()
	COMMAND KEY('C') 'Consultar' 		'Consultar un registro.'
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Aprobar'
			SHOW OPTION 'Detalle'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Detalle'
				HIDE OPTION 'Aprobar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Aprobar'
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
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_aprueba()

DEFINE done 			SMALLINT
DEFINE num_elm			SMALLINT
DEFINE estado			CHAR(1)

DEFINE documentos_validos 	SMALLINT
DEFINE documentos		SMALLINT
DEFINE vehiculos_disponibles 	SMALLINT
DEFINE vehiculos		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

IF rm_v26.v26_estado = 'P' THEN
	CALL fgl_winmessage(vg_producto,
			    'Esta preventa ya ha sido aprobada.',
			    'exclamation')
	RETURN
END IF 

IF rm_v26.v26_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto,
			    'No puede modificar este registro.',
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

SELECT COUNT(v29_valor) INTO documentos FROM veht029
        WHERE v29_compania  = vg_codcia
          AND v29_localidad = vg_codloc
          AND v29_numprev   = rm_v26.v26_numprev

SELECT COUNT(v29_valor) INTO documentos_validos FROM veht029, cxct021
        WHERE v29_compania  = vg_codcia
          AND v29_localidad = vg_codloc
          AND v29_numprev   = rm_v26.v26_numprev
          AND z21_compania  = v29_compania
          AND z21_localidad = v29_localidad
          AND z21_codcli    = rm_v26.v26_codcli
          AND z21_tipo_doc  = v29_tipo_doc
          AND z21_num_doc   = v29_numdoc
          AND z21_saldo    >= v29_valor
          
IF documentos_validos < documentos THEN
	CALL fgl_winmessage(vg_producto,
		'Alguna transacción ha disminuido el valor de uno o varios ' ||
		'documentos aplicados en esta preventa.',
		'exclamation')
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

SELECT COUNT(*) INTO vehiculos FROM veht027
        WHERE v27_compania  = vg_codcia
          AND v27_localidad = vg_codloc
          AND v27_numprev   = rm_v26.v26_numprev

SELECT COUNT(*) INTO vehiculos_disponibles FROM veht027, veht022
        WHERE v27_compania   = vg_codcia
          AND v27_localidad  = vg_codloc
          AND v27_numprev    = rm_v26.v26_numprev
          AND v22_compania   = v27_compania
          AND v22_localidad  = v27_localidad
          AND v22_codigo_veh = v27_codigo_veh
          AND v22_estado     IN ('A', 'R')
          
IF vehiculos_disponibles < vehiculos THEN
	CALL fgl_winmessage(vg_producto,
		'Algunos de los vehículos que intervienen en la preventa ' ||
		'ya no están disponibles.',
		'exclamation')
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

LET estado = 'P'

UPDATE veht026 SET v26_estado = estado WHERE CURRENT OF q_upd

LET done = actualiza_caja()
IF NOT done THEN
	ROLLBACK WORK
	CLEAR FORM
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

COMMIT WORK
CALL fl_mensaje_registro_modificado()
CLEAR FORM

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
	    '	  AND v26_estado = "A"',
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
			    'No hay valor para cancelar.',
			    'exclamation')
	RETURN
END IF

OPEN WINDOW w_216_3 AT 07,07 WITH 14 ROWS, 68 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
OPEN FORM f_216_3 FROM '../forms/vehf216_3'
DISPLAY FORM f_216_3

CALL calcula_pa_nc(vm_ind_docs)

CALL setea_botones_f3()
CALL set_count(vm_ind_docs)
DISPLAY ARRAY rm_docs TO ra_docs.*

CLOSE WINDOW w_216_3
RETURN

END FUNCTION



FUNCTION calcula_pa_nc(num_elm)

DEFINE num_elm		SMALLINT
DEFINE i 		SMALLINT

LET rm_v26.v26_tot_pa_nc = 0
FOR i = 1 TO num_elm
	IF rm_docs[i].valor_usar IS NOT NULL THEN
		LET rm_v26.v26_tot_pa_nc = 
			rm_v26.v26_tot_pa_nc + rm_docs[i].valor_usar
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

OPEN WINDOW w_216_2 AT 7,12 WITH 17 ROWS, 63 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_216_2 FROM '../forms/vehf216_2'
DISPLAY FORM f_216_2

IF rm_v26.v26_codigo_plan IS NULL THEN
	IF rm_v26.v26_cuotai_fin IS NULL THEN
		LET rm_v26.v26_cuotai_fin = 0	
	END IF
END IF
IF vm_tipo_pago_cuotai = 'C' THEN
	LET rm_v26.v26_num_cuotaif = 1
	LET rm_v26.v26_int_cuotaif = 0
END IF

CALL setea_botones_f2()

DISPLAY BY NAME rm_v26.v26_num_cuotaif, 
		rm_v26.v26_int_cuotaif,
		rm_v26.v26_cuotai_fin,
		vm_tipo_pago_cuotai

CALL total_dividendo_cuotai()
CALL set_count(vm_ind_cuotai)
DISPLAY ARRAY rm_cuotai TO ra_cuotai.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

	CLOSE WINDOW w_216_2

IF vm_tipo_pago_cuotai = 'C' THEN
	INITIALIZE rm_v26.v26_num_cuotaif, 
		   rm_v26.v26_int_cuotaif 
		TO NULL
END IF
RETURN

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

DEFINE plan		LIKE veht026.v26_codigo_plan

DEFINE fecha      	LIKE veht028.v28_fecha_vcto
DEFINE interes    	LIKE veht026.v26_int_saldo

DEFINE primer_pago	LIKE veht028.v28_fecha_vcto
DEFINE dias		SMALLINT

DEFINE dummy		LIKE veht026.v26_sdo_credito

DEFINE r_v06		RECORD LIKE veht006.*

IF rm_v26.v26_tot_neto <= 0 OR rm_v26.v26_tot_neto IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
			    'No hay valor a financiar.',
			    'exclamation')
	RETURN
END IF

OPEN WINDOW w_216_4 AT 04,02 WITH 21 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, 
		MESSAGE LINE LAST)
OPEN FORM f_216_4 FROM '../forms/vehf216_4'
DISPLAY FORM f_216_4

IF vm_ind_financ > 0 THEN
	IF flag = 'M' OR flag = 'C' THEN
		IF vm_ind_financ > 1 AND rm_v26.v26_int_saldo > 0 THEN
			LET dias = rm_financ[2].fecha - rm_financ[1].fecha
		END IF
		LET primer_pago = rm_financ[1].fecha
	END IF
	CALL muestra_forma_pago_det()
END IF

IF rm_v26.v26_codigo_plan IS NULL THEN
	INITIALIZE plan TO NULL
	INITIALIZE vm_credito_directo TO NULL
ELSE
	LET vm_credito_directo = r_v06.v06_cred_direct
END IF

DISPLAY BY NAME rm_v26.v26_reserva
DISPLAY primer_pago TO primer_pago
LET INT_FLAG = 0
CALL total_dividendo_pagos() RETURNING dummy

DISPLAY BY NAME rm_v26.v26_codigo_plan, 
		rm_v26.v26_cuotai_fin,
		rm_v26.v26_num_vctos,
		rm_v26.v26_sdo_credito,
		rm_v26.v26_int_saldo,
		dias

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
	CLOSE WINDOW w_216_4
	RETURN
END IF

CLOSE WINDOW w_216_4

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
	IF rm_cuotai[i].capital IS NOT NULL THEN
		LET tot_cap = tot_cap + rm_cuotai[i].capital
	END IF
	IF rm_cuotai[i].interes IS NOT NULL THEN
		LET tot_int = tot_int + rm_cuotai[i].interes
	END IF
END FOR 

DISPLAY BY NAME tot_cap, tot_int

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



FUNCTION consulta_detalle()

DEFINE flag 		CHAR(1)
DEFINE i 		SMALLINT
DEFINE r_v22		RECORD LIKE veht022.*

LET flag = 'C'

CALL set_count(vm_ind_v27)
DISPLAY ARRAY rm_v27 TO ra_v27.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F8)
		LET i = arr_curr()
		CALL ver_vehiculo(rm_v27[i].codigo_veh)
		LET INT_FLAG = 0
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
				'No se han aplicado pagos anticipados.',
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
				'La transacción se realizó al contado.',
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



FUNCTION ver_vehiculo(codigo_veh)

DEFINE codigo_veh	INTEGER
DEFINE command_line	CHAR(100)

LET command_line = 'fglrun vehp108 ', vg_base,   ' ', vg_modulo,
		                 ' ', vg_codcia, ' ', vg_codloc,
				 ' ', codigo_veh
RUN command_line

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



-- forma: vehf216_1.per
FUNCTION setea_botones_f1()

DISPLAY 'Código Veh.'  TO bt_codigo_veh
DISPLAY 'Precio Venta' TO bt_precio_venta
DISPLAY 'Dscto.'       TO bt_dscto 
DISPLAY 'Val. Dscto.'  TO bt_val_dscto
DISPLAY 'Total'        TO bt_total

END FUNCTION



-- forma: vehf216_2.per
FUNCTION setea_botones_f2()

DISPLAY 'Nro.'        TO bt_nro_vctos
DISPLAY 'Capital'     TO bt_capital     
DISPLAY 'Interés'     TO bt_interes
DISPLAY 'Fecha Vcto.' TO bt_fecha_vcto

END FUNCTION



-- forma: vehf216_3.per
FUNCTION setea_botones_f3()

DISPLAY 'Documento'       TO bt_documento 
DISPLAY 'M.'              TO bt_moneda      
DISPLAY 'Fec. Emi.'       TO bt_fec_emi
DISPLAY 'Saldo Doc.'      TO bt_saldo_doc
DISPLAY 'Valor a Aplicar' TO bt_valor_uti

END FUNCTION



-- forma: vehf216_4.per
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
