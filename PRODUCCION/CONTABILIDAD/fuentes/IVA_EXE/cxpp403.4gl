--------------------------------------------------------------------------------
-- Titulo           : cxpp403.4gl - IMPRESION COMPROBANTE EGRESO DE BANCO
-- Elaboracion      : 31-ene-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cxpp403 BD MODULO COMPANIA LOCALIDAD TIPO_COMP 
--		                     NUM_COMP
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_comp	LIKE ctbt012.b12_num_comp
DEFINE vm_orden		LIKE cxpt024.p24_orden_pago
DEFINE vm_tipo_comp	LIKE cxpt024.p24_tip_contable
DEFINE vm_cod_pago	LIKE cxpt022.p22_tipo_trn   
DEFINE vm_pago_ant      LIKE cxpt022.p22_tipo_trn
DEFINE rm_g08		RECORD LIKE gent008.*
DEFINE rm_g09		RECORD LIKE gent009.*
DEFINE rm_p01		RECORD LIKE cxpt001.*
DEFINE rm_p22		RECORD LIKE cxpt022.*
DEFINE rm_p21           RECORD LIKE cxpt021.*
DEFINE rm_p24		RECORD LIKE cxpt024.*
DEFINE rm_b12		RECORD LIKE ctbt012.*
DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN
DEFINE vm_tot_debito	DECIMAL(14,2)
DEFINE vm_tot_credito	DECIMAL(14,2)
DEFINE vm_num_lineas	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp403.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 6 THEN     -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base      = arg_val(1)
LET vg_modulo    = arg_val(2)
LET vg_codcia    = arg_val(3)
LET vg_codloc    = arg_val(4)
LET vm_tipo_comp = arg_val(5)
LET vm_num_comp  = arg_val(6)
LET vg_proceso   = 'cxpp403'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()

--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
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
	--CALL fgl_winmessage(vg_producto,'No existe comprobante contable.','stop')
	CALL fl_mostrar_mensaje('No existe comprobante contable.','stop')
	EXIT PROGRAM
END IF
IF vm_tipo_comp = 'EG' THEN

INITIALIZE rm_p24.* TO NULL

IF rm_b12.b12_origen = 'A' AND rm_b12.b12_modulo = 'TE' THEN
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
	--CALL fgl_winmessage(vg_producto,'No se ha emitido ningún cheque.','stop')
	CALL fl_mostrar_mensaje('No se ha emitido ningún cheque.','stop')
	EXIT PROGRAM
END IF

END IF

CALL fl_lee_banco_general(rm_g09.g09_banco) RETURNING rm_g08.*

CALL control_main_reporte()

END FUNCTION



FUNCTION validacion_orden_pago()

SELECT * INTO rm_p24.* FROM cxpt024 WHERE p24_compania     = vg_codcia
				      AND p24_tip_contable = vm_tipo_comp
				      AND p24_num_contable = vm_num_comp

IF rm_p24.p24_orden_pago IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Orden de pago no existe.','exclamation')
	CALL fl_mostrar_mensaje('Orden de pago no existe.','exclamation')
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
		--CALL fgl_winmessage(vg_producto,'No se ha generado la transaccion de la emision del cheque.','stop')
		CALL fl_mostrar_mensaje('No se ha generado la transaccion de la emision del cheque.','stop')
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
                --CALL fgl_winmessage(vg_producto,'No se ha generado el pago anticipado de la emision del cheque.','stop')
		CALL fl_mostrar_mensaje('No se ha generado el pago anticipado de la emision del cheque.','stop')
                EXIT PROGRAM
        END IF
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
DEFINE valor_cheque	LIKE ctbt013.b13_valor_base

