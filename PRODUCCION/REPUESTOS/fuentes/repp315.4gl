------------------------------------------------------------------------------
-- Titulo           : repp315.4gl - Consulta de proformas por hora
-- Elaboracion      : 11-Jul-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp315 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_par		RECORD
				fecha_ini	DATE,
				fecha_fin	DATE,
				hora_ini	DATETIME HOUR TO MINUTE,
				hora_fin	DATETIME HOUR TO MINUTE,
				r21_moneda	LIKE gent013.g13_moneda,
				tit_moneda	CHAR(20),
				r21_vendedor	LIKE rept001.r01_codigo,
				tit_vend	LIKE rept001.r01_nombres,
				flag_fact	CHAR(1)
			END RECORD
DEFINE rm_prof		ARRAY[2000] OF RECORD
				r21_numprof	LIKE rept021.r21_numprof,
				r21_nomcli	LIKE rept021.r21_nomcli,
				siglas_vend	LIKE rept001.r01_iniciales,
				fecha_max	DATE,
				r21_tot_bruto	LIKE rept021.r21_tot_bruto,
				ind_fact	CHAR(1)
			END RECORD
DEFINE rm_prof_det	ARRAY[30] OF RECORD
				r22_bodega	LIKE rept022.r22_bodega,
				r22_item	LIKE rept022.r22_item,
				tit_desc_item	LIKE rept010.r10_nombre,
				r22_cantidad	LIKE rept022.r22_cantidad,
				r22_porc_descto	LIKE rept022.r22_porc_descto,
				r22_precio	LIKE rept022.r22_precio,
				subtotal_item	DECIMAL(12,2)
			END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_vend		RECORD LIKE rept001.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp315.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp315'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

INITIALIZE rm_par.* TO NULL
LET vm_max_rows       = 2000
LET vm_max_det        = 30
LET rm_par.r21_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.* 
LET rm_par.tit_moneda = r_mon.g13_nombre
LET rm_par.fecha_ini  = vg_fecha
LET rm_par.fecha_fin  = vg_fecha
LET rm_par.hora_ini   = '08:00'
LET rm_par.hora_fin   = '17:00'
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
OPEN WINDOW w_imp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_cons FROM '../forms/repf315_1'
ELSE
	OPEN FORM f_cons FROM '../forms/repf315_1c'
END IF
DISPLAY FORM f_cons
CALL botones_cabecera()
CALL botones_detalle()
--#LET vm_size_arr = fgl_scr_size('rm_prof')
IF vg_gui = 0 THEN
	LET vm_size_arr = 5
END IF
LET rm_par.flag_fact = 'T'
CALL fl_lee_usuario(vg_usuario) RETURNING rm_g05.*
DECLARE qu_vd CURSOR FOR SELECT * FROM rept001
	WHERE r01_compania   = vg_codcia AND
	      r01_user_owner = vg_usuario
OPEN qu_vd 
INITIALIZE rm_vend.* TO NULL
FETCH qu_vd INTO rm_vend.*
LET rm_par.r21_vendedor = rm_vend.r01_codigo
LET rm_par.tit_vend     = rm_vend.r01_nombres
LET rm_par.r21_moneda   = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
	CALL fl_mostrar_mensaje('Moneda no existe.','stop')
	EXIT PROGRAM
END IF
LET rm_par.tit_moneda = r_mon.g13_nombre
WHILE TRUE
	CALL borrar_pantalla()
	CALL lee_parametros1()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL muestra_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_aux		VARCHAR(30)
DEFINE num_dec		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_r01		RECORD LIKE rept001.*
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE
DEFINE hor_ini		DATETIME HOUR TO MINUTE
DEFINE hor_fin		DATETIME HOUR TO MINUTE

