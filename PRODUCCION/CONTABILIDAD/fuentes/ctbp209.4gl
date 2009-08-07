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
IF num_args() <> 3 THEN -- Validar # parámetros correcto
        CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp209'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master_cierre_anual()

END MAIN



FUNCTION control_master_cierre_anual()
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT

CALL fl_nivel_isolation()
OPEN WINDOW wf AT 3,2 WITH 21 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_ctb FROM "../forms/ctbf209_1"
DISPLAY FORM f_ctb
CALL lee_confirmacion()
CALL verificar_descuadre_mayorizacion()
CALL verificar_saldo_cta_utilidad()
BEGIN WORK
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
        CALL fgl_winmessage(vg_producto, 'No existe registro en ctbt000.','stop')
	EXIT PROGRAM
END IF
DISPLAY BY NAME rm_b00.b00_anopro
IF YEAR(rm_b00.b00_fecha_cm) <> rm_b00.b00_anopro THEN
	LET mensaje = 'No coincide ano de ultimo cierre mensual: ',
		       rm_b00.b00_fecha_cm USING 'dd-mm-yyyy', ' ',
                       ' con el ano de proceso: ', 
		       rm_b00.b00_anopro USING '###&' 
--	CALL fgl_winmessage(mensaje, 'stop')
	CALL fgl_winmessage(vg_producto, mensaje ,'stop')
	EXIT PROGRAM
END IF
IF MONTH(rm_b00.b00_fecha_cm) <> 12 THEN
	CALL fgl_winmessage(vg_producto, 'Aun no se ha cerrado Diciembre.','stop')
	EXIT PROGRAM
END IF

CALL fgl_winquestion(vg_producto,'¿ Desea ejecutar cierre ?','No','Yes|No','question',1) RETURNING resp
IF resp <> 'Yes' THEN
	EXIT PROGRAM
END IF

{
CALL fl_hacer_pregunta('Desea ejecutar cierre','No') RETURNING resp
IF resp <> 'Yes' THEN
	EXIT PROGRAM
END IF
}

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
		CALL fgl_winmessage(vg_producto, mensaje,'stop')
--		CALL fgl_winmessage(mensaje, 'exclamation')
		EXIT PROGRAM
	END IF
	DROP TABLE te
END FOR

END FUNCTION



FUNCTION verificar_saldo_cta_utilidad()
DEFINE saldo		DECIMAL(14,2)

CALL fl_obtiene_saldo_contable(vg_codcia, rm_b00.b00_cuenta_uti, 
	rm_b00.b00_moneda_base, MDY(12,31,rm_b00.b00_anopro), 'A')
	RETURNING saldo
IF saldo <> 0 THEN
	CALL fgl_winmessage(vg_producto, 'La cuenta utilidad del ejercicio tiene saldo, haga un asiento moviendo dicho saldo a otra cuenta.', 'stop')
	EXIT PROGRAM
END IF

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
		      b11_moneda   = r_b11.b11_moneda AND
		      b11_ano      = r_b11.b11_ano + 1 AND
		      b11_cuenta   = r_b11.b11_cuenta
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
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: ' || 
                            vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
