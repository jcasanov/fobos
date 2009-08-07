------------------------------------------------------------------------------
-- Titulo           : talp310.4gl - Consulta Estadísticas Taller
-- Elaboracion      : 09-Sep-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun talp310.4gl base_datos modulo compañía
-- Ultima Correccion:  27-05-2002
-- Motivo Correccion: (RCA) se le agregó la siguiente condición en el
--		      SELECT t23_estado = 'F' AND debido a que estaba 
--		      considerando las facturas devueltas inflando valores.
--		      (linea 612)
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par RECORD
	localidad	LIKE gent002.g02_localidad,
	tit_local	LIKE gent002.g02_nombre,
	ano		SMALLINT,
	moneda		LIKE gent013.g13_moneda,
	tit_mon		VARCHAR(30),
	modelo		LIKE talt004.t04_modelo,
	tipo_ot		LIKE talt005.t05_tipord,
	tit_tipo_ot	VARCHAR(30),
	mes1		CHAR(1),
	mes2		CHAR(1),
	mes3		CHAR(1),
	mes4		CHAR(1),
	mes5		CHAR(1),
	mes6		CHAR(1),
	mes7		CHAR(1),
	mes8		CHAR(1),
	mes9		CHAR(1),
	mes10		CHAR(1),
	mes11		CHAR(1),
	mes12		CHAR(1)
	END RECORD
DEFINE rm_cons ARRAY[13] OF RECORD
	tit_rubro	VARCHAR(35),
	valor_1		DECIMAL(14,2),
	valor_2		DECIMAL(14,2),
	valor_3		DECIMAL(14,2),
	tot_val		DECIMAL(14,2)
	END RECORD
DEFINE rm_est		RECORD LIKE talt040.*
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE vm_num_meses	SMALLINT
DEFINE vm_num_rubros	SMALLINT
DEFINE vm_pantallas	SMALLINT
DEFINE vm_pant_cor	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_divisor	SMALLINT
DEFINE vm_ind_ini	SMALLINT
DEFINE vm_ind_fin	SMALLINT
DEFINE rm_meses  ARRAY[12] OF SMALLINT
DEFINE t_valor_1	DECIMAL(14,2)
DEFINE t_valor_2	DECIMAL(14,2)
DEFINE t_valor_3	DECIMAL(14,2)
DEFINE t_tot_val	DECIMAL(14,2)
DEFINE rm_color ARRAY[12] OF VARCHAR(10)

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp310.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp310'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*

INITIALIZE rm_par.* TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
CALL fl_retorna_agencia_default(vg_codcia) RETURNING rm_par.localidad
CALL fl_lee_localidad(vg_codcia, rm_par.localidad) 
	RETURNING rg_loc.*
LET rm_par.tit_local = rg_loc.g02_nombre
LET rm_par.moneda    = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING rm_mon.*
LET rm_par.tit_mon = rm_mon.g13_nombre
LET rm_par.ano     = YEAR(TODAY)
LET rm_par.mes1   = 'S'
LET rm_par.mes2   = 'S'
LET rm_par.mes3   = 'S'
LET rm_par.mes4   = 'S'
LET rm_par.mes5   = 'S'
LET rm_par.mes6   = 'S'
LET rm_par.mes7   = 'S'
LET rm_par.mes8   = 'S'
LET rm_par.mes9   = 'S'
LET rm_par.mes10  = 'S'
LET rm_par.mes11  = 'S'
LET rm_par.mes12  = 'S'
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/talf310_1'
DISPLAY FORM f_cons
LET vm_max_rows = 50
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		RETURN
	END IF
	LET vm_pant_cor   = 1
	CALL obtiene_numero_meses()
	CALL genera_tabla_temporal()
	IF int_flag THEN
		DROP TABLE temp_acum
		CONTINUE WHILE
	END IF
	CALL carga_arreglo_consulta()
	CALL muestra_consulta()
	DROP TABLE temp_acum
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(3)
DEFINE loc_aux		LIKE gent002.g02_localidad
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE mod_aux		LIKE talt004.t04_modelo
DEFINE lin_aux		LIKE talt001.t01_linea 
DEFINE tip_aux		LIKE talt005.t05_tipord  
DEFINE num_dec		SMALLINT
DEFINE r_loc		RECORD LIKE gent002.*
DEFINE r_mod		RECORD LIKE talt004.*
DEFINE r_tot		RECORD LIKE talt005.*

