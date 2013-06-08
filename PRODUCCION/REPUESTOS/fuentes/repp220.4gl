--------------------------------------------------------------------------------
-- Titulo           : repp220.4gl - Mantenimiento de Proforma
-- Elaboracion      : 06-Dic-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp220 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE r_detalle	ARRAY[100] OF RECORD                        
				r22_bodega	LIKE rept022.r22_bodega,     
				r22_item	LIKE rept022.r22_item,       
				stock_tot	DECIMAL(8,2),
				stock_loc	DECIMAL(8,2),
				r22_cantidad	LIKE rept022.r22_cantidad,   
				r22_porc_descto	LIKE rept022.r22_porc_descto,
				r22_precio	LIKE rept022.r22_precio,     
				subtotal_item	LIKE rept021.r21_tot_neto    
			END RECORD                         
DEFINE rm_r00		RECORD LIKE rept000.*
DEFINE rm_r21		RECORD LIKE rept021.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_vend		RECORD LIKE rept001.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_r03		RECORD LIKE rept003.*
DEFINE rm_r04		RECORD LIKE rept004.* 
DEFINE rm_r10		RECORD LIKE rept010.*
DEFINE rm_r11		RECORD LIKE rept011.*
DEFINE rm_r22		RECORD LIKE rept022.*
DEFINE rm_g14		RECORD LIKE gent014.*
DEFINE rm_g20		RECORD LIKE gent020.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_c02		RECORD LIKE cxct002.*
DEFINE rm_r23		RECORD LIKE rept023.*
DEFINE rm_r24		RECORD LIKE rept024.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_g04		RECORD LIKE gent004.*

DEFINE vm_rows 		ARRAY[4000] OF INTEGER 	-- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO           
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS             
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER
DEFINE vm_max_det	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER DETALLE
DEFINE vm_num_detalles	SMALLINT	-- NUMERO DE ELEMENTOS DEL DETALLE      
DEFINE vm_flag_margen 	CHAR(1)
DEFINE vm_ini_arr       SMALLINT        -- Indica la posicion inicial desde     
                                        -- que se empezo a mostrar la ultima vez
DEFINE vm_curr_arr      SMALLINT        -- Indica la posición actual en el      
                                        -- detalle (ultimo elemento mostrado)   
DEFINE vm_scr_lin       SMALLINT	-- Lineas en pantalla                   
DEFINE vm_numprof		LIKE rept021.r21_numprof
DEFINE vm_flag_calculo_impto    CHAR(1)
DEFINE vm_bod_sstock		LIKE rept002.r02_codigo
DEFINE vm_size_arr		SMALLINT
DEFINE vm_flag_mant 		CHAR(1)
DEFINE vm_flag_vendedor		CHAR(1)
DEFINE vm_ind_arr		SMALLINT

DEFINE vm_total			DECIMAL(12,2)
DEFINE vm_costo			DECIMAL(12,2)
DEFINE vm_subtotal		DECIMAL(12,2)
DEFINE vm_descuento		DECIMAL(12,2)
DEFINE vm_impuesto		DECIMAL(12,2)

DEFINE i_loc, i_rem		SMALLINT
DEFINE r_loc 		   	ARRAY[50] OF RECORD
					bod_loc		CHAR(2), 
					nom_bod_loc	CHAR(30),
					stock_loc	DECIMAL (8,2)
				END RECORD 
DEFINE r_rem			ARRAY[50] OF RECORD      	
					bod_rem		CHAR(2), 	
					nom_bod_rem	CHAR(30),	
					stock_rem	DECIMAL (8,2) 	
				END RECORD                      	
DEFINE rm_orden 		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1		SMALLINT
DEFINE vm_columna_2		SMALLINT



MAIN

DEFER QUIT                                                                      
DEFER INTERRUPT                                                                 
CLEAR SCREEN                                                                    
CALL startlog('../logs/repp220.err')
--#CALL fgl_init4js()                                                           
CALL fl_marca_registrada_producto()                                             
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')      
	EXIT PROGRAM                                                            
END IF                                                                          
LET vg_base    = arg_val(1)                                                    
LET vg_modulo  = arg_val(2)                                                    
LET vg_codcia  = arg_val(3)                                                    
LET vg_codloc  = arg_val(4)                                                    
LET vm_numprof = arg_val(5)                                                    
LET vg_proceso = 'repp220'                                                      
CALL fl_activar_base_datos(vg_base)                                             
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)                        
CALL fl_validar_parametros()                                                    
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)          
CALL funcion_master_proformas()

END MAIN



FUNCTION funcion_master_proformas()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()                                     
IF num_args() = 4 OR num_args() = 6 THEN
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
END IF
CREATE TEMP TABLE temp_loc(
		bod_loc		CHAR(2), 
		nom_bod_loc	CHAR(30),
		stock_loc	DECIMAL(8,2)
	)
CREATE TEMP TABLE temp_rem(
		bod_rem		CHAR(2), 
		nom_bod_rem	CHAR(30),
		stock_rem	DECIMAL(8,2)
	)
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*
IF rm_r00.r00_compania IS NULL THEN                                             
	CALL fl_mostrar_mensaje('No está creada una compañía para el módulo de inventarios.','stop')
	RETURN                                                                  
END IF                                                                          
IF rm_r00.r00_estado <> 'A' THEN                                                
	CALL fl_mostrar_mensaje('La compañía está con status BLOQUEADO.','stop')
	RETURN                                                                  
END IF                                                                       
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
LET vm_flag_calculo_impto = 'B'
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_vd 
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
IF status = NOTFOUND THEN
	IF rm_g05.g05_tipo = 'UF' THEN
		CALL fl_mostrar_mensaje('Usted no está configurado en la tabla de vendedores/bodegueros.','stop')
		RETURN                                                                  
	END IF  
END IF		
LET vm_flag_vendedor = 'N'    -- NO CAMBIA PRECIOS
IF rm_vend.r01_mod_descto IS NOT NULL THEN
	LET vm_flag_vendedor = rm_vend.r01_mod_descto
END IF
LET vm_max_rows = 4000
LET vm_max_det  = 100
IF num_args() = 6 THEN
	CALL ejecutar_proforma_preventa_automatica()
	EXIT PROGRAM
END IF
LET lin_menu = 0          
LET row_ini  = 3          
LET num_rows = 22         
LET num_cols = 80         
IF vg_gui = 0 THEN        
	LET lin_menu = 1                                                        
	LET row_ini  = 2
	LET num_rows = 22 
	LET num_cols = 78 
END IF                  
OPEN WINDOW w_220 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS            
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN                                                              
	OPEN FORM f_220 FROM '../forms/repf220_1'                               
ELSE                                                                           
	OPEN FORM f_220 FROM '../forms/repf220_1c'                              
END IF                                                                          
DISPLAY FORM f_220                                                              
CALL control_DISPLAY_botones()                                                  
CALL retorna_tam_arr()        
LET vm_num_rows    = 0           
LET vm_row_current = 0        
INITIALIZE rm_r21.*, vm_bod_sstock TO NULL                                      
SELECT r02_codigo
	INTO vm_bod_sstock
	FROM rept002
	WHERE r02_compania  = vg_codcia                                 
	  AND r02_localidad = vg_codloc
	  AND r02_estado    = "A"                                      
	  AND r02_tipo      = "S"                                       
IF vm_bod_sstock IS NULL THEN
	CALL fl_mostrar_mensaje('No hay bodega sin stock configurada.','stop') 
	EXIT PROGRAM
END IF
CALL muestra_contadores()
MENU 'OPCIONES'                                                                 
	BEFORE MENU                                                             
		HIDE OPTION 'Avanzar'                                           
		HIDE OPTION 'Retroceder'                                        
		HIDE OPTION 'Modificar'                                        
		HIDE OPTION 'Ver Detalle'                                       
		HIDE OPTION 'Hacer Preventa'                                    
		HIDE OPTION 'Imprimir'
		--#HIDE OPTION 'Enviar Mail'
		--#HIDE OPTION 'PDF'
		IF num_args() = 5 THEN                                          
			HIDE OPTION 'Modificar'                                 
			HIDE OPTION 'Ingresar'                                  
			HIDE OPTION 'Consultar'                                 
			SHOW OPTION 'Imprimir'                                  
			--#SHOW OPTION 'Enviar Mail'
			--#IF vg_usuario <> 'HSALAZAR' THEN
				--#SHOW OPTION 'PDF'
			--#ELSE
				--#HIDE OPTION 'PDF'
			--#END IF
			SHOW OPTION 'Ver Detalle'
			CALL control_consulta()                                 
			CALL control_ver_detalle()
			EXIT MENU
		END IF                                                          
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'    
                CALL control_ingreso()                                          
		IF vm_num_rows >= 1 THEN                                        
			SHOW OPTION 'Modificar'                                
			SHOW OPTION 'Ver Detalle'                               
			SHOW OPTION 'Hacer Preventa'                            
			SHOW OPTION 'Imprimir'                                  
			--#SHOW OPTION 'Enviar Mail'
			--#IF vg_usuario <> 'HSALAZAR' THEN
				--#SHOW OPTION 'PDF'
			--#ELSE
				--#HIDE OPTION 'PDF'
			--#END IF
		END IF                                                          
                IF vm_row_current > 1 THEN                                      
                        SHOW OPTION 'Retroceder'                              
                END IF                                                          
                IF vm_row_current = vm_num_rows THEN                            
                        HIDE OPTION 'Avanzar'                                   
                END IF                                                          
	COMMAND KEY('M') 'Modificar' 		'Modificar un registro.'       
		IF vm_num_rows > 0 THEN                                        
			CALL control_modificacion()                             
		ELSE                                                            
			CALL fl_mensaje_consultar_primero()                     
		END IF	                                                        
	COMMAND KEY('H') 'Hacer Preventa'   'Convertir la proforma en preventa.'
		IF vm_num_rows > 0 THEN                                         
			CALL control_hacer_preventa()                           
		ELSE                                                            
			CALL fl_mensaje_consultar_primero()                     
		END IF	                                                        
        COMMAND KEY('C') 'Consultar'            'Consultar un registro.'        
                CALL control_consulta()                                         
                IF vm_num_rows <= 1 THEN 
                        SHOW OPTION 'Modificar'
                        SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Imprimir'   
			--#SHOW OPTION 'Enviar Mail'
			--#IF vg_usuario <> 'HSALAZAR' THEN
				--#SHOW OPTION 'PDF'
			--#ELSE
				--#HIDE OPTION 'PDF'
			--#END IF
                        HIDE OPTION 'Avanzar'   
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Imprimir'
				--#HIDE OPTION 'Enviar Mail'
				--#IF vg_usuario <> 'HSALAZAR' THEN
					--#SHOW OPTION 'PDF'
				--#ELSE
					--#HIDE OPTION 'PDF'
				--#END IF
                        	HIDE OPTION 'Modificar'
				HIDE OPTION 'Ver Detalle'
				HIDE OPTION 'Hacer Preventa'
                        END IF 
                ELSE          
			SHOW OPTION 'Imprimir'   
			--#SHOW OPTION 'Enviar Mail'
			--#IF vg_usuario <> 'HSALAZAR' THEN
				--#SHOW OPTION 'PDF'
			--#ELSE
				--#HIDE OPTION 'PDF'
			--#END IF
			SHOW OPTION 'Hacer Preventa' 
                        SHOW OPTION 'Ver Detalle'   
                        SHOW OPTION 'Modificar'    
                        SHOW OPTION 'Avanzar'     
                END IF                           
                IF vm_row_current <= 1 THEN     
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('K') 'Imprimir'
		IF rm_r21.r21_numprof IS NOT NULL THEN 
			CALL control_imprimir_proforma(1)
		END IF
	--#COMMAND KEY('X') 'Enviar Mail' 'Enviar proforma por Correo Electronico.'
	{--
		IF rm_r21.r21_numprof IS NOT NULL THEN 
			CALL control_correo_electronico()
		END IF
	--}
		CALL enviar_mail()
	--#COMMAND KEY('Y') 'PDF' 'Genera un archivo .pdf de la proforma.'
		CALL generar_pdf()
        COMMAND KEY('V') 'Ver Detalle'   'Muestra anteriores detalles.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()  
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Modificar'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'  
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF 
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'  
			SHOW OPTION 'Modificar'   
			HIDE OPTION 'Retroceder' 
			SHOW OPTION 'Avanzar'   
			NEXT OPTION 'Avanzar'  
		ELSE 
			SHOW OPTION 'Hacer Preventa'
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Modificar' 
			SHOW OPTION 'Avanzar'  
			SHOW OPTION 'Retroceder'
		END IF                                                                       
	COMMAND KEY('S') 'Salir'    		'Salir del programa.'
		EXIT MENU
END MENU
DROP TABLE temp_loc
DROP TABLE temp_rem

END FUNCTION



FUNCTION ejecutar_proforma_preventa_automatica()
DEFINE done 		SMALLINT
DEFINE mensaje		VARCHAR(100)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r88		RECORD LIKE rept088.*

CALL fl_control_status_caja(vg_codcia, vg_codloc, 'P') RETURNING int_flag
IF int_flag <> 0 THEN
	LET int_flag = 0
	RETURN
END IF	
CALL retorna_tam_arr()        
LET vm_num_rows    = 0           
LET vm_row_current = 0        
INITIALIZE rm_r21.*, vm_bod_sstock TO NULL                                      
SELECT r02_codigo INTO vm_bod_sstock FROM rept002                               
		WHERE r02_compania  = vg_codcia                                 
		  AND r02_localidad = vg_codloc
		  AND r02_estado    = "A"                                      
		  AND r02_tipo      = "S"                                       
IF vm_bod_sstock IS NULL THEN
	CALL fl_mostrar_mensaje('No hay bodega sin stock configurada.','stop') 
	EXIT PROGRAM
END IF
CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, vm_numprof) RETURNING rm_r21.*
IF rm_r21.r21_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Proforma no existe.', 'stop')
	EXIT PROGRAM
END IF
INITIALIZE r_r88.* TO NULL
DECLARE q_r88 CURSOR FOR
	SELECT * FROM rept088
		WHERE r88_compania  = vg_codcia
		  AND r88_localidad = vg_codloc
		  AND r88_numprof   = rm_r21.r21_numprof
OPEN q_r88
FETCH q_r88 INTO r_r88.*
CLOSE q_r88
FREE q_r88
IF r_r88.r88_numprof_nue IS NOT NULL AND r_r88.r88_numprev_nue IS NULL THEN
	CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, r_r88.r88_numprof_nue)
		RETURNING rm_r21.*
	LET vm_ind_arr     = 0
	LET vm_flag_mant   = 'I'
	LET vm_flag_margen = 'N'
	LET vm_total       = rm_r21.r21_tot_neto
	CALL muestra_detalle()
	CALL calcula_totales(vm_ind_arr, 1)
	CALL control_hacer_preventa()
	EXIT PROGRAM
END IF
IF r_r88.r88_codcli_nue IS NOT NULL THEN
	CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,r_r88.r88_codcli_nue)
		RETURNING rm_c02.*
	IF rm_c02.z02_codcli IS NULL THEN	
		CALL fl_mostrar_mensaje('Cliente no esta activado para esta localidad.', 'stop')
		EXIT PROGRAM
	END IF
	LET rm_r21.r21_codcli = r_r88.r88_codcli_nue
	LET rm_r21.r21_nomcli = r_r88.r88_nomcli_nue
	CALL fl_lee_cliente_general(rm_r21.r21_codcli) RETURNING r_z01.*
	IF r_z01.z01_estado <> 'A' THEN
		CALL fl_mostrar_mensaje('Cliente esta con estado bloqueado.','stop')          
		EXIT PROGRAM
	END IF
	LET rm_r21.r21_dircli = r_z01.z01_direccion1
	LET rm_r21.r21_telcli = r_z01.z01_telefono1
	LET rm_r21.r21_cedruc = r_z01.z01_num_doc_id
END IF
LET vm_ind_arr     = 0
LET vm_flag_mant   = 'I'
LET vm_flag_margen = 'N'
LET vm_total       = rm_r21.r21_tot_neto
CALL muestra_detalle()
CALL calcula_totales(vm_ind_arr, 1)
CALL fl_lee_cabecera_transaccion_rep(r_r88.r88_compania, r_r88.r88_localidad,
					r_r88.r88_cod_dev, r_r88.r88_num_dev)
	RETURNING r_r19.*
