------------------------------------------------------------------------------
-- Titulo           : repp415.4gl - Impresión transferencias
-- Elaboracion      : 04-Ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun repp415 base módulo compañía localidad 
--		      tipo_tran num_tran
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_tipo_tran	LIKE rept019.r19_cod_tran
DEFINE vm_num_tran	LIKE rept019.r19_num_tran
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE rm_r02_ori	RECORD LIKE rept002.*
DEFINE rm_r02_dest	RECORD LIKE rept002.*
DEFINE rm_r01		RECORD LIKE rept001.*
DEFINE rm_r19		RECORD LIKE rept019.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp415.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 AND num_args() <> 7 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_tipo_tran = arg_val(5)
LET vm_num_tran  = arg_val(6)
LET vg_proceso   = 'repp415'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE tecla 		INTEGER
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r90		RECORD LIKE rept090.*

CALL fl_nivel_isolation()
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 11
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf415_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf415_1 FROM "../forms/repf415_1"
ELSE
	OPEN FORM f_repf415_1 FROM "../forms/repf415_1c"
END IF
DISPLAY FORM f_repf415_1
IF num_args() = 6 THEN
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, vm_tipo_tran,
						vm_num_tran)
		RETURNING rm_r19.*
ELSE
	INITIALIZE r_r90.* TO NULL
	SELECT * INTO r_r90.*
		FROM rept090
		WHERE r90_compania  = vg_codcia
		  AND r90_localidad = vg_codloc
		  AND r90_cod_tran  = vm_tipo_tran
		  AND r90_num_tran  = vm_num_tran
	IF r_r90.r90_compania IS NULL THEN
		CALL fl_mostrar_mensaje('No existe transferencia de Origen.','stop')
		CLOSE WINDOW f_repf415_1
		EXIT PROGRAM
	END IF
	CALL fl_lee_cabecera_transferencia_trans(r_r90.r90_compania,
						r_r90.r90_localidad,
						r_r90.r90_cod_tran,
						r_r90.r90_num_tran)
		RETURNING rm_r19.*
END IF
IF rm_r19.r19_num_tran IS NULL THEN
	CALL fl_mostrar_mensaje('No existe transferencia.','stop')
	CLOSE WINDOW f_repf415_1
	EXIT PROGRAM
END IF
CALL fl_lee_bodega_rep(rm_r19.r19_compania, rm_r19.r19_bodega_ori)
	RETURNING r_r02.*
DISPLAY BY NAME rm_r19.r19_num_tran, rm_r19.r19_bodega_ori, r_r02.r02_nombre,
		rm_r19.r19_bodega_dest, rm_r19.r19_referencia
CALL fl_lee_bodega_rep(rm_r19.r19_compania, rm_r19.r19_bodega_dest)
	RETURNING r_r02.*
DISPLAY r_r02.r02_nombre TO tit_nombre
MESSAGE "                                           Presione una tecla para continuar "
LET tecla = fgl_getkey()
MESSAGE "                                                                             "
CALL control_reporte()
EXIT PROGRAM

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(600)
DEFINE r_rep		RECORD
				num_lin		SMALLINT,
				r20_item	LIKE rept020.r20_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ven	LIKE rept020.r20_cant_ven,
				unidades	LIKE rept010.r10_uni_med
			END RECORD
DEFINE r_g06		RECORD LIKE gent006.*
DEFINE r_g24		RECORD LIKE gent024.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE r_r73		RECORD LIKE rept073.*
DEFINE bodega		LIKE rept002.r02_codigo

CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_ori) RETURNING rm_r02_ori.*
IF rm_r02_ori.r02_codigo IS NULL THEN
	CALL fl_mostrar_mensaje('No existe bodega origen.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_bodega_rep(vg_codcia, rm_r19.r19_bodega_dest) 
	RETURNING rm_r02_dest.*
IF rm_r02_dest.r02_codigo IS NULL THEN
	CALL fl_mostrar_mensaje('No existe bodega destino.','stop')
	EXIT PROGRAM
END IF
INITIALIZE r_g06.*, r_g24.* TO NULL
LET r_g06.g06_impresora = fgl_getenv('PRINTER_DESP')
IF rm_r02_ori.r02_area = 'T' OR rm_r02_dest.r02_area = 'T' THEN
	IF rm_r02_ori.r02_area = 'T' THEN
		LET bodega = rm_r02_dest.r02_codigo
	END IF
	IF rm_r02_dest.r02_area = 'T' THEN
		LET bodega = rm_r02_ori.r02_codigo
	END IF
	DECLARE q_g24 CURSOR FOR
		SELECT * FROM gent024
			WHERE g24_compania  = vg_codcia
			  AND g24_bodega    = bodega
			ORDER BY g24_imprime DESC
	OPEN q_g24
	FETCH q_g24 INTO r_g24.*
	CLOSE q_g24
	FREE q_g24
	IF r_g24.g24_impresora IS NOT NULL THEN
		LET r_g06.g06_impresora = r_g24.g24_impresora
	END IF
END IF
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
CALL obtener_vendedor()
IF num_args() = 6 THEN
	LET query = 'SELECT * FROM rept020 ',
			' WHERE r20_compania  = ', vg_codcia,
			'   AND r20_localidad = ', vg_codloc,
			'   AND r20_cod_tran  = "', vm_tipo_tran, '"',
			'   AND r20_num_tran  = ', vm_num_tran,
		    	' ORDER BY r20_orden '
ELSE
	LET query = 'SELECT * FROM rept092 ',
			' WHERE r92_compania  = ', vg_codcia,
			'   AND r92_localidad = ', vg_codloc,
			'   AND r92_cod_tran  = "', vm_tipo_tran, '"',
			'   AND r92_num_tran  = ', vm_num_tran,
		    	' ORDER BY r92_orden '
END IF
PREPARE cons_r20 FROM query
DECLARE q_rept020 CURSOR FOR cons_r20
OPEN q_rept020
FETCH q_rept020
IF STATUS = NOTFOUND THEN
	CLOSE q_rept020
	FREE q_rept020
	CALL fl_mensaje_consulta_sin_registros()
	EXIT PROGRAM
END IF
CLOSE q_rept020
START REPORT report_transferencia TO PIPE comando
LET r_rep.num_lin = 0
FOREACH q_rept020 INTO r_r20.*
	CALL fl_lee_item(vg_codcia, r_r20.r20_item) RETURNING r_r10.*
	CALL fl_lee_marca_rep(vg_codcia, r_r10.r10_marca)
		RETURNING r_r73.*
	CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea,
			r_r10.r10_sub_linea, r_r10.r10_cod_grupo,
			r_r10.r10_cod_clase)
		RETURNING r_r72.*
	LET r_rep.num_lin	= r_rep.num_lin + 1
	LET r_rep.r20_item	= r_r20.r20_item
	LET r_rep.desc_clase	= r_r72.r72_desc_clase
	LET r_rep.desc_marca	= r_r73.r73_desc_marca
	LET r_rep.descripcion	= r_r10.r10_nombre
	LET r_rep.cant_ven	= r_r20.r20_cant_ven
	LET r_rep.unidades	= UPSHIFT(r_r10.r10_uni_med)
	OUTPUT TO REPORT report_transferencia(r_rep.*)
END FOREACH
FINISH REPORT report_transferencia

END FUNCTION



FUNCTION obtener_vendedor()
DEFINE base		VARCHAR(30)
DEFINE query		CHAR(400)

IF num_args() = 6 THEN
	CALL fl_lee_vendedor_rep(vg_codcia, rm_r19.r19_vendedor)
		RETURNING rm_r01.*
ELSE
	CASE vg_codloc
		WHEN 1
			LET base = 'acero_gm:'
		WHEN 2
			LET base = 'acero_gc:'
		WHEN 3
			LET base = 'acero_qm:'
		WHEN 4
			LET base = 'acero_qs:'
		WHEN 5
			LET base = 'acero_qm:'
		WHEN 6
			LET base = 'sermaco_gm@segye01:'
		WHEN 7
			LET base = 'sermaco_qm@seuio01:'
	END CASE
	INITIALIZE rm_r01.* TO NULL
	LET query = 'SELECT * FROM ', base CLIPPED, 'rept001',
			' WHERE r01_compania = ', vg_codcia,
			'   AND r01_codigo   = ', rm_r19.r19_vendedor
	PREPARE cons_r01 FROM query
	DECLARE q_r01 CURSOR FOR cons_r01
	OPEN q_r01
	FETCH q_r01 INTO rm_r01.*
	CLOSE q_r01
	FREE q_r01
END IF
IF rm_r01.r01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe el vendedor.','stop')
	EXIT PROGRAM
END IF

END FUNCTION



REPORT report_transferencia(r_rep)
DEFINE r_rep		RECORD
				num_lin		SMALLINT,
				r20_item	LIKE rept020.r20_item,
				desc_clase	LIKE rept072.r72_desc_clase,
				desc_marca	LIKE rept073.r73_desc_marca,
				descripcion	LIKE rept010.r10_nombre,
				cant_ven	LIKE rept020.r20_cant_ven,
				unidades	LIKE rept010.r10_uni_med
			END RECORD
