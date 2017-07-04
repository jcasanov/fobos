--------------------------------------------------------------------------------
-- Titulo           : rolp103.4gl - Configuracion Rubros Generales de Roles
-- Elaboracion      : 27-nov-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun rolp103 base modulo compania localidad
-- Ultima Correccion: 27-nov-2001
-- Motivo Correccion: (RCA) Revisión y Correccion para Aceros
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_n06		RECORD LIKE rolt006.*
DEFINE rm_n07		RECORD LIKE rolt007.*
DEFINE rm_n16		RECORD LIKE rolt016.*

	---- DETALLE PRIMERA PRESENTACION  ----
DEFINE r_detalle	ARRAY[250] OF RECORD
				n06_cod_rubro	LIKE rolt006.n06_cod_rubro,
				n06_orden	LIKE rolt006.n06_orden,
				n06_nombre	LIKE rolt006.n06_nombre,
				n06_nombre_abr	LIKE rolt006.n06_nombre_abr,
				n06_det_tot	VARCHAR(15),
				n06_estado	LIKE rolt006.n06_estado
			END RECORD
	---------------------------------------------

DEFINE rm_rub_bas	ARRAY[100] OF RECORD
				n08_cod_rubro	LIKE rolt008.n08_cod_rubro,
				nombre_rub	LIKE rolt006.n06_nombre_abr,
				n08_rubro_base	LIKE rolt008.n08_rubro_base,
				nombre_bas	LIKE rolt006.n06_nombre_abr
			END RECORD
DEFINE vm_num_rub	SMALLINT
DEFINE vm_max_rub	SMALLINT
DEFINE vm_max_detalle	SMALLINT
DEFINE vm_num_detalle	SMALLINT
DEFINE vm_filas_pant	SMALLINT
DEFINE vm_flag_mant	CHAR(1)
DEFINE vm_crea_for	CHAR(1)
DEFINE vm_crea_bas	CHAR(1)
DEFINE vm_crea_id	CHAR(1)
DEFINE vm_crea_ant	CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp103.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2  AND num_args() <> 3 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_proceso = 'rolp103'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CREATE TEMP TABLE tmp_rolt006(
		n06_cod_rubro		SMALLINT,
		n06_orden		SMALLINT,
		n06_nombre		VARCHAR(30),
		n06_nombre_abr		VARCHAR(15),
		n06_det_tot		VARCHAR(15),
		n06_estado		CHAR(1)
	)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	INSERT KEY F30,
	DELETE KEY F31
OPEN WINDOW w_rolf103_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_103 FROM '../forms/rolf103_1'
DISPLAY FORM f_103
LET vm_max_detalle = 250
LET vm_max_rub     = 100
LET vm_crea_for    = 'N'
LET vm_crea_bas    = 'N'
LET vm_crea_id     = 'N'
LET vm_crea_ant    = 'N'
CALL control_display_botones()
LET vm_filas_pant = fgl_scr_size('r_detalle')
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
CALL control_cargar_detalle()
CALL control_display_array_rolt006()
LET int_flag = 0
CLOSE WINDOW w_rolf103_1
DROP TABLE tmp_rolt006
EXIT PROGRAM

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Cod.'		        TO tit_col1
DISPLAY 'Ord.'			TO tit_col2
DISPLAY 'Nombre Largo' 		TO tit_col3
DISPLAY 'Nombre Abr.'  		TO tit_col4
DISPLAY 'Detalle Totales'   	TO tit_col5
DISPLAY 'E'	 	   	TO tit_col6

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE query		VARCHAR(400)
DEFINE i 		SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*

FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
LET query = 'SELECT *  FROM rolt006'
PREPARE cons FROM query
DECLARE q_rolt006 CURSOR FOR cons
DELETE FROM tmp_rolt006
LET i = 1
FOREACH q_rolt006 INTO r_n06.*
	LET r_detalle[i].n06_cod_rubro  = r_n06.n06_cod_rubro	
	LET r_detalle[i].n06_orden      = r_n06.n06_orden	
	LET r_detalle[i].n06_nombre     = r_n06.n06_nombre
	LET r_detalle[i].n06_nombre_abr = r_n06.n06_nombre_abr	
	LET r_detalle[i].n06_estado     = r_n06.n06_estado
	CASE r_n06.n06_det_tot
		WHEN 'DI'
			LET r_detalle[i].n06_det_tot = 'DET. INGRESOS'
		WHEN 'DE'
			LET r_detalle[i].n06_det_tot = 'DET. EGRESOS'
		WHEN 'TI'
			LET r_detalle[i].n06_det_tot = 'TOT. INGRESOS'
		WHEN 'TE'
			LET r_detalle[i].n06_det_tot = 'TOT. EGRESOS'
		WHEN 'TN'
			LET r_detalle[i].n06_det_tot = 'TOTAL NETO'
	END CASE
	INSERT INTO tmp_rolt006 VALUES(r_detalle[i].*)
	LET i = i + 1
        IF i > vm_max_detalle THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET i = i - 1
