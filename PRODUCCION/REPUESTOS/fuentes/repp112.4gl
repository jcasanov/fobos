{*
 * -- Titulo           : repp112.4gl - Mantenimiento clasificacion ABC
 * -- Elaboracion      : 25-jun-2008
 * -- Autor            : JCM
 * -- Formato Ejecucion: fglrun repp112 base_datos modulo compañía 
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_item ARRAY[30000] OF RECORD
	r10_codigo	LIKE rept010.r10_codigo,
	r10_nombre	LIKE rept010.r10_nombre,
	valact		CHAR(1),
	valnue		CHAR(1)
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
	clasif_d			CHAR(1),
	clasif_e			CHAR(1),
	desc_linea			VARCHAR(30),
	desc_familia_vta	VARCHAR(30),
	desc_maquina		VARCHAR(30),
	desc_tipo			VARCHAR(30),
	desc_componente		VARCHAR(30)
END RECORD
DEFINE vm_max_rows	INTEGER	
DEFINE vm_table_rows DECIMAL(7,0)

DEFINE vm_param		LIKE rept104.r104_codigo

DEFINE GrabarNuevoCalculo VARCHAR(1)

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp112.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp112'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN


FUNCTION funcion_master()
DEFINE i		SMALLINT

LET vm_param = 'ABC'

OPEN WINDOW repw112_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_repf112_1 FROM '../forms/repf112_1'
DISPLAY FORM f_repf112_1


OPTIONS INSERT KEY F30, DELETE KEY F31
LET vm_max_rows = 30000

DISPLAY 'Item'           TO tit_col1
DISPLAY 'Descripción'    TO tit_col2
DISPLAY 'ABC Actual'      TO tit_col3
DISPLAY 'Nuevo ABC'       TO tit_col4
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
LET rm_par.clasif_d = 'S'
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
		IF rm_par.clasif_a = 'N' AND rm_par.clasif_b = 'N' AND rm_par.clasif_c = 'N' AND 
		   rm_par.clasif_d = 'N' AND rm_par.clasif_e = 'N' 
		THEN 
		CALL fgl_winmessage(vg_producto, 'Debe pedir items con alguna clasificacion.',
											 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE i			INTEGER
DEFINE query		VARCHAR(1000)
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_filtro 	VARCHAR(150)
DEFINE te_codigo	CHAR(15)
DEFINE te_nombre 	CHAR(40)
DEFINE te_valact	DECIMAL(5,2)

DEFINE len 		SMALLINT
DEFINE expr_clasif	VARCHAR(200)

LET int_flag = 0
CONSTRUCT expr_sql ON r10_codigo, r10_nombre FROM r10_codigo, r10_nombre 
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

IF rm_par.clasif_d = 'S' THEN
        IF expr_clasif = ' 1=1 ' THEN
                LET expr_clasif = ' clasif IN ('
        ELSE
                LET expr_clasif = expr_clasif CLIPPED, ', '
        END IF
        LET expr_clasif = expr_clasif CLIPPED, '"D"'
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
	 te_valact		CHAR(1),
	 te_valnue		CHAR(1)
	)

		LET query = 'SELECT r10_codigo, r10_nombre, ',
			'		CASE NVL(r105_valor, r104_valor_default) ',
			'		WHEN 0 THEN "E" ',
			'		WHEN 1 THEN "A" ',
			'		WHEN 2 THEN "B" ',
			'		WHEN 3 THEN "C" ',
			'		WHEN 4 THEN "D" ',
			'		ELSE NULL ',	
			'		END as clasif',
		    '  FROM rept010, rept011, rept104, OUTER rept105 ', 
		    ' WHERE r10_compania   = ', vg_codcia, 
			expr_lin CLIPPED,
			'   AND ', expr_sql CLIPPED,
			'	AND r11_compania   = r10_compania ',
			'	AND r11_item       = r10_codigo ',
			'   AND r104_compania  = r10_compania ',
  			'   AND r104_codigo    = "', vm_param CLIPPED, '"',
--			'   AND r103_compania  = r10_compania ',
--			'   AND r103_item      = r10_codigo ',
			'   AND r105_compania  = r104_compania ',
			'   AND r105_parametro = r104_codigo ',
			'   AND r105_item      = r10_codigo ',
			'   AND r105_fecha_fin IS NULL ',
			' GROUP BY 1, 2, 3 ',
			'  INTO TEMP temp_clasif '

PREPARE cit1 FROM query
EXECUTE cit1

LET query = 'INSERT INTO temp_item(te_item, te_descripcion, te_valact) ',
			'SELECT * ',
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
DEFINE i		INTEGER
DEFINE j		INTEGER
DEFINE num_rows		INTEGER
DEFINE lastpos		DECIMAL(7,0)
DEFINE query		VARCHAR(300)
DEFINE contador		VARCHAR(35)
DEFINE comando		VARCHAR(1000)
DEFINE r_r10		RECORD LIKE rept010.*


DEFINE TieneNuevoABC	INTEGER  -- lleva 1 si el campo valnuev de la grilla no esta vacio
				 -- esta variable es una de las q se usa para condicionar la
				 -- grabacion del registro 

LET lastpos = 0
WHILE TRUE 
	LET query = 'SELECT * FROM temp_item ',
		' WHERE te_posicion BETWEEN ', lastpos + 1, 
 	        ' AND ', lastpos + vm_max_rows,
		'  ORDER BY  te_valact,te_descripcion '

	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO lastpos, rm_item[i].*

		IF rm_item[i].valnue IS NOT NULL THEN
                  LET TieneNuevoABC = 1
		 ELSE
                  LET TieneNuevoABC = 0
		END IF		
		
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
		DISPLAY ARRAY rm_item TO  rm_item.*
		BEFORE ROW
 
			LET i = arr_curr()
			CALL mostrar_contadores(i, num_rows)
		BEFORE DISPLAY
			CALL dialog.keysetlabel('F7', 'Avanzar')
			CALL dialog.keysetlabel('F8', 'Retroceder')
			CALL dialog.keysetlabel('F9', 'Recalcular')
			CALL dialog.keysetlabel('F3', 'Grabar')

			IF lastpos >= vm_table_rows THEN
				CALL dialog.keysetlabel('F7', '')
			END IF
			IF lastpos <= vm_max_rows THEN
				CALL dialog.keysetlabel('F8', '')
			END IF

		AFTER DISPLAY
			LET int_flag = 0
			EXIT WHILE
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
		        LET comando = 'fglrun repp108 ', vg_base, ' RE ', 
			               vg_codcia, ' "',
			               rm_item[i].r10_codigo CLIPPED || '"'
			RUN comando
			LET int_flag = 0

		ON KEY(F9)
		        LET GrabarNuevoCalculo = 1  --lleva 1 al hacer clic en el boton
						    --Recalcular, indispensable para grabar
						    --el recalculo  
                        CALL calcular_ABC()         --funcion para hacer el Recalculo 
 	 		LET int_flag = 0
                        EXIT WHILE 
		ON KEY(F3)
		    --Si existen items recalculados 
			IF (GrabarNuevoCalculo = 1) AND TieneNuevoABC = 1 THEN
		  	  LET int_flag = 0
		          CALL actualiza_parametro()  -- funcion para grabar el nuevo recalculo 
		      	  LET GrabarNuevoCalculo = 0
	                  EXIT WHILE
 		   	END IF	
	END DISPLAY
	IF int_flag = 1 THEN
		LET int_flag = 0
		EXIT WHILE
	END IF
END WHILE
                                                                                
END FUNCTION


FUNCTION calcular_ABC()

--Esta funcion tiene como objetivo recalcular la clasificacion ABC ACTUAL de los items q
--se han cargado en la grilla; segun la nueva formula de clasificacion. 

DEFINE fecha            DATE
DEFINE fecha_ini        DATE
DEFINE fecha_fin        DATE

DEFINE query            VARCHAR(50)
DEFINE query_           VARCHAR(1000)

DEFINE vtas_item        DECIMAL(15,2)
DEFINE NumReg       	INTEGER   		    -- lleva 1 si halla por lo menos 1 registro 
DEFINE clasif           CHAR(1)

DEFINE  i 	        INTEGER

DEFINE item     	LIKE rept020.r20_item
DEFINE CodTran  	LIKE rept020.r20_cod_tran   -- lleva los tipos FA/DF/AF
DEFINE Cant_fa       	LIKE rept020.r20_cant_ven   -- Cant. de facturas de un item  
DEFINE cant_df       	LIKE rept020.r20_cant_dev   -- cant  de devoluciones-factura de un item  
DEFINE cant_af       	LIKE rept020.r20_cant_dev   -- cant  de Facturas anuladas     "      "
DEFINE total_tran   	LIKE rept020.r20_cant_ven   -- Total de transacciones encontradas 
						    -- segun su codtran, de un item 
LET NumReg 	= 0
LET vtas_item	= 0
LET cant_fa	= 0
LET cant_df 	= 0
LET cant_af 	= 0

        OPEN WINDOW repw112_2 AT 9,15 WITH 6 ROWS, 50 COLUMNS
                ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
                          BORDER, MESSAGE LINE LAST)
        OPEN FORM f_repf112_2 FROM '../forms/repf112_2'
        DISPLAY FORM f_repf112_2

        LET fecha = MDY(MONTH(TODAY), 1, YEAR(TODAY))
        LET fecha_fin = fecha - 1 UNITS DAY
	LET fecha_ini = fecha - 1 UNITS YEAR

	--cargamos todos los codigos-item q estan en la tabla temporal y q muestra la grilla  
	LET query = 'SELECT te_item FROM temp_item ORDER BY 1'   

        PREPARE cons_ FROM query
        DECLARE q_cons_ CURSOR FOR cons_
 

  FOREACH q_cons_ INTO  item

	LET cant_fa     = 0
	LET cant_df     = 0
	LET cant_af     = 0

	  --se  hace un conteo para saber cuantas "FA/DF/AF" a tenido cada "item cargado"
	  --durante los ultimos 12 meses

     	LET query_ = 'SELECT  r20_cod_tran,r20_item as te_item, count(DISTINCT r20_num_tran) as TOTAL ',
	            ' FROM rept019, rept020 ',
		    ' WHERE ',
		    ' r20_compania  = r19_compania  AND ',
	            ' r20_localidad = r19_localidad AND ',
                    ' r20_cod_tran  = r19_cod_tran  AND ',
                    ' r20_num_tran  = r19_num_tran  AND ',
                    ' r19_compania      = ', vg_codcia CLIPPED,
		    ' AND r19_localidad = ', vg_codloc CLIPPED,
		    ' AND r19_cod_tran  IN ("FA","DF","AF")',		   
		    ' AND r20_item  = "', item ,                   '" AND ',
                    ' DATE(r19_fecing) BETWEEN "', fecha_ini CLIPPED, '" ',
                    ' AND "', fecha_fin CLIPPED, '" ',
                    ' GROUP BY 1,2 '
        
	PREPARE stmt3 FROM query_
        DECLARE q_clasif CURSOR FOR stmt3

	FOREACH q_clasif INTO CodTran,item, total_tran

		IF Codtran='FA' THEN   
		   LET cant_fa = total_tran  	 
	        END IF
		IF Codtran='DF' THEN
                   LET cant_df = total_tran  
                END IF
		IF Codtran='AF' THEN
                   LET cant_af = total_tran  
                END IF

                LET NumReg =  1  	      

        END FOREACH
		-- obtenemos el Numero de facturas final, "FACTURAS EXITOSAMENTE VENDIDAS" 
		LET vtas_item = cant_fa - ( cant_df + cant_af )		
	
                DISPLAY BY NAME item

		--Segun el rsultado de vtas_item, se procede a clasificar el item,
		--basandonos en ciertas condiciones y/o parametros ya establecidos por diteca.

		IF vtas_item >= 7 THEN
			LET clasif = 'A'
		ELSE
			IF vtas_item >= 5 THEN
				LET clasif = 'B'
			ELSE 
				IF vtas_item >= 3 THEN
					LET clasif = 'C'
				ELSE
					IF vtas_item = 2 THEN
						LET clasif = 'D'
					ELSE
						IF vtas_item <= 1 THEN
							LET clasif = 'E'
						END IF
					END IF
				END IF
			END IF
		END IF			

		--actualizamos en la tabla temp, el nuevo ABC
                UPDATE temp_item SET te_valnue = clasif
                WHERE te_item = item
			
  END FOREACH
       
        CLOSE WINDOW repw112_2
        -- NumReg, lleva 0, significa q no hubo reg encontrados x el query, caso contrario
	-- procede la carga de la tabla temp, con los nuevos ABC, en la grilla(funcion muestra
	-- consulta)    
	IF NumReg > 0 THEN  
 	   CALL muestra_consulta()
         ELSE
	   LET GrabarNuevoCalculo = 0	
           CALL fgl_winmessage(vg_producto, 'No han habido ventas en el periodo.',
	   'exclamation')
	END IF


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



