{*
 * Titulo           : repp316.4gl - Preventas anuladas
 * Elaboracion      : 21-Junio-2011
 * Autor            : MTP
 * Formato Ejecucion: fglrun repp316 base modulo compañía localidad
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'


DEFINE vm_max_rows              INTEGER

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1     SMALLINT
DEFINE vm_columna_2     SMALLINT

DEFINE rm_desp ARRAY[1000] OF RECORD
        numprev             	  LIKE rept120.r120_numprev,
        motivo                    LIKE rept120.r120_motivo,
        usuario                   LIKE rept120.r120_usuario,
        fecing	                  LIKE rept120.r120_fecing
END RECORD



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp316.error')
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
LET vg_proceso = 'repp316'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i                SMALLINT

OPEN WINDOW repw316 AT 3,2 WITH 22 ROWS, 80 COLUMNS
        ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
                  BORDER, MESSAGE LINE LAST)
OPEN FORM repf316_1 FROM '../forms/repf316_1'
DISPLAY FORM repf316_1
LET vm_max_rows = 1000

DISPLAY 'Preventa'		TO tit_col1
DISPLAY 'Motivo'        	TO tit_col2
DISPLAY 'Usuario'       	TO tit_col3
DISPLAY 'Fecha Eliminacion'	TO tit_col4

FOR i = 1 TO fgl_scr_size('rm_desp')
        CLEAR rm_desp[i].*
END FOR

CALL muestra_consulta()

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i                SMALLINT
DEFINE query            VARCHAR(1000)
DEFINE num_rows         INTEGER

FOR i = 1 TO 10
        LET rm_orden[i] = ''
END FOR
LET vm_columna_1 = 1
LET vm_columna_2 = 4
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'

WHILE TRUE

        LET query = 'SELECT r120_numprev, r120_motivo, r120_usuario,r120_fecing ',
                                '  FROM rept120 ',
                                ' WHERE r120_compania  = ', vg_codcia,
                                '   AND r120_localidad = ', vg_codloc,
                                ' GROUP BY 1,2,3,4',
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
			DISPLAY rm_desp[i].motivo TO motivo_seleccionado
                AFTER DISPLAY
                        CONTINUE DISPLAY
                ON KEY(INTERRUPT)
                        EXIT DISPLAY
                ON KEY(F17)
                        LET i = 1
                        LET int_flag = 2
                        EXIT DISPLAY
                ON KEY(F19)
                        LET i = 3
                        LET int_flag = 2
                        EXIT DISPLAY
                ON KEY(F21)
                        LET i = 4
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

