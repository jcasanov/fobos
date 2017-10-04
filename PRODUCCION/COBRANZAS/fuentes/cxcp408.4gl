--------------------------------------------------------------------------------
-- Titulo           : cxcp408.4gl Listado Cheques Postfechados
-- Elaboracion      : 14-dic-2001
-- Autor            : RRM
-- Formato Ejecucion: fglrun cxcp408 base módulo compañía localidad
--			[estado] [moneda] [[cliente]] [[localidad]]
--			[[fecha_ini]] [[fecha_fin]] [[tipo_fecha]]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_z20		RECORD LIKE cxct020.*
DEFINE rm_z26		RECORD LIKE cxct026.*
DEFINE localidad	LIKE gent002.g02_localidad
DEFINE tipo_fecha	CHAR(1)
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
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CALL startlog('../logs/cxcp408.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   
	IF num_args() < 6 OR num_args() > 11 THEN   
		CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
		EXIT PROGRAM
	END IF
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp408'
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
IF num_args() > 4 THEN
	CALL control_llamada_otro_programa()
	EXIT PROGRAM
END IF
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
	OPEN FORM frm_listado FROM '../forms/cxcf408_1'
ELSE
	OPEN FORM frm_listado FROM '../forms/cxcf408_1c'
END IF
DISPLAY FORM frm_listado
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_llamada_otro_programa()
DEFINE r_g13		RECORD LIKE gent013.*

INITIALIZE localidad, rm_z26.*, rm_z20.*, vm_fecha_ini, vm_fecha_fin TO NULL
LET rm_z26.z26_estado = arg_val(5)
LET rm_z20.z20_moneda = arg_val(6)
CALL fl_lee_moneda(rm_z20.z20_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
IF num_args() > 6 THEN
	LET rm_z26.z26_codcli = arg_val(7)
	LET localidad         = arg_val(8)
	IF rm_z26.z26_codcli = 0 THEN
		LET rm_z26.z26_codcli = NULL
	END IF
	IF localidad = 0 THEN
		LET localidad = NULL
	END IF
	LET vm_fecha_ini      = arg_val(9)
	LET vm_fecha_fin      = arg_val(10)
	LET tipo_fecha        = arg_val(11)
END IF
CALL ejecutar_listado()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_g13		RECORD LIKE gent013.*

LET vm_fecha_ini      = vg_fecha
LET tipo_fecha        = 'C'
LET rm_z26.z26_estado = 'A'
LET rm_z20.z20_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_z20.z20_moneda) RETURNING r_g13.*
IF r_g13.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_g13.g13_nombre TO tit_moneda
IF vg_gui = 0 THEN
	CALL muestra_estado(rm_z26.z26_estado)
	CALL muestra_tipo_fec(tipo_fecha)
END IF
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL ejecutar_listado()
END WHILE

END FUNCTION



FUNCTION ejecutar_listado()
DEFINE query			CHAR(1300)
DEFINE expr_sql         VARCHAR(100)
DEFINE expr_estado      VARCHAR(100)
DEFINE expr_loc			VARCHAR(100)
DEFINE expr_fecha		VARCHAR(100)
DEFINE comando          VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET expr_sql = NULL
IF rm_z26.z26_codcli IS NOT NULL THEN
	LET expr_sql = '   AND z26_codcli      = ', rm_z26.z26_codcli
END IF
LET expr_estado = NULL
IF rm_z26.z26_estado <> 'T' THEN
	LET expr_estado = '   AND z26_estado      = "', rm_z26.z26_estado, '"'
END IF
LET expr_loc = NULL
IF localidad IS NOT NULL THEN
	LET expr_loc = '   AND z26_localidad   = ', localidad
END IF
LET expr_fecha = NULL
IF tipo_fecha = 'C' THEN
	IF vm_fecha_ini IS NOT NULL THEN
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND z26_fecha_cobro BETWEEN "',
						vm_fecha_ini,
						 '" AND "', vm_fecha_fin, '"'
		ELSE
			LET expr_fecha = '   AND z26_fecha_cobro >= "',
						vm_fecha_ini, '"'
		END IF
	ELSE
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND z26_fecha_cobro <= "',
						vm_fecha_fin, '"'
		END IF
	END IF
ELSE
	IF vm_fecha_ini IS NOT NULL THEN
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND DATE(z26_fecing) BETWEEN "',
						vm_fecha_ini,
						 '" AND "', vm_fecha_fin, '"'
		ELSE
			LET expr_fecha = '   AND DATE(z26_fecing) >= "',
						vm_fecha_ini, '"'
		END IF
	ELSE
		IF vm_fecha_fin IS NOT NULL THEN
			LET expr_fecha = '   AND DATE(z26_fecing) <= "',
						vm_fecha_fin, '"'
		END IF
	END IF
END IF
LET query = 'SELECT g03_abreviacion, z26_fecha_cobro, z01_nomcli, ',
		' z26_referencia, g08_nombre, z26_num_cta, z26_num_cheque, ',
		' z26_estado, SUM(z26_valor) ',
		' FROM cxct026, cxct001, gent008, OUTER gent003 ',
		' WHERE z26_compania    = ', vg_codcia,
		expr_loc CLIPPED,
		expr_sql CLIPPED, 
		expr_estado CLIPPED,
		expr_fecha CLIPPED,
		'  AND z01_codcli       = z26_codcli ',
		'  AND g03_compania     = z26_compania ',
		'  AND g03_areaneg      = z26_areaneg ',
		'  AND g08_banco        = z26_banco ',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8 ',
		' ORDER BY 2 DESC'
PREPARE expresion FROM query
DECLARE q_rep CURSOR FOR expresion
OPEN q_rep
FETCH q_rep INTO rm_consulta.*
IF STATUS = NOTFOUND THEN
	CLOSE q_rep
	FREE q_rep
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
START REPORT reporte_cheque_postfechado TO PIPE comando
FOREACH q_rep INTO rm_consulta.*
	OUTPUT TO REPORT reporte_cheque_postfechado(rm_consulta.*)
END FOREACH
FINISH REPORT reporte_cheque_postfechado

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codcli		LIKE cxct026.z26_codcli
DEFINE nomcli		LIKE cxct001.z01_nomcli
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

INITIALIZE mone_aux, codcli TO NULL
LET int_flag = 0
INPUT BY NAME rm_z26.z26_estado, rm_z20.z20_moneda, tipo_fecha, vm_fecha_ini,
	vm_fecha_fin, rm_z26.z26_codcli, localidad
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z20_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET rm_z20.z20_moneda = mone_aux
                               	DISPLAY BY NAME rm_z20.z20_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET localidad = r_g02.g02_localidad
				DISPLAY BY NAME localidad
				DISPLAY r_g02.g02_nombre TO tit_localidad
			END IF
		END IF
		IF INFIELD(z26_codcli) THEN
			IF localidad IS NULL THEN
                     		CALL fl_ayuda_cliente_general()
					RETURNING codcli, nomcli
			ELSE
				CALL fl_ayuda_cliente_localidad(vg_codcia,
								localidad)
					RETURNING codcli, nomcli
			END IF
                       	IF codcli IS NOT NULL THEN
                             	LET rm_z26.z26_codcli = codcli
                               	DISPLAY BY NAME rm_z26.z26_codcli
                               	DISPLAY nomcli TO tit_nombre_cli
                        END IF
                END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD z20_moneda
               	IF rm_z20.z20_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(rm_z20.z20_moneda)
                               	RETURNING r_g13.*
                       	IF r_g13.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                               	NEXT FIELD z20_moneda
                       	END IF
               	ELSE
                       	LET rm_z20.z20_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(rm_z20.z20_moneda)
				RETURNING r_g13.*
                       	DISPLAY BY NAME rm_z20.z20_moneda
               	END IF
               	DISPLAY r_g13.g13_nombre TO tit_moneda
	AFTER FIELD localidad
		IF localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, localidad)
				RETURNING r_g02.*
			IF r_g02.g02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD localidad
			END IF
			DISPLAY r_g02.g02_nombre TO tit_localidad
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER FIELD z26_codcli
               	IF rm_z26.z26_codcli IS NOT NULL THEN
                       	CALL fl_lee_cliente_general(rm_z26.z26_codcli)
                     		RETURNING r_z01.*
                        IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
                               	NEXT FIELD z26_codcli
                        END IF
			DISPLAY r_z01.z01_nomcli TO tit_nombre_cli
		ELSE
			CLEAR tit_nombre_cli
                END IF
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini < MDY(01, 01, 2003) THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial no puede ser menor a la Fecha de arranque del Sistema.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin < MDY(01, 01, 2003) THEN
				CALL fl_mostrar_mensaje('La Fecha Final no puede ser menor a la Fecha de arranque del Sistema.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD z26_estado
		IF vg_gui = 0 THEN
			IF rm_z26.z26_estado IS NOT NULL THEN
				CALL muestra_estado(rm_z26.z26_estado)
			ELSE
				CLEAR tit_estado
			END IF
		END IF
	AFTER FIELD tipo_fecha
		IF vg_gui = 0 THEN
			IF tipo_fecha IS NOT NULL THEN
				CALL muestra_tipo_fec(tipo_fecha)
			ELSE
				CLEAR tit_tipo_fecha
			END IF
		END IF
	AFTER INPUT
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_fin IS NOT NULL THEN
				IF vm_fecha_ini > vm_fecha_fin THEN
					CALL fl_mostrar_mensaje('La Fecha Inicial debe ser menor a la Fecha Final.','exclamation')
					NEXT FIELD vm_fecha_ini
				END IF
			END IF
		END IF
END INPUT

END FUNCTION



REPORT reporte_cheque_postfechado(abreviacion, fecha_cobro, cliente, referencia,
					banco, ctacte, cheque, estado, valor)
DEFINE abreviacion	LIKE gent003.g03_abreviacion
DEFINE fecha_cobro	LIKE cxct026.z26_fecha_cobro
DEFINE cliente		LIKE cxct001.z01_nomcli
DEFINE referencia     	LIKE cxct026.z26_referencia
DEFINE banco		LIKE gent008.g08_nombre
DEFINE ctacte		LIKE cxct026.z26_num_cta
DEFINE cheque		LIKE cxct026.z26_num_cheque
DEFINE estado		LIKE cxct026.z26_estado
DEFINE valor		LIKE cxct026.z26_valor
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE titulo           VARCHAR(80)
DEFINE usuario		VARCHAR(20)
DEFINE modulo		VARCHAR(20)
DEFINE descr_estado	VARCHAR(10)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE CHEQUES POSTFECHADOS', '80')
		RETURNING titulo
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	IF localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, localidad) RETURNING r_g02.*
	END IF
	CALL fl_lee_moneda(rm_z20.z20_moneda) RETURNING r_g13.*
	IF rm_z26.z26_codcli IS NOT NULL THEN
		CALL fl_lee_cliente_general(rm_z26.z26_codcli) RETURNING r_z01.*
	END IF
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 001, r_g01.g01_razonsocial,
	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 027, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
      	SKIP 1 LINES
	CASE rm_z26.z26_estado
		WHEN 'A'
			LET descr_estado = 'POR COBRAR'
		WHEN 'B'
			LET descr_estado = 'COBRADOS'
		OTHERWISE
			LET descr_estado = 'T O D O S'
	END CASE
	PRINT COLUMN 031, "** ESTADO       : ", descr_estado
	PRINT COLUMN 031, "** MONEDA       : ", rm_z20.z20_moneda, " ",
						r_g13.g13_nombre
	IF vm_fecha_ini IS NOT NULL THEN
		PRINT COLUMN 031, "** FECHA INICIAL: ",
				vm_fecha_ini USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	IF vm_fecha_fin IS NOT NULL THEN
		PRINT COLUMN 031, "** FECHA FINAL  : ",
				vm_fecha_fin USING "dd-mm-yyyy"
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	IF rm_z26.z26_codcli IS NOT NULL THEN
		PRINT COLUMN 031, "** CLIENTE      : ",
				rm_z26.z26_codcli USING "&&&&&&", " ",
				r_z01.z01_nomcli[1, 47] CLIPPED
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	IF localidad IS NOT NULL THEN
		PRINT COLUMN 031, "** LOCALIDAD    : ",
			localidad USING "&&", " ", r_g02.g02_nombre CLIPPED
	ELSE
		PRINT COLUMN 001, 1 SPACES
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
		1 SPACES, TIME,
              COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "AREA NEG.";
	IF tipo_fecha = 'C' THEN
		PRINT COLUMN 013, "FECHA COB.";
	ELSE
		PRINT COLUMN 013, "FECHA ING.";
	END IF
	PRINT COLUMN 025, "NOMBRE DEL CLIENTE",
	      COLUMN 065, "BANCO",
	      COLUMN 087, "CTA. CORRIENTE",
	      COLUMN 104, "No. CHEQUE",
	      COLUMN 121, "VALOR CHEQUE"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, abreviacion CLIPPED,
	      COLUMN 013, fecha_cobro		USING "dd-mm-yyyy",
	      COLUMN 025, cliente[1, 38] CLIPPED,
	      COLUMN 065, banco[1, 20] CLIPPED,
	      COLUMN 087, ctacte CLIPPED,
	      COLUMN 104, cheque CLIPPED,
	      COLUMN 121, valor			USING "#,###,##&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 121, "------------"
	PRINT COLUMN 103, "TOTAL CHEQUES ==> ", SUM(valor) USING "#,###,##&.##";
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION borrar_cabecera()

CLEAR localidad, tit_localidad,z26_estado, z20_moneda, tit_moneda, vm_fecha_ini,
	vm_fecha_fin, z26_codcli, tit_nombre_cli, tipo_fecha
INITIALIZE localidad, rm_z26.*, rm_z20.*, vm_fecha_ini, vm_fecha_fin, tipo_fecha
	TO NULL

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		CHAR(1)

CASE estado
	WHEN 'A'
		DISPLAY 'POR COBRAR' TO tit_estado
	WHEN 'B'
		DISPLAY 'COBRADOS' TO tit_estado
	WHEN 'T'
		DISPLAY 'T O D O S' TO tit_estado
	OTHERWISE
		CLEAR z26_estado, tit_estado
END CASE

END FUNCTION



FUNCTION muestra_tipo_fec(tipo)
DEFINE tipo		CHAR(1)

CASE tipo
	WHEN 'I'
		DISPLAY 'FECHA INGRESO' TO tit_tipo_fecha
	WHEN 'C'
		DISPLAY 'FECHA COBRO'   TO tit_tipo_fecha
	OTHERWISE
		CLEAR tipo_fecha, tit_tipo_fecha
END CASE

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
