------------------------------------------------------------------------------
-- Titulo           : ctbp209.4gl - Cierre Anual Contabilidad
-- Elaboracion      : 28-nov-2003
-- Autor            : YEC
-- Ultima Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b00		RECORD LIKE ctbt000.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp209.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN -- Validar # parÃ¡metros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp209'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master_cierre_anual()

END MAIN



FUNCTION control_master_cierre_anual()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE result, i	SMALLINT
DEFINE mayorizado	SMALLINT

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_ctb FROM "../forms/ctbf209_1"
DISPLAY FORM f_ctb
CALL lee_confirmacion()
CALL verificar_descuadre_mayorizacion()
CALL verificar_saldo_cta_utilidad() RETURNING result
BEGIN WORK
IF result = 1 THEN
	CALL genera_diario_fin_ano() RETURNING result
	IF result <> 1 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF 
END IF 
CALL mayorizacion_mes(vg_codcia, rm_b00.b00_moneda_base, rm_b00.b00_anopro,
			 MONTH(rm_b00.b00_fecha_cm))
	RETURNING mayorizado
IF NOT mayorizado THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF 
CALL proceso_cuentas()
UPDATE ctbt000 SET b00_anopro   = b00_anopro + 1,
		   b00_fecha_ca = MDY(12,31,rm_b00.b00_anopro)
	WHERE b00_compania = vg_codcia
COMMIT WORK
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION lee_confirmacion()
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(200)

SELECT * INTO rm_b00.* FROM ctbt000 WHERE b00_compania = vg_codcia 
IF status = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro en ctbt000.', 'stop')
	EXIT PROGRAM
END IF
DISPLAY BY NAME rm_b00.b00_anopro
IF YEAR(rm_b00.b00_fecha_cm) <> rm_b00.b00_anopro THEN
	LET mensaje = 'No coincide ano de ultimo cierre mensual: ',
		       rm_b00.b00_fecha_cm USING 'dd-mm-yyyy', ' ',
                       ' con el ano de proceso: ', 
		       rm_b00.b00_anopro USING '###&' 
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF MONTH(rm_b00.b00_fecha_cm) <> 12 THEN
	CALL fl_mostrar_mensaje('Aun no se ha cerrado Diciembre.', 'stop')
	EXIT PROGRAM
END IF
IF NOT cerrado_modulos() THEN
	EXIT PROGRAM
END IF
CALL fl_hacer_pregunta('Desea ejecutar cierre','No') RETURNING resp
IF resp <> 'Yes' THEN
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION cerrado_modulos()
DEFINE r_a00		RECORD LIKE actt000.*
DEFINE fec_pro_act	DATE

CALL fl_lee_compania_activos(vg_codcia) RETURNING r_a00.*
LET fec_pro_act = MDY(r_a00.a00_mespro, 01, r_a00.a00_anopro) - 1 UNITS DAY
IF rm_b00.b00_fecha_cm <> fec_pro_act THEN
	CALL fl_mostrar_mensaje('No se han cerrado todos los meses en el modulo de ACTIVOS FIJOS.', 'exclamation')
	RETURN 0
