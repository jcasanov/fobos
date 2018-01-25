------------------------------------------------------------------------------
-- Titulo           : ctbp208.4gl - Generacion de diarios periodicos
-- Elaboracion      : 08-mar-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun ctbp208 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE vm_filas_pant	SMALLINT

DEFINE rm_orden         ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

DEFINE vm_nivel_cta	SMALLINT
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE vm_max_rows	SMALLINT
DEFINE rm_rows ARRAY[1000] OF RECORD
	codigo		LIKE ctbt014.b14_codigo,
	tipo_comp	LIKE ctbt014.b14_tipo_comp,
	glosa		LIKE ctbt014.b14_glosa,
	fecha		LIKE ctbt014.b14_fecha_ini,
	veces		VARCHAR(13)
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/ctbp208.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN                   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_proceso = 'ctbp208'
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
--LET vg_codloc = arg_val(4)
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE salir		SMALLINT
DEFINE i    	 	SMALLINT

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_208 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_208 FROM '../forms/ctbf208_1'
DISPLAY FORM f_208

LET vm_max_rows = 1000

CALL fl_lee_compania_contabilidad(vg_codcia) 	RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración para está compañía en el módulo.',
		'stop')
	EXIT PROGRAM
END IF

SELECT MAX(b01_nivel) INTO vm_nivel_cta FROM ctbt001
IF vm_nivel_cta IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha configurado el plan de cuentas.',
		'stop')
	EXIT PROGRAM
END IF

FOR i = 1 TO 10
        LET rm_orden[i] = 'ASC'
END FOR

LET salir = 0
WHILE NOT salir
	CLEAR FORM
	CALL setea_nombre_botones_f1()
	CALL escoge_diarios()
	IF int_flag THEN
		LET salir = 1
		CONTINUE WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION setea_nombre_botones_f1()

DISPLAY 'Cod'		TO 	bt_diario
DISPLAY 'TC'		TO 	bt_tipo_comp
DISPLAY 'Referencia'    TO 	bt_glosa        
DISPLAY 'Fecha Ini.'	TO 	bt_fecha  
DISPLAY 'Generadas'	TO 	bt_veces 

END FUNCTION



FUNCTION muestra_contadores(row_curr, num_rows)

DEFINE row_curr		SMALLINT
DEFINE num_rows		SMALLINT

DISPLAY "" AT 1,1
DISPLAY row_curr, " de ", num_rows AT 1, 68 

END FUNCTION



FUNCTION escoge_diarios()

DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE ind_arr		SMALLINT
DEFINE j		SMALLINT
DEFINE col              SMALLINT
DEFINE salir            SMALLINT
DEFINE query		CHAR(500)

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
LET rm_orden[vm_columna_2]  = 'ASC'
INITIALIZE col TO NULL

LET salir = 0
WHILE NOT salir
        LET query = 'SELECT b14_codigo, b14_tipo_comp, b14_glosa, ',
		    ' b14_fecha_ini, b14_veces_gen || " de " || ',
		    ' b14_veces_max ',
		    '	FROM ctbt014 ',
		    '	WHERE b14_compania  = ', vg_codcia,
	  	    '     AND b14_estado    = "A" ',
	            '     AND b14_veces_gen < b14_veces_max ',
                    '	ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                              ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
        PREPARE deto FROM query
        DECLARE q_deto CURSOR FOR deto 
        LET i = 1
        FOREACH q_deto INTO rm_rows[i].*
		LET rm_rows[i].veces = 
			fl_justifica_titulo('C', rm_rows[i].veces, 13)
                LET i = i + 1
                IF i > vm_max_rows THEN
                        CALL fl_mensaje_arreglo_incompleto()
                        LET INT_FLAG = 1
                        RETURN
                END IF
        END FOREACH
	LET i = i - 1
	LET ind_arr = i
	IF ind_arr = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT PROGRAM
	END IF
        
        LET i = 1
        LET j = 1
        LET INT_FLAG = 0
	IF ind_arr > 0 THEN
		CALL set_count(ind_arr)
	END IF
	DISPLAY ARRAY rm_rows TO ra_rows.*
		ON KEY(INTERRUPT)
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
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
		ON KEY(F5)	
			CALL ver_diario_periodico(vg_codcia, rm_rows[i].codigo)
			LET int_flag = 0	
		ON KEY(F6)
			CALL generar_comprobante(vg_codcia, rm_rows[i].codigo)
			IF int_flag THEN
				LET int_flag = 0
			END IF
			EXIT DISPLAY
		BEFORE DISPLAY
			--#CALL dialog.keysetlabel('ACCEPT', '')
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores(i, ind_arr)
		AFTER DISPLAY
			LET salir = 1
	END DISPLAY
	IF INT_FLAG THEN
		RETURN
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

END FUNCTION



FUNCTION ver_diario_periodico(codcia, diario)

DEFINE codcia		LIKE ctbt014.b14_compania
DEFINE diario		LIKE ctbt014.b14_codigo

DEFINE comando		VARCHAR(255)

LET comando = 'cd ..' || vg_separador || '..' || vg_separador ||
	      'CONTABILIDAD' || vg_separador || 'fuentes; ' ||
	      'fglrun ctbp202 ' || vg_base || ' CB ' || 
	      codcia || ' ' || diario

RUN comando

END FUNCTION



