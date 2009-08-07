
--------------------------------------------------------------------------------
-- Titulo               : repp222.4gl -- Proceso Actualizacion de Cambio Precios
-- Elaboración          : 21-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun repp221.4gl base RE 1
-- Ultima Correción     : 21-sep-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cam 		RECORD LIKE rept032.*
DEFINE rm_lin 		RECORD LIKE rept003.*
DEFINE rm_rot 		RECORD LIKE rept004.*
DEFINE rm_titem 	RECORD LIKE rept006.*
DEFINE rm_mon	 	RECORD LIKE gent013.*
DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_flag_mant         CHAR(1)
DEFINE vm_num_row        INTEGER
DEFINE campo_base	VARCHAR(15)

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_proceso	= 'repp222'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE resp CHAR(6)

CALL fl_nivel_isolation()
OPEN WINDOW w_cam AT 3,2 WITH 15 ROWS, 80 COLUMNS 
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_cam FROM '../forms/repf222_1'
DISPLAY FORM f_cam
CLEAR FORM
INITIALIZE rm_cam.* TO NULL
WHILE TRUE
	CALL lee_datos()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fgl_winquestion(vg_producto,'Está seguro que desea realizar el cambio de precio ','No','Yes|No|Cancel','question',1)
		RETURNING resp
	IF resp = 'Yes' THEN
		BEGIN WORK
		CALL control_actualizacion_precios()
		UPDATE rept032 SET r32_estado = 'P'
			WHERE r32_numreg = rm_cam.r32_numreg
		COMMIT WORK
		CALL fgl_winmessage(vg_producto,
				     'Proceso realizado Ok. ','info')
		CLOSE WINDOW w_cam2
		CLEAR FORM
	ELSE
		CLEAR FORM
	END IF
END WHILE

END FUNCTION



FUNCTION lee_datos()
DEFINE  resp 		CHAR(6)
DEFINE  numreg 		LIKE rept032.r32_numreg
DEFINE  linea 		LIKE rept032.r32_linea
DEFINE  porcentaje	LIKE rept032.r32_porc_fact
DEFINE  usuario		LIKE rept032.r32_usuario

OPTIONS
	INPUT  WRAP
LET int_flag = 0
INPUT BY NAME 	rm_cam.r32_numreg
	ON KEY (INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso()
			RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1 
			RETURN
		END IF 
			
	ON KEY(F2)
		IF INFIELD(r32_numreg) THEN
			CALL fl_ayuda_cambio_precios(vg_codcia,'A')
			RETURNING numreg, porcentaje, linea, usuario
			IF numreg IS NOT NULL THEN
				SELECT r32_rubro_base,r32_moneda 
				INTO rm_cam.r32_rubro_base, rm_cam.r32_moneda 
				FROM rept032 
					WHERE r32_compania = vg_codcia
					AND   r32_numreg = numreg
				CLEAR FORM
				CASE rm_cam.r32_moneda
					WHEN rg_gen.g00_moneda_base
						LET rm_cam.r32_moneda = 'A'
					WHEN rg_gen.g00_moneda_alt
						LET rm_cam.r32_moneda = 'B'
				END CASE
			    	LET rm_cam.r32_numreg    = numreg
			    	LET rm_cam.r32_linea     = linea
			    	LET rm_cam.r32_porc_fact = porcentaje
				CALL fl_lee_linea_rep(vg_codcia, linea)
        				RETURNING rm_lin.*
			    	DISPLAY BY NAME rm_cam.r32_numreg,
						rm_cam.r32_linea,
						rm_cam.r32_porc_fact,
						rm_cam.r32_moneda,
						rm_cam.r32_rubro_base
				DISPLAY rm_lin.r03_nombre TO nom_lin
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r32_numreg
                IF rm_cam.r32_numreg IS NOT NULL THEN
			SELECT *,ROWID  INTO rm_cam.*, vm_num_row FROM rept032 
				WHERE r32_compania = vg_codcia
				AND   r32_numreg = rm_cam.r32_numreg
                        IF status = NOTFOUND THEN
                                CALL fgl_winmessage (vg_producto, 'No existe Número de registro de cambio de precio ','exclamation')
                                NEXT FIELD r32_numreg
                        END IF
			CALL lee_muestra_registro(vm_num_row)
			IF rm_cam.r32_estado = 'P' THEN
                                CALL fgl_winmessage (vg_producto, 'Registro de cambio de precio ya fue procesado','exclamation')
                                NEXT FIELD r32_numreg
                        END IF
                END IF
END INPUT

END FUNCTION



FUNCTION control_actualizacion_precios()
DEFINE precio_nuevo_mb	LIKE rept010.r10_precio_mb    --DECIMAL(14,2)
DEFINE precio_nuevo_ma	LIKE rept010.r10_precio_mb    --DECIMAL(14,2)
DEFINE r32_moneda	LIKE rept032.r32_moneda
DEFINE r_item 		RECORD LIKE rept010.*
DEFINE r_conf 		RECORD LIKE gent000.*
DEFINE r_item_act ARRAY[10]  OF RECORD      
	codigo		LIKE rept010.r10_codigo,
	nombre		LIKE rept010.r10_nombre,
	precio_ant	LIKE rept010.r10_precio_mb,
	precio_nue	LIKE rept010.r10_precio_mb
	END RECORD	
DEFINE i,j,k,filas_pant  SMALLINT
DEFINE flag 		 SMALLINT

LET i = 1
LET k = 0
DECLARE q_item CURSOR FOR 
	SELECT * FROM rept010 
		WHERE r10_compania = vg_codcia
		AND   r10_linea    = rm_cam.r32_linea
OPEN WINDOW w_cam2 AT 11,13 WITH FORM "../forms/repf222_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST,MENU LINE FIRST,BORDER,
		  MESSAGE LINE LAST)
