--------------------------------------------------------------------------------
-- Titulo           : cxpp413.4gl - Listado de Tesorería realizado en un período
-- Elaboracion      : 03-May-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxpp413 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 		RECORD
				moneda          LIKE gent013.g13_moneda,
				tit_mon         LIKE gent013.g13_nombre,
				fecha_ini	DATE,
				fecha_fin	DATE,
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				tipprov		LIKE gent012.g12_subtipo,
				tit_tipprov	LIKE gent012.g12_nombre,
				tipcar		LIKE gent012.g12_subtipo,
				tit_tipcar	LIKE gent012.g12_nombre
			END RECORD
DEFINE vm_fecha_ini	DATE
DEFINE vm_fin_mes	DATE
DEFINE rm_z60		RECORD LIKE cxct060.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp413.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp413'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_fecha_carga_cxc(vg_codcia, vg_codloc) RETURNING rm_z60.*
IF rm_z60.z60_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una fecha de carga para este módulo.', 'stop')
	EXIT PROGRAM
END IF
OPEN WINDOW w_imp AT 3,2 WITH 11 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_par FROM "../forms/cxpf413_1"
DISPLAY FORM f_par
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda    = rg_gen.g00_moneda_base
LET rm_par.fecha_ini = MDY(MONTH(TODAY), 01, YEAR(TODAY))
LET vm_fin_mes       = rm_par.fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET rm_par.fecha_fin = vm_fin_mes
LET vm_fecha_ini     = rm_z60.z60_fecha_carga
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i		SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
LET rm_par.tit_mon = r_g13.g13_nombre
WHILE TRUE
	CALL lee_parametros() 
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_imprimir()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g11		RECORD LIKE gent011.*
DEFINE r_g12		RECORD LIKE gent012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE fec_ini, fec_fin	DATE

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.moneda  = r_g13.g13_moneda
				LET rm_par.tit_mon = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(codprov) THEN
			CALL fl_ayuda_proveedores_localidad(vg_codcia,vg_codloc)
				RETURNING r_p01.p01_codprov,
					  r_p01.p01_nomprov
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET rm_par.codprov = r_p01.p01_codprov
				LET rm_par.nomprov = r_p01.p01_nomprov
				DISPLAY BY NAME rm_par.codprov, rm_par.nomprov
			END IF
		END IF
		IF INFIELD(tipprov) THEN
			CALL fl_ayuda_subtipo_entidad('TP') 
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre, r_g11.g11_nombre
			IF r_g12.g12_nombre IS NOT NULL THEN
				LET rm_par.tipprov     = r_g12.g12_subtipo
				LET rm_par.tit_tipprov = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.tipprov,
						rm_par.tit_tipprov
			END IF
		END IF
		IF INFIELD(tipcar) THEN
			CALL fl_ayuda_subtipo_entidad('CR') 
				RETURNING r_g12.g12_tiporeg, r_g12.g12_subtipo,
					  r_g12.g12_nombre, r_g11.g11_nombre
			IF r_g12.g12_nombre IS NOT NULL THEN
				LET rm_par.tipcar     = r_g12.g12_subtipo
				LET rm_par.tit_tipcar = r_g12.g12_nombre
				DISPLAY BY NAME rm_par.tipcar, rm_par.tit_tipcar
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('No existe moneda.', 'exclamation')
				NEXT FIELD moneda
			END IF
		ELSE
			LET rm_par.moneda = rg_gen.g00_moneda_base
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
		END IF
		LET rm_par.tit_mon = r_g13.g13_nombre 
		DISPLAY BY NAME rm_par.tit_mon
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NULL THEN
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
		IF rm_par.fecha_ini <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
		IF rm_par.fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor a la Fecha de Hoy.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NULL THEN
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
		IF rm_par.fecha_fin <= vm_fecha_ini THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser menor a la Fecha de Inicio de las TESORERIA en el FOBOS.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
		IF rm_par.fecha_fin > vm_fin_mes THEN
			CALL fl_mostrar_mensaje('La Fecha Final no puede ser mayor a la Fecha de Fin de Mes.', 'exclamation')
			NEXT FIELD fecha_fin
		END IF
	AFTER FIELD codprov
		IF rm_par.codprov IS NOT NULL THEN
			CALL fl_lee_proveedor(rm_par.codprov) RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no existe.', 'exclamation')
				NEXT FIELD codprov
			END IF
			LET rm_par.nomprov = r_p01.p01_nomprov
			DISPLAY BY NAME rm_par.nomprov
			CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc,
							r_p01.p01_codprov)
				RETURNING r_p02.*
			IF r_p02.p02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Proveedor no está activado para esta Localidad.', 'exclamation')
				NEXT FIELD codprov
			END IF
		ELSE
			LET rm_par.nomprov = NULL
			DISPLAY BY NAME rm_par.nomprov
		END IF
	AFTER FIELD tipprov
		IF rm_par.tipprov IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('TP', rm_par.tipprov)
				RETURNING r_g12.*
			IF r_g12.g12_tiporeg IS NULL THEN
				CALL fl_mostrar_mensaje('No existe tipo proveedor.', 'exclamation')
				NEXT FIELD tipprov
			END IF
			LET rm_par.tit_tipprov = r_g12.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipprov
		ELSE
			LET rm_par.tit_tipprov = NULL
			DISPLAY BY NAME rm_par.tit_tipprov
		END IF
	AFTER FIELD tipcar
		IF rm_par.tipcar IS NOT NULL THEN
			CALL fl_lee_subtipo_entidad('CR', rm_par.tipcar)
				RETURNING r_g12.*
			IF r_g12.g12_tiporeg IS NULL THEN
				CALL fl_mostrar_mensaje('No existe tipo cartera.', 'exclamation')
				NEXT FIELD tipcar
			END IF
			LET rm_par.tit_tipcar = r_g12.g12_nombre 
			DISPLAY BY NAME rm_par.tit_tipcar
		ELSE
			LET rm_par.tit_tipcar = NULL
			DISPLAY BY NAME rm_par.tit_tipcar
		END IF
	AFTER INPUT 
		IF rm_par.codprov IS NOT NULL THEN
			LET rm_par.tipprov     = NULL
			LET rm_par.tit_tipprov = NULL
			DISPLAY BY NAME rm_par.tipprov, rm_par.tit_tipprov
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser mayor que la Fecha Final.', 'exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_aux		RECORD
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				tipo_doc	LIKE cxpt020.p20_tipo_doc,
				num_doc		LIKE cxpt020.p20_num_doc,
				div_doc		LIKE cxpt020.p20_dividendo,
				tipo_trn	LIKE cxpt022.p22_tipo_trn,
				num_trn		LIKE cxpt022.p22_num_trn,
				localidad	LIKE cxpt022.p22_localidad,
				fec_emi		LIKE cxpt020.p20_fecha_emi,
				fec_vcto	LIKE cxpt020.p20_fecha_vcto,
				fec_pago	LIKE cxpt022.p22_fecha_emi,
				dias_dif	INTEGER,
				val_doc		DECIMAL(12,2),
				val_tes		DECIMAL(12,2)
			END RECORD