IF i = 0 THEN
	LET vm_num_detalle = 1
ELSE
	LET vm_num_detalle = i
END IF

END FUNCTION



FUNCTION control_display_array_rolt006()
DEFINE j,i,k 		SMALLINT
DEFINE query		VARCHAR(400)
DEFINE resp		CHAR(6)

LET k = 1
WHILE TRUE
	INITIALIZE rm_n06.* TO NULL
	LET query = 'SELECT * FROM tmp_rolt006 ',
		' ORDER BY ', vm_columna_1, ' ',
		      rm_orden[vm_columna_1], ', ',
		      vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE	tmp_n06 FROM query
	DECLARE q_tmp_n06 CURSOR FOR tmp_n06
	LET i = 1
	FOREACH q_tmp_n06 INTO r_detalle[i].*
		LET i = i + 1
	END FOREACH
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_num_detalle)
	DISPLAY ARRAY r_detalle TO r_detalle.*
       		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
               			EXIT DISPLAY
			END IF
		ON KEY(F5)
			BEGIN WORK
				INITIALIZE rm_n06.* TO NULL
				LET vm_flag_mant = 'I'
				CALL control_ingreso_rolt006()
				IF int_flag THEN
					ROLLBACK WORK 
					CONTINUE DISPLAY
				END IF
				CALL control_insert_rolt006()		
			COMMIT WORK 
			CALL fl_mensaje_registro_ingresado()
			CALL control_cargar_detalle()
			EXIT DISPLAY
		ON KEY(F6)
			BEGIN WORK 
				LET vm_flag_mant = 'M'
				CALL fl_lee_rubro_roles(
						r_detalle[i].n06_cod_rubro)
					RETURNING rm_n06.*
				IF rm_n06.n06_estado = 'B' THEN
					ROLLBACK WORK
					CALL fgl_winmessage(vg_producto,'No puede modificar un registro que este bloqueado.','exclamation')
					CONTINUE DISPLAY
				END IF
				CALL control_ingreso_rolt006()
				IF int_flag THEN
					ROLLBACK WORK 
					CONTINUE DISPLAY
				END IF
				CALL control_update_rolt006()
			COMMIT WORK 
			CALL fl_mensaje_registro_modificado()
			CALL control_cargar_detalle()
			EXIT DISPLAY
		ON KEY(F7)
			WHENEVER ERROR CONTINUE	
			IF r_detalle[i].n06_estado = 'A' THEN
				UPDATE rolt006 SET n06_estado = 'B' 
					WHERE n06_cod_rubro = r_detalle[i].n06_cod_rubro 
				LET r_detalle[i].n06_estado = 'B'
				DISPLAY r_detalle[i].n06_estado TO 	
					r_detalle[j].n06_estado

				UPDATE tmp_rolt006 
					SET n06_estado = 
					    r_detalle[i].n06_estado 
					WHERE n06_cod_rubro = 
					      r_detalle[i].n06_cod_rubro

			ELSE
				UPDATE rolt006 SET n06_estado = 'A' 
					WHERE n06_cod_rubro = r_detalle[i].n06_cod_rubro 
				LET r_detalle[i].n06_estado = 'A'
				DISPLAY r_detalle[i].n06_estado TO 	
					r_detalle[j].n06_estado

				UPDATE tmp_rolt006 
					SET n06_estado = 
					    r_detalle[i].n06_estado 
					WHERE n06_cod_rubro = 
					      r_detalle[i].n06_cod_rubro

			END IF
			WHENEVER ERROR STOP
			IF STATUS < 0 THEN
				CALL fl_mensaje_bloqueo_otro_usuario()
			ELSE 
				CALL fl_mensaje_registro_modificado()
			END IF
		ON KEY(F15)
			LET k = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET k = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET k = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET k = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET k = 5
			EXIT DISPLAY
		ON KEY(F20)
			LET k = 6
			EXIT DISPLAY
       		BEFORE DISPLAY
       	        	CALL dialog.keysetlabel('ACCEPT', '')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			LET rm_n06.n06_nombre = r_detalle[i].n06_nombre  
			IF vm_num_detalle = 1 AND
			   r_detalle[1].n06_cod_rubro IS NULL
			THEN
				DISPLAY 0 TO num_row
				DISPLAY 0 TO max_row
			ELSE
				DISPLAY i TO num_row
				DISPLAY vm_num_detalle TO max_row
			END IF 
        	AFTER DISPLAY
               		 CONTINUE DISPLAY
	END DISPLAY
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF k <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = k 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION control_ingreso_rolt006()
DEFINE resp		CHAR(6)
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n16		RECORD LIKE rolt016.*

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_rolf103_2 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_rolf103_2 FROM '../forms/rolf103_2'
DISPLAY FORM f_rolf103_2
IF vm_flag_mant = 'I' THEN
	LET rm_n06.n06_estado      = 'A'
	LET rm_n06.n06_usuario     = vg_usuario
	LET rm_n06.n06_fecing      = CURRENT
	LET rm_n06.n06_valor_fijo  = 0
	LET rm_n06.n06_calculo     = 'N'
	LET rm_n06.n06_imprime_0   = 'N'
	LET rm_n06.n06_ing_usuario = 'N'
	LET rm_n06.n06_cont_colect = 'N'
	LET rm_n06.n06_cont_prest  = 'N'
	LET rm_n06.n06_cant_valor  = 'H'
	LET rm_n06.n06_det_tot     = 'DI'
