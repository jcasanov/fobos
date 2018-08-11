--------------------------------------------------------------------------------
-- Titulo           : repp203.4gl - Generacion Pedido Sugerido
-- Elaboracion      : 17-Jul-2002
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp203 base RE 1 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r16		RECORD LIKE rept016.*			
DEFINE rm_p02		RECORD LIKE cxpt002.*
DEFINE rm_par		RECORD
				r16_pedido	LIKE rept016.r16_pedido,
				r16_referencia	LIKE rept016.r16_referencia,
				r16_linea	LIKE rept016.r16_linea,
				r16_proveedor	LIKE rept016.r16_proveedor,
				bod_est		CHAR(2),
				r16_periodo_vta	LIKE rept016.r16_periodo_vta,
				periodo_vtp	SMALLINT,
				r16_minimo	LIKE rept016.r16_minimo,
				r16_maximo	LIKE rept016.r16_maximo,
				--r16_pto_reorden	LIKE rept016.r16_pto_reorden,
				flag_vtp	CHAR(1),
				flag_ped	CHAR(1)
			END RECORD



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp203.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

{*
 * 4 argumentos es la llamada normal
 *}
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp203'
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
OPEN WINDOW w_sug AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_sug FROM '../forms/repf203_1'
ELSE
	OPEN FORM f_sug FROM '../forms/repf203_1c'
END IF
DISPLAY FORM f_sug
WHILE TRUE
      	CLEAR name_prov, name_bod
	INITIALIZE rm_par.* TO NULL
	LET rm_par.flag_vtp = 'S'
	LET rm_par.flag_ped = 'S'
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	BEGIN WORK
		CALL control_generacion()
	COMMIT WORK
	CALL fl_mensaje_registro_ingresado()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE codlin		LIKE rept003.r03_codigo
DEFINE nomlin		LIKE rept003.r03_nombre
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE name_prov	LIKE cxpt001.p01_nomprov
DEFINE codbod		LIKE rept002.r02_codigo
DEFINE name_bod		LIKE rept002.r02_nombre
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r16		RECORD LIKE rept016.*
DEFINE r_p01		RECORD LIKE cxpt001.*

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		RETURN
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r16_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING codlin, nomlin
			IF codlin IS NOT NULL THEN
				LET rm_par.r16_linea = codlin
				DISPLAY BY NAME rm_par.r16_linea
			END IF
		END IF
		IF INFIELD(r16_proveedor) THEN                                         
			CALL fl_ayuda_proveedores_localidad(vg_codcia, vg_codloc)
					RETURNING codprov, name_prov
			IF codprov IS NOT NULL THEN                                 
				LET rm_par.r16_proveedor = codprov                      
				DISPLAY BY NAME rm_par.r16_proveedor, name_prov                   
			END IF                                                     	
                END IF                                                             
                IF INFIELD(bod_est) THEN                                     
                	CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'A', 'F', 'R', 'N', 'I')
				RETURNING codbod, name_bod
                	IF codbod IS NOT NULL THEN
                		LET rm_par.bod_est = codbod                 
                		DISPLAY BY NAME rm_par.bod_est, name_bod
                	END IF                                                     
                END IF                                                             
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r16_pedido
		IF rm_par.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_par.r16_pedido)
					RETURNING r_r16.*
			IF r_r16.r16_pedido IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Pedido ya existe.', 'exclamation')
				NEXT FIELD r16_pedido
			END IF
		END IF
	AFTER FIELD r16_linea                                                                  	
		IF rm_par.r16_linea IS NOT NULL THEN                                           	
			CALL fl_lee_linea_rep(vg_codcia, rm_par.r16_linea) RETURNING r_r03.*                                       
        		IF r_r03.r03_codigo IS NULL THEN                                    
				CALL fl_mostrar_mensaje('Línea no existe.', 'exclamation')
        			NEXT FIELD r16_linea                                           
        		END IF                      
        	 END IF                                                                          
	AFTER FIELD r16_proveedor                                                                  
		IF rm_par.r16_proveedor IS NOT NULL THEN                                           
			CALL fl_lee_proveedor(rm_par.r16_proveedor) RETURNING r_p01.*   
        		IF r_p01.p01_codprov IS NULL THEN                                       
				CALL fl_mostrar_mensaje('Proveedor no existe.', 'exclamation')
        			NEXT FIELD r16_proveedor                                           
        		END IF     
        		DISPLAY r_p01.p01_nomprov TO name_prov                                     
        		CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, 
        					rm_par.r16_proveedor) RETURNING rm_p02.*              
        		IF rm_p02.p02_codprov IS NULL THEN                                          
					CALL fl_mostrar_mensaje('Proveedor no está activado para la compañía.', 'exclamation')
        			NEXT FIELD r16_proveedor                                                                  
        	 	END IF                                                                                                                                            
        	ELSE
        	 	CLEAR name_prov
		END IF
	AFTER FIELD bod_est                                                                                          
        	IF rm_par.bod_est IS NOT NULL THEN                                                                   
        		CALL fl_lee_bodega_rep(vg_codcia, rm_par.bod_est) RETURNING r_r02.*                                      
        		IF r_r02.r02_codigo IS NULL THEN                                                                  
					CALL fl_mostrar_mensaje('Bodega no existe.', 'exclamation')                        
        			NEXT FIELD bod_est                                                                   
        		END IF                                                                                             
        		DISPLAY r_r02.r02_nombre TO name_bod                                                             
        	ELSE
        	 	CLEAR name_bod
        	END IF                                                                                                     
	AFTER FIELD r16_periodo_vta
		IF rm_par.r16_periodo_vta IS NOT NULL THEN 
			IF rm_par.periodo_vtp IS NULL THEN                                                                  	  
				LET rm_par.periodo_vtp = rm_par.r16_periodo_vta
				DISPLAY BY NAME rm_par.periodo_vtp 
			END IF
		END IF
	AFTER INPUT
		IF rm_par.periodo_vtp > rm_par.r16_periodo_vta THEN
			CALL fl_mostrar_mensaje('El periodo de cálculo para ventas perdidas no puede ser mayor al de las ventas.','exclamation')
            NEXT FIELD periodo_vtp
        END IF                                                                                                                                                                                 
		IF rm_par.r16_minimo >= rm_par.r16_maximo THEN
			CALL fl_mostrar_mensaje('El periodo mínimo debe ser menor al máximo. ', 'exclamation')
                        NEXT FIELD r16_minimo
                END IF                                          
