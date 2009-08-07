------------------------------------------------------------------------------
-- Titulo           : repp407.4gl - Listado recepción de pedidos
-- Elaboracion      : 28-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp407 base módulo compañía [pedido]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_rep		RECORD LIKE rept016.*
DEFINE rm_cia		RECORD LIKE gent001.*

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp407'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 06 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf407_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(1000)
DEFINE r_rep		RECORD LIKE rept016.*
DEFINE r_rep2		RECORD LIKE rept017.*
DEFINE nombre		LIKE rept010.r10_nombre
DEFINE valor_fob	DECIMAL(11,2)
DEFINE cantpend		SMALLINT
DEFINE total_fob	DECIMAL(11,2)
DEFINE comando		VARCHAR(100)

WHILE TRUE
	IF num_args() = 3 THEN
		CALL lee_parametros()
		IF int_flag THEN
			EXIT WHILE
		END IF
	ELSE
		LET rm_rep.r16_pedido = arg_val(4)
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		IF num_args() = 3 THEN
			CONTINUE WHILE
		ELSE
			EXIT WHILE
		END IF
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	LET total_fob  = 0
	LET query = 'SELECT rept016.*, rept017.*, r10_nombre, ',
			'r17_cantped * r17_fob, r17_cantped - r17_cantrec ',
			'FROM rept016, rept017, rept010 ',
			'WHERE r16_compania  = ', vg_codcia,
			'  AND r16_localidad = ', vg_codloc,
			'  AND r16_pedido    = "', rm_rep.r16_pedido, '"',
			'  AND r17_compania  = r16_compania ',
			'  AND r17_localidad = r16_localidad ',
			'  AND r17_pedido    = r16_pedido ',
			'  AND r17_estado    = "R" ',
			'  AND r17_compania  = r10_compania ',
			'  AND r17_item      = r10_codigo ',
			'  AND r17_cantrec   > 0 ',
			' ORDER BY r17_orden'
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		IF num_args() = 4 THEN
			EXIT WHILE
		END IF
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT rep_pedidos TO PIPE comando
	FOREACH q_deto INTO r_rep.*, r_rep2.*, nombre, valor_fob, cantpend
		LET total_fob = total_fob + valor_fob
		OUTPUT TO REPORT rep_pedidos(r_rep.*, r_rep2.*, nombre,
					valor_fob, cantpend, total_fob)
	END FOREACH
	FINISH REPORT rep_pedidos
	IF num_args() = 4 THEN
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
	ON KEY(F2)
		IF infield(r16_pedido) THEN
			CALL fl_ayuda_pedidos_rep(vg_codcia, vg_codloc, 'R','T')
				RETURNING codpe_aux
			OPTIONS INPUT NO WRAP
			LET int_flag = 0
			IF codpe_aux IS NOT NULL THEN
				LET rm_rep.r16_pedido = codpe_aux
				DISPLAY BY NAME rm_rep.r16_pedido
			END IF
		END IF
	AFTER FIELD r16_pedido
		IF rm_rep.r16_pedido IS NOT NULL THEN
			CALL fl_lee_pedido_rep(vg_codcia,vg_codloc,
						rm_rep.r16_pedido)
				RETURNING r_rep.*
			IF r_rep.r16_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Pedido no existe.','exclamation')
				NEXT FIELD r16_pedido
			END IF
			DISPLAY BY NAME r_rep.r16_pedido
			IF r_rep.r16_estado <> 'R' THEN
				CALL fgl_winmessage(vg_producto,'Pedido no está recibido.','exclamation')
				NEXT FIELD r16_pedido
			END IF
		END IF
END INPUT

END FUNCTION



REPORT rep_pedidos(r_rep, r_rep2, nombre, valor_fob, cantpend, total_fob)
DEFINE r_rep		RECORD LIKE rept016.*
DEFINE r_rep2		RECORD LIKE rept017.*
DEFINE nombre		LIKE rept010.r10_nombre
DEFINE valor_fob	DECIMAL(11,2)
DEFINE total_fob	DECIMAL(11,2)
DEFINE cantpend		SMALLINT
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE r_pro		RECORD LIKE cxpt001.*
DEFINE tipo_des		VARCHAR(10)
DEFINE estado		VARCHAR(10)
DEFINE proveedor	VARCHAR(50)

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO RECEPCION DE PEDIDOS', 80)
		RETURNING titulo
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
	LET titulo = modulo, titulo
	IF r_rep.r16_tipo = 'E' THEN
		LET tipo_des = 'EMERGENCIA'
	ELSE
		LET tipo_des = 'SUGERIDO'
	END IF
	CALL fl_lee_proveedor(r_rep.r16_proveedor) RETURNING r_pro.*
	CALL retorna_estado(r_rep.r16_estado) RETURNING estado
	LET proveedor = r_rep.r16_proveedor, ' ', r_pro.p01_nomprov
	CALL fl_justifica_titulo('I', proveedor, 50) RETURNING proveedor
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
	      COLUMN 105, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, titulo CLIPPED,
	      COLUMN 109, "REPP407"
	PRINT COLUMN 20, "** Pedido        : ", r_rep.r16_pedido
	PRINT COLUMN 20, "** Tipo de Pedido: ", r_rep.r16_tipo, " ", tipo_des
	PRINT COLUMN 20, "** Estado        : ", r_rep.r16_estado, " ", estado
	PRINT COLUMN 20, "** Proveedor     : ", proveedor
	PRINT COLUMN 20, "** Fecha de Envío: ", r_rep.r16_fec_envio
						USING "dd-mm-yyyy"
	PRINT COLUMN 20, "** Fecha Llegada : ", r_rep.r16_fec_llegada
						USING "dd-mm-yyyy"
	PRINT COLUMN 20, "** Referencia    : ", r_rep.r16_referencia
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 97, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,   "Item",
	      COLUMN 18,  "Descripción Item",
	      COLUMN 39,  "Cant. Ped.",
	      COLUMN 51,  "Cant. Rec.",
	      COLUMN 63,  "Cant. Pen.",
	      COLUMN 75,  "Ind. Pen.",
	      COLUMN 91,  "FOB Unit.",
	      COLUMN 107, "FOB Total"
	PRINT "--------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	IF cantpend = 0 THEN
		LET r_rep2.r17_ind_bko = NULL
	END IF
	PRINT COLUMN 1,   r_rep2.r17_item,
	      COLUMN 18,  nombre[1,20],
	      COLUMN 44,  r_rep2.r17_cantped USING '###&',
	      COLUMN 56,  r_rep2.r17_cantrec USING '###&',
	      COLUMN 68,  cantpend           USING '###&',
	      COLUMN 81,  r_rep2.r17_ind_bko,
	      COLUMN 86,  r_rep2.r17_fob     USING "###,###,##&.##",
	      COLUMN 102, valor_fob          USING "###,###,##&.##"
	
ON LAST ROW
	PRINT COLUMN 44, "----",
	      COLUMN 56, "----",
	      COLUMN 68, "----",
	      COLUMN 102, "--------------"
	PRINT COLUMN 28, "TOTALES ==>  ",
	      COLUMN 44, SUM(r_rep2.r17_cantped) USING '###&',
	      COLUMN 56, SUM(r_rep2.r17_cantrec) USING '###&',
	      COLUMN 68, SUM(cantpend)           USING '###&',
	      COLUMN 102, total_fob USING "###,###,##&.##"

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
