--------------------------------------------------------------------------------
-- Titulo           : talp213.4gl - Mantenimiento de Proforma de Taller
-- Elaboracion      : 28-Feb-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp213 base modulo compania localidad
--                    [numprof]
--                    [ord_trabajo o num_presup] [tipo = 'O' ó 'P']
--                    [numprof] [A]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE r_detalle	ARRAY[100] OF RECORD                        
				r22_bodega	LIKE rept022.r22_bodega,
				r22_item	LIKE rept022.r22_item,
				stock_tot	DECIMAL (8,2),
				stock_loc	DECIMAL (8,2),
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
DEFINE vm_rows		ARRAY[4000] OF INTEGER	-- ARREGLO DE ROWID DE FILAS
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
DEFINE vm_bod_taller		LIKE rept002.r02_codigo
DEFINE vm_size_arr		SMALLINT
DEFINE vm_flag_mant 		CHAR(1)
DEFINE vm_flag_vendedor		CHAR(1)
DEFINE vm_ind_arr		SMALLINT
DEFINE vm_total			DECIMAL(12,2)
DEFINE vm_costo			DECIMAL(12,2)
DEFINE vm_subtotal		DECIMAL(12,2)
DEFINE vm_descuento		DECIMAL(12,2)
DEFINE vm_impuesto		DECIMAL(12,2)
DEFINE vm_presup_ori 		LIKE rept021.r21_num_presup
DEFINE vm_valor_ori  		DECIMAL(12,2)
DEFINE i_loc, i_rem		SMALLINT
DEFINE r_loc			ARRAY[50] OF RECORD
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
DEFINE vm_validar_stock		SMALLINT
DEFINE rm_dettrans	ARRAY[100] OF RECORD
				r19_num_tran	LIKE rept019.r19_num_tran,
				r19_bodega_ori	LIKE rept019.r19_bodega_ori,
				r19_bodega_dest	LIKE rept019.r19_bodega_dest,
				r19_referencia	LIKE rept019.r19_referencia
			END RECORD
DEFINE rm_detorddes	ARRAY[100] OF RECORD
				r34_num_ord_des	LIKE rept034.r34_num_ord_des,
				r34_bodega	LIKE rept034.r34_bodega,
				r34_fec_entrega	LIKE rept034.r34_fec_entrega,
				r34_entregar_a	LIKE rept034.r34_entregar_a
			END RECORD
DEFINE vm_max_transf	SMALLINT
DEFINE vm_num_transf	SMALLINT
DEFINE vm_cur_transf	SMALLINT
DEFINE vm_max_orddes	SMALLINT
DEFINE vm_num_orddes	SMALLINT
DEFINE vm_cur_orddes	SMALLINT



MAIN

DEFER QUIT                                                                      
DEFER INTERRUPT                                                                 
CLEAR SCREEN                                                                    
CALL startlog('../logs/talp213.err')
--#CALL fgl_init4js()                                                           
CALL fl_marca_registrada_producto()                                             
IF num_args() <> 4 AND num_args() <> 5 AND num_args() <> 6 THEN   
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')      
	EXIT PROGRAM                                                            
END IF                                                                          
LET vg_base    = arg_val(1)                                                    
LET vg_modulo  = arg_val(2)                                                    
LET vg_codcia  = arg_val(3)                                                    
LET vg_codloc  = arg_val(4)                                                    
LET vm_numprof = arg_val(5)                                                    
LET vg_proceso = 'talp213'                                                      
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
IF num_args() = 4 OR (num_args() = 6 AND arg_val(6) = 'A') THEN
	CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag
	IF int_flag THEN
		RETURN
	END IF
	CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag
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
LET vm_validar_stock = 1	-- VALIDA EL STOCK S/N (0/1) EN PRESUPUESTO
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
LET vm_flag_calculo_impto = 'B'                                                 
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_vd 
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
IF STATUS = NOTFOUND THEN
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
IF num_args() = 6 AND arg_val(6) = 'A' THEN
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
OPEN WINDOW w_213 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS            
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN                                                              
	OPEN FORM f_213 FROM '../forms/talf213_1'                               
ELSE                                                                           
	OPEN FORM f_213 FROM '../forms/talf213_1c'                              
END IF                                                                          
DISPLAY FORM f_213                                                              
CALL control_DISPLAY_botones()                                                  
CALL retorna_tam_arr()        
LET vm_num_rows    = 0           
LET vm_row_current = 0        
INITIALIZE rm_r21.*, vm_bod_taller TO NULL                                      
SELECT r02_codigo INTO vm_bod_taller
	FROM rept002                               
	WHERE r02_compania  = vg_codcia                                 
	  AND r02_localidad = vg_codloc
	  AND r02_estado    = "A"                                      
	  AND r02_area      = "T"                                       
	  AND r02_factura   = "S"                                       
	  AND r02_tipo      = "L"                                       
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay bodega lógica de facturacion de Taller configurada.','stop') 
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
		HIDE OPTION 'Transf/Orden'
		HIDE OPTION 'Imprimir'                                          
		IF num_args() >= 5 THEN
			HIDE OPTION 'Modificar'                                 
			HIDE OPTION 'Ingresar'                                  
			HIDE OPTION 'Consultar'                                 
			SHOW OPTION 'Transf/Orden'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Ver Detalle'
			CALL control_consulta()                                 
			CALL control_ver_detalle()
                	IF vm_num_rows > 1 THEN 
                        	SHOW OPTION 'Avanzar'   
			ELSE
				EXIT PROGRAM
			END IF
                END IF                           
                IF vm_row_current <= 1 THEN     
                        HIDE OPTION 'Retroceder'
		END IF                                                          
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'    
                CALL control_ingreso()                                          
		IF vm_num_rows >= 1 THEN                                        
			SHOW OPTION 'Modificar'                                
			SHOW OPTION 'Ver Detalle'                               
			SHOW OPTION 'Hacer Preventa'                            
			SHOW OPTION 'Transf/Orden'
			SHOW OPTION 'Imprimir'                                  
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
			SHOW OPTION 'Transf/Orden'
			SHOW OPTION 'Imprimir'   
                        HIDE OPTION 'Avanzar'   
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Imprimir'
                        	HIDE OPTION 'Modificar'
				HIDE OPTION 'Ver Detalle'
				HIDE OPTION 'Hacer Preventa'
				HIDE OPTION 'Transf/Orden'
                        END IF 
                ELSE          
			SHOW OPTION 'Imprimir'   
			SHOW OPTION 'Hacer Preventa' 
                        SHOW OPTION 'Ver Detalle'   
                        SHOW OPTION 'Modificar'    
			SHOW OPTION 'Transf/Orden'
                        SHOW OPTION 'Avanzar'     
                END IF                           
                IF vm_row_current <= 1 THEN     
                        HIDE OPTION 'Retroceder'
                END IF
       	COMMAND KEY('T') 'Transf/Orden' 'Muestra Transferencias y Ordenes de Despacho.'
		CALL control_transf_orddes()
	COMMAND KEY('K') 'Imprimir'
		IF rm_r21.r21_numprof IS NOT NULL THEN 
			CALL control_imprimir_proforma()
		END IF
        COMMAND KEY('D') 'Ver Detalle'   'Muestra anteriores detalles.'
		IF vm_num_rows > 0 THEN
			CALL control_ver_detalle()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('A') 'Avanzar' 		'Ver siguiente registro.'
		CALL siguiente_registro()  
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Ver Detalle'
			IF num_args() = 4 THEN
				SHOW OPTION 'Hacer Preventa'
				SHOW OPTION 'Modificar'
			END IF
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			SHOW OPTION 'Ver Detalle'  
			IF num_args() = 4 THEN
				SHOW OPTION 'Hacer Preventa'
				SHOW OPTION 'Modificar'
			END IF
		END IF 
	COMMAND KEY('R') 'Retroceder' 		'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder' 
			SHOW OPTION 'Ver Detalle'  
			SHOW OPTION 'Avanzar'   
			NEXT OPTION 'Avanzar'  
			IF num_args() = 4 THEN
				SHOW OPTION 'Hacer Preventa'
				SHOW OPTION 'Modificar'   
			END IF
		ELSE 
			SHOW OPTION 'Ver Detalle'
			SHOW OPTION 'Avanzar'  
			SHOW OPTION 'Retroceder'
			IF num_args() = 4 THEN
				SHOW OPTION 'Hacer Preventa'
				SHOW OPTION 'Modificar' 
			END IF
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
DEFINE r_t60		RECORD LIKE talt060.*

CALL fl_control_status_caja(vg_codcia, vg_codloc, 'P') RETURNING int_flag
IF int_flag <> 0 THEN
	LET int_flag = 0
	RETURN
END IF	
CALL retorna_tam_arr()        
LET vm_num_rows    = 0           
LET vm_row_current = 0        
INITIALIZE rm_r21.*, vm_bod_taller TO NULL                                      
SELECT r02_codigo INTO vm_bod_taller
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_localidad = vg_codloc
	  AND r02_estado    = "A"
	  AND r02_area      = "T"
	  AND r02_factura   = "S"
	  AND r02_tipo      = "L"
IF vm_bod_taller IS NULL THEN
	CALL fl_mostrar_mensaje('No hay bodega lógica de facturacion del Taller configurada.','stop') 
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
		WHERE r88_compania    = vg_codcia
		  AND r88_localidad   = vg_codloc
		  AND r88_numprof     = rm_r21.r21_numprof
		  AND r88_ord_trabajo = rm_r21.r21_num_ot
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
INITIALIZE r_t60.* TO NULL
DECLARE q_t60 CURSOR FOR
	SELECT * FROM talt060
		WHERE t60_compania  = vg_codcia
		  AND t60_localidad = vg_codloc
		  AND t60_ot_ant    = rm_r21.r21_num_ot
OPEN q_t60
FETCH q_t60 INTO r_t60.*
CLOSE q_t60
FREE q_t60
IF r_t60.t60_ot_nue IS NULL THEN
	CALL fl_mostrar_mensaje('No existe todavía la nueva Orden de Trabajo.', 'stop')
	EXIT PROGRAM