END INPUT

END FUNCTION            



FUNCTION control_generacion()
DEFINE uni_vta, uni_vtp		INTEGER
DEFINE uni_vta_vtp		INTEGER
DEFINE grupo_linea		LIKE gent020.g20_grupo_linea
DEFINE r_g16			RECORD LIKE gent016.*
DEFINE r_r10			RECORD LIKE rept010.*
DEFINE r_r16			RECORD LIKE rept016.*
DEFINE r_r17			RECORD LIKE rept017.*
DEFINE r_r18			RECORD LIKE rept018.*
DEFINE r_r04			RECORD LIKE rept004.*
DEFINE r_r00			RECORD LIKE rept000.*
DEFINE total_items		INTEGER
DEFINE total_stock		INTEGER
DEFINE tot_stock_gen		INTEGER
DEFINE uni_pedir		DECIMAL(8,0)
DEFINE promedio_vta		DECIMAL(10,2)
DEFINE uni_maximo		DECIMAL(10,2)
DEFINE uni_minimo		DECIMAL(10,2)
DEFINE i			INTEGER

INITIALIZE r_r16.* TO NULL

IF rm_par.bod_est IS NOT NULL THEN
	SELECT r02_codigo FROM rept002 
		WHERE r02_estado = 'A' AND r02_codigo = rm_par.bod_est
	INTO TEMP temp_bodegas
ELSE
	SELECT r02_codigo FROM rept002                                
		WHERE r02_estado = 'A'
	INTO TEMP temp_bodegas                                        