DISPLAY BY NAME rm_par.*
LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(r21_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.r21_moneda     = mon_aux
				LET rm_par.tit_moneda = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(r21_vendedor) AND (rm_g05.g05_tipo <> 'UF' OR 
			rm_vend.r01_tipo = 'J' OR
			rm_vend.r01_tipo = 'G') THEN
			CALL fl_ayuda_vendedores(vg_codcia, 'A', 'F') 
				RETURNING r_r01.r01_codigo, r_r01.r01_nombres
			IF r_r01.r01_codigo IS NOT NULL THEN                
				LET rm_par.r21_vendedor = r_r01.r01_codigo
				LET rm_par.tit_vend     = r_r01.r01_nombres
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	BEFORE FIELD hora_ini
		LET hor_ini = rm_par.hora_ini
	BEFORE FIELD hora_fin
		LET hor_fin = rm_par.hora_fin
	AFTER FIELD fecha_ini
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual a la fecha de hoy.','exclamation')
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = fec_ini
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > vg_fecha THEN
				CALL fl_mostrar_mensaje('La fecha final debe ser menor o igual a la fecha de hoy.','exclamation')
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER FIELD hora_ini
		IF rm_par.hora_ini IS NULL THEN
			LET rm_par.hora_ini = hor_ini
			DISPLAY BY NAME rm_par.hora_ini
		END IF
	AFTER FIELD hora_fin
		IF rm_par.hora_fin IS NULL THEN
			LET rm_par.hora_fin = hor_fin
			DISPLAY BY NAME rm_par.hora_fin
		END IF
	AFTER FIELD r21_moneda
		IF rm_par.r21_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.r21_moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD r21_moneda
			END IF
			LET rm_par.tit_moneda = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_moneda
		ELSE
			LET rm_par.tit_moneda = NULL
			CLEAR tit_moneda
		END IF
	AFTER FIELD r21_vendedor
		IF rm_vend.r01_tipo <> 'J' AND rm_vend.r01_tipo <> 'G' THEN
			LET rm_par.r21_vendedor = rm_vend.r01_codigo 
			DISPLAY BY NAME rm_par.*
		END IF		
		IF rm_par.r21_vendedor IS NOT NULL THEN
			CALL fl_lee_vendedor_rep(vg_codcia, rm_par.r21_vendedor) 
				RETURNING r_r01.*
			IF r_r01.r01_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('Vendedor no existe.','exclamation')
				NEXT FIELD r21_vendedor
			END IF
			LET rm_par.tit_vend = r_r01.r01_nombres
			DISPLAY BY NAME rm_par.tit_vend
		ELSE
			LET rm_par.tit_vend = NULL
			CLEAR tit_vend
		END IF
	AFTER INPUT
		IF int_flag THEN
			EXIT INPUT
		END IF
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha final debe ser mayor a la fecha inicial.','exclamation')
			NEXT FIELD fecha_fin
		END IF
		IF rm_par.hora_ini > rm_par.hora_fin THEN
			CALL fl_mostrar_mensaje('La hora final debe ser mayor a la hora inicial.','exclamation')
			NEXT FIELD hora_fin
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE i		INTEGER
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(400)
DEFINE expr_fecha	VARCHAR(200)
DEFINE expr_vend	VARCHAR(100)
DEFINE expr_fact	VARCHAR(100)
DEFINE tot_prof		LIKE rept021.r21_tot_bruto
DEFINE fecing		LIKE rept021.r21_fecing
DEFINE hora		DATETIME HOUR TO SECOND
DEFINE hor_ini		DATETIME HOUR TO SECOND
DEFINE hor_fin		DATETIME HOUR TO SECOND
DEFINE r_prof		RECORD
				r21_numprof	LIKE rept021.r21_numprof,
				r21_nomcli	LIKE rept021.r21_nomcli,
				siglas_vend	LIKE rept001.r01_iniciales,
				fecha_max	DATE,
				r21_tot_bruto	LIKE rept021.r21_tot_bruto,
				r21_cod_tran	LIKE rept021.r21_cod_tran
			END RECORD

LET int_flag = 0
CONSTRUCT expr_sql ON   r21_numprof, r21_nomcli, r21_tot_bruto
		   FROM r21_numprof, r21_nomcli, r21_tot_bruto
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	RETURN
END IF
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_fecha = ' 1 = 1 '
IF rm_par.fecha_ini IS NOT NULL THEN
	LET expr_fecha = ' DATE(r21_fecing) BETWEEN "', rm_par.fecha_ini, '"',
					  ' AND "', rm_par.fecha_fin, '"'
END IF
LET expr_vend = ' 1 = 1 '
IF rm_par.r21_vendedor IS NOT NULL THEN
	LET expr_vend = ' r21_vendedor = ', rm_par.r21_vendedor
END IF
LET expr_fact = ' 1 = 1 '
CASE rm_par.flag_fact
	WHEN 'F'
		LET expr_fact = ' r21_cod_tran IS NOT NULL '
	WHEN 'N'
		LET expr_fact = ' r21_cod_tran IS NULL '
END CASE	
LET query = 'SELECT r21_fecing fecha_ini, r21_numprof, r21_nomcli, ',
		  ' r01_iniciales, (DATE(r21_fecing) + r21_dias_prof) ',
		  ' fecha_max, r21_tot_bruto, r21_cod_tran ',
		  ' FROM rept021, rept001 ',
		  ' WHERE r21_compania  = ', vg_codcia,
		  '   AND r21_localidad = ', vg_codloc,
		  '   AND r21_moneda    = "', rm_par.r21_moneda, '"',
		  '   AND ', expr_fecha CLIPPED,
		  '   AND ', expr_vend  CLIPPED,
		  '   AND ', expr_sql   CLIPPED,
		  '   AND ', expr_fact  CLIPPED,
		  '   AND r01_compania  = r21_compania',
		  '   AND r01_codigo    = r21_vendedor', 
		  ' INTO TEMP temp_prof2'
PREPARE q_cit FROM query
EXECUTE q_cit
SELECT COUNT(*) INTO i FROM temp_prof2
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_prof2
	LET int_flag = 1
	RETURN
END IF
LET hor_ini = rm_par.hora_ini
LET hor_fin = rm_par.hora_fin
LET query = 'SELECT r21_numprof, r21_nomcli, r01_iniciales, fecha_max, ',
		  ' r21_tot_bruto, r21_cod_tran ',
		  ' FROM temp_prof2 ',
		  ' WHERE EXTEND(fecha_ini, HOUR TO SECOND) ',
			' BETWEEN "', hor_ini, '" AND "', hor_fin, '" ',
		  ' INTO TEMP temp_prof'
PREPARE q_cit2 FROM query
EXECUTE q_cit2
DROP TABLE temp_prof2
SELECT COUNT(*) INTO i FROM temp_prof
IF i = 0 THEN
	CALL fl_mostrar_mensaje('No se encontro ninguna proforma en este rango de horas.', 'exclamation')
	DROP TABLE temp_prof
	LET int_flag = 1
	RETURN
END IF
SELECT SUM(r21_tot_bruto) INTO tot_prof FROM temp_prof
DISPLAY BY NAME tot_prof
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION



FUNCTION muestra_consulta()
DEFINE i		SMALLINT
DEFINE query		CHAR(300)
DEFINE num_rows		INTEGER
DEFINE comando		VARCHAR(100)
DEFINE r_r21		RECORD LIKE rept021.*

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1           = 1
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_prof ',
			'ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_prof[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_prof TO rm_prof.*
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#IF rm_prof[i].ind_fact IS NOT NULL THEN
				--#CALL dialog.keysetlabel("F6","Factura")
			--#ELSE
				--#CALL dialog.keysetlabel("F6","")
			--#END IF
			--#CALL dialog.keysetlabel("F7","Detalle") 
			--#MESSAGE i, ' de ', num_rows
			--#CALL muestra_detalle_prof(rm_prof[i].r21_numprof)
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_proforma(rm_prof[i].r21_numprof)
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			IF rm_prof[i].ind_fact IS NOT NULL THEN
				CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, 
					rm_prof[i].r21_numprof)
					RETURNING r_r21.*
				CALL ver_factura(r_r21.r21_cod_tran,
					         r_r21.r21_num_tran)
				LET int_flag = 0
			END IF	
		ON KEY(F7)
			LET i = arr_curr()
			CALL ubicarse_en_detalle(i) 
			MESSAGE i, ' de ', num_rows
			IF int_flag THEN
				EXIT DISPLAY
			END IF
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
	IF int_flag = 0 THEN
		CONTINUE WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