END IF
CALL fl_chequeo_mes_proceso_rep(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN 0
END IF
{--
CALL fl_chequeo_mes_proceso_tal(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN 0
END IF
--}
CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN 0
END IF
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN 0
END IF
{--
CALL fl_chequeo_mes_proceso_veh(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN 0
END IF
--}
CALL fl_chequeo_mes_proceso_rol(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION verificar_descuadre_mayorizacion()
DEFINE query		CHAR(700)
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor_db_cr 	DECIMAL(12,2)
DEFINE valor_tran	DECIMAL(12,2)
DEFINE mayorizar 	SMALLINT
DEFINE ano, mes		SMALLINT
DEFINE fecha		DATE
DEFINE mensaje		VARCHAR(200)

FOR mes = 1 TO 12
	SELECT b12_moneda, ctbt013.* FROM ctbt012, ctbt013
		WHERE b12_compania           = vg_codcia
	  	  AND YEAR(b12_fec_proceso)  = rm_b00.b00_anopro
	  	  AND MONTH(b12_fec_proceso) = mes
	  	  AND b12_estado             <> 'E'
	  	  AND b12_compania           = b13_compania
          	  AND b12_tipo_comp          = b13_tipo_comp
          	  AND b12_num_comp           = b13_num_comp
		  INTO TEMP te
	LET campo_db = 'b11_db_mes_', mes USING '&&'
	LET campo_cr = 'b11_cr_mes_', mes USING '&&'
	LET query = 'SELECT b11_cuenta, ', campo_db, ', SUM(b13_valor_base) ',
			'FROM ctbt011, te ',
			'WHERE b11_compania   = b13_compania ',
          		 ' AND b11_ano        = ', rm_b00.b00_anopro,
	  	         ' AND b11_cuenta     = b13_cuenta ',
	  	         ' AND b11_moneda     = b12_moneda ',
	                 ' AND b13_valor_base > 0 ',
		         ' AND b13_cuenta <> "', rm_b00.b00_cuenta_uti, '" ',
	                 'GROUP BY 1,2 ',
			 'HAVING ', campo_db, ' <> SUM(b13_valor_base) ',
		    'UNION ALL ',
	            'SELECT b11_cuenta, ', campo_cr, ', SUM(b13_valor_base) ',
			'FROM ctbt011, te ',
			'WHERE b11_compania   = b13_compania ',
          		 ' AND b11_ano        = ', rm_b00.b00_anopro,
	  	         ' AND b11_cuenta     = b13_cuenta ',
	  	         ' AND b11_moneda     = b12_moneda ',
	                 ' AND b13_valor_base < 0 ',
		         ' AND b13_cuenta <> "', rm_b00.b00_cuenta_uti, '" ',
	                 'GROUP BY 1,2 ',
			 'HAVING ', campo_cr, ' * -1 <> SUM(b13_valor_base) ',
			'ORDER BY 1'
	PREPARE vdb FROM query
	LET mayorizar = 0
	DECLARE q_vdb CURSOR WITH HOLD FOR vdb
	FOREACH q_vdb INTO cuenta, valor_db_cr, valor_tran
		LET mayorizar = 1
		EXIT FOREACH
	END FOREACH
	IF mayorizar THEN
		LET mensaje = 'Remayorice el mes de ', 
			       fl_retorna_nombre_mes(mes), 
			       ' porque esta descuadrado.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		EXIT PROGRAM
	END IF
	DROP TABLE te
END FOR

END FUNCTION



FUNCTION verificar_saldo_cta_utilidad()
DEFINE saldo		DECIMAL(14,2)
DEFINE saldo_c		VARCHAR(20)

CALL fl_obtiene_saldo_contable(vg_codcia, rm_b00.b00_cuenta_uti, 
	rm_b00.b00_moneda_base, MDY(12,31,rm_b00.b00_anopro), 'A')
	RETURNING saldo
IF saldo <> 0 THEN
	{--
	LET saldo_c = saldo USING "--,---,--&.##"
	LET saldo_c = saldo_c USING "-<<<<<<<<&.&&"
	CALL fl_mostrar_mensaje('La cuenta utilidad del ejercicio tiene ' ||
				'saldo de ' || saldo_c ||
				' haga un asiento moviendo dicho '  ||
				'saldo a otra cuenta.', 'stop')
	--}
	RETURN 1
END IF
RETURN 0

END FUNCTION


FUNCTION genera_diario_fin_ano()
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b11		RECORD LIKE ctbt011.*
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b50		RECORD LIKE ctbt050.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE secuencia	LIKE ctbt013.b13_secuencia
DEFINE valor		DECIMAL(16,2)
DEFINE valor_acum	DECIMAL(16,2)
DEFINE fecha		DATE
DEFINE resp		CHAR(6)
DEFINE cuantos		INTEGER

CALL fl_hacer_pregunta('Desea generar contabilizacion para Fin de Anio?','Yes')
        RETURNING resp
IF resp <> 'Yes' THEN
        CALL fl_mostrar_mensaje('No se ha generado contabilizacion.', 'exclamation')
        RETURN 0
END IF
DECLARE q_genera CURSOR FOR
	SELECT * FROM ctbt010
		WHERE b10_compania     = vg_codcia
		  AND b10_cuenta[1,1] >= 4
		  AND b10_nivel       IN
			(SELECT MAX(b01_nivel) FROM ctbt001)
		  AND b10_tipo_cta     = 'R'
		  --AND b10_estado      <> 'B'
		ORDER BY b10_cuenta
OPEN q_genera 
FETCH q_genera 
IF STATUS < 0 THEN
	CALL fl_mostrar_mensaje('Ha ocurrido error de Bloqueo del Maestro de Cuentas, Intentelo nuevamente', 'stop')
	RETURN 0
END IF	
INITIALIZE r_b12.* TO NULL
LET r_b12.b12_compania    = vg_codcia
LET r_b12.b12_tipo_comp   = 'DC'
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
				r_b12.b12_tipo_comp, rm_b00.b00_anopro,
				MONTH(rm_b00.b00_fecha_cm))
IF r_b12.b12_num_comp = '0' OR r_b12.b12_num_comp = '-1' THEN
	RETURN 0
END IF
LET r_b12.b12_estado      = 'A'
LET r_b12.b12_subtipo     = NULL
LET r_b12.b12_glosa       = 'COMPROBANTE GEN. POR CIERRE ANUAL ',
				rm_b00.b00_anopro USING "&&&&"
LET r_b12.b12_benef_che   = NULL
LET r_b12.b12_num_cheque  = NULL
LET r_b12.b12_origen      = 'A'
LET r_b12.b12_moneda      = rm_b00.b00_moneda_base
LET r_b12.b12_paridad     = 1
IF r_b12.b12_moneda <> rg_gen.g00_moneda_base THEN
	CALL fl_lee_factor_moneda(r_b12.b12_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('No hay factor de conversion.','stop')
		RETURN 0
	END IF
	LET r_b12.b12_paridad = r_g14.g14_tasa
END IF	
LET r_b12.b12_fec_proceso = rm_b00.b00_fecha_cm
LET r_b12.b12_fec_reversa = NULL
LET r_b12.b12_tip_reversa = NULL
LET r_b12.b12_num_reversa = NULL
LET r_b12.b12_fec_modifi  = NULL
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES(r_b12.*)
LET secuencia             = 1
LET valor_acum            = 0
FOREACH q_genera INTO r_b10.*
	IF r_b10.b10_estado = 'B' THEN
		SELECT COUNT(*) INTO cuantos
			FROM ctbt013
			WHERE b13_compania          = vg_codcia
			  AND b13_cuenta            = r_b10.b10_cuenta
			  AND YEAR(b13_fec_proceso) = YEAR(rm_b00.b00_fecha_cm)
		IF cuantos = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET fecha = MDY(MONTH(rm_b00.b00_fecha_cm), 1, rm_b00.b00_anopro) +
			1 UNITS MONTH - 1 UNITS DAY
	CALL fl_obtiene_saldo_contable(vg_codcia, r_b10.b10_cuenta,
					rm_b00.b00_moneda_base, fecha, 'A')
		RETURNING valor
	LET valor = valor * (-1)
	CALL inserta_detalle_comp_b13(r_b12.*, secuencia, r_b10.b10_cuenta,
					valor)
	LET secuencia  = secuencia  + 1
	LET valor_acum = valor_acum + valor
END FOREACH
LET valor_acum = valor_acum * (-1)
CALL inserta_detalle_comp_b13(r_b12.*, secuencia, rm_b00.b00_cuenta_uti,
				valor_acum)

INITIALIZE r_b50.* TO NULL
LET r_b50.b50_compania  = r_b12.b12_compania
LET r_b50.b50_tipo_comp = r_b12.b12_tipo_comp
LET r_b50.b50_num_comp  = r_b12.b12_num_comp
LET r_b50.b50_anio      = YEAR(r_b12.b12_fec_proceso)
LET r_b50.b50_usuario   = vg_usuario
LET r_b50.b50_fecing    = CURRENT
INSERT INTO ctbt050 VALUES(r_b50.*)
CALL fl_mostrar_mensaje('Contabilizacion generada Ok. Comprobante ' || r_b12.b12_tipo_comp || '-' || r_b12.b12_num_comp || '.', 'info')
RETURN 1

END FUNCTION



FUNCTION inserta_detalle_comp_b13(r_b12, secuencia, cuenta, valor)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE secuencia	LIKE ctbt013.b13_secuencia
DEFINE cuenta		LIKE ctbt013.b13_cuenta
DEFINE valor		DECIMAL(16,2)
DEFINE r_b13		RECORD LIKE ctbt013.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = secuencia
LET r_b13.b13_cuenta      = cuenta CLIPPED
LET r_b13.b13_tipo_doc    = NULL
--LET r_b13.b13_glosa       = r_b12.b12_glosa CLIPPED
LET r_b13.b13_glosa       = 'COMPROB. GEN. POR CIERRE ANUAL ',
				rm_b00.b00_anopro USING "&&&&"
IF r_b12.b12_moneda = rg_gen.g00_moneda_base THEN
	LET r_b13.b13_valor_base = valor
	LET r_b13.b13_valor_aux  = 0
ELSE
	LET r_b13.b13_valor_base = valor * r_b12.b12_paridad
	LET r_b13.b13_valor_aux  = valor
END IF
LET r_b13.b13_num_concil  = NULL
LET r_b13.b13_filtro      = NULL
LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
LET r_b13.b13_codcli      = NULL
LET r_b13.b13_codprov     = NULL
LET r_b13.b13_pedido      = NULL
INSERT INTO ctbt013 VALUES(r_b13.*)

END FUNCTION



FUNCTION mayorizacion_mes(codcia, moneda, ano, mes)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE moneda		LIKE ctbt012.b12_moneda
DEFINE ano		SMALLINT
DEFINE mes		SMALLINT
DEFINE r_cia		RECORD LIKE ctbt000.*
DEFINE rd		RECORD LIKE ctbt013.*
DEFINE r_sal		RECORD LIKE ctbt011.*
DEFINE tipo_cta		CHAR(1)
DEFINE existe		SMALLINT
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE expr_up		VARCHAR(200)
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE num_ctas		INTEGER
DEFINE num_act		INTEGER
DEFINE tot_db		DECIMAL(15,2)
DEFINE tot_cr		DECIMAL(15,2)
DEFINE num_row		INTEGER

CALL fl_lee_compania_contabilidad(codcia) RETURNING r_cia.*
IF r_cia.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Compañía no esta configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
IF ano < r_cia.b00_anopro THEN 
	CALL fl_mostrar_mensaje('El ano ya esta cerrado', 'exclamation')
	RETURN 0
END IF
IF mes < 1 OR mes > 12 THEN 
	CALL fl_mostrar_mensaje('Mes no esta en el rango de 1 a 12', 'exclamation')
	RETURN 0
END IF
IF moneda IS NULL OR (moneda <> r_cia.b00_moneda_base AND 
	moneda <> r_cia.b00_moneda_aux) THEN
	CALL fl_mostrar_mensaje('Moneda no esta configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
IF r_cia.b00_cuenta_uti IS NULL THEN
	CALL fl_mostrar_mensaje('No esta configurada la cuenta utilidad presente ejercicio.', 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
SELECT * FROM ctbt006 
	WHERE b06_compania = codcia AND 
	      b06_ano      = ano    AND
	      b06_mes      = mes
LET num_row = 0
IF status = NOTFOUND THEN
	INSERT INTO ctbt006 VALUES (codcia, ano, mes, vg_usuario, CURRENT)
	LET num_row = SQLCA.SQLERRD[6]
END IF
ERROR 'Bloqueando maestro de saldos'
LOCK TABLE ctbt011 IN EXCLUSIVE MODE
IF status < 0 THEN
	CALL fl_mostrar_mensaje('No se pudo bloquear en modo exclusivo maestro de saldos. Asegúrese que nadie esta ingresando/modificando comprobantes en el sistema', 'exclamtion')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
LET campo_db = 'b11_db_mes_', mes USING '&&'
LET campo_cr = 'b11_cr_mes_', mes USING '&&'
LET expr_up = 'UPDATE ctbt011 SET ', campo_db, ' = 0, ', 
	                             campo_cr, ' = 0 ' ,
			' WHERE b11_compania = ? AND ',
			'       b11_moneda   = ? AND ',
			'       b11_ano      = ? '
PREPARE up_mesc FROM expr_up
ERROR 'Encerando maestro de saldos'
EXECUTE up_mesc USING codcia, moneda, ano	
DECLARE q_tcomp CURSOR FOR
	SELECT ctbt013.* FROM ctbt012, ctbt013
		WHERE b12_compania           = codcia AND 
		      YEAR(b12_fec_proceso)  = ano    AND
		      MONTH(b12_fec_proceso) = mes    AND
		      b12_estado <> 'E' AND
		      b12_compania           = b13_compania  AND 
		      b12_tipo_comp          = b13_tipo_comp AND 
		      b12_num_comp           = b13_num_comp 
CREATE TEMP table temp_may (	
		te_cuenta 	CHAR(12),
		te_debito	DECIMAL(14,2),
		te_credito	DECIMAL(14,2))
CREATE INDEX i1_temp_may ON temp_may (te_cuenta)
LET num_ctas = 0
LET tot_db = 0
LET tot_cr = 0
FOREACH q_tcomp INTO rd.*
	ERROR 'Procesando cuenta: ', rd.b13_cuenta, '   ', num_ctas
	SELECT b10_tipo_cta INTO tipo_cta FROM ctbt010
		WHERE b10_compania = rd.b13_compania AND 
		      b10_cuenta   = rd.b13_cuenta
	LET num_ctas = num_ctas + 1
	LET debito  = 0
	LET credito = 0
	IF rd.b13_valor_base < 0 THEN
		LET credito = rd.b13_valor_base * -1
	ELSE
		LET debito  = rd.b13_valor_base
	END IF
	IF tipo_cta = 'R' THEN
		CALL fl_genera_niveles_mayorizacion(r_cia.b00_cuenta_uti, debito, credito)
	END IF
	CALL fl_genera_niveles_mayorizacion(rd.b13_cuenta, debito, credito)
END FOREACH
DECLARE q_tmm CURSOR FOR SELECT * FROM temp_may
	ORDER BY te_cuenta DESC
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
LET num_act = 1
FOREACH q_tmm INTO cuenta, debito, credito
	ERROR 'Mayorizando cuenta: ', cuenta, '  ', num_act, '   ',
		debito, ' ', credito
	LET num_act = num_act + 1
	LET existe = 0
	WHILE NOT existe
		DECLARE q_mayc CURSOR FOR
			SELECT * FROM ctbt011
				WHERE b11_compania = codcia AND 
		                      b11_moneda   = moneda AND
		                      b11_ano      = ano    AND
		                      b11_cuenta   = cuenta
			        FOR UPDATE
	        OPEN q_mayc 
		FETCH q_mayc INTO r_sal.*
		IF status = NOTFOUND THEN
			CLOSE q_mayc
			INSERT INTO ctbt011 VALUES (codcia, cuenta,
				moneda, ano,
				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
				0,0,0,0,0)
			IF status < 0 THEN
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('Error al crear registro de saldos', 'exclamation')
				RETURN 0
			END IF
		ELSE
			IF status < 0 THEN
				WHENEVER ERROR STOP
				CALL fl_mostrar_mensaje('Cuenta ' || cuenta || ' esta bloqueada por otro usuario', 'exclamation')
				RETURN 0
			END IF
			LET existe = 1
		END IF
	END WHILE
	LET campo_db = 'b11_db_mes_', mes USING '&&'
	LET campo_cr = 'b11_cr_mes_', mes USING '&&'
	LET expr_up = 'UPDATE ctbt011 SET ', campo_db, ' = ', 
					     campo_db, ' + ?, ',
	                                     campo_cr, ' = ', 
					     campo_cr, ' + ? ',
				' WHERE CURRENT OF q_mayc' 
	PREPARE up_may FROM expr_up
	EXECUTE	up_may USING debito, credito
	IF status < 0 THEN
		WHENEVER ERROR STOP
		CALL fl_mostrar_mensaje('Error al actualizar maestro de saldos de cuenta ' || cuenta, 'exclamation')
		RETURN 0
	END IF
END FOREACH
DROP TABLE temp_may
WHENEVER ERROR CONTINUE
--ERROR 'Actualizando estado de comprobantes mayorizados'
UPDATE ctbt012 SET b12_estado = 'M' 
	WHERE b12_compania           = codcia AND 
	      YEAR(b12_fec_proceso)  = ano    AND
	      MONTH(b12_fec_proceso) = mes    AND
	      b12_estado <> 'E'
IF status < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('Error al actualizar estado de los comprobantes mayorizados ', 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
DELETE FROM ctbt006 WHERE ROWID = num_row
CALL fl_mostrar_mensaje('Mayorizacion termino correctamente. Ok', 'info')
RETURN 1

END FUNCTION



FUNCTION proceso_cuentas()
DEFINE r_b11, rn_b11	RECORD LIKE ctbt011.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE saldo		DECIMAL(14,2)

DECLARE q_mcta CURSOR FOR 
	SELECT * FROM ctbt011
		WHERE b11_compania = vg_codcia AND 
		      b11_moneda   = rm_b00.b00_moneda_base AND
		      b11_ano      = rm_b00.b00_anopro
		ORDER BY b11_cuenta
FOREACH q_mcta INTO r_b11.*
	SELECT * INTO rn_b11.* FROM ctbt011
		WHERE b11_compania = r_b11.b11_compania AND 
		      b11_cuenta   = r_b11.b11_cuenta AND
		      b11_moneda   = r_b11.b11_moneda AND
		      b11_ano      = r_b11.b11_ano + 1
	IF status = NOTFOUND THEN
		LET rn_b11.* = r_b11.*
		LET rn_b11.b11_ano        = r_b11.b11_ano + 1
		LET rn_b11.b11_db_ano_ant = 0
    		LET rn_b11.b11_cr_ano_ant = 0
    		LET rn_b11.b11_db_mes_01  = 0
    		LET rn_b11.b11_db_mes_02  = 0
		LET rn_b11.b11_db_mes_03  = 0
    		LET rn_b11.b11_db_mes_04  = 0
    		LET rn_b11.b11_db_mes_05  = 0
    		LET rn_b11.b11_db_mes_06  = 0
    		LET rn_b11.b11_db_mes_07  = 0
    		LET rn_b11.b11_db_mes_08  = 0
    		LET rn_b11.b11_db_mes_09  = 0
    		LET rn_b11.b11_db_mes_10  = 0
    		LET rn_b11.b11_db_mes_11  = 0
    		LET rn_b11.b11_db_mes_12  = 0
    		LET rn_b11.b11_cr_mes_01  = 0
    		LET rn_b11.b11_cr_mes_02  = 0
    		LET rn_b11.b11_cr_mes_03  = 0
    		LET rn_b11.b11_cr_mes_04  = 0
    		LET rn_b11.b11_cr_mes_05  = 0
    		LET rn_b11.b11_cr_mes_06  = 0
    		LET rn_b11.b11_cr_mes_07  = 0
    		LET rn_b11.b11_cr_mes_08  = 0
    		LET rn_b11.b11_cr_mes_09  = 0
    		LET rn_b11.b11_cr_mes_10  = 0
    		LET rn_b11.b11_cr_mes_11  = 0
    		LET rn_b11.b11_cr_mes_12  = 0
		INSERT INTO ctbt011 VALUES (rn_b11.*)
	END IF
	CALL fl_lee_cuenta(vg_codcia, r_b11.b11_cuenta)
		RETURNING r_b10.*
	IF r_b10.b10_tipo_cta <> 'R' THEN
		CALL fl_obtiene_saldo_contable(vg_codcia, r_b11.b11_cuenta, 
			r_b11.b11_moneda, MDY(12,31,r_b11.b11_ano), 'A')
			RETURNING saldo
		IF saldo >= 0 THEN
			LET rn_b11.b11_db_ano_ant = saldo
		ELSE
			LET saldo = saldo * -1
			LET rn_b11.b11_cr_ano_ant = saldo
		END IF
	ELSE
		LET rn_b11.b11_db_ano_ant = 0
		LET rn_b11.b11_cr_ano_ant = 0
	END IF
	UPDATE ctbt011 SET b11_db_ano_ant = rn_b11.b11_db_ano_ant,
		           b11_cr_ano_ant = rn_b11.b11_cr_ano_ant
		WHERE b11_compania = rn_b11.b11_compania AND 
		      b11_moneda   = rn_b11.b11_moneda AND
		      b11_ano      = rn_b11.b11_ano AND
		      b11_cuenta   = rn_b11.b11_cuenta
END FOREACH 

END FUNCTION
