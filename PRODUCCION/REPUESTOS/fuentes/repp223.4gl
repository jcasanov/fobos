{*
 * Titulo           : repp223.4gl - Revisar proformas aprobadas
 * Elaboracion      : 26-oct-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp223 base modulo compañía localidad
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE rm_prof ARRAY[1000] OF RECORD
	fecha_ini	DATE,
	r21_numprof	LIKE rept021.r21_numprof,
	r21_nomcli	LIKE rept021.r21_nomcli,
	siglas_vend	LIKE rept001.r01_iniciales,
	fecha_max	DATE,
	r21_tot_neto	LIKE rept021.r21_tot_neto
END RECORD
	
DEFINE rm_par RECORD
	r21_moneda	LIKE gent013.g13_moneda,
	tit_moneda	CHAR(20),
	estado		CHAR(1),
	fecha_ini	DATE,
	fecha_fin	DATE,
	r21_vendedor	LIKE rept001.r01_codigo,
	tit_vend	LIKE rept001.r01_nombres
	END RECORD
DEFINE vm_max_rows	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp223.error')
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
LET vg_proceso = 'repp223'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE i		SMALLINT

INITIALIZE rm_par.* TO NULL
LET rm_par.r21_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.* 
LET rm_par.tit_moneda = r_mon.g13_nombre

LET rm_par.fecha_fin = TODAY

OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/repf223_1'
DISPLAY FORM f_cons
LET vm_max_rows = 1000

DISPLAY 'Fecha Ini.'     TO tit_col1
DISPLAY '#'		 		 TO tit_col2
DISPLAY 'Cliente'        TO tit_col3
DISPLAY 'Ven'            TO tit_col4
DISPLAY 'Validez'        TO tit_col5
DISPLAY 'Valor Neto'     TO tit_col6

WHILE TRUE
	FOR i = 1 TO fgl_scr_size('rm_prof')
		CLEAR rm_prof[i].*
	END FOR
	CALL lee_parametros1()
	IF int_flag THEN
		RETURN
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL muestra_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_aux		VARCHAR(30)
DEFINE num_dec		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_r01		RECORD LIKE rept001.*

LET rm_par.estado = 'T'

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(F2)
		IF infield(r21_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.r21_moneda     = mon_aux
				LET rm_par.tit_moneda = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF infield(r21_vendedor) THEN
			CALL fl_ayuda_vendedores(vg_codcia) 
				RETURNING r_r01.r01_codigo,
					  r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN
				LET rm_par.r21_vendedor = r_r01.r01_codigo
				LET rm_par.tit_vend     = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r21_moneda
		IF rm_par.r21_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Moneda no existe', 
					'exclamation')
				NEXT FIELD r21_moneda
			END IF
			LET rm_par.tit_moneda = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_moneda
		ELSE
			LET rm_par.tit_moneda = NULL
			CLEAR tit_moneda
		END IF
	AFTER FIELD r21_vendedor
		IF rm_par.r21_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.r21_vendedor) 
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Vendedor no existe', 
					'exclamation')
				NEXT FIELD r21_vendedor
			END IF
			LET rm_par.tit_vend = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.tit_vend
		ELSE
			LET rm_par.tit_vend = NULL
			CLEAR tit_vend
		END IF
	AFTER INPUT
		IF int_flag THEN
			EXIT INPUT
		END IF
		IF rm_par.fecha_ini IS NULL OR rm_par.fecha_fin IS NULL THEN
			CALL fgl_winmessage(vg_producto, 'Debe ingresar un rango de fechas',
								'exclamation')
			CONTINUE INPUT					
		END IF
		IF rm_par.fecha_fin < rm_par.fecha_ini THEN
			CALL fgl_winmessage(vg_producto, 
				'La fecha final debe ser mayor ' || 
				'a la fecha inicial.',
				'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE i		SMALLINT
DEFINE expr_sql		VARCHAR(200)

DEFINE tot_prof		LIKE rept021.r21_tot_neto

LET int_flag = 0
CONSTRUCT expr_sql ON   r21_numprof, r21_nomcli, r21_tot_neto
				   FROM r21_numprof, r21_nomcli, r21_tot_neto
IF int_flag THEN
	RETURN
END IF
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)

CREATE TEMP TABLE temp_prof (
	fecha_ini		DATE,
	r21_numprof		INTEGER,
	r21_nomcli		VARCHAR(100),
	r01_iniciales	CHAR(3),
	r21_dias_prof	SMALLINT,
	r21_tot_neto	DECIMAL(12,2)
)

