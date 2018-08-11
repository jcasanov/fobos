--------------------------------------------------------------------------------
-- Titulo           : rolp104.4gl - Asignación Rubros a Procesos
-- Elaboracion      : 04-dic-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun rolp104 base modulo compania 
-- Ultima Correccion: 04-dic-2001
-- Motivo Correccion: 1
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_n11			RECORD LIKE rolt011.*	
DEFINE rm_n03			RECORD LIKE rolt003.*	
DEFINE rm_n06			RECORD LIKE rolt006.*	

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[100] OF RECORD
	n11_cod_rubro		LIKE rolt011.n11_cod_rubro,
	n06_nombre		LIKE rolt006.n06_nombre,
	seleccionar		CHAR(1)
	END RECORD
	---------------------------------------------

DEFINE vm_ind_arr		SMALLINT   
DEFINE vm_max_detalle		SMALLINT   
DEFINE vm_filas_pant		SMALLINT  



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp104.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'rolp104'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso) 
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT

CALL fl_nivel_isolation()
CREATE TEMP TABLE tmp_rolt011(
	n11_cod_rubro		SMALLINT,
	n06_nombre		VARCHAR(30),
	seleccionar		CHAR(1))

CREATE UNIQUE INDEX tmp_ind ON tmp_rolt011(n11_cod_rubro)
LET vm_max_detalle = 100

OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12,
	INSERT KEY F30,
	DELETE KEY F31
OPEN WINDOW w_rolp104 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_rolp104 FROM '../forms/rolf104_1'
DISPLAY FORM f_rolp104

LET vm_filas_pant = fgl_scr_size('r_detalle')

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR

LET rm_orden[2] = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 1

WHILE TRUE

	CLEAR FORM
	CALL control_display_botones()
	INITIALIZE rm_n11.* TO NULL
	LET rm_n11.n11_usuario = vg_usuario
	LET rm_n11.n11_fecing  = CURRENT
	DISPLAY BY NAME rm_n11.n11_usuario, rm_n11.n11_fecing

	CALL control_ingreso_rolt011()
	IF INT_FLAG THEN
		CLOSE WINDOW w_rolp104
		EXIT PROGRAM
	END IF

	CALL control_cargar_detalle()
	IF vm_ind_arr = 0 THEN
		CALL fgl_winmessage(vg_producto,'No existen rubros para este proceso','exclamation')
		CONTINUE WHILE
	END IF
	CALL control_ingreso_detalle()
	IF NOT INT_FLAG THEN
		CALL control_insert_rolt011()
	END IF
	

END WHILE

END FUNCTION



FUNCTION control_insert_rolt011()
DEFINE i 	SMALLINT
DEFINE r_n11 	RECORD LIKE rolt011.*

BEGIN WORK

	DELETE FROM rolt011
		WHERE n11_compania   = vg_codcia
		  AND n11_cod_liqrol = rm_n11.n11_cod_liqrol 

	FOR i = 1 TO vm_ind_arr
		IF r_detalle[i].seleccionar = 'S' THEN 
			LET r_n11.n11_compania   = vg_codcia
			LET r_n11.n11_cod_liqrol = rm_n11.n11_cod_liqrol
			LET r_n11.n11_cod_rubro  = r_detalle[i].n11_cod_rubro
			LET r_n11.n11_usuario    = vg_usuario
			LET r_n11.n11_fecing     = CURRENT
			INSERT INTO rolt011 VALUES (r_n11.*) 
		END IF
	END FOR

COMMIT WORK
CALL fgl_winmessage(vg_producto,'Proceso realizado Ok.','info')

END FUNCTION



FUNCTION control_ingreso_rolt011()
DEFINE resp 	CHAR(6)

LET INT_FLAG = 0 
INPUT BY NAME rm_n11.n11_cod_liqrol

	ON KEY(INTERRUPT)
		CALL fl_mensaje_abandonar_proceso()
			RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1 
			EXIT INPUT
		END IF
		LET INT_FLAG = 0 

	ON KEY(F2)
		IF INFIELD(n11_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING rm_n03.n03_proceso,
					  rm_n03.n03_nombre
			IF rm_n03.n03_proceso IS NOT NULL THEN
				LET rm_n11.n11_cod_liqrol = rm_n03.n03_proceso
				DISPLAY BY NAME rm_n11.n11_cod_liqrol,
						rm_n03.n03_nombre  
			END IF
		END IF
		LET INT_FLAG = 0

	AFTER FIELD n11_cod_liqrol
		IF rm_n11.n11_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n11.n11_cod_liqrol)
                        	RETURNING rm_n03.*
			IF rm_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n11_cod_liqrol
			END IF
			DISPLAY BY NAME rm_n03.n03_nombre
		ELSE
			NEXT FIELD n11_cod_liqrol
		END IF
		
