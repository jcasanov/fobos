------------------------------------------------------------------------------
-- Titulo           : ctbp405.4gl - Listado de Movimientos de Cuentas
-- Elaboracion      : 02-ABR-2002
-- Autor            : GVA
-- Formato Ejecucion: fglrun ctbp405 base módulo compañía localidad
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

DEFINE vm_cta_inicial	LIKE ctbt013.b13_cuenta
DEFINE nom_cta_ini	LIKE ctbt010.b10_descripcion
DEFINE nom_cta_fin	LIKE ctbt010.b10_descripcion
DEFINE vm_cta_final	LIKE ctbt013.b13_cuenta

DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE

DEFINE vm_moneda	LIKE gent013.g13_moneda

DEFINE vm_nivel         SMALLINT
DEFINE vm_saldo 	DECIMAL (14,2)

DEFINE rm_c40		RECORD LIKE ordt040.*
DEFINE rm_c13		RECORD LIKE ordt013.*
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_p02		RECORD LIKE cxpt002.*
DEFINE rm_j10		RECORD LIKE cajt010.*
DEFINE rm_g09		RECORD LIKE gent009.*



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp405.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)

LET vg_proceso = 'ctbp405'

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
OPEN FORM f_rep FROM "../forms/ctbf405_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(800)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD LIKE ctbt013.*
DEFINE r_b12	 	RECORD LIKE ctbt012.*
DEFINE r_cheque 	LIKE ctbt012.b12_num_cheque

LET vm_top    = 0
LET vm_left   = 02
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda
LET vm_fecha_fin = TODAY

LET vm_nivel     = 6

WHILE TRUE
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

	LET query = 'SELECT ctbt013.*, ctbt012.*',
			' FROM ctbt012, ctbt013 ',
			'WHERE b12_compania  =',vg_codcia,
			'  AND b12_moneda    ="',vm_moneda,'"',
			'  AND b12_fec_proceso ',
			'BETWEEN "',vm_fecha_ini,'" AND "',vm_fecha_fin, '"',
			'  AND b12_estado <> "E"',
			'  AND b12_compania  = b13_compania',
			'  AND b12_tipo_comp = b13_tipo_comp',
			'  AND b12_num_comp  = b13_num_comp',
			'  AND b13_cuenta BETWEEN "',vm_cta_inicial,'"',
			'  AND "',vm_cta_final,'"',
  			' ORDER BY b13_cuenta, b13_fec_proceso, b12_num_cheque, b12_tipo_comp, b12_num_comp'
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
	START REPORT report_movimientos_ctas TO PIPE comando
	FOREACH q_reporte INTO r_report.*, r_b12.* 
		OUTPUT TO REPORT report_movimientos_ctas(r_report.*, r_b12.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_movimientos_ctas
END WHILE 

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_b10		RECORD LIKE ctbt010.*

INITIALIZE r_b10.* TO NULL

OPTIONS INPUT NO WRAP
LET int_flag = 0
INPUT BY NAME vm_cta_inicial, vm_cta_final, vm_fecha_ini,
	      vm_fecha_fin,   vm_moneda 
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
		IF INFIELD(vm_cta_final) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET vm_cta_final   = r_b10.b10_cuenta	
				DISPLAY BY NAME vm_cta_final
				DISPLAY r_b10.b10_descripcion TO nom_cta_fin
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
		LET int_flag = 0
	AFTER FIELD vm_cta_inicial
		IF vm_cta_inicial IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, vm_cta_inicial) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la cuenta en la Compañía.','exclamation')
				CLEAR nom_cta_ini
				NEXT FIELD vm_cta_inicial
			END IF
			LET vm_cta_inicial = r_b10.b10_cuenta
			LET nom_cta_ini = r_b10.b10_descripcion
			DISPLAY BY NAME vm_cta_inicial, nom_cta_ini
			IF vm_cta_final IS NULL THEN
				LET vm_cta_final = r_b10.b10_cuenta
				LET nom_cta_fin  = r_b10.b10_descripcion
				DISPLAY BY NAME vm_cta_final, nom_cta_fin
				NEXT FIELD vm_cta_final
			END IF
		ELSE
			CLEAR nom_cta_ini
		END IF
	AFTER FIELD vm_cta_final
		IF vm_cta_final IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, vm_cta_final) 
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la cuenta en la Compañía.','exclamation')
				CLEAR nom_cta_fin
				NEXT FIELD vm_cta_final
			ELSE
				LET vm_cta_final   = r_b10.b10_cuenta
				DISPLAY r_b10.b10_descripcion TO nom_cta_fin
				LET nom_cta_fin = r_b10.b10_descripcion
			END IF
		ELSE
			CLEAR nom_cta_fin
		END IF
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD vm_moneda
			ELSE
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER INPUT 
		IF vm_cta_inicial IS NULL THEN
			NEXT FIELD vm_cta_inicial
		END IF
		IF vm_cta_final IS NULL THEN
			NEXT FIELD vm_cta_final
		END IF
		IF vm_fecha_ini IS NULL THEN
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_moneda IS NULL THEN
			NEXT FIELD vm_moneda
		END IF