END IF	
CALL carga_estadisticas_generales(rm_par.r16_periodo_vta, rm_par.periodo_vtp)
LET r_r16.r16_compania		= vg_codcia 
LET r_r16.r16_localidad  	= vg_codloc
LET r_r16.r16_pedido 		= rm_par.r16_pedido
LET r_r16.r16_estado  		= 'A'
LET r_r16.r16_tipo  		= 'S'
LET r_r16.r16_linea 		= rm_par.r16_linea
LET r_r16.r16_referencia 	= rm_par.r16_referencia
LET r_r16.r16_proveedor 	= rm_par.r16_proveedor
LET r_r16.r16_moneda  		= rg_gen.g00_moneda_base
LET r_r16.r16_demora  		= rm_p02.p02_dias_demora
LET r_r16.r16_seguridad 	= rm_p02.p02_dias_seguri
LET r_r16.r16_maximo  		= rm_par.r16_maximo
LET r_r16.r16_minimo  		= rm_par.r16_minimo
LET r_r16.r16_periodo_vta     	= rm_par.r16_periodo_vta
LET r_r16.r16_pto_reorden  	= 0     
LET r_r16.r16_flag_estad  	= 'M'
LET r_r16.r16_usuario 		= vg_usuario
LET r_r16.r16_fecing 		= fl_current()
INSERT INTO rept016 VALUES (r_r16.*)
LET total_items = 0
SELECT r12_item FROM temp_vta
UNION
SELECT r12_item FROM temp_vtp
INTO TEMP temp_unique
DECLARE qu_sug CURSOR FOR 
	SELECT rept010.*
		FROM temp_unique, rept010
		WHERE r12_item     = r10_codigo AND 
		      r10_compania = vg_codcia AND 
		      r10_estado   = 'A'
LET i = 0
FOREACH qu_sug INTO r_r10.*
	LET i = i + 1
	IF r_r10.r10_linea <> rm_par.r16_linea THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_indice_rotacion(vg_codcia, r_r10.r10_rotacion)
		RETURNING r_r04.*
	IF r_r04.r04_pedido <> 'S' THEN
		CONTINUE FOREACH
	END IF
	CALL obtiene_estadisticas_item(r_r10.r10_codigo)
		RETURNING uni_vta, uni_vtp
	IF uni_vta + uni_vtp <= 0 THEN
		CONTINUE FOREACH 
	END IF                   
	IF uni_vta <= 0 AND uni_vtp > 0 THEN 
		IF rm_par.flag_vtp = 'N' THEN  		    
			CONTINUE FOREACH
		END IF
	END IF
	CALL fl_lee_partida(r_r10.r10_partida) RETURNING r_g16.*
	SELECT SUM(r11_stock_act) INTO total_stock
		FROM rept011
		WHERE r11_compania = vg_codcia AND 
		      r11_bodega IN (SELECT r02_codigo FROM temp_bodegas) AND
		      r11_item     = r_r10.r10_codigo
	IF total_stock IS NULL THEN
		LET total_stock = 0
	END IF
	LET uni_vta_vtp  = uni_vta
	IF rm_par.flag_vtp = 'S' THEN  		    
		LET uni_vta_vtp  = uni_vta_vtp + uni_vtp
	END IF
	LET promedio_vta = uni_vta_vtp / rm_par.r16_periodo_vta
	LET uni_maximo   = promedio_vta * rm_par.r16_maximo		    
	LET uni_minimo   = promedio_vta * rm_par.r16_minimo
	LET tot_stock_gen = total_stock
	IF rm_par.flag_ped = 'S' THEN
		LET tot_stock_gen = tot_stock_gen + r_r10.r10_cantped +
				    r_r10.r10_cantback
	END IF				    
	IF tot_stock_gen >= uni_maximo THEN
		CONTINUE FOREACH
	END IF
	LET uni_pedir = uni_maximo - tot_stock_gen
	IF uni_pedir <= 0 THEN
		CONTINUE FOREACH
	END IF
	LET total_items = total_items + 1
	INITIALIZE r_r17.* TO NULL
	LET r_r17.r17_compania 	  = vg_codcia
	LET r_r17.r17_localidad	  = vg_codloc
	LET r_r17.r17_pedido      = rm_par.r16_pedido
	LET r_r17.r17_item	  = r_r10.r10_codigo
	LET r_r17.r17_orden	  = total_items
	LET r_r17.r17_estado	  = 'A'
	LET r_r17.r17_fob	  = r_r10.r10_fob
	LET r_r17.r17_cantped	  = uni_pedir
	LET r_r17.r17_cantrec 	  = 0
	LET r_r17.r17_exfab_mb    = 0
	LET r_r17.r17_desp_mb     = 0
	LET r_r17.r17_desp_mi     = 0
	LET r_r17.r17_tot_fob_mb  = 0
	LET r_r17.r17_tot_fob_mi  = 0
	LET r_r17.r17_flete       = 0
	LET r_r17.r17_seguro      = 0
	LET r_r17.r17_cif         = 0
	LET r_r17.r17_arancel     = 0
	LET r_r17.r17_cargos      = 0
	LET r_r17.r17_costuni_ing = 0
	LET r_r17.r17_ind_bko 	  = 'S'
	LET r_r17.r17_linea 	  = rm_par.r16_linea
	LET r_r17.r17_rotacion 	  = r_r10.r10_rotacion
	LET r_r17.r17_partida 	  = r_r10.r10_partida
	LET r_r17.r17_porc_part   = r_g16.g16_porcentaje
	LET r_r17.r17_vol_cuft    = r_r10.r10_vol_cuft
	LET r_r17.r17_peso 	  = r_r10.r10_peso
	LET r_r17.r17_cantpaq 	  = r_r10.r10_cantpaq
	INSERT INTO rept017 VALUES (r_r17.*)
	LET r_r18.r18_compania		= vg_codcia
	LET r_r18.r18_localidad		= vg_codloc
	LET r_r18.r18_pedido 		= rm_par.r16_pedido
	LET r_r18.r18_item 		= r_r10.r10_codigo
	LET r_r18.r18_stock 		= total_stock
	LET r_r18.r18_maximo 		= uni_maximo
	LET r_r18.r18_minimo 		= uni_minimo
	LET r_r18.r18_ventas 		= uni_vta
	LET r_r18.r18_ventas_perd 	= uni_vtp
	LET r_r18.r18_ped_pend 		= r_r10.r10_cantped
	LET r_r18.r18_ped_bko 		= r_r10.r10_cantback
	LET r_r18.r18_meses_vta 	= 1 
	LET r_r18.r18_periodo_stk       = 1
	LET r_r18.r18_promedio_vta      = promedio_vta
	LET r_r18.r18_reorden 		= 0
	INSERT INTO rept018 VALUES (r_r18.*)