ELSE
	WHENEVER ERROR CONTINUE
	DECLARE q_rolt006_2 CURSOR FOR
		SELECT * FROM rolt006 
			WHERE n06_cod_rubro = rm_n06.n06_cod_rubro
	FOR UPDATE 
	OPEN q_rolt006_2
	FETCH q_rolt006_2
	IF STATUS < 0 THEN
		LET int_flag = 1
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
END IF
DISPLAY BY NAME rm_n06.n06_cod_rubro,   rm_n06.n06_cant_valor,  
		rm_n06.n06_det_tot,     rm_n06.n06_calculo,  
		rm_n06.n06_imprime_0,   rm_n06.n06_ing_usuario, 
		rm_n06.n06_cont_colect, rm_n06.n06_cont_prest,  
		rm_n06.n06_flag_ident,  rm_n06.n06_usuario, 
		rm_n06.n06_fecing,	rm_n06.n06_estado
CALL fl_lee_identidad_rol(rm_n06.n06_flag_ident) RETURNING r_n16.*
DISPLAY BY NAME r_n16.n16_descripcion
CASE rm_n06.n06_estado
	WHEN 'A'
		DISPLAY 'ACTIVO' TO tit_estado
	WHEN 'B'
		DISPLAY 'BLOQUEADO' TO tit_estado
