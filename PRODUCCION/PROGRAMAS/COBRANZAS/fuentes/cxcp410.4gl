-------------------------------------------------------------------------------
-- Titulo               : cxcp410.4gl --  Listado Cheques Protestados
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cajp410 base modulo compañía localidad
-- Ultima Correción     : ?
-- Motivo Corrección    : ? 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_par		RECORD
				moneda		LIKE gent013.g13_moneda,
				nombre		LIKE gent013.g13_nombre,
				inicial		DATE,
				final		DATE
			END RECORD
DEFINE rm_consulta	RECORD 
				fecha_banco	LIKE cajt012.j12_nd_fec_bco,
				cliente		LIKE cxct001.z01_nomcli,
				referencia      LIKE cajt012.j12_referencia,
				banco		LIKE gent008.g08_nombre,
				ctacte		LIKE cajt012.j12_num_cta,
				cheque		LIKE cajt012.j12_num_cheque,
				num_doc		LIKE cxct020.z20_num_doc,
				num_sri		LIKE cxct020.z20_num_sri,
				valor		LIKE cajt012.j12_valor
			END RECORD



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN   
     --CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     EXIT PROGRAM
END IF

LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp410'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		CHAR(1200)
DEFINE comando          VARCHAR(100)
DEFINE string		VARCHAR(30)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 10
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
	OPEN FORM frm_listado FROM '../forms/cxcf410_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxcf410_1c'
END IF
DISPLAY FORM frm_listado

LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.moneda   = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada una moneda base en el sistema.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.nombre  = r_g13.g13_nombre
LET rm_par.inicial = TODAY
LET rm_par.final   = TODAY
WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF INT_FLAG THEN
		EXIT WHILE
	END IF
	LET query = 'SELECT j12_nd_fec_bco, z01_nomcli, j12_referencia, ',
			' g08_nombre, j12_num_cta, j12_num_cheque, ',
			' z20_num_doc, z20_num_sri, j12_valor ',
			' FROM cajt012, cxct001, gent008, cxct020',
			' WHERE j12_compania  = ', vg_codcia, 
			'   AND j12_localidad = ', vg_codloc, 
			'   AND j12_moneda    = "', rm_par.moneda, '"',
			'   AND j12_nd_fec_bco BETWEEN "', rm_par.inicial,
					'" AND "', rm_par.final, '"', 
			'   AND z01_codcli    = j12_codcli ',
			'   AND g08_banco     = j12_banco ',
			'   AND z20_compania  = j12_compania ',
			'   AND z20_localidad = j12_localidad ',
			'   AND z20_codcli    = j12_codcli ',
			'   AND z20_tipo_doc  = "ND" ',
			'   AND z20_num_doc   = j12_nd_interna ',
			'   AND z20_dividendo = 1 ',
			' ORDER BY 1'
	PREPARE expresion FROM query
	DECLARE q_rep CURSOR FOR expresion
	OPEN q_rep
	FETCH q_rep INTO rm_consulta.*
	IF STATUS = NOTFOUND THEN
		CLOSE q_rep
		CALL fl_mensaje_consulta_sin_registros()
		RETURN
	END IF
	CLOSE q_rep
	START REPORT reporte_cheque_protestado TO PIPE comando
	FOREACH q_rep INTO rm_consulta.*
		OUTPUT TO REPORT reporte_cheque_protestado(rm_consulta.*)
	END FOREACH
	FINISH REPORT reporte_cheque_protestado
END WHILE

END FUNCTION



FUNCTION control_ingreso()
DEFINE	r_moneda	RECORD LIKE gent013.*
DEFINE  codmon		LIKE gent013.g13_moneda
DEFINE  descmon		LIKE gent013.g13_nombre
DEFINE  decimales	LIKE gent013.g13_decimales

LET int_flag = 0
INPUT BY NAME rm_par.*  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
        ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING codmon, descmon, decimales
  			LET int_flag = 0
			IF codmon IS NOT NULL THEN
				LET rm_par.moneda = codmon
				DISPLAY codmon TO moneda
				DISPLAY descmon TO nombre
			ELSE
				NEXT FIELD moneda
			END IF
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda)
				RETURNING r_moneda.*
			IF r_moneda.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'No existe moneda.','exclamation')
				CALL fl_mostrar_mensaje('No existe moneda.','exclamation')
				NEXT FIELD moneda
			ELSE
				DISPLAY r_moneda.g13_nombre TO nombre
			END IF
		ELSE
			--CALL fgl_winmessage(vg_producto,'Debe especificar la moneda.','exclamation')
			CALL fl_mostrar_mensaje('Debe especificar la moneda.','exclamation')
			NEXT FIELD moneda
		END IF
	AFTER INPUT  
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
			CONTINUE INPUT
		END IF

		IF rm_par.inicial > rm_par.final THEN
			--CALL fgl_winmessage(vg_producto,'La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.','exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



REPORT reporte_cheque_protestado(fecha_banco, cliente, referencia, banco,
				ctacte, cheque, num_doc, num_sri, valor)
DEFINE fecha_banco	LIKE cajt012.j12_nd_fec_bco
DEFINE cliente		LIKE cxct001.z01_nomcli
DEFINE referencia     	LIKE cajt012.j12_referencia
DEFINE banco		LIKE gent008.g08_nombre
DEFINE ctacte		LIKE cajt012.j12_num_cta
DEFINE cheque		LIKE cajt012.j12_num_cheque
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE num_sri		LIKE cxct020.z20_num_sri
DEFINE valor		LIKE cajt012.j12_valor
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
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
	LET modulo	= 'MODULO: COBRANZAS'
	LET long	= LENGTH(modulo)
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE CHEQUES PROTESTADOS',	'80')
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp
       	PRINT COLUMN 001, rg_cia.g01_razonsocial,
       	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
       	PRINT COLUMN 001, modulo  CLIPPED,
	      COLUMN 035, titulo,
	      COLUMN 126, UPSHIFT(vg_proceso)
      	SKIP 1 LINES
	PRINT COLUMN 48, "** MONEDA       : ", rm_par.moneda, ' ', rm_par.nombre
	PRINT COLUMN 48, "** FECHA INICIAL: ", rm_par.inicial USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** FECHA FINAL  : ", rm_par.final USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 01, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy", 
			 1 SPACES, TIME,
              COLUMN 123, usuario
      	SKIP 1 LINES
	PRINT COLUMN 001, "FEC. BANCO",
	      COLUMN 012, "CLIENTE",
	      COLUMN 038, "BANCO",
	      COLUMN 054, "CTA. CORRIENTE",
	      COLUMN 070, "CHEQUE",
	      COLUMN 086, "ND - INTERNA",
	      COLUMN 102, "No. SRI - ND",
	      COLUMN 120, "        VALOR"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, fecha_banco USING "dd-mm-yyyy",
	      COLUMN 012, cliente[1, 26],
	      COLUMN 038, banco [1, 15],
	      COLUMN 054, ctacte,
	      COLUMN 070, cheque,
	      COLUMN 086, num_doc,
	      COLUMN 102, num_sri,
	      COLUMN 120, valor USING "##,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 120, "-------------"
	PRINT COLUMN 120, SUM(valor) USING "##,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