END INPUT

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'Rubro'        	TO tit_col1
DISPLAY 'Nombre'       	TO tit_col2
DISPLAY 'S' 		TO tit_col3

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE query	VARCHAR(200)
DEFINE i 	SMALLINT
DEFINE liqrol	LIKE rolt011.n11_cod_liqrol

FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].* TO NULL
	CLEAR r_detalle[i].*
END FOR
INITIALIZE liqrol TO NULL

LET query = 'SELECT n09_cod_rubro, n06_nombre ',
		' FROM rolt009, rolt006 ', 
		' WHERE n09_compania  = ', vg_codcia,
		'   AND n09_cod_rubro = n06_cod_rubro',
		'   AND n06_estado    = "A" '
PREPARE cons FROM query
DECLARE q_rolt009 CURSOR FOR cons

DELETE FROM tmp_rolt011

LET i = 1
FOREACH q_rolt009 INTO r_detalle[i].n11_cod_rubro, r_detalle[i].n06_nombre 


	---- ANL. YURI ESPINOZA DEBE HACER FL_LEE DE LA ROLT011
	SELECT n11_cod_liqrol
		INTO liqrol
		FROM rolt011
		WHERE n11_compania   = vg_codcia
		  AND n11_cod_liqrol = rm_n11.n11_cod_liqrol
		  AND n11_cod_rubro  = r_detalle[i].n11_cod_rubro
	IF liqrol IS NOT NULL THEN
		LET r_detalle[i].seleccionar    = 'S'
		INITIALIZE liqrol TO NULL
	ELSE
		LET r_detalle[i].seleccionar    = 'N'
	END IF

	INSERT INTO tmp_rolt011 VALUES (r_detalle[i].*)

	LET i = i + 1
        IF i  > vm_max_detalle THEN
		EXIT FOREACH
	END IF	

END FOREACH 
LET i = i - 1

LET vm_ind_arr = i

END FUNCTION



FUNCTION control_ingreso_detalle()
DEFINE i,j,k,m		SMALLINT
DEFINE resp		CHAR(6)
DEFINE query		VARCHAR(200)

LET k = 1
WHILE TRUE

	LET query = 'SELECT * FROM tmp_rolt011 ',
		' ORDER BY ', vm_columna_1, ' ',
		      rm_orden[vm_columna_1], ', ',
		      vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE rubros FROM query
	DECLARE q_rolt011_2 CURSOR FOR rubros

	LET m = 1
	FOREACH q_rolt011_2 INTO r_detalle[m].*
		LET m = m + 1
	END FOREACH
	LET i = 1
	LET j = 1
	LET int_flag = 0

	CALL set_count(vm_ind_arr)

	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*
		BEFORE INPUT
			CALL dialog.keysetlabel('INSERT','')
			CALL dialog.keysetlabel('DELETE','')

		ON KEY(INTERRUPT)
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				LET INT_FLAG = 1
				EXIT INPUT
			END IF
			LET INT_FLAG = 0

		BEFORE ROW
			LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()    # POSICION CORRIENTE EN PANTALLA
			CALL muestra_contadores_det(i, vm_ind_arr)

		BEFORE INSERT  
			EXIT INPUT

		AFTER INPUT 
			EXIT WHILE

		ON KEY(F15)
			LET r_detalle[i].seleccionar =
			    GET_FLDBUF(r_detalle[j].seleccionar)
			LET k = 1
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F16)
			LET r_detalle[i].seleccionar = 
			    GET_FLDBUF(r_detalle[j].seleccionar)
			LET k = 2
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F17)
			LET r_detalle[i].seleccionar = 
			    GET_FLDBUF(r_detalle[j].seleccionar)
			LET k = 3
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F18)
			LET r_detalle[i].seleccionar = 
			    GET_FLDBUF(r_detalle[j].seleccionar)
			LET k = 4
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F19)
			LET r_detalle[i].seleccionar = 
			    GET_FLDBUF(r_detalle[j].seleccionar)
			LET k = 5
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F20)
			LET r_detalle[i].seleccionar = 
			    GET_FLDBUF(r_detalle[j].seleccionar)
			LET k = 6
			LET int_flag = 2
			EXIT INPUT
	END INPUT
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF

	FOR m = 1 TO arr_count()
		UPDATE tmp_rolt011 SET seleccionar = r_detalle[m].seleccionar
			WHERE n11_cod_rubro  = r_detalle[m].n11_cod_rubro
	END FOR
			 
	IF int_flag = 2 THEN
		IF k <> vm_columna_1 THEN
			LET vm_columna_2           = vm_columna_1 
			LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
			LET vm_columna_1 = k 
		END IF
		IF rm_orden[vm_columna_1] = 'ASC' THEN
			LET rm_orden[vm_columna_1] = 'DESC'
		ELSE
			LET rm_orden[vm_columna_1] = 'ASC'
		END IF
	END IF
END WHILE

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION
