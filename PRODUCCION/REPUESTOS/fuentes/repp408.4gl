------------------------------------------------------------------------------
-- Titulo           : repp408.4gl - Reporte de Liquidación de Pedidos
-- Elaboracion      : 21-MAR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun repp408 base módulo compañía localidad [num_liq]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r28		RECORD LIKE rept028.*
DEFINE rm_p01		RECORD LIKE cxpt001.*

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT
DEFINE vm_pedidos	VARCHAR(200)
DEFINE vm_aux_cont	VARCHAR(200)

DEFINE vm_num_liq	LIKE rept028.r28_numliq



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN    -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.',
			    'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vm_num_liq  = arg_val(5)
LET vg_proceso  = 'repp408'

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
OPEN FORM f_rep FROM "../forms/repf408_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(400)
DEFINE comando 		VARCHAR(100)

LET vm_top    = 0
LET vm_left   = 10
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

WHILE TRUE
	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE

		CALL fl_lee_liquidacion_rep(vg_codcia, vg_codloc,vm_num_liq)
				RETURNING rm_r28.*
		IF rm_r28.r28_numliq IS NULL THEN
			CALL fgl_winmessage(vg_producto,'No existe Liquidación en la Companía.','stop')
			EXIT PROGRAM
		END IF
	END IF

	CALL fl_control_reportes() RETURNING comando

	IF int_flag  AND num_args() = 4 THEN
		CONTINUE WHILE
	END IF

	LET query = 'SELECT * FROM rept028 ',
			'WHERE r28_compania  =',vg_codcia,
			'  AND r28_localidad =',vg_codloc,
			'  AND r28_numliq    =',rm_r28.r28_numliq

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
	START REPORT report_liquidacion_pedidos TO PIPE comando
	FOREACH q_reporte INTO rm_r28.* 
		OUTPUT TO REPORT report_liquidacion_pedidos(rm_r28.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_liquidacion_pedidos
	IF num_args() = 5 THEN
		EXIT PROGRAM
	END IF
END WHILE 

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_r28 RECORD LIKE rept028.*

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_r28.r28_numliq	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(r28_numliq) THEN
			CALL fl_ayuda_liquidacion_rep(vg_codcia, vg_codloc, 'T')
				RETURNING r_r28.r28_numliq 
			IF r_r28.r28_numliq IS NOT NULL THEN
				CALL fl_lee_liquidacion_rep(vg_codcia, 
						    vg_codloc,r_r28.r28_numliq)
					RETURNING r_r28.*
				LET rm_r28.* = r_r28.*
				CALL fl_lee_proveedor(rm_r28.r28_codprov)
					RETURNING rm_p01.*
				DISPLAY BY NAME rm_r28.r28_numliq,
						rm_r28.r28_fecing,
						rm_r28.r28_codprov
				DISPLAY rm_p01.p01_nomprov TO nom_prov
			END IF
		END IF
		LET int_flag = 0

	AFTER FIELD r28_numliq
		IF rm_r28.r28_numliq IS NOT NULL THEN
			CALL fl_lee_liquidacion_rep(vg_codcia, 
						    vg_codloc,rm_r28.r28_numliq)
				RETURNING r_r28.*
			IF r_r28.r28_numliq IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la Liquidación en la Companía.','exclamation')
				CLEAR r28_fecing, r28_codprov, nom_prov
				NEXT FIELD r28_numliq
			ELSE
				LET rm_r28.* = r_r28.*
				CALL fl_lee_proveedor(rm_r28.r28_codprov)
					RETURNING rm_p01.*
				DISPLAY BY NAME rm_r28.r28_numliq,
						rm_r28.r28_fecing,
						rm_r28.r28_codprov
				DISPLAY rm_p01.p01_nomprov TO nom_prov
			END IF
		ELSE
				CLEAR r28_fecing, r28_codprov, nom_prov
		END IF
		
END INPUT

END FUNCTION



REPORT report_liquidacion_pedidos(r_r28)
DEFINE r_r28		RECORD LIKE rept028.*
DEFINE r_r29		RECORD LIKE rept029.*
DEFINE r_r30		RECORD LIKE rept030.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE nom_rubro	LIKE gent017.g17_nombre
DEFINE tit_estado	CHAR(10)
DEFINE valor		LIKE rept030.r30_valor
DEFINE pedido 		LIKE rept029.r29_pedido
DEFINE aux_cont		LIKE rept016.r16_aux_cont

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

	IF rm_r28.r28_estado = 'A' THEN
		LET tit_estado = 'ACTIVA'
	ELSE
		LET tit_estado = 'PROCESADA'
	END IF

	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 1,
		fl_justifica_titulo('C','LIQUIDACION No '||rm_r28.r28_numliq,70)

	SKIP 1 LINES

	print '&k2S'	        -- Letra (16 cpi)

	PRINT COLUMN 1,  'Origen: ',
	      COLUMN 30, rm_r28.r28_origen,
	      COLUMN 60, 'Fecha: ', 
	      COLUMN 70, fl_justifica_titulo('D',rm_r28.r28_fecing,19)
	PRINT COLUMN 1,  'Forma de Pago: ', 
	      COLUMN 30, rm_r28.r28_forma_pago,
	      COLUMN 60, 'Estado: ',
	      COLUMN 70, tit_estado
	PRINT COLUMN 1,  'Descripción: ', 
	      COLUMN 30, rm_r28.r28_descripcion

	DECLARE q_rept029 CURSOR FOR
		SELECT r29_pedido, r16_aux_cont FROM rept029, rept016
			WHERE r29_compania  = vg_codcia
			  AND r29_localidad = vg_codloc
			  AND r29_numliq    = rm_r28.r28_numliq
                          AND r16_compania  = r29_compania
                          AND r16_localidad = r29_localidad
			  AND r16_pedido    = r29_pedido 

	INITIALIZE vm_pedidos, vm_aux_cont TO NULL
	FOREACH q_rept029 INTO pedido, aux_cont
		IF vm_pedidos IS NOT NULL THEN
			LET vm_pedidos = vm_pedidos CLIPPED || ', '|| pedido 
			LET vm_aux_cont = vm_aux_cont CLIPPED || ', '|| aux_cont
		ELSE
			LET vm_pedidos = pedido 
			LET vm_aux_cont = aux_cont 
		END IF
	END FOREACH

	PRINT COLUMN 1,  'Pedidos: ',
	      COLUMN 30, vm_pedidos
	PRINT COLUMN 1,  'Auxiliar Contable: ',
	      COLUMN 30, vm_aux_cont
	PRINT COLUMN 1,  'Usuario: ',
	      COLUMN 30, vg_usuario,
	      COLUMN 84, 'REPP408'
	PRINT COLUMN 1,  'Fecha de Impresión: ',
	      COLUMN 30, TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 60, 'Página: ', 
	      COLUMN 88, fl_justifica_titulo('D',PAGENO,10)	USING '&&&'

	PRINT '=========================================================================================='

ON EVERY ROW
	SKIP 1 LINES

	PRINT COLUMN 1,  'Permiso de Importación: ',
	      COLUMN 30, rm_r28.r28_num_pi,
	      COLUMN 60, 'FOB Fábrica: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_fob_fabrica,14)
					USING '###,###,##&.##'
	PRINT COLUMN 1,  'Guía: ',
	      COLUMN 30, rm_r28.r28_guia,
	      COLUMN 60, 'Faltante: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_faltante,14)
					USING '###,###,##&.##'
	PRINT COLUMN 1,  'Pedimento: ',
	      COLUMN 30, rm_r28.r28_pedimento,
	      COLUMN 60, 'Flete: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_flete,14)
					USING '###,###,##&.##'
	PRINT COLUMN 1,  'Fecha Llegada: ',
	      COLUMN 30, rm_r28.r28_fecha_lleg,
	      COLUMN 60, 'Otros: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_otros,14)
					USING '###,###,##&.##'
	PRINT COLUMN 1,  'Fecha de Ingreso: ',
	      COLUMN 30, rm_r28.r28_fecha_ing,
	      COLUMN 60, 'Total Cargos: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_tot_cargos,14)
					USING '###,###,##&.##'
	CALL fl_lee_moneda(rm_r28.r28_moneda)
		RETURNING r_g13.*
	PRINT COLUMN 1,  'Moneda: ',
	      COLUMN 30, rm_r28.r28_moneda,'  ', r_g13.g13_nombre,
	      COLUMN 60, 'Seguro: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_seguro,14)
					USING '###,###,##&.##'
	PRINT COLUMN 60,  'Total FOB: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_total_fob,14)
					USING '###,###,##&.##'

	SKIP 1 LINES
	PRINT COLUMN 1,  'Factor Costo: ',
	      COLUMN 30, rm_r28.r28_fact_costo,
	      COLUMN 60, 'Margen de Util: ',
	      COLUMN 77, fl_justifica_titulo('D',rm_r28.r28_margen_uti,14)
					USING '###,###,##&.##'
	SKIP 1 LINES

	PRINT COLUMN 1, 'Elaborado Por:',
	      COLUMN 30, rm_r28.r28_elaborado,
	      COLUMN 60, 'Ingresado Por: ', 
	      COLUMN 75, rm_r28.r28_usuario

	SKIP 1 LINES

	PRINT COLUMN 1, '** DETALLE DE CARGOS'
	PRINT '=========================================================================================='
	PRINT COLUMN 1,  'Rubro',
	      COLUMN 7,  'Descripción',
	      COLUMN 24, 'Moneda',
	      COLUMN 40, 'Paridad',
	      COLUMN 59, 'Valor',
	      COLUMN 76, 'Valor Mon. Liq.'
	PRINT '=========================================================================================='
	
	DECLARE q_rept030 CURSOR FOR
		SELECT rept030.*, gent017.g17_nombre FROM rept030, gent017
			WHERE r30_compania  = vg_codcia
			  AND r30_localidad = vg_codloc
			  AND r30_numliq    = rm_r28.r28_numliq
			  AND r30_codrubro  = g17_codrubro
	FOREACH q_rept030 INTO r_r30.*, nom_rubro
		LET valor =  fl_retorna_precision_valor(rm_r28.r28_moneda, 
					r_r30.r30_valor * r_r30.r30_paridad)
		PRINT COLUMN 1,  fl_justifica_titulo('I',r_r30.r30_codrubro,4),
		      COLUMN 7,  nom_rubro[1,15],
		      COLUMN 24, r_r30.r30_moneda,
		      COLUMN 30, fl_justifica_titulo('D',r_r30.r30_paridad,17)
				USING '######&.#########',
		      COLUMN 50, fl_justifica_titulo('D',r_r30.r30_valor,14)
							USING '###,###,##&.##',
		      COLUMN 77, fl_justifica_titulo('D',valor,14)
					USING '###,###,##&.##'
	END FOREACH
	

ON LAST ROW

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_r28.* TO NULL

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