END IF
LET rm_r21.r21_num_ot     = r_t60.t60_ot_nue
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
IF rm_r21.r21_num_ot IS NOT NULL THEN
	CALL genera_transferencia()
	UPDATE rept022
		SET r22_bodega = vm_bod_taller
		WHERE r22_compania  = vg_codcia
		  AND r22_localidad = vg_codloc
		  AND r22_numprof   = rm_r21.r21_numprof 
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
DEFINE total_rp		LIKE talt020.t20_total_rp
DEFINE impto		LIKE talt020.t20_total_impto
DEFINE neto		LIKE talt020.t20_total_neto
DEFINE r_t20		RECORD LIKE talt020.*

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
LET rm_r21.r21_bodega     = rm_r00.r00_bodega_fact 
LET rm_r21.r21_dias_prof  = rm_r00.r00_dias_prof  
LET rm_r21.r21_moneda     = rg_gen.g00_moneda_base
LET rm_r21.r21_porc_impto = rg_gen.g00_porc_impto
LET rm_r21.r21_descuento  = 0.0 
LET rm_r21.r21_flete      = 0 
LET rm_r21.r21_factor_fob = 1   
LET rm_r21.r21_modelo     = '.' 
LET rm_r21.r21_forma_pago = 'A CONVENIR' 
LET rm_r21.r21_vendedor   = rm_vend.r01_codigo
CALL fl_lee_moneda(rg_gen.g00_moneda_base) 	     -- PARA OBTENER EL NOMBRE
	RETURNING rm_g13.*		   	     -- DE LA MONEDA BASE    
LET rm_r21.r21_precision = rm_g13.g13_decimales  
DECLARE qu_gl CURSOR FOR SELECT g20_grupo_linea FROM gent020
	WHERE g20_compania = vg_codcia
OPEN qu_gl 
FETCH qu_gl INTO rm_r21.r21_grupo_linea 
IF STATUS = NOTFOUND THEN                              
	CALL fl_mostrar_mensaje('No hay grupo de línea configurado.','exclamation') 
	IF vm_num_rows = 0 THEN 
		CLEAR FORM     
		CALL control_DISPLAY_botones()
	ELSE	                             
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF            
	RETURN           
END IF                                                                             
DISPLAY BY NAME rm_r21.r21_fecing, rm_r21.r21_moneda, rm_r21.r21_porc_impto
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
IF rm_r21.r21_num_presup IS NOT NULL THEN
	LET total_rp = rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto
	CALL fl_lee_presupuesto_taller(rm_r21.r21_compania,rm_r21.r21_localidad,
					rm_r21.r21_num_presup)
		RETURNING r_t20.*
	LET r_t20.t20_total_rp = r_t20.t20_total_rp + total_rp
	CALL calcular_impto(rm_r21.r21_num_presup, r_t20.t20_total_rp)
		RETURNING impto
	CALL calcular_total(rm_r21.r21_num_presup, r_t20.t20_total_rp)
		RETURNING neto
	UPDATE talt020 SET t20_total_rp     = t20_total_rp + total_rp,
			   t20_total_impto  = impto,
			   t20_total_neto   = neto
		WHERE t20_compania  = rm_r21.r21_compania  AND 
		      t20_localidad = rm_r21.r21_localidad AND 
		      t20_numpre    = rm_r21.r21_num_presup
	CALL recalcula_presupuesto(rm_r21.r21_num_presup)
END IF
IF rm_r21.r21_num_ot IS NOT NULL THEN
	CALL genera_transferencia()
	UPDATE rept022 SET r22_bodega = vm_bod_taller
		WHERE r22_compania  = vg_codcia
		AND   r22_localidad = vg_codloc
		AND   r22_numprof   = rm_r21.r21_numprof 
END IF
COMMIT WORK  
CALL muestra_contadores()
CALL control_imprimir_proforma() 
IF rm_r21.r21_num_ot IS NOT NULL THEN
	CALL imprimir_transferencia()
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION                                                                               


FUNCTION control_modificacion()
DEFINE cliente 		LIKE rept021.r21_codcli
DEFINE r_t20		RECORD LIKE talt020.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE done, i		SMALLINT
DEFINE ord_mod		CHAR(1)
DEFINE impto		LIKE talt020.t20_total_impto
DEFINE neto		LIKE talt020.t20_total_neto
DEFINE flag_bloqueo	SMALLINT

CALL lee_muestra_registro(vm_rows[vm_row_current])
LET ord_mod = 'S'
IF rm_r21.r21_num_ot IS NOT NULL THEN
	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_r21.r21_num_ot)
		RETURNING r_t23.*
	IF r_t23.t23_estado <> 'A' THEN
		CALL fl_mostrar_mensaje('No puede modificar esta proforma porque tiene una orden de trabajo que no esta activa.','exclamation')
		RETURN
	END IF
	LET ord_mod = 'N'
END IF
IF rm_r21.r21_num_presup IS NOT NULL AND rm_r21.r21_num_ot IS NULL THEN
	CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc,
					rm_r21.r21_num_presup)
		RETURNING r_t20.*
	IF r_t20.t20_estado <> 'A' THEN
		CALL fl_mostrar_mensaje('No puede modificar esta proforma porque el presupuesto fue convertido a orden de trabajo.','exclamation')
		RETURN
	END IF
END IF
IF rm_r21.r21_cod_tran IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Esta proforma ya fue facturada, no puede ser modificada.','exclamation')             	
	RETURN
END IF 
LET vm_flag_mant = 'M'
BEGIN WORK  
WHENEVER ERROR CONTINUE
DECLARE q_up2 CURSOR FOR
	SELECT * FROM rept021 
		WHERE r21_compania  = vg_codcia
		AND   r21_localidad = vg_codloc
		AND   r21_numprof   = rm_r21.r21_numprof
	FOR UPDATE
OPEN q_up2 
FETCH q_up2 INTO rm_r21.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP 
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN                   
END IF            
WHENEVER ERROR STOP
LET vm_presup_ori = rm_r21.r21_num_presup
LET vm_valor_ori  = rm_r21.r21_tot_bruto - rm_r21.r21_tot_dscto
LET rm_r21.r21_dias_prof = rm_r00.r00_dias_prof
IF ord_mod = 'S' THEN
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
		IF rm_r21.r21_num_presup = vm_presup_ori THEN
			CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc,
							rm_r21.r21_num_presup)
				RETURNING r_t20.*
			LET r_t20.t20_total_rp = r_t20.t20_total_rp - 
						 vm_valor_ori +
						 rm_r21.r21_tot_bruto -
						 rm_r21.r21_tot_dscto
			CALL calcular_impto(rm_r21.r21_num_presup, r_t20.t20_total_rp) RETURNING impto
			CALL calcular_total(rm_r21.r21_num_presup, r_t20.t20_total_rp) RETURNING neto
			UPDATE talt020 SET t20_total_rp    = r_t20.t20_total_rp,
			   		   t20_total_impto = impto,
			   		   t20_total_neto  = neto
				WHERE t20_compania  = rm_r21.r21_compania  AND 
	      		              t20_localidad = rm_r21.r21_localidad AND 
	      		              t20_numpre    = rm_r21.r21_num_presup
		ELSE
			CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc,
							vm_presup_ori)
				RETURNING r_t20.*
			LET r_t20.t20_total_rp = r_t20.t20_total_rp - 
						 vm_valor_ori
			CALL calcular_impto(vm_presup_ori, r_t20.t20_total_rp) RETURNING impto
			CALL calcular_total(vm_presup_ori, r_t20.t20_total_rp) RETURNING neto
			UPDATE talt020 SET t20_total_rp    = r_t20.t20_total_rp,
			   		   t20_total_impto = impto,
			   		   t20_total_neto  = neto
				WHERE t20_compania  = rm_r21.r21_compania  AND 
	      		              t20_localidad = rm_r21.r21_localidad AND 
	      		              t20_numpre    = vm_presup_ori
			CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc,
							rm_r21.r21_num_presup)
				RETURNING r_t20.*
			LET r_t20.t20_total_rp = r_t20.t20_total_rp + 
				                 rm_r21.r21_tot_bruto -
						 rm_r21.r21_tot_dscto
			CALL calcular_impto(rm_r21.r21_num_presup, r_t20.t20_total_rp) RETURNING impto
			CALL calcular_total(rm_r21.r21_num_presup, r_t20.t20_total_rp) RETURNING neto
			UPDATE talt020 SET t20_total_rp    = r_t20.t20_total_rp,
			   		   t20_total_impto = impto,
			   		   t20_total_neto  = neto
				WHERE t20_compania  = rm_r21.r21_compania  AND 
	      		              t20_localidad = rm_r21.r21_localidad AND 
	      		              t20_numpre    = rm_r21.r21_num_presup
			CALL recalcula_presupuesto(vm_presup_ori)
		END IF
		CALL recalcula_presupuesto(rm_r21.r21_num_presup)
		COMMIT WORK 
		CALL fl_mensaje_registro_modificado()  
	END IF      
	RETURN
END IF      
CALL leer_detalle_cant()
IF int_flag THEN   
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
ELSE    
	LET rm_r21.r21_fecing = CURRENT
	DISPLAY BY NAME rm_r21.r21_fecing
	UPDATE rept021
		SET * = rm_r21.* 
		WHERE CURRENT OF q_up2
	LET vm_num_detalles = vm_ind_arr
	DELETE FROM rept022 
		WHERE r22_compania  = vg_codcia
		AND   r22_localidad = vg_codloc
		AND   r22_numprof   = rm_r21.r21_numprof 
	LET done = control_ingreso_detalle() 
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
DEFINE expr_sql		CHAR(600)
DEFINE expr_sql_2	CHAR(600)
DEFINE query		CHAR(1200)
DEFINE r_r21		RECORD LIKE rept021.* 	-- CABECERA PROFORMA
DEFINE r_t23		RECORD LIKE talt023.*

INITIALIZE expr_sql_2 TO NULL
CLEAR FORM
CALL control_DISPLAY_botones()