DEFINE documento	VARCHAR(30)
DEFINE movimient	VARCHAR(15)
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(4000)
DEFINE expr1, expr2	VARCHAR(100)
DEFINE expr3, expr4	VARCHAR(100)
DEFINE expr5, expr6	VARCHAR(100)
DEFINE expr7, expr9	VARCHAR(100)
DEFINE expr8		VARCHAR(250)
DEFINE expr10, expr11	VARCHAR(100)
DEFINE tabl1		VARCHAR(10)
DEFINE cuantos		INTEGER
DEFINE fecing		LIKE cxpt022.p22_fecing

ERROR "Procesando documentos deudores . . . espere por favor." ATTRIBUTE(NORMAL)
INITIALIZE expr1, expr2, expr3, expr4, expr5, expr6, expr7, expr8, expr9,
		expr10, expr11, tabl1 TO NULL
LET expr1 = '   AND p22_fecha_emi    BETWEEN "', rm_par.fecha_ini,
				      '" AND "', rm_par.fecha_fin, '"'
IF rm_par.codprov IS NOT NULL THEN
	LET expr2 = '   AND p20_codprov       = ', rm_par.codprov
END IF
IF rm_par.tipprov IS NOT NULL THEN
	LET expr3 = '   AND p01_tipo_prov    = ', rm_par.tipprov
