------------------------------------------------------------------------------
-- Titulo           : repp209.4gl - Ingreso de Pre-Venta
-- Elaboracion      : 04-oct-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp209 base modulo compania localidad
-- Ultima Correccion: 04-oct-2001
-- Motivo Correccion: 1
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

-- CADA VEZ QUE SE REALIZE UNA CONSULTA SE GUARDARAN LOS ROWID DE CADA FILA 
-- RECUPERADA EN UNA TABLA LLAMADA vm_rows QUE TENDRA 1000 ELEMENTOS
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE

DEFINE vm_elementos	SMALLINT	-- MAXIMO NUMERO ELEMENTOS DEL DETALLE

DEFINE vm_ini_arr       SMALLINT        -- Indica la posición actual en el
                                        -- que se empezo a mostrar la ultima vez
DEFINE vm_curr_arr      SMALLINT        -- Indica la posición actual en el
                                        -- detalle (ultimo elemento mostrado)
                                                                                
-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_r00		 	RECORD LIKE rept000.*	-- CONFIGURACION DE LA
							-- COMPAÑIA DE RPTO.
DEFINE rm_r01		 	RECORD LIKE rept001.*	-- VENDEDOR
DEFINE rm_r02		 	RECORD LIKE rept002.*	-- BODEGA
DEFINE rm_r03		 	RECORD LIKE rept003.*	-- LINEA VTA.
DEFINE rm_r04		 	RECORD LIKE rept004.*	-- INDICE DE ROTACION.
DEFINE rm_r10		 	RECORD LIKE rept010.*	-- MAESTRO ITEMS
DEFINE rm_r11		 	RECORD LIKE rept011.*	-- EXIST. ITEMS
DEFINE rm_r21			RECORD LIKE rept021.*	-- CABECERA PROFORMA
DEFINE rm_r22			RECORD LIKE rept022.*	-- DETALLE PROFORMA
DEFINE rm_r23			RECORD LIKE rept023.*	-- CABECERA PREVENTA
DEFINE rm_r24		 	RECORD LIKE rept024.*	-- DETALLE PREVENTA
DEFINE rm_r25		 	RECORD LIKE rept025.*	-- CREDITO
DEFINE rm_r26		 	RECORD LIKE rept026.*	-- DIVIDENDOS
DEFINE rm_r27		 	RECORD LIKE rept027.*	-- ANTICIPOS
DEFINE rm_g03		 	RECORD LIKE gent003.*	-- AREA NEGOCIO
DEFINE rm_g13		 	RECORD LIKE gent013.*	-- MONEDAS
DEFINE rm_g20		 	RECORD LIKE gent020.*	-- GRUPO DE LINEAS VTA
DEFINE rm_g14		 	RECORD LIKE gent014.*	-- CONV. ENTRE MONEDAS
DEFINE rm_c01		 	RECORD LIKE cxct001.*	-- CLIENTES GENERALES
DEFINE rm_c02		 	RECORD LIKE cxct002.*	-- CLIENTES CIA. LOCA
DEFINE rm_c03		 	RECORD LIKE cxct003.*	-- CLIENTES AREA NEGOCIO

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[250] OF RECORD
	r24_proformado		LIKE rept024.r24_proformado,
	r24_cant_ped		LIKE rept024.r24_cant_ped,
	r24_cant_ven		LIKE rept024.r24_cant_ven,
	r24_bodega		LIKE rept024.r24_bodega,
	r24_item		LIKE rept024.r24_item,
	r24_descuento		LIKE rept024.r24_descuento,
	r24_precio		LIKE rept024.r24_precio,
	subtotal_item		LIKE rept023.r23_tot_neto
	END RECORD
	----------------------------------------------------------
	---- ARREGLO PARA LOS CAMPOS FUERA DE MI SCREEN RECORD ----
DEFINE r_detalle_1 ARRAY[250] OF RECORD
	r24_linea		LIKE rept024.r24_linea,
	rotacion		LIKE rept010.r10_rotacion,
	costo_item		LIKE rept023.r23_tot_costo,  -- COSTO ITEM
	r24_val_descto		LIKE rept024.r24_val_descto,
	r24_val_impto		LIKE rept024.r24_val_impto,
	val_costo		LIKE rept023.r23_tot_costo    -- COSTO DE ITEMS
	END RECORD
	----------------------------------------------------------
	-------------- DETALLE ANTICIPOS -------------
DEFINE r_detalle_2 ARRAY[250] OF RECORD
	z21_tipo_doc	LIKE cxct021.z21_tipo_doc,
	z21_num_doc	LIKE cxct021.z21_num_doc,
	z21_moneda	LIKE cxct021.z21_moneda,
	z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
	z21_saldo	LIKE cxct021.z21_saldo,
	r27_valor	LIKE rept027.r27_valor
	END RECORD
DEFINE total_anticipos		LIKE rept027.r27_valor

DEFINE vm_ind_docs		SMALLINT
DEFINE vm_flag_anticipos	CHAR(1)		-- PARA SABER SI APLICO O NO
						-- ANTICIPOS 'S' o 'N'
	----------------------------------------------------------

DEFINE vm_fecha		LIKE rept023.r23_fecing		-- FECHA DE INGRESO
DEFINE vm_item_aux	LIKE rept024.r24_item	 -- PARA SABER QUE EL ITEM A
						 -- CAMBIADO MARGEN DE UTILIDAD
DEFINE vm_credito_auto		LIKE cxct002.z02_credit_auto -- CRED. AUTOMATICO
DEFINE vm_descuento_cont 	LIKE rept023.r23_descuento   -- DSCTO CONTADO 
							     -- CLIENTE
DEFINE vm_descuento_cred 	LIKE rept023.r23_descuento   -- DSCTO CREDITO
							     -- CLIENTE
DEFINE vm_plazo		 	LIKE cxct002.z02_credit_dias -- PLAZO
DEFINE vm_cupo_credito	 	LIKE cxct020.z20_saldo_cap   -- CUPO CREDITO
DEFINE vm_cupo_credito_mb 	LIKE cxct020.z20_saldo_cap   -- CUPO CREDITO
DEFINE vm_cupo_credito_ma 	LIKE cxct020.z20_saldo_cap   -- CUPO CREDITO
DEFINE cupo_credito	 	LIKE cxct020.z20_saldo_cap   -- C. CREDITO FORMA
DEFINE saldo_credito	 	LIKE cxct020.z20_saldo_cap   -- Saldo.CRED FORM
DEFINE vm_flag_mant		CHAR(1)	   -- FLAG DE MANTENIMIENTO
					   -- 'I' --> INGRESO		
					   -- 'M' --> MODIFICACION		
					   -- 'C' --> CONSULTA		
DEFINE vm_flag_proforma		CHAR(1)	-- PARA SABER SI es DE PROFORMA
					-- 'S' Si o 'N' No
DEFINE vm_flag_margen		CHAR(1)	-- FLAG PARA EL MARGEN
					-- 'S' por debajo de configuración						-- 'N' no debajo de  configuración
DEFINE vm_ind_arr		SMALLINT   -- INDICE DE MI ARREGLO (INPUT ARRAY)
DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_costo   	 	DECIMAL(12,2)	-- TOTAL COSTO 
DEFINE vm_subtotal   	 	DECIMAL(12,2)	-- TOTAL BRUTO 
DEFINE vm_descuento    		DECIMAL(12,2)	-- TOTAL DEL DESCUENTO
DEFINE vm_impuesto    		DECIMAL(12,2)	-- TOTAL DEL IMPUESTO
DEFINE vm_total    		DECIMAL(12,2)	-- TOTAL NETO
DEFINE vm_flag_vendedor		CHAR(1)		-- FLAG PARA CAMBIAR EL DESCTO.
						-- 'S' Si o 'N' No
DEFINE vg_numprev		LIKE rept023.r23_numprev

DEFINE vm_flag_dscto_defaults	CHAR(1)	-- Para saber que ejecuto los descuentos					-- DEFAULTS en el ingreso del detalle.

DEFINE vm_tot_peso 		DECIMAL(11,3)

DEFINE vm_flag_calculo_impto	CHAR(1)	-- Para saber como se calculará
					-- el impto. 'B' por TOTAL BRUTO ó
					-- 'I' por cada ITEM
DEFINE rm_bodssto		RECORD LIKE rept002.*
DEFINE vm_flag_bodega_sin_stock	CHAR(1)


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp209.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto','stop') 
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_numprev = arg_val(5)
LET vg_proceso = 'repp209'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL fl_lee_compania_repuestos(vg_codcia)  -- PARA OBTENER LA CONFIGURACION 
	RETURNING rm_r00.*		   -- DEL AREA DE REPUESTOS

LET vm_flag_calculo_impto = 'B'
CALL funcion_master()

END MAIN




FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
IF num_args() = 4 THEN
	CALL fl_control_status_caja(vg_codcia, vg_codloc, 'P')
		RETURNING int_flag
	IF int_flag <> 0 THEN
		RETURN
	END IF
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
	IF int_flag THEN
		RETURN
	END IF
END IF	
LET vm_max_rows     = 1000
LET vm_elementos    = 250
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
OPEN WINDOW w_repp209 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp209 FROM '../forms/repf209_1'
ELSE
	OPEN FORM f_repp209 FROM '../forms/repf209_1c'
END IF
DISPLAY FORM f_repp209

CALL control_display_botones()
IF vg_gui = 0 THEN
	LET vm_filas_pant = 4
END IF
--#LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_num_rows = 0
LET vm_row_current = 0
INITIALIZE rm_r23.* TO NULL
INITIALIZE rm_r24.* TO NULL
INITIALIZE rm_bodssto.* TO NULL
DECLARE q_bds CURSOR FOR
	SELECT * FROM rept002
		WHERE r02_compania = vg_codcia
		  AND r02_estado   = "A"
		  AND r02_tipo     = "S"
OPEN q_bds
FETCH q_bds INTO rm_bodssto.*
CLOSE q_bds
CALL muestra_contadores()

MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Proforma'
		HIDE OPTION 'Avanzar Detalle'
		HIDE OPTION 'Retroceder Detalle'
		--HIDE OPTION 'Modificar'
		HIDE OPTION 'Forma de Pago'
		--HIDE OPTION 'Hacer Proforma'
		IF num_args() = 5 THEN
			--HIDE OPTION 'Modificar'
			--HIDE OPTION 'Ingresar'
			SHOW OPTION 'Proforma'
			HIDE OPTION 'Consultar'
			HIDE OPTION 'Forma de Pago'
                	IF vm_num_rows = 1 AND (vm_ind_arr - vm_curr_arr) > 0
			   THEN
                       	 	SHOW OPTION 'Avanzar Detalle'
                	END IF
			CALL control_consulta()
			CALL control_ver_detalle() 
			EXIT PROGRAM
		END IF 
{--
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
                CALL control_ingreso()
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Hacer Proforma'
		END IF
                IF vm_num_rows = 1 AND (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
                END IF
                IF vm_row_current > 1 THEN
                        SHOW OPTION 'Retroceder'
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                END IF
                IF vm_row_current = vm_num_rows THEN
                        HIDE OPTION 'Avanzar'
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                END IF
		IF rm_r23.r23_estado = 'A' THEN
			HIDE OPTION 'Forma de Pago'
		ELSE
			SHOW OPTION 'Forma de Pago'
		END IF
	COMMAND KEY('M') 'Modificar' 		'Modificar un registro.'
		IF vm_num_rows > 0 THEN
			CALL control_modificacion()
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
--}		
	COMMAND KEY('F') 'Forma de Pago' 	'Forma de pago a Crédito.'
		IF vm_num_rows > 0 THEN
			CALL control_forma_pago()
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
{--
	COMMAND KEY('H') 'Hacer Proforma' 'Convertir la Pre-venta en Proforma.'
		IF vm_num_rows > 0 THEN
			CALL control_hacer_proforma()
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
		ELSE 
			CALL fl_mensaje_consultar_primero()
		END IF
--}		
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
		HIDE OPTION 'Forma de Pago'
		HIDE OPTION 'Proforma'
		--HIDE OPTION 'Hacer Proforma'
                CALL control_consulta()
                IF vm_num_rows <= 1 THEN
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                        --SHOW OPTION 'Modificar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Proforma'
			--SHOW OPTION 'Hacer Proforma'
                        HIDE OPTION 'Avanzar'
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Forma de Pago'
				HIDE OPTION 'Proforma'
				--HIDE OPTION 'Hacer Proforma'
                        	--HIDE OPTION 'Modificar'
                                HIDE OPTION 'Avanzar Detalle'
                                HIDE OPTION 'Retroceder Detalle'
                        END IF
                ELSE
                        --SHOW OPTION 'Modificar'
                        SHOW OPTION 'Avanzar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Proforma'
			--SHOW OPTION 'Hacer Proforma'
                        IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                                SHOW OPTION 'Avanzar Detalle'
                        END IF
                END IF
		IF rm_r23.r23_estado = 'A' THEN
			HIDE OPTION 'Forma de Pago'
		ELSE
			SHOW OPTION 'Forma de Pago'
		END IF
                IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('P') 'Proforma' 'Consulta la Pre-venta en Proforma.'
		CALL llamar_proforma()
        COMMAND KEY('V') 'Avanzar Detalle'      'Muestra siguientes detalles.'
                CALL control_mostrar_sig_det()
                IF (vm_ind_arr - vm_curr_arr) <= 0 THEN
                        HIDE OPTION 'Avanzar Detalle'
                END IF
                SHOW OPTION 'Retroceder Detalle'
        COMMAND KEY('T') 'Retroceder Detalle'   'Muestra anteriores detalles.'
                CALL control_mostrar_ant_det()
                SHOW OPTION 'Avanzar Detalle'
                IF vm_ini_arr <= 1 THEN
                        HIDE OPTION 'Retroceder Detalle'
                END IF
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Proforma'
			--SHOW OPTION 'Hacer Proforma'
			SHOW OPTION 'Retroceder'
			--SHOW OPTION 'Modificar'
			NEXT OPTION 'Retroceder'
		ELSE
			--SHOW OPTION 'Modificar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Proforma'
			--SHOW OPTION 'Hacer Proforma'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
		ELSE
                        HIDE OPTION 'Avanzar Detalle'
                END IF
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
                HIDE OPTION 'Avanzar Detalle'
                HIDE OPTION 'Retroceder Detalle'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			--SHOW OPTION 'Modificar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Proforma'
			--SHOW OPTION 'Hacer Proforma'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			--SHOW OPTION 'Modificar'
			SHOW OPTION 'Forma de Pago'
			SHOW OPTION 'Proforma'
			--SHOW OPTION 'Hacer Proforma'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
                IF (vm_ind_arr - vm_curr_arr) > 0 THEN
                        SHOW OPTION 'Avanzar Detalle'
		ELSE
                        HIDE OPTION 'Avanzar Detalle'
                END IF
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_display_botones()

IF vg_gui = 1 THEN
	--#DISPLAY 'P' 			TO tit_col1
	--#DISPLAY 'Cant' 		TO tit_col2
	--#DISPLAY 'Desp' 		TO tit_col3
	--#DISPLAY 'Bd' 		TO tit_col4
	--#DISPLAY 'Item' 		TO tit_col5
	--#DISPLAY 'Des %' 		TO tit_col6
	--#DISPLAY 'Precio Unit.' 	TO tit_col7
	--#DISPLAY 'Subtotal' 		TO tit_col8
END IF

END FUNCTION



FUNCTION control_mostrar_sig_det()
DEFINE i                SMALLINT
DEFINE filas_pant       SMALLINT
DEFINE filas_mostrar    SMALLINT
                                                                                
IF (vm_ind_arr - vm_curr_arr) <= 0 THEN
        RETURN
END IF
IF vg_gui = 0 THEN
	LET filas_pant = 4
END IF                                                                                
--#LET filas_pant = fgl_scr_size('r_detalle')
LET filas_mostrar = vm_ind_arr - vm_curr_arr
                                                                                
FOR i = 1 TO filas_pant
        CLEAR r_detalle[i].*
END FOR
                                                                                
IF filas_mostrar < filas_pant THEN
        LET filas_pant = filas_mostrar
END IF
                                                                                
LET vm_ini_arr = vm_curr_arr + 1
                                                                                
FOR i = 1 TO filas_pant
        LET vm_curr_arr = vm_curr_arr + 1
        DISPLAY r_detalle[vm_curr_arr].* TO r_detalle[i].*
END FOR
                                                                                
END FUNCTION
                                                                                


FUNCTION control_mostrar_ant_det()
DEFINE i                SMALLINT
DEFINE filas_pant       SMALLINT
                                                                                
IF vm_ini_arr <= 1 THEN
        RETURN
END IF
IF vg_gui = 0 THEN
	LET filas_pant = 4
END IF                                                                                
--#LET filas_pant = fgl_scr_size('r_detalle')
LET vm_ini_arr = vm_ini_arr - filas_pant
FOR i = 1 TO filas_pant
        CLEAR r_detalle[i].*
END FOR
                                                                                
LET vm_curr_arr = vm_ini_arr - 1
FOR i = 1 TO filas_pant
        LET vm_curr_arr = vm_curr_arr + 1
        DISPLAY r_detalle[vm_curr_arr].* TO r_detalle[i].*
END FOR
                                                                                
END FUNCTION



FUNCTION control_detalle()

CALL set_count(vm_ind_arr)
DISPLAY ARRAY r_detalle TO r_detalle.*
        ON KEY(INTERRUPT)
                EXIT DISPLAY
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas() 
        --#BEFORE DISPLAY
                --#CALL dialog.keysetlabel('ACCEPT', '')
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
        --#AFTER DISPLAY
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION control_hacer_proforma()
DEFINE i 		SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE resp 		CHAR(6)
DEFINE forma_pago 	CHAR(10)
DEFINE mensaje		VARCHAR(100)

--CALL fgl_winquestion(vg_producto,'¿ Está seguro de convertir en proforma esta preventa ?','No','Yes|No','question',1)
CALL fl_hacer_pregunta('¿ Está seguro de convertir en proforma esta preventa ?','No')
	RETURNING resp
IF resp = 'No' THEN
	RETURN
END IF
INITIALIZE rm_r21.* TO NULL
BEGIN WORK
WHENEVER ERROR CONTINUE
SELECT MAX(r21_numprof) + 1 INTO rm_r21.r21_numprof
        FROM  rept021
        WHERE r21_compania  = vg_codcia
        AND   r21_localidad = vg_codloc
                                                                                
IF rm_r21.r21_numprof IS NULL THEN
        LET rm_r21.r21_numprof = 1
END IF

LET rm_r21.r21_compania    = vg_codcia                                 
LET rm_r21.r21_localidad   = vg_codloc                                 
LET rm_r21.r21_grupo_linea = rm_r23.r23_grupo_linea                       
LET rm_r21.r21_codcli      = rm_r23.r23_codcli                                 
LET rm_r21.r21_nomcli      = rm_r23.r23_nomcli                                 
LET rm_r21.r21_dircli      = rm_r23.r23_dircli                                 
LET rm_r21.r21_telcli      = rm_r23.r23_telcli                                 
LET rm_r21.r21_cedruc      = rm_r23.r23_cedruc                                 
LET rm_r21.r21_vendedor    = rm_r23.r23_vendedor                           
LET rm_r21.r21_descuento   = rm_r23.r23_descuento                               
LET rm_r21.r21_bodega      = rm_r23.r23_bodega                         
LET rm_r21.r21_porc_impto  = rm_r23.r23_porc_impto                         
LET rm_r21.r21_moneda      = rm_r23.r23_moneda                         
LET rm_r21.r21_tot_costo   = rm_r23.r23_tot_costo                   
LET rm_r21.r21_tot_bruto   = rm_r23.r23_tot_bruto                   
LET rm_r21.r21_tot_dscto   = rm_r23.r23_tot_dscto                   
LET rm_r21.r21_tot_neto    = rm_r23.r23_tot_neto - rm_r23.r23_flete  
LET rm_r21.r21_usuario     = vg_usuario    
LET rm_r21.r21_fecing      = CURRENT    
LET rm_r21.r21_referencia  = 'REFERENCIA A PREVENTA # '|| rm_r23.r23_numprev    
LET rm_r21.r21_modelo      = '.'    

IF rm_r23.r23_cont_cred = 'C' THEN
	LET forma_pago = 'CONTADO'
ELSE
	LET forma_pago = 'CREDITO'
END IF

LET rm_r21.r21_forma_pago = forma_pago    

CALL fl_lee_moneda(rm_r21.r21_moneda) 	  
	RETURNING rm_g13.*	   	 
LET rm_r21.r21_precision = rm_g13.g13_decimales

CALL fl_lee_compania_repuestos(vg_codcia)  
        RETURNING rm_r00.*                
LET rm_r21.r21_dias_prof  = rm_r00.r00_dias_prof
                                                                                
INSERT INTO rept021 VALUES (rm_r21.*)

LET rm_r22.r22_compania    = vg_codcia                                 
LET rm_r22.r22_localidad   = vg_codloc                                 
LET rm_r22.r22_numprof     = rm_r21.r21_numprof                                 

FOR i = 1 TO vm_ind_arr
        LET rm_r22.r22_cantidad     = r_detalle[i].r24_cant_ven
        LET rm_r22.r22_item         = r_detalle[i].r24_item
        LET rm_r22.r22_porc_descto  = r_detalle[i].r24_descuento
        LET rm_r22.r22_precio       = r_detalle[i].r24_precio
        LET rm_r22.r22_orden        = i

	CALL fl_lee_item(vg_codcia,rm_r22.r22_item)
		RETURNING r_r10.*
        LET rm_r22.r22_descripcion  = r_r10.r10_nombre

        LET rm_r22.r22_linea        = r_detalle_1[i].r24_linea
        LET rm_r22.r22_rotacion     = r_r10.r10_rotacion

	IF rm_r21.r21_moneda = rg_gen.g00_moneda_base THEN
		LET rm_r22.r22_costo = r_r10.r10_costo_mb
	ELSE
		LET rm_r22.r22_costo = r_r10.r10_costo_ma
	END IF 

        LET rm_r22.r22_val_descto   = r_detalle_1[i].r24_val_descto
        LET rm_r22.r22_val_impto    = r_detalle_1[i].r24_val_impto

        INSERT INTO rept022 VALUES(rm_r22.*)
END FOR
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No se realizo proceso.','exclamation')
	CALL fl_mostrar_mensaje('No se realizó proceso.','exclamation')
	RETURN
END IF

COMMIT WORK
--CALL fgl_winmessage(vg_producto,'Se genero la proforma número  '||rm_r21.r21_numprof,'info')
LET mensaje = 'Se generó la proforma número ' || rm_r21.r21_numprof
CALL fl_mostrar_mensaje(mensaje,'info')

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

CLEAR FORM

CALL control_display_botones()

LET vm_flag_mant = 'I'
LET vm_flag_anticipos = 'N'
INITIALIZE rm_r01.*, rm_r02.*, rm_r03.*, rm_r04.*, rm_r10.* TO NULL
INITIALIZE rm_r11.*, rm_g13.*, rm_g14.*, rm_g20.*, rm_c01.* TO NULL
INITIALIZE rm_c02.*, rm_c03.*, rm_r23.*, rm_r24.* TO NULL

IF rm_r00.r00_compania IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'No existe configuración para la Compañía en el área de Repuestos. ','exclamation')
	CALL fl_mostrar_mensaje('No existe configuración para la Compañía en el área de Inventario.','exclamation')
	RETURN
END IF
IF rm_r00.r00_estado <> 'A' THEN
	--CALL fgl_winmessage(vg_producto,'La Compañía está con status BLOQUEADO en el área de Repuestos. ','exclamation')
	CALL fl_mostrar_mensaje('La Compañía está con status BLOQUEADO en el área de Inventario.','exclamation')
	RETURN
END IF

-- INITIAL VALUES FOR rm_r23 FIELDS
LET rm_r23.r23_estado     = 'P'
LET rm_r23.r23_flete      = 0
LET vm_fecha              = CURRENT
LET rm_r23.r23_usuario    = vg_usuario
LET rm_r23.r23_compania   = vg_codcia
LET rm_r23.r23_localidad  = vg_codloc
LET rm_r23.r23_moneda     = rg_gen.g00_moneda_base
LET rm_r23.r23_bodega     = rm_r00.r00_bodega_fact
LET vm_credito_auto       = rm_r00.r00_fact_sin_stock
LET rm_r23.r23_cont_cred  = 'C'
LET rm_r23.r23_porc_impto = rg_gen.g00_porc_impto
LET rm_r23.r23_paridad    =  1.0
LET rm_r23.r23_precision  =  1.0
LET rm_r23.r23_descuento  =  0.0
LET vm_flag_vendedor      = 'N'    -- NO CAMBIA DESCUENTO

CALL fl_lee_moneda(rg_gen.g00_moneda_base) 	     -- PARA OBTENER EL NOMBRE 
	RETURNING rm_g13.*		   	     -- DE LA MONEDA BASE
LET rm_r23.r23_precision = rm_g13.g13_decimales
CALL fl_lee_bodega_rep(vg_codcia, rm_r23.r23_bodega) -- PARA OBTENER EL NOMBRE
	RETURNING rm_r02.*			     -- DE LA BODEGA

DISPLAY BY NAME vm_fecha, rm_r23.r23_cont_cred,  rm_r23.r23_moneda, 
		rm_r23.r23_bodega, rm_r23.r23_porc_impto, rm_r23.r23_descuento,
		rm_r23.r23_flete,  rm_r23.r23_descuento
IF vg_gui = 0 THEN
	CALL muestra_contcred(rm_r23.r23_cont_cred)
END IF

DISPLAY 'A' TO r23_estado
DISPLAY 'ACTIVO' TO tit_estado
DISPLAY rm_g13.g13_nombre TO nom_moneda
DISPLAY rm_r02.r02_nombre TO nom_bodega
CALL lee_datos()
IF INT_FLAG THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF

LET vm_total = 0
LET rm_r23.r23_tot_neto = 0
LET INT_FLAG = 0
LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_display_botones()
	ELSE	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
	-- ACTUALIZO LOS VALORES DEFAULTS QUE INGRESE AL INICIO DE LEE DATOS --
LET rm_r23.r23_fecing = CURRENT
LET rm_r23.r23_tot_neto = vm_total
BEGIN WORK

	{
	IF vm_credito_auto = 'N' AND rm_r23.r23_cont_cred = 'R' THEN
		LET rm_r23.r23_estado = 'A'
	END IF
	}

	CALL control_insert_rept023()

	CALL control_insert_rept024()

	CALL control_credito()	

	IF vm_flag_anticipos = 'S' THEN
		CALL control_actualizacion_anticipos()
	END IF

	LET done = control_actualizacion_caja()
	IF done = 0 THEN
		ROLLBACK WORK
	        CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
	END IF

COMMIT WORK

CALL muestra_contadores()

CALL lee_muestra_registro(vm_rows[vm_row_current])

CALL fl_mensaje_registro_ingresado()

CALL control_mensajes_despues_grabar()

END FUNCTION



FUNCTION control_modificacion()
DEFINE cliente 			LIKE rept023.r23_codcli
DEFINE done			SMALLINT
DEFINE r23_tot_neto_aux		LIKE rept023.r23_tot_neto
DEFINE flete_aux		LIKE rept023.r23_flete
DEFINE resp 			CHAR(3)

LET vm_flag_mant = 'M'
LET vm_flag_anticipos = 'N'

IF rm_r23.r23_estado = 'F' THEN
	CALL fl_mostrar_mensaje('La preventa ha sido facturada. No puede ser modificada.','exclamation')
	RETURN

END IF

IF rm_r23.r23_estado <> 'A'  AND rm_r23.r23_estado <> 'P' THEN
	--CALL fgl_winmessage(vg_producto,'Registro no puede ser Modificado. ','exclamation')
	CALL fl_mostrar_mensaje('Registro no puede ser Modificado.','exclamation')
	RETURN
END IF

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up2 CURSOR FOR 
	SELECT * FROM rept023 
		WHERE r23_compania  = vg_codcia
		AND   r23_localidad = vg_codloc
		AND   r23_numprev   = rm_r23.r23_numprev
	FOR UPDATE
OPEN q_up2
FETCH q_up2 
IF status < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

IF rm_r23.r23_codcli IS NOT NULL  AND rm_r23.r23_cont_cred = 'R' THEN
	LET vm_credito_auto = rm_r00.r00_fact_sin_stock
	CALL control_cliente()
		RETURNING cliente
END IF 

