{*
 * Titulo           : cxpp404.4gl - IMPRESION CHEQUE 
 * Elaboracion      : 03-mar-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun cxpp404 BD MODULO COMPANIA LOCALIDAD TIPO_COMP 
 *		                     NUM_COMP
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_comp	LIKE ctbt012.b12_num_comp
DEFINE vm_orden		LIKE cxpt024.p24_orden_pago
DEFINE vm_tipo_comp	LIKE cxpt024.p24_tip_contable
DEFINE vm_cod_pago	LIKE cxpt022.p22_tipo_trn   
DEFINE vm_pago_ant      LIKE cxpt022.p22_tipo_trn

DEFINE rm_g08		RECORD LIKE gent008.*
DEFINE rm_g09		RECORD LIKE gent009.*
DEFINE rm_g100		RECORD LIKE gent100.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_p22		RECORD LIKE cxpt022.*
DEFINE rm_p21       RECORD LIKE cxpt021.*
DEFINE rm_p24		RECORD LIKE cxpt024.*
DEFINE rm_p100		RECORD LIKE cxpt100.*
DEFINE rm_b12		RECORD LIKE ctbt012.*

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN

DEFINE vm_tot_debito	DECIMAL(14,2)
DEFINE vm_tot_credito	DECIMAL(14,2)

DEFINE vm_num_lineas	SMALLINT

DEFINE rm_c40           RECORD LIKE ordt040.*
DEFINE rm_c13           RECORD LIKE ordt013.*
DEFINE rm_c10           RECORD LIKE ordt010.*
DEFINE rm_p02           RECORD LIKE cxpt002.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp404.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN     -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 
        'stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_tipo_comp = arg_val(5)
LET vm_num_comp  = arg_val(6)
LET vg_proceso   = 'cxpp404'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_cod_pago = 'PG' 
LET vm_pago_ant = 'PA'

CALL fl_lee_comprobante_contable(vg_codcia, vm_tipo_comp, vm_num_comp)
	RETURNING rm_b12.*
IF rm_b12.b12_num_comp IS NULL THEN
	CALL fgl_winmessage(vg_producto, 
		'No existe comprobante contable.',
		'stop')
	EXIT PROGRAM
END IF

INITIALIZE rm_p100.* TO NULL
SELECT * INTO rm_p100.*
  FROM cxpt100
 WHERE p100_compania  = rm_b12.b12_compania
   AND p100_tipo_comp = rm_b12.b12_tipo_comp
   AND p100_num_comp  = rm_b12.b12_num_comp
IF rm_p100.p100_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe cheque.', 'stop')
	EXIT PROGRAM
END IF

INITIALIZE rm_p24.* TO NULL
IF rm_b12.b12_origen = 'A' THEN
	CALL validacion_orden_pago()
END IF

INITIALIZE rm_g09.* TO NULL

DECLARE q_cta CURSOR FOR 
	SELECT * FROM gent009 
	    WHERE g09_compania = rm_b12.b12_compania
	      AND g09_aux_cont IN (SELECT b13_cuenta FROM ctbt013
	 			     WHERE b13_compania  = rm_b12.b12_compania
				       AND b13_tipo_comp = rm_b12.b12_tipo_comp
				       AND b13_num_comp  = rm_b12.b12_num_comp
				       AND b13_valor_base < 0) 

OPEN  q_cta
FETCH q_cta INTO rm_g09.*
CLOSE q_cta
FREE  q_cta

IF rm_g09.g09_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No se ha emitido ningún cheque.',
		'stop')
	EXIT PROGRAM
END IF

CALL fl_lee_banco_general(rm_g09.g09_banco) RETURNING rm_g08.*
CALL control_main_reporte()

END FUNCTION



FUNCTION validacion_orden_pago()

SELECT * INTO rm_p24.* FROM cxpt024 WHERE p24_compania     = vg_codcia
				      AND p24_tip_contable = vm_tipo_comp
				      AND p24_num_contable = vm_num_comp