END IF
IF rm_par.tipcar IS NOT NULL THEN
	LET expr4 = '   AND p20_cartera      = ', rm_par.tipcar
END IF
LET query = 'SELECT * FROM cxpt020 ',
		' WHERE p20_compania     = ', vg_codcia,
		'   AND p20_localidad    = ', vg_codloc,
			expr2 CLIPPED,
		'   AND p20_moneda       = "', rm_par.moneda, '"',
			expr4 CLIPPED,
		' INTO TEMP tmp_p20 '
PREPARE cons_p20 FROM query
EXECUTE cons_p20
LET query = 'SELECT p20_compania, p20_localidad, p20_codprov, p01_nomprov,',
			' p20_tipo_doc, p20_num_doc, p20_dividendo,',
			' p20_fecha_emi, p20_fecha_vcto,',
			' (p20_valor_cap + p20_valor_int) valor_doc, ',
			' (p20_saldo_cap + p20_saldo_int) saldo_doc ',
		' FROM tmp_p20, cxpt001 ',
		' WHERE p01_codprov = p20_codprov ',
			expr3 CLIPPED,
		' INTO TEMP tmp_doc '
PREPARE stmnt1 FROM query
EXECUTE stmnt1
DROP TABLE tmp_p20
SELECT COUNT(*) INTO cuantos FROM tmp_doc 
ERROR ' '
IF cuantos = 0 THEN
	DROP TABLE tmp_doc
	CALL fl_mostrar_mensaje('No existen documentos con saldo para este criterio de búsqueda.', 'exclamation')
	RETURN
END IF
LET query = 'SELECT p20_codprov, p01_nomprov, p20_tipo_doc, p20_num_doc,',
			' p20_dividendo, p22_tipo_trn, p22_num_trn,',
			' p22_localidad, p20_fecha_emi, p20_fecha_vcto,',
			' p22_fecha_emi,',
			' (p22_fecha_emi - p20_fecha_vcto) fecha, valor_doc,',
			' (p23_valor_cap + p23_valor_int) valor_mov,',
			' p22_fecing, saldo_doc ',
		' FROM tmp_doc, cxpt023, cxpt022 ',
		' WHERE p23_compania     = p20_compania ',
		'   AND p23_localidad    = p20_localidad ',
		'   AND p23_codprov      = p20_codprov ',
		'   AND p23_tipo_doc     = p20_tipo_doc ',
		'   AND p23_num_doc      = p20_num_doc ',
		'   AND p23_div_doc      = p20_dividendo ',
		'   AND p22_compania     = p23_compania ',
		'   AND p22_localidad    = p23_localidad ',
		'   AND p22_codprov      = p23_codprov ',
		'   AND p22_tipo_trn     = p23_tipo_trn ',
		'   AND p22_num_trn      = p23_num_trn ',
			expr1  CLIPPED,
		' INTO TEMP tmp_mov '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
CALL control_generar_archivo()
LET query = 'SELECT * FROM tmp_mov ',
		' ORDER BY p22_fecing, p01_nomprov, p20_tipo_doc,',
			' p20_num_doc, p20_dividendo '
PREPARE cons_report FROM query
DECLARE q_report CURSOR FOR cons_report
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	DROP TABLE tmp_doc
	RETURN