-- OjO voy a permitir que modifique la preventa aunque sea de proforma
LET vm_flag_proforma = 'N'
IF vm_flag_proforma = 'S' THEN
	--CALL fgl_winquestion(vg_producto,'La preventa es proformada solo podrá realizar cambios al código del cliente,al tipo de pago o flete de mercadería. ¿ Desea continuar ?','No','Yes|No','question',1)
	CALL fl_hacer_pregunta('La preventa es proformada solo podrá realizar cambios al código del cliente,al tipo de pago o flete de mercadería. ¿ Desea continuar ?','No')
		RETURNING resp
	IF resp = 'No' THEN
		RETURN
	END IF
	LET flete_aux = rm_r23.r23_flete
	CALL control_preventa_proformada()
	IF NOT int_flag THEN

		CALL control_anticipos_cliente()
		IF vm_flag_anticipos = 'S' THEN
			CALL control_actualizacion_anticipos()
		ELSE
			LET rm_r23.r23_tot_neto = rm_r23.r23_tot_neto + 
						  rm_r23.r23_flete - flete_aux
		END IF
		LET done = control_actualizacion_caja()
		IF done = 0 THEN
			ROLLBACK WORK
	        	CALL lee_muestra_registro(vm_rows[vm_row_current])
			RETURN
		END IF
		UPDATE rept023 	
			SET * = rm_r23.*
			WHERE CURRENT OF q_up2

	ELSE
		ROLLBACK WORK
		RETURN
	END IF
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF

LET r23_tot_neto_aux = rm_r23.r23_tot_neto
CALL lee_datos()

IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
LET vm_num_detalles = ingresa_detalles() 
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
ELSE

IF rm_r23.r23_cont_cred = 'R' AND rm_r23.r23_tot_neto > cupo_credito AND  
   vm_credito_auto     <> 'N'
   THEN
	LET rm_r23.r23_estado = 'A'
END IF

	UPDATE rept023 	
		SET * = rm_r23.*
		WHERE CURRENT OF q_up2

	CALL control_actualizacion_preventa(r23_tot_neto_aux)

	CALL control_insert_rept024()

	CALL control_credito()	

	IF vm_flag_anticipos = 'S' THEN
		CALL control_actualizacion_anticipos()
	END IF

	LET done = control_actualizacion_caja()
	IF done = 0 THEN
		ROLLBACK WORK
	        CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN
	END IF

	COMMIT WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CALL fl_mensaje_registro_modificado()
	CALL control_mensajes_despues_grabar()
END IF

END FUNCTION



FUNCTION control_actualizacion_preventa(r23_tot_neto_aux)
DEFINE r23_tot_neto_aux	LIKE rept023.r23_tot_neto

--- ELIMINA LOS DATOS DE UNA MODIFICACION A UNA PREVT. A CREDITO ---
	DELETE FROM rept026
		WHERE r26_compania  = vg_codcia
		AND   r26_localidad = vg_codloc	
		AND   r26_numprev   = rm_r23.r23_numprev	
	DELETE FROM rept025
		WHERE r25_compania  = vg_codcia
		AND   r25_localidad = vg_codloc	
		AND   r25_numprev   = rm_r23.r23_numprev	
	DELETE FROM rept027
		WHERE r27_compania  = vg_codcia
		AND   r27_localidad = vg_codloc	
		AND   r27_numprev   = rm_r23.r23_numprev	
--------------------------------------------------------------------
DELETE FROM rept024 	
	WHERE r24_compania  = vg_codcia
	AND   r24_localidad = vg_codloc
	AND   r24_numprev   = rm_r23.r23_numprev

END FUNCTION



FUNCTION control_preventa_proformada()
DEFINE resp 	CHAR(6)
DEFINE cliente 	LIKE rept023.r23_codcli

