--------------------------------------------------------------------------------
-- Titulo           : cajp208.4gl - Eliminacion de ingresos a caja 
-- Elaboracion      : 06-mar-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun cajp208 base modulo compania localidad 
--		      [tipo_destino num_destino]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_pagos		LIKE cxct022.z22_tipo_trn
DEFINE vm_anticipo	LIKE cxct021.z21_tipo_doc	
DEFINE vm_otros_ing	LIKE cajt010.j10_tipo_destino

DEFINE vm_efectivo	LIKE cajt001.j01_codigo_pago
DEFINE vm_cheque	LIKE cajt001.j01_codigo_pago

DEFINE vm_ajuste	LIKE cxct022.z22_tipo_trn
DEFINE vm_nota_debito	LIKE cxct020.z20_tipo_doc
DEFINE vm_size_arr	INTEGER
--
-- DEFINE RECORD(S) HERE
--
DEFINE rm_j02		RECORD LIKE cajt002.*
DEFINE rm_j04		RECORD LIKE cajt004.*
DEFINE rm_j10		RECORD LIKE cajt010.*
DEFINE rm_b12		RECORD LIKE ctbt012.*

DEFINE vm_indice  	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE rm_j11 ARRAY[50] OF RECORD 
	forma_pago		LIKE cajt011.j11_codigo_pago, 
	moneda			LIKE cajt011.j11_moneda, 
	cod_bco_tarj		LIKE cajt011.j11_cod_bco_tarj, 
	num_ch_aut		LIKE cajt011.j11_num_ch_aut, 
	num_cta_tarj		LIKE cajt011.j11_num_cta_tarj,
	valor			LIKE cajt011.j11_valor 
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp208.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF

LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cajp208'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea

--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE salir		SMALLINT
DEFINE resp 		CHAR(3)  
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE encontrado	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_208 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_208 FROM '../forms/cajf208_1'
ELSE
        OPEN FORM f_208 FROM '../forms/cajf208_1c'
END IF
DISPLAY FORM f_208
LET vm_max_rows    = 50
LET vm_pagos       = 'PG'
LET vm_anticipo    = 'PA'
LET vm_otros_ing   = 'OI'
LET vm_efectivo    = 'EF'
LET vm_cheque      = 'CH'
LET vm_ajuste      = 'AJ'
--LET vm_nota_debito = 'ND' 
LET vm_nota_debito = 'DI' 

CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario) RETURNING rm_j02.*
IF rm_j02.j02_codigo_caja IS NULL THEN
	CALL fl_mostrar_mensaje('No hay una caja asignada al usuario ' || vg_usuario || '.','stop')
	EXIT PROGRAM
END IF

LET rm_j10.j10_codigo_caja = rm_j02.j02_codigo_caja

MENU 'OPCIONES'
	BEFORE MENU 
		HIDE OPTION 'Eliminar'
	COMMAND KEY('C') 'Consultar'	'Consultar un registro.'
		CALL control_consultar() RETURNING encontrado
		IF encontrado THEN
			SHOW OPTION 'Eliminar'
		ELSE
			HIDE OPTION 'Eliminar'
		END IF
	COMMAND KEY('E') 'Eliminar'	'Elimina el registro corriente.'
		IF rm_j10.j10_tipo_fuente IS NULL THEN
			CALL fl_mensaje_consultar_primero()
			CONTINUE MENU
		END IF
		CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			CALL control_eliminacion()
			HIDE OPTION 'Eliminar'
		END IF
	COMMAND KEY('S') 'Salir'	'Salir del programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consultar()

DEFINE var_rowid	INTEGER

CLEAR FORM
CALL setea_botones()
INITIALIZE rm_j10.*    TO NULL
INITIALIZE rm_j11[1].* TO NULL
LET vm_indice = 1
	
LET rm_j10.j10_codigo_caja = rm_j02.j02_codigo_caja

CALL lee_datos_cabecera()
IF INT_FLAG THEN
	RETURN 0
END IF

INITIALIZE var_rowid TO NULL
SELECT ROWID INTO var_rowid FROM cajt010
	WHERE j10_compania     = vg_codcia
	  AND j10_localidad    = vg_codloc
	  AND j10_tipo_destino = rm_j10.j10_tipo_destino
	  AND j10_num_destino  = rm_j10.j10_num_destino
	  AND j10_tipo_destino IN (vm_pagos, vm_anticipo, vm_otros_ing)
	  AND j10_estado       = 'P'
IF var_rowid IS NULL THEN
	CALL fl_mensaje_consulta_sin_registros()  
	RETURN 0 
END IF

CALL lee_muestra_registro(var_rowid)
RETURN 1 
	
END FUNCTION



FUNCTION lee_datos_cabecera()

DEFINE resp 		CHAR(6)

DEFINE r_j10		RECORD LIKE cajt010.*

INITIALIZE rm_j10.* TO NULL
LET rm_j10.j10_tipo_destino = 'PG'
IF vg_gui = 0 THEN
	CALL muestra_tipo_destino(rm_j10.j10_tipo_destino)