--DELETE FROM temp_prof
DROP TABLE temp_prof

END FUNCTION



FUNCTION muestra_detalle_prof(numprof)
DEFINE numprof		LIKE rept021.r21_numprof
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r22		RECORD LIKE rept022.*
DEFINE i, lim		SMALLINT

CALL borrar_detalle()
DECLARE q_r22 CURSOR FOR
	SELECT * FROM rept022
		WHERE r22_compania  = vg_codcia
		  AND r22_localidad = vg_codloc
		  AND r22_numprof   = numprof
		ORDER BY r22_orden
LET vm_num_det = 1
FOREACH q_r22 INTO r_r22.*
	CALL fl_lee_item(vg_codcia, r_r22.r22_item) RETURNING r_r10.*
	LET rm_prof_det[vm_num_det].r22_bodega      = r_r22.r22_bodega
	LET rm_prof_det[vm_num_det].r22_item        = r_r22.r22_item
	LET rm_prof_det[vm_num_det].tit_desc_item   = r_r10.r10_nombre
	LET rm_prof_det[vm_num_det].r22_cantidad    = r_r22.r22_cantidad
	LET rm_prof_det[vm_num_det].r22_porc_descto = r_r22.r22_porc_descto
	LET rm_prof_det[vm_num_det].r22_precio      = r_r22.r22_precio
	LET rm_prof_det[vm_num_det].subtotal_item   = r_r22.r22_cantidad *
							r_r22.r22_precio
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
LET lim        = vm_num_det
IF vm_num_det > fgl_scr_size('rm_prof_det') THEN
	LET lim = fgl_scr_size('rm_prof_det')