LET rm_r21.r21_referencia = r_r19.r19_referencia CLIPPED
LET rm_r21.r21_cod_tran   = NULL
LET rm_r21.r21_num_tran   = NULL
LET rm_r21.r21_fecing     = CURRENT 
BEGIN WORK                       
LET done = control_cabecera()   
IF done = 0 THEN               
	ROLLBACK WORK         
	CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso de la cabecera.', 'stop')
	EXIT PROGRAM
END IF          
LET done = control_ingreso_detalle() 
IF done = 0 THEN                    
	ROLLBACK WORK              
	CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso del detalle.', 'stop')
	EXIT PROGRAM
END IF
UPDATE rept088 SET r88_numprof_nue = rm_r21.r21_numprof
	WHERE r88_compania  = vg_codcia
	  AND r88_localidad = vg_codloc
	  AND r88_numprof   = vm_numprof
IF STATUS < 0 THEN
	ROLLBACK WORK              
	CALL fl_mostrar_mensaje('Ha ocurrido un error al Actualizar la Proforma Nueva en la tabla rept088.', 'stop')
	EXIT PROGRAM
END IF
COMMIT WORK  
--CALL control_imprimir_proforma(1) 
LET mensaje = 'Proforma Generada: ', rm_r21.r21_numprof USING "<<<<<<&", ' Ok.'
--CALL fl_mostrar_mensaje(mensaje, 'info')
CALL control_hacer_preventa()                           

END FUNCTION



FUNCTION control_ingreso()
DEFINE i 		SMALLINT
DEFINE intentar 	SMALLINT
DEFINE done 		SMALLINT

LET vm_ind_arr = 0
CLEAR FORM
CALL control_DISPLAY_botones()
LET vm_flag_mant = 'I'
LET vm_flag_margen = 'N'
INITIALIZE rm_r01.*, rm_r03.*, rm_r04.*, rm_r10.*, rm_r11.* TO NULL
INITIALIZE rm_r03.*, rm_r04.*, rm_r10.*, rm_r11.*, rm_g13.* TO NULL
INITIALIZE rm_g14.*, rm_g20.*, rm_z01.*, rm_c02.* TO NULL
INITIALIZE rm_r21.*, rm_r22.* TO NULL
LET rm_r21.r21_fecing     = CURRENT 
LET rm_r21.r21_usuario    = vg_usuario
LET rm_r21.r21_compania   = vg_codcia
LET rm_r21.r21_localidad  = vg_codloc
LET rm_r21.r21_dias_prof  = rm_r00.r00_dias_prof  
LET rm_r21.r21_moneda     = rg_gen.g00_moneda_base
LET rm_r21.r21_porc_impto = rg_gen.g00_porc_impto
LET rm_r21.r21_descuento  =  0.0 
LET rm_r21.r21_flete      =  0 
LET rm_r21.r21_factor_fob = 1   
LET rm_r21.r21_modelo     = '.' 
LET rm_r21.r21_vendedor   = rm_vend.r01_codigo
CALL fl_lee_moneda(rg_gen.g00_moneda_base) 	     -- PARA OBTENER EL NOMBRE
	RETURNING rm_g13.*		   	     -- DE LA MONEDA BASE    
LET rm_r21.r21_precision = rm_g13.g13_decimales  
DECLARE qu_gl CURSOR FOR SELECT g20_grupo_linea FROM gent020
	WHERE g20_compania = vg_codcia
OPEN qu_gl 
FETCH qu_gl INTO rm_r21.r21_grupo_linea 
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay grupo de línea configurado.','exclamation') 
	IF vm_num_rows = 0 THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
--LET rm_r21.r21_bodega     = rm_r00.r00_bodega_fact 
LET rm_r21.r21_bodega     = retorna_bodega_localidad(vg_codcia, vg_codloc)

DISPLAY BY NAME rm_r21.r21_fecing, rm_r21.r21_moneda, rm_r21.r21_porc_impto,
		rm_r21.r21_dias_prof
DISPLAY rm_g13.g13_nombre TO nom_moneda
DISPLAY rm_vend.r01_nombres TO nom_vendedor
CALL lee_cabecera()  
IF int_flag THEN    
	IF vm_num_rows = 0 THEN 
		CLEAR FORM
		CALL control_DISPLAY_botones()
	ELSE	                     
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF                                     
	RETURN                             
END IF                            
LET vm_total = 0                                                 
LET rm_r21.r21_tot_neto  = vm_total                                         
LET vm_num_detalles = lee_detalle()                                          
IF int_flag THEN                                                            
	IF vm_num_rows = 0 THEN                                              
		CLEAR FORM                                                    
		CALL control_DISPLAY_botones()                                
	ELSE	                                                                
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF                                                          
	RETURN                   
END IF                          
LET rm_r21.r21_fecing   = CURRENT
LET rm_r21.r21_tot_neto = vm_total
BEGIN WORK                       
LET done = control_cabecera()   
IF done = 0 THEN               
	ROLLBACK WORK         
	CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso de la cabecera.', 'stop')
	IF vm_num_rows <= 1 THEN
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CLEAR FORM           
		CALL control_DISPLAY_botones()
	ELSE                      
		LET vm_num_rows = vm_num_rows - 1 
		LET vm_row_current = vm_num_rows 
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF    
	RETURN   
END IF          
LET done = control_ingreso_detalle() 
IF done = 0 THEN                    
	ROLLBACK WORK              
	CALL fl_mostrar_mensaje('Ha ocurrido un error en el ingreso del detalle.', 'stop')
	IF vm_num_rows <= 1 THEN  
		LET vm_num_rows = 0
		LET vm_row_current = 0
		CLEAR FORM          
		CALL control_DISPLAY_botones()
	ELSE                                
		LET vm_num_rows = vm_num_rows - 1
		LET vm_row_current = vm_num_rows
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF  
	RETURN 
END IF        
COMMIT WORK  
CALL muestra_contadores()
CALL control_imprimir_proforma(1) 
CALL fl_mensaje_registro_ingresado()

END FUNCTION                                                                               


FUNCTION control_modificacion()
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE cliente 		LIKE rept021.r21_codcli
DEFINE done		SMALLINT
DEFINE cambio_precios	SMALLINT
DEFINE flag_bloqueo	SMALLINT

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r21.r21_cod_tran IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Esta proforma ya fue facturada, no puede ser modificada.','exclamation')             	
	RETURN
END IF 
IF rm_r21.r21_num_ot IS NOT NULL OR rm_r21.r21_num_presup IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Esta proforma es de talleres.','exclamation')
	RETURN
END IF 
IF DATE(rm_r21.r21_fecing) + rm_r00.r00_expi_prof < TODAY THEN   
	CALL fl_mostrar_mensaje('El tiempo de vida de la proforma ya ' ||
				'expiró, por lo tanto no puede ser ' ||
				'modificada.',
				'exclamation')
	RETURN 
END IF   
LET cambio_precios = retorna_precio_validez_item()
IF cambio_precios THEN
	CALL fl_mostrar_mensaje('Debido a que el tiempo de validez de ' ||
				'precios de la proforma ya expiró, los ' ||
				'precios han sido reactualizados.',
				'info')
END IF   

LET vm_flag_mant   = 'M'
BEGIN WORK  
WHENEVER ERROR CONTINUE
DECLARE q_up2 CURSOR FOR
	SELECT * FROM rept021 
		WHERE r21_compania  = vg_codcia
		AND   r21_localidad = vg_codloc
		AND   r21_numprof   = rm_r21.r21_numprof
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
LET rm_r21.r21_dias_prof = rm_r00.r00_dias_prof
CALL lee_cabecera()    
IF int_flag THEN    
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN 
END IF   
LET vm_num_detalles = lee_detalle() 
IF int_flag THEN   
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN   
ELSE    
	LET rm_r21.r21_fecing = CURRENT
	DISPLAY BY NAME rm_r21.r21_fecing
	WHENEVER ERROR CONTINUE
	UPDATE rept021
		SET * = rm_r21.* 
		WHERE CURRENT OF q_up2
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Ha ocurrido un ERROR al intentar actualizar los datos de la proforma. Llame al ADMINISTRADOR.', 'exclamation')
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	DELETE FROM rept022 
		WHERE r22_compania  = vg_codcia
		AND   r22_localidad = vg_codloc
		AND   r22_numprof   = rm_r21.r21_numprof 
	LET done = control_ingreso_detalle() 
	IF done = 0 THEN            
		ROLLBACK WORK      
		CALL fl_mostrar_mensaje('Ha ocurrido un error al intentar actualizar el detalle de la proforma. No se realizará el proceso.','exclamation')    
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		RETURN                   
	END IF       
	CALL retorna_preventa() RETURNING r_r23.r23_numprev
	IF r_r23.r23_numprev IS NOT NULL THEN
		CALL fl_mostrar_mensaje('Por Favor vuelva a Convertir en Pre-Venta esta Proforma.', 'info')
	END IF
	LET flag_bloqueo = 0
	CALL eliminar_preventa_anterior() RETURNING flag_bloqueo
	IF flag_bloqueo THEN
		RETURN
	END IF
	CLEAR r23_numprev
	COMMIT WORK 
	CALL fl_mensaje_registro_modificado()  
END IF      

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE r_r21		RECORD LIKE rept021.* 	-- CABECERA PROFORMA
DEFINE r_r01		RECORD LIKE rept001.*

CLEAR FORM
CALL control_DISPLAY_botones()