INPUT BY NAME rm_r23.r23_codcli, rm_r23.r23_cont_cred, rm_r23.r23_flete
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r23_codcli, r23_cont_cred, r23_flete)
		THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(r23_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r23.r23_codcli = rm_c02.z02_codcli
				LET rm_r23.r23_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r23.r23_codcli,
						rm_r23.r23_nomcli
			END IF 
		END IF
	ON KEY(F7)
		CALL control_otros_datos()
		DISPLAY BY NAME rm_r23.r23_cont_cred  
		IF vg_gui = 0 THEN
			CALL muestra_contcred(rm_r23.r23_cont_cred)
		END IF
		LET INT_FLAG = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r23_codcli
		IF rm_r23.r23_codcli IS NOT NULL OR
		   rm_r23.r23_codcli <> ''
		   THEN
			CALL control_cliente()
				RETURNING cliente
			IF cliente IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe el Cliente en la Compañía. ','exclamation') 
				CALL fl_mostrar_mensaje('No existe el Cliente en la Compañía.','exclamation')
				CLEAR r23_nomcli, r23_cedruc, r23_dircli
				LET rm_r23.r23_descuento = 0
				DISPLAY BY NAME rm_r23.r23_descuento
				INITIALIZE rm_r23.r23_telcli TO NULL 
				NEXT FIELD r23_codcli
			END IF
			IF rm_c01.z01_estado <>'A' THEN
				--CALL fgl_winmessage(vg_producto,'Cliente está bloqueado','exclamation')
				CALL fl_mostrar_mensaje('Cliente está bloqueado','exclamation')
				NEXT FIELD r23_codcli
			END IF
		END IF
		IF rm_r23.r23_cont_cred = 'R' AND 
		   rm_r23.r23_codcli IS NULL 
		   THEN
			--CALL fgl_winquestion(vg_producto,'Solo puede otorgarle crédito a los clientes de la Compañía. ¿ Desea crear el cliente ?','No','Yes|No','question',1)
			CALL fl_hacer_pregunta('Solo puede otorgarle crédito a los clientes de la Compañía. ¿ Desea crear el cliente ?','No')
				RETURNING resp
			IF resp = 'No' THEN
				NEXT FIELD r23_cont_cred
			ELSE 
				CALL control_crear_cliente()
				NEXT FIELD r23_codcli
			END IF
		END IF
		DISPLAY BY NAME rm_r23.r23_nomcli, rm_r23.r23_dircli,    
				rm_r23.r23_cedruc
	AFTER FIELD r23_cont_cred
		IF vg_gui = 0 THEN
			CALL muestra_contcred(rm_r23.r23_cont_cred)
		END IF
		IF rm_r23.r23_cont_cred = 'R' AND 
		   rm_r23.r23_codcli IS NULL 
		   THEN
			--CALL fgl_winquestion(vg_producto,'Solo puede otorgarle crédito a los clientes de la Compañía. Desea crear el cliente ?','No','Yes|No','question',1)
			CALL fl_hacer_pregunta('Solo puede otorgarle crédito a los clientes de la Compañía. Desea crear el cliente ?','No')
				RETURNING resp
			IF resp = 'No' THEN
				NEXT FIELD r23_cont_cred
			ELSE 
				CALL control_crear_cliente()
				NEXT FIELD r23_codcli
			END IF
			IF vg_gui = 0 THEN
				CALL muestra_contcred(rm_r23.r23_cont_cred)
			END IF
		END IF
END INPUT


END FUNCTION



FUNCTION control_actualizacion_caja()
DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_upd		RECORD LIKE cajt010.*

IF rm_r23.r23_estado <> 'P' THEN
	RETURN 1
END IF

LET intentar = 1
LET done = 0
WHILE (intentar)
	INITIALIZE r_j10.* TO NULL
	WHENEVER ERROR CONTINUE
		DECLARE q_j10 CURSOR FOR
			SELECT * FROM cajt010
				WHERE j10_compania    = vg_codcia      
				  AND j10_localidad   = vg_codloc       
				  AND j10_tipo_fuente = 'PR'
				  AND j10_num_fuente  =	rm_r23.r23_numprev
			FOR UPDATE
	OPEN  q_j10
	FETCH q_j10 INTO r_j10.*
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
		CLOSE q_j10
		FREE  q_j10
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF

IF STATUS <> NOTFOUND THEN
	DELETE FROM cajt010 WHERE CURRENT OF q_j10 
END IF
CLOSE q_j10
FREE  q_j10

LET r_j10.j10_areaneg   = rm_g20.g20_areaneg
LET r_j10.j10_codcli    = rm_r23.r23_codcli
LET r_j10.j10_nomcli    = rm_r23.r23_nomcli
LET r_j10.j10_moneda    = rm_r23.r23_moneda

IF rm_r23.r23_cont_cred = 'R' THEN
	LET r_j10.j10_valor = 0
ELSE
	IF vm_flag_anticipos = 'S' THEN
		LET r_j10.j10_valor = rm_r23.r23_tot_neto -
				      total_anticipos
	ELSE
		LET r_j10.j10_valor = rm_r23.r23_tot_neto 
	END IF
	
END IF

LET r_j10.j10_fecha_pro   = CURRENT
LET r_j10.j10_usuario     = vg_usuario 
LET r_j10.j10_fecing      = CURRENT
LET r_j10.j10_compania    = vg_codcia
LET r_j10.j10_localidad   = vg_codloc
LET r_j10.j10_tipo_fuente = 'PR'
LET r_j10.j10_num_fuente  = rm_r23.r23_numprev
LET r_j10.j10_estado      = 'A'

INITIALIZE r_j10.j10_codigo_caja,  r_j10.j10_tipo_destino, 
 	   r_j10.j10_num_destino,  r_j10.j10_referencia,     
 	   r_j10.j10_banco,        r_j10.j10_numero_cta,   
	   r_j10.j10_tip_contable, r_j10.j10_num_contable
           TO NULL    
                                                                
INSERT INTO cajt010 VALUES(r_j10.*)

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()
DEFINE intentar         SMALLINT
DEFINE resp             CHAR(6)
                                                                                
LET intentar = 1
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente', 'No', 'Yes|No', 'question', 1)
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente', 'No')
	RETURNING resp
IF resp = 'No' THEN
	LET intentar = 0
END IF
                                                                                
RETURN intentar
                                                                                
END FUNCTION



FUNCTION control_insert_rept023()
DEFINE i 		SMALLINT
DEFINE resp		CHAR(6)

SELECT MAX(r23_numprev) + 1 INTO rm_r23.r23_numprev
	FROM  rept023
	WHERE r23_compania  = vg_codcia
	AND   r23_localidad = vg_codloc

IF rm_r23.r23_numprev IS NULL THEN
	LET rm_r23.r23_numprev = 1
END IF
---
IF vm_flag_bodega_sin_stock = 'S' THEN
	LET rm_r23.r23_estado = 'A'
END IF
---
INSERT INTO rept023 VALUES (rm_r23.*)
DISPLAY BY NAME rm_r23.r23_numprev

IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
        LET vm_num_rows = vm_num_rows + 1
END IF

LET vm_row_current = vm_num_rows
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila 
                                             	-- procesada

END FUNCTION



FUNCTION control_insert_rept024()
DEFINE i,done 	SMALLINT

-- INITIAL VALUES FOR rm_r24 FIELDS
LET rm_r24.r24_numprev    = rm_r23.r23_numprev
LET rm_r24.r24_compania   = rm_r23.r23_compania
LET rm_r24.r24_localidad  = rm_r23.r23_localidad
LET rm_r24.r24_proformado = 'N'
FOR i = 1 TO vm_num_detalles
	LET rm_r24.r24_cant_ped   = r_detalle[i].r24_cant_ped
	LET rm_r24.r24_cant_ven   = r_detalle[i].r24_cant_ven
	LET rm_r24.r24_bodega     = r_detalle[i].r24_bodega
	LET rm_r24.r24_item       = r_detalle[i].r24_item
	LET rm_r24.r24_linea      = r_detalle_1[i].r24_linea
	LET rm_r24.r24_descuento  = r_detalle[i].r24_descuento
	LET rm_r24.r24_orden      = i
	LET rm_r24.r24_precio     = r_detalle[i].r24_precio
	LET rm_r24.r24_val_descto = r_detalle_1[i].r24_val_descto
	LET rm_r24.r24_val_impto  = r_detalle_1[i].r24_val_impto 
	INSERT INTO rept024 VALUES(rm_r24.*)
END FOR 

END FUNCTION



FUNCTION control_insert_caja()

END FUNCTION



FUNCTION control_forma_pago()
DEFINE param		VARCHAR(60)

IF rm_r23.r23_cont_cred = 'C' THEN
	--CALL fgl_winmessage(vg_producto,'Forma de Pago para Pre-ventas a crédito.','exclamation')
	CALL fl_mostrar_mensaje('Forma de Pago para Pre-ventas a crédito.','exclamation')
	RETURN
END IF
IF rm_r23.r23_estado = 'F' THEN
	--CALL fgl_winmessage(vg_producto,'La preventa ya está facturada.','exclamation')
	CALL fl_mostrar_mensaje('La preventa ya está facturada.','exclamation')
	RETURN
END IF
LET param = ' ', vg_codloc, ' ', rm_r23.r23_numprev
CALL ejecuta_comando('REPUESTOS', vg_modulo, 'repp210 ', param)

END FUNCTION



FUNCTION lee_datos()
DEFINE resp 		CHAR(6)
DEFINE cliente		LIKE rept023.r23_codcli
DEFINE done		SMALLINT
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE saldo_venc	LIKE cxct030.z30_saldo_venc
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE mensaje		VARCHAR(100)

LET int_flag = 0
INPUT BY NAME rm_r23.r23_moneda,    rm_r23.r23_bodega,   rm_r23.r23_grupo_linea,
	      rm_r23.r23_codcli,    rm_r23.r23_nomcli,   rm_r23.r23_cedruc,
	      rm_r23.r23_dircli,    rm_r23.r23_vendedor, rm_r23.r23_descuento, 
	      rm_r23.r23_cont_cred,  rm_r23.r23_flete
	      WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(r23_grupo_linea, r23_codcli, r23_nomcli, 
				     r23_cedruc,  r23_vendedor,   r23_dircli)
		THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
                	RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(r23_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_r23.r23_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_r23.r23_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF
		IF INFIELD(r23_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F')
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r23.r23_vendedor = rm_r01.r01_codigo	
				DISPLAY BY NAME rm_r23.r23_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r23_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r23.r23_codcli = rm_c02.z02_codcli
				LET rm_r23.r23_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r23.r23_codcli,
						rm_r23.r23_nomcli
			END IF 
		END IF
		IF INFIELD(r23_bodega) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', '2', 'R', 'S', 'V')
		     RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     IF rm_r02.r02_codigo IS NOT NULL THEN
			    LET rm_r23.r23_bodega = rm_r02.r02_codigo
			    DISPLAY BY NAME rm_r23.r23_bodega
			    DISPLAY rm_r02.r02_nombre TO nom_bodega
		     END IF
		END IF
		IF INFIELD(r23_grupo_linea) THEN
		      CALL fl_ayuda_grupo_lineas(vg_codcia)
			   RETURNING rm_g20.g20_grupo_linea, rm_g20.g20_nombre
			IF rm_g20.g20_grupo_linea IS NOT NULL THEN
				LET rm_r23.r23_grupo_linea = 
				    rm_g20.g20_grupo_linea
				DISPLAY BY NAME rm_r23.r23_grupo_linea
			    	DISPLAY  rm_g20.g20_nombre TO nom_grupo
			END IF
		END IF
		LET int_flag = 0

	ON KEY(F5)	
		CALL control_crear_cliente()
		LET INT_FLAG = 0

	ON KEY(F7)
		CALL control_otros_datos()
		DISPLAY BY NAME rm_r23.r23_cont_cred  
		IF vg_gui = 0 THEN
			CALL muestra_contcred(rm_r23.r23_cont_cred)
		END IF
		LET INT_FLAG = 0

	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")

	BEFORE FIELD r23_descuento
		IF vm_flag_vendedor <> 'S' THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r23_nomcli
		IF rm_r23.r23_codcli IS NOT NULL THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r23_cedruc
		IF rm_r23.r23_codcli IS NOT NULL THEN
			NEXT FIELD NEXT
		END IF
	BEFORE FIELD r23_dircli
		IF rm_r23.r23_codcli IS NOT NULL THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD r23_moneda
		IF rm_r23.r23_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_r23.r23_moneda)
				RETURNING rm_g13.*
                	IF rm_g13.g13_moneda IS  NULL THEN
		    		--CALL fgl_winmessage (vg_producto, 'La moneda no existe en la Compañía. ','exclamation')
				CALL fl_mostrar_mensaje('La moneda no existe en la Compañía. ','exclamation')
				CLEAR nom_moneda
                        	NEXT FIELD r23_moneda
			END IF
			IF  rm_r23.r23_moneda <> rg_gen.g00_moneda_base AND
			    rm_r23.r23_moneda <> rg_gen.g00_moneda_alt
			    THEN
				--CALL fgl_winmessage(vg_producto,'La Moneda ingresada no es la moneda base ni la moneda alterna.','exclamation')
				CALL fl_mostrar_mensaje('La Moneda ingresada no es la moneda base ni la moneda alterna.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD r23_moneda
			END IF
			IF rm_r23.r23_moneda = rg_gen.g00_moneda_alt THEN
				CALL fl_lee_factor_moneda(rm_r23.r23_moneda,
							rg_gen.g00_moneda_base)
					RETURNING rm_g14.*
				IF rm_g14.g14_tasa IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'No existe conversión entre la moneda base y la moneda alterna. Debe revisar la configuración. ','stop')
				CALL fl_mostrar_mensaje('No existe conversión entre la moneda base y la moneda alterna. Debe revisar la configuración. ','stop')
					EXIT PROGRAM
				END IF 
				LET rm_r23.r23_precision = rm_g13.g13_decimales
				LET rm_r23.r23_paridad   = rm_g14.g14_tasa
			END IF 
			DISPLAY rm_g13.g13_nombre TO nom_moneda
		ELSE
			CLEAR nom_moneda
                END IF
	AFTER FIELD r23_vendedor
		IF rm_r23.r23_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r23.r23_vendedor)
				RETURNING rm_r01.*
			IF rm_r01.r01_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Vendedor no existe','exclamation')
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation')
				CLEAR nom_vendedor
				NEXT FIELD r23_vendedor
			END IF 
			IF rm_r01.r01_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Vendedor está bloqueado.','exclamation')
				CALL fl_mostrar_mensaje('Vendedor está bloqueado.','exclamation')
					NEXT FIELD r23_vendedor
			END IF
		   	LET vm_flag_vendedor = rm_r01.r01_mod_descto 
			DISPLAY rm_r01.r01_nombres TO nom_vendedor
		ELSE
			CLEAR nom_vendedor
		END IF		 
	AFTER FIELD r23_bodega
		IF rm_r23.r23_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r23.r23_bodega)
				RETURNING rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				CLEAR nom_bodega
				NEXT FIELD r23_bodega
			END IF 
			IF rm_r02.r02_estado = 'B' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega está bloqueada.','exclamation')
				CALL fl_mostrar_mensaje('Bodega está bloqueada.','exclamation')
					NEXT FIELD r23_bodega
			END IF
			IF rm_r02.r02_factura <> 'S' THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no factura.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no factura.','exclamation')
					NEXT FIELD r23_bodega
			END IF
			DISPLAY rm_r02.r02_nombre TO nom_bodega
		ELSE
			CLEAR nom_bodega
		END IF
	AFTER FIELD r23_grupo_linea
		IF rm_r23.r23_grupo_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(vg_codcia, 
					        rm_r23.r23_grupo_linea)
				RETURNING rm_g20.*
			IF rm_g20.g20_grupo_linea IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Grupo de Línea de Venta no existe.','exclamation')
				CALL fl_mostrar_mensaje('Grupo de Línea de Venta no existe.','exclamation')
				CLEAR nom_grupo
				NEXT FIELD r23_grupo_linea
			END IF
			CALL fl_lee_area_negocio(vg_codcia, rm_g20.g20_areaneg)
				RETURNING rm_g03.*
			IF rm_g03.g03_modulo <> vg_modulo THEN
				--CALL fgl_winmessage(vg_producto,'El área de negocio del grupo de línea no pertenece a Repuestos.','exclamation')
				CALL fl_mostrar_mensaje('El área de negocio del grupo de línea no pertenece a Inventario.','exclamation')
				NEXT FIELD r23_grupo_linea
			END IF
			DISPLAY rm_g20.g20_nombre TO nom_grupo
		ELSE
			CLEAR nom_grupo
			NEXT FIELD r23_grupo_linea
		END IF
	AFTER FIELD r23_codcli
		IF rm_r23.r23_codcli IS NOT NULL OR
		   rm_r23.r23_codcli <> ''
		   THEN
			CALL control_cliente()
				RETURNING cliente
			IF cliente IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe el Cliente en la Compañía. ','exclamation') 
				CALL fl_mostrar_mensaje('No existe el Cliente en la Compañía. ','exclamation') 
				CLEAR r23_nomcli, r23_cedruc, r23_dircli
				LET rm_r23.r23_descuento = 0
				DISPLAY BY NAME rm_r23.r23_descuento
				INITIALIZE rm_r23.r23_telcli TO NULL 
				NEXT FIELD r23_codcli
			END IF
			IF rm_c01.z01_estado <>'A' THEN
				--CALL fgl_winmessage(vg_producto,'Cliente está bloqueado','exclamation')
				CALL fl_mostrar_mensaje('Cliente está bloqueado','exclamation')
				NEXT FIELD r23_codcli
			END IF
		END IF
		IF rm_r23.r23_cont_cred = 'R' AND 
		   rm_r23.r23_codcli IS NULL 
		   THEN
			--CALL fgl_winquestion(vg_producto,'Solo puede otorgarle crédito a los clientes de la Compañía. ¿ Desea crear el cliente ?','No','Yes|No','question',1)
			CALL fl_hacer_pregunta('Solo puede otorgarle crédito a los clientes de la Compañía. ¿ Desea crear el cliente ?','No')
				RETURNING resp
			IF resp = 'No' THEN
				NEXT FIELD r23_cont_cred
			ELSE 
				CALL control_crear_cliente()
				NEXT FIELD r23_codcli
			END IF
		END IF
	AFTER FIELD r23_cont_cred
		IF rm_r23.r23_descuento > 0 AND
		   rm_r23.r23_codcli IS NOT NULL AND
		   rm_r23.r23_descuento = vm_descuento_cont OR
		   rm_r23.r23_descuento = vm_descuento_cred		   
		   THEN
			CASE rm_r23.r23_cont_cred
				WHEN 'C'
					LET rm_r23.r23_descuento = 
					    vm_descuento_cont 
				WHEN 'R'
					LET rm_r23.r23_descuento = 
					    vm_descuento_cred 
			END CASE
		END IF
		IF vg_gui = 0 THEN
			CALL muestra_contcred(rm_r23.r23_cont_cred)
		END IF
		IF rm_r23.r23_cont_cred = 'R' AND 
		   rm_r23.r23_codcli IS NULL 
		   THEN
			--CALL fgl_winquestion(vg_producto,'Solo puede otorgarle crédito a los clientes de la Compañía. Desea crear el cliente ?','No','Yes|No','question',1)
			CALL fl_hacer_pregunta('Solo puede otorgarle crédito a los clientes de la Compañía. Desea crear el cliente ?','No')
				RETURNING resp
			IF resp = 'No' THEN
				NEXT FIELD r23_cont_cred
			ELSE 
				CALL control_crear_cliente()
				NEXT FIELD r23_codcli
			END IF
		END IF
		DISPLAY BY NAME rm_r23.r23_descuento
	AFTER INPUT 
		IF rm_r23.r23_cont_cred = 'C' AND rm_r23.r23_codcli IS NOT NULL
		   THEN
			CALL fl_retorna_saldo_vencido(vg_codcia, 
						      rm_r23.r23_codcli)
				RETURNING r_g13.g13_moneda, saldo_venc
			IF saldo_venc > 0 THEN
				CALL fl_lee_moneda(r_g13.g13_moneda)
					RETURNING r_g13.*
				LET mensaje =
					'El cliente tiene un saldo vencido ' ||
					'de  ' || saldo_venc || 
					'  en la moneda ' ||
					 r_g13.g13_nombre || '.'
				--CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			END IF
		END IF
			
		IF rm_r23.r23_cont_cred = 'R' THEN
			CALL fl_retorna_saldo_vencido(vg_codcia, 
						      rm_r23.r23_codcli)
				RETURNING r_g13.g13_moneda, saldo_venc

			IF saldo_venc > 0 THEN
				CALL fl_lee_moneda(r_g13.g13_moneda)
					RETURNING r_g13.*
				LET mensaje = 
					'El cliente tiene un saldo vencido ' ||
					'de  ' || saldo_venc || 
					'  en la moneda ' ||r_g13.g13_nombre ||
					'.'
				--CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				CALL fl_lee_compania_cobranzas(vg_codcia)
					RETURNING r_z00.* 
				IF r_z00.z00_compania IS NULL THEN
					--CALL fgl_winmessage(vg_producto,'No existe un registro de configuración para la compañía en cobranzas.','stop')
					CALL fl_mostrar_mensaje('No existe un registro de configuración para la compañía en cobranzas.','stop')
					EXIT PROGRAM
				END IF
				IF r_z00.z00_bloq_vencido = 'S' THEN
					--CALL fgl_winmessage(vg_producto,'La Compañìa tiene configurado bloquer preventas de crèdito a clientes con saldos vencidos. El cliente deberà cancelar sus deudas para otorgarle un nuevo crèdito.','exclamation')
					CALL fl_mostrar_mensaje('La Compañìa tiene configurado bloquer preventas de crèdito a clientes con saldos vencidos. El cliente deberà cancelar sus deudas para otorgarle un nuevo crèdito.','exclamation')
					CONTINUE INPUT
				END IF
			END IF
		END IF	
			
END INPUT

END FUNCTION



FUNCTION control_crear_cliente()
DEFINE param		VARCHAR(60)

LET param = ' ', vg_codloc
CALL ejecuta_comando('COBRANZAS', 'CO', 'cxcp101 ', param)

END FUNCTION



FUNCTION control_cliente()
DEFINE cliente	LIKE rept023.r23_codcli
 
LET vm_descuento_cont  = 0
LET vm_descuento_cred  = 0
LET vm_cupo_credito_mb = 0
LET vm_cupo_credito_ma = 0
INITIALIZE cliente TO NULL
CALL fl_lee_cliente_areaneg(vg_codcia, vg_codloc, rm_g20.g20_areaneg,
			    rm_r23.r23_codcli)
	RETURNING rm_c03.*
IF rm_c03.z03_codcli IS NULL THEN
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, rm_r23.r23_codcli)
		RETURNING rm_c02.*
	IF rm_c02.z02_codcli IS NULL THEN
		RETURN cliente
	END IF
	LET vm_descuento_cont = rm_c02.z02_dcto_item_c
	LET vm_descuento_cred = rm_c02.z02_dcto_item_r
	IF vm_credito_auto <> 'N' THEN
		LET vm_credito_auto = rm_c02.z02_credit_auto
	END IF
	LET vm_plazo         = rm_c02.z02_credit_dias
	LET vm_cupo_credito_mb = rm_c02.z02_cupcred_aprob
	LET vm_cupo_credito_ma = rm_c02.z02_cupcred_xaprob
ELSE
	LET vm_descuento_cont = rm_c03.z03_dcto_item_c
	LET vm_descuento_cred = rm_c03.z03_dcto_item_r
	IF vm_credito_auto <> 'N' THEN
		LET vm_credito_auto = rm_c03.z03_credit_auto
	END IF
	LET vm_plazo           = rm_c03.z03_credit_dias
	LET vm_cupo_credito_mb = rm_c03.z03_cupocred_mb
	LET vm_cupo_credito_ma = rm_c03.z03_cupocred_ma
END IF
CALL fl_lee_cliente_general(rm_r23.r23_codcli)
	RETURNING rm_c01.*
IF rm_r23.r23_cont_cred = 'C' THEN
	LET rm_r23.r23_descuento = vm_descuento_cont 
ELSE
	LET rm_r23.r23_descuento = vm_descuento_cred 
END IF
CALL calcula_cupo_credito()
LET cliente		 = rm_c01.z01_codcli
LET rm_r23.r23_nomcli    = rm_c01.z01_nomcli
LET rm_r23.r23_dircli    = rm_c01.z01_direccion1
LET rm_r23.r23_cedruc    = rm_c01.z01_num_doc_id
LET rm_r23.r23_telcli    = rm_c01.z01_telefono1
DISPLAY BY NAME rm_r23.r23_descuento, rm_r23.r23_nomcli, rm_r23.r23_dircli,
		rm_r23.r23_cedruc
RETURN cliente

END FUNCTION



FUNCTION control_otros_datos()