END IF
LET INT_FLAG = 0
INPUT BY NAME rm_j10.j10_tipo_destino, rm_j10.j10_num_destino WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(j10_tipo_destino, j10_num_destino) THEN
			RETURN
		END IF

		LET INT_FLAG = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
{
	ON KEY(F2)
		IF INFIELD(j10_num_destino) THEN
			CALL fl_ayuda_numero_fuente_caja(vg_codcia, vg_codloc, 
							 rm_j10.j10_tipo_fuente)
					RETURNING r_j10.j10_num_fuente,
						  r_j10.j10_nomcli,
						  r_j10.j10_valor 
			IF r_j10.j10_num_fuente IS NOT NULL THEN
				LET rm_j10.j10_num_fuente = r_j10.j10_num_fuente
				DISPLAY BY NAME rm_j10.j10_num_fuente
			END IF
			IF vg_gui = 0 THEN
				CALL muestra_tipo_destino(rm_j10.j10_tipo_destino)
			END IF
		END IF
		LET INT_FLAG = 0
}
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD j10_tipo_destino
		IF vg_gui = 0 THEN
			CALL muestra_tipo_destino(rm_j10.j10_tipo_destino)
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_registro()

DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g13		RECORD LIKE gent013.*

DISPLAY BY NAME rm_j10.j10_areaneg,
		rm_j10.j10_codcli,
		rm_j10.j10_nomcli,
		rm_j10.j10_estado,
		rm_j10.j10_moneda,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario

CALL fl_lee_area_negocio(vg_codcia, rm_j10.j10_areaneg) RETURNING r_g03.*
DISPLAY r_g03.g03_nombre TO n_areaneg

CALL fl_lee_moneda(rm_j10.j10_moneda) RETURNING r_g13.*
DISPLAY r_g13.g13_nombre TO n_moneda

CASE rm_j10.j10_estado
	WHEN 'P'
		DISPLAY 'PROCESADO'  TO n_estado
	WHEN 'E'
		DISPLAY 'ELIMINADO'  TO n_estado
	WHEN 'A'
		DISPLAY 'ACTIVO'     TO n_estado
	WHEN '*'
		DISPLAY 'EN PROCESO' TO n_estado
END CASE

END FUNCTION



FUNCTION calcula_total(num_elm)

DEFINE i		SMALLINT
DEFINE num_elm		SMALLINT

DEFINE total		LIKE cajt011.j11_valor

LET total = 0
FOR i = 1 TO num_elm
	IF rm_j11[i].valor IS NOT NULL THEN
		LET total = total + (rm_j11[i].valor * calcula_paridad(
							   rm_j11[i].moneda,
						           rm_j10.j10_moneda))
	END IF
END FOR 

DISPLAY total TO total_mf

RETURN total

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)

DEFINE moneda_ori	LIKE gent013.g13_moneda
DEFINE moneda_dest	LIKE gent013.g13_moneda
DEFINE paridad		LIKE gent014.g14_tasa       

DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) 
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		--CALL fgl_winmessage(vg_producto,'No existe factor de conversión para esta moneda.','exclamation')
		CALL fl_mostrar_mensaje('No existe factor de conversión para esta moneda.','exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION caja_aperturada(moneda)

DEFINE moneda		LIKE gent013.g13_moneda
DEFINE caja		SMALLINT

LET caja = 0

SELECT COUNT(*) INTO caja FROM cajt005
      	WHERE j05_compania     = rm_j04.j04_compania
          AND j05_localidad    = rm_j04.j04_localidad
          AND j05_codigo_caja  = rm_j04.j04_codigo_caja
          AND j05_fecha_aper   = rm_j04.j04_fecha_aper
          AND j05_secuencia    = rm_j04.j04_secuencia
          AND j05_moneda       = moneda

RETURN caja

END FUNCTION



FUNCTION aperturar_caja(moneda) 

DEFINE caja		SMALLINT
DEFINE moneda		LIKE gent013.g13_moneda

DEFINE r_j05		RECORD LIKE cajt005.*

INITIALIZE r_j05.* TO NULL
        
LET r_j05.j05_compania    = vg_codcia
LET r_j05.j05_localidad   = vg_codloc
LET r_j05.j05_codigo_caja = rm_j04.j04_codigo_caja
LET r_j05.j05_fecha_aper  = rm_j04.j04_fecha_aper
LET r_j05.j05_secuencia   = rm_j04.j04_secuencia
LET r_j05.j05_moneda      = moneda
LET r_j05.j05_ef_apertura = 0
LET r_j05.j05_ch_apertura = 0
LET r_j05.j05_ef_ing_dia  = 0
LET r_j05.j05_ch_ing_dia  = 0
LET r_j05.j05_ef_egr_dia  = 0
LET r_j05.j05_ch_egr_dia  = 0

INSERT INTO cajt005 VALUES (r_j05.*)		
	
RETURN r_j05.*

END FUNCTION



FUNCTION actualiza_acumulados_caja(flag)

DEFINE flag 		CHAR(1)
-- I: actualizacion en incremento
-- D: actualizacion en decremento (se multiplica por menos uno [-1])

DEFINE codigo_pago	LIKE cajt011.j11_codigo_pago
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		LIKE cajt011.j11_valor

DEFINE tot_ing_ch	LIKE cajt005.j05_ch_ing_dia
DEFINE tot_ing_ef	LIKE cajt005.j05_ef_ing_dia
DEFINE r_j05		RECORD LIKE cajt005.*

DECLARE q_cajas_j11 CURSOR FOR
	SELECT j11_codigo_pago, j11_moneda, SUM(j11_valor)
		FROM cajt011
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j11_num_fuente  = rm_j10.j10_num_fuente
		  AND j11_codigo_pago IN (vm_efectivo, vm_cheque)
	GROUP BY j11_codigo_pago, j11_moneda

FOREACH q_cajas_j11 INTO codigo_pago, moneda, valor
	IF flag = 'D' THEN
		LET valor = valor * (-1)
	END IF

	IF NOT caja_aperturada(moneda) THEN
		CALL aperturar_caja(moneda) RETURNING r_j05.* 
		IF r_j05.j05_moneda IS NULL THEN
			ROLLBACK WORK
			--CALL fgl_winmessage(vg_producto,'No se pudo aperturar la caja en la moneda ' || moneda CLIPPED || '.','stop') 
			CALL fl_mostrar_mensaje('No se pudo aperturar la caja en la moneda ' || moneda CLIPPED || '.','stop') 
			EXIT PROGRAM
		END IF
	END IF

	INITIALIZE tot_ing_ef, tot_ing_ch TO NULL
	WHENEVER ERROR CONTINUE
	SET LOCK MODE TO WAIT 3
	DECLARE q_caja_j05 CURSOR FOR
		SELECT j05_ef_ing_dia, j05_ch_ing_dia
			FROM cajt005 
			WHERE j05_compania    = rm_j04.j04_compania
			  AND j05_localidad   = rm_j04.j04_localidad
			  AND j05_codigo_caja = rm_j04.j04_codigo_caja
			  AND j05_fecha_aper  = rm_j04.j04_fecha_aper
			  AND j05_secuencia   = rm_j04.j04_secuencia
			  AND j05_moneda      = moneda
		FOR UPDATE OF j05_ef_ing_dia, j05_ch_ing_dia
	OPEN  q_caja_j05
	FETCH q_caja_j05 INTO tot_ing_ef, tot_ing_ch
	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR STOP

	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		EXIT PROGRAM
	END IF


	IF codigo_pago = vm_efectivo THEN
		LET tot_ing_ef = tot_ing_ef + valor
	ELSE
		LET tot_ing_ch = tot_ing_ch + valor
	END IF

	UPDATE cajt005 SET j05_ef_ing_dia = tot_ing_ef,
	    		   j05_ch_ing_dia = tot_ing_ch
		WHERE CURRENT OF q_caja_j05
	
	CLOSE q_caja_j05
	FREE  q_caja_j05
END FOREACH
FREE q_cajas_j11

END FUNCTION



FUNCTION actualiza_acumulados_tipo_transaccion(flag)

DEFINE flag 		CHAR(1)
-- I: actualizacion en incremento
-- D: actualizacion en decremento (se multiplica por menos uno [-1])

DEFINE codigo_pago	LIKE cajt011.j11_codigo_pago
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		LIKE cajt013.j13_valor

DEFINE r_j13		RECORD LIKE cajt013.*

DECLARE q_cajas_j13 CURSOR FOR
	SELECT j11_codigo_pago, j11_moneda, SUM(j11_valor)
		FROM cajt011
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j11_num_fuente  = rm_j10.j10_num_fuente
	GROUP BY j11_codigo_pago, j11_moneda

FOREACH q_cajas_j13 INTO codigo_pago, moneda, valor
	IF flag = 'D' THEN
		LET valor = valor * (-1)
	END IF

	INITIALIZE r_j13.* TO NULL
	SET LOCK MODE TO WAIT 3
	WHENEVER ERROR CONTINUE
		DECLARE q_j13 CURSOR FOR 
			SELECT * FROM cajt013
				WHERE j13_compania     = vg_codcia
				  AND j13_localidad    = vg_codloc
				  AND j13_codigo_caja  = rm_j02.j02_codigo_caja
				  AND j13_fecha        = TODAY
				  AND j13_moneda       = moneda
				  AND j13_trn_generada = rm_j10.j10_tipo_destino
				  AND j13_codigo_pago  = codigo_pago
			FOR UPDATE
	OPEN  q_j13
	FETCH q_j13 INTO r_j13.*
	WHENEVER ERROR STOP
	
	IF STATUS < 0 THEN
		SET LOCK MODE TO NOT WAIT
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'No se pueden actualizar los acumulados.','exclamation')
		CALL fl_mostrar_mensaje('No se pueden actualizar los acumulados.','exclamation')
		EXIT PROGRAM
	END IF

	IF STATUS = NOTFOUND THEN
		-- El registro no existe, hay que grabarlo
		LET r_j13.j13_compania     = vg_codcia
		LET r_j13.j13_localidad    = vg_codloc
		LET r_j13.j13_codigo_caja  = rm_j02.j02_codigo_caja
		LET r_j13.j13_fecha        = TODAY
		LET r_j13.j13_moneda       = moneda
		LET r_j13.j13_trn_generada = rm_j10.j10_tipo_destino
		LET r_j13.j13_codigo_pago  = codigo_pago
		LET r_j13.j13_valor        = valor
	
		INSERT INTO cajt013 VALUES(r_j13.*)
	ELSE
		UPDATE cajt013 SET j13_valor = j13_valor + valor
			WHERE CURRENT OF q_j13
	END IF
	CLOSE q_j13
	FREE  q_j13
	SET LOCK MODE TO NOT WAIT
END FOREACH

END FUNCTION



FUNCTION actualiza_cheques_postfechados(estado)