LET INT_FLAG = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON r21_num_presup, r21_num_ot, r21_numprof, r21_num_tran,
		     r21_moneda,     r21_codcli, r21_nomcli,  r21_cedruc,
		     r21_dircli,     r21_vendedor, r21_telcli
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r21_num_presup) THEN
			CALL fl_ayuda_presupuestos_taller(vg_codcia, vg_codloc,
							'A')
				RETURNING r_r21.r21_num_presup,
					  r_r21.r21_codcli, r_r21.r21_nomcli
			LET int_flag = 0
			IF r_r21.r21_num_presup IS NOT NULL THEN
				DISPLAY BY NAME r_r21.r21_num_presup,
						r_r21.r21_codcli,
						r_r21.r21_nomcli
			END IF
		END IF
		IF INFIELD(r21_num_ot) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'A')
				RETURNING r_r21.r21_num_ot, r_r21.r21_nomcli
			LET int_flag = 0
			IF r_r21.r21_num_ot IS NOT NULL THEN
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
							r_r21.r21_num_ot)
					RETURNING r_t23.*
				LET rm_r21.r21_num_ot = r_t23.t23_orden
				LET rm_r21.r21_codcli = r_t23.t23_cod_cliente
				LET rm_r21.r21_nomcli = r_t23.t23_nom_cliente
				LET rm_r21.r21_telcli = r_t23.t23_tel_cliente
				DISPLAY BY NAME rm_r21.r21_num_ot,
						rm_r21.r21_codcli,
						rm_r21.r21_nomcli,
						rm_r21.r21_telcli
			END IF
		END IF
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
						rm_r21.r21_telcli,
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
		IF INFIELD(r21_vendedor) THEN
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
		LET rm_r01.r01_codigo = GET_FLDBUF(r21_vendedor)
		IF rm_r01.r01_codigo IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r01.r01_codigo)
				RETURNING rm_r01.*       
			DISPLAY rm_r01.r01_nombres TO nom_vendedor
		ELSE
			CLEAR nom_vendedor
		END IF                        
	BEFORE CONSTRUCT
		IF rm_g05.g05_tipo = 'UF' THEN
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
	IF num_args() = 5 THEN
		LET expr_sql = 'r21_numprof = ', vm_numprof
	ELSE
		CASE arg_val(6)
			WHEN 'O'
				LET expr_sql = 'r21_num_ot = ', vm_numprof
			WHEN 'P'
				LET expr_sql = 'r21_num_presup = ', vm_numprof
		END CASE
	END IF
END IF

IF expr_sql_2 IS NOT NULL THEN
	LET expr_sql = expr_sql CLIPPED || ' AND ' || expr_sql_2 CLIPPED
END IF

LET query = 'SELECT *, ROWID FROM rept021 ', 
		' WHERE r21_compania  = ', vg_codcia,
		'   AND r21_localidad = ', vg_codloc,
		'   AND (r21_num_presup IS NOT NULL ',
		'    OR  r21_num_ot IS NOT NULL) ',
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3, 4' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r21.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() >= 5 THEN
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
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE r_t20		RECORD LIKE talt020.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_t61		RECORD LIKE talt061.*
DEFINE cliente		LIKE rept021.r21_codcli
DEFINE done, resul	SMALLINT
DEFINE flag_error	SMALLINT
DEFINE num_presup	LIKE talt020.t20_numpre
DEFINE codcli, cliant	LIKE cxct001.z01_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE num_ot		LIKE talt023.t23_orden

LET int_flag = 0
INPUT BY NAME rm_r21.r21_num_presup, rm_r21.r21_num_ot, rm_r21.r21_codcli,
	rm_r21.r21_nomcli, rm_r21.r21_cedruc, rm_r21.r21_dircli,
	rm_r21.r21_vendedor, rm_r21.r21_telcli
	WITHOUT DEFAULTS              
	ON KEY (INTERRUPT)          
		IF NOT FIELD_TOUCHED(rm_r21.r21_num_presup, rm_r21.r21_num_ot,
				rm_r21.r21_codcli, rm_r21.r21_nomcli,
				rm_r21.r21_cedruc, rm_r21.r21_dircli,
				rm_r21.r21_vendedor, rm_r21.r21_telcli)
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
		IF INFIELD(r21_num_presup) THEN
			CALL fl_ayuda_presupuestos_taller(vg_codcia, vg_codloc,
							'A')
				RETURNING num_presup, codcli, nomcli
			IF num_presup IS NOT NULL THEN
				LET rm_r21.r21_num_presup = num_presup
				LET rm_r21.r21_codcli	  = codcli
				LET rm_r21.r21_nomcli     = nomcli
				DISPLAY BY NAME rm_r21.r21_num_presup,
						rm_r21.r21_codcli,
						rm_r21.r21_nomcli
			END IF
		END IF
		IF INFIELD(r21_num_ot) AND vm_flag_mant = 'I' THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'A')
				RETURNING num_ot, nomcli
			LET int_flag = 0
			IF num_ot IS NOT NULL THEN
				CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
							num_ot)
					RETURNING r_t23.*
				LET rm_r21.r21_num_ot = r_t23.t23_orden
				LET rm_r21.r21_codcli = r_t23.t23_cod_cliente
				LET rm_r21.r21_nomcli = r_t23.t23_nom_cliente
				LET rm_r21.r21_telcli = r_t23.t23_tel_cliente
				DISPLAY BY NAME rm_r21.r21_num_ot,
						rm_r21.r21_codcli,
						rm_r21.r21_nomcli,
						rm_r21.r21_telcli
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
		IF INFIELD(r21_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F') 
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN                
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo
				DISPLAY BY NAME rm_r21.r21_vendedor 
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF  
		END IF      
		LET int_flag = 0  
	ON KEY(F5)
		CALL control_crear_cliente() 
		LET INT_FLAG = 0    
	BEFORE INPUT            
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r21_num_presup                      
		IF rm_r21.r21_num_presup IS NOT NULL THEN
			CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc,
							rm_r21.r21_num_presup)
				RETURNING r_t20.*
			IF r_t20.t20_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe presupuesto.','exclamation')
				NEXT FIELD r21_num_presup
			END IF
			IF r_t20.t20_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('No puede escojer un presupuesto que no este activo.','exclamation')
				NEXT FIELD r21_num_presup
			END IF
			IF rm_r21.r21_num_ot IS NOT NULL THEN
				LET rm_r21.r21_num_ot = NULL
				CLEAR r21_num_ot
			END IF
			LET rm_r21.r21_codcli	  = r_t20.t20_cod_cliente
			LET rm_r21.r21_nomcli     = r_t20.t20_nom_cliente
			LET rm_r21.r21_telcli     = r_t20.t20_tel_cliente
			LET rm_r21.r21_dircli     = r_t20.t20_dir_cliente
			DISPLAY BY NAME rm_r21.r21_codcli,
					rm_r21.r21_nomcli,
					rm_r21.r21_telcli,
					rm_r21.r21_dircli
			IF rm_r21.r21_cedruc IS NULL THEN
				NEXT FIELD r21_codcli
			END IF
		END IF
	AFTER FIELD r21_num_ot                      
		IF vm_flag_mant = 'M' THEN
			LET rm_r21.r21_num_ot = NULL
			DISPLAY BY NAME rm_r21.r21_num_ot
		END IF	
		IF rm_r21.r21_num_ot IS NOT NULL THEN
			CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
							rm_r21.r21_num_ot)
				RETURNING r_t23.*
			IF r_t23.t23_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe orden de trabajo.','exclamation')
				NEXT FIELD r21_num_ot
			END IF
			IF r_t23.t23_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('No puede escojer una orden de trabajo que no este activa.','exclamation')
				NEXT FIELD r21_num_ot
			END IF
			IF rm_r21.r21_num_presup IS NOT NULL THEN
				LET rm_r21.r21_num_presup = NULL
				CLEAR r21_num_presup
			END IF
			LET rm_r21.r21_codcli	  = r_t23.t23_cod_cliente
			LET rm_r21.r21_nomcli     = r_t23.t23_nom_cliente
			LET rm_r21.r21_telcli     = r_t23.t23_tel_cliente
			INITIALIZE r_t61.* TO NULL
			SELECT * INTO r_t61.* FROM talt061
				WHERE t61_compania   = r_t23.t23_compania
				  AND t61_cod_asesor = r_t23.t23_cod_asesor
			IF r_t61.t61_compania IS NOT NULL THEN
				LET rm_r21.r21_vendedor = r_t61.t61_cod_vendedor
			END IF
			DISPLAY BY NAME rm_r21.r21_codcli,
					rm_r21.r21_nomcli,
					rm_r21.r21_telcli,
					rm_r21.r21_dircli,
					rm_r21.r21_vendedor
			IF r_t61.t61_compania IS NOT NULL THEN
				CALL fl_lee_vendedor_rep(vg_codcia,
							rm_r21.r21_vendedor)
					RETURNING rm_r01.*
				DISPLAY rm_r01.r01_nombres TO nom_vendedor 
			END IF
			IF rm_r21.r21_cedruc IS NULL THEN
				NEXT FIELD r21_codcli
			END IF
		END IF
	AFTER FIELD r21_vendedor                      
		IF rm_r21.r21_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
				RETURNING rm_r01.*       
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation') 
				CLEAR nom_vendedor
				NEXT FIELD r21_vendedor
			END IF                        
			IF rm_r01.r01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r21_vendedor
			END IF        
			DISPLAY rm_r01.r01_nombres TO nom_vendedor 
		ELSE              
			CLEAR nom_vendedor
		END IF
	BEFORE FIELD r21_codcli, r21_nomcli, r21_dircli, r21_cedruc, r21_telcli 
		LET cliant = rm_r21.r21_codcli
	AFTER FIELD r21_codcli, r21_nomcli, r21_dircli, r21_cedruc, r21_telcli 
		IF rm_r21.r21_num_presup IS NOT NULL OR 
			rm_r21.r21_num_ot IS NOT NULL THEN
			LET rm_r21.r21_codcli = cliant
			DISPLAY BY NAME rm_r21.r21_codcli
		END IF
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
				CALL fl_mostrar_mensaje('Cliente no esta activado para esta localidad.','exclamation')
				NEXT FIELD r21_codcli	
			END IF	
			IF rm_z01.z01_estado <>'A' THEN
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
	AFTER INPUT
		IF NOT valida_cliente_consumidor_final(rm_r21.r21_codcli) THEN
			--NEXT FIELD r21_codcli
		END IF
		IF rm_r21.r21_num_presup IS NULL THEN
			IF rm_r21.r21_num_ot IS NULL THEN
				CALL fl_mostrar_mensaje('No puede dejar la proforma sin un presupuesto o una orden de trabajo.','exclamation')
				NEXT FIELD r21_num_presup
			END IF
		END IF
		IF rm_r21.r21_num_ot IS NULL THEN
			IF rm_r21.r21_num_presup IS NULL THEN
				CALL fl_mostrar_mensaje('No puede dejar la proforma sin un presupuesto o una orden de trabajo.','exclamation')
				NEXT FIELD r21_num_ot
			END IF
		END IF
		CALL control_saldos_vencidos(vg_codcia, rm_r21.r21_codcli, 1)
				RETURNING flag_error
		IF rm_z01.z01_paga_impto = 'N' THEN
			LET vm_flag_calculo_impto = 'I'
		END IF