END CASE
LET int_flag = 0
INPUT BY NAME rm_n06.n06_cod_rubro,   rm_n06.n06_nombre, 
	      rm_n06.n06_nombre_abr,  rm_n06.n06_etiq_impr,  rm_n06.n06_orden, 
	      rm_n06.n06_valor_fijo,  rm_n06.n06_rubro_dscto,
	      rm_n06.n06_cant_valor,  rm_n06.n06_det_tot, 
	      rm_n06.n06_calculo,     rm_n06.n06_imprime_0, 
	      rm_n06.n06_ing_usuario, rm_n06.n06_flag_ident,
 	      rm_n06.n06_cont_colect, rm_n06.n06_cont_prest
	WITHOUT DEFAULTS	
	ON KEY(INTERRUPT)
		LET int_flag = 0
		IF FIELD_TOUCHED(n06_cod_rubro, n06_nombre,
			     n06_nombre_abr,  n06_orden,
			     n06_valor_fijo,  n06_rubro_dscto, 
			     n06_cant_valor,  n06_det_tot,
			     n06_calculo,     n06_imprime_0,
			     n06_ing_usuario, n06_flag_ident,
			     n06_cont_colect, n06_cont_prest)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(n06_flag_ident) THEN
			CALL fl_ayuda_identidad_rol()
				RETURNING r_n16.n16_flag_ident,
					  r_n16.n16_descripcion
			IF r_n16.n16_flag_ident IS NOT NULL THEN
				LET rm_n06.n06_flag_ident =r_n16.n16_flag_ident
				DISPLAY BY NAME rm_n06.n06_flag_ident,
						r_n16.n16_descripcion
			END IF
		END IF
	ON KEY(F5)
		CALL control_formula()
		LET int_flag = 0
	ON KEY(F6)
		CALL control_rubro_base()
		LET int_flag = 0
	ON KEY(F7)
		CALL control_identificacion()
		IF rm_n16.n16_flag_ident IS NOT NULL THEN
			LET rm_n06.n06_flag_ident = rm_n16.n16_flag_ident
			DISPLAY BY NAME rm_n06.n06_flag_ident,
					rm_n16.n16_descripcion
       	        	CALL dialog.keysetlabel('F8', 'Rubro Anticipos')
		END IF
		LET int_flag = 0
	ON KEY(F8)
		IF rm_n06.n06_flag_ident IS NULL THEN
			CONTINUE INPUT
		END IF
		LET int_flag = 0
		CALL fl_hacer_pregunta('Desea configurar este rubro como un Rubro de Anticipos ?', 'No')
			RETURNING resp
		IF resp = 'Yes' THEN
			LET vm_crea_ant = 'S'
		ELSE
			LET vm_crea_ant = 'N'
		END IF
		LET int_flag = 0
	BEFORE INPUT
		IF rm_n06.n06_flag_ident IS NULL THEN
       	        	CALL dialog.keysetlabel('F8', '')
		END IF
	BEFORE FIELD n06_cod_rubro
		IF vm_flag_mant = 'M' THEN
			LET r_n06.n06_cod_rubro = rm_n06.n06_cod_rubro
		END IF
	AFTER FIELD n06_cod_rubro
		IF vm_flag_mant = 'M' THEN
			LET rm_n06.n06_cod_rubro = r_n06.n06_cod_rubro
			DISPLAY BY NAME rm_n06.n06_cod_rubro
			CONTINUE INPUT
		END IF
		IF rm_n06.n06_cod_rubro IS NOT NULL THEN
			CALL fl_lee_rubro_roles(rm_n06.n06_cod_rubro)
				RETURNING r_n06.*
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Este codigo de rubro ya existe.', 'exclamation')
				NEXT FIELD n06_cod_rubro
			END IF
		END IF
	AFTER FIELD n06_calculo
		IF rm_n06.n06_calculo = 'S' THEN
			LET rm_n06.n06_ing_usuario = 'N'
			DISPLAY BY NAME rm_n06.n06_ing_usuario
		END IF
	AFTER FIELD n06_ing_usuario
		IF rm_n06.n06_ing_usuario = 'S' THEN
			LET rm_n06.n06_calculo = 'N'
			DISPLAY BY NAME rm_n06.n06_calculo
		END IF
	AFTER FIELD n06_flag_ident
		IF rm_n06.n06_flag_ident IS NOT NULL THEN
			CALL fl_lee_identidad_rol(rm_n06.n06_flag_ident)
				RETURNING r_n16.*
			IF r_n16.n16_flag_ident IS NULL AND vm_flag_mant = 'M'
			THEN
				CALL fl_mostrar_mensaje('No existe el esta identidad en la compañía.', 'exclamation')
				NEXT FIELD n06_flag_ident
			END IF
			DISPLAY BY NAME r_n16.n16_descripcion
			IF rm_n16.n16_flag_ident IS NOT NULL THEN
				LET rm_n06.n06_flag_ident =rm_n16.n16_flag_ident
				DISPLAY BY NAME rm_n06.n06_flag_ident,
						rm_n16.n16_descripcion
			END IF
			IF validar_existe_flag_id(rm_n06.n06_flag_ident) THEN
				NEXT FIELD n06_flag_ident
			END IF
       	        	CALL dialog.keysetlabel('F8', 'Rubro Anticipos')
		ELSE
       	        	CALL dialog.keysetlabel('F8', '')
			CLEAR n16_descripcion
		END IF
END INPUT
CLOSE WINDOW w_rolf103_2
RETURN

END FUNCTION



FUNCTION control_formula()
DEFINE resp		CHAR(6)