DEFINE ped_cliente		LIKE rept023.r23_ped_cliente
DEFINE telcli			LIKE rept023.r23_telcli
DEFINE ord_compra 		LIKE rept023.r23_ord_compra
DEFINE referencia		LIKE rept023.r23_referencia

LET ped_cliente = rm_r23.r23_ped_cliente
LET telcli	= rm_r23.r23_telcli
LET ord_compra 	= rm_r23.r23_ord_compra
LET referencia	= rm_r23.r23_referencia

OPEN WINDOW w_repp209_2 AT 11, 17 WITH 12 ROWS, 62 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp209_2 FROM '../forms/repf209_2'
ELSE
	OPEN FORM f_repp209_2 FROM '../forms/repf209_2c'
END IF		  
DISPLAY FORM f_repp209_2

DISPLAY BY NAME rm_r23.r23_usuario, rm_r23.r23_paridad, 
		rm_r23.r23_telcli
IF rm_r23.r23_cont_cred = 'R' THEN
	DISPLAY BY NAME cupo_credito, saldo_credito
ELSE
	CLEAR cupo_credito, saldo_credito	
END IF
INPUT BY NAME rm_r23.r23_ped_cliente, cupo_credito, rm_r23.r23_telcli,
	      rm_r23.r23_ord_compra,  rm_r23.r23_referencia, rm_r23.r23_paridad,
	      rm_r23.r23_usuario, saldo_credito
	      WITHOUT DEFAULTS
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas() 
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END INPUT
IF int_flag THEN
	LET rm_r23.r23_ped_cliente 	= ped_cliente
	LET rm_r23.r23_telcli		= telcli
	LET rm_r23.r23_ord_compra 	= ord_compra
	LET rm_r23.r23_referencia	= referencia
	LET int_flag = 0
END IF


IF rm_r23.r23_ord_compra IS NOT NULL THEN
	--CALL fgl_winmessage(vg_producto,'Para pagar con orden de compra la pre-venta debe ser a credito.','info')
	CALL fl_mostrar_mensaje('Para pagar con orden de compra la pre-venta debe ser a credito.','info')
	LET rm_r23.r23_cont_cred = 'R' 
END IF

CLOSE WINDOW w_repp209_2
RETURN	

END FUNCTION



FUNCTION calcula_cupo_credito()
DEFINE 	saldo		LIKE cxct020.z20_saldo_cap
DEFINE j		SMALLINT
DEFINE r_cupo ARRAY[200] OF RECORD
	z20_saldo_cap	LIKE cxct020.z20_saldo_cap,
	z20_saldo_int	LIKE cxct020.z20_saldo_int
	END RECORD

IF rm_r23.r23_codcli IS NOT NULL THEN
	DECLARE q_cupo CURSOR FOR 
		SELECT z20_saldo_cap, z20_saldo_int
			FROM  cxct020
			WHERE z20_compania  = vg_codcia
			AND   z20_localidad = vg_codloc
			AND   z20_codcli    = rm_r23.r23_codcli 
			AND   z20_moneda    = rm_r23.r23_moneda 
	LET j = 1
	LET saldo = 0
	FOREACH q_cupo INTO r_cupo[j].*
		IF j > vm_elementos THEN
			EXIT FOREACH
		END IF
		LET saldo = saldo + r_cupo[j].z20_saldo_cap + 
				    r_cupo[j].z20_saldo_int
		LET j = j + 1
	END FOREACH
	LET saldo_credito = 0
	IF rm_r23.r23_moneda = rg_gen.g00_moneda_base THEN
		LET cupo_credito = vm_cupo_credito_mb 
		LET saldo_credito = vm_cupo_credito_mb - saldo
		IF saldo_credito < 0 THEN
			LET saldo_credito = 0
		END IF
	ELSE
		LET cupo_credito = vm_cupo_credito_ma 
		LET saldo_credito = vm_cupo_credito_ma - saldo
		IF saldo_credito < 0 THEN
			LET saldo_credito = 0
		END IF
	END IF
END IF

END FUNCTION



FUNCTION ingresa_detalles()
DEFINE i,j,k,ind, num	SMALLINT
DEFINE resp		CHAR(6)
DEFINE descuento	LIKE rept024.r24_descuento
DEFINE stock		LIKE rept024.r24_cant_ven
DEFINE item_anterior	LIKE rept010.r10_codigo
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE cod_bod		LIKE rept002.r02_codigo
DEFINE name_bod		LIKE rept002.r02_nombre
DEFINE mensaje		CHAR(70)
DEFINE cantfalta	DECIMAL (8,2)

IF vg_gui = 0 THEN
	LET vm_filas_pant = 4
END IF
--#LET vm_filas_pant  = fgl_scr_size('r_detalle')
LET vm_flag_margen = 'A'	-- INICIALIZO CON 'A' -->  OK
LET i = 1
LET j = 1
IF vm_flag_mant <> 'M' THEN
	FOR i = 1 TO vm_filas_pant 
		INITIALIZE r_detalle[i].* TO NULL
		CLEAR r_detalle[i].*
	END FOR
	LET i = 1
	CALL set_count(i)
ELSE 
	CALL set_count(vm_ind_arr)
END IF
LET int_flag = 0

LET mensaje = 'Número máximo de líneas permitido en la factura: ',
	       rm_r00.r00_numlin_fact 
MESSAGE mensaje

INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
	BEFORE ROW
		LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
		LET j = scr_line()    # POSICION CORRIENTE EN LA PANTALLA
		IF r_detalle[i].r24_item IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, r_detalle[i].r24_item)
				RETURNING rm_r10.*
				DISPLAY rm_r10.r10_nombre TO nom_item
		END IF

		DISPLAY '' AT 10,1 
		LET num = arr_count()
		DISPLAY i,' de ',num AT 10,68

	ON KEY(INTERRUPT)
		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso()
               		RETURNING resp
		IF resp = 'Yes' THEN
			DISPLAY '' AT 10,1 
			MESSAGE ''
			LET int_flag = 1
			RETURN 0
		END IF
	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_2() 
	ON KEY(F2)
		LET i = arr_curr()
		IF INFIELD(r24_item) THEN
                	CALL fl_ayuda_maestro_items_stock(vg_codcia,
							 rm_r23.r23_grupo_linea,
							r_detalle[i].r24_bodega)
	                			 --rm_r23.r23_bodega)
                     		RETURNING rm_r10.r10_codigo,  rm_r10.r10_nombre,
					  rm_r10.r10_linea,rm_r10.r10_precio_mb,
					  rm_r11.r11_bodega, stock 

                     	IF rm_r10.r10_codigo IS NOT NULL THEN
				LET r_detalle[i].r24_item   = rm_r10.r10_codigo
				LET r_detalle[i].r24_bodega = rm_r11.r11_bodega
     				CALL fl_lee_item(vg_codcia, rm_r10.r10_codigo)
					RETURNING rm_r10.*

				IF rg_gen.g00_moneda_base = rm_r23.r23_moneda 
				   THEN
					LET r_detalle[i].r24_precio = 
				    	    rm_r10.r10_precio_mb
				ELSE	
					LET r_detalle[i].r24_precio = 
				    	    rm_r10.r10_precio_ma
				END IF	

                        	DISPLAY r_detalle[i].r24_item TO
					r_detalle[j].r24_item
                        	DISPLAY r_detalle[i].r24_precio TO
					r_detalle[j].r24_precio
                        	DISPLAY r_detalle[i].r24_bodega TO
					r_detalle[j].r24_bodega

				IF r_detalle[i].r24_cant_ped IS NOT NULL THEN
				       CALL control_stock(r_detalle[i].r24_bodega, r_detalle[i].r24_item)
						RETURNING stock
					IF stock > r_detalle[i].r24_cant_ped 
					   THEN
						LET r_detalle[i].r24_cant_ven = 
			    		   	    r_detalle[i].r24_cant_ped
					ELSE
						LET r_detalle[i].r24_cant_ven = stock
					END IF
					LET r_detalle[i].r24_descuento = 
					    rm_r23.r23_descuento
					LET k = i - j + 1
					CALL calcula_totales(i,k)
                     		END IF
				DISPLAY r_detalle[i].r24_cant_ven TO
					r_detalle[j].r24_cant_ven
                        	DISPLAY r_detalle[i].r24_descuento TO
					r_detalle[j].r24_descuento
				DISPLAY r_detalle[i].subtotal_item TO
					r_detalle[j].subtotal_item
				NEXT FIELD r24_item
			END IF
                END IF
		IF infield(r24_bodega) THEN 
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', '2', 'R', 'S', 'V')
		     		RETURNING cod_bod, name_bod
		     	IF cod_bod IS NOT NULL THEN
				LET r_detalle[i].r24_bodega = cod_bod
				DISPLAY r_detalle[i].r24_bodega TO 
					r_detalle[j].r24_bodega
		     	END IF
		END IF
                LET int_flag = 0
	ON KEY(F8)
		IF r_detalle[i].r24_cant_ped IS NOT NULL AND 
		   r_detalle[i].r24_item     IS NOT NULL  
		   THEN
			IF rm_r23.r23_descuento <> 0.00 THEN
				FOR k = 1 TO arr_count()
					LET r_detalle[k].r24_descuento = 
					    rm_r23.r23_descuento
				END FOR
			ELSE
				LET vm_flag_dscto_defaults = 'S'
				CALL calcula_descuentos(r_detalle_1[i].r24_linea, r_detalle_1[i].rotacion)
				LET vm_flag_dscto_defaults = 'N'
			END IF
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
		END IF
			
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER DELETE	
		IF rm_r23.r23_descuento = 0.00 THEN
			CALL calcula_descuentos(r_detalle_1[i].r24_linea,
						r_detalle_1[i].rotacion)
		END IF
		LET k = i - j + 1
		CALL calcula_totales(arr_count(),k)
			DISPLAY r_detalle[i].r24_cant_ven TO
				r_detalle[j].r24_cant_ven
			DISPLAY r_detalle[i].r24_descuento TO
				r_detalle[j].r24_descuento
			DISPLAY r_detalle[i].subtotal_item TO
				r_detalle[j].subtotal_item
		CALL deleteRow(i, arr_count() + 1)

	AFTER FIELD r24_cant_ped
		IF r_detalle[i].r24_item IS NOT NULL THEN
		--- PARA CONOCER EL STOCK DEL ITEM EN LA BODEGA INGRESADA ---
			CALL control_stock(r_detalle[i].r24_bodega, r_detalle[i].r24_item)
				RETURNING stock
			IF stock > r_detalle[i].r24_cant_ped THEN
				LET r_detalle[i].r24_cant_ven = 
				    r_detalle[i].r24_cant_ped
			ELSE
				LET r_detalle[i].r24_cant_ven = stock
			END IF
		-------------------------------------------------------------
			IF rm_r23.r23_descuento = 0.00 THEN
			      CALL calcula_descuentos(r_detalle_1[i].r24_linea,
						      r_detalle_1[i].rotacion)
			END IF
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
			DISPLAY r_detalle[i].r24_cant_ven TO
				r_detalle[j].r24_cant_ven
			DISPLAY r_detalle[i].r24_descuento TO
				r_detalle[j].r24_descuento
			DISPLAY r_detalle[i].subtotal_item TO
				r_detalle[j].subtotal_item
		END IF

	AFTER FIELD r24_bodega
		IF r_detalle[i].r24_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia,r_detalle[i].r24_bodega)
				RETURNING r_r02.*
			IF r_r02.r02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.', 'exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')
				NEXT FIELD r24_bodega
			END IF
			NEXT FIELD r24_item
		ELSE
			IF r_detalle[i].r24_item IS NOT NULL THEN
				NEXT FIELD r24_bodega
			END IF
		END IF

	BEFORE FIELD r24_item
		IF r_detalle[i].r24_item IS NOT NULL THEN
			LET item_anterior = r_detalle[i].r24_item
		END IF

	AFTER FIELD r24_item
	    	IF r_detalle[i].r24_item IS NOT NULL THEN
     			CALL fl_lee_item(vg_codcia, r_detalle[i].r24_item)
				RETURNING rm_r10.*
                	IF rm_r10.r10_codigo IS NULL THEN
                       		--CALL fgl_winmessage(vg_producto,'El item no existe.','exclamation')
				CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                       		NEXT FIELD r24_item
                	END IF
                	IF rm_r10.r10_estado = 'B' THEN
                       		--CALL fgl_winmessage(vg_producto, 'El Item está con status Bloqueado','exclamation')
				CALL fl_mostrar_mensaje( 'El Item está con status Bloqueado','exclamation')
                       		NEXT FIELD r24_item
                	END IF
		------ PARA LA VALIDACION DE ITEMS REPETIDOS ------
			FOR k = 1 TO arr_count()
				IF  r_detalle[i].r24_item =
				    r_detalle[k].r24_item AND 
				    r_detalle[i].r24_bodega =
				    r_detalle[k].r24_bodega AND 
				    i <> k
				    THEN
					--CALL fgl_winmessage(vg_producto,'No puede ingresar items repetidos','exclamation')
					CALL fl_mostrar_mensaje('No puede ingresar items repetidos','exclamation')
					NEXT FIELD r24_item
               			END IF
			END FOR
		----------------------------------------------------------
		--- PARA SABER SI LA LINEA DE VTA. CORRESPONDE AL GRP. VTA. ---
			CALL fl_lee_linea_rep(vg_codcia, rm_r10.r10_linea)
				RETURNING rm_r03.*	
			IF rm_r03.r03_grupo_linea <> rm_g20.g20_grupo_linea THEN
				--CALL fgl_winmessage(vg_producto,'El Item no pertenece al Grupo de Línea de Venta. ','exclamation')
				CALL fl_mostrar_mensaje('El Item no pertenece al Grupo de Línea de Venta. ','exclamation')
				NEXT FIELD r24_item
			END IF
		-------------------------------------------------------------
		--- PARA CONOCER EL STOCK DEL ITEM EN LA BODEGA INGRESADA ---
			CALL control_stock(r_detalle[i].r24_bodega, r_detalle[i].r24_item)
				RETURNING stock
			LET cantfalta = 0
			IF stock > r_detalle[i].r24_cant_ped THEN
				LET r_detalle[i].r24_cant_ven = 
				    r_detalle[i].r24_cant_ped
			ELSE
				LET r_detalle[i].r24_cant_ven = stock
				LET cantfalta = r_detalle[i].r24_cant_ven - 
				    r_detalle[i].r24_cant_ped
			END IF
		-------------------------------------------------------------
		--- VALIDACIÓN DE VENTA SIN STOCK
			IF stock = 0 OR cantfalta < 0 THEN
				CALL fl_hacer_pregunta('Este ítem no tiene stock o no alcanza para completar el pedido. Desea hacer una venta sin stock','Yes')
					RETURNING resp
				LET int_flag = 0
				LET vm_flag_bodega_sin_stock = 'N'
				IF resp = 'Yes' THEN
					IF stock <> 0 AND cantfalta < 0 THEN
						CALL fl_mostrar_mensaje('Ubiquese en la siguente fila y digíte la diferencia de cantidad pedida.','info')
				    		LET r_detalle[i].r24_cant_ped =
				    		 r_detalle[i].r24_cant_ped +
						 cantfalta
				    	      DISPLAY r_detalle[i].r24_cant_ped
				    	      TO r_detalle[j].r24_cant_ped
					END IF
					IF stock = 0 THEN
						LET r_detalle[i].r24_bodega =
							rm_bodssto.r02_codigo
					END IF
					DISPLAY r_detalle[i].r24_bodega
						TO r_detalle[j].r24_bodega
					LET vm_flag_bodega_sin_stock = 'S'
				ELSE
					NEXT FIELD r24_item
				END IF
			END IF
		-------------------------------------------------------------
		------------------------------------------------------------
			---- ASIGNO VALORES SI TODO OK. ----
			IF r_detalle[i].r24_descuento IS NULL THEN
				LET r_detalle[i].r24_descuento = 
				    rm_r23.r23_descuento
			END IF
			LET r_detalle_1[i].r24_linea   = rm_r10.r10_linea
			LET r_detalle_1[i].rotacion    = rm_r10.r10_rotacion

			IF rg_gen.g00_moneda_base = rm_r23.r23_moneda THEN
				LET r_detalle[i].r24_precio = 
				    rm_r10.r10_precio_mb
			ELSE	
				LET r_detalle[i].r24_precio = 
				    rm_r10.r10_precio_ma
			END IF	
			DISPLAY rm_r10.r10_nombre TO nom_item
		------------------------------------------------------------
		---- PARA CONTROLAR QUE EL PRECIO SEA MAYOR CERO ----
			IF stock > 0 AND r_detalle[i].r24_precio <= 0 THEN
				--CALL fgl_winmessage(vg_producto,'El item no puede ser facturado porque tiene stock y su precio es igual a cero. ','exclamation')
				CALL fl_mostrar_mensaje('El item no puede ser facturado porque tiene stock y su precio es igual a cero. ','exclamation')
				NEXT FIELD r24_item
			END IF
		-----------------------------------------------------
		--- PARA CONOCER EL DESCUENTO CORRESPONDIENTE AL ITEM ---
			IF item_anterior <> r_detalle[i].r24_item THEN
				IF rm_r23.r23_descuento <> 0.00 THEN
					LET r_detalle[i].r24_descuento = 
					    rm_r23.r23_descuento
				ELSE
					IF rm_r00.r00_tipo_descto = 'L' THEN
						IF rm_r23.r23_cont_cred = 'C' 
						   THEN
							LET r_detalle[i].r24_descuento = rm_r03.r03_dcto_cont
						ELSE
							LET r_detalle[i].r24_descuento = rm_r03.r03_dcto_cred
						END IF
					ELSE
			 			CALL fl_lee_indice_rotacion(vg_codcia, r_detalle_1[i].rotacion)	RETURNING rm_r04.*
						IF rm_r23.r23_cont_cred = 'C' 
						   THEN
							LET r_detalle[i].r24_descuento = rm_r04.r04_dcto_cont
						ELSE
							LET r_detalle[i].r24_descuento = rm_r04.r04_dcto_cred
						END IF
					END IF
			
		    	           	CALL calcula_descuentos(r_detalle_1[i].r24_linea, r_detalle_1[i].rotacion)
				END IF
			END IF
		---------------------------------------------------------
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
			DISPLAY r_detalle[i].r24_descuento TO
				r_detalle[j].r24_descuento
			DISPLAY r_detalle[i].r24_cant_ven TO
				r_detalle[j].r24_cant_ven
			DISPLAY r_detalle[i].r24_precio TO
				r_detalle[j].r24_precio
			DISPLAY r_detalle[i].subtotal_item TO
				r_detalle[j].subtotal_item
		------------------------------------------------------------
		ELSE
			IF r_detalle[i].r24_cant_ped IS NOT NULL
				AND r_detalle[i].r24_item IS NULL
			THEN
				NEXT FIELD r24_item
			END IF 
		END IF
	BEFORE FIELD r24_descuento
		IF vm_flag_vendedor <> 'S' THEN
			NEXT FIELD NEXT
		END IF
		IF r_detalle[i].r24_precio = 0 THEN
			LET r_detalle[i].r24_descuento = 0
			NEXT FIELD NEXT
		END IF

	AFTER FIELD r24_descuento
		IF r_detalle[i].r24_item IS NOT NULL AND
		   r_detalle[i].r24_cant_ped IS NOT NULL 
		   THEN	
			LET k = i - j + 1
			CALL calcula_totales(arr_count(),k)
		END IF 
	AFTER INPUT
		IF rm_r23.r23_tot_neto - rm_r23.r23_flete = 0 THEN
			NEXT FIELD r24_cant_ped
		END IF 
		LET ind = arr_count()
		LET vm_ind_arr = arr_count()
		CALL control_margen_utilidad()
		IF rm_r23.r23_cont_cred = 'C' AND
		   rm_r23.r23_codcli IS NOT NULL 
		   THEN
			CALL control_anticipos_cliente()
		END IF

		IF arr_count() > rm_r00.r00_numlin_fact THEN
			CALL fl_mostrar_mensaje('El número de líneas permitida por factura es de '||rm_r00.r00_numlin_fact|| '.' || ' Elimine líneas o abandone el ingreso.','exclamation')
			NEXT FIELD r24_cant_ped
		END IF
			