END INPUT 

END FUNCTION



FUNCTION lee_detalle()
DEFINE i,j,k,ind, num	SMALLINT  
DEFINE resp		CHAR(6) 
DEFINE descuento	LIKE rept022.r22_porc_descto
DEFINE stock		LIKE rept022.r22_cantidad 
DEFINE item_anterior	LIKE rept010.r10_codigo  
DEFINE num_elm		SMALLINT       
DEFINE salir, max_row	SMALLINT
DEFINE in_array		SMALLINT   
DEFINE cant_prof	DECIMAL (8,2)   
DEFINE cod_bod		LIKE rept002.r02_codigo 
DEFINE name_bod		LIKE rept002.r02_nombre 
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*  
DEFINE max_descto	DECIMAL(4,2)
DEFINE precio_ant 	LIKE rept022.r22_precio
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
				CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'F', 'R', 'S', 'V')
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
						
     				        		LET r_detalle[i].r22_bodega = vm_bod_taller
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
				CALL fl_mostrar_mensaje('Digite bodega.','exclamation') 			
				NEXT FIELD r22_bodega
			END IF	
			IF r_detalle[i].r22_bodega IS NOT NULL THEN
				IF NOT valida_bodega(vg_codcia, 
					   r_detalle[i].r22_bodega) THEN
					NEXT FIELD r22_bodega
				END IF
				IF r_detalle[i].r22_item IS NOT NULL AND
				   r_detalle[i].r22_cantidad IS NOT NULL THEN
					 IF r_detalle[i].r22_bodega <> vm_bod_taller THEN
					 	CALL fl_lee_stock_rep(vg_codcia, 
						r_detalle[i].r22_bodega,
						r_detalle[i].r22_item)
				      		RETURNING r_r11.* 
						IF r_r11.r11_stock_act < r_detalle[i].r22_cantidad THEN 
							LET mensaje = 'El item: ', r_detalle[i].r22_item CLIPPED,
						      ' no tiene stock suficiente.'
							CALL fl_mostrar_mensaje(mensaje,'exclamation') 			
							IF vm_validar_stock THEN
							IF rm_r21.r21_num_ot IS NOT NULL THEN
								NEXT FIELD r22_cantidad
							END IF
							ELSE
								NEXT FIELD r22_item
							END IF
						END IF
					END IF	
				END IF
			END IF
		BEFORE FIELD r22_item                       
			LET item_anterior = r_detalle[i].r22_item  
		AFTER FIELD r22_item, r22_cantidad                
	    		IF r_detalle[i].r22_bodega IS NULL AND
	    		   r_detalle[i].r22_item IS NOT NULL THEN
	    		   	LET r_detalle[i].r22_item = NULL
				CLEAR r_detalle[j].r22_item
                       		CALL fl_mostrar_mensaje('Digite bodega primero.','exclamation')
                       		NEXT FIELD r22_bodega
			END IF
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
	    		IF r_detalle[i].r22_cantidad = 0 THEN
	    			LET r_detalle[i].r22_cantidad = 1
	    			DISPLAY r_detalle[i].r22_cantidad TO
	    				r_detalle[j].r22_cantidad
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
				--IF item_anterior IS NULL OR item_anterior <>
                       			--r_detalle[i].r22_item THEN
                       			CALL retorna_stock_item(vg_codcia, r_detalle[i].r22_bodega, rm_r10.r10_codigo)
                       			RETURNING --r_detalle[i].r22_bodega, 
                       			          r_r02.r02_codigo, 
                       			          r_detalle[i].stock_tot, 
                       				  r_detalle[i].stock_loc
				--END IF
				CALL retorna_descto_maximo_item(vg_codcia, rm_r10.r10_cod_util)
					RETURNING max_descto
				IF r_detalle[i].r22_porc_descto > max_descto THEN
					LET r_detalle[i].r22_porc_descto = max_descto
					DISPLAY r_detalle[i].stock_tot TO  
						r_detalle[j].stock_tot 
					DISPLAY r_detalle[i].stock_loc TO  
						r_detalle[j].stock_loc 
					DISPLAY r_detalle[i].r22_porc_descto TO 
						r_detalle[j].r22_porc_descto 
			   	END IF

				IF r_detalle[i].r22_cantidad IS NULL THEN
					LET r_detalle[i].r22_cantidad = 1
					DISPLAY r_detalle[i].r22_cantidad TO 
						r_detalle[j].r22_cantidad
				END IF
				LET cant_prof = 0
				FOR k = 1 TO arr_count()
					IF k = i THEN
						CONTINUE FOR
					END IF
                       			IF r_detalle[i].r22_item =
						 r_detalle[k].r22_item AND 
                       			   r_detalle[i].r22_bodega =
						 r_detalle[k].r22_bodega AND 
					   r_detalle[k].r22_bodega <> vm_bod_taller THEN
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
				ELSE		
					LET r_detalle[i].r22_precio = rm_r10.r10_precio_ma
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
				IF r_r11.r11_stock_act IS NULL THEN
					LET r_r11.r11_stock_act = 0
				END IF
				IF r_detalle[i].r22_cantidad > r_r11.r11_stock_act THEN
					CALL fl_mostrar_mensaje('Stock insuficiente.', 'exclamation')
					IF vm_validar_stock THEN
						IF rm_r21.r21_num_ot IS NOT NULL THEN
							NEXT FIELD r22_cantidad
						END IF
					ELSE
						NEXT FIELD r22_item
					END IF
				END IF
				LET r_detalle[i].subtotal_item = r_detalle[i].r22_precio * r_detalle[i].r22_cantidad                                    	
				DISPLAY r_detalle[i].r22_precio TO 
					r_detalle[j].r22_precio
				DISPLAY r_detalle[i].subtotal_item TO 
					r_detalle[j].subtotal_item
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
					   CALL fl_mostrar_mensaje('No puede repetir un mismo item y una misma bodega. Borre la línea.','exclamation') 
						NEXT FIELD r22_item
					END IF
				END FOR
			ELSE
				CLEAR nom_item, descrip_1, descrip_2, descrip_3, descrip_4
				IF r_detalle[i].stock_tot IS NOT NULL THEN
					NEXT FIELD r22_item
				END IF
			END IF	
		AFTER FIELD r22_porc_descto      
			IF r_detalle[i].r22_porc_descto IS NULL AND 
				r_detalle[i].r22_item IS NOT NULL THEN 
				LET r_detalle[i].r22_porc_descto = 0  
				DISPLAY r_detalle[i].* TO r_detalle[j].* 
			END IF                                 
			IF r_detalle[i].r22_porc_descto IS NOT NULL THEN
     				CALL fl_lee_item(vg_codcia,
							r_detalle[i].r22_item) 
					RETURNING rm_r10.*            
				CALL retorna_descto_maximo_item(vg_codcia, rm_r10.r10_cod_util)
					RETURNING max_descto
				IF r_detalle[i].r22_porc_descto > max_descto THEN
					LET mensaje = 'El item: ', r_detalle[i].r22_item CLIPPED,
						      ' tiene un descuento maximo de: ', 
						      max_descto USING '#&.##'	
					CALL fl_mostrar_mensaje(mensaje,'exclamation') 			
					LET r_detalle[i].r22_porc_descto = max_descto
					DISPLAY r_detalle[i].* TO  r_detalle[j].* 
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



FUNCTION leer_detalle_cant()
DEFINE i, j, k, cant	SMALLINT
DEFINE resp		CHAR(6) 
DEFINE r_cant		ARRAY[500] OF RECORD                        
				r22_cantidad	LIKE rept022.r22_cantidad 
			END RECORD                         
DEFINE max_descto	DECIMAL(4,2)
DEFINE mensaje		VARCHAR(100)
DEFINE precio_ant 	LIKE rept022.r22_precio

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
LET int_flag = 0
INPUT BY NAME rm_r21.r21_vendedor
	WITHOUT DEFAULTS              
	ON KEY (INTERRUPT)          
		IF NOT FIELD_TOUCHED(rm_r21.r21_vendedor) THEN
			RETURN
		END IF       
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp             
		IF resp = 'Yes' THEN
			LET int_flag = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)                  
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)                   
		IF INFIELD(r21_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F') 
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN                
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo
				DISPLAY BY NAME rm_r21.r21_vendedor 
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF  
		END IF      
		LET int_flag = 0  
	BEFORE INPUT            
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r21_vendedor                      
		IF rm_r21.r21_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r21.r21_vendedor)
				RETURNING rm_r01.*       
			IF rm_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation') 
				CLEAR nom_vendedor
				NEXT FIELD r21_vendedor
			END IF                        
			IF rm_r01.r01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD r21_vendedor
			END IF        
			DISPLAY rm_r01.r01_nombres TO nom_vendedor 
		ELSE              
			CLEAR nom_vendedor
		END IF
END INPUT 
FOR j = 1 TO vm_ind_arr
	LET r_cant[j].r22_cantidad = r_detalle[j].r22_cantidad