CALL fl_lee_rubro_que_se_calcula(rm_n06.n06_cod_rubro) RETURNING rm_n07.*
IF rm_n07.n07_cod_rubro IS NULL THEN
	LET rm_n07.n07_tipo_calc   = 'N'
	LET rm_n07.n07_operacion   = 'P'
	LET rm_n07.n07_factor      = 0.00
	LET rm_n07.n07_valor_max   = 0.00
	LET rm_n07.n07_valor_min   = 0.00
	LET rm_n07.n07_ganado_max  = 0.00
	LET rm_n07.n07_sum_liq_ant = 'N'
	LET rm_n07.n07_usuario     = vg_usuario
	LET rm_n07.n07_fecing      = CURRENT
END IF
LET rm_n07.n07_cod_rubro = rm_n06.n06_cod_rubro
CASE rm_n07.n07_operacion
	WHEN '*' LET rm_n07.n07_operacion = 'P'
	WHEN '/' LET rm_n07.n07_operacion = 'D'
END CASE
OPEN WINDOW w_rolf103_3 AT 05, 07 WITH 18 ROWS, 68 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
OPEN FORM f_rolf103_3 FROM '../forms/rolf103_3'
DISPLAY FORM f_rolf103_3
DISPLAY BY NAME rm_n07.*, rm_n06.n06_nombre
LET vm_crea_for = 'S'
LET int_flag    = 0
INPUT BY NAME rm_n07.*
	WITHOUT DEFAULTS	
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(n07_tipo_calc, n07_operacion, n07_factor,
				 n07_valor_max, n07_valor_min, n07_ganado_max,
				 n07_sum_liq_ant)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	AFTER INPUT
		CASE rm_n07.n07_operacion
			WHEN 'P' LET rm_n07.n07_operacion = '*'
			WHEN 'D' LET rm_n07.n07_operacion = '/'
		END CASE
		IF rm_n07.n07_valor_min > rm_n07.n07_valor_max THEN
			CALL fl_mostrar_mensaje('El valor mínimo no puede ser mayor que el valor maximo.', 'exclamation')
			NEXT FIELD n07_valor_min
		END IF
		IF rm_n07.n07_valor_min > rm_n07.n07_ganado_max THEN
			CALL fl_mostrar_mensaje('El valor mínimo no puede ser mayor que el valor ganado maximo.', 'exclamation')
			NEXT FIELD n07_valor_min
		END IF
		IF rm_n07.n07_ganado_max > rm_n07.n07_valor_max THEN
			CALL fl_mostrar_mensaje('El valor ganado maximo no puede ser mayor que el valor maximo.', 'exclamation')
			NEXT FIELD n07_ganado_max
		END IF
END INPUT
IF int_flag THEN
	INITIALIZE rm_n07.* TO NULL
	LET vm_crea_for = 'N'
END IF
CLOSE WINDOW w_rolf103_3
RETURN

END FUNCTION



FUNCTION control_rubro_base()
DEFINE resp		CHAR(6)
DEFINE i, j, max_row	SMALLINT
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n08		RECORD LIKE rolt008.*

OPEN WINDOW w_rolf103_4 AT 06, 17 WITH 12 ROWS, 47 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
OPEN FORM f_rolf103_4 FROM '../forms/rolf103_4'
DISPLAY FORM f_rolf103_4
DISPLAY 'Rub.'		TO tit_col1
DISPLAY 'Nombre Rubro'	TO tit_col2
DISPLAY 'Bas.'		TO tit_col3
DISPLAY 'Nombre Base'	TO tit_col4
FOR i = 1 TO vm_max_rub
	INITIALIZE rm_rub_bas[i].* TO NULL
END FOR
DECLARE q_n08 CURSOR FOR
	SELECT * FROM rolt008 WHERE n08_cod_rubro = rm_n06.n06_cod_rubro
LET vm_num_rub = 1
FOREACH q_n08 INTO r_n08.*
	LET rm_rub_bas[vm_num_rub].n08_cod_rubro  = r_n08.n08_cod_rubro
	LET rm_rub_bas[vm_num_rub].nombre_rub     = rm_n06.n06_nombre_abr
	LET rm_rub_bas[vm_num_rub].n08_rubro_base = r_n08.n08_rubro_base
	CALL fl_lee_rubro_roles(r_n08.n08_rubro_base) RETURNING r_n06.*
	LET rm_rub_bas[vm_num_rub].nombre_bas     = r_n06.n06_nombre_abr
	LET vm_num_rub = vm_num_rub + 1
	IF vm_num_rub > vm_max_rub THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rub = vm_num_rub - 1
IF vm_num_rub = 0 THEN
	LET vm_num_rub = 1
	LET rm_rub_bas[vm_num_rub].n08_cod_rubro  = rm_n06.n06_cod_rubro
	LET rm_rub_bas[vm_num_rub].nombre_rub     = rm_n06.n06_nombre_abr
