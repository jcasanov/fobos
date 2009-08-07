-------------------------------------------------------------------------------
-- Titulo               : cxcp408.4gl --  Listado Cheques Post Fechados
-- Elaboración          : 
-- Autor                : RRM
-- Formato de Ejecución : fglrun  cxcp408 base modulo compañía localidad
-- Ultima Correción     : ?
-- Motivo Corrección    : ? 

--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE vm_demonios      VARCHAR(12)
DEFINE rm_par RECORD
	inicial		DATE,
	final		DATE,
	estado 		CHAR(1) 
END RECORD

DEFINE rm_consulta	RECORD 
	abreviacion	LIKE gent003.g03_abreviacion,
	fecha_cobro	LIKE cxct026.z26_fecha_cobro,
	cliente		LIKE cxct001.z01_nomcli,
	referencia      LIKE cxct026.z26_referencia,
	banco		LIKE gent008.g08_nombre,
	ctacte		LIKE cxct026.z26_num_cta,
	cheque		LIKE cxct026.z26_num_cheque,
	estado		LIKE cxct026.z26_estado,
	valor		LIKE cxct026.z26_valor
END RECORD
--DEFINE  rm_cia RECORD LIKE gent001.*


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
LET vg_proceso = 'cxcp408'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()
DEFINE query 		VARCHAR(700)
DEFINE comando          VARCHAR(100)
DEFINE estado		CHAR(1)
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
OPEN FORM frm_listado FROM '../forms/cxcf408_1'
DISPLAY FORM frm_listado

LET int_flag = 0
INITIALIZE rm_par.* TO NULL 
LET rm_par.inicial = TODAY
LET rm_par.estado  = 'A'
WHILE (TRUE)
	--CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	CALL control_ingreso()
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF INT_FLAG THEN
		EXIT WHILE
	END IF

	LET string = ' '
	IF rm_par.estado <> 'T' THEN
		LET string = ' AND z26_estado = "' || rm_par.estado || '"'
	END IF

	LET query = 'SELECT g03_abreviacion, z26_fecha_cobro, z01_nomcli,' || 
		' z26_referencia, g08_nombre, z26_num_cta, z26_num_cheque,' ||
		' z26_estado, z26_valor FROM cxct026, cxct001,' || 
		' gent003, gent008' ||
		' WHERE z26_compania = ' || vg_codcia || 
		' AND z26_localidad = '  || vg_codloc || 
		' AND z26_fecha_cobro BETWEEN "' || rm_par.inicial ||
		' " AND "' || rm_par.final || '"' || string ||
		' AND z01_codcli = z26_codcli' ||
		' AND g03_compania = z26_compania' ||
		' AND g03_areaneg = z26_areaneg' ||
		' AND g08_banco = z26_banco' ||
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
	START REPORT reporte_cheque_postfechado TO PIPE comando
	FOREACH q_rep INTO rm_consulta.*
		OUTPUT TO REPORT reporte_cheque_postfechado(rm_consulta.*)
	END FOREACH
	FINISH REPORT reporte_cheque_postfechado
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

REPORT reporte_cheque_postfechado(abreviacion, fecha_cobro, cliente, 
		referencia, banco, ctacte, cheque, estado, valor)

DEFINE abreviacion	LIKE gent003.g03_abreviacion
DEFINE fecha_cobro	LIKE cxct026.z26_fecha_cobro
DEFINE cliente		LIKE cxct001.z01_nomcli
DEFINE referencia     	LIKE cxct026.z26_referencia
DEFINE banco		LIKE gent008.g08_nombre
DEFINE ctacte		LIKE cxct026.z26_num_cta
DEFINE cheque		LIKE cxct026.z26_num_cheque
DEFINE estado		LIKE cxct026.z26_estado
DEFINE valor		LIKE cxct026.z26_valor
DEFINE usuario          VARCHAR(19,15)
DEFINE titulo           VARCHAR(80)
DEFINE modulo           VARCHAR(40)
DEFINE i,long           SMALLINT
DEFINE descr_estado	VARCHAR(10)		

OUTPUT
	TOP 	MARGIN vm_top
	LEFT 	MARGIN vm_left
	RIGHT 	MARGIN vm_right
	BOTTOM	MARGIN vm_bottom
	PAGE 	LENGTH vm_page

FORMAT
	PAGE HEADER

		print 'E'; 
		print '&l26A';      -- Indica que voy a trabajar con hojas A4
		print '&k4S'	      -- Letra (12 cpi)

		LET modulo	= 'Módulo: Cobranzas'
		LET long	= LENGTH(modulo)
		
		CALL fl_justifica_titulo('D', vg_usuario, 10) RETURNING usuario
		CALL fl_justifica_titulo('C', 
					'LISTADO DE CHEQUES POSTFECHADOS', 
					'52')
			RETURNING titulo

		print '&k2S'	        -- Letra (16 cpi)

        	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
              	      COLUMN 114, "Página: ", PAGENO USING "&&&"
        	PRINT COLUMN 1,   modulo  CLIPPED,
		      COLUMN 38,  titulo,
                      COLUMN 88, UPSHIFT(vg_proceso)

      	SKIP 1 LINES
	
	CASE rm_par.estado
		WHEN 'A'
			LET descr_estado = 'ACTIVOS'
		WHEN 'B'
			LET descr_estado = 'BLOQUEADOS'
		OTHERWISE
			LET descr_estado = 'TODOS'
	END CASE

	PRINT COLUMN 18, "***Fecha Inicial: ", rm_par.inicial
	PRINT COLUMN 18, "***Fecha Final:   ", rm_par.final
	PRINT COLUMN 18, "***Estado:        ", descr_estado
	
	SKIP 1 LINES
	
	PRINT COLUMN 01, "Fecha impresión: ", TODAY USING "dd-mmm-yyyy", 
			 1 SPACES, TIME,
              COLUMN 115, fl_justifica_titulo('D',usuario,10)
                                                                                
      	SKIP 1 LINES

		PRINT COLUMN 1,  "============",
		      COLUMN 13, "================",
		      COLUMN 29, "========================",
		      COLUMN 53, "=================",
		      COLUMN 70, "======================",
		      COLUMN 92, "=================",
		      COLUMN 109,"================"
		      --COLUMN 118,"============"

		PRINT COLUMN 1,   "Area",
		      COLUMN 13,  "Fecha de Cobro",
		      COLUMN 29,  "Cliente",
		      COLUMN 53,  "Banco",
		      COLUMN 70,  "Cuenta Corriente",
		      COLUMN 92,  "Cheque",
		      COLUMN 120, "Valor"		
		      --COLUMN 128, "Valor"

		PRINT COLUMN 1,  "============",
		      COLUMN 13, "================",
		      COLUMN 29, "========================",
		      COLUMN 53, "=================",
		      COLUMN 70, "======================",
		      COLUMN 92, "=================",
		      COLUMN 109,"================"
		      --COLUMN 118,"============"

	ON EVERY ROW
		PRINT COLUMN 1,   abreviacion[1, 10] CLIPPED,
		      COLUMN 13,  fecha_cobro,
		      COLUMN 29,  cliente[1, 22] CLIPPED,
		      COLUMN 53,  banco [1, 15] CLIPPED,
		      COLUMN 70,  ctacte CLIPPED,
		      COLUMN 92,  cheque CLIPPED,
		      --COLUMN 109, descr_estado CLIPPED, 
		      COLUMN 109, valor USING "#,###,###,##&.##"

	ON LAST ROW
		NEED 3 LINES
		PRINT COLUMN 109, "----------------"
		PRINT COLUMN 109, SUM(valor) USING "#,###,###,##&.##"
END REPORT
