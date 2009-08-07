
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
DEFINE rm_par RECORD
	inicial		DATE,
	final		DATE
END RECORD

DEFINE rm_consulta	RECORD 
	area		LIKE gent003.g03_nombre,
	fecha_banco	LIKE cajt012.j12_nd_fec_bco,
	cliente		LIKE cxct001.z01_nomcli,
	referencia      LIKE cajt012.j12_referencia,
	banco		LIKE gent008.g08_nombre,
	ctacte		LIKE cajt012.j12_num_cta,
	cheque		LIKE cajt012.j12_num_cheque,
	moneda		LIKE cajt012.j12_moneda,
	valor		LIKE cajt012.j12_valor
END RECORD


DEFINE vm_page 		SMALLINT
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN   
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp410'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(700)
DEFINE comando          VARCHAR(100)
DEFINE string		VARCHAR(30)

LET vm_top	= 1
LET vm_left	= 2
LET vm_right	= 90
LET vm_bottom	= 4
LET vm_page	= 66

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 10 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP, ACCEPT KEY F12
OPEN FORM frm_listado FROM '../forms/cxcf410_1'
DISPLAY FORM frm_listado

LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.inicial = TODAY
WHILE (TRUE)
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF INT_FLAG THEN
		EXIT WHILE
	END IF

	LET query = 'SELECT g03_nombre, j12_nd_fec_bco, z01_nomcli,' || 
		' j12_referencia, g08_nombre, j12_num_cta, j12_num_cheque,' ||
		' j12_moneda, j12_valor FROM cajt012, gent003,' || 
		' cxct001, gent008' ||
		' WHERE j12_compania = ' || vg_codcia || 
		' AND j12_localidad = '  || vg_codloc || 
		' AND j12_nd_fec_bco BETWEEN "' || rm_par.inicial ||
		'" AND "' || rm_par.final || '"' || 
		' AND z01_codcli = j12_codcli' ||
		' AND g03_compania = j12_compania' ||
		' AND g03_areaneg = j12_areaneg' ||
		' AND g08_banco = j12_banco' ||
		' ORDER BY 2'

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

LET int_flag = 0
INPUT BY NAME rm_par.*  WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN

	AFTER INPUT  
		IF rm_par.inicial IS NULL OR rm_par.final IS NULL THEN
			CONTINUE INPUT
		END IF

		IF rm_par.inicial > rm_par.final THEN
			CALL fgl_winmessage('PHOBOS',
			   'La fecha inicial debe ser menor o igual que ' ||
			   'la fecha final.',
			   'exclamation')
			CONTINUE INPUT
		END IF
		
END INPUT

END FUNCTION

REPORT reporte_cheque_protestado(area, fecha_banco, cliente, 
		referencia, banco, ctacte, cheque, moneda, valor)

DEFINE area		LIKE gent003.g03_nombre
DEFINE fecha_banco	LIKE cajt012.j12_nd_fec_bco
DEFINE cliente		LIKE cxct001.z01_nomcli
DEFINE referencia     	LIKE cajt012.j12_referencia
DEFINE banco		LIKE gent008.g08_nombre
DEFINE ctacte		LIKE cajt012.j12_num_cta
DEFINE cheque		LIKE cajt012.j12_num_cheque
DEFINE moneda		LIKE cajt012.j12_moneda
DEFINE valor		LIKE cajt012.j12_valor
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT

OUTPUT
	TOP 	MARGIN vm_top
	LEFT 	MARGIN vm_left
	RIGHT 	MARGIN vm_right
	BOTTOM	MARGIN vm_bottom
	PAGE 	LENGTH vm_page

FORMAT
	PAGE HEADER
		LET modulo	= 'Módulo: Cobranzas'
		LET long	= LENGTH(modulo)
		
		CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
		CALL fl_justifica_titulo('C', 
					'LISTADO DE CHEQUES PROTESTADOS', 
					'52')


		RETURNING titulo
        	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
              	      COLUMN 120, "Página: ", PAGENO USING "&&&"
        	PRINT COLUMN 1,   modulo  CLIPPED,
		      COLUMN 44,  titulo,
                      COLUMN 109, UPSHIFT(vm_programa)

      	SKIP 1 LINES
	
	PRINT COLUMN 18, "***Fecha Inicial: ", rm_par.inicial
	PRINT COLUMN 18, "***Fecha Final:   ", rm_par.final
	
	SKIP 1 LINES
	
	PRINT COLUMN 01, "Fecha impresión: ", TODAY USING "dd-mmm-yyyy", 
			 1 SPACES, TIME,
              COLUMN 120, usuario
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,   "Area",
		      COLUMN 13,  "Fecha de Banco",
		      COLUMN 29,  "Cliente",
		      COLUMN 53,  "Banco",
		      COLUMN 70,  "Cuenta Corriente",
		      COLUMN 92,  "Cheque",
		      COLUMN 109, "Moneda",		
		      COLUMN 128, "Valor"

		PRINT COLUMN 1,  "------------",
		      COLUMN 13, "----------------",
		      COLUMN 29, "------------------------",
		      COLUMN 53, "-----------------",
		      COLUMN 70, "----------------------",
		      COLUMN 92, "-----------------",
		      COLUMN 109,"-------------",
		      COLUMN 118,"------------"


	ON EVERY ROW
		PRINT COLUMN 1,   area[1, 10] CLIPPED,
		      COLUMN 13,  fecha_banco,
		      COLUMN 29,  cliente[1, 22] CLIPPED,
		      COLUMN 53,  banco [1, 15] CLIPPED,
		      COLUMN 70,  ctacte CLIPPED,
		      COLUMN 92,  cheque CLIPPED,
		      COLUMN 109, moneda CLIPPED, 
		      COLUMN 118, valor USING "#,###,###,##&.##"

	ON LAST ROW
		NEED 3 LINES
		PRINT COLUMN 123, "-----------"
		PRINT COLUMN 118, SUM(valor) USING "#,###,###,##&.##"
END REPORT