LET INT_FLAG = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON r21_numprof,  r21_num_tran,  r21_moneda,   
		     r21_codcli,   r21_dias_prof, r21_nomcli, r21_cedruc,
		     r21_dircli,   r21_telcli,	  r21_atencion, r21_referencia,
		     r21_forma_pago, r21_vendedor
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r21_numprof) THEN
			CALL fl_ayuda_proformas_rep(vg_codcia, vg_codloc)
				RETURNING r_r21.r21_numprof, r_r21.r21_nomcli
			IF r_r21.r21_numprof IS NOT NULL THEN
				CALL fl_lee_proforma_rep(vg_codcia, vg_codloc,
							 r_r21.r21_numprof)
					RETURNING rm_r21.*
				DISPLAY BY NAME rm_r21.r21_numprof,
						rm_r21.r21_moneda,
						rm_r21.r21_codcli,
						rm_r21.r21_nomcli,
						rm_r21.r21_dircli,
						rm_r21.r21_cedruc,
						rm_r21.r21_vendedor,
						rm_r21.r21_porc_impto,
						rm_r21.r21_fecing
			END IF
		END IF
		IF INFIELD(r21_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
		      	IF rm_g13.g13_moneda IS NOT NULL THEN
		        	LET rm_r21.r21_moneda = rm_g13.g13_moneda
			    	DISPLAY BY NAME rm_r21.r21_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
		      	END IF
		END IF
		IF INFIELD(r21_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR 
			rm_vend.r01_tipo = 'J' OR
			rm_vend.r01_tipo = 'G') THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F')
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo	
				DISPLAY BY NAME rm_r21.r21_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_z01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r21.r21_codcli = rm_c02.z02_codcli
				LET rm_r21.r21_nomcli = rm_z01.z01_nomcli
				DISPLAY BY NAME rm_r21.r21_codcli,
						rm_r21.r21_nomcli
			END IF 
		END IF
		LET int_flag = 0
	AFTER FIELD r21_vendedor
		IF rm_g05.g05_tipo = 'UF' THEN
			IF (rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G')
			THEN
				DISPLAY rm_vend.r01_codigo  TO r21_vendedor
				DISPLAY rm_vend.r01_nombres TO nom_vendedor
			END IF
		END IF
		LET rm_r01.r01_codigo = GET_FLDBUF(r21_vendedor)
		IF rm_vend.r01_tipo = 'J' THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r01.r01_codigo)
				RETURNING rm_r01.*       
			IF rm_r01.r01_tipo = 'G' THEN
				DISPLAY rm_r01.r01_codigo  TO r21_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF rm_r01.r01_codigo IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r01.r01_codigo)
				RETURNING rm_r01.*
			DISPLAY rm_r01.r01_nombres TO nom_vendedor
			IF rm_vend.r01_tipo = 'J' THEN
				IF rm_r01.r01_tipo = 'G' THEN
					LET rm_r01.r01_codigo=rm_vend.r01_codigo
					DISPLAY rm_vend.r01_codigo  TO
						r21_vendedor
					DISPLAY rm_vend.r01_nombres TO
						nom_vendedor
				END IF
			END IF
		ELSE
			CLEAR nom_vendedor
		END IF                        
	BEFORE CONSTRUCT
		IF rm_g05.g05_tipo = 'UF' OR
		   (rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G') THEN
			DISPLAY rm_vend.r01_codigo TO r21_vendedor
			DISPLAY rm_vend.r01_nombres TO nom_vendedor
		END IF
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		CALL control_DISPLAY_botones()
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = 'r21_numprof = ', vm_numprof
END IF

{--
IF expr_sql_2 IS NOT NULL THEN
	LET expr_sql = expr_sql CLIPPED || ' AND ' || expr_sql_2 CLIPPED
END IF
--}

LET query = 'SELECT *, ROWID FROM rept021 ', 
		' WHERE r21_compania  = ', vg_codcia,
		'   AND r21_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3, 4' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r21.*, vm_rows[vm_num_rows]
	IF rm_vend.r01_tipo <> 'G' THEN
		CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
			RETURNING r_r01.*
		IF r_r01.r01_tipo = 'G' THEN
			IF rm_vend.r01_tipo = 'J' THEN
				CONTINUE FOREACH
			END IF
		END IF
	END IF
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
	LET vm_num_rows = 0
	LET vm_row_current = 0
	CALL muestra_contadores()
	CLEAR FORM
	CALL control_DISPLAY_botones()
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_cabecera()
DEFINE resp 		CHAR(6)
DEFINE cliente		LIKE rept021.r21_codcli
DEFINE r_g10		RECORD LIKE gent010.*
DEFINE done, resul	SMALLINT
DEFINE flag_error	SMALLINT

LET int_flag = 0
INPUT BY NAME   rm_r21.r21_codcli,     rm_r21.r21_nomcli,
		rm_r21.r21_dircli,     rm_r21.r21_cedruc,
		rm_r21.r21_telcli,     
		rm_r21.r21_atencion,   rm_r21.r21_referencia,
		rm_r21.r21_forma_pago, 
		rm_r21.r21_vendedor,   rm_r21.r21_flete
		WITHOUT DEFAULTS              
	ON KEY (INTERRUPT)          
		IF NOT FIELD_TOUCHED(r21_codcli, r21_nomcli, r21_telcli, r21_atencion, r21_referencia, r21_forma_pago, r21_cedruc,  r21_vendedor,   r21_dircli) THEN       
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
		IF INFIELD(r21_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR 
			rm_vend.r01_tipo = 'J' OR
			rm_vend.r01_tipo = 'G') THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F') 
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN                
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo
				DISPLAY BY NAME rm_r21.r21_vendedor 
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF  
		END IF      
		IF INFIELD(r21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_z01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN   
				LET rm_r21.r21_codcli = rm_c02.z02_codcli
				LET rm_r21.r21_nomcli = rm_z01.z01_nomcli
				DISPLAY BY NAME rm_r21.r21_codcli, 
						rm_r21.r21_nomcli 
			END IF   
		END IF    
		LET int_flag = 0  
	ON KEY(F5)
		CALL control_crear_cliente() 
		LET INT_FLAG = 0    
	ON KEY(F6)
		IF rm_r21.r21_codcli IS NULL THEN
			CONTINUE INPUT
		END IF
		CALL control_ver_ec_cliente()
		LET INT_FLAG = 0                            
	BEFORE INPUT            
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("F6","E/C Cliente")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r21_vendedor                      
		IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
			LET rm_r21.r21_vendedor = rm_vend.r01_codigo 
			DISPLAY BY NAME rm_r21.r21_vendedor	
		END IF
		IF rm_vend.r01_tipo = 'J' THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
				RETURNING rm_r01.*       
			IF rm_r01.r01_tipo = 'G' THEN
				LET rm_r21.r21_vendedor = rm_vend.r01_codigo 
				DISPLAY BY NAME rm_r21.r21_vendedor	
			END IF
		END IF
		IF rm_r21.r21_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
				RETURNING rm_r01.*       
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation') 
				CLEAR nom_vendedor
				NEXT FIELD r21_vendedor
			END IF                        
			IF rm_r01.r01_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Vendedor está bloqueado.','exclamation')      
				NEXT FIELD r21_vendedor
			END IF        
			DISPLAY rm_r01.r01_nombres TO nom_vendedor 
		ELSE              
			CLEAR nom_vendedor
		END IF
	AFTER FIELD r21_codcli, r21_nomcli, r21_dircli, r21_cedruc, r21_telcli 
		IF rm_r21.r21_codcli IS NOT NULL THEN    
			CALL fl_lee_cliente_general(rm_r21.r21_codcli) 
				RETURNING rm_z01.*  
			IF rm_z01.z01_codcli IS NULL THEN	
				CALL fl_mostrar_mensaje('No existe código de cliente.','exclamation')
				NEXT FIELD r21_codcli	
			END IF	
			LET rm_r21.r21_nomcli    = rm_z01.z01_nomcli 
			LET rm_r21.r21_dircli    = rm_z01.z01_direccion1
			IF rm_r21.r21_codcli <> rm_r00.r00_codcli_tal THEN    
				LET rm_r21.r21_cedruc = rm_z01.z01_num_doc_id
			END IF
			LET rm_r21.r21_telcli    = rm_z01.z01_telefono1
			DISPLAY BY NAME rm_r21.r21_nomcli, rm_r21.r21_dircli,
					rm_r21.r21_cedruc, rm_r21.r21_telcli
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, 
				rm_r21.r21_codcli) RETURNING rm_c02.*
			IF rm_c02.z02_codcli IS NULL THEN	
				CALL fl_mostrar_mensaje('Cliente no está activado para esta localidad.','exclamation')
				NEXT FIELD r21_codcli	
			END IF	
			IF rm_z01.z01_estado <> 'A' THEN
                              	CALL fl_mostrar_mensaje('Cliente está bloqueado.','exclamation')          
                        	NEXT FIELD r21_codcli
                        END IF  
			IF rm_z01.z01_paga_impto = 'N' THEN
				LET rm_r21.r21_porc_impto = 0
			ELSE
				LET rm_r21.r21_porc_impto =rg_gen.g00_porc_impto
                	END IF         
			DISPLAY BY NAME rm_r21.r21_porc_impto
		ELSE
			LET rm_z01.z01_paga_impto = 'S'
			LET rm_r21.r21_porc_impto = rg_gen.g00_porc_impto
			DISPLAY BY NAME rm_r21.r21_porc_impto
                END IF         
		IF (rm_r21.r21_cedruc IS NOT NULL AND 
			rm_r21.r21_codcli IS NULL) OR
		       (rm_r21.r21_codcli IS NOT NULL AND 
			rm_z01.z01_tipo_doc_id <> 'P') THEN    
			INITIALIZE r_g10.* TO NULL
			DECLARE q_g10 CURSOR FOR
				SELECT * FROM gent010
					WHERE g10_codcobr = rm_r21.r21_codcli
			OPEN q_g10
			FETCH q_g10 INTO r_g10.*
			CLOSE q_g10
			FREE q_g10
			IF r_g10.g10_codcobr IS NOT NULL THEN
				CALL fl_mostrar_mensaje('No se puede proformar a un código de tarjeta de crédito. Por favor utilice el código de cliente.', 'info')
				NEXT FIELD r21_codcli
			END IF
			CALL fl_validar_cedruc_dig_ver(rm_r21.r21_cedruc)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r21_cedruc
			END IF  
		END IF
		IF (rm_r21.r21_cedruc IS NOT NULL AND rm_r21.r21_codcli IS NULL)
		THEN
			IF rm_r21.r21_nomcli IS NOT NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_validar_cedruc_dig_ver(rm_r21.r21_cedruc)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r21_cedruc
			END IF  
			INITIALIZE rm_z01.* TO NULL
			DECLARE q_dat CURSOR FOR
				SELECT * FROM cxct001
					WHERE z01_num_doc_id = rm_r21.r21_cedruc
					  AND z01_estado     = 'A'
			OPEN q_dat
			FETCH q_dat INTO rm_z01.*
			CLOSE q_dat
			FREE q_dat
			LET rm_r21.r21_codcli    = rm_z01.z01_codcli
			LET rm_r21.r21_nomcli    = rm_z01.z01_nomcli 
			LET rm_r21.r21_dircli    = rm_z01.z01_direccion1
			IF rm_r21.r21_codcli <> rm_r00.r00_codcli_tal THEN    
				LET rm_r21.r21_cedruc = rm_z01.z01_num_doc_id
			END IF
			LET rm_r21.r21_telcli    = rm_z01.z01_telefono1
			IF rm_z01.z01_paga_impto = 'N' THEN
				LET rm_r21.r21_porc_impto = 0
			ELSE
				LET rm_r21.r21_porc_impto =rg_gen.g00_porc_impto
                	END IF         
			DISPLAY BY NAME rm_r21.r21_codcli, rm_r21.r21_nomcli,
					rm_r21.r21_dircli, rm_r21.r21_cedruc,
					rm_r21.r21_telcli, rm_r21.r21_porc_impto
			IF rm_z01.z01_estado <> 'A' THEN
                              	CALL fl_mostrar_mensaje('Cliente está bloqueado.','exclamation')          
                        	NEXT FIELD r21_codcli
                        END IF  
		END IF  
		IF rm_r21.r21_codcli IS NULL THEN
			LET rm_z01.z01_paga_impto = 'S'
			LET rm_r21.r21_porc_impto = rg_gen.g00_porc_impto
			DISPLAY BY NAME rm_r21.r21_porc_impto
               	END IF
	AFTER FIELD r21_flete
		CALL calcula_totales(vm_ind_arr,1)      
	AFTER INPUT
		IF NOT valida_cliente_consumidor_final(rm_r21.r21_codcli) THEN
			--NEXT FIELD r21_codcli
		END IF
		CALL control_saldos_vencidos(vg_codcia, rm_r21.r21_codcli, 1)
				RETURNING flag_error
		IF rm_z01.z01_paga_impto = 'N' THEN
			LET vm_flag_calculo_impto = 'I'
		END IF
{--
		IF flag_error THEN
			NEXT FIELD r21_codcli
		END IF
--}
END INPUT 
                                                                                                          
END FUNCTION


FUNCTION lee_detalle()
DEFINE i,j,k,ind, num	SMALLINT  
DEFINE resp		CHAR(6) 
DEFINE descuento	LIKE rept022.r22_porc_descto
DEFINE stock		LIKE rept022.r22_cantidad 
DEFINE valor_dec	LIKE rept022.r22_cantidad 
DEFINE item_anterior	LIKE rept010.r10_codigo  
DEFINE num_elm		SMALLINT       
DEFINE salir  		SMALLINT     
DEFINE in_array		SMALLINT   
DEFINE cant_prof	DECIMAL (8,2)   
DEFINE cod_bod		LIKE rept002.r02_codigo 
DEFINE name_bod		LIKE rept002.r02_nombre 
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*  
DEFINE r_r05		RECORD LIKE rept005.*  
DEFINE max_descto	DECIMAL(4,2)
DEFINE max_descto_c	DECIMAL(4,2)
DEFINE subtot_net	DECIMAL(14,2)
DEFINE precio_ant 	LIKE rept022.r22_precio
DEFINE max_row		SMALLINT
DEFINE resul		SMALLINT
DEFINE mensaje		VARCHAR(250)

INITIALIZE item_anterior TO NULL  
CALL retorna_tam_arr()     
LET i = 1          
LET j = 1        
LET salir    = 0 
LET in_array = 0
WHILE NOT salir
	LET int_flag = 0 
	IF vm_flag_mant <> 'M' THEN 
		IF NOT in_array THEN 
			INITIALIZE r_detalle[1].* TO NULL
		END IF      
		CALL set_count(i) 
	ELSE                   
		CALL set_count(vm_ind_arr)
	END IF           
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		ON KEY(INTERRUPT)
			LET INT_FLAG = 0    
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp      
			IF resp = 'Yes' THEN       
				LET int_flag = 1  
				EXIT WHILE       
			END IF                  
        	ON KEY(F1,CONTROL-W)           
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F2)          
			IF INFIELD(r22_bodega) THEN  
				CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', '2', 'R', 'S', 'V')
					RETURNING r_r02.r02_codigo, 
						  r_r02.r02_nombre
				IF r_r02.r02_codigo IS NOT NULL THEN
					LET r_detalle[i].r22_bodega = 
						r_r02.r02_codigo
					DISPLAY r_detalle[i].r22_bodega TO
						r_detalle[j].r22_bodega
				END IF
			END IF
			IF INFIELD(r22_item) THEN  
                		CALL fl_ayuda_maestro_items_stock(vg_codcia,                       	     rm_r21.r21_grupo_linea, r_detalle[i].r22_bodega)
                     		RETURNING rm_r10.r10_codigo, rm_r10.r10_nombre,
					  rm_r10.r10_linea,rm_r10.r10_precio_mb,
					  rm_r11.r11_bodega, stock         
                     	        IF rm_r10.r10_codigo IS NOT NULL THEN     
					LET r_detalle[i].r22_item = rm_r10.r10_codigo
					IF rm_r11.r11_bodega IS NOT NULL THEN
						LET r_detalle[i].r22_bodega = rm_r11.r11_bodega
					ELSE
     				        	IF r_detalle[i].r22_bodega IS NULL THEN
						
     				        		LET r_detalle[i].r22_bodega = vm_bod_sstock
						END IF
						
					END IF
     				        DISPLAY r_detalle[i].r22_bodega TO r_detalle[j].r22_bodega 
     				        DISPLAY r_detalle[i].r22_item TO r_detalle[j].r22_item 
                        	END IF			
			END IF 
                	LET INT_FLAG = 0                  
		ON KEY(F6)
			CALL control_crear_item()                     
			LET INT_FLAG = 0                             
		ON KEY(F7)                                         
			CALL control_ver_item(r_detalle[i].r22_item) 
			LET INT_FLAG = 0                            
		ON KEY(F8)
			IF r_detalle[i].r22_item IS NOT NULL THEN
				LET i = arr_curr()
				CALL muestra_stock_local_nacional(i, 
							r_detalle[i].r22_item,1)
				DISPLAY r_detalle[i].r22_bodega TO
					r_detalle[j].r22_bodega
				NEXT FIELD r22_bodega
			END IF  
		ON KEY(F9)
			LET subtot_net = rm_r21.r21_tot_bruto -
					 rm_r21.r21_tot_dscto
			ERROR 'El Subtotal - Descuento es : ', subtot_net
		BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			IF in_array THEN              
				--#CALL dialog.setcurrline(j, k)
				LET i = k      # POSICION CORRIENTE EN EL ARRAY
				LET in_array = 0     
				NEXT FIELD r22_item 
			END IF                     
		BEFORE ROW
			LET i = arr_curr()  # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()  # POSICION CORRIENTE EN LA PANTALLA
			LET max_row = arr_count()
			IF i > max_row THEN
				LET max_row = max_row + 1
			END IF
			LET item_anterior = r_detalle[i].r22_item  
			IF r_detalle[i].r22_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia,
							r_detalle[i].r22_item)
					RETURNING rm_r10.*
				CALL muestra_etiquetas_det(i, max_row, i)
			ELSE
				CLEAR nom_item, descrip_1, descrip_2, descrip_3,
					descrip_4, nom_marca
			END IF
			LET num = arr_count()
		AFTER DELETE	                                   
			LET k = i - j + 1                         
			CALL calcula_totales(arr_count(),k)      
			DISPLAY r_detalle[i].r22_cantidad TO    
				r_detalle[j].r22_cantidad      
			DISPLAY r_detalle[i].r22_porc_descto TO 
				r_detalle[j].r22_porc_descto   
			DISPLAY r_detalle[i].subtotal_item TO 
				r_detalle[j].subtotal_item   
		AFTER FIELD r22_bodega 
			IF r_detalle[i].r22_bodega IS NULL AND 
			   r_detalle[i].r22_item IS NOT NULL THEN
				--CALL fl_mostrar_mensaje('Digite bodega.','exclamation') 			
				--NEXT FIELD r22_bodega
                       		CALL retorna_stock_item(vg_codcia, r_detalle[i].r22_bodega, r_detalle[i].r22_item)
                       			RETURNING r_detalle[i].r22_bodega, 
                       			          r_detalle[i].stock_tot, 
                       				  r_detalle[i].stock_loc
				DISPLAY r_detalle[i].r22_bodega TO 
					        r_detalle[j].r22_bodega
				DISPLAY r_detalle[i].stock_tot TO 
					        r_detalle[j].stock_tot
				DISPLAY r_detalle[i].stock_loc TO 
					        r_detalle[j].stock_loc
			END IF	
			IF r_detalle[i].r22_bodega IS NOT NULL THEN
				IF NOT valida_bodega(vg_codcia, 
					   r_detalle[i].r22_bodega) THEN
					NEXT FIELD r22_bodega
				END IF
				IF r_detalle[i].r22_item IS NOT NULL AND
				   r_detalle[i].r22_cantidad IS NOT NULL THEN
					 IF r_detalle[i].r22_bodega <> vm_bod_sstock THEN
					 	CALL fl_lee_stock_rep(vg_codcia, 
						r_detalle[i].r22_bodega,
						r_detalle[i].r22_item)
				      		RETURNING r_r11.* 

						IF r_r11.r11_stock_act IS NULL THEN
							LET r_r11.r11_stock_act = 0
						END IF
						IF r_r11.r11_stock_act < r_detalle[i].r22_cantidad THEN 
							LET mensaje = 'El item: ', r_detalle[i].r22_item CLIPPED,
						      ' no tiene stock suficiente.'
							CALL fl_mostrar_mensaje(mensaje,'exclamation') 			
							NEXT FIELD r22_bodega
						END IF
					END IF	
				END IF
				{-- OJO POR IMPORTACIONES
				IF vg_codloc > 2 THEN
					CALL validar_item_importacion_sin_stock(i)
						RETURNING resul
					IF NOT resul THEN
						NEXT FIELD r22_bodega
					END IF  
				END IF
				--}
			END IF
		BEFORE FIELD r22_item                       
			LET item_anterior = r_detalle[i].r22_item  
		AFTER FIELD r22_item, r22_cantidad                
			{
	    		IF r_detalle[i].r22_bodega IS NULL AND
	    		   r_detalle[i].r22_item IS NOT NULL THEN
	    		   	LET r_detalle[i].r22_item = NULL
				CLEAR r_detalle[j].r22_item
                       		CALL fl_mostrar_mensaje('Digite bodega primero.','exclamation')
                       		NEXT FIELD r22_bodega
			END IF
			}
	    		IF r_detalle[i].r22_item IS NULL AND
	    		   r_detalle[i].r22_cantidad IS NOT NULL THEN
	    		   	LET r_detalle[i].r22_cantidad = NULL
				CLEAR r_detalle[j].r22_cantidad
                       		CALL fl_mostrar_mensaje('Digite item primero.','exclamation')
                       		NEXT FIELD r22_item
			END IF
	    		IF r_detalle[i].r22_item IS NULL AND 
	    			r_detalle[i].r22_bodega IS NOT NULL THEN
                       		CALL fl_mostrar_mensaje('Digite item.','exclamation')
                       		NEXT FIELD r22_item
			END IF
		  	IF r_detalle[i].r22_bodega IS NOT NULL THEN
				IF NOT valida_bodega(vg_codcia, 
					   r_detalle[i].r22_bodega) THEN
					NEXT FIELD r22_bodega
				END IF
			END IF
	    		IF r_detalle[i].r22_item IS NOT NULL THEN
     				CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) 
					RETURNING rm_r10.*            
                       		IF rm_r10.r10_codigo IS NULL THEN    
                       			CALL fl_mostrar_mensaje('El item no existe.','exclamation')
                       			NEXT FIELD r22_item
                       		END IF	 	
				CALL muestra_etiquetas_det(i, max_row, i)
                       		IF rm_r10.r10_estado = 'B' THEN
                       			LET mensaje = 'El Item esta con estado',
							' BLOQUEADO.',
							' Comentarios: ',
							rm_r10.r10_comentarios CLIPPED
                       			CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')           
                       			NEXT FIELD r22_item 
                       		END IF                     
				IF rm_r10.r10_comentarios[1, 11] = 'OBSERVACION'
				THEN
					CALL fl_mostrar_mensaje(rm_r10.r10_comentarios, 'exclamation')
				END IF
                       		CALL retorna_stock_item(vg_codcia, r_detalle[i].r22_bodega, rm_r10.r10_codigo)
                       			RETURNING --r_detalle[i].r22_bodega, 
                       			          r_r02.r02_codigo, 
                       			          r_detalle[i].stock_tot, 
                       				  r_detalle[i].stock_loc
				IF r_detalle[i].r22_bodega IS NULL THEN
					LET r_detalle[i].r22_bodega =
						               r_r02.r02_codigo 
					DISPLAY r_detalle[i].r22_bodega TO 
					        r_detalle[j].r22_bodega
				END IF
				CALL retorna_descto_maximo_item(vg_codcia, rm_r10.r10_cod_util)
					RETURNING max_descto, max_descto_c
				IF r_detalle[i].r22_porc_descto > max_descto THEN
					LET r_detalle[i].r22_porc_descto = max_descto
					DISPLAY r_detalle[i].stock_tot TO  
						r_detalle[j].stock_tot 
					DISPLAY r_detalle[i].stock_loc TO  
						r_detalle[j].stock_loc 
					DISPLAY r_detalle[i].r22_porc_descto TO 
						r_detalle[j].r22_porc_descto 
			   	END IF

				IF vg_codloc <> 3 AND vg_codloc <> 4 THEN
				IF FIELD_TOUCHED(r22_item) THEN
					LET r_detalle[i].r22_porc_descto = max_descto_c
					DISPLAY r_detalle[i].r22_porc_descto TO 
						r_detalle[j].r22_porc_descto 
			   	END IF
			   	END IF

				IF r_detalle[i].r22_cantidad IS NULL THEN
					LET r_detalle[i].r22_cantidad = 1
					DISPLAY r_detalle[i].r22_cantidad TO 
						r_detalle[j].r22_cantidad
				END IF

				{--
				CALL fl_lee_unidad_medida(rm_r10.r10_uni_med)
					RETURNING r_r05.*
				IF r_r05.r05_decimales = 'N' THEN
					SELECT TRUNC(r_detalle[i].r22_cantidad)
						INTO valor_dec FROM dual
					IF (r_detalle[i].r22_cantidad -
					   valor_dec) > 0
					THEN
						CALL fl_mostrar_mensaje('A este Item no puede ingresarle Cantidades con Decimales.', 'exclamation')
						NEXT FIELD r22_cantidad
					END IF
				END IF
				--}

				LET cant_prof = 0
				FOR k = 1 TO arr_count()
					IF k = i THEN
						CONTINUE FOR
					END IF
                       			IF r_detalle[i].r22_item =
						 r_detalle[k].r22_item AND 
                       			   r_detalle[i].r22_bodega =
						 r_detalle[k].r22_bodega AND 
					   r_detalle[k].r22_bodega <> vm_bod_sstock THEN
						LET cant_prof = cant_prof + 
						    r_detalle[k].r22_cantidad
					END IF
				END FOR
                       		LET r_detalle[i].stock_loc = r_detalle[i].stock_loc - cant_prof
                       		--DISPLAY r_detalle[i].r22_bodega TO r_detalle[j].r22_bodega
                       		DISPLAY r_detalle[i].stock_tot  TO r_detalle[j].stock_tot
				DISPLAY r_detalle[i].stock_loc  TO r_detalle[j].stock_loc
				IF FIELD_TOUCHED(r22_item) OR
				   FIELD_TOUCHED(r22_bodega) THEN       
				IF rg_gen.g00_moneda_base = rm_r21.r21_moneda THEN
					LET r_detalle[i].r22_precio = rm_r10.r10_precio_mb
					IF vg_codcia = 2 AND rm_vend.r01_user_owner = 'TRANINVE' THEN
						LET r_detalle[i].r22_precio = rm_r10.r10_costo_mb
					END IF
				ELSE		
					LET r_detalle[i].r22_precio = rm_r10.r10_precio_ma
					IF vg_codcia = 2 AND rm_vend.r01_user_owner = 'TRANINVE' THEN
						LET r_detalle[i].r22_precio = rm_r10.r10_costo_ma
					END IF
				END IF			
				END IF			
				IF r_detalle[i].r22_porc_descto IS NULL THEN 
					LET r_detalle[i].r22_porc_descto = 0 
				END IF                                    
				IF r_detalle[i].r22_precio <= 0 THEN                                                  
					CALL fl_mostrar_mensaje('El item debe tener precio mayor a cero.','exclamation') 
					NEXT FIELD r22_item
				END IF   
				IF rm_r10.r10_costo_mb <= 0 THEN  
					CALL fl_mostrar_mensaje('El item no tiene costo.','exclamation') 
					--NEXT FIELD r22_item                                                              
				END IF 
				LET k = i - j + 1 
				CALL calcula_totales(arr_count(),k)
				CALL fl_lee_linea_rep(vg_codcia, rm_r10.r10_linea) 
					RETURNING rm_r03.*
				IF rm_r03.r03_grupo_linea <> rm_r21.r21_grupo_linea THEN                                     
					CALL fl_mostrar_mensaje('El Item no pertenece al Grupo de Línea de Venta. ','exclamation')
					NEXT FIELD r22_item
				END IF                                        
				{
				IF r_detalle[i].stock_loc > 0 AND 
					r_detalle[i].r22_cantidad > r_detalle[i].stock_loc THEN
					LET r_detalle[i].r22_cantidad = r_detalle[i].stock_loc
					DISPLAY r_detalle[i].* TO r_detalle[j].*
				END IF		
				}
				--- VALIDACIÓN DE VENTA SIN STOCK              
				CALL fl_lee_stock_rep(vg_codcia, 
						r_detalle[i].r22_bodega,
						r_detalle[i].r22_item)
				      		RETURNING r_r11.* 
				IF r_r11.r11_stock_act IS NULL OR r_r11.r11_stock_act < 0 THEN
					LET r_r11.r11_stock_act = 0
				END IF
				LET stock = r_detalle[i].r22_cantidad - r_r11.r11_stock_act	
				IF r_detalle[i].r22_bodega <> vm_bod_sstock THEN                            
				IF stock > 0 AND r_r11.r11_stock_act > 0 THEN
					LET r_detalle[i].r22_cantidad = r_r11.r11_stock_act
					CALL fl_mostrar_mensaje('Stock insuficiente.', 'exclamation')
					DISPLAY r_detalle[i].r22_cantidad TO 
					        r_detalle[j].r22_cantidad
				END IF
				END IF
				LET r_detalle[i].subtotal_item = r_detalle[i].r22_precio * r_detalle[i].r22_cantidad                                    	
				DISPLAY r_detalle[i].r22_precio TO 
					r_detalle[j].r22_precio
				DISPLAY r_detalle[i].subtotal_item TO 
					r_detalle[j].subtotal_item
				IF r_r11.r11_stock_act = 0 AND r_detalle[i].r22_bodega <> vm_bod_sstock THEN                            
					CALL fl_hacer_pregunta('Este ítem no tiene stock. Desea hacer una proforma sin stock','No')
						RETURNING resp              
					LET int_flag = 0                   
					IF resp = 'Yes' THEN              
						IF vm_bod_sstock IS NULL THEN
							CALL fl_mostrar_mensaje('No hay bodega configurada para venta sin stock.','exclamation')
						        NEXT FIELD r22_item
						END IF
						LET r_detalle[i].r22_bodega = vm_bod_sstock
						DISPLAY r_detalle[i].r22_bodega 
							TO r_detalle[j].r22_bodega      
					ELSE  
						NEXT FIELD r22_item
					END IF  
				END IF         
				LET k = i - j + 1 
				CALL calcula_totales(arr_count(),k)
				FOR k = 1 TO arr_count()
					IF k = i THEN
						CONTINUE FOR
					END IF
                       			IF r_detalle[i].r22_item =
						 r_detalle[k].r22_item AND 
                       			   r_detalle[i].r22_bodega =
						 r_detalle[k].r22_bodega THEN
	--			AND r_detalle[k].r22_bodega <> vm_bod_sstock THEN
						CALL fl_mostrar_mensaje('No puede repetir un mismo item y una misma bodega. Borre la línea.','exclamation') 
						NEXT FIELD r22_item
					END IF
				END FOR
			ELSE
				CLEAR nom_item, descrip_1, descrip_2, descrip_3,
					descrip_4, nom_marca
				IF r_detalle[i].stock_tot IS NOT NULL THEN
					NEXT FIELD r22_item
				END IF
			END IF	
			{-- OJO POR IMPORTACIONES
			IF vg_codloc > 2 THEN
				CALL validar_item_importacion_sin_stock(i)
					RETURNING resul
				IF NOT resul THEN
					NEXT FIELD r22_bodega
				END IF  
			END IF
			--}
		AFTER FIELD r22_porc_descto      
			IF r_detalle[i].r22_porc_descto IS NULL AND 
				r_detalle[i].r22_item IS NOT NULL THEN 
				LET r_detalle[i].r22_porc_descto = 0  
				DISPLAY r_detalle[i].* TO r_detalle[j].* 
			END IF                                 
			IF r_detalle[i].r22_porc_descto IS NOT NULL THEN
				CALL retorna_descto_maximo_item(vg_codcia, rm_r10.r10_cod_util)
					RETURNING max_descto, max_descto_c
				IF r_detalle[i].r22_porc_descto > max_descto THEN
					LET mensaje = 'El item: ', r_detalle[i].r22_item CLIPPED,
						      ' tiene un descuento máximo de: ', 
						      max_descto USING '#&.##'	
					CALL fl_mostrar_mensaje(mensaje,'exclamation') 			
					IF rm_g04.g04_grupo <> 'GE' THEN
						LET r_detalle[i].r22_porc_descto = max_descto
						DISPLAY r_detalle[i].* TO  r_detalle[j].* 
			   		END IF
			   	END IF
			END IF      
			IF r_detalle[i].r22_item IS NOT NULL AND       
		   		r_detalle[i].r22_cantidad IS NOT NULL THEN
				LET k = i - j + 1                
				CALL calcula_totales(arr_count(),k)
			END IF                        
		BEFORE FIELD r22_precio
			LET precio_ant = r_detalle[i].r22_precio
		AFTER FIELD r22_precio
			IF r_detalle[i].r22_precio IS NULL OR
			   r_detalle[i].r22_precio = 0 OR
			   vm_flag_vendedor = 'N' THEN
				LET r_detalle[i].r22_precio = precio_ant
				DISPLAY r_detalle[i].r22_precio TO 
				        r_detalle[j].r22_precio
			END IF
			IF r_detalle[i].r22_precio IS NOT NULL AND       
		   		r_detalle[i].r22_item IS NOT NULL THEN
				LET r_detalle[i].subtotal_item = 
				    r_detalle[i].r22_precio * 
				    r_detalle[i].r22_cantidad
				DISPLAY r_detalle[i].subtotal_item TO 
					r_detalle[j].subtotal_item
				LET k = i - j + 1                
				CALL calcula_totales(arr_count(),k)
			END IF
		AFTER ROW
			IF NOT numero_filas_correcto(arr_count()) THEN
				LET int_flag = int_flag
			END IF
		AFTER INPUT
			LET k = i - j + 1                  
			CALL calcula_totales(arr_count(),k)
			IF NOT numero_filas_correcto(arr_count()) THEN
				NEXT FIELD r22_item
			END IF
			LET ind = arr_count()
			LET vm_ind_arr = ind
			IF rm_r21.r21_tot_neto - rm_r21.r21_flete = 0 THEN
				NEXT FIELD r22_cantidad 
			END IF                         
			LET k = valida_cliente_consumidor_final(rm_r21.r21_codcli)
			LET salir = 1 
	END INPUT 
	IF salir THEN
		EXIT WHILE
	END IF