END FOR
WHILE TRUE
	LET int_flag = 0
	CALL set_count(vm_ind_arr)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT', '')
			--#CALL dialog.keysetlabel('DELETE', '')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		ON KEY(INTERRUPT)
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp      
			IF resp = 'Yes' THEN       
				LET int_flag = 1  
				EXIT WHILE       
			END IF                  
			LET int_flag = 0    
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			IF i > vm_ind_arr THEN
				LET int_flag = 2
				EXIT INPUT
			END IF
			IF NOT INFIELD(r22_cantidad) THEN
				NEXT FIELD r22_cantidad
			END IF
			CALL muestra_etiquetas_det(i, vm_ind_arr, i)
		AFTER ROW
			IF NOT INFIELD(r22_cantidad) THEN
				NEXT FIELD r22_cantidad
			END IF
		BEFORE FIELD r22_bodega
			NEXT FIELD r22_cantidad
		BEFORE FIELD r22_item
			NEXT FIELD r22_cantidad
		--BEFORE FIELD r22_precio
		--	NEXT FIELD r22_porc_descto
		AFTER FIELD r22_cantidad
			IF r_detalle[i].r22_cantidad IS NULL THEN
				LET r_detalle[i].r22_cantidad = r_cant[i].r22_cantidad
			END IF
			IF r_detalle[i].r22_cantidad > r_cant[i].r22_cantidad THEN
				CALL fl_mostrar_mensaje('La cantidad solo puede ser menor o igual a la original.','exclamation')
				LET r_detalle[i].r22_cantidad = r_cant[i].r22_cantidad
			END IF
			DISPLAY r_detalle[i].r22_cantidad TO r_detalle[j].r22_cantidad
			IF r_detalle[i].r22_porc_descto IS NULL THEN 
				LET r_detalle[i].r22_porc_descto = 0 
			END IF                                    
			IF r_detalle[i].r22_precio <= 0 THEN                                                  
				CALL fl_mostrar_mensaje('El item debe tener precio mayor a cero.','exclamation') 
				NEXT FIELD r22_cantidad
			END IF   
			LET r_detalle[i].subtotal_item = r_detalle[i].r22_precio
						 * r_detalle[i].r22_cantidad
			DISPLAY r_detalle[i].r22_precio TO 
				r_detalle[j].r22_precio
			DISPLAY r_detalle[i].subtotal_item TO 
				r_detalle[j].subtotal_item
			LET k = i - j + 1 
			CALL calcula_totales(vm_ind_arr,k)
			--CALL calcula_totales(vm_ind_arr,1)
		AFTER FIELD r22_porc_descto      
			IF r_detalle[i].r22_porc_descto IS NULL AND 
				r_detalle[i].r22_item IS NOT NULL THEN 
				LET r_detalle[i].r22_porc_descto = 0  
				DISPLAY r_detalle[i].* TO r_detalle[j].* 
			END IF                                 
			IF r_detalle[i].r22_porc_descto IS NOT NULL THEN
     				CALL fl_lee_item(vg_codcia,
							r_detalle[i].r22_item) 
					RETURNING rm_r10.*            
				CALL retorna_descto_maximo_item(vg_codcia, rm_r10.r10_cod_util)
					RETURNING max_descto
				IF r_detalle[i].r22_porc_descto > max_descto THEN
					LET mensaje = 'El item: ', r_detalle[i].r22_item CLIPPED,
						      ' tiene un descuento maximo de: ', 
						      max_descto USING '#&.##'	
					CALL fl_mostrar_mensaje(mensaje,'exclamation') 			
					LET r_detalle[i].r22_porc_descto = max_descto
					DISPLAY r_detalle[i].* TO  r_detalle[j].* 
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
	END INPUT
	IF int_flag = 0 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION  



FUNCTION numero_filas_correcto(k) 
DEFINE k		INTEGER

IF k > rm_r00.r00_numlin_fact THEN
	CALL fl_mostrar_mensaje('El número de líneas maximo permitido por factura/proforma es de '|| rm_r00.r00_numlin_fact || '.' || ' Elimine líneas o abandone el ingreso.','exclamation')
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
IF r_r02.r02_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('Esta bodega no esta activa.','exclamation')
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
IF r_r02.r02_tipo = 'S' THEN
	CALL fl_mostrar_mensaje('No puede digitar la bodega de ventas sin stock.','exclamation') 			
	RETURN 0
END IF	
IF r_r02.r02_area = "T" AND r_r02.r02_tipo = "L" THEN
	CALL fl_mostrar_mensaje('No puede digitar la bodega de O.T. en proceso del taller.', 'exclamation')
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

SELECT MAX(r21_numprof) + 1
	INTO rm_r21.r21_numprof
	FROM rept021 
	WHERE r21_compania  = vg_codcia 
	  AND r21_localidad = vg_codloc
IF rm_r21.r21_numprof IS NULL THEN   
	LET rm_r21.r21_numprof = 1  
END IF                            
LET rm_r21.r21_fecing = CURRENT  
INSERT INTO rept021 VALUES (rm_r21.*) 
IF num_args() = 6 AND arg_val(6) = 'A' THEN
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
IF num_args() <> 6 OR arg_val(6) <> 'A' THEN
	DISPLAY BY NAME rm_r21.r21_tot_bruto, rm_r21.r21_tot_dscto,
			vm_impuesto, rm_r21.r21_tot_neto
END IF

END FUNCTION



FUNCTION control_ver_detalle() 
DEFINE i, j		SMALLINT      

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
		CALL control_imprimir_proforma() 
		LET int_flag = 0
        ON KEY(F7)
		CALL control_transf_orddes()
		LET int_flag = 0
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
		--#CALL dialog.keysetlabel("F7","Transf/Orden") 
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY 
CALL muestra_contadores_det(0, vm_ind_arr)

END FUNCTION 



FUNCTION control_imprimir_proforma()
DEFINE param		VARCHAR(60)

LET param = vg_codloc, ' ', rm_r21.r21_numprof
CALL ejecuta_comando('TALLER', vg_modulo, 'talp410 ', param)

END FUNCTION



FUNCTION control_hacer_preventa()            
DEFINE i,j,k,done 	SMALLINT            
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE resp 		CHAR(6)     
DEFINE preventas 	INTEGER   
DEFINE r_r24		RECORD LIKE rept024.*
DEFINE salir		SMALLINT            
DEFINE query		CHAR(500)   
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

CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, rm_r21.r21_numprof)
	RETURNING rm_r21.*
IF rm_r21.r21_num_presup IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Proformas asociadas a presupuestos no pueden ser convertidas en pre-ventas.','exclamation')
	RETURN 
END IF   
IF rm_r21.r21_tot_neto <= 0 THEN
	CALL fl_mostrar_mensaje('Proforma tiene valor 0.','exclamation')
	RETURN 
END IF   
	
CALL fl_control_status_caja(vg_codcia, vg_codloc, 'P') RETURNING int_flag
IF int_flag <> 0 THEN
	LET int_flag = 0
	RETURN
END IF	
IF rm_r21.r21_cod_tran IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Esta proforma ya fue facturada, no puede ser modificada.','exclamation')             	
	RETURN
END IF 
CALL fl_lee_compania_repuestos(vg_codcia)  -- PARA OBTENER LA CONFIGURACION 
	RETURNING rm_r00.*		   -- DEL AREA DE REPUESTOS 
IF DATE(rm_r21.r21_fecing) + rm_r00.r00_expi_prof < TODAY THEN   
	CALL fl_mostrar_mensaje('La proforma ya expiró.','exclamation')
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
IF num_args() = 4 THEN
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
IF num_args() = 6 AND arg_val(6) = 'A' THEN
	LET rm_r23.r23_usuario = rm_r21.r21_usuario
END IF
LET rm_r23.r23_fecing      = CURRENT
LET rm_r23.r23_referencia  = 'GENERADA DE LA PROFORMA # '
			     || rm_r21.r21_numprof || '.'
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
	LET rm_r23.r23_fecing = CURRENT
	INSERT INTO rept023 VALUES (rm_r23.*)
	LET j = 1
	WHILE NOT salir
		IF j > rm_r00.r00_numlin_fact THEN
			EXIT WHILE
		END IF
		INITIALIZE r_r24.* TO NULL
		SELECT * INTO r_r24.* FROM rept024
			WHERE r24_compania  = vg_codcia
			  AND r24_localidad = vg_codloc
			  AND r24_numprev   = rm_r23.r23_numprev
		  	  AND r24_item      = r_detprev.item
		IF STATUS <> NOTFOUND THEN
			IF r_detprev.precio <> r_r24.r24_precio THEN
				ROLLBACK WORK
				LET mensaje = 'El item ',
					r_detprev.item CLIPPED,
					' se ha digitado dos ',
					'veces en la proforma, con ',
					'precios diferentes. Se detendra ',
					'la generación de la preventa.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				RETURN 
			END IF
			IF r_detprev.descto <> r_r24.r24_descuento THEN
				ROLLBACK WORK
				LET mensaje = 'El item ',
					r_detprev.item CLIPPED,
					' se ha digitado dos ',
					'veces en la proforma, con ',
					'descuentos diferentes. Se detendra ',
					'la generación de la preventa.'
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				RETURN
			END IF
		END IF
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
		IF r_r10.r10_costo_mb <= 0.01 THEN
			LET mensaje = 'El Item ',
			     rm_r24.r24_item CLIPPED, ' ',
			     'no tiene costo. Se debe hacer un ajuste al costo.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
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
					' en la bodega ', r_r11.r11_bodega, ' ',
					', y la cantidad pedida es ',
					rm_r24.r24_cant_ped USING "---,--&.##",
					' ¿ Desea Continuar ?'
				CALL fl_hacer_pregunta(mensaje,'No') 
                                	RETURNING resp 
				IF resp <> 'Yes' THEN
					ROLLBACK WORK
					RETURN 
				END IF 
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
IF num_args() = 6 AND arg_val(6) = 'A' THEN
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
LET mensaje = 'Se generó ', preventas USING "<<<<<<&", ' preventa ',
		' y la última preventa se genero con el número ',
		rm_r23.r23_numprev USING "<<<<<<<<&", '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
IF num_args() = 4 THEN
	DISPLAY BY NAME rm_r23.r23_numprev
END IF

END FUNCTION



FUNCTION eliminar_preventa_anterior()
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_r24		RECORD LIKE rept024.*
DEFINE flag, i		SMALLINT

LET flag = 0
WHENEVER ERROR CONTINUE
DECLARE q_elimpre CURSOR FOR
	SELECT * FROM rept023
		WHERE r23_compania  = vg_codcia
		  AND r23_localidad = vg_codloc
		  AND r23_numprof   = rm_r21.r21_numprof
	FOR UPDATE
OPEN q_elimpre
FETCH q_elimpre INTO r_r23.*
IF STATUS < 0 THEN
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
	RETURN flag
END IF
FOREACH q_elimpre INTO r_r23.*
	IF r_r23.r23_cod_tran IS NOT NULL THEN
		CONTINUE FOREACH
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

CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr 
	INITIALIZE r_detalle[i].* TO NULL
	IF num_args() <> 6 OR arg_val(6) <> 'A' THEN
		CLEAR r_detalle[i].*
	END IF
END FOR

DECLARE  q_rept022 CURSOR FOR 
	SELECT rept022.*, rept010.r10_peso 
		 FROM rept022, rept010 
            	WHERE r22_compania  = vg_codcia 
	    	  AND r22_localidad = vg_codloc
            	  AND r22_numprof   = rm_r21.r21_numprof
            	  AND r22_compania  = r10_compania
            	  AND r22_item      = r10_codigo
		ORDER BY r22_orden