LET int_flag = 0
DISPLAY BY NAME rm_par.tit_mon
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.localidad, rm_par.ano,rm_par.moneda,
				     rm_par.modelo, rm_par.tipo_ot) THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		CALL FGL_WINQUESTION(vg_producto, 
                                     'Desea salir de la consulta',
                                     'No', 'Yes|No|Cancel',
                                     'question', 1) RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF infield(localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING loc_aux, rm_par.tit_local
			IF loc_aux IS NOT NULL THEN
				LET rm_par.localidad = loc_aux
				DISPLAY BY NAME rm_par.localidad, rm_par.tit_local
			END IF
		END IF
		IF infield(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux,rm_par.tit_mon,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF infield(modelo) THEN
			CALL fl_ayuda_tipos_vehiculos(vg_codcia) RETURNING mod_aux, lin_aux
			IF mod_aux IS NOT NULL THEN
				LET rm_par.modelo = mod_aux
				DISPLAY BY NAME rm_par.modelo
			END IF
		END IF
		IF infield(tipo_ot) THEN
			CALL fl_ayuda_tipo_orden_trabajo(vg_codcia)
				RETURNING tip_aux, rm_par.tit_tipo_ot
			IF tip_aux IS NOT NULL THEN
				LET rm_par.tipo_ot = tip_aux
				DISPLAY BY NAME rm_par.tipo_ot, rm_par.tit_tipo_ot
			END IF
		END IF
	AFTER FIELD localidad
		IF rm_par.localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_par.localidad) 
				RETURNING r_loc.*
			IF r_loc.g02_localidad IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Localidad no existe', 'exclamation')
				NEXT FIELD localidad
			END IF
			LET rm_par.tit_local = r_loc.g02_nombre
			DISPLAY BY NAME rm_par.tit_local
		ELSE
			LET rm_par.tit_local = NULL
			CLEAR tit_local
		END IF
	AFTER FIELD ano
		IF rm_par.ano > YEAR(TODAY) THEN
			CALL fgl_winmessage(vg_producto, 'Año incorrecto', 'exclamation')
			NEXT FIELD ano
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
			CLEAR tit_mon
		END IF
	AFTER FIELD modelo
		IF rm_par.modelo IS NOT NULL THEN
			CALL fl_lee_tipo_vehiculo(vg_codcia, rm_par.modelo) RETURNING r_mod.*
			IF r_mod.t04_modelo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Modelo no existe', 'exclamation')
				NEXT FIELD modelo
			END IF
		END IF
	AFTER FIELD tipo_ot
		IF rm_par.tipo_ot IS NOT NULL THEN
			CALL fl_lee_tipo_orden_taller(vg_codcia, rm_par.tipo_ot) RETURNING r_tot.*
			IF r_tot.t05_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Tipo de orden no existe', 'exclamation')
				NEXT FIELD tipo_ot
			END IF
			LET rm_par.tit_tipo_ot = r_tot.t05_nombre
			DISPLAY BY NAME rm_par.tit_tipo_ot
		ELSE
			LET rm_par.tit_tipo_ot = NULL
			CLEAR tit_tipo_ot
		END IF
	AFTER INPUT 
		IF rm_par.mes1  = 'N' AND rm_par.mes2  = 'N' AND
		   rm_par.mes3  = 'N' AND rm_par.mes4  = 'N' AND
		   rm_par.mes5  = 'N' AND rm_par.mes6  = 'N' AND
		   rm_par.mes7  = 'N' AND rm_par.mes8  = 'N' AND
		   rm_par.mes9  = 'N' AND rm_par.mes10 = 'N' AND
		   rm_par.mes11 = 'N' AND rm_par.mes12 = 'N' THEN
			CALL fgl_winmessage(vg_producto, 'Seleccion un mes por lo menos', 'exclamation')
			NEXT FIELD mes1
		END IF
END INPUT

END FUNCTION



FUNCTION genera_tabla_temporal()
DEFINE mes, i		SMALLINT
DEFINE valor, val	DECIMAL(14,2)
DEFINE expr1, expr2	VARCHAR(80)
DEFINE expr3       	VARCHAR(80)
DEFINE query		VARCHAR(500)
DEFINE val1, val2	DECIMAL(14,2)
DEFINE val3, val4	DECIMAL(14,2)
DEFINE val5, val6	DECIMAL(14,2)
DEFINE val7, val8	DECIMAL(14,2)
DEFINE val9, val10	DECIMAL(14,2)
DEFINE val11, val12	DECIMAL(14,2)

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CREATE TEMP TABLE temp_acum
       (te_num_rubro	SMALLINT,
        te_tit_rubro	VARCHAR(35),
	te_mes1		DECIMAL(14,2),
	te_mes2		DECIMAL(14,2),
	te_mes3		DECIMAL(14,2),
	te_mes4		DECIMAL(14,2),
	te_mes5		DECIMAL(14,2),
	te_mes6		DECIMAL(14,2),
	te_mes7		DECIMAL(14,2),
	te_mes8		DECIMAL(14,2),
	te_mes9 	DECIMAL(14,2),
	te_mes10	DECIMAL(14,2),
	te_mes11	DECIMAL(14,2),
	te_mes12	DECIMAL(14,2))
LET expr1 = ' 1 = 1 '
LET expr2 = ' 1 = 1 '
LET expr3 = ' 1 = 1 '
IF rm_par.localidad IS NOT NULL THEN
	LET expr1 = " t40_localidad = ", rm_par.localidad
END IF
IF rm_par.modelo IS NOT NULL THEN
	LET expr2 = " t40_modelo = '", rm_par.modelo CLIPPED, "' "
END IF
IF rm_par.tipo_ot IS NOT NULL THEN
	LET expr3 = " t40_tipo_orden = '", rm_par.tipo_ot CLIPPED, "' "
END IF
LET query = 'SELECT t40_mes, SUM(t40_val_mo_tal),',
                           ' SUM(t40_val_mo_ext),',
                           ' SUM(t40_val_mo_cti),',
                           ' SUM(t40_val_rp_tal),',
                           ' SUM(t40_val_rp_ext),',
                           ' SUM(t40_val_rp_cti),',
                           ' SUM(t40_val_rp_alm),',
                           ' SUM(t40_val_otros1+t40_val_otros2),',
                           ' SUM(t40_vde_mo_tal+t40_vde_rp_tal+t40_vde_rp_alm),',
                           ' 0, SUM(t40_val_impto),',
                           ' SUM(t40_valor_neto) ',
		' FROM talt040 ',
		' WHERE t40_ano = ? AND t40_moneda = ? AND ',
		  expr1, ' AND ',
		  expr2, ' AND ',
		  expr3,
		' GROUP BY 1 '
PREPARE men FROM query
DECLARE q_men CURSOR FOR men
OPEN q_men USING rm_par.ano, rm_par.moneda
LET vm_num_rubros = 0
WHILE TRUE
	FETCH q_men INTO mes, val1, val2,  val3,  val4, val5, val6, val7, val8,
	                      val9, val10, val11, val12
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	LET val10 = val12 - val11
	CALL inserta_actualiza_temporal(1, 'MANO OBRA INTERNA',      val1, mes)
	CALL inserta_actualiza_temporal(2, 'MANO OBRA EXTERNA',      val2, mes)
	CALL inserta_actualiza_temporal(3, 'MANO OBRA CONTRATISTAS', val3, mes)
	CALL inserta_actualiza_temporal(4, 'REPUESTOS TALLER',       val4, mes)
	CALL inserta_actualiza_temporal(5, 'REPUESTOS EXTERNOS',     val5, mes)
	CALL inserta_actualiza_temporal(6, 'REPUESTOS CONTRATISTAS', val6, mes)
	CALL inserta_actualiza_temporal(7, 'REPUESTOS ALMACEN',      val7, mes)
	CALL inserta_actualiza_temporal(8, 'OTROS            ',      val8, mes)
	CALL inserta_actualiza_temporal(9, 'DESCUENTOS       ',      val9, mes)
	CALL inserta_actualiza_temporal(10,'SUBTOTAL         ',      val10,mes)
	CALL inserta_actualiza_temporal(11,'IMPUESTOS        ',      val11,mes)
	CALL inserta_actualiza_temporal(12,'N E T O          ',      val12,mes)
END WHILE
LET int_flag = 0
IF vm_num_rubros = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	RETURN
END IF
SELECT SUM(te_mes1+te_mes2+te_mes3+te_mes4+te_mes5+te_mes6+
           te_mes7+te_mes8+te_mes9+te_mes10+te_mes11+te_mes12)
	INTO valor
	FROM temp_acum
LET vm_divisor = 1
IF valor > 999999 THEN
	LET vm_divisor = 1000
END IF

END FUNCTION



FUNCTION inserta_actualiza_temporal(num_rubro, tit_rubro, valor, mes)
DEFINE num_rubro	SMALLINT
DEFINE tit_rubro	VARCHAR(35)
DEFINE mes, i		SMALLINT
DEFINE mes_c		CHAR(10)
DEFINE campo		VARCHAR(15)
DEFINE expr_ins		VARCHAR(200)
DEFINE query		VARCHAR(500)
DEFINE valor, val	DECIMAL(14,2)

LET mes_c = mes
LET campo = 'te_mes', mes_c
LET expr_ins = NULL
FOR i = 1 TO 12
	IF mes = i THEN
		LET val = valor
	ELSE
		LET val = 0
	END IF
	LET expr_ins = expr_ins CLIPPED, ',', val 
END FOR
SELECT * FROM temp_acum WHERE te_num_rubro = num_rubro
IF status = NOTFOUND THEN
	LET vm_num_rubros = vm_num_rubros + 1
	LET query = "INSERT INTO temp_acum VALUES(", num_rubro, ",'",
		     tit_rubro CLIPPED, "'",
		     expr_ins CLIPPED, ')'
	PREPARE in_temp FROM query
	EXECUTE in_temp 
ELSE
	LET query = 'UPDATE temp_acum SET ', campo, '= ', campo, ' + ?',
			' WHERE te_num_rubro = ?'
	PREPARE up_temp FROM query
	EXECUTE up_temp USING valor, num_rubro 
END IF

END FUNCTION



FUNCTION carga_arreglo_consulta()
DEFINE i		SMALLINT
DEFINE expr_meses	VARCHAR(300)
DEFINE expr_suma	VARCHAR(300)
DEFINE expr_ceros	VARCHAR(10)
DEFINE mes_c		CHAR(10)
DEFINE query		VARCHAR(600)
DEFINE num_rubro	SMALLINT

SELECT * FROM temp_acum INTO TEMP temp_acum1
UPDATE temp_acum1 SET te_mes1 = te_mes1 / vm_divisor,
                      te_mes2 = te_mes2 / vm_divisor,
                      te_mes3 = te_mes3 / vm_divisor,
                      te_mes4 = te_mes4 / vm_divisor,
                      te_mes5 = te_mes5 / vm_divisor,
                      te_mes6 = te_mes6 / vm_divisor,
                      te_mes7 = te_mes7 / vm_divisor,
                      te_mes8 = te_mes8 / vm_divisor,
                      te_mes9 = te_mes9 / vm_divisor,
                      te_mes10= te_mes10/ vm_divisor,
                      te_mes11= te_mes11/ vm_divisor,
                      te_mes12= te_mes12/ vm_divisor
CASE vm_pant_cor 
	WHEN 1
		LET vm_ind_ini = 1
		LET vm_ind_fin = 3
	WHEN 2
		LET vm_ind_ini = 4
		LET vm_ind_fin = 6
	WHEN 3
		LET vm_ind_ini = 7
		LET vm_ind_fin = 9
	WHEN 4
		LET vm_ind_ini = 10
		LET vm_ind_fin = 12
END CASE
LET expr_ceros = ''
IF vm_num_meses < vm_ind_fin THEN
	FOR i = vm_num_meses + 1 TO vm_ind_fin
		LET expr_ceros = expr_ceros CLIPPED, ',0 '
	END FOR
	LET vm_ind_fin = vm_num_meses
END IF
LET expr_meses = NULL
FOR i = vm_ind_ini TO vm_ind_fin 
	LET mes_c = rm_meses[i]
	LET expr_meses = expr_meses CLIPPED, ', te_mes', mes_c
END FOR
LET expr_suma  = ',0'
FOR i = 1 TO vm_num_meses
	LET mes_c = rm_meses[i]
	LET expr_suma  = expr_suma  CLIPPED, '+ te_mes', mes_c
END FOR
LET query = 'SELECT te_num_rubro, te_tit_rubro ', 
		expr_meses CLIPPED,
		expr_ceros CLIPPED,
		expr_suma CLIPPED,
		' FROM temp_acum1 ',
		' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET t_valor_1 = 0
LET t_valor_2 = 0
LET t_valor_3 = 0
LET t_tot_val = 0
LET i = 1
FOREACH q_cons INTO num_rubro, rm_cons[i].*
	LET t_valor_1 = t_valor_1 + rm_cons[i].valor_1
	LET t_valor_2 = t_valor_2 + rm_cons[i].valor_2
	LET t_valor_3 = t_valor_3 + rm_cons[i].valor_3
	LET t_tot_val = t_tot_val + rm_cons[i].tot_val
	LET i = i + 1
END FOREACH
DROP TABLE temp_acum1

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i		SMALLINT

ERROR " " ATTRIBUTE(NORMAL) 
CALL set_count(vm_num_rubros)
WHILE TRUE
	CALL muestra_nombre_meses()
	CALL muestra_precision()
	LET int_flag = 0
	CALL fgl_keysetlabel('F9','Gráfico')
	DISPLAY ARRAY rm_cons TO rm_cons.*
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.keysetlabel("PREVPAGE","")
			CALL dialog.keysetlabel("NEXTPAGE","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL detalle_ordenes_trabajo(rm_meses[vm_ind_ini])
		ON KEY(F6)
			IF vm_pantallas > 1 THEN
				IF vm_pant_cor = 4 OR vm_pant_cor = vm_pantallas THEN
					LET vm_pant_cor = 1
				ELSE
					LET vm_pant_cor = vm_pant_cor + 1
				END IF
				CALL carga_arreglo_consulta()
				EXIT DISPLAY
			END IF
		ON KEY(F7)
			IF vm_divisor = 1 THEN
				LET vm_divisor = 10
			ELSE
				IF vm_divisor = 10 THEN
					LET vm_divisor = 100
				ELSE
					IF vm_divisor = 100 THEN
						LET vm_divisor = 1000
					ELSE
						IF vm_divisor = 1000 THEN
							LET vm_divisor = 1
						END IF
					END IF
				END IF
			END IF
			CALL carga_arreglo_consulta()
			EXIT DISPLAY
		ON KEY(F9)
			CALL muestra_grafico_lineas()
			LET int_flag = 0
	END DISPLAY
	IF int_flag THEN
		RETURN
	END IF
END WHILE

END FUNCTION



FUNCTION detalle_ordenes_trabajo(mes)
DEFINE mes		SMALLINT
DEFINE fec_ini, fec_fin	DATE
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE tot_val		DECIMAL(14,2)
DEFINE comando		VARCHAR(140)
DEFINE r_ot		RECORD LIKE talt023.*
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE query		VARCHAR(300)
DEFINE r_mot ARRAY[2000] OF RECORD
	fecha		DATE,
	num_ot		LIKE talt023.t23_orden,
	num_fa		LIKE talt023.t23_num_factura,
	nomcli		LIKE talt023.t23_nom_cliente,
	valor		DECIMAL(14,2)
	END RECORD

CREATE TEMP TABLE temp_ord
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_num_ot	INTEGER,
	 te_num_fa	INTEGER,
	 te_nomcli	CHAR(40),
	 te_valor	DECIMAL(14,2))
LET max_rows = 2000
OPEN WINDOW w_mov AT 4,5 WITH FORM "../forms/talf310_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
DISPLAY 'Fecha'         TO tit_col1
DISPLAY 'Orden'         TO tit_col2
DISPLAY 'Factura'       TO tit_col3
DISPLAY 'C l i e n t e' TO tit_col4
DISPLAY 'V a l o r'     TO tit_col5
LET fec_ini = MDY(mes, 01, rm_par.ano)
LET fec_fin = fec_ini + 1 UNITS MONTH - 1 UNITS DAY
DISPLAY BY NAME fec_ini, fec_fin, rm_par.moneda,
	rm_par.tit_mon, rm_par.modelo,
	rm_par.tipo_ot, rm_par.tit_tipo_ot
LET int_flag = 0
INPUT BY NAME fec_ini, fec_fin WITHOUT DEFAULTS
	AFTER INPUT
		IF fec_ini > fec_fin THEN
			CALL fgl_winmessage(vg_producto, 'Rango de fechas incorrecto', 'exclamation')
			NEXT FIELD fec_ini
		END IF
END INPUT			
IF int_flag THEN
	LET int_flag = 0
	CLOSE WINDOW w_mov
	DROP TABLE temp_ord
	RETURN
END IF
ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
DECLARE q_cab CURSOR FOR 
	SELECT * FROM talt023
		WHERE t23_compania  = vg_codcia AND 
		      t23_estado = 'F' AND
	              t23_fec_cierre BETWEEN EXTEND(fec_ini, YEAR TO SECOND) AND
	              EXTEND(fec_fin, YEAR TO SECOND) + 23 UNITS HOUR + 
		      59 UNITS MINUTE
LET num_rows = 0
LET tot_val = 0
FOREACH q_cab INTO r_ot.*
	IF rm_par.localidad IS NOT NULL AND 
		r_ot.t23_localidad <> rm_par.localidad THEN
		CONTINUE FOREACH
	END IF
	IF rm_par.moneda <> r_ot.t23_moneda THEN
		CONTINUE FOREACH
	END IF
	IF rm_par.modelo IS NOT NULL AND r_ot.t23_modelo <> rm_par.modelo THEN
		CONTINUE FOREACH
	END IF
	IF rm_par.tipo_ot IS NOT NULL AND 
		r_ot.t23_tipo_ot <> rm_par.tipo_ot THEN
		CONTINUE FOREACH
	END IF
	LET num_rows = num_rows + 1
	INSERT INTO temp_ord VALUES (r_ot.t23_fec_cierre, r_ot.t23_orden,
	                             r_ot.t23_num_factura, r_ot.t23_nom_cliente,
	                             r_ot.t23_tot_neto)
	LET tot_val = tot_val + r_ot.t23_tot_neto
	IF num_rows = max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
IF num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_mov
	DROP TABLE temp_ord
	RETURN
END IF
LET orden_act = 'DESC'
LET orden_ant = 'ASC'
LET columna_act = 1
LET columna_ant = 4
DISPLAY BY NAME tot_val
ERROR ' '
WHILE TRUE
	IF orden_act = 'ASC' THEN
		LET orden_act = 'DESC'
	ELSE
		LET orden_act = 'ASC'
	END IF
	LET orden = columna_act, ' ', orden_act, ', ', columna_ant, ' ',
		    orden_ant 
	LET query = 'SELECT * FROM temp_ord ORDER BY ', orden CLIPPED
	PREPARE mt FROM query
	DECLARE q_mt CURSOR FOR mt
	LET  i = 1
	FOREACH q_mt INTO r_mot[i].*
		LET i = i + 1
	END FOREACH 
	LET int_flag = 0
	CALL set_count(num_rows)
	DISPLAY ARRAY r_mot TO r_mot.*
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET comando = 'cd ', vg_dir_fobos CLIPPED, vg_separador,
				      'TALLER', vg_separador, 'fuentes; ',
				      'fglrun talp204 ', vg_base, 
				      ' TA ', vg_codcia, ' ', vg_codloc, ' ',
				      r_mot[i].num_ot, ' O'
			RUN comando
		ON KEY(F15)
			LET columna_ant = columna_act
			LET columna_act = 1 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET columna_ant = columna_act
			LET columna_act = 2 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET columna_ant = columna_act
			LET columna_act = 3 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET columna_ant = columna_act
			LET columna_act = 4 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET columna_ant = columna_act
			LET columna_act = 5 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_mov
DROP TABLE temp_ord
LET int_flag = 0

END FUNCTION



FUNCTION muestra_nombre_meses()
DEFINE tit_mes1		VARCHAR(11)
DEFINE tit_mes2		VARCHAR(11)
DEFINE tit_mes3		VARCHAR(11)
DEFINE i		SMALLINT

LET i = vm_ind_ini 
LET tit_mes1 = fl_retorna_nombre_mes(rm_meses[i])
LET i = i + 1
IF i <= vm_num_meses THEN
	LET tit_mes2 = fl_retorna_nombre_mes(rm_meses[i])
	LET i = i + 1
	IF i <= vm_num_meses THEN
		LET tit_mes3 = fl_retorna_nombre_mes(rm_meses[i])
	END IF
END IF
DISPLAY BY NAME tit_mes1, tit_mes2, tit_mes3	

END FUNCTION



FUNCTION muestra_precision()

CASE vm_divisor
	WHEN 1
		DISPLAY 'Valores Expresados en Unidades' TO tit_precision
	WHEN 10
		DISPLAY 'Valores Expresados en Decenas' TO tit_precision
	WHEN 100
		DISPLAY 'Valores Expresados en Centenas' TO tit_precision
	WHEN 1000
		DISPLAY 'Valores Expresados en Miles' TO tit_precision
END CASE

END FUNCTION



FUNCTION obtiene_numero_meses() 
DEFINE i		SMALLINT

LET i = 0
IF rm_par.mes1 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 1
END IF
IF rm_par.mes2 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 2
END IF
IF rm_par.mes3 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 3
END IF
IF rm_par.mes4 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 4
END IF
IF rm_par.mes5 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 5
END IF
IF rm_par.mes6 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 6
END IF
IF rm_par.mes7 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 7
END IF
IF rm_par.mes8 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 8
END IF
IF rm_par.mes9 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 9
END IF
IF rm_par.mes10 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 10
END IF
IF rm_par.mes11 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 11
END IF
IF rm_par.mes12 = 'S' THEN
	LET i = i + 1
	LET rm_meses[i] = 12
END IF
LET vm_num_meses = i
LET vm_pantallas = vm_num_meses / 3
IF vm_num_meses MOD 3 > 0 THEN
	LET vm_pantallas = vm_pantallas + 1
END IF

END FUNCTION



FUNCTION muestra_grafico_lineas()
DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(16,6)
DEFINE elementos_y	SMALLINT
DEFINE elementos_x	SMALLINT
DEFINE intervalo_x	SMALLINT
DEFINE intervalo_y	SMALLINT

DEFINE pos_fin_x	SMALLINT
DEFINE pos_fin_y	SMALLINT
DEFINE pos_ant_x	SMALLINT
DEFINE pos_ant_y	SMALLINT
DEFINE marca_x		SMALLINT
DEFINE marca_y		SMALLINT
DEFINE pos_ini		SMALLINT

DEFINE inicio2_x	SMALLINT
DEFINE inicio2_y	SMALLINT

DEFINE max_valor	DECIMAL(14,2)
DEFINE valor_c 		CHAR(10)

DEFINE mes, i, indice	SMALLINT
DEFINE divisor       	SMALLINT
DEFINE valor_rango     	DECIMAL(11,0)
DEFINE valor_aux     	DECIMAL(11,0)
DEFINE valor		DECIMAL(14,2)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE tecla		CHAR(1)
DEFINE titulo, tit_pos	CHAR(75)
DEFINE tit_val		CHAR(16)
DEFINE siglas_mes	CHAR(3)
DEFINE nombre_mes	CHAR(11)
DEFINE r_obj ARRAY[12] OF RECORD
	id_obj_rec1	SMALLINT,
	id_obj_rec2	SMALLINT
	END RECORD

CALL carga_colores()
LET inicio_x    = 120
LET inicio_y    = 100
LET maximo_x    = 600
LET maximo_y    = 750
LET elementos_y = 10
LET elementos_x = 12
LET intervalo_x = maximo_x / elementos_x
LET intervalo_y = maximo_y / elementos_y

SELECT 1 te_mes, te_mes1 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 2 te_mes, te_mes2 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 3 te_mes, te_mes3 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 4 te_mes, te_mes4 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 5 te_mes, te_mes5 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 6 te_mes, te_mes6 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 7 te_mes, te_mes7 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 8 te_mes, te_mes8 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 9 te_mes, te_mes9 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 10 te_mes, te_mes10 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 11 te_mes, te_mes11 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
UNION ALL
SELECT 12 te_mes, te_mes12 te_valor FROM temp_acum
	WHERE te_num_rubro = 12
INTO TEMP temp_lin
SELECT MAX(te_valor) INTO max_valor FROM temp_lin
LET titulo = 'FACTURACION TALLER ANO: ', rm_par.ano USING '####'
DECLARE q_lin CURSOR FOR SELECT te_mes, te_valor FROM temp_lin
	ORDER BY 1
CALL drawinit()
OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/talf310_3"
	ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
CALL drawselect('c001')
CALL drawanchor('w')
CALL drawlinewidth(2)
CALL DrawFillColor("black")
LET i = drawline(inicio_y, inicio_x, 0, maximo_x)
LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
--
LET i = drawtext(960,10,titulo CLIPPED)
LET divisor = 1
IF max_valor > 999999 THEN
	LET divisor = 1000
	LET i = drawtext(920,10,'Valores expresados en miles')
END IF
LET valor_rango = max_valor / divisor / elementos_y
LET factor_y  = maximo_y / max_valor 
LET pos_ant_y = inicio_y
LET pos_ant_x = inicio_x
LET marca_x   = inicio_x + intervalo_x
LET marca_y   = inicio_y + intervalo_y
LET pos_ini   = 900
LET indice    = 0
LET valor_aux = valor_rango 
FOREACH q_lin INTO mes, valor
	LET indice = indice + 1
	CALL DrawFillColor("black")
	CALL drawlinewidth(1)
	CASE mes
		WHEN 1
			LET siglas_mes = 'Ene'
		WHEN 2
			LET siglas_mes = 'Feb'
		WHEN 3
			LET siglas_mes = 'Mar'
		WHEN 4
			LET siglas_mes = 'Abr'
		WHEN 5
			LET siglas_mes = 'May'
		WHEN 6
			LET siglas_mes = 'Jun'
		WHEN 7
			LET siglas_mes = 'Jul'
		WHEN 8
			LET siglas_mes = 'Ago'
		WHEN 9
			LET siglas_mes = 'Sep'
		WHEN 10
			LET siglas_mes = 'Oct'
		WHEN 11
			LET siglas_mes = 'Nov'
		WHEN 12
			LET siglas_mes = 'Dic'
	END CASE
	IF indice <= elementos_x THEN
		LET i = drawline(inicio_y - 10, marca_x, 20, 0)
		LET i = drawline(inicio_y, marca_x, maximo_y, 0)
		LET i = drawtext(inicio_y - 20, marca_x - 20, siglas_mes)
	END IF
	IF indice <= elementos_y THEN
		IF indice = elementos_y AND divisor = 1 THEN
			LET valor_aux = max_valor
		END IF
		LET valor_c = valor_aux USING "##,###,##&"
		LET i = drawline(marca_y, inicio_x - 10, 0, 20)
		LET i = drawline(marca_y, inicio_x, 0, maximo_x)
		LET i = drawtext(marca_y, inicio_x - 150, valor_c)
	END IF
	LET valor_aux = valor_aux + valor_rango
	LET marca_x = marca_x + intervalo_x
	LET marca_y = marca_y + intervalo_y
	CALL drawlinewidth(2)
	--CALL DrawFillColor(rm_color[mes])
	LET pos_fin_x = pos_ant_x + intervalo_x
	LET pos_fin_y = (factor_y  * valor) + inicio_y
	CALL DrawFillColor("cyan")
	LET r_obj[mes].id_obj_rec1 =
		drawline(pos_ant_y, pos_ant_x, pos_fin_y - pos_ant_y, 
			 pos_fin_x - pos_ant_x)
	LET nombre_mes = fl_retorna_nombre_mes(mes)
	LET r_obj[indice].id_obj_rec2 = drawrectangle(pos_ini,900,25,75)
	LET i = drawtext(pos_ini + 40, 830, nombre_mes)
	LET pos_ini = pos_ini - 80
	LET pos_ant_x = pos_fin_x
	LET pos_ant_y = pos_fin_y
END FOREACH
LET i = drawtext(30,10,'Haga click sobre un mes para ver detalles')
FOR i = 1 TO 12
	LET key_n = i + 30
	LET key_c = 'F', key_n
	CALL drawbuttonleft(r_obj[i].id_obj_rec2, key_c)
END FOR
LET key_f30 = FGL_KEYVAL("F30")
LET int_flag = 0
INPUT BY NAME tecla
	BEFORE INPUT
		CALL dialog.keysetlabel("ACCEPT","")
		CALL dialog.keysetlabel("F31","")
		CALL dialog.keysetlabel("F32","")
		CALL dialog.keysetlabel("F33","")
		CALL dialog.keysetlabel("F34","")
		CALL dialog.keysetlabel("F35","")
		CALL dialog.keysetlabel("F36","")
		CALL dialog.keysetlabel("F37","")
		CALL dialog.keysetlabel("F38","")
		CALL dialog.keysetlabel("F39","")
		CALL dialog.keysetlabel("F40","")
		CALL dialog.keysetlabel("F41","")
		CALL dialog.keysetlabel("F42","")
	ON KEY(F31,F32,F33,F34,F35,F36,F37,F38,F39,F40,F41,F42)
		LET i = FGL_LASTKEY() - key_f30
		CALL detalle_ordenes_trabajo(i)
	AFTER FIELD tecla
		NEXT FIELD tecla	
END INPUT
DROP TABLE temp_lin
CLOSE WINDOW w_gr1
	
END FUNCTION



FUNCTION carga_colores()

LET rm_color[01] = 'cyan'
LET rm_color[02] = 'yellow'
LET rm_color[03] = 'green'
LET rm_color[04] = 'red'
LET rm_color[05] = 'snow'
LET rm_color[06] = 'magenta'
LET rm_color[07] = 'pink'
LET rm_color[08] = 'chocolate'
LET rm_color[09] = 'tomato'
LET rm_color[10] = 'blue'
LET rm_color[11] = 'orange'
LET rm_color[12] = 'black'

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