WHILE TRUE
	LET vm_tot_debito  = 0
	LET vm_tot_credito = 0
	LET vm_num_lineas  = 0
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		EXIT WHILE
	END IF

	DECLARE q_ctbt013 CURSOR FOR
		SELECT 	b13_secuencia, b13_cuenta, 
			b13_glosa, b13_tipo_doc, b13_valor_base 
			 FROM ctbt013
			WHERE b13_compania = vg_codcia
		  	AND b13_tipo_comp  = rm_b12.b12_tipo_comp
		  	AND b13_num_comp   = rm_b12.b12_num_comp
		ORDER BY 1

	IF rm_b12.b12_tipo_comp = 'EG' THEN
		LET vm_top    = 0
		LET vm_left   =	4
		LET vm_right  =	120
		LET vm_bottom =	4
		LET vm_page   = 33
		FOREACH q_ctbt013 INTO r_report.*	
			DECLARE q_g09 CURSOR FOR
				SELECT * FROM gent009
				WHERE g09_compania = vg_codcia
				  AND g09_aux_cont = r_report.cuenta
			OPEN q_g09
			FETCH q_g09
			IF STATUS <> NOTFOUND THEN
				CLOSE q_g09
				FREE q_g09
				LET valor_cheque = r_report.valor_base
				EXIT FOREACH
			END IF
			CLOSE q_g09
			FREE q_g09
		END FOREACH
		START REPORT report_egreso_2 TO PIPE comando	
		FOREACH q_ctbt013 INTO r_report.*	
			OUTPUT TO REPORT report_egreso_2(r_report.*,
								valor_cheque)
		END FOREACH
		FINISH REPORT report_egreso_2
		EXIT WHILE
	ELSE
		LET vm_top    = 0
		LET vm_left   =	2
		LET vm_right  =	120
		LET vm_bottom =	4
		LET vm_page   = 66
		START REPORT report_egreso TO PIPE comando
		FOREACH q_ctbt013 INTO r_report.*
			OUTPUT TO REPORT report_egreso(r_report.*)
		END FOREACH
		FINISH REPORT report_egreso
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



REPORT report_egreso(secuencia, cuenta, glosa, tipo_doc, valor_base)
DEFINE	secuencia	LIKE ctbt013.b13_secuencia
DEFINE	cuenta		LIKE ctbt013.b13_cuenta
DEFINE	glosa		LIKE ctbt013.b13_glosa
DEFINE	tipo_doc	LIKE ctbt013.b13_tipo_doc
DEFINE	valor_base	LIKE ctbt013.b13_valor_base
DEFINE num_ctas		SMALLINT
DEFINE tit_estado	CHAR(10)
DEFINE tit_origen	CHAR(10)
DEFINE r_b04		RECORD LIKE ctbt004.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	3
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CASE rm_b12.b12_estado 
		WHEN 'A'
			LET tit_estado = 'ACTIVO'
		WHEN 'E'
			LET tit_estado = 'ELIMINADO'
		WHEN 'M'
			LET tit_estado = 'MAYORIZADO'
	END CASE
	CASE rm_b12.b12_origen 
		WHEN 'A'
			LET tit_origen = 'AUTOMATICO'
		WHEN 'M'
			LET tit_origen = 'MANUAL'
	END CASE

	CALL fl_lee_subtipo_comprob_contable(vg_codcia, rm_b12.b12_subtipo)
		RETURNING r_b04.*
	CALL fl_lee_moneda(rm_b12.b12_moneda)
		RETURNING r_g13.*
	LET modulo  = "Módulo: Contabilidad"
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 120, 'Página: ', PAGENO USING '&&&'
	PRINT COLUMN 001, modulo,
	      COLUMN 121, UPSHIFT(vg_proceso)
	PRINT COLUMN 1, 'Comprobante: ',
	      COLUMN 21, rm_b12.b12_tipo_comp, '-', 
			fl_justifica_titulo('I', rm_b12.b12_num_comp, 8),
	      COLUMN 64, 'Estado: ',
	      COLUMN 80, tit_estado
	PRINT COLUMN 1, 'Subtipo: ',
	      COLUMN 21, rm_b12.b12_subtipo,'  ', r_b04.b04_nombre
	PRINT COLUMN 1, 'Glosa: ', 
	      COLUMN 21, rm_b12.b12_glosa[1,123]  
	PRINT COLUMN 1, 'Moneda: ',
	      COLUMN 21, r_g13.g13_nombre,
	      COLUMN 64, 'Paridad: ', 
	      COLUMN 80, fl_justifica_titulo('I',rm_b12.b12_paridad,17)
	PRINT COLUMN 1, 'Fecha Proceso: ',
	      COLUMN 21, rm_b12.b12_fec_proceso USING 'dd-mm-yyyy',
	      COLUMN 64, 'Origen: ',
	      COLUMN 80, tit_origen
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 112, usuario

	PRINT COLUMN 1, '=================================================================================================================================='
	PRINT COLUMN 001, 'Cuenta',
	      COLUMN 015, 'Nombre Cuenta',
	      COLUMN 052, 'G l o s a',
	      COLUMN 089, 'TF',                  
	      COLUMN 094, '            Débito',
	      COLUMN 113, '           Crédito'
	
	PRINT COLUMN 1, '=================================================================================================================================='