END IF
FOR i = 1 TO lim
	DISPLAY rm_prof_det[i].* TO rm_prof_det[i].*
END FOR
CALL sacar_total_det()
CALL mostrar_descripcion(rm_prof_det[1].r22_item)

END FUNCTION



FUNCTION ubicarse_en_detalle(l) 
DEFINE l, i, j 		SMALLINT      
DEFINE r_r21		RECORD LIKE rept021.*

LET int_flag = 0
CALL set_count(vm_num_det)  
DISPLAY ARRAY rm_prof_det TO rm_prof_det.* 
        ON KEY(INTERRUPT)   
		LET int_flag = 1
                EXIT DISPLAY  
        ON KEY(F1,CONTROL-W) 
		CALL control_visor_teclas_caracter_2() 
	ON KEY(RETURN)
		LET i = arr_curr()	
		LET j = scr_line()
		CALL mostrar_descripcion(rm_prof_det[i].r22_item)
	ON KEY(F5)
		CALL ver_proforma(rm_prof[l].r21_numprof)
		LET int_flag = 0
	ON KEY(F6)
		IF rm_prof[l].ind_fact IS NOT NULL THEN
			CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, 
							rm_prof[l].r21_numprof)
				RETURNING r_r21.*
			CALL ver_factura(r_r21.r21_cod_tran, r_r21.r21_num_tran)
			LET int_flag = 0
		END IF	
	ON KEY(F7)
		LET int_flag = 0
		EXIT DISPLAY
        --#BEFORE DISPLAY 
                --#CALL dialog.keysetlabel("ACCEPT", "")   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#IF rm_prof[l].ind_fact IS NOT NULL THEN
			--#CALL dialog.keysetlabel("F6","Factura")
		--#ELSE
			--#CALL dialog.keysetlabel("F6","")
		--#END IF
	--#BEFORE ROW 
		--#LET i = arr_curr()	
		--#LET j = scr_line()
		--#CALL dialog.keysetlabel("F7","Cabecera")
		--#CALL mostrar_descripcion(rm_prof_det[i].r22_item)
		--#MESSAGE i, ' de ', vm_num_det
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY 