END INPUT
DISPLAY '' AT 10,1 
MESSAGE ''
RETURN ind

END FUNCTION



FUNCTION control_mensajes_despues_grabar()

IF vm_flag_margen = 'S' THEN
	--CALL fgl_winmessage(vg_producto,'El margen de utilidad está por debajo de lo configurado por la Compañía. Necesita Aprobación.','exclamation')
	CALL fl_mostrar_mensaje('El margen de utilidad está por debajo de lo configurado por la Compañía. Necesita Aprobación.','exclamation')
END IF 

IF vm_credito_auto = 'N' AND rm_r23.r23_cont_cred = 'R' THEN
	--CALL fgl_winmessage(vg_producto,'El cliente no posee crédito automático necesita aprobación.','exclamation')
	CALL fl_mostrar_mensaje('El cliente no posee crédito automático necesita aprobación.','exclamation')
END IF

IF rm_r23.r23_cont_cred = 'R' AND rm_r23.r23_tot_neto > cupo_credito AND
   vm_credito_auto <> 'N'
   THEN
	--CALL fgl_winmessage(vg_producto,'El cliente sobrepaso su cupo de crédito. La preventa necesita aprobación.','exclamation')
	CALL fl_mostrar_mensaje('El cliente sobrepaso su cupo de crédito. La preventa necesita aprobación.','exclamation')
END IF

END FUNCTION




FUNCTION control_anticipos_cliente()
DEFINE i		SMALLINT 
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_r27		RECORD LIKE rept027.*
DEFINE resp 		CHAR(6)

DECLARE q_read_z21 CURSOR FOR
	SELECT * FROM cxct021
		WHERE z21_compania  = vg_codcia
		  AND z21_localidad = vg_codloc
		  AND z21_codcli    = rm_r23.r23_codcli
		  AND z21_areaneg   = rm_g20.g20_areaneg
		  AND z21_moneda    = rm_r23.r23_moneda
		  AND z21_saldo     > 0		
		ORDER BY z21_fecha_emi 

DECLARE q_read_r27 CURSOR FOR
	SELECT * FROM rept027
		WHERE r27_compania  = vg_codcia
		  AND r27_localidad = vg_codloc
		  AND r27_numprev   = rm_r23.r23_numprev

LET i = 1
FOREACH q_read_z21 INTO r_z21.*
	LET r_detalle_2[i].z21_tipo_doc  = r_z21.z21_tipo_doc
	LET r_detalle_2[i].z21_num_doc   = r_z21.z21_num_doc
	LET r_detalle_2[i].z21_moneda    = r_z21.z21_moneda
	LET r_detalle_2[i].z21_fecha_emi = r_z21.z21_fecha_emi
	LET r_detalle_2[i].z21_saldo     = r_z21.z21_saldo
	LET r_detalle_2[i].r27_valor     = 0 
	LET i = i + 1
	IF i > vm_elementos THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
LET vm_ind_docs = i

FOREACH q_read_r27 INTO r_r27.* 
	FOR i = 1 TO vm_ind_docs 
		IF r_detalle_2[i].z21_tipo_doc = r_r27.r27_tipo 
		AND r_detalle_2[i].z21_num_doc = r_r27.r27_numero 
		THEN
			LET r_detalle_2[i].r27_valor = r_r27.r27_valor 
			EXIT FOR
		END IF
	END FOR
END FOREACH

IF i = 0 THEN
	RETURN
ELSE
	--CALL fgl_winquestion(vg_producto,'El cliente tiene documentos a favor en la compañia desea aplicarlos a la pre-venta','No','Yes|No','question',1)
	CALL fl_hacer_pregunta('El cliente tiene documentos a favor en la compañia desea aplicarlos a la pre-venta','No')
		RETURNING resp
	IF resp = 'No' THEN
		RETURN
	ELSE
		OPEN WINDOW w_209_3 AT 8, 11 WITH 14 ROWS, 68 COLUMNS
		ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		MESSAGE LINE LAST - 1) 
		IF vg_gui = 1 THEN
			OPEN FORM f_209_3 FROM '../forms/repf210_2'
		ELSE
			OPEN FORM f_209_3 FROM '../forms/repf210_2c'
		END IF
		DISPLAY FORM f_209_3
		CLEAR FORM
		CALL control_display_botones_anticipos()
	END IF
END IF

CALL control_ingreso_anticipos()
IF int_flag THEN
	LET int_flag = 0
END IF
CLOSE WINDOW w_209_3

END FUNCTION



FUNCTION control_display_botones_anticipos()

IF vg_gui = 1 THEN
	--#DISPLAY 'Tip'		TO tit_col1
	--#DISPLAY 'No. Doc.'		TO tit_col2
	--#DISPLAY 'Mon'		TO tit_col3
	--#DISPLAY 'Fec. Emisión'	TO tit_col4
	--#DISPLAY 'Saldo Doc.'		TO tit_col5
	--#DISPLAY 'Valor a usar'	TO tit_col6
END IF
	
END FUNCTION



FUNCTION control_ingreso_anticipos()
DEFINE i,j,done		SMALLINT 
DEFINE resp		CHAR(6)
DEFINE r_z21		RECORD LIKE cxct021.*

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F40

CALL calcula_total_anticipos(vm_ind_docs)

LET int_flag = 0
WHILE TRUE

	CALL set_count(vm_ind_docs)
	INPUT ARRAY r_detalle_2 WITHOUT DEFAULTS FROM r_detalle_2.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
               		 	RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
        	ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas() 
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line() 
		AFTER ROW
			CALL calcula_total_anticipos(vm_ind_docs)
		AFTER FIELD r27_valor
			IF r_detalle_2[i].r27_valor IS NOT NULL THEN
				IF r_detalle_2[i].r27_valor > 
				   r_detalle_2[i].z21_saldo
				   THEN
					--CALL fgl_winmessage(vg_producto,'El saldo del documento es insuficiente.','exclamation')
					CALL fl_mostrar_mensaje('El saldo del documento es insuficiente.','exclamation')
					NEXT FIELD r27_valor
				END IF
			ELSE
				LET r_detalle_2[i].r27_valor = 0
				DISPLAY r_detalle_2[i].r27_valor TO 
					r_detalle_2[j].r27_valor
				END IF
			CALL calcula_total_anticipos(vm_ind_docs)
		BEFORE INSERT
			EXIT INPUT
		BEFORE DELETE
			EXIT INPUT
		AFTER INPUT 
			CALL calcula_total_anticipos(vm_ind_docs)
			IF total_anticipos > rm_r23.r23_tot_neto THEN
				--CALL fgl_winmessage(vg_producto,'El total de los pagos anticipados aplicados es mayor al total de la factura.','exclamation') 
				CALL fl_mostrar_mensaje('El total de los pagos anticipados aplicados es mayor al total de la factura.','exclamation') 
				CONTINUE INPUT
			END IF
			IF total_anticipos = rm_r25.r25_valor_cred THEN
				--CALL fgl_winquestion(vg_producto,'El total de los pagos anticipados aplicados es igual al total de la preventa, desea aplicar a la preventa.', 'No', 'Yes|No','question', 1) 
				CALL fl_hacer_pregunta('El total de los pagos anticipados aplicados es igual al total de la preventa, desea aplicar a la preventa.', 'No') 
					RETURNING resp 
				IF resp = 'Yes' THEN
					LET vm_flag_anticipos = 'S'
					RETURN
				ELSE
					CONTINUE INPUT
				END IF	
			END IF
		LET vm_flag_anticipos = 'S'
		EXIT WHILE
END INPUT
IF int_flag THEN
	LET vm_flag_anticipos = 'N'
	LET total_anticipos = 0
	RETURN
END IF
END WHILE

END FUNCTION



FUNCTION calcula_total_anticipos(num_elm)
DEFINE num_elm		SMALLINT
DEFINE i 		SMALLINT

LET total_anticipos = 0
FOR i = 1 TO num_elm
	IF r_detalle_2[i].r27_valor IS NOT NULL THEN
		LET total_anticipos = total_anticipos + r_detalle_2[i].r27_valor
	END IF
END FOR

DISPLAY BY NAME total_anticipos

END FUNCTION



FUNCTION control_actualizacion_anticipos()
DEFINE i,done SMALLINT

INITIALIZE rm_r25.* TO NULL

	DELETE FROM rept025
		WHERE r25_compania  = vg_codcia
		AND   r25_localidad = vg_codloc
		AND   r25_numprev   = rm_r23.r23_numprev

	LET rm_r25.r25_compania   = vg_codcia
	LET rm_r25.r25_localidad  = vg_codloc
	LET rm_r25.r25_numprev    = rm_r23.r23_numprev
	LET rm_r25.r25_valor_ant  = total_anticipos
	LET rm_r25.r25_valor_cred = 0
	LET rm_r25.r25_dividendos = 0
	LET rm_r25.r25_plazo      = 0
	LET rm_r25.r25_interes    = 0

	INSERT INTO rept025 VALUES(rm_r25.*)

