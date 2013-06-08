--------------------------------------------------------------------------------
-- Titulo           : talp408.4gl - ANEXO DEL REPORTE FACTURA DE TALLER
-- Elaboracion      : 09-Ene-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp408 base modulo compañía localidad [orden]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*
DEFINE rm_t00		RECORD LIKE talt000.*
DEFINE rm_z01		RECORD LIKE cxct001.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp408.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 5 AND num_args() <> 7 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base		= arg_val(1)
LET vg_modulo		= arg_val(2)
LET vg_codcia		= arg_val(3)
LET vg_codloc		= arg_val(4)
LET rm_t23.t23_orden	= arg_val(5)
LET vg_proceso		= 'talp408'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, rm_t23.t23_orden)
	RETURNING rm_t23.*
IF rm_t23.t23_compania IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe Orden de Trabajo.','stop')
	EXIT PROGRAM
END IF
IF rm_t23.t23_num_factura IS NULL AND num_args() = 5 THEN	
	CALL fl_mostrar_mensaje('Orden no ha sido Facturada.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_cliente_general(rm_t23.t23_cod_cliente) RETURNING rm_z01.*
CALL fl_lee_mecanico(vg_codcia, rm_t23.t23_cod_asesor) RETURNING rm_t03.*
IF rm_t23.t23_cod_asesor IS NULL THEN	
	CALL fl_mostrar_mensaje('No existe codigo de asesor.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_configuracion_taller(vg_codcia) RETURNING rm_t00.*
CALL control_main_reporte()

END FUNCTION



FUNCTION control_main_reporte()
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c14		RECORD LIKE ordt014.*
DEFINE query		CHAR(600)
DEFINE expr_est		VARCHAR(100)
DEFINE comando		VARCHAR(100)

INITIALIZE r_c10.*, r_c14.* TO NULL
LET expr_est = '   AND c10_estado      IN ("P", "C") '
IF num_args() > 5 THEN
	IF rm_t23.t23_orden = arg_val(7) THEN
		LET expr_est = NULL
	END IF
END IF
LET query ='SELECT * FROM ordt010 ',
		' WHERE c10_compania    = ', vg_codcia,
		'   AND c10_localidad   = ', vg_codloc,
		'   AND c10_ord_trabajo = ', rm_t23.t23_orden,
		expr_est CLIPPED,
		' ORDER BY c10_fecing '
PREPARE cons_c10 FROM query
DECLARE q_ordt010 CURSOR FOR cons_c10
OPEN q_ordt010
FETCH q_ordt010 INTO r_c10.*
CLOSE q_ordt010
DECLARE q_c14 CURSOR FOR
	SELECT ordt014.*
		FROM ordt014, ordt013
		WHERE c14_compania  = vg_codcia
		  AND c14_localidad = vg_codloc
		  AND c14_numero_oc = r_c10.c10_numero_oc
		  AND c13_compania  = c14_compania
		  AND c13_localidad = c14_localidad
		  AND c13_numero_oc = c14_numero_oc
		  AND c13_num_recep = c14_num_recep
		  AND c13_estado    = "A"
		ORDER BY c14_numero_oc, c14_secuencia
OPEN q_c14
FETCH q_c14 INTO r_c14.*
CLOSE q_c14
IF r_c14.c14_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay otros repuestos y materiales que detallar.','exclamation')
	EXIT PROGRAM
END IF
INITIALIZE r_g06.* TO NULL
LET r_g06.g06_impresora = fgl_getenv('PRINTER_DESP')
IF r_g06.g06_impresora IS NOT NULL THEN
	CALL fl_lee_impresora(r_g06.g06_impresora) RETURNING r_g06.*
	IF r_g06.g06_impresora IS NULL THEN
		CALL fl_control_reportes() RETURNING comando
		IF int_flag THEN
			RETURN
		END IF
	END IF
	LET comando = 'lpr -o raw -P ', r_g06.g06_impresora
ELSE
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		RETURN
	END IF
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
START REPORT report_factura_det TO PIPE comando
OUTPUT TO REPORT report_factura_det()
FINISH REPORT report_factura_det

END FUNCTION



REPORT report_factura_det()
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c14		RECORD LIKE ordt014.*
DEFINE orden		LIKE talt023.t23_orden
DEFINE documento	VARCHAR(60)
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE precio		DECIMAL(12,2)
DEFINE total		DECIMAL(13,2)
DEFINE total_gen	DECIMAL(14,2)
DEFINE factura		VARCHAR(15)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	3
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	--print 'E';
	--print '&l26A';	-- Indica que voy a trabajar con hojas A4
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_justifica_titulo('I', vg_usuario, 10) RETURNING usuario
--	print '&k2S' 		-- Letra condensada
	LET factura  = rm_t23.t23_num_factura
	LET orden    = rm_t23.t23_orden
	IF num_args() > 5 THEN
		LET factura  = arg_val(6)
		LET orden    = arg_val(7)
	END IF
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 27,  "ALMACEN : ", rm_loc.g02_nombre,
	      COLUMN 99,  "No. FA ", factura
	SKIP 2 LINES
	PRINT COLUMN 01,  "CLIENTE (", rm_t23.t23_cod_cliente
					USING "&&&&&", ") : ",
					rm_t23.t23_nom_cliente[1,47],
	      COLUMN 67,  "No. ORDEN TRABAJO: ", orden USING "<<<<&&"
	PRINT COLUMN 01,  "CEDULA/RUC      : ", rm_t23.t23_cedruc,
	      COLUMN 67,  "FECHA FACTURA    : ", DATE(rm_t23.t23_fecing) 
			 			USING "dd-mm-yyyy"
	PRINT COLUMN 01,  "DIRECCION       : ", rm_t23.t23_dir_cliente,
	      COLUMN 67,  "TECNICO(ASESOR)  : ", rm_t03.t03_nombres
	PRINT COLUMN 01,  "TELEFONO        : ", rm_t23.t23_tel_cliente
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 02,  "FECHA",
	      COLUMN 14,  "ORD.COMP.",
	      COLUMN 25,  "DESCRIPCION",
	      COLUMN 90,  "CANTIDAD",
	      COLUMN 102, "PRECIO UNIT.",
	      COLUMN 121, "VALOR TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES

ON EVERY ROW
	--NEED 2 LINES
	PRINT COLUMN 01,  "OTROS REPUESTOS Y MATERIALES DE ALMACEN"
	SKIP 1 LINES
	LET total_gen = 0
	FOREACH q_ordt010 INTO r_c10.*
		DECLARE q_ordt014 CURSOR FOR
			SELECT ordt014.*
				FROM ordt014, ordt013
				WHERE c14_compania  = vg_codcia
				  AND c14_localidad = vg_codloc
				  AND c14_numero_oc = r_c10.c10_numero_oc
				  AND c13_compania  = c14_compania
				  AND c13_localidad = c14_localidad
				  AND c13_numero_oc = c14_numero_oc
				  AND c13_num_recep = c14_num_recep
				  AND c13_estado    = "A"
				ORDER BY c14_numero_oc, c14_secuencia
		FOREACH q_ordt014 INTO r_c14.*
			LET total  = (r_c14.c14_cantidad * r_c14.c14_precio) -
				      r_c14.c14_val_descto
			LET total  = total + ((total * r_c10.c10_recargo) / 100)
			LET precio = total / r_c14.c14_cantidad
			PRINT COLUMN 02,  DATE(r_c10.c10_fecing)
						USING "dd-mm-yyyy",
			      COLUMN 17,  r_c14.c14_numero_oc USING "######",
		      	      COLUMN 25,  r_c14.c14_descrip,
			      COLUMN 91,  r_c14.c14_cantidad  USING '###&.##',
			      COLUMN 100, precio USING '###,###,##&.##',
			      COLUMN 118, total	 USING '###,###,##&.##'
			LET total_gen = total_gen + total
		END FOREACH
	END FOREACH
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 116, "----------------"
	PRINT COLUMN 106, "TOTAL ==> ", total_gen USING "#,###,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
