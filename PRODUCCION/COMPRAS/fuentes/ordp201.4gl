------------------------------------------------------------------------------
-- Titulo           : ordp201.4gl - Aprobacion Ordenes de Compra
-- Elaboracion      : 15-nov-2001
-- Autor            : GVA
-- Formato Ejecucion: fglrun ordp201 base modulo compania localidad
-- Ultima Correccion: 15-nov-2001
-- Motivo Correccion: 1
------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

-- ---------------------
-- DEFINE RECORD(S) HERE
-- ---------------------

DEFINE rm_c10			RECORD LIKE ordt010.*	-- CABECERA
DEFINE rm_c11		 	RECORD LIKE ordt011.*	-- DETALLE
DEFINE rm_p01		 	RECORD LIKE cxpt001.*	-- PROVEEDORES

	---- ARREGLO IDENTICO A MI SCREEN RECORD ----
DEFINE r_detalle ARRAY[250] OF RECORD
	c10_numero_oc		LIKE ordt010.c10_numero_oc,
	p01_nomprov		LIKE cxpt001.p01_nomprov,
	vm_fecha		DATE,
	c10_tot_compra		LIKE ordt010.c10_tot_compra,
	aprobar			LIKE ordt010.c10_estado
	END RECORD
DEFINE vm_size_arr		INTEGER
	---------------------------------------------

DEFINE vm_estado		LIKE ordt010.c10_estado
DEFINE vm_num_detalle		SMALLINT   -- INDICE DE LA PREVENTA (ARRAY)
DEFINE vm_ind_arr		SMALLINT   -- INDICE DE MI ARREGLO  (ARRAY)
DEFINE vm_filas_pant		SMALLINT   -- FILAS EN PANTALLA
DEFINE vm_max_detalle		SMALLINT   -- MAXIMO NUMERO DE ELEMENTOS DEL
					   -- DETALLE


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ordp201.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'ordp201'

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
DEFINE i		SMALLINT
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_detalle  = 250
LET vm_estado   = 'A'

CREATE TEMP TABLE temp_oc(
	c10_numero_oc		INTEGER,
	p01_nomprov		VARCHAR(40),
	vm_fecha		DATE,
	c10_tot_compra		DECIMAL(12,2),
	aprobar			CHAR(1))

CREATE UNIQUE INDEX ind_tmp ON temp_oc(c10_numero_oc)

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31

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
OPEN WINDOW w_201 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_201 FROM '../forms/ordf201_1'
ELSE
	OPEN FORM f_201 FROM '../forms/ordf201_1c'
END IF
DISPLAY FORM f_201

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
INITIALIZE rm_c10.* TO NULL
INITIALIZE rm_c11.* TO NULL

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR

LET rm_orden[3]  = 'DESC'
LET vm_columna_1 = 3
LET vm_columna_2 = 1

--#DISPLAY 'No.Orden'        		TO tit_col1
--#DISPLAY 'Nombre del Proveedor'	TO tit_col2
--#DISPLAY 'Fecha'			TO tit_col3
--#DISPLAY 'Total' 			TO tit_col4
--#DISPLAY 'P'				TO tit_col5

CALL control_cargar_detalle()
CALL control_lee_detalle()

END FUNCTION



FUNCTION control_lee_detalle()
DEFINE i,j,k,m,salir,done	SMALLINT
DEFINE resp			CHAR(6)
DEFINE command_line		VARCHAR(100)
DEFINE query			VARCHAR(200)
DEFINE run_prog			CHAR(10)
DEFINE r_c12			RECORD LIKE ordt012.*