DELETE FROM rept027 
	WHERE r27_compania  = vg_codcia 
	AND   r27_localidad = vg_codloc
	AND   r27_numprev   = rm_r23.r23_numprev

LET rm_r27.r27_compania  = vg_codcia
LET rm_r27.r27_localidad = vg_codloc
LET rm_r27.r27_numprev   = rm_r23.r23_numprev

FOR i = 1 TO vm_ind_docs
	IF r_detalle_2[i].r27_valor IS NOT NULL AND
	   r_detalle_2[i].r27_valor > 0 
	   THEN
		LET rm_r27.r27_tipo   = r_detalle_2[i].z21_tipo_doc
		LET rm_r27.r27_numero = r_detalle_2[i].z21_num_doc
		LET rm_r27.r27_valor  = r_detalle_2[i].r27_valor
		INSERT INTO rept027 VALUES (rm_r27.*)
	END IF
END FOR 

END FUNCTION



FUNCTION control_credito()
DEFINE vcto 	DATE

IF rm_r23.r23_cont_cred = 'R' AND cupo_credito >= rm_r23.r23_tot_neto AND  
   vm_credito_auto     <> 'N'
   THEN
	DELETE FROM rept025
		WHERE r25_compania  = vg_codcia
		AND   r25_localidad = vg_codloc
		AND   r25_numprev   = rm_r23.r23_numprev
	DELETE FROM rept026
		WHERE r26_compania  = vg_codcia
		AND   r26_localidad = vg_codloc
		AND   r26_numprev   = rm_r23.r23_numprev

	INSERT INTO rept025 
			VALUES(vg_codcia, vg_codloc,  rm_r23.r23_numprev, 0, 
		       	       rm_r23.r23_tot_neto, 0, 1, vm_plazo, NULL, NULL)

	LET vcto = TODAY + vm_plazo 

	INSERT INTO rept026 
			VALUES(vg_codcia, vg_codloc,  rm_r23.r23_numprev, 1, 
		       	       rm_r23.r23_tot_neto, 0, vcto)
END IF

END FUNCTION



FUNCTION control_stock(bodega, item)
DEFINE bodega 	LIKE rept024.r24_bodega
DEFINE item 	LIKE rept024.r24_item

CALL fl_lee_stock_rep(vg_codcia, bodega, item)
	RETURNING rm_r11.*
IF rm_r11.r11_stock_act IS NULL THEN
	LET rm_r11.r11_stock_act = 0
END IF
RETURN rm_r11.r11_stock_act

END FUNCTION




FUNCTION calcula_totales(indice, indice_2)
DEFINE indice,k		SMALLINT
DEFINE indice_2,y	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

IF vg_gui = 0 THEN
	LET vm_filas_pant = 4
END IF
--#LET vm_filas_pant = fgl_scr_size('r_detalle')
LET vm_costo     = 0	-- TOTAL COSTO 
LET vm_subtotal  = 0	-- TOTAL BRUTO 
LET vm_descuento = 0	-- TOTAL DEL DESCUENTO
LET vm_impuesto  = 0 	-- TOTAL DEL IMPUESTO
LET vm_total     = 0	-- TOTAL NETO
LET vm_tot_peso  = 0	-- TOTAL PESO

FOR k = 1 TO indice
	CALL fl_lee_item(vg_codcia, r_detalle[k].r24_item)
		RETURNING r_r10.*

	LET r_detalle_1[k].r24_linea = r_r10.r10_linea
	LET r_detalle_1[k].rotacion  = r_r10.r10_rotacion

	IF rg_gen.g00_moneda_base = rm_r23.r23_moneda THEN
		LET r_detalle_1[k].costo_item = r_r10.r10_costo_mb
	ELSE	
		LET r_detalle_1[k].costo_item = r_r10.r10_costo_ma
	END IF	

	LET r_detalle_1[k].val_costo = r_detalle[k].r24_cant_ven * 
				       r_detalle_1[k].costo_item
	LET vm_costo = vm_costo + r_detalle_1[k].val_costo 

	LET r_detalle[k].subtotal_item = r_detalle[k].r24_precio *  
				         r_detalle[k].r24_cant_ven
	LET vm_subtotal = vm_subtotal + r_detalle[k].subtotal_item 

	LET r_detalle_1[k].r24_val_descto = r_detalle[k].r24_cant_ven  *
					    r_detalle[k].r24_precio    * 
					    r_detalle[k].r24_descuento / 100  
	LET r_detalle_1[k].r24_val_descto = 
	    fl_retorna_precision_valor(rm_r23.r23_moneda,
				       r_detalle_1[k].r24_val_descto)

	LET vm_descuento = vm_descuento + r_detalle_1[k].r24_val_descto

	LET r_detalle_1[k].r24_val_impto = 0
	IF vm_flag_calculo_impto = 'I' THEN
		IF rm_c01.z01_paga_impto IS NULL OR
	   	   rm_c01.z01_paga_impto <> 'N' THEN
			LET r_detalle_1[k].r24_val_impto =
		    	(r_detalle[k].subtotal_item - 
			 r_detalle_1[k].r24_val_descto) * 
			 rm_r23.r23_porc_impto     / 100
			LET r_detalle_1[k].r24_val_impto = 
	    	    	fl_retorna_precision_valor(rm_r23.r23_moneda,
		 	  		           r_detalle_1[k].r24_val_impto)
		END IF
		LET vm_impuesto = vm_impuesto + r_detalle_1[k].r24_val_impto
	END IF

	-- OJO...

	LET vm_tot_peso = vm_tot_peso + 
			 (r_r10.r10_peso * r_detalle[k].r24_cant_ven) 

END FOR

LET y = indice_2

IF indice < vm_filas_pant THEN
	LET vm_filas_pant = indice
END IF

FOR k = 1 TO vm_filas_pant
	DISPLAY r_detalle[y].r24_descuento TO r_detalle[k].r24_descuento
	IF y = indice THEN
		EXIT FOR
	END IF 
	LET y = y + 1
END FOR

IF vm_flag_calculo_impto <> 'I' THEN
	LET vm_impuesto = 0
	LET vm_impuesto = vm_impuesto +((vm_subtotal - vm_descuento) * 
				         rm_r23.r23_porc_impto / 100 )
END IF

LET vm_total = vm_subtotal - vm_descuento + vm_impuesto + rm_r23.r23_flete
LET rm_r23.r23_tot_costo = vm_costo
LET rm_r23.r23_tot_bruto = vm_subtotal
LET rm_r23.r23_tot_dscto = vm_descuento
LET rm_r23.r23_tot_neto  = vm_total
DISPLAY BY NAME rm_r23.r23_tot_bruto, rm_r23.r23_tot_dscto, 
		vm_impuesto, rm_r23.r23_tot_neto, vm_tot_peso

END FUNCTION



FUNCTION calcula_descuentos(linea, rotacion)
DEFINE linea		LIKE rept024.r24_linea
DEFINE rotacion		LIKE rept010.r10_rotacion
DEFINE descuento	LIKE rept024.r24_descuento
DEFINE item		LIKE rept010.r10_codigo

IF rm_r00.r00_tipo_descto = 'L' THEN
	CALL control_descuento_linea(linea)
ELSE
	CALL control_descuento_rotacion(rotacion)
END IF

END FUNCTION



FUNCTION control_descuento_linea(linea)
DEFINE linea			LIKE rept007.r07_linea
DEFINE descuento	 	LIKE rept007.r07_descuento
DEFINE total_linea_item		LIKE rept007.r07_monto_fin
DEFINE j			SMALLINT
DEFINE r_r03			RECORD LIKE rept003.*	-- LINEA DE VENTA

INITIALIZE descuento TO NULL

LET total_linea_item = 0
FOR j = 1 TO arr_count()
	IF linea = r_detalle_1[j].r24_linea THEN
		LET total_linea_item = total_linea_item + 
				       r_detalle[j].r24_precio * 
			      	       r_detalle[j].r24_cant_ven
	END IF  
END FOR

	SELECT r07_descuento INTO descuento
		 FROM rept007
		WHERE r07_compania  =  vg_codcia
		  AND r07_linea     =  linea
		  AND r07_cont_cred =  rm_r23.r23_cont_cred
		  AND total_linea_item
              BETWEEN r07_monto_ini AND r07_monto_fin

IF descuento IS NULL THEN  --- No encontro ningun descuento para ese 
			   --- valor de la preventa 

	IF vm_flag_dscto_defaults = 'S' THEN
		IF rm_r23.r23_cont_cred = 'C' THEN
			LET descuento = rm_r03.r03_dcto_cont
		ELSE
			LET descuento = rm_r03.r03_dcto_cred
		END IF
		FOR j = 1 TO arr_count()
			IF linea = r_detalle_1[j].r24_linea THEN
				LET r_detalle[j].r24_descuento = descuento
			END IF  
		END FOR
	END IF

	RETURN

ELSE
	FOR j = 1 TO arr_count()
		IF linea = r_detalle_1[j].r24_linea THEN
			LET r_detalle[j].r24_descuento = descuento
		END IF  
	END FOR
END IF

END FUNCTION



FUNCTION control_descuento_rotacion(rotacion)
DEFINE descuento	 	LIKE rept008.r08_descuento
DEFINE total_rotacion_item	LIKE rept008.r08_monto_fin
DEFINE j			SMALLINT
DEFINE r_r04			RECORD LIKE rept004.*
DEFINE rotacion			LIKE rept008.r08_rotacion

INITIALIZE descuento TO NULL

LET total_rotacion_item = 0
FOR j = 1 TO arr_count()
	IF rotacion = r_detalle_1[j].rotacion THEN
		LET total_rotacion_item = total_rotacion_item + 
				 	  r_detalle[j].r24_precio *
					  r_detalle[j].r24_cant_ven
	END IF  
END FOR
SELECT r08_descuento INTO descuento
	 FROM rept008
	WHERE r08_compania  =  vg_codcia
	  AND r08_rotacion  =  rotacion
	  AND r08_cont_cred =  rm_r23.r23_cont_cred
	  AND total_rotacion_item
      BETWEEN r08_monto_ini AND r08_monto_fin

IF descuento IS NULL THEN  --- No encontro ningun descuento para ese 
			   --- valor de la preventa 

	IF vm_flag_dscto_defaults = 'S' THEN
		IF rm_r23.r23_cont_cred = 'C' THEN
			LET descuento = rm_r04.r04_dcto_cont
		ELSE
			LET descuento = rm_r04.r04_dcto_cred
		END IF
		FOR j = 1 TO arr_count()
			IF rotacion = r_detalle_1[j].rotacion THEN
				LET r_detalle[j].r24_descuento = descuento
			END IF  
		END FOR
	END IF

	RETURN

ELSE
	FOR j = 1 TO arr_count()
		IF rotacion = r_detalle_1[j].rotacion THEN
			LET r_detalle[j].r24_descuento = descuento
		END IF  
	END FOR
END IF

END FUNCTION



FUNCTION control_margen_utilidad()
DEFINE margen		LIKE rept003.r03_porc_uti
DEFINE monto		LIKE rept024.r24_val_impto
DEFINE r_r03		RECORD LIKE rept003.*	-- LINEA DE VENTA
DEFINE r_r04		RECORD LIKE rept004.*	-- INDICE DE ROTACION
DEFINE r_item		RECORD LIKE rept010.*	-- MAESTRO DE ITEMS
DEFINE j		SMALLINT

LET rm_r23.r23_estado  = 'P'

FOR j = 1 TO arr_count()

	IF r_detalle[j].r24_precio = 0 THEN
		CONTINUE FOR
	END IF

	IF r_detalle[j].subtotal_item = 0 THEN
		CONTINUE FOR
	END IF
	LET monto =(r_detalle[j].subtotal_item - r_detalle_1[j].r24_val_descto) 		    - r_detalle_1[j].val_costo
	LET margen = monto / r_detalle_1[j].val_costo * 100	
	IF rm_r00.r00_tipo_descto = 'L' THEN
		CALL fl_lee_linea_rep(vg_codcia, r_detalle_1[j].r24_linea)
			RETURNING r_r03.*
		IF margen < r_r03.r03_porc_uti THEN
			LET rm_r23.r23_estado  = 'A'
			LET vm_flag_margen     = 'S'
			EXIT FOR
		END IF
	ELSE
		CALL fl_lee_item(vg_codcia, r_detalle[j].r24_item) 
			RETURNING r_item.*
		CALL fl_lee_indice_rotacion(vg_codcia, r_item.r10_rotacion)
			RETURNING r_r04.*
		IF margen < r_r04.r04_porc_uti THEN
			LET rm_r23.r23_estado = 'A'
			LET vm_flag_margen     = 'S'
			EXIT FOR
		END IF
	END IF
END FOR

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(500)
DEFINE expr_sql_2	CHAR(500)
DEFINE query		CHAR(600)
DEFINE r_r23		RECORD LIKE rept023.* 	-- CABECERA PREVENTA
DEFINE flag_cons_otros_datos 	CHAR(1)

DISPLAY '' AT 10,1 
INITIALIZE expr_sql_2 TO NULL
CLEAR FORM
CALL control_display_botones()