ON EVERY ROW
	LET vm_num_lineas = vm_num_lineas + 1

	CALL fl_lee_cuenta(vg_codcia, cuenta)
		RETURNING r_b10.*	
	IF valor_base < 0 THEN
		PRINT COLUMN 001, cuenta,
	      	      COLUMN 015, r_b10.b10_descripcion[1,35], 
	      	      COLUMN 052, glosa[1, 35] CLIPPED, 
	      	      COLUMN 089, tipo_doc,
	      	      COLUMN 113, valor_base USING "###,###,###,##&.##"
		IF glosa[36,70] IS NOT NULL OR glosa[36,70] <> ' ' THEN
			PRINT COLUMN 052, glosa[36,70] 
		END IF
		IF glosa[71,90] IS NOT NULL OR glosa[71,90] <> ' ' THEN
			PRINT COLUMN 052, glosa[71,90] 
		END IF
		LET vm_tot_credito = vm_tot_credito + valor_base
	ELSE
		PRINT COLUMN 001, cuenta CLIPPED,
	      	      COLUMN 015, r_b10.b10_descripcion[1,35], 
	      	      COLUMN 052, glosa[1, 35] CLIPPED, 
	      	      COLUMN 089, tipo_doc,
	      	      COLUMN 094, valor_base USING "###,###,###,##&.##"
		IF glosa[36,70] IS NOT NULL OR glosa[36,70] <> ' ' THEN
			PRINT COLUMN 052, glosa[36,70] 
		END IF
		IF glosa[71,90] IS NOT NULL OR glosa[71,90] <> ' ' THEN
			PRINT COLUMN 052, glosa[71,90] 
		END IF
		LET vm_tot_debito = vm_tot_debito + valor_base
	END IF
{
	IF vm_num_lineas > 46 THEN
		NEED 3 LINES 
		PRINT COLUMN 094, '------------------',
	              COLUMN 113, '------------------'
		PRINT COLUMN 094, vm_tot_debito  USING '###,###,###,##&.##',
		      COLUMN 013, vm_tot_credito USING '###,###,###,##&.##'
		LET vm_num_lineas = 0
		SKIP TO TOP OF PAGE
	END IF
}
ON LAST ROW
	NEED 5 LINES 
	PRINT COLUMN 094, '------------------',
	      COLUMN 113,  '------------------'
	PRINT COLUMN 094, vm_tot_debito  USING '###,###,###,##&.##',
	      COLUMN 113, vm_tot_credito USING '###,###,###,##&.##'
	PRINT COLUMN 1, '----------------------------------------------------------------------------------------------------------------------------------'
	SKIP 1 LINES 
	PRINT COLUMN 1, 'Ingresado Por: ', 
	      COLUMN 20, rm_b12.b12_usuario;
	print ASCII escape;
	print ASCII desact_comp 
	
END REPORT




REPORT report_egreso_2(secuencia, cuenta, glosa, tipo_doc, valor_base,
			valor_cheque)