CASE rm_par.estado 
	WHEN 'A'
		CALL generar_consulta_aprobadas(expr_sql)
	WHEN 'S'
		CALL generar_consulta_sin_aprobar(expr_sql)
	WHEN 'F'
		CALL generar_consulta_facturadas(expr_sql)
	WHEN 'T'
		CALL generar_consulta_aprobadas(expr_sql)
		CALL generar_consulta_sin_aprobar(expr_sql)
		CALL generar_consulta_facturadas(expr_sql)
END CASE		

SELECT COUNT(*) INTO i FROM temp_prof
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_prof
	LET int_flag = 1
	RETURN
END IF

SELECT SUM(r21_tot_neto) INTO tot_prof FROM temp_prof
DISPLAY BY NAME tot_prof

ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION



FUNCTION generar_consulta_aprobadas(expr_sql)
DEFINE query		VARCHAR(1000)
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_vend	VARCHAR(100)

LET expr_vend = ' 1 = 1 '
IF rm_par.r21_vendedor IS NOT NULL THEN
	LET expr_vend = ' r21_vendedor = ', rm_par.r21_vendedor
END IF

LET query = 'INSERT INTO temp_prof ',
			'SELECT DATE(MIN(r23_fecing)) fecha_ini, ',
			'       r21_numprof, r21_nomcli, r01_iniciales, ',
			'       r21_dias_prof, r21_tot_neto ',
			'  FROM rept021, rept001, rept102, rept023 ',
			' WHERE r21_compania   = ', vg_codcia, 
			'   AND r21_localidad  = ', vg_codloc, 
			'   AND r21_moneda     = "', rm_par.r21_moneda, '"',
			'   AND ', expr_vend CLIPPED,  
			'   AND ', expr_sql CLIPPED,  
			'   AND r01_compania   = r21_compania', 
			'   AND r01_codigo     = r21_vendedor', 
			'   AND r102_compania  = r21_compania',
			'   AND r102_localidad = r21_localidad',
			'   AND r102_numprof   = r21_numprof',
			'   AND r23_compania   = r102_compania',
			'   AND r23_localidad  = r102_localidad',
			'   AND r23_numprev    = r102_numprev',
			'   AND r23_estado     = "P" ',
			' GROUP BY r21_numprof, r21_nomcli, ',
			' 		   r01_iniciales, r21_dias_prof, r21_tot_neto ',
			'HAVING DATE(MIN(r23_fecing)) BETWEEN "', rm_par.fecha_ini, '"', 
											' AND "', rm_par.fecha_fin, '"'

PREPARE stmt1 FROM query
EXECUTE stmt1

END FUNCTION



FUNCTION generar_consulta_sin_aprobar(expr_sql)
DEFINE query		VARCHAR(1000)
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_vend	VARCHAR(100)

LET expr_vend = ' 1 = 1 '
IF rm_par.r21_vendedor IS NOT NULL THEN
	LET expr_vend = ' r21_vendedor = ', rm_par.r21_vendedor
END IF

LET query = 'INSERT INTO temp_prof ',
			'SELECT DATE(r21_fecing), ',
			'       r21_numprof, r21_nomcli, r01_iniciales, ',
			'       r21_dias_prof, r21_tot_neto ',
			'  FROM rept021, rept001 ',
			' WHERE r21_compania   = ', vg_codcia, 
			'   AND r21_localidad  = ', vg_codloc, 
			'   AND r21_moneda     = "', rm_par.r21_moneda, '"',
			'   AND DATE(r21_fecing) BETWEEN "', rm_par.fecha_ini, '"', 
									   ' AND "', rm_par.fecha_fin, '"',
			'   AND ', expr_vend CLIPPED,  
			'   AND ', expr_sql CLIPPED,  
			'   AND NOT EXISTS (SELECT 1 FROM rept102, rept023',
							   ' WHERE r102_compania  = r21_compania',
							     ' AND r102_localidad = r21_localidad',
							     ' AND r102_numprof   = r21_numprof',
							     ' AND r23_compania   = r102_compania',
							     ' AND r23_localidad  = r102_localidad',
							     ' AND r23_numprev    = r102_numprev',
							     ' AND r23_estado     = "P")',
			'   AND r01_compania   = r21_compania', 
			'   AND r01_codigo     = r21_vendedor', 
			' GROUP BY r21_fecing, r21_numprof, r21_nomcli, ',
			' 		   r01_iniciales, r21_dias_prof, r21_tot_neto '

PREPARE stmt2 FROM query
EXECUTE stmt2

END FUNCTION



FUNCTION generar_consulta_facturadas(expr_sql)
DEFINE query		VARCHAR(1000)
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_vend	VARCHAR(100)

LET expr_vend = ' 1 = 1 '
IF rm_par.r21_vendedor IS NOT NULL THEN
	LET expr_vend = ' r21_vendedor = ', rm_par.r21_vendedor
END IF

LET query = 'INSERT INTO temp_prof ',
			'SELECT DATE(MIN(r23_fecing)) fecha_ini, ',
			'       r21_numprof, r21_nomcli, r01_iniciales, ',
			'       r21_dias_prof, r21_tot_neto ',
			'  FROM rept021, rept001, rept102, rept023 ',
			' WHERE r21_compania   = ', vg_codcia, 
			'   AND r21_localidad  = ', vg_codloc, 
			'   AND r21_moneda     = "', rm_par.r21_moneda, '"',
			'   AND ', expr_vend CLIPPED,  
			'   AND ', expr_sql CLIPPED,  
			'   AND r01_compania   = r21_compania', 
			'   AND r01_codigo     = r21_vendedor', 
			'   AND r102_compania  = r21_compania',
			'   AND r102_localidad = r21_localidad',
			'   AND r102_numprof   = r21_numprof',
			'   AND r23_compania   = r102_compania',
			'   AND r23_localidad  = r102_localidad',
			'   AND r23_numprev    = r102_numprev',
			'   AND r23_estado     = "F" ',
			' GROUP BY r21_numprof, r21_nomcli, ',
			' 		   r01_iniciales, r21_dias_prof, r21_tot_neto ',
			'HAVING DATE(MIN(r23_fecing)) BETWEEN "', rm_par.fecha_ini, '"', 
											' AND "', rm_par.fecha_fin, '"'

PREPARE stmt3 FROM query
EXECUTE stmt3

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i		SMALLINT
DEFINE query		VARCHAR(300)
DEFINE num_rows		INTEGER
DEFINE comando		VARCHAR(100)

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT fecha_ini, r21_numprof, r21_nomcli, ',
				'       r01_iniciales, fecha_ini + r21_dias_prof, ', 
				'       r21_tot_neto ',
				'  FROM temp_prof ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_prof[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_prof TO rm_prof.*
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
			IF fl_proforma_aprobada(vg_codcia,vg_codloc,rm_prof[i].r21_numprof)
			THEN
				CALL dialog.keysetlabel("F6","Ver preventas")
				CALL dialog.keysetlabel("F8","Anular preventas")
			ELSE
				CALL dialog.keysetlabel("F6","")
				CALL dialog.keysetlabel("F8","")
			END IF

			-- Verifico que de hecho tenga los permisos apropiados
			IF NOT fl_control_permiso_opcion('Eliminar') THEN
				CALL dialog.keysetlabel("F8","")
			END IF
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.keysetlabel("F5","Ver proforma")
			CALL dialog.keysetlabel("F7","Imprimir")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL ver_proforma(rm_prof[i].r21_numprof)		
			LET int_flag = 0
		ON KEY(F6)
			CALL ver_preventas(rm_prof[i].r21_numprof)		
			LET int_flag = 0
		ON KEY(F7)
			CALL imprimir(num_rows)		
			LET int_flag = 0
		ON KEY(F8)
			CALL anular_preventas(rm_prof[i].r21_numprof)
			CALL dialog.keysetlabel("F6","")
			CALL dialog.keysetlabel("F8","")
			LET int_flag = 0
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
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
DROP TABLE temp_prof
                                                                                
END FUNCTION



FUNCTION ver_proforma(numprof)
DEFINE numprof	LIKE rept021.r21_numprof
DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp220 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' ', numprof	
RUN comando	

END FUNCTION



FUNCTION ver_preventas(numprof)
DEFINE numprof	LIKE rept021.r21_numprof
DEFINE comando		CHAR(255)

LET comando = 'cd ..', vg_separador, '..', vg_separador, 'REPUESTOS', 
	vg_separador, 'fuentes', vg_separador, '; fglrun repp209 ', vg_base, 
	' ', 'RE', vg_codcia, ' ', vg_codloc, ' PROF ', numprof	
RUN comando	

END FUNCTION



