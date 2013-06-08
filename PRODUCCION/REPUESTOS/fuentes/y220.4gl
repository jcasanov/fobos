-----------------------------------------------------------------------------
-- Titulo           : repp220.4gl - Mantenimiento de Proforma
-- Elaboracion      : 06-Dic-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp220 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
DATABASE acero_gm

GLOBALS

DEFINE vg_producto	VARCHAR(10)
DEFINE vg_proceso	LIKE gent054.g54_proceso
DEFINE vg_base		LIKE gent051.g51_basedatos
DEFINE vg_modulo	LIKE gent050.g50_modulo
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vg_usuario	LIKE gent005.g05_usuario
DEFINE vg_separador	LIKE fobos.fb_separador
DEFINE vg_dir_fobos	LIKE fobos.fb_dir_fobos
DEFINE vg_gui		SMALLINT

DEFINE rg_gen		RECORD LIKE gent000.* 
DEFINE rg_cia		RECORD LIKE gent001.* 
DEFINE rg_loc		RECORD LIKE gent002.* 
DEFINE rg_mod		RECORD LIKE gent050.* 
DEFINE rg_pro		RECORD LIKE gent054.* 

DEFINE ag_one 		ARRAY[9] OF CHAR (6)
DEFINE ag_two 		ARRAY[9] OF CHAR (10)
DEFINE ag_three 	ARRAY[9] OF CHAR (9)
DEFINE ag_four 		ARRAY[9] OF CHAR (13)
DEFINE ag_five 		ARRAY[9] OF CHAR (13)

END GLOBALS
DEFINE r_detalle	ARRAY[500] OF RECORD                        
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
DEFINE rm_c01		RECORD LIKE cxct001.*
DEFINE rm_c02		RECORD LIKE cxct002.*
DEFINE rm_r23		RECORD LIKE rept023.*
DEFINE rm_r24		RECORD LIKE rept024.*
DEFINE rm_g05		RECORD LIKE gent005.*

DEFINE vm_rows 		ARRAY[500] OF INTEGER  	-- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO           
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS             
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS A LEER        
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
IF num_args() <> 4 AND num_args() <> 5 THEN     -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')      
	EXIT PROGRAM                                                            
END IF                                                                          
LET vg_base     = arg_val(1)                                                    
LET vg_modulo   = arg_val(2)                                                    
LET vg_codcia   = arg_val(3)                                                    
LET vg_codloc   = arg_val(4)                                                    
LET vm_numprof  = arg_val(5)                                                    
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
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN                                              
	RETURN                                                
END IF                                                                          
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING rm_r00.*		   
IF rm_r00.r00_compania IS NULL THEN                                             
	CALL fl_mostrar_mensaje('No está creada una compañía para el módulo de inventarios.','stop')
	RETURN                                                                  
END IF                                                                          
IF rm_r00.r00_estado <> 'A' THEN                                                
	CALL fl_mostrar_mensaje('La compañía está con status BLOQUEADO.', 'stop')
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
LET vm_max_rows = 500
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
SELECT r02_codigo INTO vm_bod_sstock FROM rept002                               
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
		IF num_args() = 5 THEN                                          
			HIDE OPTION 'Modificar'                                 
			HIDE OPTION 'Ingresar'                                  
			HIDE OPTION 'Consultar'                                 
			SHOW OPTION 'Imprimir'                                  
			SHOW OPTION 'Ver Detalle'
			CALL control_consulta()                                 
			CALL control_ver_detalle()
		END IF                                                          
	COMMAND KEY('I') 'Ingresar' 		'Ingresar nuevos registros.'    
                CALL control_ingreso()                                          
		IF vm_num_rows >= 1 THEN                                        
			SHOW OPTION 'Modificar'                                
			SHOW OPTION 'Ver Detalle'                               
			SHOW OPTION 'Hacer Preventa'                            
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
			SHOW OPTION 'Imprimir'   
                        HIDE OPTION 'Avanzar'   
                        HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Imprimir'
                        	HIDE OPTION 'Modificar'
				HIDE OPTION 'Ver Detalle'
				HIDE OPTION 'Hacer Preventa'
                        END IF 
                ELSE          
			SHOW OPTION 'Imprimir'   
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
			CALL control_imprimir_proforma()
		END IF
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
INITIALIZE rm_g14.*, rm_g20.*, rm_c01.*, rm_c02.* TO NULL
INITIALIZE rm_r21.*, rm_r22.* TO NULL
LET rm_r21.r21_fecing     = CURRENT 
LET rm_r21.r21_usuario    = vg_usuario
LET rm_r21.r21_compania   = vg_codcia
LET rm_r21.r21_localidad  = vg_codloc
--LET rm_r21.r21_bodega     = rm_r00.r00_bodega_fact 
LET rm_r21.r21_bodega     = retorna_bodega_localidad(vg_codcia, vg_codloc)
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
CALL control_imprimir_proforma() 
CALL fl_mensaje_registro_ingresado()

END FUNCTION                                                                               


FUNCTION control_modificacion()
DEFINE cliente 		LIKE rept021.r21_codcli
DEFINE done		SMALLINT
DEFINE cambio_precios	SMALLINT

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
	UPDATE rept021
		SET * = rm_r21.* 
		WHERE CURRENT OF q_up2
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
	COMMIT WORK 
	CALL fl_mensaje_registro_modificado()  
END IF      

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(600)
DEFINE expr_sql_2	CHAR(600)
DEFINE query		CHAR(600)
DEFINE r_r21		RECORD LIKE rept021.* 	-- CABECERA PROFORMA

INITIALIZE expr_sql_2 TO NULL
CLEAR FORM
CALL control_DISPLAY_botones()

LET INT_FLAG = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql 
		  ON r21_numprof,  r21_num_tran,  r21_moneda,   
		     r21_codcli,   r21_dias_prof, r21_nomcli, r21_cedruc,
		     r21_dircli,   r21_telcli,    r21_vendedor
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
			CALL fl_ayuda_vendedores(vg_codcia)
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo	
				DISPLAY BY NAME rm_r21.r21_vendedor
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF
		END IF
		IF INFIELD(r21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN
				LET rm_r21.r21_codcli = rm_c02.z02_codcli
				LET rm_r21.r21_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r21.r21_codcli,
						rm_r21.r21_nomcli
			END IF 
		END IF
		LET int_flag = 0
	AFTER FIELD r21_vendedor
		IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
			DISPLAY rm_vend.r01_codigo TO r21_vendedor
			DISPLAY rm_vend.r01_nombres TO nom_vendedor
		END IF		
		LET rm_r01.r01_codigo = GET_FLDBUF(r21_vendedor)
		IF rm_r01.r01_codigo IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_r01.r01_codigo)
				RETURNING rm_r01.*       
			DISPLAY rm_r01.r01_nombres TO nom_vendedor
		ELSE
			CLEAR nom_vendedor
		END IF                        
	BEFORE CONSTRUCT
		DISPLAY rm_vend.r01_codigo TO r21_vendedor
		DISPLAY rm_vend.r01_nombres TO nom_vendedor
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

IF expr_sql_2 IS NOT NULL THEN
	LET expr_sql = expr_sql CLIPPED || ' AND ' || expr_sql_2 CLIPPED
END IF

LET query = 'SELECT *, ROWID FROM rept021 ', 
		' WHERE r21_compania  = ', vg_codcia,
		'   AND r21_localidad = ', vg_codloc,
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
			CALL fl_ayuda_vendedores(vg_codcia) 
				RETURNING rm_r01.r01_codigo, rm_r01.r01_nombres
			IF rm_r01.r01_codigo IS NOT NULL THEN                
				LET rm_r21.r21_vendedor = rm_r01.r01_codigo
				DISPLAY BY NAME rm_r21.r21_vendedor 
				DISPLAY rm_r01.r01_nombres TO nom_vendedor
			END IF  
		END IF      
		IF INFIELD(r21_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING rm_c02.z02_codcli, rm_c01.z01_nomcli
			IF rm_c02.z02_codcli IS NOT NULL THEN   
				LET rm_r21.r21_codcli = rm_c02.z02_codcli
				LET rm_r21.r21_nomcli = rm_c01.z01_nomcli
				DISPLAY BY NAME rm_r21.r21_codcli, 
						rm_r21.r21_nomcli 
			END IF   
		END IF    
		LET int_flag = 0  
	ON KEY(F5)
		CALL control_crear_cliente() 
		LET INT_FLAG = 0    
	BEFORE INPUT            
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r21_vendedor                      
		IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
			LET rm_r21.r21_vendedor = rm_vend.r01_codigo 
			DISPLAY BY NAME rm_r21.r21_vendedor	
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
				RETURNING rm_c01.*  
			IF rm_c01.z01_codcli IS NULL THEN	
				CALL fl_mostrar_mensaje('No existe código de cliente.','exclamation')
				NEXT FIELD r21_codcli	
			END IF	
			LET rm_r21.r21_nomcli    = rm_c01.z01_nomcli 
			LET rm_r21.r21_dircli    = rm_c01.z01_direccion1
			IF rm_r21.r21_codcli <> rm_r00.r00_codcli_tal THEN    
				LET rm_r21.r21_cedruc = rm_c01.z01_num_doc_id
			END IF
			LET rm_r21.r21_telcli    = rm_c01.z01_telefono1
			DISPLAY BY NAME rm_r21.r21_nomcli, rm_r21.r21_dircli,
					rm_r21.r21_cedruc, rm_r21.r21_telcli
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, 
				rm_r21.r21_codcli) RETURNING rm_c02.*
			IF rm_c02.z02_codcli IS NULL THEN	
				CALL fl_mostrar_mensaje('Cliente no está activado para esta localidad.','exclamation')
				NEXT FIELD r21_codcli	
			END IF	
			IF rm_c01.z01_estado <>'A' THEN
                              	CALL fl_mostrar_mensaje('Cliente está bloqueado.','exclamation')          
                        	NEXT FIELD r21_codcli
                        END IF  
                END IF         
		IF rm_r21.r21_cedruc IS NOT NULL THEN
			CALL fl_validar_cedruc_dig_ver(rm_r21.r21_cedruc)
				RETURNING resul
			IF NOT resul THEN
				NEXT FIELD r21_cedruc
			END IF  
		END IF  
	AFTER FIELD r21_flete
		CALL calcula_totales(vm_ind_arr,1)      
	AFTER INPUT
		IF NOT valida_cliente_consumidor_final(rm_r21.r21_codcli) THEN
			--NEXT FIELD r21_codcli
		END IF
		CALL control_saldos_vencidos(vg_codcia, rm_r21.r21_codcli, 1)
				RETURNING flag_error
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
DEFINE item_anterior	LIKE rept010.r10_codigo  
DEFINE num_elm		SMALLINT       
DEFINE salir  		SMALLINT     
DEFINE in_array		SMALLINT   
DEFINE cant_prof	DECIMAL (8,2)   
DEFINE mensaje		VARCHAR(100)
DEFINE cod_bod		LIKE rept002.r02_codigo 
DEFINE name_bod		LIKE rept002.r02_nombre 
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*  
DEFINE max_descto	DECIMAL(4,2)
DEFINE max_descto_c	DECIMAL(4,2)
DEFINE subtot_net	DECIMAL(14,2)
DEFINE precio_ant 	LIKE rept022.r22_precio

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
			LET item_anterior = r_detalle[i].r22_item  
			IF r_detalle[i].r22_item IS NOT NULL THEN
				CALL fl_lee_item(vg_codcia, r_detalle[i].r22_item)
					RETURNING rm_r10.*
				CALL muestra_descripciones(r_detalle[i].r22_item,
					rm_r10.r10_linea, rm_r10.r10_sub_linea,
					rm_r10.r10_cod_grupo, 
					rm_r10.r10_cod_clase)
				DISPLAY rm_r10.r10_nombre TO nom_item
			ELSE
				CLEAR nom_item, descrip_1, descrip_2, descrip_3,
					descrip_4, nom_marca
			END IF
			LET num = arr_count()
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
				CALL fl_ayuda_bodegas_rep(vg_codcia, 'F') 
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
							r_detalle[i].r22_item)
				DISPLAY r_detalle[i].r22_bodega TO
					r_detalle[j].r22_bodega
				NEXT FIELD r22_bodega
			END IF  
		ON KEY(F9)
			LET subtot_net = rm_r21.r21_tot_bruto -
					 rm_r21.r21_tot_dscto
			ERROR 'El Subtotal - Descuento es : ', subtot_net
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
                       		DISPLAY rm_r10.r10_nombre TO nom_item
				CALL muestra_descripciones(r_detalle[i].r22_item,
					rm_r10.r10_linea, rm_r10.r10_sub_linea,
					rm_r10.r10_cod_grupo, 
					rm_r10.r10_cod_clase)
                       		IF rm_r10.r10_estado = 'B' THEN           
                       			CALL fl_mostrar_mensaje('El Item está con status bloqueado.','exclamation')           
                       			NEXT FIELD r22_item 
                       		END IF                     
				IF rm_r10.r10_comentarios[1, 10] = 'INCOMPLETO'
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