DEFINE r_loc_ori	RECORD LIKE gent002.*
DEFINE r_loc_dest	RECORD LIKE gent002.*
DEFINE usuario		VARCHAR(10,5)
DEFINE titulo		VARCHAR(80)
DEFINE nom_loc		VARCHAR(10)
DEFINE sal_ing		VARCHAR(30)
DEFINE transferencia	VARCHAR(15)
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
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_justifica_titulo('I', rm_r01.r01_user_owner, 10)
		RETURNING usuario
	CALL fl_justifica_titulo('C', rm_cia.g01_razonsocial, 80)
		RETURNING titulo
	CALL fl_lee_localidad(vg_codcia, rm_r02_ori.r02_localidad)
		RETURNING r_loc_ori.*
	CALL fl_lee_localidad(vg_codcia, rm_r02_dest.r02_localidad)
		RETURNING r_loc_dest.*
	LET transferencia = rm_r19.r19_num_tran
	LET nom_loc	  = 'SUCURSAL'
	IF r_loc_ori.g02_ciudad = r_loc_dest.g02_ciudad THEN
		LET nom_loc = 'LOCAL'
	END IF
	LET sal_ing = "SALIDA No. [", rm_r19.r19_bodega_ori, "] "
	IF r_loc_dest.g02_localidad = vg_codloc THEN
		LET sal_ing = "INGRESO No. [", rm_r19.r19_bodega_dest, "] "
	END IF
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 26,  titulo
	PRINT COLUMN 124, "PAG. ", PAGENO USING "&&&"
	PRINT COLUMN 31,  "LOCAL  : ", rm_loc.g02_nombre
	PRINT COLUMN 31,  "BODEGA : ", rm_r02_ori.r02_nombre,
	      COLUMN 114, "FECHA : ", DATE(rm_r19.r19_fecing)
					USING 'dd-mm-yyyy'
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "TRANSFERENCIA ", nom_loc,
	      COLUMN 101, sal_ing, transferencia
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------"
	IF nom_loc = 'SUCURSAL' THEN
		PRINT COLUMN 67,  "SUCURSAL       : ", r_loc_dest.g02_nombre
	ELSE
		PRINT COLUMN 01, 1 SPACES
	END IF
	PRINT COLUMN 01,  "BODEGA ORIGEN   : [", rm_r19.r19_bodega_ori, "] ",
						 rm_r02_ori.r02_nombre,
	      COLUMN 67,  "BODEGA DESTINO : [", rm_r19.r19_bodega_dest, "] ",
						rm_r02_dest.r02_nombre
	PRINT COLUMN 01,  "DIRECCION       : ", r_loc_ori.g02_direccion,
	      COLUMN 67,  "DIRECCION      : ", r_loc_dest.g02_direccion
	PRINT COLUMN 01,  "FECHA IMPRESION : ", DATE(vg_fecha) USING 'dd-mm-yyyy',
		1 SPACES, TIME,
   	      COLUMN 67,  "USUARIO        : ", usuario,
	      COLUMN 125, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 01,  "L.",
	      COLUMN 06,  "CODIGO",
	      COLUMN 15,  "DESCRIPCION",
	      COLUMN 75,  "MARCA",
	      COLUMN 109, "     CANTIDAD",
	      COLUMN 124, "MEDIDA"
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 01,  r_rep.num_lin		USING "&&&",
	      COLUMN 06,  r_rep.r20_item[1,7],
	      COLUMN 15,  r_rep.desc_clase,
	      COLUMN 75,  r_rep.desc_marca
	PRINT COLUMN 17,  r_rep.descripcion,
	      COLUMN 109, r_rep.cant_ven	USING '##,###,##&.##',
	      COLUMN 124, r_rep.unidades
	
PAGE TRAILER
	PRINT "-----------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 55,  "COMENTARIO: ", rm_r19.r19_referencia
	IF r_loc_dest.g02_localidad <> vg_codloc THEN
		PRINT COLUMN 01,  "DESPACHADO",
		      COLUMN 67,  "RECIBIDO"
		PRINT COLUMN 01,  "POR       _______________________",
				   rm_r01.r01_nombres,
		      COLUMN 67,  "POR     _______________________";
	ELSE
		PRINT COLUMN 01,  "RECIBI" 
		PRINT COLUMN 01,  "CONFORME_______________________";
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