IF rm_p24.p24_orden_pago IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'Orden de pago no existe.',
		'exclamation')
	EXIT PROGRAM
END IF

IF rm_p24.p24_tipo = 'P' THEN
	INITIALIZE rm_p22.* TO NULL
	SELECT * INTO rm_p22.* FROM cxpt022 
		WHERE p22_compania   = vg_codcia
	  	  AND p22_localidad  = vg_codloc
	  	  AND p22_codprov    = rm_p24.p24_codprov
	  	  AND p22_tipo_trn   = vm_cod_pago
	  	  AND p22_moneda     = rm_p24.p24_moneda
	  	  AND p22_tiptrn_elim IS NULL
	  	  AND p22_numtrn_elim IS NULL
	  	  AND p22_orden_pago = rm_p24.p24_orden_pago

	IF rm_p22.p22_num_trn IS NULL THEN
		CALL fgl_winmessage(vg_producto,
			'No se ha generado la transaccion de la emision ' ||
			'del cheque.',
			'stop')
		EXIT PROGRAM
	END IF
ELSE
	INITIALIZE rm_p21.* TO NULL
        SELECT * INTO rm_p21.* FROM cxpt021
                WHERE p21_compania   = vg_codcia
                  AND p21_localidad  = vg_codloc
                  AND p21_codprov    = rm_p24.p24_codprov
                  AND p21_tipo_doc   = vm_pago_ant
                  AND p21_moneda     = rm_p24.p24_moneda
                  AND p21_orden_pago = rm_p24.p24_orden_pago
                                                                                
        IF rm_p21.p21_num_doc IS NULL THEN
                CALL fgl_winmessage(vg_producto,
                        'No se ha generado el pago anticipado de la emision ' ||
                        'del cheque.',
                        'stop')
                EXIT PROGRAM
        END IF
END IF

IF rm_p24.p24_medio_pago <> 'C' THEN
	CALL fgl_winmessage(vg_producto, 'El pago no se realizo por cheque.',
						'stop')
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION control_main_reporte()

DEFINE comando		VARCHAR(100)
DEFINE r_report		RECORD 
	secuencia	LIKE ctbt013.b13_secuencia,
	cuenta		LIKE ctbt013.b13_cuenta,
	glosa		LIKE ctbt013.b13_glosa,
	tipo_doc	LIKE ctbt013.b13_tipo_doc,
	valor_base	LIKE ctbt013.b13_valor_base
	END RECORD 

	LET vm_tot_debito  = 0
	LET vm_tot_credito = 0
	LET vm_num_lineas  = 0
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		RETURN
	END IF

	CALL fl_lee_chequera_cuenta(vg_codcia, rm_p100.p100_banco, rm_p100.p100_numero_cta)
		RETURNING rm_g100.*

	IF rm_g100.g100_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto, 'No hay chequera asignada a esta cuenta.',
							'stop')
		EXIT PROGRAM
	END IF

	DECLARE q_ctbt013 CURSOR FOR
		SELECT 	b13_secuencia, b13_cuenta, 
			b13_glosa, b13_tipo_doc, b13_valor_base 
			 FROM ctbt013
			WHERE b13_compania  = vg_codcia
		  	AND b13_tipo_comp = rm_b12.b12_tipo_comp
		  	AND b13_num_comp  = rm_b12.b12_num_comp
			AND b13_cuenta    = rm_g09.g09_aux_cont
		ORDER BY 1

		LET vm_top    = 0
		LET vm_left   =	2
		LET vm_right  =	120
		LET vm_bottom =	4
		LET Vm_page   = 15

		START REPORT report_egreso TO PIPE comando
		OPEN  q_ctbt013
		FETCH q_ctbt013 INTO r_report.*
		CLOSE q_ctbt013
		FREE  q_ctbt013
		OUTPUT TO REPORT report_egreso(r_report.*)
		FINISH REPORT report_egreso

END FUNCTION