END WHILE          
IF int_flag THEN  
	RETURN 0 
ELSE            
	RETURN ind
END IF       

END FUNCTION  



FUNCTION numero_filas_correcto(k) 
DEFINE k		INTEGER

IF k > rm_r00.r00_numlin_fact THEN
	CALL fl_mostrar_mensaje('El número de líneas máximo permitido por factura/proforma es de '||rm_r00.r00_numlin_fact|| '.' || ' Elimine líneas o abandone el ingreso.','exclamation')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION valida_bodega(codcia, bodega)
DEFINE codcia 		LIKE gent001.g01_compania
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE r_r02		RECORD LIKE rept002.*

CALL fl_lee_bodega_rep(codcia, bodega) RETURNING r_r02.*
IF r_r02.r02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Bodega no existe.','exclamation') 
	RETURN 0
END IF	
IF r_r02.r02_factura <> 'S' THEN
	CALL fl_mostrar_mensaje('Esta bodega no es de facturación.','exclamation') 			
	RETURN 0
END IF	
IF r_r02.r02_localidad <> vg_codloc THEN
	CALL fl_mostrar_mensaje('Esta bodega no pertenece a esta localidad.','exclamation') 			
	RETURN 0
END IF	
IF r_r02.r02_tipo = 'L' THEN
	CALL fl_mostrar_mensaje('Esta bodega no es física.','exclamation')
	RETURN 0
END IF	
RETURN 1

END FUNCTION



FUNCTION control_saldos_vencidos(codcia, codcli, flag_mens)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codcli		LIKE cxct001.z01_codcli
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		DECIMAL(14,2)
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z00		RECORD LIKE cxct000.*
DEFINE mensaje		VARCHAR(180)
DEFINE flag_error 	SMALLINT
DEFINE flag_mens 	SMALLINT
DEFINE icono		CHAR(20)
DEFINE mens		CHAR(20)

LET icono = 'exclamation'
LET mens  = 'Lo siento, esta'
IF flag_mens THEN
	LET icono = 'info'
	LET mens  = 'Esta'
END IF
CALL fl_retorna_saldo_vencido(codcia, codcli) RETURNING moneda, valor
LET flag_error = 0
IF valor > 0 THEN
	CALL fl_lee_moneda(moneda) RETURNING r_g13.*
	LET mensaje = 'El cliente tiene un saldo vencido ' ||
		      'de  ' || valor || 
		      '  en la moneda ' ||
                      r_g13.g13_nombre ||
		      '.'
	CALL fl_mostrar_mensaje(mensaje, icono)
	CALL fl_lee_compania_cobranzas(codcia) RETURNING r_z00.* 
	IF r_z00.z00_bloq_vencido = 'S' THEN
		CALL fl_mostrar_mensaje(mens CLIPPED || ' activo el bloqueo de proformar y facturar a clientes con saldos vencidos. El cliente debera cancelar sus deudas.',icono)
		LET flag_error = 1
	END IF
END IF
RETURN flag_error

END FUNCTION



FUNCTION tiene_proforma_sobre_stock()
DEFINE r_reg1		RECORD
				ite_s		LIKE rept010.r10_codigo,
				cant_s		LIKE rept022.r22_cantidad
			END RECORD
DEFINE r_reg2		RECORD
				bod_s		LIKE rept002.r02_codigo,
				sto_s		LIKE rept011.r11_stock_act
			END RECORD
DEFINE cuantos		INTEGER
DEFINE lim, i		SMALLINT
DEFINE mensaje		CHAR(400)
DEFINE tex_num, espa	VARCHAR(10)

SELECT r02_codigo bode, r02_tipo tipo
	FROM rept002
	WHERE r02_compania   = vg_codcia
	  AND r02_localidad  = vg_codloc
	  AND r02_estado     = 'A'
	  AND r02_factura    = 'S'
	  AND r02_area       = 'R'
	  AND r02_tipo_ident = 'V'
	INTO TEMP tmp_bod
SELECT r22_bodega bod, r22_item item, r22_cantidad cant
	FROM rept022
	WHERE r22_compania  = vg_codcia
	  AND r22_localidad = vg_codloc
	  AND r22_numprof   = rm_r21.r21_numprof
	INTO TEMP tmp_pro
SELECT COUNT(*) INTO cuantos
	FROM tmp_pro
	WHERE bod = (SELECT bode FROM tmp_bod WHERE tipo = 'S')
IF cuantos = 0 THEN
	DROP TABLE tmp_bod
	DROP TABLE tmp_pro
	RETURN 1
END IF
SELECT r11_bodega bod_sto1, r11_item ite_sto1, r11_stock_act stock1
	FROM rept011
	WHERE r11_compania   = vg_codcia
	  AND r11_bodega    IN (SELECT bode FROM tmp_bod WHERE tipo <> 'S')
	  AND r11_item      IN (SELECT UNIQUE item FROM tmp_pro)
	  AND r11_stock_act <> 0
	INTO TEMP tmp_sto1
SELECT ite_sto1 ite_sto2, NVL(SUM(stock1), 0) stock2
	FROM tmp_sto1
	GROUP BY 1
	INTO TEMP t1