DEFINE	secuencia	LIKE ctbt013.b13_secuencia
DEFINE	cuenta		LIKE ctbt013.b13_cuenta
DEFINE	glosa		LIKE ctbt013.b13_glosa
DEFINE	valor_base	LIKE ctbt013.b13_valor_base
DEFINE valor_cheque	LIKE ctbt013.b13_valor_base
DEFINE	tipo_doc	LIKE ctbt013.b13_tipo_doc
DEFINE tit_estado	CHAR(10)
DEFINE tit_origen	CHAR(10)
DEFINE r_b04		RECORD LIKE ctbt004.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE valor_che_letra1	VARCHAR (100)
DEFINE valor_che_letra2	VARCHAR (100)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	1
	LEFT   MARGIN	3
	RIGHT  MARGIN	132
	BOTTOM MARGIN	4
	PAGE   LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	CASE rm_b12.b12_estado 
		WHEN 'A'
			LET tit_estado = 'ACTIVO'
		WHEN 'E'
			LET tit_estado = 'ELIMINADO'
		WHEN 'M'
			LET tit_estado = 'MAYORIZADO'
	END CASE
	CASE rm_b12.b12_origen 
		WHEN 'A'
			LET tit_origen = 'AUTOMATICO'
		WHEN 'M'
			LET tit_origen = 'MANUAL'
	END CASE

	CALL fl_lee_subtipo_comprob_contable(vg_codcia, rm_b12.b12_subtipo)
		RETURNING r_b04.*
	CALL fl_lee_moneda(rm_b12.b12_moneda)
		RETURNING r_g13.*
	CALL fl_lee_localidad(vg_codcia, vg_codloc)
		RETURNING r_g02.*
	CALL fl_lee_ciudad(r_g02.g02_ciudad)
		RETURNING r_g31.*
	CALL valor_cheque_letras_formato (fl_retorna_letras(rm_b12.b12_moneda,
						valor_cheque))
		RETURNING valor_che_letra1, valor_che_letra2
	--SKIP 1 LINES
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 51, rm_b12.b12_benef_che,
	      COLUMN 110, valor_cheque USING '###,###,###,##&.##'
	SKIP 1 LINES
	PRINT COLUMN 51, fl_justifica_titulo('I', valor_che_letra1, 80) 
	IF valor_che_letra2 IS NULL THEN
		SKIP 2 LINES
	ELSE
		PRINT COLUMN 48, fl_justifica_titulo('I', valor_che_letra2, 80) 
		SKIP 1 LINES
	END IF
	PRINT COLUMN 41, r_g31.g31_nombre, ', ',
	      rm_b12.b12_fec_proceso USING 'dd-mm-yyyy'
	SKIP 11 LINES
	--PRINT COLUMN 116, vm_tipo_comp, '-', vm_num_comp
	--SKIP 3 LINES
	--SKIP 14 LINES
	PRINT COLUMN 1, rg_cia.g01_razonsocial,
	      COLUMN 120, 'Página: ', PAGENO USING '&&&'
	SKIP 1 LINES
	PRINT COLUMN 1, 'Comprobante: ',
	      COLUMN 20, 'EGRESO   ',rm_b12.b12_tipo_comp, '-', 
			fl_justifica_titulo('I', rm_b12.b12_num_comp, 8),
	      COLUMN 64, 'Estado: ',
	      COLUMN 80, tit_estado
	PRINT COLUMN 1, 'Subtipo: ',
	      COLUMN 20, rm_b12.b12_subtipo,'  ', r_b04.b04_nombre
	PRINT COLUMN 1, 'Glosa: ', 
	      COLUMN 20, rm_b12.b12_glosa[1,80]  
	PRINT COLUMN 1, 'Moneda: ',
	      COLUMN 20, r_g13.g13_nombre,
	      COLUMN 64, 'Paridad: ', 
	      COLUMN 80, fl_justifica_titulo('I',rm_b12.b12_paridad,17)
	PRINT COLUMN 1, 'Fecha Proceso: ',
	      COLUMN 20, rm_b12.b12_fec_proceso USING 'dd-mm-yyyy',
	      COLUMN 64, 'Origen: ',
	      COLUMN 80, tit_origen
	PRINT COLUMN 1,  'Beneficiario: ',
	      COLUMN 20, rm_b12.b12_benef_che
	PRINT COLUMN 1,  'Banco: ',
	      COLUMN 20, rm_g08.g08_nombre,
	      COLUMN 64, 'No Cheque: ',
	      COLUMN 80, fl_justifica_titulo('I',rm_b12.b12_num_cheque,10) 
	PRINT COLUMN 1,  'Cuenta: ',
	      COLUMN 20, rm_g09.g09_numero_cta

	PRINT COLUMN 1, '=================================================================================================================================='
	PRINT COLUMN 1, 'Cuenta',
	      COLUMN 15, 'Nombre Cuenta',
	      COLUMN 52, 'Glosa',
	      COLUMN 094, '            Débito',
	      COLUMN 113, '           Crédito'
	
	PRINT COLUMN 1, '=================================================================================================================================='