{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
LET salir = 0
CALL retorna_tam_arr()
LET vm_filas_pant  = vm_size_arr
LET k = 1
WHILE NOT salir

	LET query = 'SELECT * FROM temp_oc ',
		' ORDER BY ', vm_columna_1, ' ',
		      rm_orden[vm_columna_1], ', ',
		      vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE dprev FROM query
	DECLARE q_dprev CURSOR FOR dprev

	LET i = 1
	FOREACH q_dprev INTO r_detalle[i].*

		LET i = i + 1

	END FOREACH
	LET i = 1
	LET j = 1
	LET int_flag = 0
	CALL set_count(vm_ind_arr)
	INPUT ARRAY r_detalle WITHOUT DEFAULTS FROM r_detalle.*

		BEFORE INPUT
			--#CALL dialog.keysetlabel('INSERT','')
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")

		ON KEY(INTERRUPT)
			LET INT_FLAG = 0
			CALL fl_mensaje_abandonar_proceso()
               			RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF

        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 

		ON KEY(F5)
			LET command_line = run_prog || 'ordp200 ' || vg_base
					 || ' ' || vg_modulo || ' ' || vg_codcia
					    || ' ' || vg_codloc || ' ' ||
					    r_detalle[i].c10_numero_oc
			RUN command_line

		BEFORE ROW
			LET i = arr_curr()    # POSICION CORRIENTE EN EL ARRAY
			LET j = scr_line()    # POSICION CORRIENTE EN PANTALLA

			--#DISPLAY '' AT 20, 10
			--#DISPLAY i, ' de ', vm_ind_arr AT 20, 10

		BEFORE INSERT  
			IF i = arr_count() THEN
				LET vm_ind_arr = arr_count() - 1
			ELSE
				LET vm_ind_arr = arr_count()
			END IF
			EXIT INPUT

		AFTER FIELD aprobar
			IF r_detalle[i].aprobar = 'P' THEN
				CALL fl_lee_orden_compra(vg_codcia, vg_codloc,
						r_detalle[i].c10_numero_oc)
					RETURNING rm_c10.*
				IF rm_c10.c10_tipo_pago = 'R' THEN
					DECLARE q_c12 CURSOR FOR
						SELECT * FROM ordt012
							WHERE c12_compania  =
							    vg_codcia
							  AND c12_localidad =
							    vg_codloc
							  AND c12_numero_oc =
							    rm_c10.c10_numero_oc
					OPEN q_c12
					FETCH q_c12 INTO r_c12.*
					IF STATUS = NOTFOUND THEN
						CLOSE q_c12
						CALL fl_mostrar_mensaje('Debe especificar la forma de pago en ingreso de ordenes de compra.','exclamation')
						LET r_detalle[i].aprobar = 'A'
						DISPLAY r_detalle[i].aprobar TO
							r_detalle[j].aprobar
						NEXT FIELD aprobar
					END IF
					CLOSE q_c12
					FREE q_c12
				END IF
			END IF

		AFTER INPUT 
		FOR m = 1 TO vm_ind_arr
			IF r_detalle[m].aprobar = 'P' THEN
				LET m = 0
				EXIT FOR
			END IF
		END FOR
		IF m = 0 THEN
			BEGIN WORK
				CALL control_actualizacion()
					RETURNING done
				IF done = 0 THEN
					ROLLBACK WORK
					--CALL fgl_winmessage(vg_producto,'No se realizó proceso. ', 'exclamation')
					CALL fl_mostrar_mensaje('No se realizó proceso.','exclamation')
					CONTINUE INPUT
				ELSE 
					COMMIT WORK
					--CALL fgl_winmessage(vg_producto,'Proceso realizado Ok. ','info')
					CALL fl_mostrar_mensaje('Proceso realizado Ok.','info')
					CALL control_cargar_detalle()
				END IF 
		END IF
		ON KEY(F15)
			LET r_detalle[i].aprobar = r_detalle[j].aprobar
			LET k = 1
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F16)
			LET r_detalle[i].aprobar = r_detalle[j].aprobar
			LET k = 2
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F17)
			LET r_detalle[i].aprobar = r_detalle[j].aprobar
			LET k = 3
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F18)
			LET r_detalle[i].aprobar = r_detalle[j].aprobar
			LET k = 4
			LET int_flag = 2
			EXIT INPUT
		ON KEY(F19)
			LET r_detalle[i].aprobar = r_detalle[j].aprobar
			LET k = 5
			LET int_flag = 2
			EXIT INPUT
	END INPUT
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF

	FOR m = 1 TO arr_count()
	
		UPDATE temp_oc SET aprobar  = r_detalle[m].aprobar
			WHERE c10_numero_oc = r_detalle[m].c10_numero_oc

	END FOR
		
	IF int_flag = 2 THEN
		IF k <> vm_columna_1 THEN
			LET vm_columna_2           = vm_columna_1 
			LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
			LET vm_columna_1 = k 
		END IF
		IF rm_orden[vm_columna_1] = 'ASC' THEN
			LET rm_orden[vm_columna_1] = 'DESC'
		ELSE
			LET rm_orden[vm_columna_1] = 'ASC'
		END IF
	END IF
END WHILE

END FUNCTION



FUNCTION control_cargar_detalle()
DEFINE query		CHAR(600)
DEFINE i 		SMALLINT

CALL retorna_tam_arr()
LET vm_filas_pant = vm_size_arr
FOR i = 1 TO vm_filas_pant 
	INITIALIZE r_detalle[i].*    TO NULL
	CLEAR r_detalle[i].*
END FOR

LET query = 'SELECT c10_numero_oc, p01_nomprov, DATE(c10_fecing),'||
	    	' c10_tot_compra, c10_estado '||
		' FROM ordt010, cxpt001 '||
		' WHERE c10_compania  = ', vg_codcia,
		' AND c10_localidad   = ', vg_codloc,
		' AND c10_estado      ="', vm_estado,'"',
		' AND c10_codprov     = p01_codprov '

PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons

DELETE FROM temp_oc
LET i = 1

FOREACH q_cons INTO r_detalle[i].*

	INSERT INTO temp_oc VALUES (r_detalle[i].*)

	LET i = i + 1
        IF i > vm_max_detalle THEN
		EXIT FOREACH
	END IF	

