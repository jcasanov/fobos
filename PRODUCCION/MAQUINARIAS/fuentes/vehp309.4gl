------------------------------------------------------------------------------
-- Titulo           : vehp309.4gl - Consulta de Liquidacion de vehiculos
-- Elaboracion      : 20-feb-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun vehp309 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)

DEFINE rm_v36		RECORD LIKE veht036.*

DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT
DEFINE vm_filas_pant    SMALLINT
DEFINE vm_cod_tran	LIKE veht030.v30_cod_tran

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE r_detalle	ARRAY [1000] OF RECORD
				v36_numliq	LIKE veht036.v36_numliq,
				v36_fecha_ing	LIKE veht036.v36_fecha_ing,
				p01_nomprov	LIKE cxpt001.p01_nomprov,
				v36_fob_fabrica LIKE veht036.v36_fob_fabrica,
				v36_total_fob	LIKE veht036.v36_total_fob
			END RECORD


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto',
			    'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'vehp309'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i 	SMALLINT

CALL fl_nivel_isolation()

LET vm_max_det    = 1000
LET vm_filas_pant = fgl_scr_size('r_detalle')

OPEN WINDOW w_vehp309 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT NO WRAP,
	ACCEPT KEY	F12
OPEN FORM f_vehp309 FROM "../forms/vehf309_1"
DISPLAY FORM f_vehp309

LET vm_num_det = 0
INITIALIZE rm_v36.* TO NULL

WHILE TRUE
	FOR i = 1 TO vm_filas_pant
		INITIALIZE r_detalle[i].* TO NULL
		CLEAR r_detalle[i].*
	END FOR
	CLEAR FORM 
	DISPLAY "" AT 20, 4
	DISPLAY '0', " de ", '0' AT 20, 4
	CALL control_display_botones()

	CALL control_construct()
	IF vm_num_det = 0 THEN
		CALL fgl_winmessage(vg_producto,'No se encontraron registros con el criterio indicado.','exclamation')
		CONTINUE WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION control_display_botones()

DISPLAY 'No'       		TO tit_col1
DISPLAY 'Fecha Cierre'		TO tit_col2
DISPLAY 'Proveedor'    		TO tit_col3
DISPLAY 'Costo FOB'   		TO tit_col4
DISPLAY 'Total'		     	TO tit_col5

END FUNCTION



FUNCTION control_construct()
DEFINE query         	VARCHAR(500)
DEFINE expr_sql        	VARCHAR(500)
DEFINE i,j,col		SMALLINT
DEFINE command_run	VARCHAR(300)

        LET int_flag = 0
        CONSTRUCT BY NAME expr_sql 
		ON v36_numliq, v36_fecha_ing, p01_nomprov, v36_fob_fabrica,
		   v36_total_fob

		ON KEY(INTERRUPT)
			IF NOT FIELD_TOUCHED(v36_fecha_ing, v36_numliq,
					     p01_nomprov,   v36_total_fob,
					     v36_fob_fabrica)
			   THEN
				EXIT PROGRAM
			ELSE
				LET INT_FLAG = 1
				RETURN
			END IF

	END CONSTRUCT

LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1]  = 'ASC'
INITIALIZE col TO NULL

WHILE TRUE

 	LET query = 'SELECT v36_numliq, v36_fecha_ing, p01_nomprov, ', 
			' v36_fob_fabrica, v36_total_fob ',
			'  FROM veht036, veht034, cxpt001 ',
			' WHERE v36_compania  = ',vg_codcia,
			'   AND v36_localidad = ',vg_codloc,
			'   AND v36_estado    = "P" ',
			'   AND v34_compania  = v36_compania ',
			'   AND v34_localidad = v36_localidad ',
			'   AND v34_pedido    = v36_pedido ',
			'   AND p01_codprov   = v34_proveedor ',
			'   AND ', expr_sql CLIPPED, 
    			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
                           ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]

	PREPARE consulta FROM query

	DECLARE q_consulta CURSOR FOR consulta

	LET i = 1
	FOREACH q_consulta INTO r_detalle[i].*
		LET i = i + 1
		IF i > vm_max_det THEN
			EXIT FOREACH
		END IF
	END FOREACH

	LET vm_num_det = i - 1
	IF vm_num_det = 0 THEN
		LET INT_FLAG = 1
		RETURN
	END IF

	CALL set_count(vm_num_det)
	DISPLAY ARRAY r_detalle TO r_detalle.*

		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')

		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i)

		AFTER DISPLAY 
			CONTINUE DISPLAY

		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY

		ON KEY(F5)
			LET command_run = 'cd ..', vg_separador, '..',
				   vg_separador, 
		    		  'VEHICULOS', vg_separador, 'fuentes', 
				   vg_separador, '; fglrun vehp212 ', vg_base,
				  ' ', vg_modulo, ' ', vg_codcia, ' ',vg_codloc,
				  ' ', r_detalle[i].v36_numliq
			RUN command_run
			LET int_flag = 0
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

	END DISPLAY
	IF int_flag = 1 THEN
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

END FUNCTION



FUNCTION muestra_contadores_det(i)
DEFINE i           SMALLINT

DISPLAY "" AT 20, 4
DISPLAY i, " de ", vm_num_det AT 20,4

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEn
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