DEFINE estado		CHAR(1)

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
DECLARE q_che_post CURSOR FOR
	SELECT z26_estado FROM cxct026
		WHERE EXISTS (SELECT z26_compania, z26_localidad, z26_codcli,
			             z26_banco,    z26_num_cta,   z26_num_cheque
	  			FROM cajt011
	  			WHERE j11_compania    = vg_codcia
	  		  	  AND j11_localidad   = vg_codloc
	  			  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
	  			  AND j11_num_fuente  = rm_j10.j10_num_fuente
	  			  AND j11_codigo_pago = vm_cheque
	  			  --AND j11_protestado  = 'N'
	  			  AND z26_compania    = j11_compania
	  			  AND z26_localidad   = j11_localidad
	  			  AND z26_codcli      = rm_j10.j10_codcli
	  			  AND z26_banco       = j11_cod_bco_tarj
	  			  AND z26_num_cta     = j11_num_cta_tarj
	  			  AND z26_num_cheque  = j11_num_ch_aut
	  			  AND z26_estado     <> estado)
	FOR UPDATE
OPEN  q_che_post
WHILE TRUE
	FETCH q_che_post 
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	UPDATE cxct026 SET z26_estado = estado WHERE CURRENT OF q_che_post
END WHILE
SET LOCK MODE TO NOT WAIT

END FUNCTION



FUNCTION setea_botones()

--#DISPLAY 'FP'			TO 	bt_codigo_pago
--#DISPLAY 'Mon'			TO 	bt_moneda
--#DISPLAY 'Bco/Tarj'		TO 	bt_bco_tarj
--#DISPLAY 'Nro. Che./Aut.'	TO 	bt_che_aut
--#DISPLAY 'Nro. Cta./Tarj.'	TO 	bt_cta_tarj
--#DISPLAY 'Valor'			TO 	bt_valor

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row 		INTEGER

SELECT * INTO rm_j10.* FROM cajt010 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid', row
END IF

DISPLAY BY NAME rm_j10.j10_tipo_destino,
		rm_j10.j10_num_destino,
		rm_j10.j10_areaneg,
		rm_j10.j10_codcli,
		rm_j10.j10_nomcli,
		rm_j10.j10_estado,
		rm_j10.j10_moneda,
		rm_j10.j10_fecha_pro,
		rm_j10.j10_usuario
	      	
IF vg_gui = 0 THEN
	CALL muestra_tipo_destino(rm_j10.j10_tipo_destino)
END IF
CALL muestra_registro()
CALL muestra_detalle()

END FUNCTION



FUNCTION muestra_detalle()

DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE filas_pant	SMALLINT

DEFINE dummy		LIKE cajt011.j11_valor

CALL retorna_arreglo()
LET filas_pant = vm_size_arr
FOR i = 1 TO filas_pant
	CLEAR ra_j11[i].*
END FOR

DECLARE q_detalle CURSOR FOR
	SELECT j11_codigo_pago,  j11_moneda, j11_cod_bco_tarj, j11_num_ch_aut, 
	       j11_num_cta_tarj, j11_valor 
		FROM cajt011
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j11_num_fuente  = rm_j10.j10_num_fuente

LET i = 1
FOREACH q_detalle INTO rm_j11[i].*
	LET i = i + 1
	IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
LET vm_indice = i

IF i > 0 THEN
	CALL calcula_total(i) RETURNING dummy
	CALL set_count(i)
ELSE
	--CALL fgl_winmessage(vg_producto,'No hay detalle de forma de pago.','exclamation')
	CALL fl_mostrar_mensaje('No hay detalle de forma de pago.','exclamation')
	EXIT PROGRAM
END IF

FOR j = 1 TO filas_pant
	DISPLAY rm_j11[j].* TO ra_j11[j].*
	IF j >= i THEN
		EXIT FOR
	END IF
END FOR

END FUNCTION



FUNCTION control_eliminacion()

DEFINE resp    		CHAR(6)
DEFINE done 		SMALLINT

DEFINE tot_egr_ch	DECIMAL(12,2)
DEFINE query		CHAR(700)

DEFINE num_fuente 	LIKE cajt010.j10_num_fuente

LET int_flag = 0
SELECT * INTO rm_j10.* FROM cajt010 
	WHERE j10_compania     = rm_j10.j10_compania
	  AND j10_localidad    = rm_j10.j10_localidad
	  AND j10_tipo_fuente  = rm_j10.j10_tipo_fuente
	  AND j10_num_fuente   = rm_j10.j10_num_fuente

IF rm_j10.j10_estado = 'E' THEN
	--CALL fgl_winmessage(vg_producto,'Este registro ya ha sido eliminado.','exclamation')
	CALL fl_mostrar_mensaje('Este registro ya ha sido eliminado.','exclamation')
	RETURN
END IF

IF DATE(rm_j10.j10_fecha_pro) <> TODAY THEN
	--CALL fgl_winmessage(vg_producto,'Solo puede eliminar ingresos realizados hoy.','exclamation')
	CALL fl_mostrar_mensaje('Solo puede eliminar ingresos realizados hoy.','exclamation')
	RETURN
END IF

INITIALIZE rm_j04.* TO NULL
SELECT * INTO rm_j04.* FROM cajt004
	WHERE j04_compania    = vg_codcia
	  AND j04_localidad   = vg_codloc
	  AND j04_codigo_caja = rm_j02.j02_codigo_caja
	  AND j04_fecha_aper  = TODAY
	  AND j04_secuencia   = (SELECT MAX(j04_secuencia) 
	  			FROM cajt004
  				WHERE j04_compania    = vg_codcia
  				  AND j04_localidad   = vg_codloc
  				  AND j04_codigo_caja = rm_j02.j02_codigo_caja
  				  AND j04_fecha_aper  = TODAY)