END IF
LET vm_crea_bas = 'S'
LET int_flag    = 0
CALL set_count(vm_num_rub)
INPUT ARRAY rm_rub_bas WITHOUT DEFAULTS FROM rm_rub_bas.*
	ON KEY(INTERRUPT)
        	LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso() RETURNING resp
                IF resp = 'Yes' THEN
                	LET int_flag = 1
                        EXIT INPUT
                END IF
	ON KEY(F2)
		IF INFIELD(n08_rubro_base) THEN
			CALL fl_ayuda_rubros_generales_roles('00', 'T', 'T',
								'T', 'T', 'T')
				RETURNING r_n06.n06_cod_rubro, r_n06.n06_nombre 
			LET int_flag = 0
			IF r_n06.n06_cod_rubro IS NOT NULL THEN
				LET rm_rub_bas[i].n08_rubro_base =
							r_n06.n06_cod_rubro
				LET rm_rub_bas[i].nombre_bas     =
							r_n06.n06_nombre
				DISPLAY rm_rub_bas[i].* TO rm_rub_bas[j].*
			END IF
		END IF
	BEFORE ROW
		LET i       = arr_curr()
		LET j       = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL mostrar_contadores_det(i, max_row)
	AFTER FIELD n08_rubro_base
		IF rm_rub_bas[i].n08_rubro_base = rm_n06.n06_cod_rubro
		THEN
			CALL fl_mostrar_mensaje('El rubro base debe ser diferente del codigo rubro.', 'exclamation')
			NEXT FIELD n08_rubro_base
		END IF
		IF rm_rub_bas[i].n08_rubro_base IS NOT NULL THEN
			CALL fl_lee_rubro_roles(rm_rub_bas[i].n08_rubro_base)
				RETURNING r_n06.*
			IF r_n06.n06_cod_rubro IS NULL THEN
				CALL fl_mostrar_mensaje('El rubro no existe.', 'exclamation')
				NEXT FIELD n08_rubro_base
			END IF
			LET rm_rub_bas[i].n08_cod_rubro = rm_n06.n06_cod_rubro
			LET rm_rub_bas[i].nombre_rub    = rm_n06.n06_nombre_abr
			LET rm_rub_bas[i].nombre_bas    = r_n06.n06_nombre_abr
			DISPLAY rm_rub_bas[i].* TO rm_rub_bas[j].*
		END IF
	AFTER INPUT
		LET vm_num_rub = arr_count()
		FOR i = 1 TO vm_num_rub - 1
			FOR j = i + 1 TO vm_num_rub
				IF rm_rub_bas[i].n08_rubro_base =
				   rm_rub_bas[j].n08_rubro_base
				THEN
					CALL fl_mostrar_mensaje('El rubro base no puede repetirse.', 'exclamation')
					NEXT FIELD n08_rubro_base
				END IF
			END FOR
		END FOR
END INPUT
IF int_flag THEN
	LET vm_crea_for = 'N'
END IF
CLOSE WINDOW w_rolf103_4
RETURN

END FUNCTION



FUNCTION mostrar_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION control_identificacion()
DEFINE resp		CHAR(6)
DEFINE flag_ident	LIKE rolt016.n16_flag_ident

OPEN WINDOW w_rolf103_5 AT 10, 22 WITH 07 ROWS, 37 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
OPEN FORM f_rolf103_5 FROM '../forms/rolf103_5'
DISPLAY FORM f_rolf103_5
LET flag_ident = NULL
CALL fl_lee_identidad_rol(rm_n06.n06_flag_ident) RETURNING rm_n16.*
IF rm_n16.n16_flag_ident IS NOT NULL THEN
	LET flag_ident = rm_n16.n16_flag_ident
END IF
DISPLAY BY NAME rm_n16.*
LET vm_crea_id = 'S'
LET int_flag   = 0
INPUT BY NAME rm_n16.*
	WITHOUT DEFAULTS	
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(n16_flag_ident, n16_descripcion)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	AFTER FIELD n16_flag_ident
		IF flag_ident IS NOT NULL THEN
			LET rm_n16.n16_flag_ident = flag_ident
			DISPLAY BY NAME rm_n16.n16_flag_ident
		END IF
		IF validar_existe_flag_id(rm_n16.n16_flag_ident) THEN
			NEXT FIELD n16_flag_ident
		END IF