END INPUT

END FUNCTION



REPORT report_movimientos_ctas(r_b13, r_b12)
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE glosa		CHAR(40)
DEFINE fecha_ini	DATE

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT
PAGE HEADER

	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 26,
		fl_justifica_titulo('C','LISTADO DE MOVIMIENTOS DE CUENTAS',80)

	SKIP 1 LINES

	PRINT COLUMN 1, 'Fecha de Impresión: ',
	      COLUMN 23, TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 119,'Página: ', 
	      COLUMN 127, PAGENO USING '&&&&'
	PRINT COLUMN 1, 'Cuenta Inicial: ', 
	      COLUMN 23, vm_cta_inicial, '  ', nom_cta_ini
	PRINT COLUMN 1, 'Cuenta Final: ', 
	      COLUMN 23, vm_cta_final, '  ', nom_cta_fin
	PRINT COLUMN 1, 'Fecha Inicial: ',
	      COLUMN 23, vm_fecha_ini USING 'dd-mm-yyyy',
	      COLUMN 67, 'Fecha Final: ',
	      COLUMN 81, vm_fecha_fin USING 'dd-mm-yyyy'
	PRINT COLUMN 1, 'Moneda: ',
	      COLUMN 23, rm_g13.g13_nombre
	PRINT COLUMN 1, 'Usuario: ',
	      COLUMN 23, vg_usuario,
	      COLUMN 124, 'CTBP405'

	PRINT '=================================================================================================================================='
	PRINT COLUMN 1,  'TP',
	      COLUMN 4,  'Número',
	      COLUMN 14, 'Fecha',
	      COLUMN 26, 'G l o s a',
	      COLUMN 63, fl_justifica_titulo('D', 'Débito', 18),
	      COLUMN 83, fl_justifica_titulo('D', 'Crédito', 18),
	      COLUMN 103, fl_justifica_titulo('D', 'Saldo', 18)
	PRINT '=================================================================================================================================='

ON EVERY ROW
	LET glosa = r_b13.b13_glosa CLIPPED
	IF r_b12.b12_num_cheque IS NOT NULL THEN
		INITIALIZE rm_g09.* TO NULL 
		DECLARE q_bancos CURSOR FOR
			SELECT * FROM gent009
			 WHERE g09_compania = vg_codcia
			   AND g09_aux_cont = r_b13.b13_cuenta
			OPEN q_bancos
			FETCH q_bancos INTO rm_g09.*
			IF STATUS <> NOTFOUND THEN
			  LET glosa = 'Ch. ', r_b12.b12_num_cheque USING '&&&&#'
				IF r_b12.b12_benef_che IS NOT NULL THEN
					LET glosa = glosa CLIPPED, ' ', 
				    r_b12.b12_benef_che[1,23] CLIPPED
				END IF
--			ELSE
--				LET glosa = glosa CLIPPED, ' ', r_b13.b13_glosa CLIPPED
--OJO
			END IF
	END IF
	IF r_b12.b12_tipo_comp = 'OI' THEN
		INITIALIZE rm_j10.* TO NULL 
		DECLARE q_otros CURSOR FOR
			SELECT * FROM cajt010
			 WHERE j10_compania = vg_codcia
			   AND j10_localidad= vg_codloc
			   AND j10_tip_contable = r_b12.b12_tipo_comp
			   AND j10_num_contable  = r_b12.b12_num_comp 
			OPEN q_otros
			FETCH q_otros INTO rm_j10.*
		        IF STATUS <> NOTFOUND THEN
		          	 LET glosa = rm_j10.j10_nomcli CLIPPED
			 END IF
	CLOSE q_otros
	FREE  q_otros
	END IF
	IF r_b12.b12_tipo_comp = 'DP' OR 'EC' THEN
		INITIALIZE rm_j10.* TO NULL 
		DECLARE q_caja CURSOR FOR
			SELECT * FROM cajt010
			 WHERE j10_compania = vg_codcia
			   AND j10_localidad= vg_codloc
			   AND j10_tip_contable = r_b12.b12_tipo_comp
			   AND j10_num_contable  = r_b12.b12_num_comp 
			OPEN q_caja
			FETCH q_caja INTO rm_j10.*
		        IF STATUS <> NOTFOUND THEN
		          	 LET glosa = rm_j10.j10_referencia CLIPPED
			 END IF
	CLOSE q_caja
	FREE  q_caja
	END IF
	IF r_b12.b12_tipo_comp = 'DO' THEN
		INITIALIZE rm_c40.* TO NULL 
		DECLARE q_diario CURSOR FOR
			SELECT * FROM ordt040 
			 WHERE c40_compania = vg_codcia