SELECT MAX(r21_numprof) + 1 INTO rm_r21.r21_numprof
	FROM  rept021 
	WHERE r21_compania  = vg_codcia 
	AND   r21_localidad = vg_codloc
IF rm_r21.r21_numprof IS NULL THEN   
	LET rm_r21.r21_numprof = 1  
END IF                            
INSERT INTO rept021 VALUES (rm_r21.*) 
DISPLAY BY NAME rm_r21.r21_numprof 
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
		IF rm_c01.z01_paga_impto IS NULL OR 
	  	   rm_c01.z01_paga_impto <> 'N' THEN
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
LET vm_total = vm_subtotal - vm_descuento + vm_impuesto + rm_r21.r21_flete
LET rm_r21.r21_tot_costo = vm_costo    
LET rm_r21.r21_tot_bruto = vm_subtotal
LET rm_r21.r21_tot_dscto = vm_descuento
LET rm_r21.r21_tot_neto  = vm_total   
DISPLAY BY NAME rm_r21.r21_tot_bruto, rm_r21.r21_tot_dscto,
		vm_impuesto, rm_r21.r21_tot_neto

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
		CALL llamar_visor_teclas()
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL fl_lee_item(vg_codcia,r_detalle[i].r22_item) 
			RETURNING r_r10.*  
		DISPLAY r_r10.r10_nombre TO nom_item 
		CALL muestra_descripciones(r_detalle[i].r22_item,
			r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, 
			r_r10.r10_cod_clase)
        --#BEFORE DISPLAY 
                --#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL fl_lee_item(vg_codcia,r_detalle[i].r22_item) 
			--#RETURNING r_r10.*  
		--#DISPLAY r_r10.r10_nombre TO nom_item 
		--#CALL muestra_descripciones(r_detalle[i].r22_item,
			--#r_r10.r10_linea, r_r10.r10_sub_linea,
			--#r_r10.r10_cod_grupo, 
			--#r_r10.r10_cod_clase)
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY 

END FUNCTION 



FUNCTION control_imprimir_proforma()
DEFINE command_run 	VARCHAR(100)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
	LET command_run = run_prog, 'repp419 ',vg_base, ' ',
			   vg_modulo, ' ', vg_codcia, ' ',
			   vg_codloc, ' ',rm_r21.r21_numprof
	RUN command_run

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
	bodega			LIKE rept022.r22_bodega,
	item			LIKE rept022.r22_item, 
	precio			LIKE rept022.r22_precio,
	descto			LIKE rept022.r22_porc_descto, 
	linea			LIKE rept010.r10_linea,  
	cantidad		LIKE rept022.r22_cantidad 
END RECORD
DEFINE mensaje		VARCHAR(200)
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
CALL fl_hacer_pregunta('Esta seguro de convertir en preventa esta proforma','No')
	RETURNING resp
IF resp = 'No' THEN
	RETURN
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
		GROUP BY r22_bodega, r22_item, r22_precio, r22_porc_descto, r10_linea
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
					'precios diferentes. Se detendrá ',
					'la generación de la preventa.'
				--CALL fgl_winmessage(vg_producto, mensaje, 'stop') 
				CALL fl_mostrar_mensaje(mensaje, 'stop')
				RETURN 
			END IF
			IF r_detprev.descto <> r_r24.r24_descuento THEN
				ROLLBACK WORK
				LET mensaje = 'El item ',
					r_detprev.item CLIPPED,
					' se ha digitado dos ',
					'veces en la proforma, con ',
					'descuentos diferentes. Se detendrá ',
					'la generación de la preventa.'
				--CALL fgl_winmessage(vg_producto, mensaje, 'stop')
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
		IF r_r10.r10_costo_mb = 0 THEN
			LET mensaje = 'El Item ',
			     rm_r24.r24_item, '  ',
			     ' no tiene costo. Se debe hacer un ajuste al costo.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
				RETURN
		END IF	
		IF r_r11.r11_stock_act < rm_r24.r24_cant_ped THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_r24.r24_bodega) 
				RETURNING r_r02.* 
			IF r_r02.r02_tipo IS NULL OR r_r02.r02_tipo <> 'S' THEN
        			LET rm_r24.r24_cant_ven = r_r11.r11_stock_act
				LET mensaje = 'El Item ',
				     rm_r24.r24_item CLIPPED, '  ',
				     r_r10.r10_nombre CLIPPED, '  ',
				     '  tiene en stock ',
				     r_r11.r11_stock_act,
				     '  y la cantidad pedida es ',
				     rm_r24.r24_cant_ped, '. ',
				     'Modifique la proforma y vuelva a ', 
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
COMMIT WORK
LET mensaje = 'Se generó la preventa: ', rm_r23.r23_numprev, '.'
CALL fl_mostrar_mensaje(mensaje, 'info')
DISPLAY BY NAME rm_r23.r23_numprev

END FUNCTION



FUNCTION eliminar_preventa_anterior()
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
	DELETE FROM cajt010 
		WHERE j10_compania    = r_r23.r23_compania 
		  AND j10_localidad   = r_r23.r23_localidad 
		  AND j10_tipo_fuente = 'PR'
		  AND j10_num_fuente  =	r_r23.r23_numprev 
		  AND j10_tipo_destino IS NULL
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

CALL retorna_tam_arr()
FOR i = 1 TO vm_size_arr 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
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
        IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 

LET i = i - 1
IF i = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
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
		IF r_detalle[i].stock_loc > 0 AND 
		   r_detalle[i].r22_cantidad > r_detalle[i].stock_loc THEN
			LET r_detalle[i].r22_cantidad = r_detalle[i].stock_loc
		END IF		
	END IF		
	--- VALIDACIÓN DE VENTA SIN STOCK              
	LET stock = r_detalle[i].r22_cantidad - r_detalle[i].stock_loc	
	IF stock > 0 AND r_detalle[i].r22_bodega <> vm_bod_sstock THEN
		LET r_detalle[i].r22_bodega = vm_bod_sstock
	END IF         
END FOR
IF vm_ind_arr < vm_size_arr THEN
	LET vm_size_arr = vm_ind_arr
END IF
IF cambiar_precio THEN
	CALL calcula_totales(vm_num_detalles, 0)   
END IF

FOR i = 1 TO vm_size_arr 
	DISPLAY r_detalle[i].* TO r_detalle[i].*
END FOR

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
LET stock_tot = 0
LET stock_loc = 0
LET bode      = bodega
LET bodega    = NULL
FOREACH q_barc INTO r_r11.*
	CALL fl_lee_bodega_rep(codcia, r_r11.r11_bodega)
		RETURNING r_r02.*                
	IF r_r02.r02_factura IS NULL OR r_r02.r02_factura <> 'S' THEN
		CONTINUE FOREACH
	END IF
	IF r_r02.r02_tipo = 'S' OR r_r02.r02_area = 'T' THEN
		CONTINUE FOREACH
	END IF
	IF r_r02.r02_localidad = vg_codloc THEN
		LET stock_loc = stock_loc + r_r11.r11_stock_act
		IF r_r11.r11_stock_act > 0 THEN
			LET bodega    = r_r11.r11_bodega	
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



FUNCTION muestra_stock_local_nacional(l, codigo)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE tot_stock_loc	DECIMAL (8,2)
DEFINE tot_stock_rem	DECIMAL (8,2)
DEFINE tot_stock_gen 	DECIMAL (8,2)
DEFINE i, l, salir	SMALLINT

CALL fl_lee_item(vg_codcia, codigo) RETURNING r_r10.*
IF r_r10.r10_compania IS NULL THEN
	RETURN
END IF
OPEN WINDOW w_stln AT 3, 30 WITH 20 ROWS, 48 COLUMNS
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
	CALL control_detalle_bodega_loc(l) RETURNING salir
END IF
IF i_rem > 0 AND salir = 0 THEN
	CALL control_detalle_bodega_rem(l) RETURNING salir
END IF
DELETE FROM temp_loc
DELETE FROM temp_rem
CLOSE WINDOW w_stln
LET int_flag = 0

END FUNCTION



FUNCTION control_detalle_bodega_loc(l)
DEFINE i, j, l, salir	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 1
LET vm_columna_1 = 1
LET vm_columna_2 = 3
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
	CALL set_count(i)
	DISPLAY ARRAY r_loc TO r_loc.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
        	        EXIT DISPLAY  
        	ON KEY(RETURN)   
			LET salir = 1
			LET i = arr_curr()	
			LET r_detalle[l].r22_bodega = r_loc[i].bod_loc
        	        EXIT DISPLAY  
		ON KEY(F1,CONTROL-W) 
			CALL control_visor_teclas_caracter_3() 
		ON KEY(F5)
			IF i_rem > 0 THEN
				CALL control_detalle_bodega_rem(l)
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



FUNCTION control_detalle_bodega_rem(l)
DEFINE i, j, l, salir 	SMALLINT
DEFINE col 		SMALLINT
DEFINE query		CHAR(400)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col          = 1
LET vm_columna_1 = 1
LET vm_columna_2 = 3
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
	CALL set_count(i)
	DISPLAY ARRAY r_rem TO r_rem.*
        	ON KEY(INTERRUPT)   
			LET salir = 1
	                EXIT DISPLAY  
        	ON KEY(F1,CONTROL-W) 
			CALL control_visor_teclas_caracter_4() 
		ON KEY(F5)
			IF i_loc > 0 THEN
				CALL control_detalle_bodega_loc(l)
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
IF rm_vend.r01_compania IS NULL OR rm_g05.g05_tipo = 'AM' THEN
	RETURN r_r77.r77_dscmax_ger, r_r77.r77_dscmax_ven
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
--#DISPLAY 'Cant.'		TO tit_col4
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

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET command_run = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS', 
	           vg_separador, 'fuentes', vg_separador, run_prog,
		   'cxcp101 ', vg_base, ' ','CO', ' ',vg_codcia, ' ',
		   vg_codloc
RUN command_run

END FUNCTION



FUNCTION control_crear_item()
DEFINE command_run	VARCHAR(100)
DEFINE run_prog		CHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
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

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
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