FUNCTION generar_comprobante(codcia, diario)

DEFINE codcia		LIKE ctbt014.b14_compania
DEFINE diario		LIKE ctbt014.b14_codigo
DEFINE num_comp		LIKE ctbt014.b14_ult_num
DEFINE resp		VARCHAR(6)

DEFINE r_b14		RECORD LIKE ctbt014.*

CALL fl_lee_diario_periodico(codcia, diario) RETURNING r_b14.*
IF r_b14.b14_codigo IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Diario periódico no existe.',
		'exclamation')
	RETURN
END IF
IF r_b14.b14_estado = 'B' THEN
	CALL fgl_winmessage(vg_producto,
		'Diario periódico está bloqueado.',
		'exclamation')
	RETURN
END IF
IF r_b14.b14_veces_gen >= r_b14.b14_veces_max THEN
	CALL fgl_winmessage(vg_producto,
		'El diario periódico se ha generado el máximo de veces ' ||
		'programadas.',
		'exclamation')
	RETURN
END IF

CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF

BEGIN WORK
INITIALIZE r_b14.* TO NULL
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR
	SELECT * FROM ctbt014 
		WHERE b14_compania = codcia 
		  AND b14_codigo   = diario
	FOR UPDATE
OPEN  q_upd
FETCH q_upd INTO r_b14.*
IF STATUS < 0 THEN	
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP

INITIALIZE num_comp TO NULL
LET num_comp = crea_comprobante_contable(r_b14.*)
IF num_comp IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se pudo generar comprobante.',
		'exclamation')
	ROLLBACK WORK
	RETURN
END IF

LET r_b14.b14_veces_gen = r_b14.b14_veces_gen + 1
LET r_b14.b14_ult_num   = num_comp
IF r_b14.b14_veces_gen  = r_b14.b14_veces_max THEN
	LET r_b14.b14_estado = 'B'
END IF

UPDATE ctbt014 SET * = r_b14.* WHERE CURRENT OF q_upd 

COMMIT WORK

CALL fl_mayoriza_comprobante(codcia, r_b14.b14_tipo_comp, num_comp, 'M')
CALL fgl_winmessage(vg_producto,
	'Se ha generado correctamente el comprobante ' || 
	r_b14.b14_tipo_comp || '-' || num_comp || '.',
	'exclamation')

END FUNCTION



FUNCTION crea_comprobante_contable(r_b14)

DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b14		RECORD LIKE ctbt014.*
DEFINE query		VARCHAR(500)

INITIALIZE r_b12.* TO NULL

LET r_b12.b12_compania  = r_b14.b14_compania
LET r_b12.b12_tipo_comp = r_b14.b14_tipo_comp
LET r_b12.b12_num_comp  = fl_numera_comprobante_contable(r_b14.b14_compania, 
				                         r_b14.b14_tipo_comp, 
  							 YEAR(vg_fecha), 
							 MONTH(vg_fecha))
LET r_b12.b12_estado    = 'A'
LET r_b12.b12_glosa     = r_b14.b14_glosa
IF r_b12.b12_tipo_comp  = 'EG' THEN
	CALL ingresa_datos_cheque() RETURNING r_b12.b12_benef_che,
					      r_b12.b12_num_cheque
END IF
LET r_b12.b12_origen    = 'A'
LET r_b12.b12_moneda    = r_b14.b14_moneda
LET r_b12.b12_paridad   = r_b14.b14_paridad
LET r_b12.b12_fec_proceso = vg_fecha
LET r_b12.b12_modulo    = 'CB'
LET r_b12.b12_usuario   = vg_usuario
LET r_b12.b12_fecing    = fl_current()

INSERT INTO ctbt012 VALUES (r_b12.*)

LET query = 'INSERT INTO ctbt013(b13_compania, b13_tipo_comp, b13_num_comp, ',
			       ' b13_secuencia, b13_cuenta, b13_valor_base, ',
			       ' b13_valor_aux, b13_fec_proceso) ', 
		' SELECT ', r_b12.b12_compania, ', "', r_b12.b12_tipo_comp,  
		      '", "', r_b12.b12_num_comp, '", b15_secuencia, ',
                         'b15_cuenta, b15_valor_base, b15_valor_aux, "', 
		         r_b12.b12_fec_proceso,
			'" FROM ctbt015 ',
			' WHERE b15_compania = ', r_b14.b14_compania,
		  	'   AND b15_codigo   = ', r_b14.b14_codigo

PREPARE stmnt1 FROM query
EXECUTE stmnt1
	       
RETURN r_b12.b12_num_comp

END FUNCTION



FUNCTION ingresa_datos_cheque()

DEFINE b12_benef_che	LIKE ctbt012.b12_benef_che
DEFINE b12_num_cheque 	LIKE ctbt012.b12_num_cheque

OPTIONS 
	INPUT WRAP,
	ACCEPT KEY F12

OPEN WINDOW w_208_2 AT 10, 10 WITH 5 ROWS, 70 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_208_2 FROM '../forms/ctbf208_2'
DISPLAY FORM f_208_2

LET int_flag = 0
INPUT BY NAME b12_benef_che, b12_num_cheque

CLOSE WINDOW w_208_2

LET int_flag = 0
RETURN b12_benef_che, b12_num_cheque

END FUNCTION



FUNCTION no_validar_parametros()

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