SELECT ite_sto2, (stock2 -
	NVL((SELECT SUM(cant)
		FROM tmp_pro
		WHERE item = ite_sto2
		  AND bod  IN (SELECT bode
				FROM tmp_bod
				WHERE tipo <> 'S')), 0)) stock2
	FROM t1
	INTO TEMP tmp_sto2
DROP TABLE t1
SELECT bod_sto1, item, cant, stock1
	FROM tmp_pro, tmp_sto2, tmp_sto1
	WHERE item      = ite_sto2
	  AND ((cant   <> stock2
	  AND   stock2  > 0)
	   OR   stock2 <> 0)
	  AND bod       = (SELECT bode FROM tmp_bod WHERE tipo = 'S')
	  AND ite_sto1  = ite_sto2
	INTO TEMP tmp_ite
DROP TABLE tmp_bod
DROP TABLE tmp_pro
DROP TABLE tmp_sto1
DROP TABLE tmp_sto2
SELECT COUNT(*) INTO cuantos FROM tmp_ite
IF cuantos = 0 THEN
	DROP TABLE tmp_ite
	RETURN 1
END IF
DECLARE c1 CURSOR FOR
	SELECT UNIQUE item, cant
		FROM tmp_ite
		ORDER BY 1
FOREACH c1 INTO r_reg1.*
	LET mensaje = 'Ha proformado el ítem: ', r_reg1.ite_s CLIPPED,
			' con SOBRE STOCK de ', r_reg1.cant_s USING "<<<<<&.##",
			'.\nPor favor proformelo con: \n\n'
	DECLARE c2 CURSOR FOR
		SELECT bod_sto1, stock1
			FROM tmp_ite
			WHERE item = r_reg1.ite_s
			ORDER BY 1
	LET mensaje = mensaje CLIPPED, '\tBODEGA\t      S T O C K\n',
			'\t----------\t      ------------\n'
	FOREACH c2 INTO r_reg2.*
		LET tex_num = r_reg2.sto_s USING "---,--&.##"
		CALL fl_justifica_titulo('I', tex_num, 10) RETURNING tex_num
		LET tex_num = tex_num CLIPPED
		LET lim     = (10 - LENGTH(tex_num))
		IF lim = 1 THEN
			LET lim = lim + 1
		END IF
		LET espa = ' '
		FOR i = 1 TO lim
			LET espa = espa, ' '
		END FOR
		CALL fl_justifica_titulo('D', tex_num, 10) RETURNING tex_num
		LET mensaje = mensaje CLIPPED, '\t     ', r_reg2.bod_s CLIPPED,
				'\t ', espa, tex_num CLIPPED, '\n'
	END FOREACH
	LET lim     = LENGTH(mensaje) - 1
	LET mensaje = mensaje[1, lim] CLIPPED, '\n\nREORGANICE SU PROFORMA.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
END FOREACH
DROP TABLE tmp_ite
RETURN 0

END FUNCTION



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



FUNCTION control_cabecera()
DEFINE r_r21		RECORD LIKE rept021.*

WHILE TRUE
	SQL
		SELECT NVL(MAX(r21_numprof), 0) + 1
			INTO $rm_r21.r21_numprof
			FROM rept021
			WHERE r21_compania  = $vg_codcia
			  AND r21_localidad = $vg_codloc
	END SQL
	CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, rm_r21.r21_numprof)
		RETURNING r_r21.*
	IF r_r21.r21_compania IS NULL THEN   
		EXIT WHILE
	END IF
END WHILE
LET rm_r21.r21_fecing = CURRENT  
INSERT INTO rept021 VALUES (rm_r21.*) 
IF num_args() = 6 THEN
	RETURN 1
END IF
DISPLAY BY NAME rm_r21.r21_numprof, rm_r21.r21_fecing 
IF vm_num_rows = vm_max_rows THEN 
	LET vm_num_rows = 1      
ELSE  
        LET vm_num_rows = vm_num_rows + 1   
END IF
LET vm_row_current = vm_num_rows  
LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 	-- Rowid de la ultima fila
RETURN 1

END FUNCTION                     



FUNCTION control_ingreso_detalle()
DEFINE i,done 	SMALLINT
DEFINE r_r10	RECORD LIKE rept010.* 
DEFINE orden	SMALLINT              

LET done  = 1 
LET orden = 1
-- INITIAL VALUES FOR rm_r22 FIELDS
FOR i = 1 TO vm_num_detalles
	INITIALIZE rm_r22.* TO NULL 
	IF r_detalle[i].r22_item IS NULL THEN
		CONTINUE FOR
	END IF
	LET rm_r22.r22_compania     = vg_codcia 
	LET rm_r22.r22_localidad    = vg_codloc
	LET rm_r22.r22_numprof      = rm_r21.r21_numprof
	LET rm_r22.r22_cantidad     = r_detalle[i].r22_cantidad
	LET rm_r22.r22_bodega       = r_detalle[i].r22_bodega 
	LET rm_r22.r22_item         = r_detalle[i].r22_item  
	LET rm_r22.r22_item_ant     = NULL
	LET rm_r22.r22_porc_descto  = r_detalle[i].r22_porc_descto
	LET rm_r22.r22_precio       = r_detalle[i].r22_precio    
	LET rm_r22.r22_dias_ent     = 0
	LET rm_r22.r22_orden        = orden 
	LET orden = orden + 1              
	CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item) RETURNING r_r10.*
	LET rm_r22.r22_descripcion  = r_r10.r10_nombre                     
	LET rm_r22.r22_linea        = r_r10.r10_linea
	LET rm_r22.r22_rotacion     = r_r10.r10_rotacion                  
	IF rg_gen.g00_moneda_base = rm_r21.r21_moneda THEN  
		LET rm_r22.r22_costo  = r_r10.r10_costo_mb 
	ELSE	                                           
		LET rm_r22.r22_costo  = r_r10.r10_costo_ma
	END IF
	LET rm_r22.r22_val_descto     = (r_detalle[i].r22_cantidad * r_detalle[i].r22_precio)
					 * r_detalle[i].r22_porc_descto / 100  
	LET rm_r22.r22_val_descto     = fl_retorna_precision_valor(rm_r21.r21_moneda, 
					              rm_r22.r22_val_descto)
	LET rm_r22.r22_val_impto      =	((r_detalle[i].r22_cantidad * r_detalle[i].r22_precio) -
				         rm_r22.r22_val_descto) * rm_r21.r21_porc_impto / 100     
	LET rm_r22.r22_val_impto      = fl_retorna_precision_valor(rm_r21.r21_moneda,  
					rm_r22.r22_val_impto)
	INSERT INTO rept022 VALUES(rm_r22.*)          
END FOR 
RETURN done  

END FUNCTION 



FUNCTION calcula_totales(indice, indice_2)   
DEFINE indice,k		SMALLINT            
DEFINE indice_2,y	SMALLINT         
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE descto		DECIMAL(12,2)
DEFINE val_impto	DECIMAL(12,2)

LET vm_costo     = 0	-- TOTAL COSTO     
LET vm_subtotal  = 0	-- TOTAL BRUTO    
LET vm_descuento = 0	-- TOTAL DEL DESCUENTO 
LET vm_impuesto  = 0 	-- TOTAL DEL IMPUESTO 
LET vm_total     = 0	-- TOTAL NETO        
FOR k = 1 TO indice 
	IF r_detalle[k].r22_item IS NULL THEN
		CONTINUE FOR
	END IF
	CALL fl_lee_item(vg_codcia, r_detalle[k].r22_item) RETURNING r_r10.* 
	LET vm_costo                   = vm_costo + r_detalle[k].r22_cantidad *
				         r_r10.r10_costo_mb
	LET r_detalle[k].subtotal_item = r_detalle[k].r22_precio *
				         r_detalle[k].r22_cantidad 
	LET vm_subtotal                = vm_subtotal +  
					 r_detalle[k].subtotal_item
	LET descto = r_detalle[k].r22_cantidad * r_detalle[k].r22_precio *  
		     r_detalle[k].r22_porc_descto / 100
	LET descto = fl_retorna_precision_valor(rm_r21.r21_moneda, descto) 
	IF descto IS NOT NULL THEN
		LET vm_descuento = vm_descuento + descto 
	END IF
	IF vm_flag_calculo_impto = 'I' THEN   
		IF rm_z01.z01_paga_impto IS NULL OR 
	  	   rm_z01.z01_paga_impto <> 'N' THEN
			LET val_impto = (r_detalle[k].subtotal_item - descto)* 
			                 rm_r21.r21_porc_impto / 100 
			LET val_impto = fl_retorna_precision_valor(rm_r21.r21_moneda,
		 		                                   val_impto)
		END IF 
		LET vm_impuesto = vm_impuesto + val_impto 
	END IF  
END FOR        
IF vm_flag_calculo_impto <> 'I' THEN 
	LET vm_impuesto = 0         
	LET vm_impuesto = vm_impuesto +((vm_subtotal - vm_descuento) *
				         rm_r21.r21_porc_impto / 100 )
	LET vm_impuesto = fl_retorna_precision_valor(rm_r21.r21_moneda, vm_impuesto)
END IF 
IF vm_impuesto IS NULL THEN
	LET vm_impuesto = 0
END IF
LET vm_total = vm_subtotal - vm_descuento + vm_impuesto + rm_r21.r21_flete
LET rm_r21.r21_tot_costo = vm_costo    
LET rm_r21.r21_tot_bruto = vm_subtotal
LET rm_r21.r21_tot_dscto = vm_descuento
LET rm_r21.r21_tot_neto  = vm_total   
IF num_args() <> 6 THEN
	DISPLAY BY NAME rm_r21.r21_tot_bruto, rm_r21.r21_tot_dscto,
			vm_impuesto, rm_r21.r21_tot_neto
END IF

END FUNCTION



FUNCTION control_ver_detalle() 
DEFINE i, j 		SMALLINT      

CALL muestra_contadores_det(1, vm_ind_arr)
CALL set_count(vm_ind_arr)  
DISPLAY ARRAY r_detalle TO r_detalle.* 
        ON KEY(INTERRUPT)   
		CALL muestra_etiquetas_det(0, vm_ind_arr, 1)
                EXIT DISPLAY  
        ON KEY(F1,CONTROL-W) 
		CALL control_visor_teclas_caracter_5() 
	ON KEY(F5)
		LET i = arr_curr()
		CALL muestra_stock_local_nacional(i, r_detalle[i].r22_item, 0)
		LET int_flag = 0
	ON KEY(F6)
		CALL control_imprimir_proforma(1)
		LET int_flag = 0
	ON KEY(F7)
		CALL enviar_mail()
		LET int_flag = 0
	ON KEY(F8)
		IF vg_usuario <> 'HSALAZAR' THEN
			CALL generar_pdf()
			LET int_flag = 0
		END IF
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL muestra_etiquetas_det(i, vm_ind_arr, i)
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL muestra_etiquetas_det(i, vm_ind_arr, i)
        --#BEFORE DISPLAY 
                --#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F5","Stock Total") 
		--#CALL dialog.keysetlabel("F6","Imprimir") 
		--#CALL dialog.keysetlabel("F7","Enviar Mail") 
		--#IF vg_usuario <> 'HSALAZAR' THEN
			--#CALL dialog.keysetlabel("F8","PDF")
		--#ELSE
			--#CALL dialog.keysetlabel("F8","")
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY 
CALL muestra_contadores_det(0, vm_ind_arr)

END FUNCTION 



FUNCTION control_imprimir_proforma(flag)
DEFINE flag		SMALLINT
DEFINE command_run 	VARCHAR(100)
DEFINE run_prog		CHAR(10)
DEFINE param		CHAR(1)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
CASE flag
	WHEN 1
		LET param = NULL
	WHEN 2
		LET param = 'M'
END CASE
LET command_run = run_prog, 'repp419 ',vg_base, ' ',
		   vg_modulo, ' ', vg_codcia, ' ',
		   vg_codloc, ' ', rm_r21.r21_numprof, ' ', param
RUN command_run

END FUNCTION



FUNCTION control_hacer_preventa()            
DEFINE i,j,k,done 	SMALLINT            
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE resp 		CHAR(6)     
DEFINE preventas 	INTEGER   
DEFINE r_r24		RECORD LIKE rept024.*
DEFINE salir		SMALLINT            
DEFINE query		CHAR(600)   
DEFINE expr_costo	VARCHAR(100)
DEFINE r_r02		RECORD LIKE rept002.* 
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE orden		SMALLINT  
DEFINE r_detprev	RECORD   
				bodega		LIKE rept022.r22_bodega,
				item		LIKE rept022.r22_item, 
				precio		LIKE rept022.r22_precio,
				descto		LIKE rept022.r22_porc_descto, 
				linea		LIKE rept010.r10_linea,  
				cantidad	LIKE rept022.r22_cantidad 
			END RECORD
DEFINE mensaje		CHAR(400)
DEFINE flag_error	SMALLINT
DEFINE flag_bloqueo	SMALLINT
DEFINE numprof		VARCHAR(15)

IF rm_r21.r21_num_ot IS NOT NULL OR rm_r21.r21_num_presup IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Esta proforma es de talleres.','exclamation')             	
	RETURN
END IF 
CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, rm_r21.r21_numprof)
	RETURNING rm_r21.*
CALL fl_control_status_caja(vg_codcia, vg_codloc, 'P') RETURNING int_flag
IF int_flag <> 0 THEN
	LET int_flag = 0
	RETURN
END IF	
IF rm_r21.r21_cod_tran IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Esta proforma ya fue facturada, no puede ser convertida en preventa.','exclamation')             	
	RETURN
END IF 
CALL fl_lee_compania_repuestos(vg_codcia)  -- PARA OBTENER LA CONFIGURACION 
	RETURNING rm_r00.*		   -- DEL AREA DE REPUESTOS 
IF DATE(rm_r21.r21_fecing) + rm_r00.r00_expi_prof < TODAY THEN   
	CALL fl_mostrar_mensaje('El tiempo de vida de la proforma ya ' ||
				'expiró, por lo tanto no puede ser ' ||
				'convertida en preventa.',
				'exclamation')
	RETURN 
END IF   
IF rm_r21.r21_codcli IS NULL THEN
	CALL fl_mostrar_mensaje('Modifique la proforma e ingrese código del cliente.','exclamation')
	RETURN
END IF
IF NOT valida_cliente_consumidor_final(rm_r21.r21_codcli) THEN
	RETURN
END IF
CALL control_saldos_vencidos(vg_codcia, rm_r21.r21_codcli, 0)
	RETURNING flag_error
{--
IF flag_error THEN
	RETURN
END IF
--} 
IF num_args() <> 6 THEN
	IF NOT tiene_proforma_sobre_stock() THEN
		RETURN
	END IF
END IF
IF rm_r21.r21_referencia IS NULL THEN
	CALL fl_mostrar_mensaje('POR FAVOR ASEGURESE DE INGRESAR LA DIRECCION DE ENTREGA', 'info')
END IF
IF num_args() <> 6 THEN
	CALL fl_hacer_pregunta('Esta seguro de convertir en preventa esta proforma','No')
		RETURNING resp
	IF resp = 'No' THEN
		RETURN
	END IF
END IF
-- Empieza el proceso 
BEGIN WORK 
LET flag_bloqueo = 0
CALL eliminar_preventa_anterior() RETURNING flag_bloqueo
IF flag_bloqueo THEN
	RETURN
END IF
INITIALIZE rm_r23.* TO NULL
LET rm_r23.r23_compania    = vg_codcia 
LET rm_r23.r23_localidad   = vg_codloc
LET rm_r23.r23_estado      = 'P'
LET rm_r23.r23_cont_cred   = 'C'
LET rm_r23.r23_grupo_linea = rm_r21.r21_grupo_linea
LET rm_r23.r23_codcli      = rm_r21.r21_codcli
LET rm_r23.r23_nomcli      = rm_r21.r21_nomcli
LET rm_r23.r23_dircli      = rm_r21.r21_dircli
LET rm_r23.r23_telcli      = rm_r21.r21_telcli
LET rm_r23.r23_cedruc      = rm_r21.r21_cedruc
LET rm_r23.r23_vendedor    = rm_r21.r21_vendedor
LET rm_r23.r23_descuento   = rm_r21.r21_descuento
LET rm_r23.r23_bodega      = rm_r21.r21_bodega  
LET rm_r23.r23_porc_impto  = rm_r21.r21_porc_impto 
LET rm_r23.r23_moneda      = rm_r21.r21_moneda
LET rm_r23.r23_tot_costo   = rm_r21.r21_tot_costo 
LET rm_r23.r23_tot_bruto   = rm_r21.r21_tot_bruto
LET rm_r23.r23_tot_dscto   = rm_r21.r21_tot_dscto
LET rm_r23.r23_tot_neto    = rm_r21.r21_tot_neto 
LET rm_r23.r23_flete  	   = rm_r21.r21_flete
LET rm_r23.r23_numprof     = rm_r21.r21_numprof
LET rm_r23.r23_num_ot      = rm_r21.r21_num_ot
LET rm_r23.r23_usuario     = vg_usuario
IF num_args() = 6 THEN
	LET rm_r23.r23_usuario = rm_r21.r21_usuario