FUNCTION anular_preventas(numprof)
DEFINE numprof	LIKE rept021.r21_numprof
DEFINE numprev          LIKE rept023.r23_numprev
DEFINE r_r23            RECORD LIKE rept023.*
DEFINE resp 		CHAR(6)

IF NOT fl_control_permiso_opcion('Eliminar') THEN
	CALL fgl_winmessage(vg_producto,'USUARIO NO TIENE PERMISO PARA ESTA OPCION'
				|| '. PEDIR AYUDA AL ADMINISTRADOR ',
				'stop')
	RETURN
END IF

CALL fgl_winquestion(vg_producto,
				'¿Desea anular las preventas generadas para esta proforma?', 
				'No', 'Yes|No', 'question', 1)
		RETURNING resp
IF resp = 'No' THEN
	RETURN
END IF

DECLARE q_prevs CURSOR FOR 
	SELECT r102_numprev FROM rept102
        WHERE r102_compania  = vg_codcia 
          AND r102_localidad = vg_codloc 
          AND r102_numprof   = numprof

FOREACH q_prevs INTO numprev
	INITIALIZE r_r23.* TO NULL
	CALL fl_lee_preventa_rep(vg_codcia, vg_codloc, numprev) RETURNING r_r23.*
	IF r_r23.r23_compania IS NULL OR r_r23.r23_estado <> 'P' OR
	   r_r23.r23_cod_tran IS NOT NULL THEN
		CONTINUE FOREACH
	END IF

	DELETE FROM cajt010
	 WHERE j10_compania    = vg_codcia  
	   AND j10_localidad   = vg_codloc 
	   AND j10_tipo_fuente = 'PR'
	   AND j10_num_fuente  = numprev

	DELETE FROM rept027
	 WHERE r27_compania  = vg_codcia
	   AND r27_localidad = vg_codloc
	   AND r27_numprev   = numprev

	DELETE FROM rept026
	 WHERE r26_compania  = vg_codcia
	   AND r26_localidad = vg_codloc
	   AND r26_numprev   = numprev

	DELETE FROM rept025
	 WHERE r25_compania  = vg_codcia
	   AND r25_localidad = vg_codloc
	   AND r25_numprev   = numprev

	UPDATE rept023 SET r23_estado = 'N'
	 WHERE r23_compania  = vg_codcia
	   AND r23_localidad = vg_codloc
	   AND r23_numprev   = numprev

END FOREACH
FREE q_prevs

CALL fgl_winmessage(vg_producto, 'Proceso completado OK', 'exclamation')

END FUNCTION



FUNCTION imprimir(maxelm)
DEFINE i		SMALLINT          
DEFINE maxelm		SMALLINT          
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN          
END IF

START REPORT rep_proforma TO PIPE comando 
	FOR i = 1 TO (maxelm - 1)
		OUTPUT TO REPORT rep_proforma(i)
	END FOR
FINISH REPORT rep_proforma

END FUNCTION



REPORT rep_proforma(numelm)
DEFINE numelm		SMALLINT
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO DETALLE DE PROFORMAS', 80)
		RETURNING titulo

	PRINT COLUMN 1, rg_cia.g01_razonsocial,
  	      COLUMN 120, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 124, "REPP306" 
	PRINT COLUMN 48, "** Moneda        : ", rm_par.r21_moneda,
						" ", rm_par.tit_moneda
	PRINT COLUMN 48, "** Vendedor      : ", rm_par.r21_vendedor, 
						" ", rm_par.tit_vend
	PRINT COLUMN 48, "** Fecha Inicial : ", rm_par.fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** Fecha Final   : ", rm_par.fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 112, usuario
	SKIP 1 LINES
--	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   "Fecha Ini.",
	      COLUMN 13,  "  #  ",
	      COLUMN 20,  "Cliente",
	      COLUMN 52,  "Ven",
	      COLUMN 57,  "Validez",
	      COLUMN 69, "Valor Neto"
	PRINT "------------------------------------------------------------------------------------------------------------------------"
ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,   rm_prof[numelm].fecha_ini USING "dd-mm-yyyy",
	      COLUMN 13,  rm_prof[numelm].r21_numprof USING "####&",
	      COLUMN 20,  rm_prof[numelm].r21_nomcli[1,30],
	      COLUMN 52,  rm_prof[numelm].siglas_vend,
	      COLUMN 57,  rm_prof[numelm].fecha_max USING "dd-mm-yyyy",
	      COLUMN 69,  rm_prof[numelm].r21_tot_neto USING "---,---,--&.&&" 

END REPORT



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