LET filas_pant = fgl_scr_size("r_item_act")
CASE rm_cam.r32_moneda
	WHEN 'A'
		LET r32_moneda = rg_gen.g00_moneda_base
	WHEN 'B'
		LET r32_moneda = rg_gen.g00_moneda_alt
END CASE
CASE rm_cam.r32_rubro_base 
	WHEN 'P'
		LET campo_base =  'Precio'
	WHEN 'C'
		LET campo_base =  'Costo'
END CASE
CALL fl_lee_moneda(r32_moneda) 
	RETURNING rm_mon.*
DISPLAY BY NAME campo_base, r32_moneda
DISPLAY rm_mon.g13_nombre TO g13_nombre
LET flag = 0
FOREACH q_item INTO r_item.*
	IF r_item.r10_rotacion <> rm_cam.r32_rotacion THEN
		CONTINUE FOREACH
	END IF
	IF r_item.r10_tipo <> rm_cam.r32_tipo_item THEN
		CONTINUE FOREACH
	END IF
	IF r_item.r10_estado <> 'A' AND r_item.r10_estado <> 'S' THEN
		CONTINUE FOREACH
	END IF
	LET precio_nuevo_ma = r_item.r10_precio_ma  
	CASE rm_cam.r32_rubro_base
		WHEN 'C'
			LET precio_nuevo_mb = r_item.r10_costo_mb + 
			(r_item.r10_costo_mb * rm_cam.r32_porc_fact / 100)	
			IF rg_gen.g00_moneda_alt IS NOT NULL THEN
		       		LET precio_nuevo_ma = r_item.r10_costo_ma + 
			     	(r_item.r10_costo_ma * rm_cam.r32_porc_fact/100)	
			END IF
		WHEN 'P'
			LET precio_nuevo_mb = r_item.r10_precio_mb + 
			(r_item.r10_precio_mb * rm_cam.r32_porc_fact / 100)	
			IF rg_gen.g00_moneda_alt IS NOT NULL THEN
			    	LET precio_nuevo_ma = r_item.r10_precio_ma + 
		            (r_item.r10_precio_ma *rm_cam.r32_porc_fact/100)	
			END IF
	END CASE
	LET precio_nuevo_mb =  fl_retorna_precision_valor(rg_gen.g00_moneda_base, precio_nuevo_mb)
	IF rg_gen.g00_moneda_alt IS NOT NULL THEN
		LET precio_nuevo_ma =  fl_retorna_precision_valor(rg_gen.g00_moneda_alt, precio_nuevo_ma)
	END IF
	CASE rm_cam.r32_moneda
		WHEN 'A'
			UPDATE rept010
				SET r10_precio_ant   = r_item.r10_precio_mb,
		    		    r10_precio_mb    = precio_nuevo_mb,
		    		    r10_fec_camprec  = CURRENT
				WHERE r10_compania   = vg_codcia
				AND   r10_codigo     = r_item.r10_codigo

			IF i > filas_pant THEN
				LET i = filas_pant
				LET flag = 1
			END IF	
			LET r_item_act[i].precio_ant = r_item.r10_precio_mb
			LET r_item_act[i].precio_nue = precio_nuevo_mb
		WHEN 'B'
			UPDATE rept010
				SET r10_precio_ma    = precio_nuevo_ma,
		    		    r10_fec_camprec  = CURRENT
				WHERE r10_compania   = vg_codcia
				AND   r10_codigo     = r_item.r10_codigo

			IF i > filas_pant THEN
				LET i = filas_pant
				LET flag = 1
			END IF	
			LET r_item_act[i].precio_ant = r_item.r10_precio_ma
			LET r_item_act[i].precio_nue = precio_nuevo_ma
	END CASE
	IF i > filas_pant  OR flag = 1 THEN
		LET i = filas_pant
		LET flag = 1
		FOR j = 1 TO filas_pant - 1 
			DISPLAY r_item_act[j + 1].* TO r_item_act[j].*
			LET r_item_act[j].* = r_item_act[j + 1].*
		END FOR
	END IF 	
	LET r_item_act[i].codigo        = r_item.r10_codigo
	LET r_item_act[i].nombre        = r_item.r10_nombre
	DISPLAY r_item_act[i].* TO r_item_act[i].*
        LET k = k + 1
	DISPLAY  k TO num_items
        LET i = i + 1
END FOREACH

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

SELECT * INTO rm_cam.* FROM rept032 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
CASE rm_cam.r32_moneda
	WHEN rg_gen.g00_moneda_base
		LET rm_cam.r32_moneda = 'A'
	WHEN rg_gen.g00_moneda_alt
		LET rm_cam.r32_moneda = 'B'
END CASE
DISPLAY BY NAME rm_cam.r32_numreg, rm_cam.r32_linea, rm_cam.r32_moneda, 
		rm_cam.r32_rotacion, rm_cam.r32_tipo_item,
		rm_cam.r32_porc_fact, rm_cam.r32_rubro_base
CALL fl_lee_indice_rotacion(vg_codcia, rm_cam.r32_rotacion)
        RETURNING rm_rot.*
	DISPLAY rm_rot.r04_nombre TO nom_rot
CALL fl_lee_linea_rep(vg_codcia, rm_cam.r32_linea)
        RETURNING rm_lin.*
	DISPLAY rm_lin.r03_nombre TO nom_lin
CALL fl_lee_tipo_item(rm_cam.r32_tipo_item)
	RETURNING rm_titem.*
	DISPLAY rm_titem.r06_nombre TO nom_tipo

END FUNCTION



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
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
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