IF STATUS = NOTFOUND THEN 
	--CALL fgl_winmessage(vg_producto,'La caja no está aperturada.','exclamation')
	CALL fl_mostrar_mensaje('La caja no está aperturada.','exclamation')
	EXIT PROGRAM
END IF

IF NOT caja_aperturada(rm_j10.j10_moneda) THEN
	--CALL fgl_winmessage(vg_producto,'No puede eliminar ingresos de una caja cerrada.','exclamation')
	CALL fl_mostrar_mensaje('No puede eliminar ingresos de una caja cerrada.','exclamation')
	RETURN
END IF

	CASE rm_j10.j10_tipo_fuente
		WHEN 'PV'
		LET query = 'SELECT ctbt012.* FROM veht050, ctbt012 ',
			    ' WHERE v50_compania  = ', vg_codcia,
			    '   AND v50_localidad = ', vg_codloc,
			    '   AND v50_cod_tran  = "', rm_j10.j10_tipo_destino,
			    '"  AND v50_num_tran  = ', rm_j10.j10_num_destino,
			    '   AND b12_compania  = v50_compania ',
			    '   AND b12_tipo_comp = v50_tipo_comp',
			    '   AND b12_num_comp  = v50_num_comp '
		WHEN 'PR'
		LET query = 'SELECT ctbt012.* FROM rept040, ctbt012 ',
			    ' WHERE r40_compania  = ', vg_codcia,
			    '   AND r40_localidad = ', vg_codloc,
			    '   AND r40_cod_tran  = "', rm_j10.j10_tipo_destino,
			    '"  AND r40_num_tran  = ', rm_j10.j10_num_destino,
			    '   AND b12_compania  = r40_compania ',
			    '   AND b12_tipo_comp = r40_tipo_comp',
			    '   AND b12_num_comp  = r40_num_comp '
		WHEN 'OT'
		LET query = 'SELECT ctbt012.* FROM talt050, ctbt012 ',
			    ' WHERE t50_compania  = ', vg_codcia,
			    '   AND t50_localidad = ', vg_codloc,
			    '   AND t50_orden     = ', rm_j10.j10_num_fuente,
			    '   AND t50_factura   = ', rm_j10.j10_num_destino,
			    '   AND b12_compania  = t50_compania ',
			    '   AND b12_tipo_comp = t50_tipo_comp',
			    '   AND b12_num_comp  = t50_num_comp '
		WHEN 'SC'
		LET query = 'SELECT ctbt012.* FROM cxct040, ctbt012 ',
			    ' WHERE z40_compania  = ', vg_codcia,
			    '   AND z40_localidad = ', vg_codloc,
			    '   AND z40_codcli    = ', rm_j10.j10_codcli,
			    '   AND z40_tipo_doc  = "', rm_j10.j10_tipo_destino,
			    '"  AND z40_num_doc   = ', rm_j10.j10_num_destino,
			    '   AND b12_compania  = z40_compania ',
			    '   AND b12_tipo_comp = z40_tipo_comp',
			    '   AND b12_num_comp  = z40_num_comp '	
		WHEN 'OI'
		LET query = 'SELECT * FROM ctbt012 ',
			    ' WHERE b12_compania  = ', vg_codcia,
			    '   AND b12_tipo_comp = "', rm_j10.j10_tip_contable,
			    '"  AND b12_num_comp  = ', rm_j10.j10_num_contable
	END CASE
	PREPARE stmnt3 FROM query
	DECLARE q_b12 CURSOR FOR stmnt3
	OPEN  q_b12
	FETCH q_b12 INTO rm_b12.*
	CLOSE q_b12
	FREE  q_b12
	IF rm_b12.b12_compania IS NOT NULL THEN	
		CALL fl_mayoriza_comprobante(vg_codcia, rm_b12.b12_tipo_comp,
				     	rm_b12.b12_num_comp, 'D')	
	END IF

	BEGIN WORK
	SET LOCK MODE TO WAIT 10
	WHENEVER ERROR CONTINUE
	DECLARE q_del CURSOR FOR 
		SELECT * FROM cajt010 
			WHERE j10_compania     = rm_j10.j10_compania
			  AND j10_localidad    = rm_j10.j10_localidad
			  AND j10_tipo_fuente  = rm_j10.j10_tipo_fuente
			  AND j10_num_fuente   = rm_j10.j10_num_fuente
		  	  AND j10_tipo_destino = rm_j10.j10_tipo_destino
		  	  AND j10_num_destino  = rm_j10.j10_num_destino
	  	  	  AND j10_estado       = 'P'
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_j10.*
	IF status = NOTFOUND THEN
		SET LOCK MODE TO NOT WAIT 
		ROLLBACK WORK
		--CALL fgl_winmessage(vg_producto,'No se encontró registro a bloquear, intente más tarde.','exclamation')
		CALL fl_mostrar_mensaje('No se encontró registro a bloquear, intente más tarde.','exclamation')
		RETURN
	END IF
	IF status < 0 THEN
		WHENEVER ERROR STOP
		SET LOCK MODE TO NOT WAIT 
		CALL fl_mensaje_bloqueo_otro_usuario()
		ROLLBACK WORK
		RETURN
	END IF
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT 

	IF rm_j10.j10_tipo_fuente = 'SC' THEN
		CALL actualiza_cheques_postfechados('A')
	END IF
	CALL actualiza_acumulados_caja('D')
	CALL actualiza_acumulados_tipo_transaccion('D')
	CALL elimina_comprobante_contable()

	CASE rm_j10.j10_tipo_destino
		WHEN vm_pagos
			LET done = proceso_elimina_pago_factura(rm_j10.*)
		WHEN vm_anticipo
			LET done = proceso_elimina_pago_anticipo(rm_j10.*)
		IF NOT done THEN
			ROLLBACK WORK
			RETURN
		END IF
	END CASE	
	IF vg_gui = 0 THEN
		CALL muestra_tipo_destino(rm_j10.j10_tipo_destino)
	END IF

	UPDATE cajt010 SET j10_estado = 'E' WHERE CURRENT OF q_del
	IF rm_j10.j10_codcli IS NOT NULL THEN	
		CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc,
						rm_j10.j10_codcli)
	END IF
	DELETE FROM cajt014
		WHERE j14_compania    = rm_j10.j10_compania
		  AND j14_localidad   = rm_j10.j10_localidad
		  AND j14_tipo_fuente = rm_j10.j10_tipo_fuente
		  AND j14_num_fuente  = rm_j10.j10_num_fuente
	COMMIT WORK
	CLEAR FORM
	LET int_flag = 0 
	INITIALIZE rm_j10.* TO NULL
	CALL setea_botones()
	CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION elimina_comprobante_contable()