LET i = 1
FOREACH q_rept022 INTO r_r22.*, peso
	CALL fl_lee_item(vg_codcia, r_r22.r22_item) RETURNING rm_r10.*
	CALL retorna_descto_maximo_item(vg_codcia, rm_r10.r10_cod_util)
		RETURNING max_descto
	LET r_detalle[i].r22_porc_descto = r_r22.r22_porc_descto
	IF r_detalle[i].r22_porc_descto > max_descto THEN
		LET r_detalle[i].r22_porc_descto = max_descto
	END IF
	LET r_detalle[i].r22_cantidad    = r_r22.r22_cantidad
	LET r_detalle[i].r22_bodega      = r_r22.r22_bodega
	LET r_detalle[i].r22_item        = r_r22.r22_item
	IF num_args() = 6 AND arg_val(6) = 'A' THEN
		IF r_detalle[i].r22_cantidad = 0 THEN
			CONTINUE FOREACH
		END IF
		CALL obtener_bodega_por_refacturacion(i)
			RETURNING r_detalle[i].r22_bodega
		IF r_detalle[i].r22_bodega IS NULL THEN
			CALL fl_mostrar_mensaje('No existe bodega de origen para el Item ' || r_r22.r22_item CLIPPED || '.', 'stop')
			EXIT PROGRAM
		END IF
	END IF
	LET r_detalle[i].r22_precio      = rm_r10.r10_precio_mb
	IF (num_args() = 6 AND arg_val(6) = 'A') OR
	    rm_r21.r21_cod_tran IS NOT NULL
	THEN
		LET r_detalle[i].r22_precio = r_r22.r22_precio
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
	IF num_args() <> 6 OR arg_val(6) = 'A' THEN
		RETURN
	END IF
	LET i = 0
	CLEAR FORM
	CALL control_DISPLAY_botones()
	RETURN
END IF
LET vm_ind_arr      = i
LET vm_num_detalles = vm_ind_arr
FOR i = 1 TO vm_ind_arr 
       	CALL retorna_stock_item(vg_codcia, r_detalle[i].r22_bodega, r_detalle[i].r22_item)
        	RETURNING r_detalle[i].r22_bodega, r_detalle[i].stock_tot, r_detalle[i].stock_loc
END FOR
IF vm_ind_arr < vm_size_arr THEN
	LET vm_size_arr = vm_ind_arr
END IF

IF num_args() = 6 AND arg_val(6) = 'A' THEN
	RETURN
END IF
FOR i = 1 TO vm_size_arr 
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR
CALL muestra_etiquetas_det(0, vm_ind_arr, 1)

END FUNCTION



FUNCTION obtener_bodega_por_refacturacion(i)
DEFINE i		SMALLINT
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE cant		LIKE rept020.r20_cant_dev
DEFINE bodega		LIKE rept020.r20_bodega

DECLARE q_retorno_t CURSOR FOR
	SELECT rept020.*
		FROM rept019, rept020
		WHERE r19_compania    = vg_codcia
		  AND r19_localidad   = vg_codloc
		  AND r19_cod_tran    = 'TR'
		  AND r19_bodega_dest = r_detalle[i].r22_bodega
		  AND r19_ord_trabajo = rm_r21.r21_num_ot
		  AND r20_compania    = r19_compania
		  AND r20_localidad   = r19_localidad
		  AND r20_cod_tran    = r19_cod_tran
		  AND r20_num_tran    = r19_num_tran
		  AND r20_item        = r_detalle[i].r22_item
		ORDER BY r20_cant_ven DESC
LET cant   = 0
LET bodega = NULL
FOREACH q_retorno_t INTO r_r20.*
	CALL fl_lee_bodega_rep(vg_codcia, r_r20.r20_bodega) RETURNING r_r02.*
	IF r_r02.r02_area = 'T' THEN
		CONTINUE FOREACH
	END IF
	LET cant   = cant + r_detalle[i].r22_cantidad
	LET bodega = r_r20.r20_bodega
	IF cant >= r_detalle[i].r22_cantidad THEN
		EXIT FOREACH
	END IF
END FOREACH
RETURN bodega

END FUNCTION



FUNCTION retorna_stock_item(codcia, bodega, codigo)
DEFINE codcia		LIKE rept021.r21_compania
DEFINE codigo		LIKE rept022.r22_item
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE stock_tot	DECIMAL (8,2)
DEFINE stock_loc	DECIMAL (8,2)

DECLARE q_barc CURSOR FOR 
	SELECT * FROM rept011
		WHERE r11_compania = codcia AND 
		      r11_item     = codigo	
LET stock_tot = 0
LET stock_loc = 0
--LET bodega    = NULL
FOREACH q_barc INTO r_r11.*
	CALL fl_lee_bodega_rep(codcia, r_r11.r11_bodega)
		RETURNING r_r02.*                
	IF r_r02.r02_factura IS NULL OR r_r02.r02_factura <> 'S' THEN
		CONTINUE FOREACH
	END IF
	IF r_r02.r02_tipo = 'S' THEN
		CONTINUE FOREACH
	END IF
	IF r_r02.r02_localidad = vg_codloc THEN
		LET stock_loc = stock_loc + r_r11.r11_stock_act
		IF r_r11.r11_stock_act > 0 THEN
			--LET bodega    = r_r11.r11_bodega	
		END IF
	ELSE
		LET stock_tot = stock_tot + r_r11.r11_stock_act
	END IF		           
END FOREACH
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
	OPEN FORM f_213_4 FROM '../../REPUESTOS/forms/repf220_4'
ELSE
	OPEN FORM f_213_4 FROM '../../REPUESTOS/forms/repf220_4c'
END IF
DISPLAY FORM f_213_4
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
        IF r_r02.r02_tipo = 'S' THEN                                 
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
DEFINE l, flag	 	SMALLINT
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
        	ON KEY(F1,CONTROL-W) 
			CALL control_visor_teclas_caracter_4() 
		ON KEY(RETURN)
			LET i = arr_curr()	
			LET j = scr_line()
			CALL muestra_contadores_det_tot(0, i_loc, i, i_rem)
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
	RETURN 0
END IF
IF rm_vend.r01_compania IS NULL AND rm_g05.g05_tipo = 'AG' THEN
	RETURN r_r77.r77_dscmax_ger
END IF
IF rm_vend.r01_compania IS NULL AND rm_g05.g05_tipo = 'AM' THEN
	RETURN r_r77.r77_dscmax_jef
END IF
IF rm_vend.r01_tipo = 'J' THEN
	RETURN r_r77.r77_dscmax_jef
END IF
IF rm_vend.r01_tipo = 'G' THEN
	RETURN r_r77.r77_dscmax_ger
END IF
RETURN r_r77.r77_dscmax_ven

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
		rm_r21.r21_tot_bruto,  rm_r21.r21_telcli,
		rm_r21.r21_tot_dscto,  vm_impuesto,
		rm_r21.r21_num_presup, rm_r21.r21_num_ot,
		rm_r21.r21_cod_tran, rm_r21.r21_num_tran 
INITIALIZE r_r23.* TO NULL
DECLARE q_mos_r23 CURSOR FOR
	SELECT * FROM rept023
		WHERE r23_compania  = vg_codcia
		  AND r23_localidad = vg_codloc
		  AND r23_numprof   = rm_r21.r21_numprof
		ORDER BY r23_fecing DESC
OPEN q_mos_r23
FETCH q_mos_r23 INTO r_r23.*
DISPLAY BY NAME r_r23.r23_numprev
CLOSE q_mos_r23
FREE q_mos_r23
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