END FOREACH	
IF total_items = 0 THEN
	CALL fl_mostrar_mensaje('No se generó pedido, verifique parámetros.', 'stop')
	DELETE FROM rept016 
		WHERE r16_compania  = vg_codcia AND 
		      r16_localidad = vg_codloc AND 
		      r16_pedido    = rm_par.r16_pedido
END IF

END FUNCTION	
	
	    
	    
FUNCTION carga_estadisticas_generales(meses_vta, meses_vtp)
DEFINE meses_vta		SMALLINT
DEFINE meses_vtp		SMALLINT
DEFINE fecha_ini, fecha_fin	DATE            

LET fecha_fin = vg_fecha - 1                                    
LET fecha_ini = fecha_fin - (rm_par.r16_periodo_vta * 30) + 1
SELECT r12_item, SUM(r12_uni_venta - r12_uni_dev) te_uni_vta FROM rept012 
	WHERE r12_compania = vg_codcia AND 
	      r12_fecha BETWEEN fecha_ini AND fecha_fin AND
	      r12_bodega IN (SELECT r02_codigo FROM temp_bodegas)
	GROUP BY 1
	INTO TEMP temp_vta
LET fecha_fin = vg_fecha - 1                                    	  
LET fecha_ini = fecha_fin - (rm_par.periodo_vtp * 30) + 1
SELECT r12_item, SUM(r12_uni_perdi) te_uni_vtp FROM rept012 
	WHERE r12_compania = vg_codcia AND                                        
	      r12_fecha BETWEEN fecha_ini AND fecha_fin AND                       
	      r12_bodega IN (SELECT r02_codigo FROM temp_bodegas)                 
	GROUP BY 1                                                                
	INTO TEMP temp_vtp

END FUNCTION



FUNCTION obtiene_estadisticas_item(codigo)                                 
DEFINE codigo			LIKE rept010.r10_codigo                                     
DEFINE uni_vta, uni_vtp		INTEGER

LET uni_vta = 0
SELECT te_uni_vta INTO uni_vta FROM temp_vta WHERE r12_item = codigo
LET uni_vtp = 0                                                     
SELECT te_uni_vtp INTO uni_vtp FROM temp_vtp WHERE r12_item = codigo
RETURN uni_vta, uni_vtp

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