SET LOCK MODE TO WAIT 10
WHENEVER ERROR CONTINUE
DECLARE q_ctb CURSOR FOR 
	SELECT * FROM ctbt012
		WHERE b12_compania  = rm_b12.b12_compania
		  AND b12_tipo_comp = rm_b12.b12_tipo_comp
		  AND b12_num_comp  = rm_b12.b12_num_comp
		FOR UPDATE

OPEN  q_ctb
FETCH q_ctb INTO rm_b12.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No se pudo eliminar el comprobante contable, porque está bloqueado por otro usuario.','stop')
	CALL fl_mostrar_mensaje('No se pudo eliminar el comprobante contable, porque está bloqueado por otro usuario.','stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP

WHILE (STATUS <> NOTFOUND) 
	UPDATE ctbt012 SET b12_estado = 'E' WHERE CURRENT OF q_ctb
	
	INITIALIZE rm_b12.* TO NULL
	FETCH q_ctb INTO rm_b12.*
END WHILE
CLOSE q_ctb
FREE  q_ctb
SET LOCK MODE TO NOT WAIT

END FUNCTION



FUNCTION proceso_elimina_pago_factura(r_j10)

DEFINE done 		SMALLINT
DEFINE intentar		SMALLINT
DEFINE orden   		SMALLINT
DEFINE tipo_doc		LIKE cxct020.z20_tipo_doc
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE div_doc		LIKE cxct020.z20_dividendo
DEFINE val_cap		LIKE cxct020.z20_saldo_cap
DEFINE val_int		LIKE cxct020.z20_saldo_int
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE r_j10		RECORD LIKE cajt010.*

LET done     = 1
LET intentar = 1

INITIALIZE r_z22.* TO NULL
LET r_z22.z22_compania   = r_j10.j10_compania 
LET r_z22.z22_localidad  = r_j10.j10_localidad
LET r_z22.z22_codcli     = r_j10.j10_codcli
LET r_z22.z22_tipo_trn   = vm_ajuste    
LET r_z22.z22_num_trn    = fl_actualiza_control_secuencias(r_j10.j10_compania,
				r_j10.j10_localidad, 'CO', 'AA', vm_ajuste)
LET r_z22.z22_areaneg    = r_j10.j10_areaneg
LET r_z22.z22_referencia = 'ELIMINACION: ', r_j10.j10_tipo_destino,
			   '-', r_j10.j10_num_destino
LET r_z22.z22_fecha_emi  = TODAY
LET r_z22.z22_moneda     = r_j10.j10_moneda 
LET r_z22.z22_paridad    = calcula_paridad(r_j10.j10_moneda, 
					   rg_gen.g00_moneda_base) 
LET r_z22.z22_tasa_mora  = 0
LET r_z22.z22_total_cap  = 0    
LET r_z22.z22_total_int  = 0  
LET r_z22.z22_total_mora = 0 
LET r_z22.z22_origen     = 'A' 
LET r_z22.z22_usuario    = vg_usuario    
LET r_z22.z22_fecing     = CURRENT
INSERT INTO cxct022 VALUES(r_z22.*)

DECLARE q_aj1 CURSOR FOR 
	SELECT z23_tipo_doc, z23_num_doc, z23_div_doc,
               SUM(z23_valor_cap), SUM(z23_valor_int)
                FROM cxct022, cxct023
                WHERE z22_compania   = r_j10.j10_compania
                  AND z22_localidad  = r_j10.j10_localidad
                  AND z22_codcli     = r_j10.j10_codcli      
		  AND z22_tipo_trn   = r_j10.j10_tipo_destino
		  AND z22_num_trn    = r_j10.j10_num_destino
                  AND z23_compania   = z22_compania
                  AND z23_localidad  = z22_localidad
                  AND z23_codcli     = z22_codcli
                  AND z23_tipo_trn   = z22_tipo_trn
                  AND z23_num_trn    = z22_num_trn
                GROUP BY z23_tipo_doc, z23_num_doc, z23_div_doc

LET orden = 1
FOREACH q_aj1 INTO tipo_doc, num_doc, div_doc, val_cap, val_int 
	LET val_cap = val_cap * (-1)
	LET val_int = val_int * (-1)
	
	LET r_z22.z22_total_cap = r_z22.z22_total_cap + val_cap
	LET r_z22.z22_total_int = r_z22.z22_total_int + val_int

	CALL fl_lee_documento_deudor_cxc(r_j10.j10_compania, 
					 r_j10.j10_localidad,
					 r_j10.j10_codcli,
					 tipo_doc, num_doc,
					 div_doc) RETURNING r_z20.*

	INITIALIZE r_z23.* TO NULL
	LET r_z23.z23_compania   = r_z22.z22_compania  
	LET r_z23.z23_localidad  = r_z22.z22_localidad     
	LET r_z23.z23_codcli     = r_z22.z22_codcli     
	LET r_z23.z23_tipo_trn   = r_z22.z22_tipo_trn    
	LET r_z23.z23_num_trn    = r_z22.z22_num_trn   
	LET r_z23.z23_orden      = orden
	LET orden = orden + 1  
	LET r_z23.z23_areaneg    = r_z22.z22_areaneg
	LET r_z23.z23_tipo_doc   = tipo_doc 
	LET r_z23.z23_num_doc    = num_doc
	LET r_z23.z23_div_doc    = div_doc
	LET r_z23.z23_valor_cap  = val_cap   
	LET r_z23.z23_valor_int  = val_int  
	LET r_z23.z23_valor_mora = 0 
	LET r_z23.z23_saldo_cap  = r_z20.z20_saldo_cap 
	LET r_z23.z23_saldo_int  = r_z20.z20_saldo_int
	INSERT INTO cxct023 VALUES (r_z23.*)
	
	INITIALIZE r_doc.* TO NULL
	SET LOCK MODE TO WAIT 5
	WHENEVER ERROR CONTINUE
	DECLARE q_z20 CURSOR FOR
		SELECT * FROM cxct020
			WHERE z20_compania  = r_j10.j10_compania
			  AND z20_localidad = r_j10.j10_localidad
			  AND z20_codcli    = r_j10.j10_codcli
			  AND z20_tipo_doc  = tipo_doc
			  AND z20_num_doc   = num_doc
			  AND z20_dividendo = div_doc
		FOR UPDATE
	OPEN  q_z20 
	FETCH q_z20 INTO r_doc.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		SET LOCK MODE TO NOT WAIT
		--CALL fgl_winmessage(vg_producto,'No se pudo actualizar documentos.','exclamation')
		CALL fl_mostrar_mensaje('No se pudo actualizar documentos.','exclamation')
		LET done = 0
		EXIT FOREACH
	END IF
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT

	UPDATE cxct020 SET z20_saldo_cap = z20_saldo_cap + val_cap,
			   z20_saldo_int = z20_saldo_int + val_int
		WHERE CURRENT OF q_z20
	CLOSE q_z20
	FREE  q_z20
END FOREACH
FREE q_aj1

UPDATE cxct022 SET * = r_z22.* 
	WHERE z22_compania  = r_z22.z22_compania
	  AND z22_localidad = r_z22.z22_localidad
	  AND z22_codcli    = r_z22.z22_codcli
	  AND z22_tipo_trn  = r_z22.z22_tipo_trn
	  AND z22_num_trn   = r_z22.z22_num_trn
			
RETURN done

END FUNCTION



FUNCTION proceso_elimina_pago_anticipo(r_j10)

DEFINE done 		SMALLINT
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE r_j10		RECORD LIKE cajt010.*

LET done = 0

SET LOCK MODE TO WAIT 5
WHENEVER ERROR CONTINUE
	DECLARE q_pa1 CURSOR FOR
		SELECT * FROM cxct021
			WHERE z21_compania   = r_j10.j10_compania 
			  AND z21_localidad  = r_j10.j10_localidad
			  AND z21_codcli     = r_j10.j10_codcli
			  AND z21_tipo_doc   = r_j10.j10_tipo_destino
			  AND z21_num_doc    = r_j10.j10_num_destino
		FOR UPDATE
OPEN  q_pa1
FETCH q_pa1 INTO r_z21.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	SET LOCK MODE TO NOT WAIT
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN done
END IF
IF STATUS = NOTFOUND THEN
	SET LOCK MODE TO NOT WAIT
	--CALL fgl_winmessage(vg_producto,'No se encontró el pago anticipado.','exclamation')
	CALL fl_mostrar_mensaje('No se encontró el pago anticipado.','exclamation')
	RETURN done
END IF
SET LOCK MODE TO NOT WAIT

IF r_z21.z21_saldo <> r_z21.z21_valor THEN
	--CALL fgl_winmessage(vg_producto,'El pago anticipado ya fue aplicado.','exclamation')
	CALL fl_mostrar_mensaje('El pago anticipado ya fue aplicado.','exclamation')
	RETURN done
END IF

INITIALIZE r_z20.* TO NULL
LET r_z20.z20_compania    = r_j10.j10_compania     
LET r_z20.z20_localidad   = r_j10.j10_localidad
LET r_z20.z20_codcli      = r_j10.j10_codcli
LET r_z20.z20_tipo_doc    = vm_nota_debito
LET r_z20.z20_num_doc     = fl_actualiza_control_secuencias(r_j10.j10_compania,
							    r_j10.j10_localidad,
							    'CO', 'AA', 
							    vm_nota_debito)    
LET r_z20.z20_dividendo   = 1 
LET r_z20.z20_areaneg     = r_j10.j10_areaneg
LET r_z20.z20_referencia  = 'ELIMINACION: ', r_j10.j10_tipo_destino,
			    '-', r_j10.j10_num_destino
LET r_z20.z20_fecha_emi   = TODAY
LET r_z20.z20_fecha_vcto  = TODAY
LET r_z20.z20_tasa_int    = 0   
LET r_z20.z20_tasa_mora   = 0  
LET r_z20.z20_moneda      = r_j10.j10_moneda 
LET r_z20.z20_paridad    = calcula_paridad(r_j10.j10_moneda, 
					   rg_gen.g00_moneda_base) 
LET r_z20.z20_val_impto   = 0
LET r_z20.z20_valor_cap   = r_z21.z21_valor
LET r_z20.z20_valor_int   = 0 
LET r_z20.z20_saldo_cap   = 0
LET r_z20.z20_saldo_int   = 0
LET r_z20.z20_cartera     = 1

INITIALIZE r_g20.* TO NULL
DECLARE q_g20 CURSOR FOR
	SELECT * FROM gent020
		WHERE g20_compania = r_j10.j10_compania
		  AND g20_areaneg  = r_j10.j10_areaneg
OPEN  q_g20
FETCH q_g20 INTO r_g20.*
CLOSE q_g20
FREE  q_g20
IF r_g20.g20_grupo_linea IS NULL THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No existen grupos de lineas asociadas a este area de negocios.','stop')
	CALL fl_mostrar_mensaje('No existen grupos de lineas asociadas a este area de negocios.','stop')
	EXIT PROGRAM
END IF

LET r_z20.z20_linea       = r_g20.g20_grupo_linea
LET r_z20.z20_origen      = 'A'
LET r_z20.z20_usuario     = vg_usuario
LET r_z20.z20_fecing      = CURRENT
INSERT INTO cxct020 VALUES (r_z20.*)

INITIALIZE r_z22.* TO NULL
LET r_z22.z22_compania   = r_j10.j10_compania 
LET r_z22.z22_localidad  = r_j10.j10_localidad
LET r_z22.z22_codcli     = r_j10.j10_codcli
LET r_z22.z22_tipo_trn   = vm_ajuste    
LET r_z22.z22_num_trn    = fl_actualiza_control_secuencias(r_j10.j10_compania,
				r_j10.j10_localidad, 'TE', 'AA', vm_ajuste)
LET r_z22.z22_areaneg    = r_j10.j10_areaneg
LET r_z22.z22_referencia = 'APLICACION NOTA DEBITO # ', r_z20.z20_num_doc
LET r_z22.z22_fecha_emi  = TODAY
LET r_z22.z22_moneda     = r_j10.j10_moneda 
LET r_z22.z22_paridad    = calcula_paridad(r_j10.j10_moneda, 
					   rg_gen.g00_moneda_base) 
LET r_z22.z22_tasa_mora  = 0
LET r_z22.z22_total_cap  = r_z21.z21_valor * (-1) 
LET r_z22.z22_total_int  = 0  
LET r_z22.z22_total_mora = 0 
LET r_z22.z22_origen     = 'A' 
LET r_z22.z22_usuario    = vg_usuario    
LET r_z22.z22_fecing     = CURRENT
INSERT INTO cxct022 VALUES(r_z22.*)

INITIALIZE r_z23.* TO NULL
LET r_z23.z23_compania   = r_z22.z22_compania  
LET r_z23.z23_localidad  = r_z22.z22_localidad     
LET r_z23.z23_codcli     = r_z22.z22_codcli     
LET r_z23.z23_tipo_trn   = r_z22.z22_tipo_trn    
LET r_z23.z23_num_trn    = r_z22.z22_num_trn   
LET r_z23.z23_orden      = 1
LET r_z23.z23_areaneg    = r_z22.z22_areaneg
LET r_z23.z23_tipo_doc   = r_z20.z20_tipo_doc
LET r_z23.z23_num_doc    = r_z20.z20_num_doc
LET r_z23.z23_div_doc    = r_z20.z20_dividendo
LET r_z23.z23_tipo_favor = r_z21.z21_tipo_doc  
LET r_z23.z23_doc_favor  = r_z21.z21_num_doc
LET r_z23.z23_valor_cap  = r_z20.z20_valor_cap * (-1)   
LET r_z23.z23_valor_int  = 0  
LET r_z23.z23_valor_mora = 0 
LET r_z23.z23_saldo_cap  = r_z20.z20_valor_cap 
LET r_z23.z23_saldo_int  = 0
INSERT INTO cxct023 VALUES (r_z23.*)

UPDATE cxct021 SET z21_saldo = 0 WHERE CURRENT OF q_pa1

RETURN 1

END FUNCTION


FUNCTION retorna_arreglo()
--#LET vm_size_arr = fgl_scr_size('ra_j11')
IF vg_gui = 0 THEN
        LET vm_size_arr = 6
END IF
                                                                                
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



FUNCTION muestra_tipo_destino(tipo)
DEFINE tipo		LIKE cajt010.j10_tipo_destino

IF tipo = 'PG' THEN
	DISPLAY 'PAGO FACTURA' TO tit_tipo_destino
END IF
IF tipo = 'PA' THEN
	DISPLAY 'PAGO ANTICIPO' TO tit_tipo_destino
END IF
IF tipo = 'OI' THEN
	DISPLAY 'OTROS INGRESOS' TO tit_tipo_destino
END IF

END FUNCTION
