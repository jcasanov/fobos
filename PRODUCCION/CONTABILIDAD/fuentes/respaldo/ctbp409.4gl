------------------------------------------------------------------------------
-- Titulo           : ctbp409.4gl - Listado de Movimientos de Cuentas por FILTRO
-- Elaboracion      : 23-SEP-2002
-- Autor            : RCA
-- Formato Ejecucion: fglrun ctbp409 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE rm_b13		RECORD LIKE ctbt013.*
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT
DEFINE vm_tot_debito	DECIMAL(14,2)
DEFINE vm_tot_credito	DECIMAL(14,2)
DEFINE tot_val_db_c	DECIMAL(14,2)
DEFINE tot_val_cr_c	DECIMAL(14,2)
DEFINE tot_val_db_p	DECIMAL(14,2)
DEFINE tot_val_cr_p	DECIMAL(14,2)
DEFINE tot_val_db_d	DECIMAL(14,2)
DEFINE tot_val_cr_d	DECIMAL(14,2)
DEFINE tot_val_db_g	DECIMAL(14,2)
DEFINE tot_val_cr_g	DECIMAL(14,2)
DEFINE vm_cta_inicial	LIKE ctbt013.b13_cuenta
DEFINE nom_cta_ini	LIKE ctbt010.b10_descripcion
DEFINE vm_cliente	LIKE ctbt013.b13_codcli
DEFINE nom_cliente	LIKE cxct001.z01_nomcli
DEFINE vm_proveedor	LIKE ctbt013.b13_codprov
DEFINE nom_proveedor	LIKE cxpt001.p01_nomprov
DEFINE vm_pedido	LIKE ctbt013.b13_pedido
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_moneda	LIKE gent013.g13_moneda
DEFINE vm_nivel         SMALLINT
DEFINE vm_saldo 	DECIMAL (14,2)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/ctbp409.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)

LET vg_proceso = 'ctbp409'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 12 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/ctbf409_1"
DISPLAY FORM f_rep
CREATE TEMP TABLE temp_reporte
        (tipo_comp		CHAR(2),
	num_comp		CHAR(8),
	fec_proceso		DATE,
	glosa			CHAR(35),
	valor			DECIMAL(14,2),
	filtro			CHAR(11),
	flag_filtro		CHAR(1))  -- C Cliente, P Proveedor, D Pedido
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(800)
DEFINE comando 		VARCHAR(100)
DEFINE r_b13 	RECORD LIKE ctbt013.*
DEFINE r_b12	 	RECORD LIKE ctbt012.*
DEFINE val_db		DECIMAL(14,2)
DEFINE val_cr		DECIMAL(14,2)
DEFINE flag		CHAR(1)
DEFINE filtro		VARCHAR(10)
DEFINE i		SMALLINT
DEFINE r_rep  RECORD
		tipo_comp		CHAR(2),
		num_comp		CHAR(8),
		fec_proceso		DATE,
		glosa			CHAR(35),
		valor			DECIMAL(14,2),
		filtro			CHAR(11),
		flag_filtro		CHAR(1)
	END RECORD

LET vm_top    = 1
LET vm_left   = 0
LET vm_right  = 132
LET vm_bottom = 4
LET vm_page   = 66

LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda
LET vm_fecha_ini = TODAY
LET vm_fecha_fin = TODAY

LET vm_nivel     = 6

WHILE TRUE
	DELETE FROM temp_reporte
	LET vm_tot_debito  = 0
	LET vm_tot_credito = 0
	LET vm_saldo       = 0
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET query = 'SELECT * FROM ctbt013 ',
			'WHERE b13_compania  =',vg_codcia,
			'  AND b13_cuenta    ="',vm_cta_inicial,'"',
			'  AND b13_fec_proceso ',
			'BETWEEN "',vm_fecha_ini,'" AND "',vm_fecha_fin, '"'
	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte
	LET i = 0
	FOREACH q_reporte INTO r_b13.*
		IF (r_b13.b13_codcli IS NULL AND r_b13.b13_codprov IS NULL AND 
		    r_b13.b13_pedido IS NULL) AND 
		   (vm_cliente IS NOT NULL OR vm_proveedor IS NOT NULL OR
		    vm_pedido IS NOT NULL) THEN
			CONTINUE FOREACH
		END IF
		IF vm_cliente IS NOT NULL THEN
			IF r_b13.b13_codcli IS NULL OR 
			   vm_cliente <> r_b13.b13_codcli THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF vm_proveedor IS NOT NULL THEN
			IF r_b13.b13_codprov IS NULL OR 
			   vm_proveedor <> r_b13.b13_codprov THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF vm_pedido IS NOT NULL THEN 
			IF r_b13.b13_pedido IS NULL OR 
			   vm_pedido <> r_b13.b13_pedido THEN
				CONTINUE FOREACH
			END IF
		END IF
		CALL fl_lee_comprobante_contable(vg_codcia, r_b13.b13_tipo_comp,
			r_b13.b13_num_comp)
			RETURNING r_b12.*
		IF r_b12.b12_compania IS NULL THEN
			CONTINUE FOREACH
		END IF
		IF r_b12.b12_moneda <> vm_moneda THEN
			CONTINUE FOREACH
		END IF
		IF r_b12.b12_estado = 'E' THEN
			CONTINUE FOREACH
		END IF
		LET flag   = '*'
		LET filtro = 'FILTRO NULO'
		IF r_b13.b13_codcli IS NOT NULL THEN
			LET flag   = 'C'
			LET filtro = r_b13.b13_codcli USING '&&&&&&&'
		END IF
		IF r_b13.b13_codprov IS NOT NULL THEN
			LET flag   = 'P'
			LET filtro = r_b13.b13_codprov USING '&&&&&&&'
		END IF
		IF r_b13.b13_pedido IS NOT NULL THEN
			LET flag   = 'D'
			LET filtro = r_b13.b13_pedido
		END IF
		LET i = i + 1
		INSERT INTO temp_reporte VALUES (r_b13.b13_tipo_comp,
			r_b13.b13_num_comp, r_b13.b13_fec_proceso,
			r_b13.b13_glosa, r_b13.b13_valor_base, filtro, flag)
	END FOREACH
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	DECLARE q_filtro CURSOR FOR SELECT * FROM temp_reporte 
		ORDER BY flag_filtro, filtro, fec_proceso, tipo_comp, num_comp
	START REPORT report_movimientos_ctas TO PIPE comando
			--START REPORT rep_nota_pedido TO FILE "notaped.txt"
	LET tot_val_db_c = 0
	LET tot_val_cr_c = 0
	LET tot_val_db_p = 0
	LET tot_val_cr_p = 0
	LET tot_val_db_d = 0
	LET tot_val_cr_d = 0
	LET tot_val_db_g = 0
	LET tot_val_cr_g = 0
	FOREACH q_filtro INTO r_rep.*
		LET val_db = r_rep.valor
		LET val_cr = 0
		IF r_rep.valor < 0 THEN
			LET val_db = 0
			LET val_cr = r_rep.valor
		END IF
		OUTPUT TO REPORT report_movimientos_ctas(r_rep.*, r_b12.*, 
			val_db,val_cr)
	END FOREACH
	FINISH REPORT report_movimientos_ctas
END WHILE 

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_pro		RECORD LIKE cxpt002.*

INITIALIZE r_b10.* TO NULL
INITIALIZE r_z01.* TO NULL
INITIALIZE r_p01.* TO NULL
INITIALIZE r_pro.* TO NULL

OPTIONS INPUT NO WRAP
LET int_flag = 0
INPUT BY NAME 	vm_cta_inicial,	vm_moneda, vm_fecha_ini, vm_fecha_fin, 	
	        vm_cliente, vm_proveedor, vm_pedido
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(vm_cta_inicial) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET vm_cta_inicial = r_b10.b10_cuenta	
				DISPLAY BY NAME vm_cta_inicial
				DISPLAY r_b10.b10_descripcion TO nom_cta_ini
			END IF
		END IF
		IF INFIELD(vm_moneda) THEN
        		CALL fl_ayuda_monedas()
	               		RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		IF INFIELD(vm_cliente) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli 
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET vm_cliente  = r_z01.z01_codcli
				LET nom_cliente	= r_z01.z01_nomcli
				DISPLAY BY NAME vm_cliente, nom_cliente
			END IF
		END IF
		IF INFIELD(vm_proveedor) THEN
			CALL fl_ayuda_proveedores()
				RETURNING r_p01.p01_codprov, r_p01.p01_nomprov 
			IF r_p01.p01_codprov IS NOT NULL THEN
				LET vm_proveedor  = r_p01.p01_codprov
				LET nom_proveedor = r_p01.p01_nomprov
				DISPLAY BY NAME vm_proveedor, nom_proveedor
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD vm_cta_inicial
		IF vm_cta_inicial IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, vm_cta_inicial) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la cuenta en la Compañía.','exclamation')
				NEXT FIELD vm_cta_inicial
			END IF
			LET vm_cta_inicial = r_b10.b10_cuenta
			LET nom_cta_ini = r_b10.b10_descripcion
			DISPLAY BY NAME vm_cta_inicial, nom_cta_ini
		ELSE
			CLEAR nom_cta_ini
		END IF
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				NEXT FIELD vm_moneda
			ELSE
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER FIELD vm_cliente
		IF vm_cliente IS NULL THEN
			CLEAR nom_cliente
		ELSE
			CALL fl_lee_cliente_general(vm_cliente) 
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'No existe un cliente '||
                                                    'con ese código',
                                                    'exclamation')
				NEXT FIELD vm_cliente
        		END IF   
			IF r_z01.z01_estado = 'B' THEN
              			CALL fgl_winmessage(vg_producto,
                                                    'El cliente '||
                                                    'está bloqueado',
                                                    'exclamation')
				NEXT FIELD vm_cliente
			END IF
			LET vm_cliente  = r_z01.z01_codcli
			LET nom_cliente	= r_z01.z01_nomcli
			DISPLAY BY NAME vm_cliente, nom_cliente
		END IF
	AFTER FIELD vm_proveedor
		IF vm_proveedor IS NOT NULL THEN
			CALL fl_lee_proveedor(vm_proveedor)
		 		RETURNING r_p01.*
			IF r_p01.p01_codprov IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Proveedor no existe.','exclamation')
                                NEXT FIELD vm_proveedor
			END IF
			IF r_p01.p01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD vm_proveedor
                        END IF		 
			LET vm_proveedor  = r_p01.p01_codprov
			LET nom_proveedor = r_p01.p01_nomprov
			DISPLAY BY NAME vm_proveedor, nom_proveedor
		ELSE
			CLEAR nom_proveedor
		END IF
	AFTER INPUT 
		IF vm_cta_inicial IS NULL THEN
			NEXT FIELD vm_cta_inicial
		END IF
		IF vm_fecha_ini IS NULL THEN
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor igual a la de hoy.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha Final debe ser menor igual a la de hoy.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor igual a la Fecha Final.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_moneda IS NULL THEN
			NEXT FIELD vm_moneda
		END IF
		IF vm_cliente IS NOT NULL AND vm_proveedor IS NOT NULL 
			AND vm_pedido IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_proveedor, vm_cliente, vm_pedido
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_proveedor, vm_pedido, vm_cliente TO NULL
			NEXT FIELD vm_proveedor
		END IF
		IF vm_cliente IS NOT NULL AND vm_proveedor IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_proveedor, vm_cliente
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_cliente, vm_proveedor TO NULL
			NEXT FIELD vm_proveedor
		END IF
		IF vm_cliente IS NOT NULL AND vm_pedido IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_cliente, vm_pedido
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_cliente, vm_pedido TO NULL
			NEXT FIELD vm_cliente
		END IF
		IF vm_proveedor IS NOT NULL AND vm_pedido IS NOT NULL THEN
			CALL fgl_winmessage(vg_producto,'Especificar un solo Filtro, por favor','exclamation')
			CLEAR vm_proveedor, vm_pedido
			CLEAR nom_cliente, nom_proveedor, vm_pedido
			INITIALIZE vm_proveedor, vm_pedido TO NULL
			NEXT FIELD vm_proveedor
		END IF
END INPUT

END FUNCTION



REPORT report_movimientos_ctas(r_rep, r_b12, val_db, val_cr)
DEFINE r_rep  RECORD
		tipo_comp		CHAR(2),
		num_comp		CHAR(8),
		fec_proceso		DATE,
		glosa			CHAR(35),
		valor			DECIMAL(14,2),
		filtro			CHAR(11),
		flag_filtro		CHAR(1)
	END RECORD
DEFINE val_db		DECIMAL(14,2)
DEFINE val_cr		DECIMAL(14,2)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE glosa		CHAR(36)
DEFINE fecha_ini	DATE
DEFINE expr_filtro	VARCHAR(35)
DEFINE filtro		VARCHAR(15)
DEFINE usuario		VARCHAR(20)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
	ORDER EXTERNAL BY r_rep.flag_filtro, r_rep.filtro, r_rep.fec_proceso, 
		          r_rep.tipo_comp, r_rep.num_comp

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET usuario     = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	LET filtro      = '* T O D O S *'
	LET expr_filtro = NULL
	IF vm_proveedor IS NOT NULL THEN
		LET filtro 	= 'PROVEEDOR '
		LET expr_filtro = vm_proveedor USING '&&&&&&', '-', 
		                  nom_proveedor 
	END IF
	IF vm_cliente IS NOT NULL THEN
		LET filtro 	= 'CLIENTE '
		LET expr_filtro = vm_cliente USING '&&&&&&', '-', 
				  nom_cliente 
	END IF
	IF vm_pedido IS NOT NULL THEN
		LET filtro 	= 'PEDIDO '
		LET expr_filtro = vm_pedido
	END IF
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 01,  rg_cia.g01_razonsocial,
	      COLUMN 122, 'PAGINA: ', PAGENO USING '&&&'
	PRINT COLUMN 01,  'CONTABILIDAD',
	      COLUMN 48,  'MOVIMIENTOS DE CUENTA POR FILTROS',
	      COLUMN 123, UPSHIFT(fl_justifica_titulo('D', vg_proceso, 10))
	SKIP 1 LINES
	PRINT COLUMN 45, '** CUENTA      : ', vm_cta_inicial, ' ', nom_cta_ini
	PRINT COLUMN 45, '** MONEDA      : ',
	                 rm_g13.g13_nombre
	PRINT COLUMN 45, '** RANGO FECHAS: ',
	      		 vm_fecha_ini USING 'dd-mm-yyyy', ' - ',
	                 vm_fecha_fin USING 'dd-mm-yyyy'
	PRINT COLUMN 45, '** FILTRO      : ', filtro, ' ', expr_filtro 
	PRINT COLUMN 1,  'FECHA DE IMPRESION: ', TODAY USING 'dd-mm-yyyy',
		1 SPACES, TIME,
	      COLUMN 114,  usuario
	SKIP 1 LINES
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 01,  'TP',
	      COLUMN 07,  'NUMERO',
	      COLUMN 19,  'FECHA',
	      COLUMN 35,  'G L O S A',
	      COLUMN 74,  fl_justifica_titulo('D', 'DEBITO', 17),
	      COLUMN 95,  fl_justifica_titulo('D', 'CREDITO', 17),
	      COLUMN 116, fl_justifica_titulo('D', 'SALDO', 17) 
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF r_rep.filtro
	CASE r_rep.flag_filtro
		WHEN 'C'
			CALL fl_lee_cliente_general(r_rep.filtro) 
				RETURNING r_z01.*
			PRINT COLUMN 01, 'CLIENTE  : ', r_rep.filtro, ' ',
					 r_z01.z01_nomcli
		WHEN 'P'
			CALL fl_lee_proveedor(r_rep.filtro)
				RETURNING r_p01.*
			PRINT COLUMN 01, 'PROVEEDOR: ', r_rep.filtro, ' ',
					 r_p01.p01_nomprov
		WHEN 'D'
			PRINT COLUMN 01, 'PEDIDO   : ', r_rep.filtro
		OTHERWISE
			PRINT COLUMN 01, '*** SIN FILTRO ***'
	END CASE		