END IF
LET rm_r23.r23_fecing      = CURRENT
LET numprof		   = rm_r21.r21_numprof
LET rm_r23.r23_referencia  = 'PREVTA. GENERADA DE PROF. # ', numprof CLIPPED
CALL fl_lee_moneda(rm_r23.r23_moneda) RETURNING rm_g13.*
LET rm_r23.r23_precision = rm_g13.g13_decimales
IF rm_r23.r23_moneda = rg_gen.g00_moneda_base THEN 
	LET rm_r23.r23_paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(rg_gen.g00_moneda_alt,
			 	  rg_gen.g00_moneda_base)
		RETURNING rm_g14.* 
	LET rm_r23.r23_paridad =  rm_g14.g14_tasa
END IF
-- Para hacer el numero de preventas segun el numero de lineas
-- soportadas por la factura 
LET preventas = 1
IF rm_r00.r00_numlin_fact <> 9999 THEN
	LET preventas = vm_ind_arr / rm_r00.r00_numlin_fact 
	IF vm_ind_arr MOD rm_r00.r00_numlin_fact > 0 THEN  
		LET preventas = preventas + 1 	---NUMERO DE PREVENTAS A GENERAR
	END IF 
END IF
-- Saca los items que se van a grabar en el detalle de la(s) preventa(s)
DECLARE q_prof CURSOR FOR
	SELECT MIN(r22_orden), r22_bodega, r22_item, r22_precio,
		r22_porc_descto, r10_linea, SUM(r22_cantidad)
		FROM rept022, rept010 
		WHERE r22_compania  = vg_codcia 
		  AND r22_localidad = vg_codloc
		  AND r22_numprof   = rm_r21.r21_numprof
		  AND r10_compania  = r22_compania
		  AND r10_codigo    = r22_item 
		GROUP BY r22_bodega, r22_item, r22_precio, r22_porc_descto,
			r10_linea
		ORDER BY 1 
INITIALIZE r_detprev.* TO NULL
LET salir = 0 
OPEN  q_prof 
FETCH q_prof INTO orden, r_detprev.* 
IF STATUS = NOTFOUND THEN 
	LET salir = 1
END IF 
FOR i = 1 TO preventas 
	IF salir THEN
		EXIT FOR
	END IF
	SELECT MAX(r23_numprev) + 1 INTO rm_r23.r23_numprev 
       		FROM  rept023
        	WHERE r23_compania  = vg_codcia 
        	AND   r23_localidad = vg_codloc
	IF rm_r23.r23_numprev IS NULL THEN
       	 	LET rm_r23.r23_numprev = 1
	END IF
	FOR k = 1 TO vm_num_detalles
		CALL fl_lee_bodega_rep(vg_codcia, r_detalle[k].r22_bodega)
			RETURNING r_r02.*
		IF r_r02.r02_tipo = 'S' THEN
			LET rm_r23.r23_estado = 'A'
			EXIT FOR
		END IF
	END FOR 
	IF i > 1 THEN
		LET rm_r23.r23_flete = 0
	END IF 
	INSERT INTO rept023 VALUES (rm_r23.*)
	LET j = 1
	WHILE NOT salir
		IF j > rm_r00.r00_numlin_fact THEN
			EXIT WHILE
		END IF
		INITIALIZE r_r24.* TO NULL
		DECLARE q_r24 CURSOR FOR
			SELECT * FROM rept024
				WHERE r24_compania  = vg_codcia
				  AND r24_localidad = vg_codloc
				  AND r24_numprev   = rm_r23.r23_numprev
		  		  AND r24_item      = r_detprev.item
			ORDER BY r24_orden DESC
		OPEN q_r24
		FETCH q_r24 INTO r_r24.*
		IF STATUS <> NOTFOUND THEN
			IF r_detprev.precio <> r_r24.r24_precio THEN
				ROLLBACK WORK
				LET mensaje = 'El item ',
					r_detprev.item CLIPPED,
					' se ha digitado dos ',
					'veces en la proforma, con ',
					'precios diferentes. Se detendrá ',
					'la generación de la preventa.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				RETURN 
			END IF
			IF r_detprev.descto <> r_r24.r24_descuento THEN
				ROLLBACK WORK
				LET mensaje = 'El item ',
					r_detprev.item CLIPPED,
					' se ha digitado dos o mas ',
					'veces en la proforma, con ',
					'descuentos diferentes. Se detendra ',
					'la generación de la preventa.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				RETURN
			END IF
		END IF
		CLOSE q_r24
		FREE q_r24
		INITIALIZE rm_r24.* TO NULL
		LET rm_r24.r24_compania     = vg_codcia
		LET rm_r24.r24_localidad    = vg_codloc 
		LET rm_r24.r24_numprev      = rm_r23.r23_numprev
		LET rm_r24.r24_bodega       = r_detprev.bodega
                LET rm_r24.r24_numprev      = rm_r23.r23_numprev 
        	LET rm_r24.r24_proformado   = 'S'
	        LET rm_r24.r24_cant_ped     = r_detprev.cantidad 
	        LET rm_r24.r24_cant_ven     = r_detprev.cantidad
        	LET rm_r24.r24_item         = r_detprev.item 
        	LET rm_r24.r24_descuento    = r_detprev.descto
        	LET rm_r24.r24_precio       = r_detprev.precio
       		LET rm_r24.r24_orden        = j 
        	LET rm_r24.r24_linea        = r_detprev.linea 
		CALL fl_lee_stock_rep(vg_codcia, rm_r24.r24_bodega,
				      rm_r24.r24_item) RETURNING r_r11.* 
		IF r_r11.r11_stock_act IS NULL THEN
			LET r_r11.r11_stock_act = 0
		END IF	
		CALL fl_lee_item(vg_codcia, rm_r24.r24_item)
			RETURNING r_r10.* 
		IF r_r10.r10_estado = 'B' THEN
			LET mensaje = 'El ítem ', rm_r24.r24_item CLIPPED,
					' esta BLOQUEADO. Por favor solicite',
					' al departamento que administra los',
					' ítems para que lo desbloquee.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation') 
			ROLLBACK WORK
			RETURN 
		END IF 
		IF r_r10.r10_costo_mb <= 0.01 THEN
			LET mensaje = 'El Item ',
			     rm_r24.r24_item, ' ',
			     'no tiene costo. Se debe hacer un ajuste al costo.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			ROLLBACK WORK
			RETURN
		END IF	
		IF r_r11.r11_stock_act < rm_r24.r24_cant_ped THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r24.r24_bodega) 
				RETURNING r_r02.* 
			IF r_r02.r02_tipo IS NULL OR r_r02.r02_tipo <> 'S' THEN
        			LET rm_r24.r24_cant_ven = r_r11.r11_stock_act
				LET mensaje = 'El Item ',
					rm_r24.r24_item CLIPPED, ' ',
					r_r10.r10_nombre CLIPPED,
					' tiene en stock ',
					r_r11.r11_stock_act USING "---,--&.##",
					' en la bodega ', r_r11.r11_bodega,
					', y la cantidad pedida es ',
					rm_r24.r24_cant_ped USING "---,--&.##",
					'. Modifique la proforma y vuelva a ',
					'generar la preventa.'
				CALL fl_mostrar_mensaje(mensaje,'exclamation') 
				ROLLBACK WORK
				RETURN 
			END IF 
		END IF
	        LET rm_r24.r24_val_descto   = 
	        	(r_detprev.cantidad * r_detprev.precio) *  
	        	(r_detprev.descto / 100)
	        LET rm_r24.r24_val_impto    =
			((r_detprev.cantidad * r_detprev.precio) - 
	                  rm_r24.r24_val_descto) *
			(rm_r23.r23_porc_impto / 100)
		INSERT INTO rept024 VALUES(rm_r24.*)
	       	LET j = j + 1
		INITIALIZE r_detprev.* TO NULL 
		FETCH q_prof INTO orden, r_detprev.*
		IF STATUS = NOTFOUND THEN
			LET salir = 1
		END IF
	END WHILE 
	IF rm_r23.r23_moneda = rg_gen.g00_moneda_base THEN
		LET expr_costo = ' SUM(r24_cant_ven * r10_costo_mb) '
	ELSE
		IF rm_r23.r23_moneda = rg_gen.g00_moneda_alt THEN
			LET expr_costo = ' SUM(r24_cant_ven * r10_costo_ma) '
		ELSE
			ROLLBACK WORK 
			CALL fl_mostrar_mensaje('La preventa debe hacerse en la moneda base o en la moneda alterna del sistema.','stop')
			RETURN 
		END IF
	END IF
	LET query = 'SELECT SUM(r24_cant_ven * r24_precio), ' ||
		          ' SUM(r24_val_descto), SUM(r24_val_impto), ' || 
			  expr_costo CLIPPED ||
		    '	FROM rept024, rept010 ' ||
		    '	WHERE r24_compania  = ' || vg_codcia ||
		        ' AND r24_localidad = ' || vg_codloc ||
		        ' AND r24_numprev   = ' || rm_r23.r23_numprev ||
		        ' AND r10_compania  = r24_compania ' ||
		        ' AND r10_codigo    = r24_item '
	PREPARE stmnt1 FROM query
	EXECUTE stmnt1 INTO vm_subtotal, vm_descuento, vm_impuesto, vm_costo
	LET vm_descuento = fl_retorna_precision_valor(rm_r23.r23_moneda,
					              vm_descuento)
	LET vm_impuesto  = fl_retorna_precision_valor(rm_r23.r23_moneda, 
					              vm_impuesto)
	LET rm_r23.r23_tot_costo = vm_costo
	LET rm_r23.r23_tot_bruto = vm_subtotal
	LET rm_r23.r23_tot_dscto = vm_descuento
--	LET rm_r23.r23_tot_neto  = vm_subtotal - vm_descuento + vm_impuesto
	-- Para sacar el impuesto del total bruto
	LET vm_impuesto= (vm_subtotal - vm_descuento) * 
			  rm_r23.r23_porc_impto / 100
	LET rm_r23.r23_tot_neto  = vm_subtotal - vm_descuento + vm_impuesto +
				   rm_r23.r23_flete
	UPDATE rept023 SET r23_tot_costo = rm_r23.r23_tot_costo,
		           r23_tot_bruto = rm_r23.r23_tot_bruto,
	      	      	   r23_tot_dscto = rm_r23.r23_tot_dscto,
	      	      	   r23_tot_neto  = rm_r23.r23_tot_neto 
		WHERE r23_compania  = vg_codcia
		  AND r23_localidad = vg_codloc
		  AND r23_numprev   = rm_r23.r23_numprev
	CALL control_actualizacion_caja() RETURNING done
	IF done = 0 THEN
		ROLLBACK WORK 
		CALL fl_mostrar_mensaje('No se pudo grabar en la cajt010. No se realizará proceso.','exclamation')
		RETURN 
	END IF
END FOR
IF num_args() = 6 THEN
	UPDATE rept088 SET r88_numprev_nue = rm_r23.r23_numprev
		WHERE r88_compania  = vg_codcia
		  AND r88_localidad = vg_codloc
		  AND r88_numprof   = vm_numprof
	IF STATUS < 0 THEN
		ROLLBACK WORK              
		CALL fl_mostrar_mensaje('Ha ocurrido un error al Actualizar la Pre-Venta Nueva en la tabla rept088.', 'stop')
		EXIT PROGRAM
	END IF
END IF
COMMIT WORK
LET mensaje = 'Se generó la preventa: ', rm_r23.r23_numprev USING "<<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
IF num_args() <> 6 THEN
	DISPLAY BY NAME rm_r23.r23_numprev
END IF

END FUNCTION



FUNCTION eliminar_preventa_anterior()
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_r24		RECORD LIKE rept024.*
DEFINE flag, i		SMALLINT

LET flag = 0
INITIALIZE r_r23.* TO NULL
SELECT r23_numprev FROM rept023
	WHERE r23_compania  = vg_codcia
	  AND r23_localidad = vg_codloc
	  AND r23_numprof   = rm_r21.r21_numprof
	INTO TEMP te_qulazo
WHENEVER ERROR CONTINUE
DECLARE q_elimpre CURSOR FOR
	SELECT * FROM rept023
		WHERE r23_compania  = vg_codcia
		  AND r23_localidad = vg_codloc
		  AND r23_numprev   IN (SELECT r23_numprev FROM te_qulazo)
	FOR UPDATE
OPEN q_elimpre
FETCH q_elimpre INTO r_r23.*
IF STATUS < 0 THEN
	DROP TABLE te_qulazo
	ROLLBACK WORK
	LET flag = 1
	CLOSE q_elimpre
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN flag
END IF
WHENEVER ERROR STOP
IF r_r23.r23_compania IS NULL THEN
	CLOSE q_elimpre
	DROP TABLE te_qulazo
	RETURN flag
END IF
FOREACH q_elimpre INTO r_r23.*
	IF r_r23.r23_cod_tran IS NOT NULL THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_cabecera_caja(r_r23.r23_compania, r_r23.r23_localidad, 'PR',
					r_r23.r23_numprev)
		RETURNING r_j10.*
	IF r_j10.j10_tipo_destino IS NULL THEN
		DELETE FROM cajt011 
			WHERE j11_compania    = r_j10.j10_compania 
			  AND j11_localidad   = r_j10.j10_localidad 
			  AND j11_tipo_fuente =	r_j10.j10_tipo_fuente 
			  AND j11_num_fuente  =	r_j10.j10_num_fuente 
		DELETE FROM cajt010 
			WHERE j10_compania    = r_j10.j10_compania 
			  AND j10_localidad   = r_j10.j10_localidad 
			  AND j10_tipo_fuente =	r_j10.j10_tipo_fuente 
			  AND j10_num_fuente  =	r_j10.j10_num_fuente 
	END IF
	DELETE FROM rept027
		WHERE r27_compania  = r_r23.r23_compania
		  AND r27_localidad = r_r23.r23_localidad
		  AND r27_numprev   = r_r23.r23_numprev
	DELETE FROM rept026
		WHERE r26_compania  = r_r23.r23_compania
		  AND r26_localidad = r_r23.r23_localidad
		  AND r26_numprev   = r_r23.r23_numprev
	DELETE FROM rept025
		WHERE r25_compania  = r_r23.r23_compania
		  AND r25_localidad = r_r23.r23_localidad
		  AND r25_numprev   = r_r23.r23_numprev
	DELETE FROM rept024
		WHERE r24_compania  = r_r23.r23_compania
		  AND r24_localidad = r_r23.r23_localidad
		  AND r24_numprev   = r_r23.r23_numprev
	DELETE FROM rept023 WHERE CURRENT OF q_elimpre
END FOREACH
DROP TABLE te_qulazo
CLOSE q_elimpre
FREE q_elimpre
RETURN flag

END FUNCTION



FUNCTION muestra_detalle()
DEFINE i, k		SMALLINT
DEFINE cant_prof	DECIMAL (8,2)
DEFINE stock          	DECIMAL (8,2)
DEFINE r_r22		RECORD LIKE rept022.*
DEFINE peso 		LIKE rept010.r10_peso
DEFINE max_descto	DECIMAL(4,2)
DEFINE max_descto_c	DECIMAL(4,2)
DEFINE bode		LIKE rept002.r02_codigo
DEFINE cambiar_precio	SMALLINT
DEFINE dias_trans	INTEGER

CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr 
	INITIALIZE r_detalle[i].* TO NULL
	IF num_args() <> 6 THEN
		CLEAR r_detalle[i].*
	END IF
END FOR

DECLARE q_rept022 CURSOR FOR 
	SELECT rept022.*, rept010.r10_peso 
		 FROM rept022, rept010 
            	WHERE r22_compania  = vg_codcia 
	    	  AND r22_localidad = vg_codloc
            	  AND r22_numprof   = rm_r21.r21_numprof
            	  AND r22_compania  = r10_compania
            	  AND r22_item      = r10_codigo
		ORDER BY r22_orden

