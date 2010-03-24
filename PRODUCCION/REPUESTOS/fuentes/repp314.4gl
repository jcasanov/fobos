{*
 * Titulo           : repp314.4gl - Revisar proformas pendientes de facturar
 * Elaboracion      : 18-mar-2010
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp314 base modulo compañía localidad
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_cod_fact		LIKE rept019.r19_cod_tran
DEFINE vm_cod_desp		LIKE rept019.r19_cod_tran


DEFINE vm_max_rows		INTEGER

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE rm_desp ARRAY[1000] OF RECORD
	numprof			LIKE rept021.r21_numprof,
	numprev			LIKE rept023.r23_numprev,
	nomcli			LIKE rept021.r21_nomcli,
	cod_desp		LIKE rept019.r19_cod_tran,
	num_desp		LIKE rept019.r19_num_tran,
	fecing			DATE 
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp314.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 
		'Número de parámetros incorrecto', 
		'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp314'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_rep	RECORD LIKE rept000.*
DEFINE i		SMALLINT

OPEN WINDOW repw314 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM repf314_1 FROM '../forms/repf314_1'
DISPLAY FORM repf314_1
LET vm_max_rows = 1000
LET vm_cod_fact = 'FA'
LET vm_cod_desp = 'NE'

DISPLAY 'Prof'			 TO tit_col1
DISPLAY 'Prev'			 TO tit_col2
DISPLAY 'Cliente'        TO tit_col3
DISPLAY '.'  			 TO tit_col4
DISPLAY 'Desp'	    	 TO tit_col5
DISPLAY 'Fecha Desp'     TO tit_col6

FOR i = 1 TO fgl_scr_size('rm_desp')
	CLEAR rm_desp[i].*
END FOR
CALL muestra_consulta()

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i			SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE num_rows		INTEGER

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 4
LET vm_columna_2 = 3
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT r102_numprof, r118_numprev, r19_nomcli, r118_cod_desp, ',
                      ' r118_num_desp, DATE(r19_fecing) ',
				'  FROM rept118, rept019, rept102 ',
				' WHERE r118_compania  = ', vg_codcia, 
				'   AND r118_localidad = ', vg_codloc, 
				'   AND r118_cod_fact  IS NULL ',
				'   AND r118_compania  = r19_compania ', 
				'   AND r118_localidad = r19_localidad ', 
				'   AND r118_cod_desp  = r19_cod_tran ', 
				'   AND r118_num_desp  = r19_num_tran ', 
				'   AND r102_compania  = r118_compania ',
				'   AND r102_localidad = r118_localidad ',
				'   AND r102_numprev   = r118_numprev ',
				' GROUP BY 1, 2, 3, 4, 5, 6 ',
				' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
							  vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_desp[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT PROGRAM
	END IF
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_desp TO rm_desp.*
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
ERROR ' ' ATTRIBUTE(NORMAL)
                                                                                
END FUNCTION



{
FUNCTION imprimir(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran

DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp422 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', cod_tran, ' ',
	num_tran
	
RUN comando	

END FUNCTION
}



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
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