END INPUT
IF int_flag THEN
	INITIALIZE rm_n16.* TO NULL
	LET vm_crea_id = 'N'
END IF
CLOSE WINDOW w_rolf103_5
RETURN

END FUNCTION



FUNCTION control_actualizacion_otras_config(flag)
DEFINE flag		SMALLINT
DEFINE r_n07		RECORD LIKE rolt007.*
DEFINE r_n16		RECORD LIKE rolt016.*
DEFINE i		SMALLINT

IF vm_crea_for = 'S' AND NOT flag THEN
	CALL fl_lee_rubro_que_se_calcula(rm_n07.n07_cod_rubro) RETURNING r_n07.*
	IF r_n07.n07_cod_rubro IS NULL THEN
		LET rm_n07.n07_fecing = CURRENT
		INSERT INTO rolt007 VALUES (rm_n07.*)
	ELSE
		UPDATE rolt007 SET * = rm_n07.*
			WHERE n07_cod_rubro = rm_n07.n07_cod_rubro
	END IF
END IF
IF vm_crea_id = 'S' AND flag THEN
	CALL fl_lee_identidad_rol(rm_n16.n16_flag_ident) RETURNING r_n16.*
	IF r_n16.n16_flag_ident IS NULL THEN
		INSERT INTO rolt016 VALUES (rm_n16.*)
	ELSE
		UPDATE rolt016 SET n16_descripcion = rm_n16.n16_descripcion
			WHERE n16_flag_ident = rm_n16.n16_flag_ident
	END IF
END IF
IF vm_crea_bas = 'S' AND NOT flag THEN
	DELETE FROM rolt008 WHERE n08_cod_rubro = rm_n06.n06_cod_rubro
	FOR i = 1 TO vm_num_rub
		INSERT INTO rolt008 (n08_cod_rubro, n08_rubro_base)
			VALUES (rm_rub_bas[i].n08_cod_rubro,
				rm_rub_bas[i].n08_rubro_base)
	END FOR
END IF
IF vm_crea_ant = 'S' AND NOT flag THEN
	IF rm_n06.n06_flag_ident IS NOT NULL THEN
		DELETE FROM rolt018 WHERE n18_cod_rubro = rm_n06.n06_cod_rubro
		INSERT INTO rolt018
			VALUES(rm_n06.n06_cod_rubro, rm_n06.n06_flag_ident,
				vg_usuario, CURRENT)
	END IF
END IF

END FUNCTION



FUNCTION validar_existe_flag_id(flag_ident)
DEFINE flag_ident	LIKE rolt016.n16_flag_ident
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE query		VARCHAR(300)
DEFINE expr_sql		VARCHAR(100)
DEFINE resul		SMALLINT

LET resul    = 0
LET expr_sql = NULL
IF rm_n06.n06_cod_rubro IS NOT NULL THEN
	LET expr_sql = '   AND n06_cod_rubro <> ', rm_n06.n06_cod_rubro
END IF
LET query = 'SELECT * FROM rolt006 ',
		' WHERE n06_flag_ident = "', flag_ident, '"',
		expr_sql CLIPPED
PREPARE cons_flag FROM query
DECLARE q_flag CURSOR FOR cons_flag
OPEN q_flag
FETCH q_flag INTO r_n06.*
IF STATUS <> NOTFOUND THEN
	IF flag_ident <> 'AN' AND flag_ident <> 'BO' THEN
		CALL fl_mostrar_mensaje('La identidad ' || flag_ident || ' esta asignado al rubro ' || r_n06.n06_cod_rubro || ' ' || r_n06.n06_nombre_abr || '.', 'exclamation')
		LET resul = 1
	END IF
END IF
CLOSE q_flag
FREE q_flag
RETURN resul

END FUNCTION



FUNCTION control_insert_rolt006()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n09		RECORD LIKE rolt009.*
DEFINE r_n11		RECORD LIKE rolt011.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE query		CHAR(600)
DEFINE i		SMALLINT

IF rm_n06.n06_cod_rubro IS NULL THEN
	SELECT MAX(n06_cod_rubro) + 1 INTO rm_n06.n06_cod_rubro FROM rolt006
		WHERE n06_det_tot = rm_n06.n06_det_tot
	CALL fl_lee_rubro_roles(rm_n06.n06_cod_rubro) RETURNING r_n06.*
	IF r_n06.n06_cod_rubro IS NOT NULL THEN
		SELECT MAX(n06_cod_rubro) + 1 INTO rm_n06.n06_cod_rubro
			FROM rolt006
	END IF
	IF rm_n06.n06_cod_rubro IS NULL THEN
		LET rm_n06.n06_cod_rubro = 1
	END IF
