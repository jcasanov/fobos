------------------------------------------------------------------------------
-- Titulo           : cxpp300.4gl - Consulta Estado Cuenta Proveedores
-- Elaboracion      : 26-Nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxpp300 base módulo compañía localidad
--		      fglrun cxpp300 base módulo compañía localidad proveedor
--				     moneda
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_doc       SMALLINT
DEFINE vm_tot_doc	DECIMAL(14,2)
DEFINE vm_num_doc	SMALLINT
DEFINE rm_progen	RECORD LIKE cxpt001.*
DEFINE rm_procia	RECORD LIKE cxpt002.*
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_filtro	VARCHAR(250)
DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_par  RECORD
	codprov		LIKE cxpt001.p01_codprov,
	nomprov		LIKE cxpt001.p01_nomprov,
	moneda		LIKE gent013.g13_moneda,
	tit_mon		LIKE gent013.g13_nombre,
        flag_saldo	CHAR(1),
	tipo_saldo	CHAR(1),
	valor		DECIMAL(12,2)
	END RECORD
DEFINE rm_rows	ARRAY [1000] OF LIKE cxpt001.p01_codprov
DEFINE rm_dprov		ARRAY [1000] OF RECORD
			p20_tipo_doc	LIKE cxpt020.p20_tipo_doc,
			num_doc		CHAR(18),
			p20_fecha_emi	LIKE cxpt020.p20_fecha_emi,
			p20_fecha_vcto	LIKE cxpt020.p20_fecha_vcto,
			tit_estado	CHAR(15),
			dias		SMALLINT,
			saldo		DECIMAL(14,2)
		END RECORD
DEFINE rm_rowid ARRAY[1000] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp300.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN    -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp300'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE r		RECORD LIKE gent013.*
DEFINE ru		RECORD LIKE gent005.*
DEFINE comando		VARCHAR(100)

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET vm_max_doc  = 1000
CREATE TEMP TABLE temp_doc
	(p20_tipo_doc		CHAR(2),
	 num_doc		CHAR(18),
	 p20_fecha_emi		DATE,
	 p20_fecha_vcto		DATE,
	 tit_estado		CHAR(10),
	 dias			SMALLINT,
	 saldo			DECIMAL(14,2),
	 val_ori		DECIMAL(14,2),
	 p20_num_doc		CHAR(15),
	 p20_dividendo		SMALLINT,
	 p20_codprov		INTEGER,
	 p20_numero_oc		INTEGER)
INITIALIZE rm_par.* TO NULL
LET rm_par.flag_saldo = 'S'
LET rm_par.tipo_saldo = 'T'
LET rm_par.valor      = 0.01
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 30,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_prov FROM "../forms/cxpf300_2"
DISPLAY FORM f_prov
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL muestra_titulos_columnas()
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Detalle'
		HIDE OPTION 'Movimientos'
		HIDE OPTION 'Doc. a Favor'
		HIDE OPTION 'Datos'
		CALL fl_lee_usuario(vg_usuario) RETURNING ru.*
		IF ru.g05_tipo <> 'AG' THEN	
			HIDE OPTION 'Recalcular Saldos'
		END IF
		IF num_args() = 6 THEN
			HIDE OPTION 'Consultar'
			LET rm_par.codprov = arg_val(5)
			LET rm_par.moneda = arg_val(6)
			CALL control_consulta()
                        SHOW OPTION 'Movimientos'
			SHOW OPTION 'Doc. a Favor'
			SHOW OPTION 'Datos'
			IF vm_num_doc > 0 THEN
                      		SHOW OPTION 'Detalle'
                	END IF
		END IF
	COMMAND KEY('C') 'Consultar'
		IF num_args() = 6 THEN
			CONTINUE MENU
		END IF
		CALL control_consulta()
		CALL muestra_titulos_columnas()
                SHOW OPTION 'Movimientos'
		SHOW OPTION 'Doc. a Favor'
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Movimientos'
			SHOW OPTION 'Datos'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
		IF vm_num_doc > 0 THEN
                      SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('A') 'Avanzar'
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_doc > 0 THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('R') 'Retroceder'
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_doc > 0 THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('D') 'Detalle' 'Ir al detalle de documentos.'
		IF vm_num_doc > 0 THEN
			CALL ubicarse_en_detalle()
		END IF
	COMMAND KEY('M') 'Movimientos' 'Ver detalle de pagos.'
		IF vm_num_rows > 0 THEN
			CALL mostrar_movimientos_proveedor(vg_codcia, vg_codloc,
				rm_rows[vm_row_current], rm_par.moneda)
		END IF
	COMMAND KEY('D') 'Doc. a Favor'
		IF vm_num_rows > 0 THEN
			CALL mostrar_documentos_favor(vg_codcia, vg_codloc, 
				    rm_rows[vm_row_current], rm_par.moneda)
		END IF
	COMMAND KEY('Z') 'Retenciones'
		IF vm_num_rows > 0 THEN
			CALL mostrar_retenciones(vg_codcia, vg_codloc, 
				    rm_rows[vm_row_current], rm_par.moneda)
		END IF
	COMMAND KEY('T') 'Datos'
		IF vm_row_current > 0 THEN
			LET comando = 'fglrun cxpp101 ', vg_base, ' ',
				vg_modulo, ' ', vg_codcia, ' ', 
				vg_codloc, ' ', rm_rows[vm_row_current]
			RUN comando 
		END IF
	COMMAND KEY('Z') 'Recalcular Saldos'
		CALL proceso_recalcula_saldos()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE query		VARCHAR(500)
DEFINE expr_valor	VARCHAR(150)
DEFINE orden		VARCHAR(20)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_mon		LIKE gent013.g13_nombre
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE nomprov		LIKE cxpt001.p01_nomprov
DEFINE i		SMALLINT