REPORT report_egreso(secuencia, cuenta, glosa, tipo_doc, valor_base)
DEFINE	secuencia	LIKE ctbt013.b13_secuencia
DEFINE	cuenta		LIKE ctbt013.b13_cuenta
DEFINE	glosa		LIKE ctbt013.b13_glosa
DEFINE	tipo_doc	LIKE ctbt013.b13_tipo_doc
DEFINE	valor_base	LIKE ctbt013.b13_valor_base

DEFINE r_g31		RECORD LIKE gent031.*
DEFINE i,long		SMALLINT

DEFINE valletras1	VARCHAR(150)
DEFINE valletras2	VARCHAR(150)
DEFINE indice		INTEGER

DEFINE max_lineas	INTEGER
DEFINE linea_act	INTEGER
DEFINE saltar		INTEGER


OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT
PAGE HEADER
	SKIP rm_g100.g100_posy_benef LINES
	LET max_lineas = 15
	LET linea_act = rm_g100.g100_posy_benef

ON EVERY ROW
	IF valor_base < 0 THEN
		LET valor_base = valor_base * (-1)
	END IF

	PRINT COLUMN rm_g100.g100_posix_benef, rm_b12.b12_benef_che,
		  COLUMN rm_g100.g100_posix_valn,  valor_base USING '#,###,###,##&.&&' 
	LET linea_act = linea_act + 1	  

	CALL fl_retorna_letras(rm_b12.b12_moneda, valor_base) RETURNING valletras1
	LET indice = LENGTH(valletras1 CLIPPED)
	LET long = rm_g100.g100_posfx_vallt2
	IF indice > rm_g100.g100_posfx_vallt1 THEN
		LET indice =  rm_g100.g100_posfx_vallt1 - rm_g100.g100_posix_vallt1
		WHILE TRUE
			IF valletras1[indice] = ' ' THEN
				LET i = indice + 1
				LET valletras2 = valletras1[i, rm_g100.g100_posfx_vallt2]
				LET i = LENGTH(valletras2 CLIPPED) + 1
				EXIT WHILE
			ELSE 
				LET indice = indice - 1
			END IF
		END WHILE
	ELSE 
		LET i = indice + 1
	END IF

	LET saltar = rm_g100.g100_posy_vallt1 - linea_act 
	LET linea_act = rm_g100.g100_posy_vallt1
	IF saltar > 0 THEN
		SKIP saltar LINES
	END IF	
	PRINT COLUMN rm_g100.g100_posix_vallt1, valletras1[1, rm_g100.g100_posfx_vallt1]
	LET linea_act = linea_act + 1	  

	LET saltar = rm_g100.g100_posy_vallt2 - linea_act  
	LET linea_act = rm_g100.g100_posy_vallt2
	IF saltar > 0 THEN
		SKIP saltar LINES
	END IF	
	PRINT COLUMN rm_g100.g100_posix_vallt2, valletras2[1, rm_g100.g100_posfx_vallt2]
	LET linea_act = linea_act + 1	  
											
	CALL fl_lee_ciudad(rg_loc.g02_ciudad) RETURNING r_g31.*
	LET saltar = rm_g100.g100_posy_ciud - linea_act  
	LET linea_act = rm_g100.g100_posy_ciud
	IF saltar > 0 THEN
		SKIP saltar LINES
	END IF	
	PRINT COLUMN rm_g100.g100_posix_ciud, r_g31.g31_nombre CLIPPED, ', ', fl_justifica_titulo('I', fl_retorna_nombre_mes(MONTH(TODAY)), 10) CLIPPED, ' ', DAY(TODAY) USING '&&', ' del ', YEAR(TODAY) USING '&&&&'										 
	LET linea_act = linea_act + 1	  
	SKIP TO TOP OF PAGE

END REPORT


	
FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 
                            'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || 
                            vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 
                            'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_compania <> vg_codcia THEN
	CALL fgl_winmessage(vg_producto, 'Combinación compañía/localidad no ' ||
                            'existe ', 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