--			   AND c40_localidad= vg_codloc
			   AND c40_tipo_comp = 'DO'
                           AND c40_num_comp = r_b12.b12_num_comp
		OPEN q_diario
		FETCH q_diario INTO rm_c40.*
		IF STATUS <> NOTFOUND THEN
			INITIALIZE rm_c13.* TO NULL 
			DECLARE q_recep CURSOR FOR
				SELECT * FROM ordt013 
			  	 WHERE c13_compania = vg_codcia
			  	   AND c13_localidad= rm_c40.c40_localidad
			   	   AND c13_numero_oc= rm_c40.c40_numero_oc
			   	   AND c13_num_recep= rm_c40.c40_num_recep
--display 'RECEPCION : ', rm_c40.c40_localidad, '   ',rm_c40.c40_numero_oc
			OPEN q_recep
			FETCH q_recep INTO rm_c13.*
			IF STATUS <> NOTFOUND THEN
				INITIALIZE rm_c10.* TO NULL 
				DECLARE q_num_prov CURSOR FOR
				SELECT * FROM ordt010 
			  	 WHERE c10_compania = vg_codcia
			  	   AND c10_localidad= rm_c13.c13_localidad
			   	   AND c10_numero_oc= rm_c13.c13_numero_oc
--display 'O/C : ', rm_c13.c13_localidad, '   ',rm_c13.c13_numero_oc
				OPEN q_num_prov
				FETCH q_num_prov INTO rm_c10.*
				IF STATUS <> NOTFOUND THEN
					INITIALIZE rm_p02.* TO NULL 
					DECLARE q_prov CURSOR FOR
					SELECT * FROM cxpt002 
			  	 	 WHERE p02_compania = vg_codcia
					   AND p02_localidad= rm_c13.c13_localidad
					   AND p02_codprov  = rm_c10.c10_codprov
--display 'HOLA ', vg_codcia, ' ', rm_c13.c13_localidad, ' ', rm_c10.c10_codprov
					OPEN q_prov
					FETCH q_prov INTO rm_p02.*
					IF STATUS <> NOTFOUND THEN
			                   INITIALIZE rm_p01.* TO NULL
                                           DECLARE q_cod CURSOR FOR
                                           SELECT * FROM cxpt001	
					    WHERE p01_codprov = rm_c10.c10_codprov
					   OPEN q_cod
					   FETCH q_cod INTO rm_p01.*
					   IF STATUS <> NOTFOUND THEN
				          	 LET glosa = rm_p01.p01_nomprov CLIPPED, ' ', rm_c13.c13_factura CLIPPED
					   END IF
					CLOSE q_cod
					FREE  q_cod
					END IF
					CLOSE q_prov
					FREE  q_prov
				END IF
				CLOSE q_num_prov
				FREE  q_num_prov
			END IF
			CLOSE q_recep
			FREE  q_recep
		END IF
		CLOSE q_diario
		FREE  q_diario
	END IF	
	IF r_b12.b12_tipo_comp = 'DR' THEN
		INITIALIZE rm_c40.* TO NULL 
		DECLARE q_diario1 CURSOR FOR
			SELECT * FROM ordt040 
			 WHERE c40_compania = vg_codcia
--			   AND c40_localidad= vg_codloc
			   AND c40_tipo_comp = 'DR'
                           AND c40_num_comp = r_b12.b12_num_comp
		OPEN q_diario1
		FETCH q_diario1 INTO rm_c40.*
		IF STATUS <> NOTFOUND THEN
			INITIALIZE rm_c13.* TO NULL 
			DECLARE q_recep1 CURSOR FOR
				SELECT * FROM ordt013 
			  	 WHERE c13_compania = vg_codcia
			  	   AND c13_localidad= rm_c40.c40_localidad
			   	   AND c13_numero_oc= rm_c40.c40_numero_oc
			   	   AND c13_num_recep= rm_c40.c40_num_recep
--display 'RECEPCION : ', rm_c40.c40_localidad, '   ',rm_c40.c40_numero_oc
			OPEN q_recep1
			FETCH q_recep1 INTO rm_c13.*
			IF STATUS <> NOTFOUND THEN
				INITIALIZE rm_c10.* TO NULL 
				DECLARE q_num_prov1 CURSOR FOR
				SELECT * FROM ordt010 
			  	 WHERE c10_compania = vg_codcia
			  	   AND c10_localidad= rm_c13.c13_localidad
			   	   AND c10_numero_oc= rm_c13.c13_numero_oc
--display 'O/C : ', rm_c13.c13_localidad, '   ',rm_c13.c13_numero_oc
				OPEN q_num_prov1
				FETCH q_num_prov1 INTO rm_c10.*
				IF STATUS <> NOTFOUND THEN
					INITIALIZE rm_p02.* TO NULL 
					DECLARE q_prov1 CURSOR FOR
					SELECT * FROM cxpt002 
			  	 	 WHERE p02_compania = vg_codcia
					   AND p02_localidad= rm_c13.c13_localidad
					   AND p02_codprov  = rm_c10.c10_codprov
--display 'HOLA ', vg_codcia, ' ', rm_c13.c13_localidad, ' ', rm_c10.c10_codprov
					OPEN q_prov1
					FETCH q_prov1 INTO rm_p02.*
					IF STATUS <> NOTFOUND THEN
			                   INITIALIZE rm_p01.* TO NULL
                                           DECLARE q_cod1 CURSOR FOR
                                           SELECT * FROM cxpt001	
					    WHERE p01_codprov = rm_c10.c10_codprov
					   OPEN q_cod1
					   FETCH q_cod1 INTO rm_p01.*
					   IF STATUS <> NOTFOUND THEN
				          	 LET glosa = rm_p01.p01_nomprov CLIPPED, ' ', rm_c13.c13_factura CLIPPED
					   END IF
					CLOSE q_cod1
					FREE  q_cod1
					END IF
					CLOSE q_prov1
					FREE  q_prov1
				END IF
				CLOSE q_num_prov1
				FREE  q_num_prov1
			END IF
			CLOSE q_recep1
			FREE  q_recep1
		END IF
		CLOSE q_diario1
		FREE  q_diario1
	END IF	

	IF r_b13.b13_valor_base < 0 THEN
		LET vm_saldo = vm_saldo + r_b13.b13_valor_base
		PRINT COLUMN 1,  r_b13.b13_tipo_comp,
	      	      COLUMN 4,  r_b13.b13_num_comp,
	      	      COLUMN 14, r_b13.b13_fec_proceso USING 'dd-mm-yyyy',
	      	      COLUMN 26, glosa,
	      	      COLUMN 63, '0.00' USING '###,###,###,##&.##',
	      	      COLUMN 83, r_b13.b13_valor_base 
				 USING '###,###,###,##&.##',
		      COLUMN 103,  vm_saldo 
				 USING '---,---,---,--&.--'
		LET vm_tot_credito = vm_tot_credito + r_b13.b13_valor_base 
	ELSE
		LET vm_saldo = vm_saldo + r_b13.b13_valor_base
		PRINT COLUMN 1,  r_b13.b13_tipo_comp,
	      	      COLUMN 4,  r_b13.b13_num_comp,
	      	      COLUMN 14, r_b13.b13_fec_proceso USING 'dd-mm-yyyy',
	      	      COLUMN 26, glosa,
	      	      COLUMN 63, r_b13.b13_valor_base 
				 USING '###,###,###,##&.##',
		      COLUMN 83, '0.00' USING '###,###,###,##&.##', 
		      COLUMN 103, vm_saldo 
				 USING '---,---,---,--&.--'
		LET vm_tot_debito = vm_tot_debito + r_b13.b13_valor_base
	END IF

BEFORE GROUP OF r_b13.b13_cuenta
--	display "CUENTA ...... ", r_b13.b13_cuenta
	NEED 3 LINES 
	LET vm_tot_debito  = 0
	LET vm_tot_credito = 0
	CALL fl_lee_cuenta(vg_codcia, r_b13.b13_cuenta) RETURNING r_b10.*
	LET fecha_ini = vm_fecha_ini - 1 
display fecha_ini
	CALL fl_obtiene_saldo_contable(vg_codcia, r_b10.b10_cuenta, 
				       rm_g13.g13_moneda, fecha_ini, 'A')
					RETURNING vm_saldo
	PRINT COLUMN 1,  r_b10.b10_descripcion, ': ', r_b10.b10_cuenta,
	      COLUMN 70, 'Saldo al ', fecha_ini USING 'dd-mm-yyyy', ': ',      
	      COLUMN 103, vm_saldo USING '---,---,---,--&.--'
	
AFTER GROUP OF r_b13.b13_cuenta
	NEED 4 LINES
	PRINT COLUMN 63, '------------------',
	      COLUMN 83, '------------------'
	PRINT COLUMN 63, vm_tot_debito USING '###,###,###,##&.##',
	      COLUMN 83, vm_tot_credito USING '###,###,###,##&.##'
	PRINT COLUMN 1,  '   '

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_b12.*, rm_b13.*, vm_fecha_ini, vm_fecha_fin TO NULL

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
