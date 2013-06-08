------------------------------------------------------------------------------
-- Titulo           : repp406.4gl - Listado de pedidos
-- Elaboracion      : 28-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp406 base módulo compañía localidad [pedido]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_rep		RECORD LIKE rept016.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE total_fob	DECIMAL(14,4)
DEFINE total_peso	DECIMAL(9,3)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp406.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN   -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp406'
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

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 6
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mas AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rep FROM "../forms/repf406_1"
ELSE
	OPEN FORM f_rep FROM "../forms/repf406_1c"
END IF
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		CHAR(1200)
DEFINE comando		VARCHAR(100)
DEFINE r_report		RECORD
				item		LIKE rept010.r10_codigo,
				cant		LIKE rept017.r17_cantped,
				fob		LIKE rept017.r17_fob,
				orden		LIKE rept017.r17_orden,
				descripcion	LIKE rept010.r10_nombre,
				peso		LIKE rept010.r10_peso	
			END RECORD

WHILE TRUE
	IF num_args() = 4 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_rep.r16_pedido = arg_val(5)
		CALL fl_lee_pedido_rep(vg_codcia, vg_codloc, rm_rep.r16_pedido)
			RETURNING rm_rep.*
		IF rm_rep.r16_pedido IS NULL THEN
			CALL fl_mostrar_mensaje('No existe Pedido en la Compañía.','stop')
			EXIT PROGRAM
		END IF
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		IF num_args() = 4 THEN
			CONTINUE WHILE
		ELSE
			EXIT WHILE
		END IF
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	LET total_fob  = 0
	LET total_peso = 0
	LET query = 'SELECT r17_item, r17_cantped, r17_fob, r17_orden,', 
			' r10_nombre, r10_peso',
			' FROM rept017, rept010 ',
			'WHERE r17_compania  = ', vg_codcia,
			'  AND r17_localidad = ', vg_codloc,
			'  AND r17_pedido    = "', rm_rep.r16_pedido, '"',
			'  AND r17_compania  = r10_compania ',
			'  AND r17_item      = r10_codigo ',
			' ORDER BY r17_orden '
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		IF num_args() = 5 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT rep_pedidos TO PIPE comando
	FOREACH q_deto INTO r_report.*
		OUTPUT TO REPORT rep_pedidos(r_report.*)
	END FOREACH
	FINISH REPORT rep_pedidos
	IF num_args() = 5 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_rep		RECORD LIKE rept016.*
DEFINE codpe_aux	LIKE rept016.r16_pedido

OPTIONS INPUT NO WRAP
INITIALIZE r_rep.*, codpe_aux TO NULL
LET int_flag = 0
INPUT BY NAME rm_rep.r16_pedido
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r16_pedido) THEN
			CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc, 'T','T')
				RETURNING codpe_aux
			OPTIONS INPUT NO WRAP
			LET int_flag = 0
			IF codpe_aux IS NOT NULL THEN
				LET rm_rep.r16_pedido = codpe_aux
				DISPLAY BY NAME rm_rep.r16_pedido
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD r16_pedido
		IF rm_rep.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia,vg_codloc,
						rm_rep.r16_pedido)
				RETURNING r_rep.*
			IF r_rep.r16_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Pedido no existe.','exclamation')
				NEXT FIELD r16_pedido
			END IF
			DISPLAY BY NAME r_rep.r16_pedido
			LET rm_rep.* = r_rep.*
		END IF
END INPUT

END FUNCTION



