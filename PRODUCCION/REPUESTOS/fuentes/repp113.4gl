{*
 * -- Titulo           : repp113.4gl - Mantenimiento precios 
 * -- Elaboracion      : 27-jun-2008
 * -- Autor            : JCM
 * -- Formato Ejecucion: fglrun repp113 base_datos modulo compañía 
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_item ARRAY[30000] OF RECORD
	r10_codigo		LIKE rept010.r10_codigo,
	r10_nombre		LIKE rept010.r10_nombre,
	valact			LIKE rept010.r10_precio_mb,
	valnue			DECIMAL(11,2)
	END RECORD
DEFINE rm_par RECORD
	r10_linea			LIKE rept010.r10_linea,
	r103_familia_vta	LIKE rept103.r103_familia_vta,
	r103_maquina		LIKE rept103.r103_maquina,
	r10_tipo			LIKE rept010.r10_tipo,
	r103_componente		LIKE rept103.r103_componente,
	clasif_a			CHAR(1),
	clasif_b			CHAR(1),
	clasif_c			CHAR(1),
	clasif_e			CHAR(1),
	desc_linea			VARCHAR(30),
	desc_familia_vta	VARCHAR(30),
	desc_maquina		VARCHAR(30),
	desc_tipo			VARCHAR(30),
	desc_componente		VARCHAR(30)
END RECORD
DEFINE vm_max_rows	INTEGER	
DEFINE vm_table_rows DECIMAL(7,0)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp113.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp113'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT

OPEN WINDOW repw113_1 AT 3,2 WITH 24 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_repf113_1 FROM '../forms/repf113_1'
DISPLAY FORM f_repf113_1


OPTIONS INSERT KEY F30, DELETE KEY F31
LET vm_max_rows = 30000

DISPLAY 'Item'        	TO tit_col1
DISPLAY 'Descripción'	TO tit_col2
DISPLAY 'PVP Actual'    TO tit_col3
DISPLAY 'Nuevo PVP'     TO tit_col4
WHILE TRUE
	FOR i = 1 TO fgl_scr_size('rm_item')
		CLEAR rm_item[i].*
	END FOR
	CALL lee_parametros1()
	IF int_flag THEN
		RETURN
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL muestra_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros1()
DEFINE lin_aux		LIKE rept003.r03_codigo
DEFINE tit_aux		VARCHAR(30)
DEFINE r_lin		RECORD LIKE rept003.*

INITIALIZE rm_par.* TO NULL
LET rm_par.clasif_a = 'S'
LET rm_par.clasif_b = 'S'
LET rm_par.clasif_c = 'S'
LET rm_par.clasif_e = 'S'
LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(F2)
		IF infield(r10_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux, tit_aux
			IF lin_aux IS NOT NULL THEN
				LET rm_par.r10_linea = lin_aux
				LET rm_par.desc_linea = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r10_linea
		IF rm_par.r10_linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_par.r10_linea) RETURNING r_lin.*
			IF r_lin.r03_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Línea no existe', 'exclamation')
				NEXT FIELD r10_linea
			END IF
		END IF
	AFTER INPUT
		IF rm_par.clasif_a = 'N' AND rm_par.clasif_b = 'N' AND 
		   rm_par.clasif_c = 'N' AND rm_par.clasif_e = 'N' 
		THEN 
			CALL fgl_winmessage(vg_producto, 'Debe pedir items con alguna clasificacion.',
											 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE i			INTEGER
DEFINE query		VARCHAR(1500)
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_filtro 	VARCHAR(150)
DEFINE te_codigo	CHAR(15)
DEFINE te_nombre 	CHAR(40)
DEFINE te_valact	DECIMAL(5,2)

DEFINE item			LIKE rept010.r10_codigo
DEFINE nombre		LIKE rept010.r10_nombre

DEFINE len 		SMALLINT
DEFINE expr_clasif	VARCHAR(200)

LET int_flag = 0
CONSTRUCT expr_sql ON r10_codigo, r10_nombre FROM r10_codigo, r10_nombre 
	ON KEY(F2)
		IF INFIELD(r10_codigo) THEN
			IF rm_par.r10_linea IS NOT NULL THEN
			     	CALL fl_ayuda_maestro_items(vg_codcia, rm_par.r10_linea)
			     		RETURNING item, nombre
			ELSE 
			     	CALL fl_ayuda_maestro_items(vg_codcia, 'TODOS')
			     		RETURNING item, nombre
			END IF
		    IF item IS NOT NULL THEN
				INITIALIZE rm_item[1].* TO NULL
				LET rm_item[1].r10_codigo = item
				DISPLAY BY NAME rm_item[1].* 
		     END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	RETURN
END IF
ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_lin = ' '
IF rm_par.r10_linea IS NOT NULL THEN
	LET expr_lin = ' AND r10_linea = "', rm_par.r10_linea CLIPPED, '"'
END IF

LET expr_clasif = ' 1=1 ' 
IF rm_par.clasif_a = 'S' THEN
	IF expr_clasif = ' 1=1 ' THEN
		LET expr_clasif = ' clasif IN ('
	END IF
	LET expr_clasif = expr_clasif CLIPPED, '"A"'
END IF
IF rm_par.clasif_b = 'S' THEN
	IF expr_clasif = ' 1=1 ' THEN
		LET expr_clasif = ' clasif IN ('
	ELSE
		LET expr_clasif = expr_clasif CLIPPED, ', '
	END IF
	LET expr_clasif = expr_clasif CLIPPED, '"B"'
END IF
IF rm_par.clasif_c = 'S' THEN
	IF expr_clasif = ' 1=1 ' THEN
		LET expr_clasif = ' clasif IN ('
	ELSE
		LET expr_clasif = expr_clasif CLIPPED, ', '
	END IF
	LET expr_clasif = expr_clasif CLIPPED, '"C"'
END IF
IF rm_par.clasif_e = 'S' THEN
	IF expr_clasif = ' 1=1 ' THEN
		LET expr_clasif = ' clasif IN ('
	ELSE
		LET expr_clasif = expr_clasif CLIPPED, ', '
	END IF
	LET expr_clasif = expr_clasif CLIPPED, '"E"'
END IF
IF expr_clasif <> ' 1=1 ' THEN
	LET expr_clasif = expr_clasif CLIPPED, ')'
END IF

WHENEVER ERROR CONTINUE
DROP TABLE temp_item
DROP TABLE temp_clasif
WHENEVER ERROR STOP

CREATE TEMP TABLE temp_item
	(
	 te_posicion	SERIAL,
	 te_item		CHAR(15),
	 te_descripcion CHAR(40),
	 te_valact		DECIMAL(11,2),
	 te_valnue		DECIMAL(11,2),
	 te_costo		DECIMAL(11,2)
	)

LET query = 'SELECT r10_codigo, r10_nombre, r10_precio_mb, r10_costo_mb, ',
			'		CASE NVL(r105_valor, r104_valor_default) ',
				'		WHEN 0 THEN "E" ',
				'		WHEN 1 THEN "A" ',
				'		WHEN 2 THEN "B" ',
				'		WHEN 3 THEN "C" ',
				'		ELSE NULL ',	
			'		END as clasif',
		    '  FROM rept010, rept011, rept104, OUTER rept105, OUTER rept103 ', 
		    ' WHERE r10_compania   = ', vg_codcia, 
			expr_lin CLIPPED,
			'   AND ', expr_sql CLIPPED,
			'   AND r11_compania   = r10_compania ',
			'   AND r11_item       = r10_codigo ',
			'   AND r104_compania  = r10_compania ',
			'   AND r104_compania  = r10_compania ',
  			'   AND r104_codigo    = "ABC" ',
			'   AND r103_compania  = r10_compania ',
			'   AND r103_item      = r10_codigo ',
			'   AND r105_compania  = r104_compania ',
			'   AND r105_parametro = r104_codigo ',
			'   AND r105_item      = r10_codigo ',
			'   AND r105_fecha_fin IS NULL ',
			' GROUP BY 1, 2, 3, 4, 5 ',
			'  INTO TEMP temp_clasif '

PREPARE cit1 FROM query
EXECUTE cit1

LET query = 'INSERT INTO temp_item(te_item,te_descripcion,te_valact,te_costo) ',
            'SELECT r10_codigo, r10_nombre, r10_precio_mb, r10_costo_mb ',
		    '  FROM temp_clasif ', 
		    ' WHERE ', expr_clasif CLIPPED 

PREPARE cit2 FROM query
EXECUTE cit2

SELECT COUNT(*) INTO vm_table_rows FROM temp_item
IF vm_table_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	RETURN
END IF
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION
 


FUNCTION muestra_consulta()
DEFINE i			INTEGER
DEFINE j			INTEGER
DEFINE num_rows		INTEGER
DEFINE lastpos		DECIMAL(7,0)
DEFINE dummy		DECIMAL(11,0)
DEFINE query		VARCHAR(300)
DEFINE contador		VARCHAR(35)
DEFINE comando		VARCHAR(1000)
DEFINE r_r10		RECORD LIKE rept010.*

LET lastpos = 0
WHILE TRUE 
	LET query = 'SELECT * FROM temp_item ',
				' WHERE te_posicion BETWEEN ', lastpos + 1, 
									  ' AND ', lastpos + vm_max_rows,
				'  ORDER BY 1'

	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO lastpos, rm_item[i].*, dummy
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	
	IF num_rows = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		LET int_flag = 1
		EXIT WHILE
	END IF

	CALL set_count(num_rows)
	INPUT ARRAY rm_item WITHOUT DEFAULTS FROM rm_item.*
		BEFORE ROW
			LET i = arr_curr()
			CALL mostrar_contadores(i, num_rows)
			CALL mostrar_datos(i)
		AFTER ROW
			CALL actualizar_registro(i)
			LET int_flag = 0
		BEFORE INPUT
			CALL dialog.keysetlabel('INSERT', '')
			CALL dialog.keysetlabel('DELETE', '')
			CALL dialog.keysetlabel('F6', 'Actualizar todos')
			CALL dialog.keysetlabel('F7', 'Avanzar')
			CALL dialog.keysetlabel('F8', 'Retroceder')
			IF lastpos >= vm_table_rows THEN
				CALL dialog.keysetlabel('F7', '')
			END IF
			IF lastpos <= vm_max_rows THEN
				CALL dialog.keysetlabel('F8', '')
			END IF
		AFTER INPUT
			LET int_flag = 0
			CALL actualiza_precios()
			EXIT WHILE
		BEFORE INSERT
			LET lastpos = lastpos - num_rows 
			LET int_flag = 0
			EXIT INPUT
		ON KEY(INTERRUPT)
			EXIT INPUT
		ON KEY(F5)
			LET comando = 'fglrun repp108 ', vg_base, ' RE ', 
			               vg_codcia, ' "',
			               rm_item[i].r10_codigo CLIPPED || '"'
			RUN comando
			LET int_flag = 0
		ON KEY(F6)
			CALL actualizar_todos()
			LET lastpos = lastpos - num_rows 
			LET int_flag = 0
			EXIT INPUT
		ON KEY(F7)
			CALL actualizar_registro(i)
			LET int_flag = 0
			EXIT INPUT
		ON KEY(F8)
			CALL actualizar_registro(i)
			LET lastpos = lastpos - num_rows - vm_max_rows
			LET int_flag = 0
			EXIT INPUT
	END INPUT
	IF int_flag = 1 THEN
		LET int_flag = 0
		EXIT WHILE
	END IF
END WHILE
                                                                                
END FUNCTION



FUNCTION actualizar_todos()
DEFINE r_par RECORD
	val			LIKE rept105.r105_valor,
	rubro_base	CHAR(1)
END RECORD
DEFINE query	VARCHAR(1000)
DEFINE campo	VARCHAR(10)

	OPEN WINDOW repw113_2 AT 9,25 WITH 9 ROWS, 30 COLUMNS
		ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
			  BORDER, MESSAGE LINE LAST) 
	OPEN FORM f_repf113_2 FROM '../forms/repf113_2'
	DISPLAY FORM f_repf113_2

	INITIALIZE r_par.* TO NULL
	LET r_par.rubro_base = 'C'

	INPUT BY NAME r_par.* WITHOUT DEFAULTS
		AFTER INPUT
			IF r_par.rubro_base IS NULL or r_par.val IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Debe ingresar un rubro base y un valor de factor.', 'exclamation')
				CONTINUE INPUT
			END IF

			CASE r_par.rubro_base 
			WHEN 'C' 
				LET campo = 'te_costo'
			WHEN 'P' 
				LET campo = 'te_valact'
			OTHERWISE
				LET campo = ''
				CONTINUE INPUT
		END CASE	
	END INPUT
	IF int_flag = 1 THEN
		LET int_flag = 0
		CLOSE WINDOW repw113_2
		RETURN
	END IF
		
	LET query = 'UPDATE temp_item SET te_valnue = ', 
						campo CLIPPED, ' * (1 + ', r_par.val, '/100) '

	PREPARE stmt1 FROM query
	EXECUTE stmt1

	CLOSE WINDOW repw113_2
END FUNCTION



FUNCTION mostrar_contadores(num_elm, num_rows)
DEFINE num_elm		INTEGER 
DEFINE num_rows		INTEGER 
DEFINE num_reg		VARCHAR(45)

LET num_reg = num_elm CLIPPED, ' de ', num_rows CLIPPED, 
			  ' - Total: ', vm_table_rows CLIPPED
DISPLAY BY NAME num_reg
	
END FUNCTION



FUNCTION actualizar_registro(currpos)
DEFINE currpos		INTEGER

UPDATE temp_item SET te_valnue = rm_item[currpos].valnue
 WHERE te_item = rm_item[currpos].r10_codigo

END FUNCTION



FUNCTION mostrar_datos(currpos)
DEFINE currpos 		INTEGER
DEFINE clas_abc		CHAR(1)
DEFINE query		VARCHAR(1000)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r20		RECORD LIKE rept020.*

CALL fl_lee_item(vg_codcia, rm_item[currpos].r10_codigo) RETURNING r_r10.*
DISPLAY r_r10.r10_precio_ant TO precio_ant
DISPLAY r_r10.r10_precio_mb TO precio_act
DISPLAY r_r10.r10_costult_mb TO costo_ant
DISPLAY r_r10.r10_costo_mb TO costo_act

INITIALIZE r_r20.* TO NULL
LET query = 'SELECT FIRST 1 * FROM rept020 ',
			' WHERE r20_compania = ', vg_codcia,
			'   AND r20_item = "', rm_item[currpos].r10_codigo CLIPPED, '"',
			'   AND r20_cod_tran IN ("IM", "CL") ',
			' ORDER BY r20_fecing DESC '

PREPARE cons1 FROM query
EXECUTE cons1 INTO r_r20.*
DISPLAY r_r20.r20_costo TO ult_costo_compra
DISPLAY DATE(r_r20.r20_fecing) TO ult_fecha_compra

INITIALIZE clas_abc TO NULL
SELECT clasif INTO clas_abc
  FROM temp_clasif
 WHERE r10_codigo = rm_item[currpos].r10_codigo
DISPLAY BY NAME clas_abc 

END FUNCTION



FUNCTION actualiza_precios()
DEFINE query		VARCHAR(1000)

BEGIN WORK

	UPDATE rept010 SET r10_precio_ant = r10_precio_mb,
					   r10_precio_mb = (SELECT te_valnue FROM temp_item
										 WHERE te_item = r10_codigo),
					   r10_fec_camprec = CURRENT
	 WHERE r10_compania = vg_codcia
	   AND r10_codigo IN (SELECT te_item FROM temp_item 
						   WHERE te_valnue IS NOT NULL
						     AND te_valnue <> te_valact)

COMMIT WORK

CALL fgl_winmessage(vg_producto, 'Proceso realizado Ok.', 'info')

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