END IF
START REPORT report_list_tesoreria TO PIPE comando
LET cuantos = 0
FOREACH q_report INTO r_aux.*, fecing
	LET documento = r_aux.tipo_doc CLIPPED, '-',
			r_aux.num_doc CLIPPED, '-',
			r_aux.div_doc USING "&&"
	LET movimient = r_aux.tipo_trn CLIPPED, '-',
			r_aux.num_trn USING "<<<<<&&"
	OUTPUT TO REPORT report_list_tesoreria(r_aux.codprov, r_aux.nomprov,
						documento, movimient,
						r_aux.localidad, r_aux.fec_emi,
						r_aux.fec_vcto, r_aux.fec_pago,
						r_aux.dias_dif,	r_aux.val_doc,
						r_aux.val_tes)
	LET cuantos   = 1
END FOREACH
FINISH REPORT report_list_tesoreria
DROP TABLE tmp_doc
DROP TABLE tmp_mov
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
END IF

END FUNCTION



REPORT report_list_tesoreria(r_rep)
DEFINE r_rep		RECORD
				codprov		LIKE cxpt001.p01_codprov,
				nomprov		LIKE cxpt001.p01_nomprov,
				documento	VARCHAR(30),
				movimient	VARCHAR(15),
				localidad	LIKE cxpt022.p22_localidad,
				fec_emi		LIKE cxpt020.p20_fecha_emi,
				fec_vcto	LIKE cxpt020.p20_fecha_vcto,
				fec_pago	LIKE cxpt022.p22_fecha_emi,
				dias_dif	INTEGER,
				val_doc		DECIMAL(12,2),
				val_tes		DECIMAL(12,2)
			END RECORD
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE tipo		LIKE cxpt022.p22_tipo_trn
DEFINE tipo_nom		LIKE cxpt004.p04_nombre
DEFINE total_doc	DECIMAL(14,2)
DEFINE total_mov	DECIMAL(14,2)
DEFINE total_trn	INTEGER
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	160
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo  = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 001, r_g01.g01_razonsocial,
  	      COLUMN 150, "PAGINA: ", PAGENO USING '&&&'
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 062, "<< LISTADO DE TESORERIA REALIZADA >>",
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 015, "** MONEDA            : ", rm_par.moneda,
		" ", rm_par.tit_mon,
	      COLUMN 095, "TESORERIA REALIZADA DEL ",
		rm_par.fecha_ini USING 'dd-mm-yyyy', " AL ",
		rm_par.fecha_fin USING 'dd-mm-yyyy'
	IF rm_par.codprov IS NOT NULL THEN
		PRINT COLUMN 015, "** PROVEEDOR         : ",
			rm_par.codprov USING '<<<<&&', " ",
			rm_par.nomprov CLIPPED
	END IF
	IF rm_par.tipprov IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO PROVEEDOR    : ",
			rm_par.tipprov USING '<<&&', " ", rm_par.tit_tipprov
	END IF
	IF rm_par.tipcar IS NOT NULL THEN
		PRINT COLUMN 015, "** TIPO CARTERA      : ",
			rm_par.tipcar USING '<<&&', " ", rm_par.tit_tipcar
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 142, usuario
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 019, "P R O V E E D O R E S",
	      COLUMN 052, "DOCUMENTOS",
	      COLUMN 078, "MOVIMIENTOS",
	      COLUMN 096, "LC",
	      COLUMN 100, "FECHA EMI.",
	      COLUMN 111, "FEC. VCTO.",
	      COLUMN 122, " FEC. PAGO",
	      COLUMN 133, "DIAS",
	      COLUMN 138, " VALOR DOC.",
	      COLUMN 150, " VALOR COB."
	PRINT "----------------------------------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_rep.codprov		USING "####&&",
	      COLUMN 008, r_rep.nomprov[1, 42]	CLIPPED,
	      COLUMN 052, r_rep.documento	CLIPPED,
	      COLUMN 078, r_rep.movimient	CLIPPED,
	      COLUMN 096, r_rep.localidad	USING "&&",
	      COLUMN 100, r_rep.fec_emi		USING "dd-mm-yyyy",
	      COLUMN 111, r_rep.fec_vcto	USING "dd-mm-yyyy",
	      COLUMN 122, r_rep.fec_pago	USING "dd-mm-yyyy",
	      COLUMN 133, r_rep.dias_dif	USING "---&",
	      COLUMN 138, r_rep.val_doc		USING "----,--&.##",
	      COLUMN 150, r_rep.val_tes		USING "----,--&.##"
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 138, "-----------",
	      COLUMN 150, "-----------"
	PRINT COLUMN 125, "TOTALES ==>  ",
	      COLUMN 138, SUM(r_rep.val_doc)		USING "----,--&.##",
	      COLUMN 150, SUM(r_rep.val_tes)		USING "----,--&.##"
	SKIP 2 LINES
	DECLARE q_totales CURSOR FOR
		SELECT p22_tipo_trn, p04_nombre, NVL(SUM(valor_doc), 0),
			NVL(SUM(valor_mov), 0), COUNT(*)
			FROM tmp_mov, cxpt004
			WHERE p04_tipo_doc = p22_tipo_trn
			GROUP BY 1, 2
			ORDER BY 1
	FOREACH q_totales INTO tipo, tipo_nom, total_doc, total_mov, total_trn
		PRINT COLUMN 005, "TOTAL DOCUMENTOS  ==> ",
			total_doc USING "----,--&.##",
		      COLUMN 045, "TOTAL ", tipo CLIPPED, " - ",
			tipo_nom CLIPPED,
		      COLUMN 071, " (", total_trn USING "<<<&&", ") ==> ",
			total_mov USING "----,--&.##"
	END FOREACH
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION control_generar_archivo()
DEFINE mensaje		VARCHAR(200)
DEFINE resp		CHAR(6)

LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar este listado en archivo ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
SELECT p23_localidad, p23_codprov, p23_tipo_doc, p23_num_doc, p23_div_doc,
	NVL(SUM(p23_valor_cap + p23_valor_int), 0) valor_pag
	FROM cxpt022, cxpt023
	WHERE p22_compania      = vg_codcia
	  AND p22_localidad     = vg_codloc
	  AND p22_tipo_trn     <> "AJ"
	  AND DATE(p22_fecing) <= rm_par.fecha_fin
	  AND p23_compania      = p22_compania
	  AND p23_localidad     = p22_localidad
	  AND p23_codprov       = p22_codprov
	  AND p23_tipo_trn      = p22_tipo_trn
	  AND p23_num_trn       = p22_num_trn
	GROUP BY 1, 2, 3, 4, 5
	INTO TEMP t1
UNLOAD TO "../../../tmp/cxpp413.unl"
	SELECT p20_codprov, p01_nomprov, p20_tipo_doc, p20_num_doc,
		p20_dividendo, p22_tipo_trn, p22_num_trn, p22_localidad,
		p20_fecha_emi, p20_fecha_vcto, p22_fecha_emi, fecha, valor_doc,
		valor_mov, saldo_doc, NVL(valor_pag, 0) valor_pag
		FROM tmp_mov, OUTER t1
		WHERE p23_localidad = p22_localidad
		  AND p23_codprov   = p20_codprov
		  AND p23_tipo_doc  = p20_tipo_doc
		  AND p23_num_doc   = p20_num_doc
		  AND p23_div_doc   = p20_dividendo
		ORDER BY p01_nomprov, p20_fecha_emi, p20_tipo_doc, p20_num_doc,
			p20_dividendo
RUN "mv ../../../tmp/cxpp413.unl $HOME/tmp/"
LET mensaje = 'Archivo Generado en ', FGL_GETENV("HOME"), '/tmp/cxpp413.unl',
		' OK.'
DROP TABLE t1
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION
