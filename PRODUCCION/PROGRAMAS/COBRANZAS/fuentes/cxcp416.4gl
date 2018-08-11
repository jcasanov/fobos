------------------------------------------------------------------------------
-- Titulo               : cxcp416.4gl --  Listado de Retenciones
-- Elaboraci�n          : 15-Feb-2003
-- Autor                : NPC
-- Formato de Ejecuci�n : fglrun cxcp416 base modulo compa��a localidad
-- Ultima Correci�n     :  
-- Motivo Correcci�n    :   

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_par		RECORD
				moneda		VARCHAR(2),
				inicial		DATE,
				final		DATE,
				cliente		INTEGER
			END RECORD
DEFINE rm_consulta	RECORD 
				ruc_ced		LIKE cxct001.z01_num_doc_id,
				cliente		LIKE cxct001.z01_nomcli,
				fecha_retencion	LIKE cajt010.j10_fecing,
				num_retencion	LIKE cajt011.j11_num_ch_aut,
				fecha_factura	LIKE rept019.r19_fecing,
				num_factura_sri LIKE rept038.r38_num_sri,
				valor_base	DECIMAL(14,2),
				valor_retencion LIKE cajt011.j11_valor
			END RECORD
DEFINE vm_tipo		CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   
     --CALL fgl_winmessage(vg_producto,'N�mero de par�metros incorrecto','stop')
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso  = 'cxcp416'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		CHAR(1500)
DEFINE comando          VARCHAR(100)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE subtotal		DECIMAL(14,2)
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_r38		RECORD
				cod_cia		LIKE rept019.r19_compania,
				cod_loc		LIKE rept019.r19_localidad,
				tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran
			END RECORD
DEFINE imprime		CHAR(1)

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 12
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM frm_listado FROM '../forms/cxcf416_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxcf416_1c'
END IF
DISPLAY FORM frm_listado
LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.inicial = TODAY
LET rm_par.final   = TODAY
LET vm_tipo	   = 'T'
WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET query = 'SELECT cajt010.*, cajt011.* ',
			' FROM cajt010, cajt011 ',
			' WHERE j10_compania    = ', vg_codcia,
			'   AND j10_localidad   = ', vg_codloc, 
			'   AND j10_moneda      = "', rm_par.moneda, '"',
			'   AND DATE(j10_fecing) BETWEEN "', rm_par.inicial,
						  '" AND "', rm_par.final, '"',
			'   AND j10_estado      <> "E" ',
			'   AND j11_compania    = j10_compania', 
			'   AND j11_localidad   = j10_localidad', 
			'   AND j11_tipo_fuente = j10_tipo_fuente', 
			'   AND j11_num_fuente  = j10_num_fuente', 
			'   AND j11_codigo_pago = "RT"', 
			' ORDER BY j10_fecing'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO r_j10.*, r_j11.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		FREE q_rep
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	START REPORT reporte_retenciones TO PIPE comando
	LET imprime = 'N'
	FOREACH q_rep INTO r_j10.*, r_j11.*
		IF vm_tipo = 'P' THEN
			IF r_j10.j10_tipo_fuente = "PR" OR
			   r_j10.j10_tipo_fuente = "OT" THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF vm_tipo = 'F' THEN
			IF r_j10.j10_tipo_destino = "PG" THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF rm_par.cliente IS NOT NULL THEN
			IF r_j10.j10_codcli IS NULL THEN
				CONTINUE FOREACH
			END IF
			IF rm_par.cliente <> r_j10.j10_codcli THEN
				CONTINUE FOREACH
			END IF
		END IF
		LET imprime = 'S'
		IF r_j10.j10_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(r_j10.j10_codcli)
				RETURNING r_z01.*
			LET rm_consulta.ruc_ced	= r_z01.z01_num_doc_id
			LET rm_consulta.cliente	= r_z01.z01_nomcli
		END IF
		LET r_r38.cod_cia		= vg_codcia
		LET r_r38.cod_loc		= vg_codloc
		LET r_r38.tipo_fuente		= r_j10.j10_tipo_fuente
		LET rm_consulta.fecha_retencion	= r_j10.j10_fecing
		LET rm_consulta.num_retencion	= r_j11.j11_num_ch_aut
		LET rm_consulta.valor_retencion = r_j11.j11_valor
		IF r_j10.j10_tipo_fuente = "PR" OR r_j10.j10_tipo_fuente = "SC"
		THEN
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
					vg_codloc, r_j10.j10_tipo_destino,
					r_j10.j10_num_destino)
				RETURNING r_r19.*
			LET subtotal       = r_r19.r19_tot_bruto - 
					     r_r19.r19_tot_dscto
			LET r_r38.cod_tran = r_r19.r19_cod_tran
			LET r_r38.num_tran = r_r19.r19_num_tran
			IF r_j10.j10_codcli IS NULL THEN
				LET rm_consulta.ruc_ced = r_r19.r19_cedruc
				LET rm_consulta.cliente	= r_r19.r19_nomcli
			END IF
			LET rm_consulta.fecha_factura = r_r19.r19_fecing
			LET rm_consulta.valor_base    = subtotal
			IF r_j10.j10_tipo_destino = "PG" THEN
				LET rm_consulta.num_factura_sri =
					r_j10.j10_tipo_destino, '-', 
					r_j10.j10_num_destino
				LET rm_consulta.fecha_factura	= NULL
				LET rm_consulta.valor_base      = 0
			END IF
		END IF
		IF r_j10.j10_tipo_fuente = "OT" THEN
			CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc,
						r_j10.j10_num_fuente)
				RETURNING r_t23.*
			LET r_r38.cod_tran = "FA"
			LET r_r38.num_tran = r_t23.t23_num_factura
			IF r_j10.j10_codcli IS NULL THEN
				LET rm_consulta.ruc_ced = "**SIN CODIGO**"
				LET rm_consulta.cliente	= r_t23.t23_nom_cliente
			END IF
			LET rm_consulta.fecha_factura = r_t23.t23_fec_factura
			LET rm_consulta.valor_base    = r_t23.t23_tot_bruto -
						        r_t23.t23_tot_dscto
		END IF
		IF r_j10.j10_tipo_destino <> "PG" THEN
			CALL retorna_sri(r_r38.*)
		END IF
		OUTPUT TO REPORT reporte_retenciones()
	END FOREACH
	FINISH REPORT reporte_retenciones
	IF imprime = 'N' THEN
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION retorna_sri(r_r38)
DEFINE r_r38		RECORD
				cod_cia		LIKE rept019.r19_compania,
				cod_loc		LIKE rept019.r19_localidad,
				tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				cod_tran	LIKE rept019.r19_cod_tran,
				num_tran	LIKE rept019.r19_num_tran
			END RECORD

SELECT r38_num_sri INTO rm_consulta.num_factura_sri
	FROM rept038
	WHERE r38_compania    = r_r38.cod_cia
	  AND r38_localidad   = r_r38.cod_loc
	  AND r38_tipo_fuente = r_r38.tipo_fuente
	  AND r38_cod_tran    = r_r38.cod_tran
	  AND r38_num_tran    = r_r38.num_tran

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_moneda		RECORD LIKE gent013.*
DEFINE r_cliente	RECORD LIKE cxct001.*
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE nombre_mon	LIKE gent013.g13_nombre
DEFINE decimales	LIKE gent013.g13_decimales
DEFINE cliente		LIKE cxct001.z01_codcli
DEFINE desc_cliente	LIKE cxct001.z01_nomcli
DEFINE tipo		VARCHAR(10)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_moneda.* 
DISPLAY r_moneda.g13_nombre TO desc_moneda
IF vg_gui = 0 THEN
	CALL muestra_tipo(1) RETURNING tipo
END IF
LET int_flag = 0
INPUT BY NAME rm_par.moneda, rm_par.inicial, rm_par.final, rm_par.cliente,
	      vm_tipo
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY (F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING moneda, nombre_mon, decimales
			LET int_flag = 0
			IF moneda IS NOT NULL THEN
				LET rm_par.moneda = moneda
				DISPLAY moneda TO moneda
				DISPLAY nombre_mon TO desc_moneda
			END IF
		END IF
		IF INFIELD(cliente) THEN
			CALL fl_ayuda_cliente_general()
				RETURNING cliente, desc_cliente
			LET int_flag = 0
			IF cliente IS NOT NULL THEN 
				LET rm_par.cliente = cliente
				DISPLAY cliente TO cliente
				DISPLAY desc_cliente TO desc_cli
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD inicial
		LET fecha_ini = rm_par.inicial
	BEFORE FIELD final
		LET fecha_fin = rm_par.final
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) 
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe moneda','exclamation')
				CALL fl_mostrar_mensaje('No existe moneda.','exclamation')
				NEXT FIELD moneda
			ELSE
				DISPLAY r_moneda.g13_nombre TO desc_moneda
			END IF
		ELSE
			CLEAR desc_moneda
		END IF
	AFTER FIELD inicial
		IF rm_par.inicial IS NOT NULL THEN
			IF rm_par.inicial > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor o igual a la fecha de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha de hoy.','exclamation')
				NEXT FIELD inicial
			END IF
		ELSE
			LET rm_par.inicial = fecha_ini
			DISPLAY BY NAME rm_par.inicial
		END IF
	AFTER FIELD final
		IF rm_par.final IS NOT NULL THEN
			IF rm_par.final > TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha final debe ser menor o igual a la fecha de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha final debe ser menor o igual a la fecha de hoy.','exclamation')
				NEXT FIELD final
			END IF
		ELSE
			LET rm_par.final = fecha_fin
			DISPLAY BY NAME rm_par.final
		END IF
	AFTER FIELD cliente
		IF rm_par.cliente IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.cliente)
				RETURNING r_cliente.*
			IF r_cliente.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe cliente.','exclamation')
				CALL fl_mostrar_mensaje('No existe cliente.','exclamation')
				NEXT FIELD cliente
			ELSE
				DISPLAY r_cliente.z01_nomcli TO desc_cli
			END IF
		ELSE
			CLEAR desc_cli
		END IF
	AFTER FIELD vm_tipo
		IF vg_gui = 0 THEN
			IF vm_tipo IS NOT NULL THEN
				CALL muestra_tipo(1) RETURNING tipo
			ELSE
				CLEAR tit_tipo
				LET vm_tipo = 'T'
				DISPLAY BY NAME vm_tipo
				CALL muestra_tipo(1) RETURNING tipo
			END IF
		END IF
	AFTER INPUT  
		IF rm_par.inicial > rm_par.final THEN
			--CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			NEXT FIELD inicial
		END IF
END INPUT

END FUNCTION



REPORT reporte_retenciones()
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE tipo             VARCHAR(10)
DEFINE long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	0
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi�n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo	= 'MODULO: COBRANZAS'
	LET long	= LENGTH(modulo)
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE RETENCIONES', 80)
		RETURNING titulo
	CALL muestra_tipo(2) RETURNING tipo
	print ASCII escape;
	print ASCII act_comp
       	PRINT COLUMN 01,  rg_cia.g01_razonsocial,
              COLUMN 122, 'PAGINA: ', PAGENO USING '&&&'
       	PRINT COLUMN 01,  modulo CLIPPED,
	      COLUMN 34,  titulo CLIPPED,
              COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 37, '** FECHA INICIAL: ', rm_par.inicial
						USING 'dd-mm-yyyy'
	PRINT COLUMN 37, '** FECHA FINAL  : ', rm_par.final USING 'dd-mm-yyyy'
	IF rm_par.cliente IS NOT NULL THEN
		PRINT COLUMN 37, '** CLIENTE      : ', rm_consulta.cliente
	ELSE
		PRINT 1 SPACES
	END IF
	PRINT COLUMN 37, '** TIPO         : ', vm_tipo, ' ', tipo
	SKIP 1 LINES
	PRINT COLUMN 01, 'FECHA IMPRESION: ', TODAY USING 'dd-mm-yyyy', 
		 1 SPACES, TIME,
              COLUMN 122, usuario
      	SKIP 1 LINES
	PRINT COLUMN 01,  '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 01,  'RUC/CEDULA',
	      COLUMN 17,  'CLIENTE',
	      COLUMN 54,  'FECH. RET.',
	      COLUMN 65,  'No. RETENCION',
	      COLUMN 81,  'FEC. FACT.',
	      COLUMN 92,  'FACTURA SRI',
	      COLUMN 109, '   VALOR BASE',
	      COLUMN 123, 'VALOR RET.'
	PRINT COLUMN 01,  '------------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 01,  rm_consulta.ruc_ced, 
	      COLUMN 17,  rm_consulta.cliente[1, 36],
	      COLUMN 54,  DATE(rm_consulta.fecha_retencion) USING 'dd-mm-yyyy',
	      COLUMN 65,  rm_consulta.num_retencion,
	      COLUMN 81,  DATE(rm_consulta.fecha_factura)   USING 'dd-mm-yyyy',
	      COLUMN 92,  rm_consulta.num_factura_sri,
	      COLUMN 109, rm_consulta.valor_base	USING '##,###,##&.##',
	      COLUMN 123, rm_consulta.valor_retencion	USING '###,##&.##'

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 109, '-------------',
	      COLUMN 123, '----------'
	PRINT COLUMN 109, SUM(rm_consulta.valor_base) USING '##,###,##&.##',
	      COLUMN 123, SUM(rm_consulta.valor_retencion) USING '###,##&.##';
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION muestra_tipo(flag)
DEFINE flag		SMALLINT
DEFINE tipo		VARCHAR(10)

LET tipo = NULL
CASE vm_tipo
	WHEN 'F'
		CASE flag
			WHEN 1
				DISPLAY 'FACTURAS' TO tit_tipo
			WHEN 2
				LET tipo = 'FACTURAS'
		END CASE
	WHEN 'P'
		CASE flag
			WHEN 1
				DISPLAY 'PAGOS' TO tit_tipo
			WHEN 2
				LET tipo = 'PAGOS'
		END CASE
	WHEN 'T'
		CASE flag
			WHEN 1
				DISPLAY 'T O D O S' TO tit_tipo
			WHEN 2
				LET tipo = 'T O D O S'
		END CASE
	OTHERWISE
		CLEAR vm_tipo, tit_tipo
END CASE
RETURN tipo

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