LET flag_cons_otros_datos = 'S'
LET INT_FLAG = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON r23_numprev,  r23_moneda,  r23_bodega,   r23_grupo_linea,
		     r23_codcli,   r23_nomcli, r23_cedruc,    r23_dircli, 
		     r23_vendedor, r23_estado, r23_descuento, r23_cont_cred,
		     r23_flete  
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_3() 
	ON KEY(F2)
		IF INFIELD(r23_numprev) THEN
			CALL fl_ayuda_preventas_rep(vg_codcia, vg_codloc,'M')
				RETURNING r_r23.r23_numprev, r_r23.r23_nomcli,
					  r_r23.r23_estado 
			IF r_r23.r23_numprev IS NOT NULL THEN
				CALL fl_lee_preventa_rep(vg_codcia,vg_codloc,
							 r_r23.r23_numprev)
					RETURNING rm_r23.*
				LET vm_fecha = rm_r23.r23_fecing
				DISPLAY BY NAME rm_r23.r23_numprev,
						rm_r23.r23_moneda,
						rm_r23.r23_grupo_linea,
						rm_r23.r23_bodega,
						rm_r23.r23_codcli,
						rm_r23.r23_nomcli,
						rm_r23.r23_dircli,
						rm_r23.r23_cedruc,
						rm_r23.r23_descuento,
						rm_r23.r23_vendedor,
						rm_r23.r23_flete,
						rm_r23.r23_porc_impto,
						rm_r23.r23_estado,
						rm_r23.r23_cont_cred,vm_fecha
				DISPLAY 'ACTIVO' TO tit_estado
			END IF
		END IF
		IF INFIELD(r23_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_r23.r23_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_r23.r23_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF
		IF INFIELD(r23_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F')
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r23.r23_vendedor = rm_r01.r01_codigo	
				DISPLAY BY NAME rm_r23.r23_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r23_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r23.r23_codcli = rm_c02.z02_codcli
				LET rm_r23.r23_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r23.r23_codcli,
						rm_r23.r23_nomcli
			END IF 
		END IF
		IF INFIELD(r23_bodega) THEN
		     CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', '2', 'R', 'S', 'V')
		     RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
		     IF rm_r02.r02_codigo IS NOT NULL THEN
			    LET rm_r23.r23_bodega = rm_r02.r02_codigo
			    DISPLAY BY NAME rm_r23.r23_bodega
			    DISPLAY rm_r02.r02_nombre TO nom_bodega
		     END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF flag_cons_otros_datos = 'S' THEN
			CALL control_consulta_otros_datos()
				RETURNING expr_sql_2
			LET int_flag = 0
		END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r23_descuento
		LET rm_r23.r23_descuento = get_fldbuf(r23_descuento)
               	IF rm_r23.r23_descuento IS NOT NULL THEN
			LET flag_cons_otros_datos = 'N'
		ELSE 
			LET flag_cons_otros_datos = 'S'
               	END IF
	AFTER FIELD r23_cont_cred
		LET rm_r23.r23_cont_cred = get_fldbuf(r23_cont_cred)
		IF vg_gui = 0 THEN
	               	IF rm_r23.r23_cont_cred IS NOT NULL THEN
				CALL muestra_contcred(rm_r23.r23_cont_cred)
			ELSE 
				CLEAR tit_cont_cred
			END IF
		END IF
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		CALL control_display_botones()
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'r23_numprev = ',vg_numprev 
END IF

IF expr_sql_2 IS NOT NULL THEN
	LET expr_sql = expr_sql || ' AND ' || expr_sql_2
END IF

LET query = 'SELECT *, ROWID FROM rept023 ',
		' WHERE r23_compania  = ', vg_codcia,
		' AND r23_localidad = ', vg_codloc,
		' AND ', expr_sql CLIPPED,
		' ORDER BY 3, 4' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r23.*, vm_rows[vm_num_rows]
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
	CALL muestra_contadores()
	CLEAR FORM
	CALL control_display_botones()
	RETURN
END IF

LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_consulta_otros_datos()
DEFINE expr_sql		CHAR(300)

OPEN WINDOW w_repp209_2 AT 11, 17 WITH 12 ROWS, 62 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER, 
		  MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp209_2 FROM '../forms/repf209_2'
ELSE
	OPEN FORM f_repp209_2 FROM '../forms/repf209_2c'
END IF
DISPLAY FORM f_repp209_2
CONSTRUCT BY NAME expr_sql
                  ON r23_ped_cliente, r23_telcli,     r23_ord_compra, 
		     r23_paridad,     r23_referencia, r23_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas() 
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
RETURN expr_sql
	
END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r23.* FROM rept023 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
LET vm_impuesto = rm_r23.r23_tot_neto - rm_r23.r23_flete - 
		  (rm_r23.r23_tot_bruto - rm_r23.r23_tot_dscto)
LET vm_fecha  = rm_r23.r23_fecing
	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r23.r23_numprev,     rm_r23.r23_vendedor,  rm_r23.r23_bodega,
		rm_r23.r23_tot_neto,    vm_fecha,             rm_r23.r23_moneda,
		rm_r23.r23_porc_impto,  rm_r23.r23_cont_cred, rm_r23.r23_codcli,
		rm_r23.r23_nomcli,      rm_r23.r23_dircli,    rm_r23.r23_cedruc,
		rm_r23.r23_descuento,   rm_r23.r23_flete,     rm_r23.r23_estado,
		rm_r23.r23_grupo_linea, rm_r23.r23_tot_bruto, 
		rm_r23.r23_tot_dscto,   vm_impuesto    
IF vg_gui = 0 THEN
	CALL muestra_contcred(rm_r23.r23_cont_cred)
END IF
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

DISPLAY BY NAME vm_tot_peso

END FUNCTION



FUNCTION muestra_detalle()
DEFINE r_r24 	RECORD LIKE rept024.*
DEFINE i 		SMALLINT
DEFINE query 		CHAR(300)
DEFINE peso 		LIKE rept010.r10_peso

IF vg_gui = 0 THEN
	LET vm_filas_pant = 4
END IF
--#LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR

DECLARE q_rept024 CURSOR FOR 
	SELECT rept024.*, rept010.r10_peso FROM rept024, rept010
		WHERE r24_compania  = vg_codcia
		  AND r24_localidad = vg_codloc
		  AND r24_numprev   = rm_r23.r23_numprev
		  AND r24_compania  = r10_compania
		  AND r24_item      = r10_codigo
		ORDER BY r24_orden

LET vm_tot_peso = 0

LET i = 1
FOREACH q_rept024 INTO r_r24.*, peso

	LET r_detalle[i].r24_proformado   = r_r24.r24_proformado 
	LET r_detalle[i].r24_cant_ped     = r_r24.r24_cant_ped 
	LET r_detalle[i].r24_cant_ven     = r_r24.r24_cant_ven 
	LET r_detalle[i].r24_bodega       = r_r24.r24_bodega 
	LET r_detalle[i].r24_item         = r_r24.r24_item 
	LET r_detalle_1[i].r24_linea      = r_r24.r24_linea 
	LET r_detalle[i].r24_descuento    = r_r24.r24_descuento 
	LET r_detalle[i].r24_precio       = r_r24.r24_precio 
	LET r_detalle_1[i].r24_val_descto = r_r24.r24_val_descto 
	LET r_detalle_1[i].r24_val_impto  = r_r24.r24_val_impto 
	LET r_detalle[i].subtotal_item    = r_r24.r24_precio *
					    r_r24.r24_cant_ven 
		
	LET vm_tot_peso = vm_tot_peso + r_r24.r24_cant_ven * peso 
		
	LET i = i + 1
        IF i > vm_elementos THEN
		EXIT FOREACH
	END IF	

END FOREACH 

LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET i = 0
	CLEAR FORM
	CALL control_display_botones()
	RETURN
END IF
LET vm_ind_arr = i
LET vm_curr_arr = 0
LET vm_ini_arr  = 0

LET vm_flag_proforma = 'N'
FOR i = 1 TO vm_ind_arr
	IF r_detalle[i].r24_proformado = 'S' THEN
		LET vm_flag_proforma = 'S'
		EXIT FOR
	END IF
END FOR 

CALL control_mostrar_sig_det()

END FUNCTION



FUNCTION muestra_contadores()

IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67
END IF

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

CASE rm_r23.r23_estado 
	WHEN 'A'
		DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'P'
		DISPLAY 'APROBADO' TO tit_estado
	WHEN 'N'
		DISPLAY 'NO APROBADO' TO tit_estado
	WHEN 'F'
		DISPLAY 'FACTURADO' TO tit_estado
END CASE
CALL fl_lee_grupo_linea(vg_codcia,  rm_r23.r23_grupo_linea)
	RETURNING rm_g20.*
	DISPLAY rm_g20.g20_nombre TO nom_grupo
CALL fl_lee_moneda(rm_r23.r23_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda
CALL fl_lee_bodega_rep(vg_codcia, rm_r23.r23_bodega)
	RETURNING rm_r02.*
	DISPLAY rm_r02.r02_nombre TO nom_bodega
CALL fl_lee_vendedor_rep(vg_codcia, rm_r23.r23_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION deleteRow(i, num_rows)
                                                                                
DEFINE i                SMALLINT
DEFINE num_rows         SMALLINT
                                                                                
WHILE (i < num_rows)
        LET r_detalle_1[i].* = r_detalle_1[i + 1].*
        LET i = i + 1
END WHILE
INITIALIZE r_detalle_1[i].* TO NULL
                                                                                
END FUNCTION
                                                                                


-- Funcion que añade N filas en un arreglo 
-- curr_row posicion aactual en el arreglo
-- num_rows numero actual de filas en el arreglo
-- added_rows numero de filas que se van a aumentar
FUNCTION addRows(curr_row, num_rows, added_rows)
DEFINE i                SMALLINT
DEFINE curr_row         SMALLINT
DEFINE num_rows         SMALLINT
DEFINE added_rows       SMALLINT

FOR i = num_rows TO curr_row STEP -1
	LET r_detalle_1[i + added_rows].* = r_detalle_1[i].* 	
	CALL llena_arreglo_detalle(i, (i + added_rows))
END FOR

END FUNCTION



-- Funcion que llena los datos que pueden variar del arreglo r_detalle_1
-- ant_pos indice que hace referencia a la posicion anterior de la fila
--	se usa para hacer referencia al item en el arreglo r_detalle
-- new_pos nueva posicion de la fila
FUNCTION llena_arreglo_detalle(ant_pos, new_pos)

DEFINE ant_pos      	SMALLINT
DEFINE new_pos      	SMALLINT
DEFINE bruto		DECIMAL(12,2)

DEFINE r_r10		RECORD LIKE rept010.*

CALL fl_lee_item(vg_codcia, r_detalle[ant_pos].r24_item) RETURNING r_r10.* 

LET r_detalle_1[new_pos].r24_linea       = r_r10.r10_linea
LET r_detalle_1[new_pos].rotacion        = r_r10.r10_rotacion

IF rg_gen.g00_moneda_base = rm_r21.r21_moneda THEN
	LET r_detalle_1[new_pos].costo_item = r_r10.r10_costo_mb
ELSE
	LET r_detalle_1[new_pos].costo_item = r_r10.r10_costo_ma
END IF

LET r_detalle_1[new_pos].r24_val_descto = r_detalle[ant_pos].r24_cant_ven *
					  r_detalle[ant_pos].r24_precio *
				          r_detalle[ant_pos].r24_descuento / 100

LET r_detalle_1[new_pos].val_costo      = r_detalle_1[new_pos].costo_item * 
				          r_detalle[ant_pos].r24_cant_ven
	
LET bruto = r_detalle[ant_pos].r24_cant_ven * r_detalle[ant_pos].r24_precio - 
	    r_detalle_1[new_pos].r24_val_descto

LET r_detalle_1[new_pos].r24_val_impto = (bruto * rm_r23.r23_porc_impto) / 100

END FUNCTION



FUNCTION no_validar_parametros()
DEFINE mensaje		VARCHAR(100)

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	LET mensaje = 'No existe módulo: ' || vg_modulo
	--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	LET mensaje = 'No existe compañía: '|| vg_codcia
	--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	LET mensaje = 'Compañía no está activa: ' || vg_codcia
	--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	LET mensaje = 'No existe localidad: ' || vg_codloc
	--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	LET mensaje = 'Localidad no está activa: '|| vg_codloc
	--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	--CALL fgl_winmessage(vg_producto,'Combinación compañía/localidad no existe.', 'stop')
	CALL fl_mostrar_mensaje('Combinación compañía/localidad no existe.', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION

                                                                                
                                                                                
FUNCTION llamar_proforma()
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, rm_r23.r23_numprof)
	RETURNING r_r21.*
LET param  = ' ', vg_codloc, ' ', r_r21.r21_numprof
LET modulo = 'REPUESTOS'
LET mod    = vg_modulo
LET prog   = 'repp220 '
IF r_r21.r21_num_ot IS NOT NULL THEN
	LET modulo = 'TALLER'
	LET mod    = 'TA'
	LET prog   = 'talp213 '
END IF
CALL ejecuta_comando(modulo, mod, prog, param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION control_ver_detalle() 
DEFINE i, j 		SMALLINT      
DEFINE r_r10		RECORD LIKE rept010.*

CALL set_count(vm_ind_arr)  
DISPLAY ARRAY r_detalle TO r_detalle.* 
        ON KEY(INTERRUPT)   
		CLEAR nom_item 
                EXIT DISPLAY  
        ON KEY(F1,CONTROL-W) 
		CALL control_visor_teclas_caracter_4() 
	ON KEY(F5)
		CALL llamar_proforma()
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL fl_lee_item(vg_codcia,r_detalle[i].r24_item) 
			RETURNING r_r10.*  
		DISPLAY r_r10.r10_nombre TO nom_item 
		{--
		CALL muestra_descripciones(r_detalle[i].r24_item,
			r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, 
			r_r10.r10_cod_clase)
		--}
        --#BEFORE DISPLAY 
                --#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F5","Proforma") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL fl_lee_item(vg_codcia,r_detalle[i].r24_item) 
			--#RETURNING r_r10.*  
		--#DISPLAY r_r10.r10_nombre TO nom_item 
		--CALL muestra_descripciones(r_detalle[i].r24_item,
			--r_r10.r10_linea, r_r10.r10_sub_linea,
			--r_r10.r10_cod_grupo, 
			--r_r10.r10_cod_clase)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY 

END FUNCTION 


{--
FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r03.r03_nombre     TO descrip_1
DISPLAY r_r70.r70_desc_sub   TO descrip_2
DISPLAY r_r71.r71_desc_grupo TO descrip_3
DISPLAY r_r72.r72_desc_clase TO descrip_4
DISPLAY r_r10.r10_marca      TO nom_marca

END FUNCTION
--}
                                                                                
                                                                                
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
DISPLAY '<F5>      Crear Cliente'        AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Otros Datos'          AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F8>      % Defaults' AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Crear Cliente'        AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_4() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Proforma'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION muestra_contcred(contcred)
DEFINE contcred		CHAR(1)

CASE contcred
	WHEN 'C'
		DISPLAY 'CONTADO' TO tit_cont_cred
	WHEN 'R'
		DISPLAY 'CREDITO' TO tit_cont_cred
	OTHERWISE
		CLEAR r23_cont_cred, tit_cont_cred
END CASE

END FUNCTION