LET int_flag = 0
IF num_args() = 4 THEN
	OPEN WINDOW w_par AT 9,8 WITH FORM "../forms/cxpf300_1"
		ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER)
	INPUT BY NAME rm_par.* WITHOUT DEFAULTS
		ON KEY(F2)
			IF infield(codprov) THEN
				CALL fl_ayuda_proveedores_localidad(vg_codcia, vg_codloc)
					RETURNING codprov, nomprov
				IF codprov IS NOT NULL THEN
					LET rm_par.codprov = codprov
					LET rm_par.nomprov = nomprov
					DISPLAY BY NAME rm_par.codprov, rm_par.nomprov
				END IF
			END IF
			IF infield(moneda) THEN
                        	CALL fl_ayuda_monedas() RETURNING mon_aux, tit_mon, i
                        	IF mon_aux IS NOT NULL THEN
					LET rm_par.tit_mon = tit_mon
                                	DISPLAY BY NAME rm_par.tit_mon
                        	END IF
                	END IF
                	LET int_flag = 0
		AFTER FIELD codprov
			IF rm_par.codprov IS NOT NULL THEN
				CALL fl_lee_proveedor(rm_par.codprov)
					RETURNING rm_progen.*
				IF rm_progen.p01_codprov IS NULL THEN
					CALL fgl_winmessage(vg_producto, 'Proveedor no existe', 'exclamation')
					NEXT FIELD codprov
				END IF
				LET rm_par.nomprov = rm_progen.p01_nomprov
				DISPLAY BY NAME rm_par.nomprov
				CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_par.codprov)
					RETURNING rm_procia.*
				IF rm_procia.p02_compania IS NULL THEN
					CALL fgl_winmessage(vg_producto, 'Proveedor no está activado para la compañía', 'exclamation')
					NEXT FIELD codprov
				END IF
			ELSE
				LET rm_par.nomprov = NULL
				DISPLAY BY NAME rm_par.nomprov
			END IF
		AFTER FIELD moneda
			IF rm_par.moneda IS NOT NULL THEN
				CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
				IF rm_mon.g13_moneda IS NULL THEN
					CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
					NEXT FIELD moneda
				END IF
				LET rm_par.tit_mon = rm_mon.g13_nombre
				DISPLAY BY NAME rm_par.tit_mon
			ELSE
				LET rm_par.tit_mon = NULL
				DISPLAY BY NAME rm_par.tit_mon
			END IF
		AFTER FIELD valor
			IF rm_par.valor < 0 OR rm_par.valor IS NULL THEN
				LET rm_par.valor = 0.01
				DISPLAY BY NAME rm_par.valor
			END IF
	END INPUT
	CLOSE WINDOW w_par
	IF int_flag THEN
		LET int_flag = 0
		IF vm_row_current > 0 THEN
			CALL mostrar_registro(rm_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
END IF
ERROR 'Generando consulta . . . espere por favor.' ATTRIBUTE(NORMAL)
LET query = 'SELECT p30_codprov, ' ||
		'SUM(p30_saldo_favor), ' ||
       		'SUM(p30_saldo_xvenc), ' ||
       		'SUM(p30_saldo_venc),  ' ||
       		'SUM(p30_saldo_xvenc + p30_saldo_venc) ' ||
  		'FROM cxpt030 ' ||
		'WHERE p30_compania  = ' || vg_codcia ||
		' AND  p30_localidad = ' || vg_codloc ||
		' AND  p30_moneda    = "' || rm_par.moneda || '"' 
IF rm_par.codprov IS NULL THEN
	CASE rm_par.tipo_saldo 
		WHEN 'A'
			LET expr_valor = 'SUM(p30_saldo_favor) >= ' || rm_par.valor
			LET orden      = '2 DESC'
		WHEN 'P'
			LET expr_valor = 'SUM(p30_saldo_xvenc) >= ' || rm_par.valor
			LET orden      = '3 DESC'
		WHEN 'V'
			LET expr_valor = 'SUM(p30_saldo_venc)  >= ' || rm_par.valor
			LET orden      = '4 DESC'
		WHEN 'T'
			LET expr_valor = 'SUM(p30_saldo_xvenc) + ' ||
				 	'SUM(p30_saldo_venc) >= '|| rm_par.valor
			LET orden      = '5 DESC'
	END CASE
	LET query = query CLIPPED || 
			' GROUP BY 1 ' ||
			' HAVING ' || expr_valor ||
			' ORDER BY ' || orden
ELSE
	LET query = query CLIPPED || 
			' AND p30_codprov = ' || rm_par.codprov ||
			' GROUP BY 1 '
END IF
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	MESSAGE '' 
	ERROR ' ' ATTRIBUTE(NORMAL)
	CLEAR FORM
	LET vm_row_current = 0
	IF num_args() = 6 THEN
		EXIT PROGRAM
	END IF
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(rm_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION ubicarse_en_detalle()
DEFINE i		SMALLINT
DEFINE query		VARCHAR(500)
DEFINE r_an		RECORD LIKE gent003.*
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE codprov		LIKE cxpt020.p20_codprov 
DEFINE val_original	DECIMAL(14,2)
DEFINE comando		VARCHAR(150)
DEFINE num_oc		LIKE ordt010.c10_numero_oc
DEFINE filtro		VARCHAR(250)

LET rm_orden[4] = 'ASC'
LET vm_columna_1 = 4
LET vm_columna_2 = 1
LET vm_filtro = ' 1 = 1 '
WHILE TRUE
	CALL set_count(vm_num_doc)
	DISPLAY ARRAY rm_dprov TO rm_dprov.*
		BEFORE ROW
			LET i = arr_curr()
			SELECT p20_num_doc, p20_dividendo,
			       p20_codprov, val_ori, p20_numero_oc
				INTO num_doc, dividendo, 
				     codprov, val_original, num_oc
				FROM temp_doc 
				WHERE ROWID = rm_rowid[i]
			MESSAGE i, ' de ', vm_num_doc, 
				'    Valor Original: ', 
			        val_original USING '#,###,###,##&.##'
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.keysetlabel("F8","Filtrar")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			IF num_oc IS NULL THEN
				CONTINUE DISPLAY
			END IF	
			LET comando = 'cd ..' || vg_separador || 
			        '..' || vg_separador || 
				'COMPRAS' || vg_separador || 'fuentes; ' ||
			      	'fglrun ordp200 ' || vg_base || 
			      	' OC ' || 
			      	vg_codcia || ' ' || 
			      	vg_codloc || ' ' ||
			      	num_oc
			RUN comando
		ON KEY(F6)
			LET i = arr_curr()
			SELECT p20_codprov, p20_num_doc, p20_dividendo
				INTO codprov, num_doc, dividendo
				FROM temp_doc 
				WHERE ROWID = rm_rowid[i]
			CALL muestra_movimientos_documento_cxp(vg_codcia, 
				vg_codloc, codprov, rm_dprov[i].p20_tipo_doc, 
				num_doc, dividendo)
		ON KEY(F7)
			LET i = arr_curr()
			LET comando = 'fglrun cxpp200 ' || vg_base || ' ' ||
			      vg_modulo || ' ' ||
			      vg_codcia || ' ' || 
			      vg_codloc || ' ' ||
			      codprov   || ' ' ||
			      rm_dprov[i].p20_tipo_doc || ' ' ||
			      num_doc   || ' ' ||
			      dividendo
			RUN comando
		ON KEY(F8)
			CALL filtrar_detalle() RETURNING filtro
			LET int_flag = 0
			IF filtro = 'FILTRO_CANCELADO' THEN
				LET vm_filtro = filtro
			ELSE
				LET vm_filtro = ' 1 = 1 ' 
			END IF
			EXIT DISPLAY
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET i = 7
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
	LET query = 'SELECT p20_tipo_doc, num_doc, p20_fecha_emi, ',
		        'p20_fecha_vcto, tit_estado, dias, saldo, ROWID ',
			' FROM temp_doc ',
			' WHERE ', vm_filtro CLIPPED,
			' ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE dcol FROM query
	DECLARE q_dcol CURSOR FOR dcol
	LET i = 1
	FOREACH q_dcol INTO rm_dprov[i].*, rm_rowid[i]
		LET i = i + 1
	END FOREACH
	LET vm_num_doc = i - 1
END WHILE
MESSAGE vm_num_doc || ' documento(s)'

-- Regreso todo a su estado original
LET query = 'SELECT p20_tipo_doc, num_doc, p20_fecha_emi, ',
  	          ' p20_fecha_vcto, tit_estado, dias, saldo, ROWID ',
	     ' FROM temp_doc ',
	    ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			  vm_columna_2, ' ', rm_orden[vm_columna_2] 

-- Cursors *must be* uniquely declared 
PREPARE dcol1 FROM query
DECLARE q_dcol1 CURSOR FOR dcol1
LET i = 1
FOREACH q_dcol1 INTO rm_dprov[i].*, rm_rowid[i]
	LET i = i + 1
	IF i > 1000 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_doc = i - 1
CALL set_count(vm_num_doc)
DISPLAY ARRAY rm_dprov TO rm_dprov.*
	BEFORE DISPLAY
		EXIT DISPLAY
END DISPLAY
FREE q_dcol1

END FUNCTION



FUNCTION filtrar_detalle()
DEFINE filtro		VARCHAR(250)

LET int_flag = 0
CONSTRUCT BY NAME filtro ON p20_tipo_doc, num_doc, p20_fecha_vcto, dias, 
                            saldo 

IF int_flag THEN
	LET int_flag = 0
	LET filtro = 'FILTRO_CANCELADO'
END IF

RETURN filtro

END FUNCTION



FUNCTION muestra_titulos_columnas()

DISPLAY 'Tip'           TO tit_col1
DISPLAY 'No. Documento' TO tit_col2
DISPLAY 'Fecha Emis.'   TO tit_col3
DISPLAY 'Fecha Vcto.'   TO tit_col4
DISPLAY 'Estado'        TO tit_col5
DISPLAY 'Días'          TO tit_col6
DISPLAY 'S a l d o'     TO tit_col7

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(rm_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(rm_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_tal_aux	RECORD LIKE talt020.*
DEFINE num_registro	LIKE talt022.t22_numpre
DEFINE tot_favor 	DECIMAL(14,2)
DEFINE tot_xven  	DECIMAL(14,2)
DEFINE tot_vcdo  	DECIMAL(14,2)
DEFINE tot_saldo 	DECIMAL(14,2)

ERROR 'Cargando documentos del proveedor . . . espere por favor.' ATTRIBUTE(NORMAL)
IF vm_num_rows > 0 THEN
	SELECT * INTO rm_progen.* FROM cxpt001 
                WHERE p01_codprov = num_registro
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe proveedor: ' || num_registro,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_progen.p01_codprov, rm_progen.p01_nomprov, 
			rm_par.tit_mon, rm_progen.p01_direccion1, 
			rm_progen.p01_telefono1, rm_progen.p01_telefono2, 
			rm_progen.p01_fax1
	IF rm_progen.p01_estado = 'A' THEN
		DISPLAY 'ACTIVO' TO tit_estprov
	END IF
	IF rm_progen.p01_estado = 'B' THEN
		DISPLAY 'BLOQUEADO' TO tit_estprov
	END IF
	LET tot_favor = 0
	SELECT  SUM(p30_saldo_favor), SUM(p30_saldo_xvenc), SUM(p30_saldo_venc)
		INTO tot_favor, tot_xven, tot_vcdo
		FROM cxpt030
		WHERE p30_compania  = vg_codcia AND 
		      p30_localidad = vg_codloc AND 
		      p30_codprov    = rm_progen.p01_codprov AND 
		      p30_moneda    = rm_par.moneda
	IF tot_favor IS NULL THEN
		LET tot_favor = 0	
		LET tot_xven  = 0	
		LET tot_vcdo  = 0	
		LET tot_saldo = 0	
	END IF
	LET tot_saldo = tot_xven + tot_vcdo
	DISPLAY BY NAME tot_favor, tot_xven, tot_vcdo, tot_saldo
	CALL carga_muestra_detalle(num_registro)
END IF
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION



FUNCTION carga_muestra_detalle(codprov)
DEFINE codprov           LIKE cxpt001.p01_codprov
DEFINE r_doc		RECORD LIKE cxpt020.*
DEFINE tit_estado	CHAR(10)
DEFINE query            VARCHAR(400)
DEFINE i, dias          SMALLINT
DEFINE valor_aux, aux	DECIMAL(13,2)
DEFINE numdoc   	CHAR(18)
                                                                                
DELETE FROM temp_doc 
FOR i = 1 TO fgl_scr_size('rm_dprov')
        INITIALIZE rm_dprov[i].* TO NULL
        CLEAR rm_dprov[i].*
END FOR
LET valor_aux = 0
IF rm_par.flag_saldo = 'S' THEN
	LET valor_aux = 0.01
END IF
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[4] = 'ASC'
LET vm_columna_1 = 4
LET vm_columna_2 = 1
DECLARE q_doc CURSOR FOR
	SELECT cxpt020.*
	FROM cxpt020
        WHERE p20_compania  = vg_codcia
	  AND p20_localidad = vg_codloc 
	  AND p20_codprov    = codprov
          AND p20_saldo_cap + p20_saldo_int >= valor_aux 
	ORDER BY p20_fecha_vcto
LET int_flag = 0
LET vm_num_doc = 0
FOREACH q_doc INTO r_doc.*
        LET vm_num_doc = vm_num_doc + 1
	LET numdoc = r_doc.p20_num_doc CLIPPED, '-', 
		     r_doc.p20_dividendo USING '&&'
	LET valor_aux = r_doc.p20_saldo_cap + r_doc.p20_saldo_int
	LET dias = NULL
	LET tit_estado = 'Cancelado'
	IF valor_aux <> 0 THEN
		LET dias = r_doc.p20_fecha_vcto - TODAY
		IF dias < 0 THEN
			LET tit_estado = 'Vencido'
		ELSE
			LET tit_estado = 'Por Vencer'
		END IF
	END IF
	LET aux = r_doc.p20_valor_cap + r_doc.p20_valor_int
	INSERT INTO temp_doc VALUES (r_doc.p20_tipo_doc, numdoc,
		r_doc.p20_fecha_emi, r_doc.p20_fecha_vcto, tit_estado, dias, 
		valor_aux, aux,
	        r_doc.p20_num_doc, r_doc.p20_dividendo,
		r_doc.p20_codprov, r_doc.p20_numero_oc)
	LET rm_rowid[vm_num_doc] = SQLCA.SQLERRD[6]
	LET rm_dprov[vm_num_doc].p20_tipo_doc	= r_doc.p20_tipo_doc
	LET rm_dprov[vm_num_doc].num_doc	= numdoc
	LET rm_dprov[vm_num_doc].p20_fecha_emi 	= r_doc.p20_fecha_emi 
	LET rm_dprov[vm_num_doc].p20_fecha_vcto	= r_doc.p20_fecha_vcto
	LET rm_dprov[vm_num_doc].tit_estado	= tit_estado
	LET rm_dprov[vm_num_doc].dias		= dias
	LET rm_dprov[vm_num_doc].saldo		= valor_aux
        IF vm_num_doc >= vm_max_doc THEN
                EXIT FOREACH
        END IF
END FOREACH
IF vm_num_doc > 0 THEN
        FOR i = 1 TO fgl_scr_size('rm_dprov')
                DISPLAY rm_dprov[i].* TO rm_dprov[i].*
        END FOR
END IF
MESSAGE vm_num_doc || ' documento(s)'
                                                                                
END FUNCTION



FUNCTION muestra_movimientos_documento_cxp(codcia, codloc, codprov, tipo_doc, 
					   num_doc, dividendo)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_doc		LIKE cxpt020.p20_tipo_doc
DEFINE num_doc		LIKE cxpt020.p20_num_doc
DEFINE dividendo	LIKE cxpt020.p20_dividendo
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE max_rows, i	SMALLINT
DEFINE r_orden ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		VARCHAR(500)
DEFINE comando		VARCHAR(200)
DEFINE r_pdoc	ARRAY[100] OF RECORD
	p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
	p23_num_trn	LIKE cxpt023.p23_num_trn,
	p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
	p22_referencia	LIKE cxpt022.p22_referencia,
	val_pago	DECIMAL(14,2)
	END RECORD

LET max_rows = 100
OPEN WINDOW w_mdoc AT 8,3 WITH FORM "../forms/cxpf300_3"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Tp'                  TO tit_col1 
DISPLAY 'Número'              TO tit_col2 
DISPLAY 'Fec.Pago'            TO tit_col3
DISPLAY 'R e f e r e n c i a' TO tit_col4 
DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_proveedor(codprov) RETURNING r_prov.*
IF r_prov.p01_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe proveedor: ' || codprov,
			    'exclamation')
	CLOSE WINDOW w_mdoc
	RETURN
END IF
DISPLAY BY NAME r_prov.p01_nomprov
DISPLAY tipo_doc, num_doc, dividendo TO p23_tipo_doc, p23_num_doc, p23_div_doc
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET r_orden[3]  = 'ASC'
LET columna_1 = 3
LET columna_2 = 1
WHILE TRUE
	LET query = 'SELECT p23_tipo_trn, p23_num_trn, p22_fecha_emi, ' ||
			'   p22_referencia, p23_valor_cap + p23_valor_int ' ||
	        	' FROM cxpt023, cxpt022 ' ||
			' WHERE p23_compania  = ? AND ' || 
		              ' p23_localidad = ? AND ' ||
		      	      ' p23_codprov    = ? AND ' ||
		      	      ' p23_tipo_doc  = ? AND ' ||
		              ' p23_num_doc   = ? AND ' || 
		      	      ' p23_div_doc   = ? AND ' ||
		      	      ' p23_compania  = p22_compania  AND ' || 
		      	      ' p23_localidad = p22_localidad AND ' ||
		      	      ' p23_codprov    = p22_codprov    AND ' ||
		      	      ' p23_tipo_trn  = p22_tipo_trn  AND ' ||
		      	      ' p23_num_trn   = p22_num_trn ' ||
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dpgc FROM query
	DECLARE q_dpgc CURSOR FOR dpgc
	LET i = 1
	LET tot_pago = 0
	OPEN q_dpgc USING codcia, codloc, codprov, tipo_doc, num_doc, dividendo
	WHILE TRUE
		FETCH q_dpgc INTO r_pdoc[i].*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dpgc
	FREE q_dpgc
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fgl_winmessage(vg_producto, 'Documento no tiene movimientos', 'exclamation')
		CLOSE WINDOW w_mdoc
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
			IF r_pdoc[i].p23_tipo_trn <> 'PG' THEN
				CALL dialog.keysetlabel("F5","")
			ELSE
				CALL dialog.keysetlabel("F5","Cheque")
			END IF
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL muestra_cheque_emitido(codcia, codloc, codprov, r_pdoc[i].p23_tipo_trn, r_pdoc[i].p23_num_trn ) 
		ON KEY(F6)
			LET i = arr_curr()
			LET comando = 'fglrun cxpp202 ' || vg_base || ' ' ||
			      vg_modulo || ' ' ||
			      codcia    || ' ' || 
			      codloc    || ' ' ||
			      codprov   || ' ' ||
			      r_pdoc[i].p23_tipo_trn || ' ' ||
			      r_pdoc[i].p23_num_trn
			RUN comando
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_mdoc

END FUNCTION



FUNCTION muestra_movimientos_de_doc_favor(codcia, codloc, codprov, tipo_doc, 
					   num_doc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_doc		LIKE cxpt021.p21_tipo_doc
DEFINE num_doc		LIKE cxpt021.p21_num_doc
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE max_rows, i	SMALLINT
DEFINE r_orden ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		VARCHAR(500)
DEFINE comando		VARCHAR(200)
DEFINE r_pdoc	ARRAY[100] OF RECORD
	p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
	p23_num_trn	LIKE cxpt023.p23_num_trn,
	p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
	p22_referencia	LIKE cxpt022.p22_referencia,
	val_pago	DECIMAL(14,2)
	END RECORD

LET max_rows = 100
OPEN WINDOW w_ftrn AT 8,3 WITH FORM "../forms/cxpf300_7"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Tp'                  TO tit_col1 
DISPLAY 'Número'              TO tit_col2 
DISPLAY 'Fecha'               TO tit_col3
DISPLAY 'R e f e r e n c i a' TO tit_col4 
DISPLAY 'V a l o r'           TO tit_col5
CALL fl_lee_proveedor(codprov) RETURNING r_prov.*
IF r_prov.p01_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe proveedor: ' || codprov,
			    'exclamation')
	CLOSE WINDOW w_ftrn
	RETURN
END IF
DISPLAY BY NAME r_prov.p01_nomprov
DISPLAY tipo_doc, num_doc TO p23_tipo_favor, p23_doc_favor
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET r_orden[3]  = 'ASC'
LET columna_1 = 3
LET columna_2 = 1
WHILE TRUE
	LET query = 'SELECT p23_tipo_trn, p23_num_trn, p22_fecha_emi, ' ||
			'   p22_referencia, p23_valor_cap + p23_valor_int ' ||
	        	' FROM cxpt023, cxpt022 ' ||
			' WHERE p23_compania  = ? AND ' || 
		              ' p23_localidad = ? AND ' ||
		      	      ' p23_codprov   = ? AND ' ||
		      	      ' p23_tipo_favor= ? AND ' ||
		              ' p23_doc_favor = ? AND ' || 
		      	      ' p23_compania  = p22_compania  AND ' || 
		      	      ' p23_localidad = p22_localidad AND ' ||
		      	      ' p23_codprov    = p22_codprov    AND ' ||
		      	      ' p23_tipo_trn  = p22_tipo_trn  AND ' ||
		      	      ' p23_num_trn   = p22_num_trn ' ||
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dtf FROM query
	DECLARE q_dtf CURSOR FOR dtf
	LET i = 1
	LET tot_pago = 0
	OPEN q_dtf USING codcia, codloc, codprov, tipo_doc, num_doc
	WHILE TRUE
		FETCH q_dtf INTO r_pdoc[i].*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_pago = tot_pago + r_pdoc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dtf
	FREE q_dtf
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fgl_winmessage(vg_producto, 'Documento no tiene movimientos', 'exclamation')
		CLOSE WINDOW w_ftrn
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_pdoc TO r_pdoc.*
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET comando = 'fglrun cxpp202 ' || vg_base || ' ' ||
			      vg_modulo || ' ' ||
			      codcia    || ' ' || 
			      codloc    || ' ' ||
			      codprov   || ' ' ||
			      r_pdoc[i].p23_tipo_trn || ' ' ||
			      r_pdoc[i].p23_num_trn
			RUN comando
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_ftrn

END FUNCTION



FUNCTION mostrar_movimientos_proveedor(codcia, codloc, codprov, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE max_rows, i, j	SMALLINT
DEFINE r_orden ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_pago		DECIMAL(14,2)
DEFINE query		VARCHAR(500)
DEFINE comando		VARCHAR(200)
DEFINE dividendo	SMALLINT
DEFINE r_movc	ARRAY[800] OF RECORD
	p23_tipo_trn	LIKE cxpt023.p23_tipo_trn,
	p23_num_trn	LIKE cxpt023.p23_num_trn,
	p23_tipo_doc	LIKE cxpt023.p23_tipo_doc,
	num_doc		CHAR(18),
	p22_fecha_elim	LIKE cxpt022.p22_fecha_elim,
	p22_fecha_emi	LIKE cxpt022.p22_fecha_emi,
	p22_moneda	LIKE cxpt022.p22_moneda,
	val_pago	DECIMAL(14,2)
	END RECORD

LET max_rows = 800
OPEN WINDOW w_dmprov AT 8,3 WITH FORM "../forms/cxpf300_4"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Tp'                  TO tit_col1 
DISPLAY 'Número'              TO tit_col2 
DISPLAY 'Tp'                  TO tit_col3 
DISPLAY 'Documento'           TO tit_col4
DISPLAY 'Fec. Elim'           TO tit_col5 
DISPLAY 'Fec. Pago'           TO tit_col6 
DISPLAY 'Mo'                  TO tit_col7 
DISPLAY 'V a l o r'           TO tit_col8
CALL fl_lee_proveedor(codprov) RETURNING r_prov.*
IF r_prov.p01_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe proveedor: ' || codprov,
			    'exclamation')
	CLOSE WINDOW w_dmprov
	RETURN
END IF
DISPLAY BY NAME r_prov.p01_nomprov
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[6]  = 'ASC'
LET columna_1 = 6
LET columna_2 = 1
WHILE TRUE
	LET query = 'SELECT p23_tipo_trn, p23_num_trn, p23_tipo_doc, ' ||
			' p23_num_doc, p22_fecha_elim, p22_fecha_emi, ' ||
			' p22_moneda, p23_valor_cap + p23_valor_int, ' ||
			' p23_div_doc ',
	        	' FROM cxpt023, cxpt022 ' ||
			' WHERE p23_compania  = ? AND ' || 
		              ' p23_localidad = ? AND ' ||
		      	      ' p23_codprov    = ? AND ' ||
		      	      ' p23_compania  = p22_compania  AND ' || 
		      	      ' p23_localidad = p22_localidad AND ' ||
		      	      ' p23_codprov    = p22_codprov    AND ' ||
		      	      ' p23_tipo_trn  = p22_tipo_trn  AND ' ||
		      	      ' p23_num_trn   = p22_num_trn   AND ' ||
		      	      ' p22_moneda    = ? ' ||
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dmprov FROM query
	DECLARE q_dmprov CURSOR FOR dmprov
	LET i = 1
	LET tot_pago = 0
	OPEN q_dmprov USING codcia, codloc, codprov, moneda
	WHILE TRUE
		FETCH q_dmprov INTO r_movc[i].*, dividendo
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET r_movc[i].num_doc = r_movc[i].num_doc CLIPPED, 
				        '-', dividendo USING '&&'
		LET tot_pago = tot_pago + r_movc[i].val_pago 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dmprov
	FREE q_dmprov
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fgl_winmessage(vg_producto, 'Proveedor no tiene movimientos', 'exclamation')
		CLOSE WINDOW w_dmprov
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_pago
	DISPLAY ARRAY r_movc TO r_movc.*
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', num_rows
			IF r_movc[j].p23_tipo_trn <> 'PG' THEN
				CALL dialog.keysetlabel("F5","")
			ELSE
				CALL dialog.keysetlabel("F5","Cheque")
			END IF
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL muestra_cheque_emitido(codcia, codloc, codprov, r_movc[j].p23_tipo_trn, r_movc[j].p23_num_trn) 
		ON KEY(F6)
			LET comando = 'fglrun cxpp202 ' || vg_base || ' ' ||
			      vg_modulo || ' ' ||
			      codcia    || ' ' || 
			      codloc    || ' ' ||
			      codprov   || ' ' ||
			      r_movc[j].p23_tipo_trn || ' ' ||
			      r_movc[j].p23_num_trn
			RUN comando
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET i = 7
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F22)
			LET i = 8
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_dmprov

END FUNCTION



FUNCTION mostrar_documentos_favor(codcia, codloc, codprov, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE max_rows, i	SMALLINT
DEFINE r_orden ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_valor	DECIMAL(14,2)
DEFINE tot_saldo	DECIMAL(14,2)
DEFINE query		VARCHAR(500)
DEFINE dividendo	SMALLINT
DEFINE comando		VARCHAR(200)
DEFINE r_dda	ARRAY[500] OF RECORD
	p21_tipo_doc	LIKE cxpt021.p21_tipo_doc,
	p21_num_doc	LIKE cxpt021.p21_num_doc,
	p21_fecha_emi	LIKE cxpt021.p21_fecha_emi,
	p21_valor	LIKE cxpt021.p21_valor,
	p21_saldo	LIKE cxpt021.p21_saldo
	END RECORD

LET max_rows = 500
OPEN WINDOW w_dda AT 6,11 WITH FORM "../forms/cxpf300_5"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Tipo'                TO tit_col1 
DISPLAY 'Número'              TO tit_col2 
DISPLAY 'Fec. Pago'           TO tit_col3 
DISPLAY 'V a l o r'           TO tit_col4
DISPLAY 'S a l d o'           TO tit_col5
CALL fl_lee_proveedor(codprov) RETURNING r_prov.*
IF r_prov.p01_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe proveedor: ' || codprov,
			    'exclamation')
	CLOSE WINDOW w_dda
	RETURN
END IF
DISPLAY BY NAME r_prov.p01_nomprov
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[3]  = 'ASC'
LET columna_1 = 3
LET columna_2 = 2
WHILE TRUE
	LET query = 'SELECT p21_tipo_doc, p21_num_doc, p21_fecha_emi, ' ||
			' p21_valor, p21_saldo ' ||
	        	' FROM cxpt021 ' ||
			' WHERE p21_compania  = ? AND ' || 
		              ' p21_localidad = ? AND ' ||
		      	      ' p21_codprov    = ? AND ' ||
		      	      ' p21_moneda    = ? ' ||
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dda FROM query
	DECLARE q_dda CURSOR FOR dda
	LET i = 1
	LET tot_valor = 0
	LET tot_saldo = 0
	OPEN q_dda USING codcia, codloc, codprov, moneda
	WHILE TRUE
		FETCH q_dda INTO r_dda[i].*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		CALL fl_lee_moneda(moneda) RETURNING rm_mon.*
		DISPLAY rm_mon.g13_nombre TO tit_mon
		LET tot_valor = tot_valor + r_dda[i].p21_valor 
		LET tot_saldo = tot_saldo + r_dda[i].p21_saldo 
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dda
	FREE q_dda
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fgl_winmessage(vg_producto, 'Proveedor no tiene documentos a favor', 'exclamation')
		CLOSE WINDOW w_dda
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_valor, tot_saldo
	DISPLAY ARRAY r_dda TO r_dda.*
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
			IF r_dda[i].p21_tipo_doc <> 'PA' THEN
				CALL dialog.keysetlabel("F5","")
			ELSE
				CALL dialog.keysetlabel("F5","Cheque")
			END IF
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL muestra_cheque_emitido(codcia, codloc, codprov,
				r_dda[i].p21_tipo_doc, r_dda[i].p21_num_doc) 
		ON KEY(F6)
			LET i = arr_curr()
			LET comando = 'fglrun cxpp201 ' || vg_base || ' ' ||
			      vg_modulo || ' ' ||
			      vg_codcia || ' ' || 
			      vg_codloc || ' ' ||
			      codprov   || ' ' ||
			      r_dda[i].p21_tipo_doc || ' ' ||
			      r_dda[i].p21_num_doc
			RUN comando
		ON KEY(F7)
			CALL muestra_movimientos_de_doc_favor(codcia, codloc, 
			codprov, r_dda[i].p21_tipo_doc, r_dda[i].p21_num_doc) 
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_dda

END FUNCTION



FUNCTION muestra_cheque_emitido(codcia, codloc, codprov, tipo_trn, num_trn)
DEFINE codcia		LIKE cxpt024.p24_compania
DEFINE codloc		LIKE cxpt024.p24_localidad
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE tipo_trn		LIKE cxpt022.p22_tipo_trn
DEFINE num_trn		LIKE cxpt022.p22_num_trn
DEFINE c		CHAR(1)
DEFINE r		RECORD LIKE cxpt024.*
DEFINE r_ban		RECORD LIKE gent008.*
DEFINE r_td		RECORD LIKE cxpt004.*
DEFINE r_fav		RECORD LIKE cxpt021.*
DEFINE r_trn		RECORD LIKE cxpt022.*
DEFINE comando		VARCHAR(200)
DEFINE orden_pago	INTEGER

CALL fl_lee_tipo_doc_tesoreria(tipo_trn) RETURNING r_td.*
IF r_td.p04_tipo IS NULL THEN
	RETURN
END IF
LET orden_pago = NULL
IF r_td.p04_tipo = 'F' THEN
	CALL fl_lee_documento_favor_cxp(codcia, codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_fav.*
	LET orden_pago = r_fav.p21_orden_pago
ELSE
	CALL fl_lee_transaccion_cxp(codcia, codloc, codprov, tipo_trn, 
					num_trn)
		RETURNING r_trn.*
	LET orden_pago = r_trn.p22_orden_pago
END IF
CALL fl_lee_orden_pago_cxp(codcia, codloc, orden_pago)
	RETURNING r.*
IF r.p24_orden_pago IS NULL THEN
	RETURN
END IF
OPEN WINDOW w_pch AT 7,20 WITH FORM "../forms/cxpf300_6"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER, MENU LINE 0)
IF status = NOTFOUND THEN
	CALL fgl_winmessage(vg_producto, 'No existe registro en órdenes de pago', 'exclamation')
	CLOSE WINDOW w_pch
	RETURN
END IF
CALL fl_lee_banco_general(r.p24_banco) RETURNING r_ban.*
DISPLAY r_ban.g08_nombre TO banco
DISPLAY BY NAME r.p24_numero_cta, r.p24_numero_che, r.p24_tip_contable, 
		r.p24_num_contable
LET int_flag = 0
MENU 'OPCIONES'
	COMMAND KEY('C') 'Contabilización' 
		LET comando = 'cd ..', vg_separador, '..', vg_separador,
			       'CONTABILIDAD', vg_separador, 'fuentes; ',
			       'fglrun ctbp201 ', vg_base, ' CB ',
				vg_codcia, ' ', vg_codloc, ' ', r.p24_tip_contable, ' ',
				r.p24_num_contable
		RUN comando
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU
LET int_flag = 0
CLOSE WINDOW w_pch

END FUNCTION
			        


FUNCTION mostrar_retenciones(codcia, codloc, codprov, moneda)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE codprov		LIKE cxpt001.p01_codprov
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE r_prov		RECORD LIKE cxpt001.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE max_rows, i, j	SMALLINT
DEFINE r_orden ARRAY[10] OF CHAR(4)
DEFINE columna_1	SMALLINT
DEFINE columna_2	SMALLINT
DEFINE num_rows		SMALLINT
DEFINE tot_base		DECIMAL(14,2)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE query		VARCHAR(500)
DEFINE comando		VARCHAR(200)
DEFINE r_ret	ARRAY[800] OF RECORD
	fecing		DATE,
	p28_num_ret	LIKE cxpt028.p28_num_ret,
	p28_tipo_doc	LIKE cxpt028.p28_tipo_doc,
	p28_num_doc	LIKE cxpt028.p28_num_doc,
	p28_porcentaje	LIKE cxpt028.p28_porcentaje,
	p28_valor_base	LIKE cxpt028.p28_valor_base,
	p28_valor_ret	LIKE cxpt028.p28_valor_ret
	END RECORD

LET max_rows = 800
OPEN WINDOW w_ret AT 8,3 WITH FORM "../forms/cxpf300_8"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Fecha'               TO tit_col1 
DISPLAY 'Núm.'                TO tit_col2 
DISPLAY 'Tp'                  TO tit_col3
DISPLAY 'Factura'             TO tit_col4 
DISPLAY ' % '                 TO tit_col5 
DISPLAY 'Valor Base'          TO tit_col6 
DISPLAY 'Valor Reten.'        TO tit_col7 
CALL fl_lee_proveedor(codprov) RETURNING r_prov.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
IF r_prov.p01_codprov IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe proveedor: ' || codprov,
			    'exclamation')
	CLOSE WINDOW w_ret
	RETURN
END IF
DISPLAY r_prov.p01_nomprov, r_mon.g13_nombre TO nomprov, titmon
FOR i = 1 TO 10
	LET r_orden[i] = '' 
END FOR
LET r_orden[6]  = 'ASC'
LET columna_1 = 1
LET columna_2 = 2
WHILE TRUE
	LET query = 'SELECT p27_fecing, p28_num_ret, p28_tipo_doc, ' ||
			' p28_num_doc, p28_porcentaje, p28_valor_base, ' ||
			' p28_valor_ret ' ||
	        	' FROM cxpt027, cxpt028 ' ||
			' WHERE p27_compania  = ?   AND ' || 
		              ' p27_localidad = ?   AND ' ||
		      	      ' p27_codprov   = ?   AND ' ||
		      	      ' p27_estado    = "A" AND ' ||
		      	      ' p27_moneda    = ?   AND ' ||
		      	      ' p27_compania  = p28_compania  AND ' || 
		      	      ' p27_localidad = p28_localidad AND ' ||
		      	      ' p27_num_ret   = p28_num_ret ',
			' ORDER BY ', columna_1, ' ',
			      r_orden[columna_1], ', ',
			      columna_2, ' ', r_orden[columna_2]
	PREPARE dret FROM query
	DECLARE q_dret CURSOR FOR dret
	LET i = 1
	LET tot_base = 0
	LET tot_ret  = 0
	OPEN q_dret USING codcia, codloc, codprov, moneda
	WHILE TRUE
		FETCH q_dret INTO r_ret[i].*
		IF status = NOTFOUND THEN
			EXIT WHILE
		END IF
		LET tot_base = tot_base + r_ret[i].p28_valor_base
		LET tot_ret  = tot_ret  + r_ret[i].p28_valor_ret
		LET i = i + 1
		IF i > max_rows THEN
			EXIT WHILE
		END IF
	END WHILE
	CLOSE q_dret
	FREE q_dret
	LET num_rows = i - 1
	IF num_rows = 0 THEN
		CALL fgl_winmessage(vg_producto, 'Proveedor no tiene retenciones', 'exclamation')
		CLOSE WINDOW w_ret
		RETURN
	END IF
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY BY NAME tot_base, tot_ret
	DISPLAY ARRAY r_ret TO r_ret.*
		BEFORE ROW
			LET j = arr_curr()
			MESSAGE j, ' de ', num_rows
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL imprimir_retenciones(r_ret[j].p28_num_ret)
			LET int_flag = 0
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F21)
			LET i = 7
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> columna_1 THEN
		LET columna_2           = columna_1 
		LET r_orden[columna_2] = r_orden[columna_1]
		LET columna_1 = i 
	END IF
	IF r_orden[columna_1] = 'ASC' THEN
		LET r_orden[columna_1] = 'DESC'
	ELSE
		LET r_orden[columna_1] = 'ASC'
	END IF
END WHILE
CLOSE WINDOW w_ret

END FUNCTION



FUNCTION proceso_recalcula_saldos()

IF vm_num_rows <= 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_progen.p01_codprov)
CALL mostrar_registro(rm_rows[vm_row_current])

END FUNCTION



FUNCTION imprimir_retenciones(num_ret)

DEFINE num_ret		LIKE cxpt027.p27_num_ret
DEFINE comando		VARCHAR(255)

LET comando = 'cd ..' || vg_separador || '..' || vg_separador || 
	      'TESORERIA' || vg_separador || 'fuentes; ' ||
	      'fglrun cxpp405 ' || vg_base || ' TE ' || 
	      vg_codcia || ' ' || vg_codloc || ' ' || num_ret

RUN comando

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