END FUNCTION 



FUNCTION sacar_total_det()
DEFINE tot_prof_det	DECIMAL(14,2)
DEFINE i		SMALLINT

LET tot_prof_det = 0
FOR i = 1 TO vm_num_det
	LET tot_prof_det = tot_prof_det + rm_prof_det[i].subtotal_item
END FOR
DISPLAY BY NAME tot_prof_det

END FUNCTION



FUNCTION mostrar_descripcion(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
CALL fl_lee_clase_rep(vg_codcia, r_r10.r10_linea, r_r10.r10_sub_linea,
			r_r10.r10_cod_grupo, r_r10.r10_cod_clase)
	RETURNING r_r72.*
DISPLAY BY NAME r_r10.r10_nombre, r_r72.r72_desc_clase

END FUNCTION



FUNCTION ver_factura(cod_tran, num_tran)
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE param		VARCHAR(60)

LET param  = ' ', vg_codloc, ' "', cod_tran, '" ', num_tran  
CALL ejecuta_comando('REPUESTOS', vg_modulo, 'repp308 ', param)

END FUNCTION

                                                                                
                                                                                
FUNCTION ver_proforma(numprof)
DEFINE numprof		LIKE rept021.r21_numprof
DEFINE r_r21		RECORD LIKE rept021.*
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)

CALL fl_lee_proforma_rep(vg_codcia, vg_codloc, numprof) RETURNING r_r21.*
LET param  = ' ', vg_codloc, ' ', r_r21.r21_numprof
LET modulo = 'REPUESTOS'
LET mod    = vg_modulo
LET prog   = 'repp220 '
IF r_r21.r21_num_ot IS NOT NULL OR r_r21.r21_num_presup IS NOT NULL THEN
	LET modulo = 'TALLER'
	LET mod    = 'TA'
	LET prog   = 'talp213 '
END IF
CALL ejecuta_comando(modulo, mod, prog, param)

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
{--- ---}
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION borrar_pantalla()
DEFINE i		SMALLINT

FOR i = 1 TO vm_size_arr 
	CLEAR rm_prof[i].*
END FOR
CLEAR tot_prof
CALL borrar_detalle()

END FUNCTION



FUNCTION borrar_detalle()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_prof_det')
	CLEAR rm_prof_det[i].*
END FOR
CLEAR tot_prof_det, r72_desc_clase, r10_nombre

END FUNCTION




FUNCTION botones_cabecera()

--#DISPLAY 'No.'	TO tit_col1
--#DISPLAY 'Cliente'    TO tit_col2
--#DISPLAY 'Ven'        TO tit_col3
--#DISPLAY 'Validéz'    TO tit_col4
--#DISPLAY 'Subtotal'   TO tit_col5
--#DISPLAY 'F'          TO tit_col6

END FUNCTION



FUNCTION botones_detalle()

--#DISPLAY 'Bd'			TO tit_det1
--#DISPLAY 'Item'		TO tit_det2
--#DISPLAY 'Descripción'	TO tit_det3
--#DISPLAY 'Cantidad'		TO tit_det4
--#DISPLAY 'Desc.'		TO tit_det5
--#DISPLAY 'Precio Unit.'	TO tit_det6
--#DISPLAY 'Subtotal'		TO tit_det7

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Proforma'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Factura'                  AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Detalle'                  AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Proforma'                 AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Factura'                  AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Cabecera'                 AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
