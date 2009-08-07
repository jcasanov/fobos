------------------------------------------------------------------------------
-- Titulo           : repp427.4gl - Listado de Ubicacion de items
-- Elaboracion      : 15-MAR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp427 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_r11		RECORD LIKE rept011.*
DEFINE rm_r02		RECORD LIKE rept002.*

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT

DEFINE vm_tot_stock	SMALLINT
DEFINE vm_percha	VARCHAR(3)
DEFINE vm_percha2	VARCHAR(3)
DEFINE vm_ubicacion	VARCHAR(7)
DEFINE vm_ubicacion2	VARCHAR(7)

DEFINE expr_percha	VARCHAR(100)
DEFINE expr_ubicacion	VARCHAR(100)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp427'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 10 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf427_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(800)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD
	item		LIKE rept011.r11_item,
	descripcion	LIKE rept010.r10_nombre,
	stock		LIKE rept011.r11_stock_act,
	percha		VARCHAR(3),
	ubicacion	VARCHAR(7)
	END RECORD

LET vm_top    = 0
LET vm_left   = 15
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

WHILE TRUE
	LET vm_tot_stock  = 0
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET query = 'SELECT r11_item, r10_nombre, r11_stock_act,',
			' r11_ubicacion[1,3], r11_ubicacion[4,10]',
			' FROM rept011, rept010 ',
			'WHERE r11_compania  =',vg_codcia,
			'  AND r11_bodega    ="',rm_r11.r11_bodega,'"',
			'  AND r11_stock_act > 0',
			'  AND ',expr_percha,
			'  AND ',expr_ubicacion,
			'  AND r11_compania = r10_compania',
			'  AND r11_item     = r10_codigo',
			' ORDER BY 4, 5'

	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte
	OPEN q_reporte
	FETCH q_reporte
	IF STATUS = NOTFOUND THEN
		CLOSE q_reporte
		FREE  q_reporte
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	START REPORT report_ubicacion_items TO PIPE comando
	FOREACH q_reporte INTO r_report.* 
		OUTPUT TO REPORT report_ubicacion_items(r_report.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_ubicacion_items
END WHILE 
END FUNCTION



FUNCTION lee_parametros()

OPTIONS INPUT NO WRAP
LET int_flag = 0
INPUT BY NAME rm_r11.r11_bodega, vm_percha, vm_percha2, 
	      vm_ubicacion, vm_ubicacion2
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(r11_bodega) THEN
                     	CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T')
				RETURNING rm_r02.r02_codigo, rm_r02.r02_nombre
			IF rm_r02.r02_codigo IS NOT NULL THEN
				LET rm_r11.r11_bodega = rm_r02.r02_codigo
				DISPLAY BY NAME rm_r11.r11_bodega
				DISPLAY rm_r02.r02_nombre TO nom_bod
			END IF
		END IF
	AFTER FIELD r11_bodega
		IF rm_r11.r11_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia,rm_r11.r11_bodega)
				RETURNING rm_r02.*
			IF rm_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la bodega en la Compañía.','exclamation')
				CLEAR nom_bod
				NEXT FIELD r11_bodega
			ELSE
				LET rm_r11.r11_bodega = rm_r02.r02_codigo
				DISPLAY BY NAME rm_r11.r11_bodega
				DISPLAY rm_r02.r02_nombre TO nom_bod
			END IF
		ELSE
			CLEAR nom_bod
		END IF
	AFTER INPUT 
		LET expr_percha    = '1 = 1'
		LET expr_ubicacion = '1 = 1'
		IF vm_percha IS NULL AND vm_percha2 IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la percha inicial.','exclamation')
			NEXT FIELD vm_percha
		END IF
		IF vm_percha2 IS NULL AND vm_percha IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la percha final.','exclamation')
			NEXT FIELD vm_percha2
		END IF
		IF vm_ubicacion IS NULL AND vm_ubicacion2 IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la ubicación inicial.','exclamation')
			NEXT FIELD vm_ubicacion
		END IF
		IF vm_ubicacion2 IS NULL AND vm_ubicacion IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Debe ingresar la ubicación final.','exclamation')
			NEXT FIELD vm_ubicacion2
		END IF
		IF (vm_ubicacion IS NOT NULL OR vm_ubicacion2 IS NOT NULL) AND
		   (vm_percha IS NULL OR vm_percha2 IS NULL) 
		   THEN
			CALL fgl_winmessage(vg_producto,'Si ingresa la ubicacion debe también ingresar la percha.','exclamation')
			NEXT FIELD vm_percha
		END IF
		IF vm_percha IS NOT NULL AND
		   vm_percha2 IS NOT NULL 
		   THEN
			LET expr_percha = 
		' r11_ubicacion[1,3]  BETWEEN "',vm_percha,'"', ' AND ',
					   '"',vm_percha2,'"'
		END IF
		IF vm_ubicacion IS NOT NULL AND 
		   vm_ubicacion2 IS NOT NULL 
		   THEN
			LET expr_ubicacion =
		' r11_ubicacion[4,10]  BETWEEN "',vm_ubicacion,'"', ' AND ',
					   '"',vm_ubicacion2,'"'
		END IF
		
END INPUT

END FUNCTION



REPORT report_ubicacion_items(item, descripcion, stock, percha, ubicacion)
DEFINE	item		LIKE rept011.r11_item
DEFINE	descripcion	LIKE rept010.r10_nombre
DEFINE	stock		LIKE rept011.r11_stock_act
DEFINE	percha		VARCHAR(3)
DEFINE	ubicacion	VARCHAR(7)

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT
PAGE HEADER
	print 'E'; 
	print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	        -- Letra (12 cpi)

	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 1,
		fl_justifica_titulo('C','LISTADO DE UBICACION DE ITEMS',70)

	SKIP 1 LINES

	print '&k2S'	        -- Letra (16 cpi)

	PRINT COLUMN 1, 'Fecha de Impresión: ',
	      COLUMN 30, TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 75,'Página: ', 
	      COLUMN 88, fl_justifica_titulo('D',PAGENO,10)	USING '&&&'
	PRINT COLUMN 1, 'Bodega: ', 
	      COLUMN 30, rm_r11.r11_bodega, '  ',rm_r02.r02_nombre,
	      COLUMN 84, 'REPP427'
	PRINT COLUMN 1, 'Usuario: ',
	      COLUMN 30, vg_usuario

	PRINT '=========================================================================================='
	PRINT COLUMN 1,   'Item',
	      COLUMN 17,  'Descripción',
	      COLUMN 40,  'Stock',
	      COLUMN 48,  'Percha',
	      COLUMN 57,  'Ubicación',
	      COLUMN 68,  'N. Percha',
	      COLUMN 79,  'N. Ubicación'
	PRINT '=========================================================================================='

ON EVERY ROW

	PRINT COLUMN 1,  fl_justifica_titulo('I',item,15),
	      COLUMN 17, descripcion[1,21],
	      COLUMN 39, stock,
	      COLUMN 48, percha,
	      COLUMN 57, ubicacion,
	      COLUMN 68, '_________ ',
	      COLUMN 79, '____________'
	
	LET vm_tot_stock = stock + vm_tot_stock

ON LAST ROW
	PRINT COLUMN 39, '-----'
	PRINT COLUMN 39, vm_tot_stock

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_r11.*, rm_r02.*, vm_percha, vm_percha2,
	   vm_ubicacion, vm_ubicacion2 TO NULL

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