ON EVERY ROW
	NEED 6 LINES
	LET vm_saldo = vm_saldo + (val_db + val_cr)
	PRINT COLUMN 01,  r_rep.tipo_comp,
     	      COLUMN 07,  r_rep.num_comp,
      	      COLUMN 19,  r_rep.fec_proceso USING 'dd-mm-yyyy',
      	      COLUMN 33,  r_rep.glosa,
      	      COLUMN 74,  val_db USING '##,###,###,##&.##',
      	      COLUMN 95,  val_cr USING '##,###,###,##&.##',
      	      COLUMN 116, vm_saldo USING '--,---,---,--&.##' 
	CASE r_rep.flag_filtro
		WHEN 'C'
			LET tot_val_db_c = tot_val_db_c + val_db
			LET tot_val_cr_c = tot_val_cr_c + val_cr
		WHEN 'P'
			LET tot_val_db_p = tot_val_db_p + val_db
			LET tot_val_cr_p = tot_val_cr_p + val_cr
		WHEN 'D'
			LET tot_val_db_d = tot_val_db_d + val_db
			LET tot_val_cr_d = tot_val_cr_d + val_cr
	END CASE		
	LET tot_val_db_g = tot_val_db_g + val_db
	LET tot_val_cr_g = tot_val_cr_g + val_cr

AFTER GROUP OF r_rep.filtro
	NEED 2 LINES
	PRINT COLUMN 74, '-----------------',
	      COLUMN 95, '-----------------'
	PRINT COLUMN 74, GROUP SUM(val_db) USING '##,###,###,##&.##',
	      COLUMN 95, GROUP SUM(val_cr) USING '##,###,###,##&.##'

ON LAST ROW
	NEED 8 LINES
	SKIP 2 LINES
	IF tot_val_db_c > 0 OR tot_val_db_p > 0 OR tot_val_db_d > 0 OR
	   tot_val_cr_c > 0 OR tot_val_cr_p > 0 OR tot_val_cr_d > 0 THEN
		PRINT COLUMN 74, '------------------',
		      COLUMN 95, '------------------'
	END IF
	IF tot_val_db_c > 0 OR tot_val_cr_c THEN
		PRINT COLUMN 42, 'TOTALES GENERALES CLIENTES ==>  ',
			tot_val_db_c USING '###,###,###,##&.##',
		      COLUMN 95, tot_val_cr_c USING '###,###,###,##&.##'
	END IF
	IF tot_val_db_p > 0 OR tot_val_cr_p THEN
		PRINT COLUMN 39, 'TOTALES GENERALES PROVEEDORES ==>  ',
			tot_val_db_p USING '###,###,###,##&.##',
		      COLUMN 95, tot_val_cr_p USING '###,###,###,##&.##'
	END IF
	IF tot_val_db_d > 0 OR tot_val_cr_d THEN
		PRINT COLUMN 43, 'TOTALES GENERALES PEDIDOS ==>  ',
			tot_val_db_d USING '###,###,###,##&.##',
		      COLUMN 95, tot_val_cr_d USING '###,###,###,##&.##'
	END IF
	PRINT COLUMN 74, '------------------',
	      COLUMN 95, '------------------'
	PRINT COLUMN 43, 'TOTALES GENERALES FILTROS ==>  ',
		tot_val_db_g USING '###,###,###,##&.##',
	      COLUMN 95, tot_val_cr_g USING '###,###,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_b12.*, rm_b13.*, vm_fecha_ini, vm_fecha_fin , vm_cliente, vm_proveedor, vm_pedido TO NULL

END FUNCTION