LET vm_size_arr = fgl_scr_size('r_detalle') 
{
IF vg_gui = 0 THEN 
	LET vm_size_arr = 5
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
DEFINE param		VARCHAR(60)

LET param = vg_codloc
CALL ejecuta_comando('COBRANZAS', 'CO', 'cxcp101 ', param)

END FUNCTION



FUNCTION control_crear_item()
DEFINE param		VARCHAR(60)

LET param = vg_codloc
CALL ejecuta_comando('REPUESTOS', 'RE', 'repp108 ', param)

END FUNCTION



FUNCTION control_ver_item(item)
DEFINE item 		LIKE rept010.r10_codigo
DEFINE param		VARCHAR(60)

IF item IS NULL THEN
	RETURN
END IF
LET param = vg_codloc, ' ', item
CALL ejecuta_comando('REPUESTOS', 'RE', 'repp108 ', param)

END FUNCTION



FUNCTION genera_transferencia()
DEFINE i		SMALLINT
DEFINE cod_tran		CHAR(2)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE item		LIKE rept011.r11_item
DEFINE cantidad		LIKE rept011.r11_stock_act
DEFINE num_tran		INTEGER

LET cod_tran = 'TR'
CREATE TEMP TABLE te_trans
	(te_bodega		CHAR(2),
	 te_item		CHAR(15),
	 te_cantidad		DECIMAL(8,2))
FOR i = 1 TO vm_num_detalles
	IF r_detalle[i].r22_cantidad <= 0 OR r_detalle[i].r22_bodega IS NULL
	THEN
		CONTINUE FOR
	END IF
	SELECT * FROM te_trans WHERE te_bodega = r_detalle[i].r22_bodega AND
				     te_item   = r_detalle[i].r22_item
	IF STATUS = NOTFOUND THEN
		INSERT INTO te_trans VALUES (r_detalle[i].r22_bodega,
				             r_detalle[i].r22_item,
					     r_detalle[i].r22_cantidad)
	ELSE
		UPDATE te_trans SET te_cantidad = te_cantidad + 
					          r_detalle[i].r22_cantidad
			WHERE te_bodega = r_detalle[i].r22_bodega AND
			      te_item   = r_detalle[i].r22_item
	END IF
END FOR
DECLARE qu_botr CURSOR FOR SELECT UNIQUE te_bodega FROM te_trans
FOREACH qu_botr INTO bodega
	INITIALIZE r_r19.*, r_r20.* TO NULL
	CALL fl_actualiza_control_secuencias(vg_codcia,vg_codloc,'RE','AA','TR')
		RETURNING num_tran
	IF num_tran <= 0 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_r19.r19_compania	  = vg_codcia
    	LET r_r19.r19_localidad	  = vg_codloc
    	LET r_r19.r19_cod_tran 	  = cod_tran
    	LET r_r19.r19_num_tran 	  = num_tran
    	LET r_r19.r19_cont_cred	  = 'C'
    	LET r_r19.r19_referencia  = 'O.T.: ', 
				   rm_r21.r21_num_ot USING '<<<<<<' CLIPPED,
				  ', PROF.: ',
				   rm_r21.r21_numprof USING '<<<<<<' CLIPPED,
				  ', ', rm_r21.r21_nomcli  
    	LET r_r19.r19_codcli 	  = rm_r21.r21_codcli
    	LET r_r19.r19_nomcli 	  = rm_r21.r21_nomcli
    	LET r_r19.r19_dircli 	  = rm_r21.r21_dircli
    	LET r_r19.r19_telcli 	  = rm_r21.r21_telcli
    	LET r_r19.r19_cedruc 	  = rm_r21.r21_cedruc
    	LET r_r19.r19_vendedor 	  = rm_r21.r21_vendedor
    	LET r_r19.r19_ord_trabajo = rm_r21.r21_num_ot
    	LET r_r19.r19_descuento   = 0
    	LET r_r19.r19_porc_impto  = 0
    	LET r_r19.r19_bodega_ori  = bodega
    	LET r_r19.r19_bodega_dest = vm_bod_taller
    	LET r_r19.r19_moneda 	  = rm_r21.r21_moneda
	LET r_r19.r19_paridad     = rg_gen.g00_decimal_mb
    	LET r_r19.r19_precision   = rm_r21.r21_precision
    	LET r_r19.r19_tot_costo   = 0
    	LET r_r19.r19_tot_bruto   = 0
    	LET r_r19.r19_tot_dscto   = 0
    	LET r_r19.r19_tot_neto 	  = 0
    	LET r_r19.r19_flete 	  = 0
    	LET r_r19.r19_usuario 	  = vg_usuario
    	LET r_r19.r19_fecing 	  = CURRENT
	INSERT INTO rept019 VALUES (r_r19.*)
	DECLARE qu_dettr CURSOR FOR SELECT te_item, te_cantidad
		FROM te_trans WHERE te_bodega = bodega
	LET i = 0
	FOREACH qu_dettr INTO item, cantidad
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_ori, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
			CONTINUE FOREACH
		END IF
 		IF r_r11.r11_stock_act < cantidad THEN
			CONTINUE FOREACH
		END IF
		LET i = i + 1
    		LET r_r20.r20_compania 	 = r_r19.r19_compania
    		LET r_r20.r20_localidad	 = r_r19.r19_localidad
    		LET r_r20.r20_cod_tran 	 = r_r19.r19_cod_tran
    		LET r_r20.r20_num_tran 	 = r_r19.r19_num_tran
    		LET r_r20.r20_bodega 	 = bodega
    		LET r_r20.r20_item 	 = item
    		LET r_r20.r20_orden 	 = i
    		LET r_r20.r20_cant_ped 	 = cantidad
    		LET r_r20.r20_cant_ven   = cantidad
    		LET r_r20.r20_cant_dev 	 = 0
    		LET r_r20.r20_cant_ent   = 0
    		LET r_r20.r20_descuento  = 0
    		LET r_r20.r20_val_descto = 0
		CALL fl_lee_item(r_r19.r19_compania, item)
			RETURNING r_r10.*
    		LET r_r20.r20_costant_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costant_ma = r_r10.r10_costo_ma
    		LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
    		LET r_r20.r20_costnue_ma = r_r10.r10_costo_ma
		IF r_r19.r19_moneda <> rg_gen.g00_moneda_base THEN
			LET r_r10.r10_precio_mb = r_r10.r10_precio_ma
			LET r_r10.r10_costo_mb  = r_r10.r10_costo_ma
		END IF	
    		LET r_r20.r20_precio 	 = r_r10.r10_precio_mb
    		LET r_r20.r20_val_impto  = 0
    		LET r_r20.r20_costo 	 = r_r10.r10_costo_mb
    		LET r_r20.r20_fob 	 = r_r10.r10_fob
    		LET r_r20.r20_linea 	 = r_r10.r10_linea
    		LET r_r20.r20_rotacion 	 = r_r10.r10_rotacion
    		LET r_r20.r20_ubicacion  = '.'
    		LET r_r20.r20_stock_ant  = r_r11.r11_stock_act
		UPDATE rept011 
			SET r11_stock_act = r11_stock_act - cantidad,
		            r11_egr_dia   = r11_egr_dia + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_ori
			  AND r11_item     = item 
		CALL fl_lee_stock_rep(vg_codcia, r_r19.r19_bodega_dest, item)
			RETURNING r_r11.*
		IF r_r11.r11_compania IS NULL THEN
    			LET r_r11.r11_stock_act = 0
			INSERT INTO rept011
      				(r11_compania, r11_bodega, r11_item, 
		 		r11_ubicacion, r11_stock_ant, 
		 		r11_stock_act, r11_ing_dia,
		 		r11_egr_dia)
				VALUES(vg_codcia, r_r19.r19_bodega_dest,
		       			item, 'SN', 0, 0, 0, 0) 
		END IF
    		LET r_r20.r20_stock_bd = r_r11.r11_stock_act
    		LET r_r20.r20_fecing   = CURRENT
		INSERT INTO rept020 VALUES (r_r20.*)
		UPDATE rept011 
			SET r11_stock_act = r11_stock_act + cantidad,
		            r11_ing_dia   = r11_ing_dia   + cantidad
			WHERE r11_compania = vg_codcia
			  AND r11_bodega   = r_r19.r19_bodega_dest
			  AND r11_item     = item 
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
					  (cantidad * r_r20.r20_costo)
	END FOREACH
	IF i = 0 THEN
		DELETE FROM rept019
			WHERE r19_compania  = r_r19.r19_compania  AND 
		              r19_localidad = r_r19.r19_localidad AND 
		      	      r19_cod_tran  = r_r19.r19_cod_tran  AND 
		              r19_num_tran  = r_r19.r19_num_tran 
	ELSE
		UPDATE rept019 SET r19_tot_costo = r_r19.r19_tot_costo,
	                           r19_tot_bruto = r_r19.r19_tot_costo,
	                           r19_tot_neto  = r_r19.r19_tot_costo
			     WHERE r19_compania  = r_r19.r19_compania  AND 
		                   r19_localidad = r_r19.r19_localidad AND 
		                   r19_cod_tran  = r_r19.r19_cod_tran  AND 
		                   r19_num_tran  = r_r19.r19_num_tran 
		IF num_args() = 4 THEN
			CALL fl_mostrar_mensaje('Se generó la transferencia: ' || r_r19.r19_num_tran, 'info')
		END IF
	END IF
END FOREACH
DROP TABLE te_trans

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



FUNCTION calcular_impto(num_presup, total_rp)
DEFINE num_presup	LIKE talt020.t20_numpre
DEFINE total_rp		LIKE talt020.t20_total_rp
DEFINE r_t20		RECORD LIKE talt020.*
DEFINE r_g00		RECORD LIKE gent000.*
DEFINE r_z01		RECORD LIKE cxct001.*

CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, num_presup)
	RETURNING r_t20.*
LET r_t20.t20_total_rp = total_rp
CALL fl_lee_configuracion_facturacion() RETURNING r_g00.*
IF r_t20.t20_cod_cliente IS NOT NULL THEN
	CALL fl_lee_cliente_general(r_t20.t20_cod_cliente) RETURNING r_z01.*
	IF r_z01.z01_paga_impto = 'N' THEN
		LET r_g00.g00_porc_impto = 0
	END IF
END IF
LET r_t20.t20_total_impto = (r_t20.t20_total_mo + r_t20.t20_total_rp +
			     r_t20.t20_mano_ext) * (r_g00.g00_porc_impto / 100)
IF r_z01.z01_paga_impto = 'N' THEN
	LET r_t20.t20_total_impto = 0
END IF
RETURN r_t20.t20_total_impto

END FUNCTION



FUNCTION calcular_total(num_presup, total_rp)
DEFINE num_presup	LIKE talt020.t20_numpre
DEFINE total_rp		LIKE talt020.t20_total_rp
DEFINE r_t20		RECORD LIKE talt020.*

CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, num_presup)
	RETURNING r_t20.*
LET r_t20.t20_total_rp = total_rp
LET r_t20.t20_total_neto = r_t20.t20_total_mo + r_t20.t20_total_rp +
			    r_t20.t20_mano_ext + r_t20.t20_total_impto +
			    r_t20.t20_otros_mat + r_t20.t20_gastos
RETURN r_t20.t20_total_neto

END FUNCTION



FUNCTION recalcula_presupuesto(num_presup)
DEFINE num_presup	LIKE talt020.t20_numpre
DEFINE r_t20		RECORD LIKE talt020.*

CALL fl_lee_presupuesto_taller(vg_codcia, vg_codloc, num_presup)
	RETURNING r_t20.*
IF status = NOTFOUND THEN
	RETURN
END IF
SELECT SUM(r21_tot_bruto - r21_tot_dscto) INTO r_t20.t20_total_rp
	FROM rept021
	WHERE r21_compania   = vg_codcia AND 
	      r21_localidad  = vg_codloc AND
	      r21_num_presup = num_presup
IF r_t20.t20_total_rp IS NULL THEN
	LET r_t20.t20_total_rp = 0
END IF
SELECT SUM(t21_valor) INTO r_t20.t20_total_mo
	FROM talt021
	WHERE t21_compania   = vg_codcia AND 
	      t21_localidad  = vg_codloc AND
	      t21_numpre     = num_presup
IF r_t20.t20_total_mo IS NULL THEN
	LET r_t20.t20_total_mo = 0
END IF
CALL calcular_impto(r_t20.t20_numpre, r_t20.t20_total_rp) RETURNING r_t20.t20_total_impto
CALL calcular_total(r_t20.t20_numpre, r_t20.t20_total_rp) RETURNING r_t20.t20_total_neto
UPDATE talt020 SET * = r_t20.*
	WHERE t20_compania   = vg_codcia AND 
	      t20_localidad  = vg_codloc AND
	      t20_numpre     = num_presup

END FUNCTION



FUNCTION imprimir_transferencia()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE resp		CHAR(6)
DEFINE param		VARCHAR(60)

DECLARE q_imp_trans CURSOR FOR
	SELECT * FROM rept019
		WHERE r19_compania    = vg_codcia
		  AND r19_localidad   = vg_codloc
		  AND r19_cod_tran    = 'TR'
		  AND r19_ord_trabajo = rm_r21.r21_num_ot
		ORDER BY r19_num_tran
OPEN q_imp_trans
FETCH q_imp_trans INTO r_r19.*
IF STATUS = NOTFOUND THEN
	CLOSE q_imp_trans
	FREE q_imp_trans
	RETURN