END IF
CALL control_actualizacion_otras_config(1)
INSERT INTO rolt006 VALUES (rm_n06.*)
CALL control_actualizacion_otras_config(0)
DECLARE q_rolt001 CURSOR FOR SELECT * FROM rolt001
FOREACH q_rolt001 INTO r_n01.*
	IF r_n01.n01_estado <> 'A' THEN
		CONTINUE FOREACH
	END IF
	LET r_n09.n09_compania  = r_n01.n01_compania
	LET r_n09.n09_cod_rubro = rm_n06.n06_cod_rubro
	LET r_n09.n09_estado    = 'A'
	LET r_n09.n09_valor     = 0
	LET r_n09.n09_usuario   = vg_usuario
	LET r_n09.n09_fecing    = CURRENT
	INSERT INTO rolt009 VALUES(r_n09.*)
	LET r_n11.n11_compania  = r_n01.n01_compania
	LET r_n11.n11_cod_rubro = rm_n06.n06_cod_rubro
	LET r_n11.n11_usuario   = vg_usuario
	IF r_n01.n01_rol_mensual = 'S' THEN
		LET r_n11.n11_cod_liqrol = 'ME'
		LET r_n11.n11_fecing     = CURRENT
		INSERT INTO rolt011 VALUES(r_n11.*)
	END IF
	IF r_n01.n01_rol_quincen = 'S' THEN
		LET r_n11.n11_cod_liqrol = 'Q1'
		LET r_n11.n11_fecing     = CURRENT
		INSERT INTO rolt011 VALUES(r_n11.*)
		LET r_n11.n11_cod_liqrol = 'Q2'
		LET r_n11.n11_fecing     = CURRENT
		INSERT INTO rolt011 VALUES(r_n11.*)
	END IF
	IF r_n01.n01_rol_semanal = 'S' THEN
		FOR i = 1 TO 5
			LET r_n11.n11_cod_liqrol = 'S', i USING "&"
			LET r_n11.n11_fecing     = CURRENT
			INSERT INTO rolt011 VALUES(r_n11.*)
		END FOR
	END IF
	INITIALIZE r_n05.* TO NULL
	SELECT * INTO r_n05.* FROM rolt005
		WHERE n05_compania = r_n01.n01_compania
		  AND n05_activo   = 'S'
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
	IF r_n05.n05_compania IS NOT NULL THEN
		DECLARE q_ultliq CURSOR FOR
			SELECT * FROM rolt032
				WHERE n32_compania   = r_n05.n05_compania
				  AND n32_cod_liqrol = r_n05.n05_proceso
				  AND n32_estado     = 'A'
				ORDER BY n32_fecha_ini DESC
		OPEN q_ultliq
		FETCH q_ultliq INTO r_n32.*
		LET query = 'INSERT INTO rolt033 ',
				' SELECT n32_compania, n32_cod_liqrol, ',
					' n32_fecha_ini, n32_fecha_fin, ',
					' n32_cod_trab, ', rm_n06.n06_cod_rubro,
					', "", "", "", ',rm_n06.n06_orden,', "',
					rm_n06.n06_det_tot, '", "',
					rm_n06.n06_imprime_0, '", "',
					rm_n06.n06_cant_valor, '", "", ',
					rm_n06.n06_valor_fijo,
					' FROM rolt032 ',
					' WHERE n32_compania   = ',
						r_n32.n32_compania,
					'   AND n32_cod_liqrol = "',
						r_n32.n32_cod_liqrol, '"',
					'   AND n32_fecha_ini  = "',
						r_n32.n32_fecha_ini, '"',
					'   AND n32_fecha_fin  = "',
						r_n32.n32_fecha_fin, '"'
		PREPARE inssel FROM query
		EXECUTE inssel
		CLOSE q_ultliq
		FREE q_ultliq
	END IF
END FOREACH
DISPLAY BY NAME rm_n06.n06_cod_rubro

END FUNCTION



FUNCTION control_update_rolt006()

CALL control_actualizacion_otras_config(1)
UPDATE rolt006 SET * = rm_n06.* WHERE CURRENT OF q_rolt006_2
CALL control_actualizacion_otras_config(0)

END FUNCTION