ON EVERY ROW
	NEED 8 LINES
	CALL fl_lee_cuenta(vg_codcia, cuenta) RETURNING r_b10.*	
	IF valor_base < 0 THEN
		PRINT COLUMN 1, cuenta,
	      	      COLUMN 15, r_b10.b10_descripcion[1,35], 
	      	      COLUMN 52, glosa[1, 41] CLIPPED , 
	      	      COLUMN 113, valor_base USING "###,###,###,##&.##"
		IF glosa[42,82] IS NOT NULL OR glosa[42,82] <> ' ' THEN
			PRINT COLUMN 052, glosa[42,82] 
		END IF
		IF glosa[83,90] IS NOT NULL OR glosa[83,90] <> ' ' THEN
			PRINT COLUMN 052, glosa[83,90] 
		END IF
		LET vm_tot_credito = vm_tot_credito + valor_base
	ELSE
		PRINT COLUMN 1, cuenta CLIPPED,
	      	      COLUMN 15, r_b10.b10_descripcion[1,35], 
	      	      COLUMN 52, glosa[1, 41] CLIPPED, 
	      	      COLUMN 94, valor_base USING "###,###,###,##&.##"
		IF glosa[42,82] IS NOT NULL OR glosa[42,82] <> ' ' THEN
			PRINT COLUMN 052, glosa[42,82] 
		END IF
		IF glosa[83,90] IS NOT NULL OR glosa[83,90] <> ' ' THEN
			PRINT COLUMN 052, glosa[83,90] 
		END IF
		LET vm_tot_debito = vm_tot_debito + valor_base
	END IF

ON LAST ROW
	-- Aqui se debe imprimir el valor del cheque en letras
	SKIP 1 LINES
	PRINT COLUMN 1, fl_justifica_titulo('I', 
				fl_retorna_letras(rm_b12.b12_moneda, 
				valor_base), 130)
	NEED 6 LINES 
	PRINT COLUMN 94, '------------------',
	      COLUMN 113, '------------------'
	PRINT COLUMN 94, vm_tot_debito  USING '###,###,###,##&.##',
	      COLUMN 113, vm_tot_credito USING '###,###,###,##&.##'
	PRINT COLUMN 1, '----------------------------------------------------------------------------------------------------------------------------------'
	SKIP 3 LINES 
	PRINT COLUMN 1, 'Ingresado Por: ', 
	      COLUMN 20, rm_b12.b12_usuario,
	      COLUMN 64, 'Aprobado Por:    ________________________________'
	SKIP 3 LINES
	PRINT COLUMN 64, 'Recibi Conforme: ________________________________';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION valor_cheque_letras_formato (valor_che_letras)
DEFINE valor_che_letras	VARCHAR(200)
DEFINE i,l		SMALLINT
DEFINE vl1		VARCHAR(100)
DEFINE vl2		VARCHAR(100)

INITIALIZE vl1, vl2 TO NULL
LET l = LENGTH (valor_che_letras)
LET vl1 = valor_che_letras
IF l > 80 THEN
	FOR i = l TO 1 STEP -1
		IF (valor_che_letras[i] = ' ') AND (i <= 80) THEN
			LET vl1 = valor_che_letras[1,i]
			LET vl2 = valor_che_letras[i+1,l]
			EXIT FOR
		END IF
	END FOR
END IF
RETURN vl1, vl2

END FUNCTION 