FUNCTION retorna_bodega_localidad(codcia, codloc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE mensaje		VARCHAR(80)
DEFINE bodega		LIKE rept002.r02_codigo

DECLARE qu_bolo CURSOR FOR
	SELECT r02_codigo FROM rept002
		WHERE r02_compania = codcia AND r02_localidad = codloc AND 
		      r02_tipo = 'F'
OPEN qu_bolo
FETCH qu_bolo INTO bodega
IF status = NOTFOUND THEN
	LET mensaje = 'No existe bodega física para localidad: '|| codloc
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



FUNCTION fl_mostrar_mensaje(texto, tipo_icono)
DEFINE texto		CHAR(400)
DEFINE tipo_icono	CHAR(11)
DEFINE car_lin, i	SMALLINT
DEFINE ind_ini, ind_fin	SMALLINT
DEFINE num_lin, aux	SMALLINT
DEFINE r_lineas	ARRAY[10] OF VARCHAR(60)
DEFINE long_text, key	SMALLINT

IF vg_gui = 1 THEN
	--#CALL fgl_winmessage(vg_producto, texto, tipo_icono)
ELSE
	LET car_lin = 60
	LET num_lin = 1
	LET long_text = LENGTH(texto)
{
	IF long_text <= 80 AND UPSHIFT(tipo_icono) <> 'STOP' AND 
		UPSHIFT(tipo_icono) <> 'INFO' THEN
		ERROR texto ATTRIBUTE(REVERSE, BLINK)
		RETURN
	END IF
}
	LET num_lin = 0
	LET ind_ini = 1
	LET ind_fin = car_lin
	WHILE TRUE
		IF long_text <= car_lin THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto
			EXIT WHILE
		END IF
		IF texto[ind_fin, ind_fin] = ' ' THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto[ind_ini, ind_fin - 1]
			LET ind_ini = ind_fin + 1
			LET ind_fin = ind_fin + car_lin
			IF ind_fin > long_text THEN
				LET num_lin = num_lin + 1
				LET r_lineas[num_lin] = 
					texto[ind_ini, long_text]
				EXIT WHILE
			END IF	
		ELSE
			LET ind_fin = ind_fin - 1
		END IF
	END WHILE		
	LET aux = num_lin + 1
	OPEN WINDOW w_men AT 10,10 WITH aux ROWS, 62 COLUMNS
		ATTRIBUTE(BORDER)
	CASE UPSHIFT(tipo_icono)
		WHEN 'STOP'
			LET aux = (car_lin - 13) / 2
			DISPLAY ' ERROR FATAL ' AT 1, aux ATTRIBUTE(REVERSE)
		WHEN 'INFO'
			LET aux = (car_lin - 7) / 2
			DISPLAY ' AVISO ' AT 1, aux ATTRIBUTE(REVERSE)
		OTHERWISE
			LET aux = (car_lin - 7) / 2
			DISPLAY ' ERROR ' AT 1, aux ATTRIBUTE(REVERSE)
	END CASE
	FOR i = 1 TO num_lin
		LET aux = i + 1
		DISPLAY r_lineas[i] AT aux,2
	END FOR
	LET key = fgl_getkey()
	CLOSE WINDOW w_men
END IF

END FUNCTION



FUNCTION fl_marca_registrada_producto()                                             
SELECT fb_aplicativo INTO vg_producto FROM fobos
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Tabla fobos está vacía', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_activar_base_datos(base)
DEFINE base		CHAR(20)
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*

CLOSE DATABASE 
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	CALL fl_mostrar_mensaje('No se pudo abrir base de datos: ' || vg_base, 
		'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SELECT * FROM gent051 WHERE g51_basedatos = base
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No se pudo abrir base de datos: ' || vg_base, 
		'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_seteos_defaults()
DEFINE resp		CHAR(6)
DEFINE r_usuario        RECORD LIKE gent005.*
DEFINE estado           CHAR(9)
DEFINE clave 	        LIKE gent005.g05_clave

SET ISOLATION TO DIRTY READ
LET vg_gui = fgl_getenv('FGLGUI')
CALL fl_lee_configuracion_facturacion() RETURNING rg_gen.*
CALL fl_marca_registrada_producto()
CALL fl_retorna_usuario()
CALL fl_separador()
IF vg_codcia = 0 OR vg_codcia IS NULL THEN
	LET vg_codcia = fl_retorna_compania_default()
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF vg_codloc = 0 OR vg_codloc IS NULL THEN
	LET vg_codloc = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_control_acceso_procesos(vg_usuario, vg_codcia, vg_modulo, vg_proceso) 
OPTIONS ACCEPT KEY	F12,
	INPUT WRAP,
	FORM LINE	FIRST + 2,
	MENU LINE	FIRST + 1,
	COMMENT LINE 	LAST - 1,
	PROMPT LINE	LAST,
	MESSAGE LINE	LAST - 2,
	NEXT KEY	F3,	
	PREVIOUS KEY	F4,
	INSERT KEY	F10,
	DELETE KEY	F11

END FUNCTION



FUNCTION fl_validar_parametros()
DEFINE mensaje		VARCHAR(100)

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	LET mensaje = 'No existe módulo: ' || vg_modulo
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	LET mensaje = 'No existe compañía: '|| vg_codcia
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	LET mensaje = 'Compañía no está activa: ' || vg_codcia
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	LET mensaje = 'No existe localidad: ' || vg_codloc
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	LET mensaje = 'Localidad no está activa: '|| vg_codloc
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fl_mostrar_mensaje('Combinación compañía/localidad no existe.', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_cabecera_pantalla(cod_cia, cod_local, cod_mod, cod_proc)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_local	LIKE gent002.g02_localidad
DEFINE cod_mod		LIKE gent050.g50_modulo
DEFINE cod_proc		LIKE gent054.g54_proceso
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*
DEFINE r_proc		RECORD LIKE gent054.*
DEFINE r_mod		RECORD LIKE gent050.*
DEFINE titulo		CHAR(54)
DEFINE num_row 		SMALLINT

LET vg_proceso  = cod_proc
CALL fl_lee_compania(cod_cia) RETURNING r_cia.*
IF r_cia.g01_compania  IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código cía. en gent001: ' || cod_cia, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(cod_cia, cod_local) RETURNING r_loc.*
IF r_loc.g02_compania  IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código localidad. en gent0021: ' || cod_local, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_modulo(cod_mod) RETURNING r_mod.*
IF r_mod.g50_modulo  IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código módulo en gent050: ' || cod_mod, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso(cod_mod, cod_proc) RETURNING r_proc.*
IF r_proc.g54_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe código proceso en gent054: ' || cod_proc, 'stop')
	EXIT PROGRAM
END IF
LET titulo = r_cia.g01_abreviacion CLIPPED, " (", r_loc.g02_abreviacion CLIPPED,
	     ")"
IF vg_gui = 1 THEN
	LET num_row = 1
	OPEN WINDOW wt AT 1,2 WITH 1 ROWS, 90 COLUMNS ATTRIBUTE(BORDER)
	DISPLAY titulo AT num_row,1 ATTRIBUTE(BLUE)
ELSE
	LET num_row = 2
	CALL fgl_drawbox(3,80,1,1)
	DISPLAY titulo AT num_row,2 ATTRIBUTE(BLUE)
END IF
LET titulo = r_mod.g50_nombre CLIPPED, ": ", r_proc.g54_nombre CLIPPED
LET titulo = fl_justifica_titulo('D', titulo, 54)
DISPLAY titulo AT num_row,25 ATTRIBUTE(BLUE)

END FUNCTION



FUNCTION fl_nivel_isolation()

SET ISOLATION TO DIRTY READ

END FUNCTION



FUNCTION fl_chequeo_mes_proceso_rep(cod_cia)
DEFINE cod_cia          LIKE rept000.r00_compania
DEFINE r_rep            RECORD LIKE rept000.*

CALL fl_lee_compania_repuestos(cod_cia) RETURNING r_rep.*
IF MONTH(TODAY) <> r_rep.r00_mespro THEN
	CALL fl_mostrar_mensaje( 'Mes de proceso incorrecto. Debe ejecutar cierre mensual de Inventarios', 'stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION fl_lee_compania_repuestos(cod_cia)
DEFINE cod_cia		LIKE rept000.r00_compania
DEFINE r		RECORD LIKE rept000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept000 
	WHERE r00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_usuario(usuario)
DEFINE usuario		LIKE gent005.g05_usuario 
DEFINE r		RECORD LIKE gent005.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent005 WHERE g05_usuario = usuario
RETURN r.*

END FUNCTION



FUNCTION fl_mensaje_registro_ingresado()

CALL fl_mostrar_mensaje('Registro grabado Ok.', 'info')

END FUNCTION



FUNCTION fl_mensaje_registro_modificado()

CALL fl_mostrar_mensaje('Registro actualizado Ok.', 'info')

END FUNCTION



FUNCTION fl_mensaje_consultar_primero()

CALL fl_mostrar_mensaje('Ejecute una consulta primero', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_bloqueo_otro_usuario()

CALL fl_mostrar_mensaje('Registro está siendo modificado por otro usuario','exclamation')

END FUNCTION



FUNCTION fl_mensaje_consulta_sin_registros()

CALL fl_mostrar_mensaje('No se encontraron registros con el criterio indicado', 'exclamation')

END FUNCTION



FUNCTION fl_mensaje_estado_bloqueado()

CALL fl_mostrar_mensaje('Registro está bloqueado', 'exclamation')

END FUNCTION



FUNCTION fl_lee_moneda(moneda)
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r		RECORD LIKE gent013.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent013 WHERE g13_moneda = moneda
RETURN r.*

END FUNCTION




FUNCTION fl_lee_proforma_rep(cod_cia, cod_loc, numprof)
DEFINE cod_cia		LIKE rept021.r21_compania
DEFINE cod_loc		LIKE rept021.r21_localidad
DEFINE numprof		LIKE rept021.r21_numprof
DEFINE r		RECORD LIKE rept021.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept021 
	WHERE r21_compania = cod_cia AND r21_localidad = cod_loc AND
	      r21_numprof  = numprof
RETURN r.*

END FUNCTION



FUNCTION fl_lee_vendedor_rep(cod_cia, cod_vend)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_vend		LIKE rept001.r01_codigo
DEFINE r		RECORD LIKE rept001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept001 
	WHERE r01_compania = cod_cia AND r01_codigo = cod_vend
RETURN r.*

END FUNCTION



FUNCTION fl_lee_cliente_general(cod_cliente)
DEFINE cod_cliente	LIKE cxct001.z01_codcli
DEFINE r		RECORD LIKE cxct001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct001 WHERE z01_codcli = cod_cliente
RETURN r.*

END FUNCTION


FUNCTION fl_lee_cliente_localidad(cod_cia, cod_loc, cod_cliente)
DEFINE cod_cia		LIKE cxct002.z02_compania
DEFINE cod_loc		LIKE cxct002.z02_localidad
DEFINE cod_cliente	LIKE cxct002.z02_codcli
DEFINE r		RECORD LIKE cxct002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct002 WHERE z02_compania = cod_cia
AND z02_localidad = cod_loc
AND z02_codcli = cod_cliente
RETURN r.*

END FUNCTION



FUNCTION fl_validar_cedruc_dig_ver(cedruc)
DEFINE cedruc		VARCHAR(15)
DEFINE valor		ARRAY[15] OF SMALLINT
DEFINE suma, i, lim	SMALLINT
DEFINE residuo_suma	SMALLINT

LET lim    = 10
LET cedruc = cedruc CLIPPED
IF (LENGTH(cedruc) <> lim) AND (LENGTH(cedruc) <> 13) THEN
	CALL fl_mostrar_mensaje('El número de digitos de cédula/ruc es incorrecto.', 'exclamation')
	RETURN 0
END IF
IF (cedruc[1, 2] > 22) OR (cedruc[1, 2] = 00) THEN
	CALL fl_mostrar_mensaje('Los digitos iniciales de cédula/ruc son incorrectos.', 'exclamation')
	RETURN 0
END IF
IF LENGTH(cedruc) = 13 THEN
	IF cedruc[11, 13] = '000' OR cedruc[11, 12] <> '00' THEN
		CALL fl_mostrar_mensaje('El número de digitos del ruc es incorrecto.', 'exclamation')
		RETURN 0
	END IF
END IF
FOR i = 1 TO lim
	LET valor[i] = 0
END FOR
LET residuo_suma = NULL
IF cedruc[3, 3] = 9 THEN
	LET valor[1]   = cedruc[1, 1] * 4
	LET valor[2]   = cedruc[2, 2] * 3
	LET valor[3]   = cedruc[3, 3] * 2
	LET valor[4]   = cedruc[4, 4] * 7
	LET valor[5]   = cedruc[5, 5] * 6
	LET valor[6]   = cedruc[6, 6] * 5
	LET valor[7]   = cedruc[7, 7] * 4
	LET valor[8]   = cedruc[8, 8] * 3
	LET valor[9]   = cedruc[9, 9] * 2
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF (cedruc[3, 3] = 6) OR (cedruc[3, 3] = 8) THEN
	LET valor[1]   = cedruc[1, 1] * 3
	LET valor[2]   = cedruc[2, 2] * 2
	LET valor[3]   = cedruc[3, 3] * 7
	LET valor[4]   = cedruc[4, 4] * 6
	LET valor[5]   = cedruc[5, 5] * 5
	LET valor[6]   = cedruc[6, 6] * 4
	LET valor[7]   = cedruc[7, 7] * 3
	LET valor[8]   = cedruc[8, 8] * 2
	LET valor[lim] = cedruc[9, 9]
	LET suma       = 0
	FOR i = 1 TO lim - 2
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 11 - (suma mod 11)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 11 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
IF ((cedruc[3, 3] < 3) OR (cedruc[3, 3] > 5)) AND (cedruc[3, 3] <> 7) THEN
	FOR i = 1 TO lim - 1
		LET valor[i] = cedruc[i, i]
		IF (i mod 2) <> 0 THEN
			LET valor[i] = valor[i] * 2
			IF valor[i] > 9 THEN
				LET valor[i] = valor[i] - 9
			END IF
		END IF
	END FOR
	LET valor[lim] = cedruc[lim, lim]
	LET suma       = 0
	FOR i = 1 TO lim - 1
		LET suma = suma + valor[i]
	END FOR
	LET residuo_suma = 10 - (suma mod 10)
	IF residuo_suma >= lim THEN
		LET residuo_suma = 10 - residuo_suma
	END IF
	IF valor[lim] = residuo_suma THEN
		RETURN 1
	END IF
END IF
CALL fl_mostrar_mensaje('El número de cédula/ruc no es valido.', 'exclamation')
RETURN 0

END FUNCTION



FUNCTION fl_lee_item(cod_cia, item)
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE item		LIKE rept010.r10_codigo     
DEFINE r		RECORD LIKE rept010.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept010 
	WHERE r10_compania = cod_cia AND r10_codigo = item
RETURN r.*

END FUNCTION



FUNCTION fl_lee_stock_rep(cod_cia, bodega, item)
DEFINE cod_cia		LIKE rept011.r11_compania
DEFINE bodega		LIKE rept011.r11_bodega
DEFINE item		LIKE rept011.r11_item
DEFINE r		RECORD LIKE rept011.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept011 
	WHERE r11_compania = cod_cia AND r11_bodega = bodega AND
	      r11_item     = item
RETURN r.*

END FUNCTION



FUNCTION fl_lee_linea_rep(cod_cia, linea)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE linea		LIKE rept003.r03_codigo
DEFINE r		RECORD LIKE rept003.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept003 
	WHERE r03_compania = cod_cia AND r03_codigo = linea
RETURN r.*

END FUNCTION



FUNCTION fl_hacer_pregunta(texto, resp_default)
DEFINE texto		CHAR(400)
DEFINE resp_default	CHAR(3)
DEFINE resp		CHAR(3)
DEFINE car_lin, i	SMALLINT
DEFINE ind_ini, ind_fin	SMALLINT
DEFINE num_lin, aux	SMALLINT
DEFINE r_lineas	ARRAY[10] OF VARCHAR(60)
DEFINE long_text, key	SMALLINT
DEFINE num_col, pos_y  	SMALLINT
DEFINE opcion		CHAR(1)

IF vg_gui = 1 THEN
	--#CALL fgl_winquestion(vg_producto, texto, resp_default,'Yes|No','question',1) RETURNING resp
ELSE
	LET car_lin = 60
	LET num_lin = 1
	LET texto = texto CLIPPED, '?'
	LET long_text = LENGTH(texto)
	LET num_lin = 0
	LET ind_ini = 1
	LET ind_fin = car_lin
	LET num_col = car_lin + 2
	WHILE TRUE
		IF long_text <= car_lin THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto
			LET num_col = long_text + 2
			EXIT WHILE
		END IF
		IF texto[ind_fin, ind_fin] = ' ' THEN
			LET num_lin = num_lin + 1
			LET r_lineas[num_lin] = texto[ind_ini, ind_fin - 1]
			LET ind_ini = ind_fin + 1
			LET ind_fin = ind_fin + car_lin
			IF ind_fin > long_text THEN
				LET num_lin = num_lin + 1
				LET r_lineas[num_lin] = 
					texto[ind_ini, long_text]
				EXIT WHILE
			END IF	
		ELSE
			LET ind_fin = ind_fin - 1
		END IF
	END WHILE		
	LET aux = num_lin + 2
	LET pos_y = (80 - num_col) / 2
	OPEN WINDOW w_preg AT 10,pos_y WITH aux ROWS, num_col COLUMNS
		ATTRIBUTE(BORDER, PROMPT LINE LAST)
	DISPLAY ' PREGUNTA '
	LET aux = (num_col - 10) / 2
	DISPLAY ' PREGUNTA ' AT 1,aux ATTRIBUTE(REVERSE)
	FOR i = 1 TO num_lin
		LET aux = i + 1
		DISPLAY r_lineas[i] AT aux,2
	END FOR
      	LET opcion = "k" 
      	WHILE opcion NOT MATCHES "[SsNn]" 
	 	PROMPT " Presione (S/N) ==> " 
			FOR CHAR opcion   
	     		ON KEY(INTERRUPT)
	     			LET opcion = "q"
	 	END PROMPT
	 	IF opcion IS NULL THEN
	    		LET opcion = "k"
	    		CONTINUE WHILE
	 	END IF
      	END WHILE
      	IF opcion MATCHES "[Ss]" THEN
		LET resp = 'Yes'
	ELSE
		LET resp = 'No'
	END IF
	CLOSE WINDOW w_preg
END IF
RETURN resp

END FUNCTION



FUNCTION fl_lee_bodega_rep(cod_cia, bodega)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE r		RECORD LIKE rept002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept002 
	WHERE r02_compania = cod_cia AND r02_codigo = bodega
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_saldo_vencido(cod_cia, cod_cliente)
DEFINE cod_cia		LIKE cxct030.z30_compania
DEFINE cod_cliente	LIKE cxct030.z30_codcli
DEFINE saldo_vencido	LIKE cxct030.z30_saldo_venc		
DEFINE moneda		LIKE gent013.g13_moneda

LET saldo_vencido = 0
LET moneda        = NULL
DECLARE q_clivenc CURSOR FOR 
	SELECT z30_moneda, SUM(z30_saldo_venc)
		FROM cxct030
		WHERE z30_compania = cod_cia
	    	  AND z30_codcli   = cod_cliente
		GROUP BY 1
OPEN q_clivenc
FETCH q_clivenc INTO moneda, saldo_vencido
CLOSE q_clivenc
FREE q_clivenc
RETURN moneda, saldo_vencido

END FUNCTION



FUNCTION fl_lee_compania_cobranzas(cod_cia)
DEFINE cod_cia		LIKE cxct000.z00_compania
DEFINE r		RECORD LIKE cxct000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct000 
	WHERE z00_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_lee_grupo_rep(cod_cia, linea, sub_linea, cod_grupo)
DEFINE cod_cia		LIKE rept071.r71_compania
DEFINE linea		LIKE rept071.r71_linea
DEFINE sub_linea	LIKE rept071.r71_sub_linea
DEFINE cod_grupo	LIKE rept071.r71_cod_grupo
DEFINE r		RECORD LIKE rept071.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept071 	
	WHERE r71_compania  = cod_cia
	  AND r71_linea     = linea
	  AND r71_sub_linea = sub_linea
	  AND r71_cod_grupo = cod_grupo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_clase_rep(cod_cia, linea, sub_linea, cod_grupo, cod_clase)
DEFINE cod_cia		LIKE rept072.r72_compania
DEFINE linea		LIKE rept072.r72_linea
DEFINE sub_linea	LIKE rept072.r72_sub_linea
DEFINE cod_grupo	LIKE rept072.r72_cod_grupo
DEFINE cod_clase	LIKE rept072.r72_cod_clase
DEFINE r		RECORD LIKE rept072.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept072 	
	WHERE r72_compania  = cod_cia
	  AND r72_linea     = linea
	  AND r72_sub_linea = sub_linea
	  AND r72_cod_grupo = cod_grupo
	  AND r72_cod_clase = cod_clase
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_precision_valor(moneda, valor)
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor, val_aux	DECIMAL(16,4)
DEFINE r		RECORD LIKE gent013.*

CALL fl_lee_moneda(moneda) RETURNING r.*
IF r.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe moneda: ' ||  moneda, 'stop')
	EXIT PROGRAM
END IF
LET val_aux = NULL
SELECT ROUND(valor, r.g13_decimales) INTO val_aux FROM dual  
RETURN val_aux

END FUNCTION



FUNCTION fl_control_status_caja(cod_cia, cod_loc, tipo)
DEFINE cod_cia          LIKE cajt004.j04_compania
DEFINE cod_loc          LIKE cajt004.j04_localidad
DEFINE tipo		CHAR(1)
DEFINE r_j04		RECORD LIKE cajt004.*
DEFINE query		VARCHAR(200)
DEFINE expr_campo	VARCHAR(30)
DEFINE i, cod_return	SMALLINT
DEFINE cod_caja		LIKE cajt004.j04_codigo_caja

IF tipo = 'P' THEN
	LET expr_campo = 'j02_pre_ventas'
ELSE
	IF tipo = 'O' THEN
		LET expr_campo = 'j02_ordenes'
	ELSE
		IF tipo = 'S' THEN
			LET expr_campo = 'j02_solicitudes'
		ELSE
			EXIT PROGRAM
		END IF
	END IF
END IF
LET query = 'SELECT j02_codigo_caja FROM cajt002 ',
		' WHERE ', expr_campo, ' = "S"'
PREPARE ces FROM query
DECLARE cu_ces CURSOR FOR ces
LET cod_return = 1    -- Se asume que la Caja está aperturada y cerrada
LET i = 0
FOREACH cu_ces INTO cod_caja
	LET i = i + 1
	DECLARE cu_chcj CURSOR FOR SELECT * FROM cajt004
		WHERE j04_compania    = cod_cia  AND 
	      	      j04_localidad   = cod_loc  AND 
	      	      j04_codigo_caja = cod_caja AND
	      	      j04_fecha_aper  = TODAY
		ORDER BY j04_fecing DESC
	OPEN cu_chcj
	FETCH cu_chcj INTO r_j04.*
	IF status = NOTFOUND THEN
		LET cod_return = 2
		CONTINUE FOREACH
	END IF
	IF r_j04.j04_fecha_cierre IS NULL THEN
		LET cod_return = 0    -- La Caja está aperturada y no cerrada
		EXIT FOREACH
	ELSE
		LET cod_return = 1
	END IF
END FOREACH
IF i = 0 THEN
	LET cod_return = 2  -- La Caja no ha sido aperturada
END IF
IF cod_return = 1 THEN
	CALL fl_mostrar_mensaje( 'La Caja ya ha sido cerrada', 'stop')
ELSE
	IF cod_return = 2 THEN
		CALL fl_mostrar_mensaje( 'La Caja no ha sido aperturada aún', 'stop')
	END IF

END IF
RETURN cod_return

END FUNCTION	 



FUNCTION fl_lee_factor_moneda(mon_ori, mon_des)
DEFINE mon_ori, mon_des	LIKE gent014.g14_moneda_ori
DEFINE r		RECORD LIKE gent014.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent014 WHERE g14_serial = 
	(SELECT MAX(g14_serial) FROM gent014
		WHERE g14_moneda_ori = mon_ori AND g14_moneda_des = mon_des)
RETURN r.*

END FUNCTION



FUNCTION fl_lee_grupo_linea(cod_cia, grupo_linea)
DEFINE cod_cia		LIKE gent020.g20_compania
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE r		RECORD LIKE gent020.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent020 
	WHERE g20_compania = cod_cia AND g20_grupo_linea = grupo_linea
RETURN r.*

END FUNCTION



FUNCTION fl_visor_teclas_caracter()

OPEN WINDOW w_tf AT 2,5 WITH 18 ROWS, 60 COLUMNS 
	ATTRIBUTE(BORDER)			
DISPLAY ' *** TECLAS FUNCIONALES *** ' AT 1,16 ATTRIBUTE(REVERSE) 
DISPLAY 'Teclas Fijas:' AT 2,2 ATTRIBUTE(REVERSE)	
DISPLAY '<F12>	   Grabar, Aceptar' AT 3,2
DISPLAY  'F12'     AT 3,3 ATTRIBUTE(REVERSE)
DISPLAY '<Delete>  Abandonar consulta-proceso-reporte' AT 4,2
DISPLAY  'Delete'  AT 4,3 ATTRIBUTE(REVERSE)
DISPLAY '<F2>      Lista de Valores' AT 5,2
DISPLAY  'F2'      AT 5,3 ATTRIBUTE(REVERSE)
DISPLAY '<F3>      Ver siguiente desplieque de datos' AT 6,2
DISPLAY  'F3'      AT 6,3 ATTRIBUTE(REVERSE)
DISPLAY '<F4>      Ver anterior desplieque de datos' AT 7,2
DISPLAY  'F4'      AT 7,3 ATTRIBUTE(REVERSE)
DISPLAY '<F9>      Imprimir' AT 8,2
DISPLAY  'F9'      AT 8,3 ATTRIBUTE(REVERSE)
DISPLAY '<F10>     Insertar nuevo renglón'   AT 9,2
DISPLAY  'F10'     AT 9,3 ATTRIBUTE(REVERSE)
DISPLAY '<F11>     Borrar renglón corriente' AT 10,2
DISPLAY  'F11'     AT 10,3 ATTRIBUTE(REVERSE)
RETURN 10        -- Retorna el # líneas displayadas.

END FUNCTION



FUNCTION fl_ayuda_proformas_rep(cod_cia, cod_loc)

DEFINE rh_prorep ARRAY[1000] OF RECORD
	r21_numprof	LIKE rept021.r21_numprof,
	r21_nomcli	LIKE rept021.r21_nomcli  
	END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE expr_estado	CHAR(25)
DEFINE cod_cia		LIKE rept021.r21_compania
DEFINE cod_loc		LIKE rept021.r21_localidad
DEFINE r_vend		RECORD LIKE rept001.*
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE expr_vend 	CHAR(30)

CALL fl_lee_usuario(vg_usuario) RETURNING r_g05.*
DECLARE qu_ace CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_ace 
INITIALIZE r_vend.* TO NULL
FETCH qu_ace INTO r_vend.*
IF status = NOTFOUND THEN
END IF		
LET expr_vend = ' 1 = 1 '
IF r_vend.r01_tipo <> 'J' THEN
	LET expr_vend = ' r21_vendedor = ', r_vend.r01_codigo
END IF
LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_prorep AT 06, 26 WITH 15 ROWS, 53 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf108 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf108'
ELSE
	OPEN FORM f_ayuf108 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf108c'
END IF
DISPLAY FORM f_ayuf108
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r21_numprof, r21_nomcli
	IF int_flag THEN
		INITIALIZE rh_prorep[1].* TO NULL
		CLOSE WINDOW w_prorep
		RETURN rh_prorep[1].*
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'
	LET query = "SELECT r21_numprof, r21_nomcli FROM rept021 ",
				"WHERE r21_compania =  ", cod_cia, " AND ",
				"r21_localidad = ", cod_loc, " AND ",
				 expr_vend CLIPPED, ' AND ',
				 expr_sql CLIPPED,
				" ORDER BY 1"
	PREPARE prorep FROM query
	DECLARE q_prorep CURSOR FOR prorep
	LET i = 1
	FOREACH q_prorep INTO rh_prorep[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_prorep TO rh_prorep.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_prorep
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_prorep[i].*
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_prorep[1].* TO NULL
	RETURN rh_prorep[1].*
END IF
LET  i = arr_curr()
RETURN rh_prorep[i].*

END FUNCTION



FUNCTION fl_ayuda_monedas()
DEFINE rh_mon  ARRAY[100] OF RECORD 
        g13_moneda      LIKE gent013.g13_moneda,
        g13_nombre      LIKE gent013.g13_nombre,
        g13_simbolo     LIKE gent013.g13_simbolo
        END RECORD
DEFINE rh_dec	ARRAY[100] OF RECORD 
 	g13_decimales	LIKE gent013.g13_decimales	
	END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
                                                                                
LET filas_max  = 100
OPEN WINDOW w_mon AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf008 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf008'
ELSE
	OPEN FORM f_ayuf008 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf008c'
END IF
DISPLAY FORM f_ayuf008
LET filas_pant = fgl_scr_size('rh_mon')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_mon CURSOR FOR
        SELECT 	g13_moneda, g13_nombre, g13_simbolo, 
		g13_decimales
 		FROM gent013
		WHERE  g13_estado = 'A'
        ORDER BY 2
LET i = 1
FOREACH q_mon INTO rh_mon[i].*, rh_dec[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                
        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW w_mon
        INITIALIZE rh_mon[1].*, rh_dec[1] TO NULL
        RETURN 	rh_mon[1].g13_moneda, rh_mon[1].g13_nombre, 
		rh_dec[1].g13_decimales 
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_mon TO rh_mon.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW w_mon
IF int_flag THEN
        INITIALIZE rh_mon[1].*, rh_dec[1] TO NULL
        RETURN 	rh_mon[1].g13_moneda, rh_mon[1].g13_nombre, 
		rh_dec[1].g13_decimales 
END IF
LET  i = arr_curr()
RETURN 	rh_mon[i].g13_moneda, rh_mon[i].g13_nombre, 
	rh_dec[i].g13_decimales 

END FUNCTION
                                                                                


FUNCTION fl_ayuda_vendedores(cod_cia)
DEFINE rh_vend ARRAY[100] OF RECORD
   	r01_codigo      	LIKE rept001.r01_codigo,
        r01_nombres      	LIKE rept001.r01_nombres
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia 		LIKE rept001.r01_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_vend AT 06, 42 WITH 15 ROWS, 37 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf038 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf038'
ELSE
	OPEN FORM f_ayuf038 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf038c'
END IF
DISPLAY FORM f_ayuf038
LET filas_pant = fgl_scr_size('rh_vend')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_vend CURSOR FOR
        SELECT r01_codigo, r01_nombres FROM rept001
		WHERE r01_compania = cod_cia
		  AND r01_estado = 'A'
        ORDER BY 2
LET i = 1
FOREACH q_vend INTO rh_vend[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_vend
        INITIALIZE rh_vend[1].* TO NULL
        RETURN rh_vend[1].r01_codigo, rh_vend[1].r01_nombres
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_vend TO rh_vend.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_vend
IF int_flag THEN
        INITIALIZE rh_vend[1].* TO NULL
        RETURN rh_vend[1].r01_codigo, rh_vend[1].r01_nombres
END IF
LET  i = arr_curr()
RETURN rh_vend[i].r01_codigo, rh_vend[i].r01_nombres

END FUNCTION



FUNCTION fl_ayuda_cliente_localidad(cod_cia, cod_loc)
DEFINE rh_cliloc	ARRAY[1000] OF
				RECORD
					z02_codcli	LIKE cxct002.z02_codcli,
        				z01_nomcli	LIKE cxct001.z01_nomcli,
        			      z01_num_doc_id LIKE cxct001.z01_num_doc_id
				END RECORD
DEFINE i		SMALLINT
DEFINE expr_sql	CHAR(300)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE cxct002.z02_compania
DEFINE cod_loc 		LIKE cxct002.z02_localidad
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT

LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_cliloc AT 06, 13 WITH 15 ROWS, 66 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf098 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf098'
ELSE
	OPEN FORM f_ayuf098 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf098c'
END IF
DISPLAY FORM f_ayuf098
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'         TO bt_codigo
--#DISPLAY 'Nombre Cliente' TO bt_nombre
--#DISPLAY 'Cedula/RUC'     TO bt_cedruc

WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON z02_codcli, z01_nomcli, z01_num_doc_id
	IF int_flag THEN
		INITIALIZE rh_cliloc[1].* TO NULL
		CLOSE WINDOW w_cliloc
		RETURN rh_cliloc[1].z02_codcli, rh_cliloc[1].z01_nomcli
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
	LET query = "SELECT z02_codcli, z01_nomcli, z01_num_doc_id ",
			" FROM cxct001, cxct002 ",
			" WHERE z02_compania  = ",  cod_cia, 
			"   AND z02_localidad = ",  cod_loc, 
			"   AND z02_codcli    =  z01_codcli", 
			"   AND z01_estado    =  'A'", " AND ", 
				 expr_sql CLIPPED,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE cliloc FROM query
	DECLARE q_cliloc CURSOR FOR cliloc
	LET i = 1
	FOREACH q_cliloc INTO rh_cliloc[i].*
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rh_cliloc TO rh_cliloc.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_cliloc[i].*
                        END FOR
                        EXIT DISPLAY
                ON KEY(F15)
                        LET col = 1
                        EXIT DISPLAY
                ON KEY(F16)
                        LET col = 2
                        EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1
	END DISPLAY
        IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
                EXIT WHILE
        END IF
                                                                                
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_cliloc
	EXIT WHILE
END IF
FOR i = 1 TO filas_pant
	CLEAR rh_cliloc[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_cliloc[1].* TO NULL
	RETURN rh_cliloc[1].z02_codcli, rh_cliloc[1].z01_nomcli
END IF
LET  i = arr_curr()
RETURN rh_cliloc[i].z02_codcli, rh_cliloc[i].z01_nomcli

END FUNCTION



FUNCTION fl_ayuda_bodegas_rep(cod_cia, indicador) ## indicador T ó F 
DEFINE rh_bode ARRAY[100] OF RECORD	          ## Todas ó sólo de Facturación
   	r02_codigo      	LIKE rept002.r02_codigo,
        r02_nombre      	LIKE rept002.r02_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE rept002.r02_compania
DEFINE indicador	LIKE rept002.r02_factura
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_bode AT 06, 45 WITH 15 ROWS, 34 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf030 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf030'
ELSE
	OPEN FORM f_ayuf030 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf030c'
END IF
DISPLAY FORM f_ayuf030
LET filas_pant = fgl_scr_size('rh_bode')
LET int_flag = 0

MESSAGE 'Seleccionando datos..' 
IF indicador ='F' THEN
DECLARE q_bode1 CURSOR FOR
        SELECT r02_codigo, r02_nombre FROM rept002
	WHERE r02_compania = cod_cia
        AND r02_factura = 'S'
	AND r02_estado = 'A'
        ORDER BY 1
	LET i = 1
	FOREACH q_bode1 INTO rh_bode[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
END IF
IF indicador ='T' THEN
DECLARE q_bode2 CURSOR FOR
        SELECT r02_codigo, r02_nombre FROM rept002
	WHERE r02_compania = vg_codcia
	AND r02_estado = 'A'
        ORDER BY 1
	LET i = 1
	FOREACH q_bode2 INTO rh_bode[i].*
        	LET i = i + 1
        	IF i > filas_max THEN
                	EXIT FOREACH
                END IF
	END FOREACH
END IF
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_bode
        INITIALIZE rh_bode[1].* TO NULL
        RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_bode TO rh_bode.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_bode
IF int_flag THEN
        INITIALIZE rh_bode[1].* TO NULL
        RETURN rh_bode[1].r02_codigo, rh_bode[1].r02_nombre
END IF
LET  i = arr_curr()
RETURN rh_bode[i].r02_codigo, rh_bode[i].r02_nombre

END FUNCTION



FUNCTION fl_ayuda_maestro_items_stock(cod_cia, grupo, bodega)
DEFINE rh_reppre ARRAY[500] OF RECORD
   	r10_sec_item      	LIKE rept010.r10_sec_item,
   	r10_codigo      	LIKE rept010.r10_codigo,
   	r10_nombre      	LIKE rept010.r10_nombre,
--   	r10_linea  	    	LIKE rept010.r10_linea,
   	r10_precio_mb      	LIKE rept010.r10_precio_mb,
	r11_bodega		LIKE rept011.r11_bodega,
   	r11_stock_act      	LIKE rept011.r11_stock_act 
	END RECORD
DEFINE rh_lin  ARRAY[500] OF LIKE rept010.r10_linea
DEFINE i		SMALLINT
DEFINE criterio	CHAR(600)		## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(800)		## Contiene todo el query preparado
DEFINE filas_max	SMALLINT	## No. elementos del arreglo
DEFINE filas_pant	SMALLINT	## No. elementos de cada pantalla
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_sub		RECORD LIKE rept070.*
DEFINE r_grp		RECORD LIKE rept071.*
DEFINE r_cla		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE bodega	 	LIKE rept011.r11_bodega
DEFINE grupo		LIKE rept003.r03_grupo_linea
DEFINE expr_bodega	CHAR(100)
DEFINE expr_linea	CHAR(100)
DEFINE expr_sublinea	CHAR(100)
DEFINE expr_grupo	CHAR(100)
DEFINE expr_clase	CHAR(100)
DEFINE expr_marca	CHAR(100)
DEFINE j, flag		SMALLINT

LET filas_max  = 500
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_reppre AT 05, 04 WITH 17 ROWS, 75 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf105 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf105'
ELSE
	OPEN FORM f_ayuf105 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf105c'
END IF
DISPLAY FORM f_ayuf105
LET filas_pant = fgl_scr_size('rh_reppre')
IF vg_gui = 1 THEN
	DISPLAY 'Sec'         TO tit_col1
	DISPLAY 'Codigo'      TO tit_col2
	DISPLAY 'Descripcion' TO tit_col3
	DISPLAY 'Precio'      TO tit_col4
	DISPLAY 'Bd'          TO tit_col5
	DISPLAY 'Stock'       TO tit_col6
END IF
LET r_r10.r10_linea = NULL
WHILE TRUE
	--#MESSAGE "Digite condicion-búsqueda y presione (F12)"
	LET int_flag = 0
	INPUT BY NAME r_r10.r10_linea, r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
		r_r10.r10_cod_clase, r_r10.r10_marca
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
		ON KEY(F2)
			IF INFIELD(r10_linea) THEN
		     		CALL fl_ayuda_lineas_rep(cod_cia)
		     			RETURNING r_r03.r03_codigo, r_r03.r03_nombre
		     		IF r_r03.r03_codigo IS NOT NULL THEN
					LET r_r10.r10_linea = r_r03.r03_codigo
					DISPLAY BY NAME r_r10.r10_linea
					DISPLAY r_r03.r03_nombre TO descri_linea
		     		END IF
			END IF
			IF INFIELD(r10_sub_linea) THEN
				CALL fl_ayuda_sublinea_rep(cod_cia,
								r_r10.r10_linea)
		  		RETURNING r_sub.r70_sub_linea,
					  r_sub.r70_desc_sub
				IF r_sub.r70_sub_linea IS NOT NULL THEN
					LET r_r10.r10_sub_linea =
							r_sub.r70_sub_linea
					DISPLAY BY NAME r_r10.r10_sub_linea
					DISPLAY r_sub.r70_desc_sub TO descri_sub_linea
		   		END IF
			END IF
			IF INFIELD(r10_cod_grupo) THEN
				CALL fl_ayuda_grupo_ventas_rep(cod_cia,
							r_r10.r10_linea,
							r_r10.r10_sub_linea)
		     			RETURNING r_grp.r71_cod_grupo,
						  r_grp.r71_desc_grupo
				IF r_grp.r71_cod_grupo IS NOT NULL THEN
					LET r_r10.r10_cod_grupo =
							r_grp.r71_cod_grupo
					DISPLAY BY NAME r_r10.r10_cod_grupo
					DISPLAY r_grp.r71_desc_grupo TO descri_cod_grupo
		     		END IF
			END IF
			IF INFIELD(r10_cod_clase) THEN
				CALL fl_ayuda_clase_ventas_rep(cod_cia,
							r_r10.r10_linea,
							r_r10.r10_sub_linea,
							r_r10.r10_cod_grupo)
			     		RETURNING r_cla.r72_cod_clase,
					   	  r_cla.r72_desc_clase
			     	IF r_cla.r72_cod_clase IS NOT NULL THEN
					LET r_r10.r10_cod_clase =
							r_cla.r72_cod_clase
					DISPLAY BY NAME r_r10.r10_cod_clase
					DISPLAY r_cla.r72_desc_clase TO descri_cod_clase
			     	END IF
			END IF
			IF INFIELD(r10_marca) THEN
				CALL fl_ayuda_marcas_rep_asignadas(cod_cia, 
					r_r10.r10_cod_clase)
		  			RETURNING r_r73.r73_marca
				IF r_r73.r73_compania IS NOT NULL THEN
					LET r_r10.r10_marca = r_r73.r73_marca
					DISPLAY BY NAME r_r10.r10_marca
		   		END IF
			END IF
        	        LET int_flag = 0
		AFTER FIELD r10_linea
			IF r_r10.r10_linea IS NOT NULL THEN
				CALL fl_lee_linea_rep(cod_cia, r_r10.r10_linea)
					RETURNING r_r03.*
				IF r_r03.r03_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Division no existe.','exclamation')
					NEXT FIELD r10_linea
				END IF
				DISPLAY r_r03.r03_nombre TO descri_linea
			ELSE
				CLEAR descri_linea
			END IF
		AFTER FIELD r10_sub_linea 
			IF r_r10.r10_sub_linea IS NOT NULL THEN
{--
				IF r_r10.r10_linea IS NULL THEN
					CALL fl_mostrar_mensaje('Digite division primero.','exclamation')
					LET r_r10.r10_sub_linea = NULL
					CLEAR r10_sub_linea
					NEXT FIELD r10_linea
				END IF	
				CALL fl_lee_sublinea_rep(cod_cia, r_r10.r10_linea, r_r10.r10_sub_linea)
					RETURNING r_sub.*
--}
				CALL fl_retorna_sublinea_rep(cod_cia,
							r_r10.r10_sub_linea)
					RETURNING r_sub.*, flag
				IF flag = 0 THEN
					IF r_sub.r70_compania IS NULL THEN
						CALL fl_mostrar_mensaje('Linea no existe.','exclamation')
						NEXT FIELD r10_sub_linea
					END IF
				END IF
				DISPLAY r_sub.r70_desc_sub TO descri_sub_linea
			ELSE
				CLEAR descri_sub_linea
			END IF
		AFTER FIELD r10_cod_grupo 
			IF r_r10.r10_cod_grupo IS NOT NULL THEN
{--
				IF r_r10.r10_sub_linea IS NULL THEN
					CALL fl_mostrar_mensaje('Digite linea primero.','exclamation')
					LET r_r10.r10_cod_grupo = NULL
					CLEAR r10_cod_grupo
					NEXT FIELD r10_sub_linea
				END IF	
				CALL fl_lee_grupo_rep(cod_cia, r_r10.r10_linea, r_r10.r10_sub_linea, r_r10.r10_cod_grupo)
					RETURNING r_grp.*
--}
				CALL fl_retorna_grupo_rep(cod_cia,
							r_r10.r10_cod_grupo)
					RETURNING r_grp.*, flag
				IF flag = 0 THEN
					IF r_grp.r71_compania IS NULL THEN
						CALL fl_mostrar_mensaje('Grupo no existe.','exclamation')
						NEXT FIELD r10_cod_grupo
					END IF
				END IF
				DISPLAY r_grp.r71_desc_grupo TO descri_cod_grupo
			ELSE
				CLEAR descri_cod_grupo
			END IF
		AFTER FIELD r10_cod_clase 
			IF r_r10.r10_cod_clase IS NOT NULL THEN
{--
				IF r_r10.r10_cod_grupo IS NULL THEN
					CALL fl_mostrar_mensaje('Digite grupo primero.','exclamation')
					LET r_r10.r10_cod_clase = NULL
					CLEAR r10_cod_clase
					NEXT FIELD r10_cod_grupo
				END IF	
				CALL fl_lee_clase_rep(cod_cia, r_r10.r10_linea, r_r10.r10_sub_linea, r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
					RETURNING r_cla.*
--}
				CALL fl_retorna_clase_rep(cod_cia,
							r_r10.r10_cod_clase)
					RETURNING r_cla.*, flag
				IF flag = 0 THEN
					IF r_cla.r72_compania IS NULL THEN
						CALL fl_mostrar_mensaje('Clase no existe.','exclamation')
						NEXT FIELD r10_cod_clase
					END IF
				END IF
				DISPLAY r_cla.r72_desc_clase TO descri_cod_clase
			ELSE
				CLEAR descri_cod_clase
			END IF
		AFTER FIELD r10_marca 
			IF r_r10.r10_marca IS NOT NULL THEN
				CALL fl_lee_marca_rep(cod_cia, r_r10.r10_marca)
					RETURNING r_r73.*
				IF r_r73.r73_compania IS NULL THEN
					CALL fl_mostrar_mensaje('Marca no existe.','exclamation')
					NEXT FIELD r10_marca
				END IF
				DISPLAY r_r73.r73_desc_marca TO descri_marca
			ELSE
				CLEAR descri_marca
			END IF
	END INPUT
	IF int_flag THEN
		INITIALIZE rh_reppre[1].* TO NULL
		CLOSE WINDOW w_reppre
		RETURN rh_reppre[1].r10_codigo, rh_reppre[1].r10_nombre,
		rh_lin[1], rh_reppre[1].r10_precio_mb, rh_reppre[1].r11_bodega,
		rh_reppre[1].r11_stock_act
	END IF
	CONSTRUCT BY NAME criterio ON 	r10_sec_item, r10_codigo, r10_nombre, 
 					r10_precio_mb, r11_bodega,
					r11_stock_act
		BEFORE CONSTRUCT
			IF bodega <> '00' THEN
				DISPLAY bodega TO r11_bodega
			END IF
--			DISPLAY "> 0" TO r11_stock_act
	END CONSTRUCT
	IF int_flag THEN
		INITIALIZE rh_reppre[1].* TO NULL
		CLOSE WINDOW w_reppre
		RETURN rh_reppre[1].r10_codigo, rh_reppre[1].r10_nombre,
		rh_lin[1], rh_reppre[1].r10_precio_mb, rh_reppre[1].r11_bodega,
		rh_reppre[1].r11_stock_act
	END IF
	MESSAGE "Seleccionando datos .."
---------
	LET expr_linea = NULL
	IF r_r10.r10_linea IS NOT NULL THEN
		LET expr_linea = ' AND r10_linea = "',
					r_r10.r10_linea CLIPPED, '"'
	END IF
	LET expr_sublinea = NULL
	IF r_r10.r10_sub_linea IS NOT NULL THEN
		LET expr_sublinea = ' AND r10_sub_linea = "',
					r_r10.r10_sub_linea CLIPPED, '"'
	END IF
	LET expr_grupo = NULL
	IF r_r10.r10_cod_grupo IS NOT NULL THEN
		LET expr_grupo = ' AND r10_cod_grupo = "',
					r_r10.r10_cod_grupo CLIPPED, '"'
	END IF
	LET expr_clase = NULL
	IF r_r10.r10_cod_clase IS NOT NULL THEN
		LET expr_clase = ' AND r10_cod_clase = "',
					r_r10.r10_cod_clase CLIPPED, '"'
	END IF
	LET expr_marca = NULL
	IF r_r10.r10_marca IS NOT NULL THEN
		LET expr_marca = ' AND r10_marca = "', r_r10.r10_marca CLIPPED, '"'
	END IF
        LET query = "SELECT r10_sec_item, r10_codigo, r10_nombre, r10_linea, ",
			" r10_precio_mb, ",
			" r11_bodega, r11_stock_act",
			"  FROM rept010, OUTER rept011 ",
                                " WHERE r10_compania = ", cod_cia, " AND ",
                                " r10_compania = r11_compania",    " AND ",
                                " r10_codigo = r11_item ",  
                                --" r11_bodega = '", bodega,"'",     " AND ",
                                --" r10_linea IN ",
			        --" (SELECT r03_codigo FROM rept003 ",
				--" WHERE r03_compania = ", cod_cia, " AND ",
                                --" r03_grupo_linea = '", grupo,"')",
				expr_linea CLIPPED,
				expr_sublinea CLIPPED,
				expr_grupo CLIPPED,
				expr_clase CLIPPED,
				expr_marca CLIPPED, " AND ",
                                criterio CLIPPED
			--" ORDER BY 1, 2"
---------
	PREPARE reppre FROM query
	DECLARE q_reppre CURSOR FOR reppre
	LET i = 1
	FOREACH q_reppre INTO rh_reppre[i].r10_sec_item,rh_reppre[i].r10_codigo,
		rh_reppre[i].r10_nombre, rh_lin[i], rh_reppre[i].r10_precio_mb, 
		rh_reppre[i].r11_bodega, rh_reppre[i].r11_stock_act
		IF rh_reppre[i].r11_stock_act IS NULL THEN
			LET rh_reppre[i].r11_stock_act = 0
		END IF
		LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
        	CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
	CALL set_count(i)
	DISPLAY rh_reppre[1].r10_nombre TO tit_descripcion
	LET int_flag = 0
	DISPLAY ARRAY rh_reppre TO rh_reppre.*
		ON KEY(F2)
			LET int_flag = 4
			EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
			--#DISPLAY rh_reppre[j].r10_nombre TO tit_descripcion
			--#CALL dialog.keysetlabel("F5","")
		ON KEY(F5)
			LET j = arr_curr()
			DISPLAY rh_reppre[j].r10_nombre TO tit_descripcion
		ON KEY(RETURN)
                	EXIT DISPLAY
	END DISPLAY
	IF int_flag <> 4 THEN
		CLOSE WINDOW w_reppre
		EXIT WHILE
	END IF
	FOR i = 1 TO filas_pant
		CLEAR rh_reppre[i].*
		CLEAR tit_descripcion
	END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_reppre[1].* TO NULL
	RETURN rh_reppre[1].r10_codigo, rh_reppre[1].r10_nombre,
		rh_lin[1], rh_reppre[1].r10_precio_mb, rh_reppre[1].r11_bodega,
		rh_reppre[1].r11_stock_act
END IF
LET  i = arr_curr()
RETURN rh_reppre[i].r10_codigo, rh_reppre[i].r10_nombre,
       rh_lin[i], rh_reppre[i].r10_precio_mb, rh_reppre[i].r11_bodega,
       rh_reppre[i].r11_stock_act

END FUNCTION



FUNCTION fl_mensaje_abandonar_proceso()
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Realmente desea abandonar','No')
	RETURNING resp
RETURN resp

END FUNCTION



FUNCTION fl_lee_sublinea_rep(cod_cia, linea, sub_linea)
DEFINE cod_cia		LIKE rept070.r70_compania
DEFINE linea		LIKE rept070.r70_linea
DEFINE sub_linea	LIKE rept070.r70_sub_linea
DEFINE r		RECORD LIKE rept070.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept070 	
	WHERE r70_compania  = cod_cia
	  AND r70_linea     = linea
	  AND r70_sub_linea = sub_linea
RETURN r.*

END FUNCTION



FUNCTION fl_lee_marca_rep(cod_cia, marca)
DEFINE cod_cia		LIKE rept073.r73_compania
DEFINE marca		LIKE rept073.r73_marca
DEFINE r		RECORD LIKE rept073.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM rept073 	
	WHERE r73_compania = cod_cia AND r73_marca = marca	
RETURN r.*

END FUNCTION



FUNCTION fl_lee_configuracion_facturacion()
DEFINE r		RECORD LIKE gent000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent000 
	WHERE g00_serial = (SELECT MAX(g00_serial) FROM gent000)
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_usuario()
 
SELECT USER INTO vg_usuario FROM dual
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Tabla dual está vacía', 'stop')
	EXIT PROGRAM
END IF
LET vg_usuario = UPSHIFT(vg_usuario)

END FUNCTION



FUNCTION fl_separador()

SELECT fb_separador, fb_dir_fobos INTO vg_separador, vg_dir_fobos FROM fobos
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('Tabla fobos está vacía', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION fl_retorna_compania_default()
DEFINE cod_cia		LIKE gent001.g01_compania

SELECT g01_compania INTO cod_cia FROM gent001 WHERE g01_principal = 'S'
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay compañía principal configurada.', 'stop')
	EXIT PROGRAM
END IF
RETURN cod_cia

END FUNCTION



FUNCTION fl_lee_compania(cod_cia)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE r		RECORD LIKE gent001.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent001 WHERE g01_compania = cod_cia
RETURN r.*

END FUNCTION



FUNCTION fl_retorna_agencia_default(cod_cia)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_local	LIKE gent002.g02_localidad

SELECT g02_localidad INTO cod_local FROM gent002
	WHERE g02_compania = cod_cia AND g02_matriz = 'S'
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No hay localidad matriz para compañía: ' || cod_cia, 'stop')
	EXIT PROGRAM
END IF
RETURN cod_local

END FUNCTION



FUNCTION fl_control_acceso_procesos(v_usuario, v_codcia, v_modulo, v_proceso) 
DEFINE v_usuario	LIKE gent005.g05_usuario
DEFINE v_codcia		LIKE gent001.g01_compania
DEFINE v_modulo		LIKE gent050.g50_modulo
DEFINE v_proceso	LIKE gent054.g54_proceso
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_g05		RECORD LIKE gent005.*
DEFINE rm_g55   	RECORD LIKE gent055.*
DEFINE r_g54   		RECORD LIKE gent054.*
DEFINE clave		LIKE gent005.g05_clave

CALL fl_lee_usuario(v_usuario) RETURNING r_g05.*
IF r_g05.g05_usuario IS NULL THEN
	CALL fl_mostrar_mensaje('USUARIO: ' || v_usuario CLIPPED 
	          || ' NO ESTA CONFIGURADO EN EL SISTEMA.'
		  || ' PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	EXIT PROGRAM
END IF
IF r_g05.g05_estado <> 'A' THEN
	CALL fl_mostrar_mensaje('USUARIO: ' || v_usuario CLIPPED 
	          || ' ESTA BLOQUEADO.'
		  || ' PEDIR AYUDA AL ADMINISTRADOR ', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_modulo(v_modulo) RETURNING r_g50.*
IF r_g50.g50_modulo IS NULL THEN
	CALL fl_mostrar_mensaje('MODULO: ' || v_modulo CLIPPED 
				          || ' NO EXISTE ', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_proceso(v_modulo, v_proceso) RETURNING r_g54.*
IF r_g54.g54_modulo IS NULL THEN
	CALL fl_mostrar_mensaje('PROCESO: ' || v_modulo CLIPPED 
				          || '-' || v_proceso CLIPPED
					  || ' NO EXISTE ', 'stop')
	EXIT PROGRAM
END IF
SELECT * FROM gent052 
	WHERE g52_modulo  = v_modulo  AND 
	      g52_usuario = v_usuario
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('USUARIO NO TIENE ACCESO AL MODULO: '
					 || r_g50.g50_nombre CLIPPED 
					 || '. PEDIR AYUDA AL ADMINISTRADOR ',
					 'stop')
	EXIT PROGRAM
END IF
SELECT * FROM gent053 
	WHERE g53_modulo   = v_modulo  AND 
	      g53_usuario  = v_usuario AND
	      g53_compania = v_codcia 
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('USUARIO NO TIENE ACCESO A LA COMPAÑIA:'
				|| ' ' || rg_cia.g01_abreviacion CLIPPED 
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
IF r_g54.g54_estado = 'B' THEN
	CALL fl_mostrar_mensaje('EL PROCESO: ' 
				|| v_proceso CLIPPED
				|| ' ESTA MARCADO COMO BLOQUEADO.'
				|| ' PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_permisos_usuarios(vg_usuario, vg_codcia, vg_modulo, vg_proceso) 
	RETURNING rm_g55.*
IF rm_g55.g55_user IS NOT  NULL THEN
	CALL fl_mostrar_mensaje('USTED NO TIENE ACCESO AL PROCESO ' 
				|| v_proceso CLIPPED
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	EXIT PROGRAM
END IF
IF r_g54.g54_estado = 'R' THEN
	OPEN WINDOW w_clave AT 9, 20 WITH 7 ROWS, 43 COLUMNS
 		ATTRIBUTE(FORM LINE FIRST, BORDER, COMMENT LINE LAST)
	IF vg_gui = 1 THEN
		OPEN FORM f_ayuf126
			FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf126'
	ELSE
		OPEN FORM f_ayuf126
			FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf126c'
	END IF
	DISPLAY FORM f_ayuf126
	LET int_flag = 0
	LET clave = NULL
	INPUT BY NAME clave
	IF int_flag THEN
		EXIT PROGRAM
	END IF
	IF clave = r_g05.g05_clave OR 
		(clave IS NULL AND r_g05.g05_clave IS NULL) THEN
		CLOSE WINDOW w_clave
		RETURN
	END IF
	CALL fl_mostrar_mensaje('LO SIENTO CLAVE INCORRECTA ',
				'stop')
	EXIT PROGRAM
END IF	
 
END FUNCTION



FUNCTION fl_lee_modulo(modulo)
DEFINE modulo		LIKE gent050.g50_modulo
DEFINE r		RECORD LIKE gent050.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent050 WHERE g50_modulo = modulo
RETURN r.*

END FUNCTION



FUNCTION fl_lee_localidad(cod_cia, cod_local)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_local	LIKE gent002.g02_localidad
DEFINE r		RECORD LIKE gent002.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent002 	
	WHERE g02_compania = cod_cia AND g02_localidad = cod_local
RETURN r.*

END FUNCTION



FUNCTION fl_lee_proceso(cod_mod, cod_proc)
DEFINE cod_mod		LIKE gent050.g50_modulo
DEFINE cod_proc		LIKE gent054.g54_proceso
DEFINE r		RECORD LIKE gent054.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent054 
	WHERE g54_modulo = cod_mod AND g54_proceso = cod_proc
RETURN r.*

END FUNCTION



FUNCTION fl_justifica_titulo(flag, titulo, longitud)
DEFINE flag 		CHAR(1)     -- C Centrar   D Derecha   I Izquierda
DEFINE titulo, aux	CHAR(132)
DEFINE longitud, i, j	SMALLINT
DEFINE max_long      	SMALLINT

LET max_long = 80
IF longitud > max_long OR longitud <= 0 OR LENGTH(titulo) = 0 THEN
	RETURN titulo
END IF
IF flag <> 'C' AND flag <> 'D' AND flag <> 'I' THEN
	RETURN titulo
END IF
LET aux = titulo
FOR i = 1 TO LENGTH(titulo)
	IF titulo[i,i] <> ' ' OR titulo[i,i] <> '' THEN
		EXIT FOR
	END IF
END FOR
IF i <= max_long THEN
	LET aux = titulo[i, max_long]
	IF LENGTH(aux CLIPPED) > longitud THEN
		LET aux = NULL
		FOR i = 1 TO longitud
			LET aux[i,i] = '*'
		END FOR
		RETURN aux
	END IF
END IF
IF flag = 'D' THEN
	FOR i = 1 TO max_long
		LET aux[i,i] = ' '
	END FOR
	LET i = max_long
	FOR j = LENGTH(titulo CLIPPED) TO 1 STEP -1
		LET aux[i,i] = titulo[j,j]
		LET i = i - 1
	END FOR
	RETURN aux[max_long - longitud + 1, max_long]
ELSE
	IF flag = 'C' THEN
		LET i = 0
		IF longitud > LENGTH(aux CLIPPED) THEN
 			LET i = ((longitud - LENGTH(aux CLIPPED)) / 2) + 1
		END IF
		LET aux = i SPACES, aux CLIPPED
		RETURN aux
	ELSE
		RETURN aux[1, longitud]
	END IF
END IF

END FUNCTION



FUNCTION fl_ayuda_lineas_rep(cod_cia)
DEFINE rh_linea ARRAY[100] OF RECORD
   	r03_codigo      	LIKE rept003.r03_codigo,
        r03_nombre      	LIKE rept003.r03_nombre
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE cod_cia		LIKE rept003.r03_compania
                                                                                
LET filas_max  = 100
OPEN WINDOW wh_linea AT 06, 43 WITH 15 ROWS, 36 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf031 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf031'
ELSE
	OPEN FORM f_ayuf031 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf031c'
END IF
DISPLAY FORM f_ayuf031
LET filas_pant = fgl_scr_size('rh_linea')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
DECLARE q_linea CURSOR FOR
        SELECT r03_codigo, r03_nombre FROM rept003
	WHERE r03_compania = cod_cia
	  AND r03_estado = 'A'
        ORDER BY 1
LET i = 1
FOREACH q_linea INTO rh_linea[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_linea
        INITIALIZE rh_linea[1].* TO NULL
        RETURN rh_linea[1].r03_codigo, rh_linea[1].r03_nombre
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_linea TO rh_linea.*
        ON KEY(RETURN)
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
END DISPLAY
CLOSE WINDOW wh_linea
IF int_flag THEN
        INITIALIZE rh_linea[1].* TO NULL
        RETURN rh_linea[1].r03_codigo, rh_linea[1].r03_nombre
END IF
LET  i = arr_curr()
RETURN rh_linea[i].r03_codigo, rh_linea[i].r03_nombre

END FUNCTION



FUNCTION fl_ayuda_sublinea_rep(cod_cia, linea)
DEFINE rh_sublin	ARRAY[500] OF RECORD
			        r70_sub_linea	LIKE rept070.r70_sub_linea,
				r70_desc_sub	LIKE rept070.r70_desc_sub, 
				r03_nombre	LIKE rept003.r03_nombre
		        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept070.r70_compania
DEFINE linea		LIKE rept070.r70_linea
--DEFINE nom_linea	LIKE rept003.r03_nombre
DEFINE expr_linea	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 500
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_sublin AT 06, 12 WITH 15 ROWS, 67 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf127 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf127'
ELSE
	OPEN FORM f_ayuf127 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf127c'
END IF
DISPLAY FORM f_ayuf127
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Sub Línea'     TO bt_sublinea
--#DISPLAY 'Descripción'   TO bt_descripcion
--#DISPLAY 'Línea'         TO bt_linea
		   
WHILE TRUE
{--
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r70_sub_linea, r70_desc_sub
	IF int_flag THEN
		INITIALIZE rh_sublin[1].* TO NULL
		CLOSE WINDOW w_sublin
		RETURN rh_sublin[1].r70_sub_linea, rh_sublin[1].r70_desc_sub 
	END IF
--}
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_linea = " 1 = 1 "
	IF linea IS NOT NULL THEN
		LET expr_linea = " r70_linea = '", linea, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r70_sub_linea, r70_desc_sub, r03_nombre FROM rept070, rept003 ",
			"WHERE r70_compania =  ", cod_cia, " AND ",
			"r70_compania = r03_compania", 	   " AND ",
			"r70_linea = r03_codigo ", 	   " AND ",
				 --expr_sql CLIPPED ,        " AND ",
				 expr_linea CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE sublin FROM query
        DECLARE q_sublin CURSOR FOR sublin
        LET i = 1
        FOREACH q_sublin INTO rh_sublin[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_sublin TO rh_sublin.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_sublin[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_sublin
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_sublin[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_sublin[1].* TO NULL
	RETURN rh_sublin[1].r70_sub_linea, rh_sublin[1].r70_desc_sub 
END IF
LET  i = arr_curr()
RETURN rh_sublin[i].r70_sub_linea, rh_sublin[i].r70_desc_sub 

END FUNCTION



FUNCTION fl_ayuda_grupo_ventas_rep(cod_cia, linea, sublinea)
DEFINE rh_codgrupo	ARRAY[500] OF RECORD
        			r71_cod_grupo	LIKE rept071.r71_cod_grupo,
				r71_desc_grupo	LIKE rept071.r71_desc_grupo 
        		END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql		CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query		CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept071.r71_compania
DEFINE linea		LIKE rept071.r71_linea
DEFINE sublinea		LIKE rept071.r71_sub_linea
DEFINE expr_linea	CHAR(50)
DEFINE expr_grupo	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 500
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_codgrupo AT 06, 29 WITH 15 ROWS, 50 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf128 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf128'
ELSE
	OPEN FORM f_ayuf128 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf128c'
END IF
DISPLAY FORM f_ayuf128
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Grupo'         TO bt_grupo
--#DISPLAY 'Descripción'   TO bt_descripcion
		   
WHILE TRUE
{--
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r71_cod_grupo, r71_desc_grupo
	IF int_flag THEN
		INITIALIZE rh_codgrupo[1].* TO NULL
		CLOSE WINDOW w_codgrupo
		RETURN rh_codgrupo[1].r71_cod_grupo,
		       rh_codgrupo[1].r71_desc_grupo
	END IF
--}
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_linea = " 1 = 1 "
	IF linea IS NOT NULL THEN
		LET expr_linea = " r71_linea = '", linea, "'"
	END IF
	LET expr_grupo = " 1 = 1 "
	IF sublinea IS NOT NULL THEN
		LET expr_grupo = " r71_sub_linea = '", sublinea, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r71_cod_grupo, r71_desc_grupo ",
			"FROM rept071, rept070 ",
			"WHERE r71_compania =  ", cod_cia, " AND ",
			"r71_compania  = r70_compania",   " AND ",
			"r71_linea     = r70_linea ",  " AND ",
			"r71_sub_linea = r70_sub_linea ",  " AND ",
				 --expr_sql CLIPPED ,        " AND ",
				 expr_linea CLIPPED ,	   " AND ",
				 expr_grupo CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE codgrupo FROM query
        DECLARE q_codgrupo CURSOR FOR codgrupo
        LET i = 1
        FOREACH q_codgrupo INTO rh_codgrupo[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_codgrupo TO rh_codgrupo.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_codgrupo[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_codgrupo
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_codgrupo[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_codgrupo[1].* TO NULL
	RETURN rh_codgrupo[1].r71_cod_grupo, rh_codgrupo[1].r71_desc_grupo
END IF
LET  i = arr_curr()
RETURN rh_codgrupo[i].r71_cod_grupo, rh_codgrupo[i].r71_desc_grupo

END FUNCTION



FUNCTION fl_ayuda_clase_ventas_rep(cod_cia, linea, sublinea, codgrupo)
DEFINE rh_codclase ARRAY[1000] OF RECORD
        r72_cod_clase      	LIKE rept072.r72_cod_clase,
	r72_desc_clase		LIKE rept072.r72_desc_clase 
	END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE expr_sql	CHAR(300)	## Contiene el CONSTRUCT del usuario
DEFINE query	CHAR(500)	## Contiene todo el query preparado
DEFINE j		SMALLINT
DEFINE cod_cia		LIKE rept072.r72_compania
DEFINE linea 		LIKE rept072.r72_linea
DEFINE sublinea 	LIKE rept072.r72_sub_linea
DEFINE codgrupo 	LIKE rept072.r72_cod_grupo
DEFINE expr_linea	CHAR(50)
DEFINE expr_sublinea	CHAR(50)
DEFINE expr_clase	CHAR(50)
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE vm_columna_3     SMALLINT
DEFINE col		SMALLINT
DEFINE salir 		SMALLINT


LET filas_max  = 1000
LET filas_pant = 10
OPTIONS INPUT WRAP,
	ACCEPT KEY 	F12

OPEN WINDOW w_codclase AT 06, 16 WITH 15 ROWS, 63 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf129 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf129'
ELSE
	OPEN FORM f_ayuf129 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf129c'
END IF
DISPLAY FORM f_ayuf129
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

--#DISPLAY 'Clase'         TO bt_clase
--#DISPLAY 'Descripción'   TO bt_descripcion
		   
WHILE TRUE
	--#MESSAGE 'Digite condicion-búsqueda y presione (F12)'
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON r72_cod_clase, r72_desc_clase
	IF int_flag THEN
		INITIALIZE rh_codclase[1].* TO NULL
		CLOSE WINDOW w_codclase
		RETURN rh_codclase[1].r72_cod_clase,
		       rh_codclase[1].r72_desc_clase
	END IF
	MESSAGE 'Seleccionando datos . . . espere por favor.'

	LET expr_linea = " 1 = 1 "
	IF linea IS NOT NULL THEN
		LET expr_linea = " r72_linea = '", linea, "'"
	END IF
	LET expr_sublinea = " 1 = 1 "
	IF sublinea IS NOT NULL THEN
		LET expr_sublinea = " r72_sub_linea = '", sublinea, "'"
	END IF
	LET expr_clase = " 1 = 1 "
	IF codgrupo IS NOT NULL THEN
		LET expr_clase = " r72_cod_grupo = '", codgrupo, "'"
	END IF
	
---------------
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET vm_columna_3 = 3
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
	LET query = "SELECT r72_cod_clase, r72_desc_clase FROM rept072, rept071 ",
			"WHERE r72_compania =  ", cod_cia, " AND ",
			"r72_compania = r71_compania", 	   " AND ",
			"r72_cod_grupo = r71_cod_grupo ",  " AND ",
				 expr_sql CLIPPED ,        " AND ",
				 expr_linea CLIPPED ,      " AND ",
				 expr_sublinea CLIPPED ,   " AND ",
				 expr_clase CLIPPED ,
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE codclase FROM query
        DECLARE q_codclase CURSOR FOR codclase
        LET i = 1
        FOREACH q_codclase INTO rh_codclase[i].*
                LET i = i + 1
		IF i > filas_max THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET i = i - 1
	IF i = 0 THEN
                CALL fl_mensaje_consulta_sin_registros()
                LET i = 0
                LET salir = 0
                EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		MESSAGE "                                           "
	END IF
        LET j = 1
        LET INT_FLAG = 0
	CALL set_count(i)
---------------
	DISPLAY ARRAY rh_codclase TO rh_codclase.*
		ON KEY(F2)
                        LET int_flag = 4
                        FOR i = 1 TO filas_pant
                                CLEAR rh_codclase[i].*
                        END FOR
                        EXIT DISPLAY
		ON KEY(F15)	
			LET col = 1  
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
                ON KEY(F17)
                        LET col = 3
                        EXIT DISPLAY
		--#BEFORE ROW
			--#LET j = arr_curr()
			--#MESSAGE j, ' de ', i
		ON KEY(RETURN)
                        LET salir = 1
                        EXIT DISPLAY
                --#AFTER DISPLAY
                        --#LET salir = 1

	END DISPLAY
	IF int_flag = 4  OR int_flag = 1 AND col IS NULL THEN
		EXIT WHILE
	END IF

	IF col IS NOT NULL AND NOT salir THEN
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
		INITIALIZE col TO NULL
	END IF
END WHILE
IF i = 0 THEN
        CONTINUE WHILE
END IF
IF NOT salir AND int_flag = 4 THEN
        CONTINUE WHILE
END IF
IF int_flag <> 4 THEN
	CLOSE WINDOW w_codclase
	EXIT WHILE
END IF

FOR i = 1 TO filas_pant
	CLEAR rh_codclase[i].*
END FOR
END WHILE
IF int_flag <> 0 THEN
	INITIALIZE rh_codclase[1].* TO NULL
	RETURN rh_codclase[1].r72_cod_clase, rh_codclase[1].r72_desc_clase
END IF
LET  i = arr_curr()
RETURN rh_codclase[i].r72_cod_clase, rh_codclase[i].r72_desc_clase

END FUNCTION



FUNCTION fl_ayuda_marcas_rep_asignadas(cod_cia, clase)
DEFINE rh_marcasrep ARRAY[300] OF RECORD
   	r73_marca      	 	LIKE rept073.r73_marca,
        r73_desc_marca      	LIKE rept073.r73_desc_marca
        END RECORD
DEFINE i                SMALLINT
DEFINE filas_max        SMALLINT        ## No. elementos del arreglo
DEFINE filas_pant       SMALLINT        ## No. elementos de cada pantalla
DEFINE j	SMALLINT
DEFINE query	CHAR(500)		## Contiene todo el query preparado
DEFINE cod_cia 		LIKE veht001.v01_compania
DEFINE clase		LIKE rept072.r72_cod_clase
DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE expr_clase       CHAR(80)
                                                                                
LET filas_max  = 300
OPEN WINDOW wh_marcasrep AT 06, 41 WITH 15 ROWS, 38 COLUMNS
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE OFF, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_ayuf130 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf130'
ELSE
	OPEN FORM f_ayuf130 FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf130c'
END IF
DISPLAY FORM f_ayuf130
FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR
                                                                                
--#DISPLAY 'Código'     TO bt_codigo
--#DISPLAY 'Nombre'     TO bt_nombre

LET filas_pant = fgl_scr_size('rh_marcasrep')
LET int_flag = 0
MESSAGE 'Seleccionando datos..' 
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL
                                                                                
LET salir = 0
WHILE NOT salir
--------------
LET expr_clase = ' AND  1 = 1 '
IF clase IS NOT NULL THEN
	LET expr_clase = " AND r10_cod_clase = '", clase CLIPPED, "' "
END IF
LET query = " SELECT UNIQUE r10_marca, r73_desc_marca FROM rept010, rept073 ",
		" WHERE r10_compania =  ", cod_cia, " AND ",
		"       r10_compania = r73_compania ",
		expr_clase, 
		" AND r10_marca = r73_marca ",
                    'ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE chepo FROM query
DECLARE q_chepo CURSOR FOR chepo
--------------
LET i = 1
FOREACH q_chepo INTO rh_marcasrep[i].*
        LET i = i + 1
        IF i > filas_max THEN
                EXIT FOREACH
                                                                                        END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
        CALL fl_mensaje_consulta_sin_registros()
        CLOSE WINDOW wh_marcasrep
        INITIALIZE rh_marcasrep[1].* TO NULL
        RETURN rh_marcasrep[1].r73_marca
END IF
IF vg_gui = 0 THEN
	MESSAGE "                      "
END IF
CALL set_count(i)
LET int_flag = 0
DISPLAY ARRAY rh_marcasrep TO rh_marcasrep.*
        ON KEY(RETURN)
                LET salir = 1
                EXIT DISPLAY
        ON KEY(F15)
                LET col = 1
                EXIT DISPLAY
        ON KEY(F16)
                LET col = 2
                EXIT DISPLAY
	--#BEFORE ROW
		--#LET j = arr_curr()
		--#MESSAGE  j, ' de ', i
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel('RETURN', '')
        --#AFTER DISPLAY
                --#LET salir = 1
END DISPLAY
        IF int_flag  AND col IS NULL THEN
                EXIT WHILE
        END IF
        IF col IS NOT NULL AND NOT salir THEN
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
                INITIALIZE col TO NULL
        END IF
END WHILE
CLOSE WINDOW wh_marcasrep
IF int_flag THEN
        INITIALIZE rh_marcasrep[1].* TO NULL
        RETURN rh_marcasrep[1].r73_marca
END IF
LET  i = arr_curr()
RETURN rh_marcasrep[i].r73_marca

END FUNCTION



FUNCTION fl_retorna_sublinea_rep(codcia, sub)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE sub		LIKE rept010.r10_sub_linea
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE flag		SMALLINT

LET flag = 1
INITIALIZE r_r70.* TO NULL
DECLARE q_sub CURSOR FOR
		SELECT * FROM rept070
			WHERE r70_compania  = codcia
			  AND r70_sub_linea = sub
OPEN q_sub
FETCH q_sub INTO r_r70.*
IF STATUS = NOTFOUND THEN
	LET flag = 0
END IF 
CLOSE q_sub
RETURN r_r70.*, flag

END FUNCTION



FUNCTION fl_retorna_grupo_rep(codcia, grp)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE grp		LIKE rept010.r10_cod_grupo
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE flag		SMALLINT

LET flag = 1
INITIALIZE r_r71.* TO NULL
DECLARE q_grp CURSOR FOR
		SELECT * FROM rept071
			WHERE r71_compania  = codcia
			  AND r71_cod_grupo = grp
OPEN q_grp
FETCH q_grp INTO r_r71.*
IF STATUS = NOTFOUND THEN
	LET flag = 0
END IF 
CLOSE q_grp
RETURN r_r71.*, flag

END FUNCTION



FUNCTION fl_retorna_clase_rep(codcia, cla)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE cla		LIKE rept010.r10_cod_clase
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE flag		SMALLINT

LET flag = 1
INITIALIZE r_r72.* TO NULL
DECLARE q_cla CURSOR FOR
		SELECT * FROM rept072
			WHERE r72_compania  = codcia
			  AND r72_cod_clase = cla
OPEN q_cla
FETCH q_cla INTO r_r72.*
IF STATUS = NOTFOUND THEN
	LET flag = 0
END IF 
CLOSE q_cla
RETURN r_r72.*, flag

END FUNCTION



FUNCTION fl_lee_permisos_usuarios(usuario, cod_cia, modulo, proceso)
DEFINE cod_cia          LIKE gent055.g55_compania
DEFINE modulo           LIKE gent055.g55_modulo
DEFINE usuario          LIKE gent055.g55_user
DEFINE proceso          LIKE gent055.g55_proceso
DEFINE r                RECORD LIKE gent055.*
                                                                                
INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent055
        WHERE g55_user          = usuario
          AND g55_compania      = cod_cia
          AND g55_modulo        = modulo
	  AND g55_proceso	= proceso
RETURN r.*
                                                                                
END FUNCTION