FUNCTION actualiza_parametro()
DEFINE query		VARCHAR(1000)

BEGIN WORK

  UPDATE rept105 SET r105_fecha_fin = TODAY
  WHERE r105_compania = vg_codcia
  AND r105_parametro = vm_param 
  AND r105_item IN (SELECT te_item FROM temp_item WHERE te_valnue IS NOT NULL)
  AND r105_fecha_fin IS NULL

  LET query = 'INSERT INTO rept105(r105_compania, r105_parametro, r105_item, ', 
  ' r105_fecha_ini, r105_secuencia, r105_valor, r105_origen, r105_usuario) ',
  ' SELECT ', vg_codcia CLIPPED, ',  "',  vm_param CLIPPED, '",  ',
  ' te_item, TODAY, NVL((SELECT MAX(r105_secuencia) FROM rept105 ',
  ' WHERE r105_compania = ', vg_codcia CLIPPED,
  ' AND r105_parametro = "', vm_param CLIPPED, '"',
  ' AND r105_item = te_item  AND r105_fecha_ini = TODAY), 0) + 1, ',
  ' CASE te_valnue WHEN "A" THEN 1 ',
  ' WHEN "B" THEN 2 ',
  ' WHEN "C" THEN 3 ',
  ' WHEN "D" THEN 4 ',
  ' WHEN "E" THEN 0 ',
  ' END, "M", "', vg_usuario CLIPPED, '"',
  ' FROM temp_item ',
  ' WHERE (te_valnue IS NOT NULL) AND (te_valnue <> te_valact) '

  PREPARE stmt1 FROM query
  EXECUTE stmt1

 -- DELETE FROM rept105 WHERE r105_valor = 0

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