END IF
CALL fl_hacer_pregunta('Desea imprimir transferencias generadas ?','Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	CLOSE q_imp_trans
	FREE q_imp_trans
	RETURN
END IF
FOREACH q_imp_trans INTO r_r19.*
	LET param = vg_codloc, ' "', r_r19.r19_cod_tran, '" ',
			r_r19.r19_num_tran
	CALL ejecuta_comando('REPUESTOS', 'RE', 'repp415 ', param)
END FOREACH

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



FUNCTION control_transf_orddes()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resul	 	SMALLINT
DEFINE r_t23		RECORD LIKE talt023.*

IF rm_r21.r21_num_ot IS NULL THEN
	CALL fl_mostrar_mensaje('No existe O.T. asociada.', 'exclamation')
	RETURN
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 69
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 19
	LET num_cols = 70
END IF
OPEN WINDOW w_213_2 AT row_ini, 06 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_talf213_2 FROM '../forms/talf213_2'
ELSE
	OPEN FORM f_talf213_2 FROM '../forms/talf213_2c'
END IF
DISPLAY FORM f_talf213_2
--#CALL mostrar_botones_to()
CALL preparar_query_to() RETURNING resul
IF resul THEN
	CLOSE WINDOW w_213_2
	RETURN
END IF
CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_r21.r21_num_ot)
	RETURNING r_t23.*
DISPLAY BY NAME rm_r21.r21_codcli, r_t23.t23_nom_cliente, r_t23.t23_numpre,
		rm_r21.r21_num_ot
WHILE TRUE
	IF vm_num_transf > 0 THEN
		CALL detalle_dettransf()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
	IF vm_num_orddes > 0 THEN
		CALL detalle_orddes()
		IF int_flag THEN
			EXIT WHILE
		END IF
	END IF
END WHILE
CLOSE WINDOW w_213_2

END FUNCTION



FUNCTION mostrar_botones_to()

DISPLAY 'Número'	TO tit_col1
DISPLAY 'BO'		TO tit_col2
DISPLAY 'BD'		TO tit_col3
DISPLAY 'Referencia'	TO tit_col4

DISPLAY 'Número'	TO tit_col5
DISPLAY 'Bd'		TO tit_col6
DISPLAY 'Fecha Ord.'	TO tit_col7
DISPLAY 'Entregar a'	TO tit_col8

END FUNCTION



FUNCTION preparar_query_to()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r34		RECORD LIKE rept034.*
DEFINE lim		SMALLINT
DEFINE cuantos		INTEGER

LET vm_max_transf = 100
LET vm_max_orddes = 100
INITIALIZE r_r34.*, r_r19.* TO NULL
SELECT * FROM rept019
	WHERE r19_compania     = vg_codcia
	  AND r19_localidad    = vg_codloc
	  AND r19_cod_tran    IN ('FA', 'TR')
	  AND r19_ord_trabajo  = rm_r21.r21_num_ot
	INTO TEMP t_r19
SELECT COUNT(*) INTO cuantos FROM t_r19
IF cuantos = 0 THEN
	DROP TABLE t_r19
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
DECLARE q_dettrans CURSOR FOR
	SELECT * FROM t_r19
		WHERE r19_compania  = vg_codcia
		  AND r19_localidad = vg_codloc
		  AND r19_cod_tran  = 'TR'
		ORDER BY r19_num_tran
LET vm_num_transf = 1
FOREACH q_dettrans INTO r_r19.*
	LET rm_dettrans[vm_num_transf].r19_num_tran    = r_r19.r19_num_tran
	LET rm_dettrans[vm_num_transf].r19_bodega_ori  = r_r19.r19_bodega_ori
	LET rm_dettrans[vm_num_transf].r19_bodega_dest = r_r19.r19_bodega_dest
	LET rm_dettrans[vm_num_transf].r19_referencia  = r_r19.r19_referencia
	LET vm_num_transf = vm_num_transf + 1
	IF vm_num_transf > vm_max_transf THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_transf  = vm_num_transf - 1
IF vm_num_transf > 0 THEN
	LET lim = vm_num_transf
	IF lim > fgl_scr_size('rm_dettrans') THEN
		LET lim = fgl_scr_size('rm_dettrans')
	END IF
	LET vm_cur_transf = 1
	CALL muestra_contadores_dettranf()
	FOR vm_cur_transf = 1 TO lim
		DISPLAY rm_dettrans[vm_cur_transf].* TO
			rm_dettrans[vm_cur_transf].*
	END FOR
END IF
IF rm_r21.r21_cod_tran IS NULL THEN
	DROP TABLE t_r19
	RETURN 0
END IF
DECLARE q_detord CURSOR FOR
	SELECT * FROM rept034
		WHERE r34_compania   = vg_codcia
		  AND r34_localidad  = vg_codloc
		  AND r34_cod_tran   = 'FA'
		  AND r34_num_tran  IN (SELECT r19_num_tran FROM t_r19
						WHERE r19_compania  = vg_codcia
						  AND r19_localidad = vg_codloc
						  AND r19_cod_tran  = 'FA')
		ORDER BY r34_num_ord_des
LET vm_num_orddes = 1
FOREACH q_detord INTO r_r34.*
	LET rm_detorddes[vm_num_orddes].r34_num_ord_des = r_r34.r34_num_ord_des
	LET rm_detorddes[vm_num_orddes].r34_bodega      = r_r34.r34_bodega
	LET rm_detorddes[vm_num_orddes].r34_fec_entrega = r_r34.r34_fec_entrega
	LET rm_detorddes[vm_num_orddes].r34_entregar_a  = r_r34.r34_entregar_a
	LET vm_num_orddes = vm_num_orddes + 1
	IF vm_num_orddes > vm_max_orddes THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_orddes = vm_num_orddes - 1
IF vm_num_orddes > 0 THEN
	LET lim = vm_num_orddes
	IF lim > fgl_scr_size('rm_detorddes') THEN
		LET lim = fgl_scr_size('rm_detorddes')
	END IF
	LET vm_cur_orddes = 0
	CALL muestra_contadores_detord()
	FOR vm_cur_orddes = 1 TO lim
		DISPLAY rm_detorddes[vm_cur_orddes].* TO
			rm_detorddes[vm_cur_orddes].*
	END FOR
END IF
DROP TABLE t_r19
RETURN 0

END FUNCTION



FUNCTION detalle_dettransf()
DEFINE j		SMALLINT

CALL set_count(vm_num_transf)
DISPLAY ARRAY rm_dettrans TO rm_dettrans.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F1,CONTROL-W) 
		CALL control_visor_teclas_caracter_6() 
	ON KEY(F5)
		IF vm_num_orddes > 0 THEN
			LET int_flag = 0
			EXIT DISPLAY
		END IF
	ON KEY(F6)
		LET vm_cur_transf = arr_curr()
		CALL ver_transferencia()
		LET int_flag = 0
	ON KEY(F8)
		LET vm_cur_transf = arr_curr()
		CALL imprimir_to('T')
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_orddes > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Orden Despacho") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("F6", "Transferencia") 
		--#CALL dialog.keysetlabel("F7", "") 
		--#CALL dialog.keysetlabel("F8", "Imprimir Trans.") 
	--#BEFORE ROW 
		--#LET vm_cur_transf = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_dettranf()
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY
END DISPLAY
LET vm_cur_transf = 0
--#CALL muestra_contadores_dettranf()

END FUNCTION 



FUNCTION detalle_orddes()
DEFINE j		SMALLINT

CALL set_count(vm_num_orddes)
DISPLAY ARRAY rm_detorddes TO rm_detorddes.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F1,CONTROL-W) 
		CALL control_visor_teclas_caracter_7() 
	ON KEY(F5)
		IF vm_num_transf > 0 THEN
			LET int_flag = 0
			EXIT DISPLAY
		END IF
	ON KEY(F7)
		LET vm_cur_orddes = arr_curr()
		CALL ver_orden_despacho()
		LET int_flag = 0
	ON KEY(F8)
		LET vm_cur_orddes = arr_curr()
		CALL imprimir_to('O')
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F1","") 
		--#IF vm_num_transf > 0 THEN
			--#CALL dialog.keysetlabel("F5", "Transferencias") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5","") 
		--#END IF
		--#CALL dialog.keysetlabel("F6", "") 
		--#CALL dialog.keysetlabel("F7", "Orden Despacho") 
		--#CALL dialog.keysetlabel("F8", "Imprimir Orden") 
	--#BEFORE ROW 
		--#LET vm_cur_orddes = arr_curr()
		--#LET j = scr_line()
		--#CALL muestra_contadores_detord()
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
LET vm_cur_orddes = 0
--#CALL muestra_contadores_detord()

END FUNCTION 



FUNCTION muestra_contadores_dettranf()

--#DISPLAY BY NAME vm_cur_transf, vm_num_transf

END FUNCTION 



FUNCTION muestra_contadores_detord()

--#DISPLAY BY NAME vm_cur_orddes, vm_num_orddes

END FUNCTION 



FUNCTION ver_transferencia()
DEFINE param		VARCHAR(60)

LET param = vg_codloc, ' "TR" ', rm_dettrans[vm_cur_transf].r19_num_tran, ' "P"'
CALL ejecuta_comando('REPUESTOS', 'RE', 'repp216 ', param)

END FUNCTION 



FUNCTION ver_orden_despacho()
DEFINE param		VARCHAR(60)

LET param = vg_codloc, ' "', rm_r21.r21_cod_tran, '" ', rm_r21.r21_num_tran,
		' "C" "T" "', rm_detorddes[vm_cur_orddes].r34_bodega, '" ',
		rm_detorddes[vm_cur_orddes].r34_num_ord_des
CALL ejecuta_comando('REPUESTOS', 'RE', 'repp231 ', param)

END FUNCTION 



FUNCTION imprimir_to(flag)
DEFINE flag		CHAR(1)
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

CASE flag
	WHEN 'T'
		LET prog  = 'repp415 '
		LET param = vg_codloc, ' "TR" ',
				rm_dettrans[vm_cur_transf].r19_num_tran
	WHEN 'O'
		LET prog = 'repp431 '
		LET param = vg_codloc, ' "',
				rm_detorddes[vm_cur_orddes].r34_bodega, '" ',
				rm_detorddes[vm_cur_orddes].r34_num_ord_des
END CASE
CALL ejecuta_comando('REPUESTOS', 'RE', prog, param)

END FUNCTION 



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

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
DISPLAY '<F7>      Transf./Orden Desp.'      AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_6() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ordenes Despachos'        AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Transferencia'            AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprmir Transferencia'    AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_7() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Transferencias'           AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Orden Despacho'           AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprmir Orden Despacho'   AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