CALL retorna_precio_validez_item() RETURNING cambiar_precio
IF num_args() = 6 THEN
	LET cambiar_precio = 0
END IF
LET i = 1
FOREACH q_rept022 INTO r_r22.*, peso
	CALL fl_lee_item(vg_codcia, r_r22.r22_item) RETURNING rm_r10.*
	LET r_detalle[i].r22_porc_descto = r_r22.r22_porc_descto
	{
	CALL retorna_descto_maximo_item(vg_codcia, rm_r10.r10_cod_util)
		RETURNING max_descto, max_descto_c
	LET r_detalle[i].r22_porc_descto = r_r22.r22_porc_descto
	IF r_detalle[i].r22_porc_descto > max_descto THEN
		LET r_detalle[i].r22_porc_descto = max_descto
	END IF
	}
	LET r_detalle[i].r22_cantidad    = r_r22.r22_cantidad
	LET r_detalle[i].r22_bodega      = r_r22.r22_bodega
	LET r_detalle[i].r22_item        = r_r22.r22_item
	LET r_detalle[i].r22_precio      = r_r22.r22_precio
	IF cambiar_precio THEN
		LET r_detalle[i].r22_precio = rm_r10.r10_precio_mb
	END IF
	LET r_detalle[i].subtotal_item   = r_r22.r22_precio * r_r22.r22_cantidad
	LET i = i + 1
        IF i > vm_max_det THEN
		EXIT FOREACH
	END IF	
END FOREACH 

LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 6 THEN
		RETURN
	END IF
	LET i = 0
	CLEAR FORM
	CALL control_DISPLAY_botones()
	RETURN
END IF
LET vm_ind_arr = i
LET vm_num_detalles = vm_ind_arr
FOR i = 1 TO vm_ind_arr 
       	CALL retorna_stock_item(vg_codcia, r_detalle[i].r22_bodega, r_detalle[i].r22_item)
        	RETURNING bode, r_detalle[i].stock_tot, r_detalle[i].stock_loc
        	--RETURNING r_detalle[i].r22_bodega, r_detalle[i].stock_tot, r_detalle[i].stock_loc

	LET cant_prof = 0
	FOR k = 1 TO vm_ind_arr
		IF k = i THEN
			CONTINUE FOR
		END IF
                IF r_detalle[i].r22_item   = r_detalle[k].r22_item AND 
                   r_detalle[i].r22_bodega = r_detalle[k].r22_bodega AND 
		   r_detalle[k].r22_bodega <> vm_bod_sstock THEN
			LET cant_prof = cant_prof + r_detalle[k].r22_cantidad
		END IF
	END FOR
        IF r_detalle[i].stock_loc > 0 THEN
        	LET r_detalle[i].stock_loc = r_detalle[i].stock_loc - cant_prof
	END IF
	-- OJO REVISAR ***NPC
	IF r_detalle[i].r22_bodega <> vm_bod_sstock THEN
		LET dias_trans = TODAY - DATE(rm_r21.r21_fecing)
		IF (rm_r21.r21_cod_tran IS NULL) AND
		   NOT (rm_r00.r00_dias_prof < dias_trans OR
			rm_r00.r00_dias_prof = 0)
		THEN
			IF r_detalle[i].stock_loc > 0 AND 
			   r_detalle[i].r22_cantidad > r_detalle[i].stock_loc
			THEN
				LET r_detalle[i].r22_cantidad =
							r_detalle[i].stock_loc
				LET r_detalle[i].subtotal_item =
							r_r22.r22_precio *
						       r_detalle[i].r22_cantidad
			END IF		
		END IF		
	END IF		
	--- VALIDACIÓN DE VENTA SIN STOCK              
	LET stock = r_detalle[i].r22_cantidad - r_detalle[i].stock_loc	
	IF rm_r21.r21_cod_tran IS NULL THEN
		IF stock > 0 AND r_detalle[i].r22_bodega <> vm_bod_sstock THEN
			LET r_detalle[i].r22_bodega = vm_bod_sstock
		END IF         
	END IF
END FOR
IF vm_ind_arr < vm_size_arr THEN
	LET vm_size_arr = vm_ind_arr
END IF
IF cambiar_precio THEN
	CALL calcula_totales(vm_num_detalles, 0)   
END IF

IF num_args() = 6 THEN
	RETURN
END IF
FOR i = 1 TO vm_size_arr 
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR
CALL muestra_etiquetas_det(0, vm_ind_arr, 1)

END FUNCTION



FUNCTION retorna_stock_item(codcia, bodega, codigo)
DEFINE codcia		LIKE rept021.r21_compania
DEFINE codigo		LIKE rept022.r22_item
DEFINE bodega, bode	LIKE rept011.r11_bodega
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE stock_tot	DECIMAL (8,2)
DEFINE stock_loc	DECIMAL (8,2)

DECLARE q_barc CURSOR FOR 
	SELECT * FROM rept011
		WHERE r11_compania = codcia AND 
		      r11_item     = codigo	
		ORDER BY r11_stock_act DESC
LET stock_tot = 0
LET stock_loc = 0
LET bode      = bodega
LET bodega    = NULL
FOREACH q_barc INTO r_r11.*
	CALL fl_lee_bodega_rep(codcia, r_r11.r11_bodega) RETURNING r_r02.*
	IF r_r02.r02_tipo = 'S' OR r_r02.r02_area = 'T' OR
	  (r_r02.r02_tipo_ident <> 'V' AND r_r02.r02_tipo_ident <> 'X' AND
	   r_r02.r02_tipo_ident <> 'E')
	THEN
		CONTINUE FOREACH
	END IF
	IF r_r02.r02_localidad = vg_codloc THEN
		LET stock_loc = stock_loc + r_r11.r11_stock_act
		IF r_r11.r11_stock_act > 0 AND r_r02.r02_factura = 'S' THEN
			LET bodega = r_r11.r11_bodega	
		END IF
	ELSE
		LET stock_tot = stock_tot + r_r11.r11_stock_act
	END IF		           
END FOREACH
IF bodega IS NULL THEN
	LET bodega  = vm_bod_sstock
END IF
{
IF bodega IS NULL THEN
	LET bodega = rm_r00.r00_bodega_fact
	CALL fl_lee_stock_rep(codcia, bodega, codigo)
       		RETURNING r_r11.*                    
	IF r_r11.r11_stock_act IS NULL THEN          
       		LET r_r11.r11_stock_act = 0          
	END IF                                       
	LET stock_loc = r_r11.r11_stock_act
END IF                                       
}
RETURN bodega, stock_tot, stock_loc

END FUNCTION



FUNCTION muestra_stock_local_nacional(l, codigo, flag)
DEFINE l, flag		SMALLINT
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE tot_stock_loc	DECIMAL (8,2)
DEFINE tot_stock_rem	DECIMAL (8,2)
DEFINE tot_stock_gen 	DECIMAL (8,2)
DEFINE i, salir		SMALLINT
DEFINE row_ini		SMALLINT

CALL fl_lee_item(vg_codcia, codigo) RETURNING r_r10.*
IF r_r10.r10_compania IS NULL THEN
	RETURN
END IF
LET row_ini = 3
IF vg_gui = 0 THEN
	LET row_ini = 2
END IF
OPEN WINDOW w_stln AT row_ini, 31 WITH 21 ROWS, 48 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN                                                              
	OPEN FORM f_220_4 FROM '../forms/repf220_4'
ELSE
	OPEN FORM f_220_4 FROM '../forms/repf220_4c'
END IF
DISPLAY FORM f_220_4
CALL mostrar_cabecera_bodegas_ln()
DISPLAY BY NAME codigo, r_r10.r10_nombre
DECLARE q_eme CURSOR FOR                       
	SELECT * FROM rept011                   
		WHERE r11_compania = vg_codcia AND 
		      r11_item     = codigo	
		ORDER BY r11_stock_act DESC, r11_bodega
LET i_loc = 0
LET i_rem = 0
LET tot_stock_loc = 0
LET tot_stock_rem = 0
FOREACH q_eme INTO r_r11.*
	CALL fl_lee_bodega_rep(vg_codcia, r_r11.r11_bodega)
		RETURNING r_r02.*
	IF r_r02.r02_tipo = 'S' OR r_r02.r02_tipo_ident = 'C' OR
	   r_r02.r02_tipo_ident = 'R'
	THEN
		CONTINUE FOREACH
	END IF
        IF r_r02.r02_localidad = vg_codloc THEN   
		LET i_loc = i_loc + 1
		LET r_loc[i_loc].bod_loc     = r_r11.r11_bodega
		LET r_loc[i_loc].nom_bod_loc = r_r02.r02_nombre
		LET r_loc[i_loc].stock_loc   = r_r11.r11_stock_act
        	LET tot_stock_loc          = tot_stock_loc + r_r11.r11_stock_act
		INSERT INTO temp_loc VALUES (r_loc[i_loc].*)
        ELSE	
        	LET i_rem = i_rem + 1
        	LET r_rem[i_rem].bod_rem     = r_r11.r11_bodega
        	LET r_rem[i_rem].nom_bod_rem = r_r02.r02_nombre
        	LET r_rem[i_rem].stock_rem   = r_r11.r11_stock_act
        	LET tot_stock_rem          = tot_stock_rem + r_r11.r11_stock_act
		INSERT INTO temp_rem VALUES (r_rem[i_rem].*)
        END IF		                                             
END FOREACH
IF i_loc = 0 AND i_rem = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_stln
	LET int_flag = 0
	RETURN
END IF
LET tot_stock_gen = tot_stock_loc + tot_stock_rem
FOR i = 1 TO fgl_scr_size('r_loc')
	IF i > i_loc THEN
		EXIT FOR
	END IF
	DISPLAY r_loc[i].* TO r_loc[i].*
END FOR
FOR i = 1 TO fgl_scr_size('r_rem')      
	IF i > i_rem THEN               
		EXIT FOR                
	END IF                          
	DISPLAY r_rem[i].* TO r_rem[i].*
END FOR                            
DISPLAY BY NAME tot_stock_loc, tot_stock_rem, tot_stock_gen
LET salir = 0
IF i_loc > 0 THEN
	CALL control_detalle_bodega_loc(l, flag) RETURNING salir
END IF
IF i_rem > 0 AND salir = 0 THEN
	CALL control_detalle_bodega_rem(l, flag) RETURNING salir
END IF
DELETE FROM temp_loc
DELETE FROM temp_rem
CLOSE WINDOW w_stln
LET int_flag = 0

END FUNCTION