REPORT rep_pedidos(item, cant, fob, orden, descripcion, peso)
DEFINE item		LIKE rept010.r10_codigo
DEFINE cant		LIKE rept017.r17_cantped
DEFINE fob		LIKE rept017.r17_fob
DEFINE orden		LIKE rept017.r17_orden
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE peso		LIKE rept010.r10_peso	
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE r_pro		RECORD LIKE cxpt001.*
DEFINE tipo_des		VARCHAR(10)
DEFINE estado		VARCHAR(10)
DEFINE proveedor	VARCHAR(50)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	--print 'E'; --print '&l26A';  -- Indica que voy a trabajar con hojas A4
	--print '&k4S'	                -- Letra condensada (12 cpi)
	LET modulo  = "MODULO: INVENTARIO"
	LET long    = LENGTH(modulo)
	LET usuario = 'USUARIO: ', vg_usuario
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE PEDIDOS', 80)
		RETURNING titulo
	--LET titulo = modulo, titulo
	IF rm_rep.r16_tipo = 'E' THEN
		LET tipo_des = 'EMERGENCIA'
	ELSE
		LET tipo_des = 'SUGERIDO'
	END IF
	CALL fl_lee_proveedor(rm_rep.r16_proveedor) RETURNING r_pro.*
	--CALL retorna_estado(rm_rep.r16_estado) RETURNING estado
	LET estado = retorna_estado(rm_rep.r16_estado)
	LET proveedor = rm_rep.r16_proveedor, ' ', r_pro.p01_nomprov
	CALL fl_justifica_titulo('I', proveedor, 50) RETURNING proveedor
	SKIP 2 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01,  rm_cia.g01_razonsocial,
	      COLUMN 122, 'PAGINA: ', PAGENO USING '&&&'
	PRINT COLUMN 01,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	--print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 28, "** PEDIDO        : ", rm_rep.r16_pedido
	PRINT COLUMN 28, "** TIPO DE PEDIDO: ", rm_rep.r16_tipo, " ", tipo_des
	PRINT COLUMN 28, "** ESTADO        : ", rm_rep.r16_estado, " ", estado
	PRINT COLUMN 28, "** PROVEEDOR     : ", proveedor
	PRINT COLUMN 28, "** FECHA DE ENVÍO: ", rm_rep.r16_fec_envio
						USING "dd-mm-yyyy"
	PRINT COLUMN 28, "** REFERENCIA    : ", rm_rep.r16_referencia
	PRINT COLUMN 01, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 113, usuario
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "ITEM",
	      COLUMN 010, "DESCRIPCIÓN",
	      COLUMN 067, "  CANTIDAD",
	      COLUMN 078, "PESO UNIT.",
	      COLUMN 089, "   FOB UNITARIO",
	      COLUMN 105, " PESO TOTAL",
	      COLUMN 117, "       FOB TOTAL"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, item[1,7]		CLIPPED,
	      COLUMN 010, descripcion[1,56]	CLIPPED,
	      COLUMN 067, cant 			USING "###,##&.##",
	      COLUMN 078, peso    		USING "##,##&.###",
	      COLUMN 089, fob    		USING "##,###,##&.####",
	      COLUMN 105, cant * peso		USING "###,##&.###",
	      COLUMN 117, cant * fob		USING "###,###,##&.####"
	LET total_peso = total_peso + cant * peso
	LET total_fob  = total_fob  + cant * fob
	
ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 105, "-----------",
	      COLUMN 117, "----------------"
	PRINT COLUMN 092, "TOTALES ==>  ",
	      COLUMN 105, total_peso		USING "###,##&.###",
	      COLUMN 117, total_fob		USING "###,###,##&.####";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION borrar_cabecera()

CLEAR r16_pedido
INITIALIZE rm_rep.* TO NULL

END FUNCTION



FUNCTION retorna_estado(estado)
DEFINE estado		LIKE rept016.r16_estado
                                                                                
IF estado = 'A' THEN
        RETURN 'ACTIVO'
END IF
IF estado = 'C' THEN
        RETURN 'CONFIRMADO'
END IF
IF estado = 'R' THEN
        RETURN 'RECIBIDO'
END IF
IF estado = 'L' THEN
        RETURN 'LIQUIDADO'
END IF
IF estado = 'P' THEN
        RETURN 'PROCESADO'
END IF

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