END FOREACH 

LET i = i - 1
IF i = 0 THEN 
	--CALL fgl_winmessage(vg_producto,'No existen Ordenes de Compra para su aprobación.','info')
	CALL fl_mostrar_mensaje('No existen Ordenes de Compra para su aprobación.','info')
	EXIT PROGRAM
END IF

LET vm_ind_arr = i

END FUNCTION



FUNCTION control_actualizacion()
DEFINE done,j            SMALLINT

LET j	     = 1
LET done     = 0
WHILE TRUE
        WHENEVER ERROR CONTINUE
	IF r_detalle[j].aprobar = 'P' THEN
		IF NOT actualizar_cantback_maestro_item(j) THEN
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		UPDATE ordt010 
			SET c10_estado      = 'P',
			    c10_usua_aprob  = vg_usuario,
			    c10_fecha_aprob = CURRENT
                      WHERE c10_compania    = vg_codcia
                        AND c10_localidad   = vg_codloc
                        AND c10_numero_oc   = r_detalle[j].c10_numero_oc
	END IF
        WHENEVER ERROR STOP
        IF STATUS < 0 THEN
		{
                CALL fgl_winmessage(vg_producto,'La Orden de Compra número '||
				r_detalle[j].c10_numero_oc ||'  del proveedor  '
				||r_detalle[j].p01_nomprov ||
				    '  está siendo modificada, no se '||
				    'realizará la aprobacion. ','exclamation')
		}
		CALL fl_mostrar_mensaje('La Orden de Compra número ' ||
			    r_detalle[j].c10_numero_oc || ' del proveedor ' ||
			    r_detalle[j].p01_nomprov ||
			    ' está siendo modificada, no se ' ||
			    'realizará la aprobacion.','exclamation')
		EXIT WHILE
        END IF
	LET j = j + 1
	IF j > vm_ind_arr THEN
		LET done     = 1
		EXIT WHILE
	END IF
END WHILE
RETURN done

END FUNCTION



FUNCTION actualizar_cantback_maestro_item(i)
DEFINE i, intentar	SMALLINT
DEFINE salir 		SMALLINT
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c11		RECORD LIKE ordt011.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r93		RECORD LIKE rept093.*

CALL fl_lee_orden_compra(vg_codcia, vg_codloc, r_detalle[i].c10_numero_oc)
	RETURNING r_c10.*
IF r_c10.c10_tipo_orden <> 1 THEN
	RETURN 1
END IF
DECLARE q_c11 CURSOR FOR
	SELECT * FROM ordt011
		WHERE c11_compania  = vg_codcia
		  AND c11_localidad = vg_codloc
		  AND c11_numero_oc = r_detalle[i].c10_numero_oc
FOREACH q_c11 INTO r_c11.*
	INITIALIZE r_r93.* TO NULL
	SELECT * INTO r_r93.* FROM rept093
		WHERE r93_compania = vg_codcia
		  AND r93_item     = r_c11.c11_codigo
	IF r_r93.r93_compania IS NULL THEN
		LET salir = 1
		CONTINUE FOREACH
	END IF
	LET intentar = 1
	LET salir    = 0
	WHENEVER ERROR CONTINUE
	WHILE (intentar)
		INITIALIZE r_r10.* TO NULL
		DECLARE q_r10 CURSOR FOR
			SELECT * FROM rept010
				WHERE r10_compania = vg_codcia
				  AND r10_codigo   = r_c11.c11_codigo
			FOR UPDATE
		OPEN q_r10
		FETCH q_r10 INTO r_r10.*
		IF STATUS < 0 THEN
			LET intentar = mensaje_intentar(r_r10.r10_codigo)
		ELSE
			LET intentar = 0
			LET salir    = 1
		END IF
		IF r_r10.r10_compania IS NULL THEN
			ROLLBACK WORK
			CALL fl_mostrar_mensaje('Ocurrió un ERROR de Integridad con el Item ' || r_c11.c11_codigo CLIPPED || '. Por favor llame al ADMINISTRADOR.', 'stop')
			WHENEVER ERROR STOP
			EXIT PROGRAM
		END IF
	END WHILE
	WHENEVER ERROR STOP
	IF NOT intentar AND NOT salir THEN
		RETURN salir
	END IF
	UPDATE rept010 SET r10_cantback = r10_cantback - r_c11.c11_cant_ped
		WHERE CURRENT OF q_r10 
	CLOSE q_r10
	FREE q_r10
END FOREACH
RETURN salir

END FUNCTION



FUNCTION mensaje_intentar(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fl_hacer_pregunta('Item ' || item CLIPPED || ' bloqueado por otro usuario. Desea intentarlo nuevamente ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	CALL fl_mensaje_abandonar_proceso() RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF
RETURN intentar

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('r_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 6
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Orden'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