FUNCTION control_detalle_bodega_loc(l, flag)
DEFINE l, flag		SMALLINT
DEFINE i, j, salir	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_loc ',
			'ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
				vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE loc FROM query
	DECLARE q_loc CURSOR FOR loc 
	LET i = 1
	FOREACH q_loc INTO r_loc[i].*
		LET i = i + 1
		IF i > i_loc THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(1, i_loc, 0, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_loc TO r_loc.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
        	        EXIT DISPLAY  
        	ON KEY(RETURN)   
			LET i = arr_curr()
			CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
			IF flag THEN
				LET salir = 1
				LET r_detalle[l].r22_bodega = r_loc[i].bod_loc
        		        EXIT DISPLAY  
			END IF
		ON KEY(F1,CONTROL-W) 
			CALL control_visor_teclas_caracter_3() 
		ON KEY(F5)
			IF i_rem > 0 THEN
				CALL muestra_contadores_det_tot(0, i_loc, 1,
								i_rem)
				CALL control_detalle_bodega_rem(l, flag)
					RETURNING salir
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel("F1","") 
			--#IF i_rem > 0 THEN
				--#CALL dialog.keysetlabel("F5","Remotas") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
			--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(i, i_loc, 0, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY
	IF salir = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
RETURN salir

END FUNCTION 



FUNCTION control_detalle_bodega_rem(l, flag)
DEFINE l, flag		SMALLINT
DEFINE i, j, salir 	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 3
LET vm_columna_1 = col
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_rem ',
			'ORDER BY ',
				vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
				vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE rem FROM query
	DECLARE q_rem CURSOR FOR rem 
	LET i = 1
	FOREACH q_rem INTO r_rem[i].*
		LET i = i + 1
		IF i > i_rem THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	LET salir = 0
	CALL muestra_contadores_det_tot(0, i_loc, 1, i_rem)
	CALL set_count(i)
	DISPLAY ARRAY r_rem TO r_rem.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
	                EXIT DISPLAY  
		ON KEY(RETURN)
			LET i = arr_curr()	
			LET j = scr_line()
			CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
        	ON KEY(F1,CONTROL-W) 
			CALL control_visor_teclas_caracter_4() 
		ON KEY(F5)
			IF i_loc > 0 THEN
				CALL muestra_contadores_det_tot(1, i_loc, 0,
								i_rem)
				CALL control_detalle_bodega_loc(l, flag)
					RETURNING salir
				IF salir = 1 THEN
					EXIT DISPLAY
				END IF
			END IF
		ON KEY(F18)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET col = 3
			EXIT DISPLAY
	        --#BEFORE DISPLAY 
	                --#CALL dialog.keysetlabel('ACCEPT', '')   
			--#CALL dialog.keysetlabel("F1","") 
			--#IF i_loc > 0 THEN
				--#CALL dialog.keysetlabel("F5","Locales") 
			--#ELSE
				--#CALL dialog.keysetlabel("F5","") 
			--#END IF
				--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#BEFORE ROW 
			--#LET i = arr_curr()	
			--#LET j = scr_line()
			--#CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
	        --#AFTER DISPLAY  
	                --#CONTINUE DISPLAY  
	END DISPLAY 
	IF salir = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
RETURN salir

END FUNCTION 



FUNCTION muestra_contadores_det_tot(num_row_l, max_row_l, num_row_r, max_row_r)
DEFINE num_row_l, max_row_l	SMALLINT
DEFINE num_row_r, max_row_r	SMALLINT

DISPLAY BY NAME num_row_l, max_row_l, num_row_r, max_row_r

END FUNCTION 



FUNCTION mostrar_cabecera_bodegas_ln()

IF vg_gui = 1 THEN
	DISPLAY 'BD'			TO tit_col1
	DISPLAY 'Bodegas Locales'	TO tit_col2
	DISPLAY 'Stock'			TO tit_col3
	DISPLAY 'BD'			TO tit_col4
	DISPLAY 'Bodegas Remotas'	TO tit_col5
	DISPLAY 'Stock'			TO tit_col6
END IF

END FUNCTION 



FUNCTION retorna_descto_maximo_item(codcia, cod_util)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE cod_util		LIKE rept010.r10_cod_util
DEFINE r_r77		RECORD LIKE rept077.*

SELECT * INTO r_r77.* FROM rept077
	WHERE r77_compania    = codcia AND 
	      r77_codigo_util = cod_util
IF status = NOTFOUND THEN
	RETURN 0, 0
END IF
IF rm_vend.r01_compania IS NULL AND rm_g05.g05_tipo = 'AG' THEN
	RETURN r_r77.r77_dscmax_ger, r_r77.r77_dscmax_ven
END IF
IF rm_vend.r01_compania IS NULL AND rm_g05.g05_tipo = 'AM' THEN
	RETURN r_r77.r77_dscmax_jef, r_r77.r77_dscmax_ven
END IF
IF rm_vend.r01_tipo = 'J' THEN
	RETURN r_r77.r77_dscmax_jef, r_r77.r77_dscmax_ven
END IF
IF rm_vend.r01_tipo = 'G' THEN
	RETURN r_r77.r77_dscmax_ger, r_r77.r77_dscmax_ven
END IF
RETURN r_r77.r77_dscmax_ven, r_r77.r77_dscmax_ven

END FUNCTION



FUNCTION control_DISPLAY_botones()

--#DISPLAY 'Item' 		TO tit_col1
--#DISPLAY 'E.N.' 		TO tit_col2
--#DISPLAY 'E.L.' 		TO tit_col3
--#DISPLAY 'Cantidad'		TO tit_col4
--#DISPLAY 'Bd'			TO tit_col5
--#DISPLAY 'Desc.'		TO tit_col6
--#DISPLAY 'Precio Unit.'	TO tit_col7
--#DISPLAY 'Subtotal'		TO tit_col8

END FUNCTION    



FUNCTION muestra_contadores()     

IF vg_gui = 1 THEN 
	DISPLAY "" AT 1,1
	DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 67 
END IF

END FUNCTION 



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER
DEFINE r_r23		RECORD LIKE rept023.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r21.* FROM rept021 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF
LET vm_impuesto = rm_r21.r21_tot_neto - rm_r21.r21_flete - 
		  (rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto)
	---PARA MOSTRAR LA CABECERA-----
DISPLAY BY NAME rm_r21.r21_numprof, rm_r21.r21_vendedor, rm_r21.r21_tot_neto,  
		rm_r21.r21_fecing,  rm_r21.r21_moneda,   rm_r21.r21_porc_impto,
		rm_r21.r21_codcli,  rm_r21.r21_nomcli,   rm_r21.r21_dircli,
		rm_r21.r21_cedruc,  
		rm_r21.r21_dias_prof,
		rm_r21.r21_tot_bruto,  rm_r21.r21_telcli,
		rm_r21.r21_tot_dscto,  vm_impuesto,       
		rm_r21.r21_referencia, 
		rm_r21.r21_forma_pago, rm_r21.r21_atencion,
		rm_r21.r21_flete, rm_r21.r21_cod_tran, rm_r21.r21_num_tran 
CALL retorna_preventa() RETURNING r_r23.r23_numprev
DISPLAY BY NAME r_r23.r23_numprev
CALL muestra_etiquetas()
CALL muestra_contadores()
CALL muestra_detalle()

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

CALL fl_lee_moneda(rm_r21.r21_moneda)
	RETURNING rm_g13.*
	DISPLAY rm_g13.g13_nombre TO nom_moneda
CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
	RETURNING rm_r01.*
	DISPLAY rm_r01.r01_nombres TO nom_vendedor

END FUNCTION



FUNCTION retorna_tam_arr()

IF num_args() <> 6 THEN
	LET vm_size_arr = fgl_scr_size('r_detalle') 
END IF
{
IF vg_gui = 0 THEN 
	LET vm_size_arr = 3
END IF 
}

END FUNCTION  



FUNCTION control_actualizacion_caja()
DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_upd		RECORD LIKE cajt010.*

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
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF

IF STATUS <> NOTFOUND THEN
	DELETE FROM cajt011 
		WHERE j11_compania    = r_j10.j10_compania 
		  AND j11_localidad   = r_j10.j10_localidad 
		  AND j11_tipo_fuente =	r_j10.j10_tipo_fuente 
		  AND j11_num_fuente  =	r_j10.j10_num_fuente 
	DELETE FROM cajt010 WHERE CURRENT OF q_j10
END IF
CLOSE q_j10
FREE  q_j10

INITIALIZE r_j10.* TO NULL

CALL fl_lee_grupo_linea(vg_codcia, rm_r23.r23_grupo_linea)
	RETURNING rm_g20.*

LET r_j10.j10_areaneg   = rm_g20.g20_areaneg
LET r_j10.j10_codcli    = rm_r23.r23_codcli
LET r_j10.j10_nomcli    = rm_r23.r23_nomcli
LET r_j10.j10_moneda    = rm_r23.r23_moneda

IF rm_r23.r23_cont_cred = 'R' THEN
	LET r_j10.j10_valor = 0
ELSE
	LET r_j10.j10_valor = rm_r23.r23_tot_neto 
END IF

LET r_j10.j10_fecha_pro   = CURRENT
LET r_j10.j10_usuario     = vg_usuario 
LET r_j10.j10_fecing      = CURRENT
LET r_j10.j10_compania    = vg_codcia
LET r_j10.j10_localidad   = vg_codloc
LET r_j10.j10_tipo_fuente = 'PR'
LET r_j10.j10_num_fuente  = rm_r23.r23_numprev
LET r_j10.j10_estado      = 'A'

INSERT INTO cajt010 VALUES(r_j10.*)

RETURN done

END FUNCTION



FUNCTION mensaje_intentar()
DEFINE intentar         SMALLINT
DEFINE resp             CHAR(6)
                                                                                
LET intentar = 1
--CALL fgl_winquestion(vg_producto,'Registro bloqueado por otro usuario, desea intentarlo nuevamente','No','Yes|No','question',1)
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
	RETURNING resp
IF resp = 'No' THEN
	LET intentar = 0
END IF
                                                                                
RETURN intentar
                                                                                
END FUNCTION



FUNCTION control_crear_cliente()
DEFINE command_run	VARCHAR(100)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', 
	           vg_separador, 'fuentes', vg_separador, run_prog,
		   'cxcp101 ', vg_base, ' ','CO', ' ',vg_codcia, ' ',
		   vg_codloc
RUN command_run

END FUNCTION



FUNCTION control_crear_item()
DEFINE command_run	VARCHAR(100)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	           vg_separador, 'fuentes', vg_separador, run_prog,
		   'repp108 ', vg_base, ' ','RE', ' ',vg_codcia,' ',vg_codloc
RUN command_run

END FUNCTION



FUNCTION control_ver_item(item)
DEFINE item 		LIKE rept010.r10_codigo
DEFINE command_run	VARCHAR(100)
DEFINE run_prog		CHAR(10)

IF item IS NULL THEN
	RETURN
END IF

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	           vg_separador, 'fuentes', vg_separador, run_prog,
		   'repp108 ', vg_base, ' ','RE', ' ',vg_codcia, ' ',
		   ' ', vg_codloc, ' ', item
RUN command_run

END FUNCTION



FUNCTION valida_cliente_consumidor_final(codcli)
DEFINE codcli		LIKE cxct021.z21_codcli
DEFINE mensaje		VARCHAR(200)

LET mensaje = 'El código de cliente que usted digitó ',       
	'solo puede ser usado para ventas contado menores o ',
	'iguales a: ',                                        
        rm_r00.r00_valmin_ccli USING '##,##&.##'              
IF codcli = rm_r00.r00_codcli_tal THEN 
	IF rm_r21.r21_tot_neto > rm_r00.r00_valmin_ccli THEN
		CALL fl_mostrar_mensaje(mensaje,'exclamation')          
		RETURN 0
	END IF
END IF
LET mensaje = 'El código de cliente es obligatorio para ventas ',       
	      'contado mayores a: ',
	      rm_r00.r00_valmin_ccli USING '##,##&.##'
IF codcli IS NULL AND rm_r00.r00_codcli_tal IS NULL THEN 
	IF rm_r21.r21_tot_neto > rm_r00.r00_valmin_ccli THEN
		CALL fl_mostrar_mensaje(mensaje,'exclamation')          
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION  



FUNCTION mensaje_codcli_obligatorio()
DEFINE mensaje		VARCHAR(200)

LET mensaje = 'El código del cliente es obligatorio. Recuerde que si ',
	      'la venta es <= a ', 
	      rm_r00.r00_valmin_ccli USING '##,##&.##',
	      ', puede usar el código de Consumidor Final: ', 
	      rm_r00.r00_codcli_tal USING '<<<<<#'
CALL fl_mostrar_mensaje(mensaje, 'exclamation')

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION retorna_preventa()
DEFINE r_r23		RECORD LIKE rept023.*

INITIALIZE r_r23.* TO NULL
DECLARE q_mos_r23 CURSOR FOR
	SELECT * FROM rept023
		WHERE r23_compania  = vg_codcia
		  AND r23_localidad = vg_codloc
		  AND r23_numprof   = rm_r21.r21_numprof
		ORDER BY r23_fecing DESC
OPEN q_mos_r23
FETCH q_mos_r23 INTO r_r23.*
CLOSE q_mos_r23
FREE q_mos_r23
RETURN r_r23.r23_numprev

END FUNCTION



FUNCTION retorna_bodega_localidad(codcia, codloc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE r_b40		RECORD LIKE ctbt040.*
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE mensaje		VARCHAR(80)
DEFINE cont		SMALLINT

DECLARE qu_bolo CURSOR FOR
	SELECT r02_codigo
		FROM rept002
		WHERE r02_compania   = codcia
		  AND r02_localidad  = codloc
		  AND r02_estado     = 'A'
		  AND r02_tipo       = 'F'
		  AND r02_factura    = 'S'
		  AND r02_area       = 'R'
		  AND r02_tipo_ident = 'V'
		ORDER BY 1
LET cont = 0
FOREACH qu_bolo INTO bodega
	IF codloc = 2 OR codloc = 4 THEN
		LET cont = cont + 1
		EXIT FOREACH
	END IF
	CALL fl_lee_auxiliares_ventas(codcia, codloc, vg_modulo, bodega,
					rm_r21.r21_grupo_linea,
					rm_r21.r21_porc_impto)
		RETURNING r_b40.*
	IF r_b40.b40_compania IS NOT NULL THEN
		LET cont = cont + 1
		EXIT FOREACH
	END IF
END FOREACH
IF cont = 0 THEN
	LET mensaje = 'No existe bodega física para localidad: ',
			codloc USING "&&"
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
RETURN bodega

END FUNCTION



FUNCTION retorna_precio_validez_item()
DEFINE dias_trans	INTEGER

IF rm_r21.r21_cod_tran IS NULL THEN
	LET dias_trans = TODAY - DATE(rm_r21.r21_fecing)
	IF rm_r00.r00_dias_prof < dias_trans OR rm_r00.r00_dias_prof = 0 THEN
		RETURN 1
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_etiquetas_det(i, ind1, ind2)
DEFINE i, ind1, ind2	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

CALL muestra_contadores_det(i, ind1)
CALL fl_lee_item(vg_codcia, r_detalle[ind2].r22_item) RETURNING r_r10.*  
CALL muestra_descripciones(r_detalle[ind2].r22_item, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
DISPLAY r_r10.r10_nombre TO nom_item 

END FUNCTION



FUNCTION control_correo_electronico()
DEFINE r_mail		RECORD
				remitente		VARCHAR(50),
				enviar_a		VARCHAR(50),
				asunto			VARCHAR(50),
				mensaje_m		VARCHAR(200)
			END RECORD
DEFINE row_ini		SMALLINT
DEFINE proforma		VARCHAR(30)
DEFINE comando		CHAR(400)

LET row_ini = 8
IF vg_gui = 0 THEN
	LET row_ini = 7
END IF
OPEN WINDOW w_mail AT row_ini, 09 WITH 11 ROWS, 64 COLUMNS
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
IF vg_gui = 1 THEN                                                              
	OPEN FORM f_220_5 FROM '../forms/repf220_5'
ELSE
	OPEN FORM f_220_5 FROM '../forms/repf220_5c'
END IF
DISPLAY FORM f_220_5
LET int_flag = 0
INPUT BY NAME r_mail.*
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_mail
	LET int_flag = 0
	RETURN
END IF
LET proforma = 'prof', rm_r21.r21_numprof USING "<<<<<<<<<<&", '_1.txt'
LET comando  = '> ', proforma CLIPPED
RUN comando
LET comando = 'echo "<html> <head> <title>Untitled Document</title> ',
		'<meta http-equiv="Content-Type" content="text/html; ',
		'charset=iso-8859-1"> </head> <body> <p><font size="3" ',
		'face="Courier New, Courier, mono"> " >> ', proforma CLIPPED
RUN comando
LET comando  = 'echo ', r_mail.enviar_a CLIPPED, ' >> ', proforma CLIPPED
RUN comando
LET comando  = 'echo " "', ' >> ', proforma CLIPPED
RUN comando
LET comando  = 'echo ', r_mail.mensaje_m CLIPPED, ' >> ', proforma CLIPPED
RUN comando
CALL control_imprimir_proforma(2)
LET comando  = 'cat ', proforma CLIPPED, ' prof', rm_r21.r21_numprof
		USING "<<<<<<<<<<&", '_2.txt > ',
		'prof', rm_r21.r21_numprof USING "<<<<<<<<<<&", '.txt'
RUN comando
LET comando = 'echo " </font></p> </body> </html>" >> ',
		'prof', rm_r21.r21_numprof USING "<<<<<<<<<<&", '.txt'
RUN comando
LET comando  = 'mail -s ', r_mail.asunto CLIPPED, ' fobos@acero.com < ',
		'prof', rm_r21.r21_numprof USING "<<<<<<<<<<&", '.txt'
CALL fl_mostrar_mensaje('Proforma Enviada Ok.', 'info')
RUN comando
LET comando = 'rm -rf ', proforma CLIPPED, ' prof', rm_r21.r21_numprof
		USING "<<<<<<<<<<&", '_2.txt ',
		'prof', rm_r21.r21_numprof USING "<<<<<<<<<<&", '.txt'
RUN comando
CLOSE WINDOW w_mail
LET int_flag = 0

END FUNCTION



FUNCTION validar_item_importacion_sin_stock(i)
DEFINE i		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r17		RECORD LIKE rept017.*
DEFINE fecing		LIKE rept016.r16_fecing

CALL fl_lee_bodega_rep(vg_codcia, r_detalle[i].r22_bodega) RETURNING r_r02.*
IF r_r02.r02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')
	RETURN 0
END IF
IF r_r02.r02_tipo <> 'S' THEN
	RETURN 1
END IF
INITIALIZE r_r17.* TO NULL
DECLARE q_r17 CURSOR FOR
	SELECT r16_fecing, rept017.* FROM rept016, rept017
		WHERE r16_compania  = vg_codcia
		  AND r16_localidad = vg_codloc
		  AND r17_compania  = r16_compania
		  AND r17_localidad = r16_localidad
		  AND r17_pedido    = r16_pedido
		  AND r17_item      = r_detalle[i].r22_item
		  AND r17_estado    IN ("R", "L")
		ORDER BY r16_fecing DESC
OPEN q_r17
FETCH q_r17 INTO fecing, r_r17.*
CLOSE q_r17
FREE q_r17
IF r_r17.r17_compania IS NULL THEN
	RETURN 1
END IF
CALL fl_mostrar_mensaje('El Item ' || r_detalle[i].r22_item[1, 7] CLIPPED || ' esta en proceso de importación del pedido No. ' || r_r17.r17_pedido CLIPPED || ' y por lo tanto no puede proformarlo con la bodega SIN STOCK. Hagalo con una bodega Física de Facturación.', 'exclamation')
RETURN 0

END FUNCTION



FUNCTION control_ver_ec_cliente()
DEFINE comando          VARCHAR(250)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
		vg_separador, 'fuentes', vg_separador, run_prog,' cxcp314 ',
		vg_base, ' "CO" ', vg_codcia, ' ', vg_codloc, ' ',
		rm_r21.r21_moneda, ' ', DATE(TODAY), ' "T" 0.01 ',
		'"N" ', vg_codloc, ' ', rm_r21.r21_codcli
RUN comando

END FUNCTION



FUNCTION enviar_mail()
DEFINE err_flag, varex	INTEGER
DEFINE comando		CHAR(256)

--LET comando = 'sendprof.exe ', rm_r21.r21_numprof USING "<<<<<<&"
--LET comando = "cmd /C start /B firefox -new-window \"http://www.sony.com\""
--LET comando = "cmd /C start /B firefox -new-window """"http://192.168.4.1:8080/pentaho/content/reporting?renderMode=report&output-type=application/pdf&output-target=pageable/pdf&solution=steel-wheels&path=/&name=Proforma2010.prpt&numero="""""
		--rm_r21.r21_numprof USING "<<<<<<&", """"
--LET comando = 'cmd /C "start firefox"'
--CALL WinExec(comando) RETURNING err_flag
--LET comando = 'cmd /C start iexplore -new'
--LET varex = WinExec(comando)
--IF vg_usuario = 'HSALAZAR' THEN
--	LET comando = "proforma.jsp?numero=", rm_r21.r21_numprof USING "<<<<<<&"
--	CALL fl_ejecuta_reporte_pdf(vg_codloc, comando, 'F')
--ELSE
	--#LET comando = 'sendprof.exe ', rm_r21.r21_numprof USING "<<<<<<&"
	--#CALL WinExec(comando) RETURNING err_flag
--END IF

END FUNCTION



FUNCTION generar_pdf()
DEFINE comando		CHAR(256)

LET comando = "proforma.jsp?numero=", rm_r21.r21_numprof USING "<<<<<<&"
CALL fl_ejecuta_reporte_pdf(vg_codloc, comando, 'F')

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
DISPLAY '<F5>      Crear Cliente'            AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F6>      Crear Item'               AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Ver Item'                 AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Stock Total'              AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F9>      Subtotal Neto'            AT a,2
DISPLAY  'F9' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_3() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Bodegas Remotas'          AT a,2
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
DISPLAY '<F5>      Bodegas Locales'          AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_5() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Stock Total'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Imprimir'                 AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Enviar Mail'              AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      PDF'                      AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
