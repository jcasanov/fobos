------------------------------------------------------------------------------
-- Titulo           : rolp201.4gl - Mantenimiento novedades procesos roles  
-- Elaboracion      : 18-mar-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp202 base modulo compania
-- Ultima Correccion: 31-jul-2003 
-- Motivo Correccion: Terminar este proceso
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*  
DEFINE rm_par		RECORD 
				n32_cod_liqrol	LIKE rolt032.n32_cod_liqrol,
				n_liqrol	LIKE rolt003.n03_nombre,
				n32_fecha_ini	LIKE rolt032.n32_fecha_ini,
				n32_fecha_fin	LIKE rolt032.n32_fecha_fin,
				n32_ano_proceso	LIKE rolt032.n32_ano_proceso,
				n32_mes_proceso	LIKE rolt032.n32_mes_proceso,
				n_mes		VARCHAR(15),
				n32_cod_depto	LIKE rolt032.n32_cod_depto,
				n_depto		LIKE gent034.g34_nombre,
				n33_cod_rubro	LIKE rolt033.n33_cod_rubro,
				n_rubro		LIKE rolt006.n06_nombre,
				n32_moneda	LIKE rolt032.n32_moneda,
				n_moneda	LIKE gent013.g13_nombre
			END RECORD

DEFINE vm_filas_pant 	INTEGER
DEFINE vm_numelm 	INTEGER
DEFINE vm_maxelm 	INTEGER
DEFINE rm_scr		ARRAY[1000] OF RECORD
				n33_cod_trab	LIKE rolt033.n33_cod_trab,
				n_trab		LIKE rolt030.n30_nombres,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE r_det_arch	ARRAY[1000] OF RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				val_rub		LIKE rolt006.n06_valor_fijo,
				flag_ident	LIKE rolt006.n06_flag_ident
			END RECORD
DEFINE r_det_nov	ARRAY[1000] OF RECORD
				n30_cod_trab	LIKE rolt030.n30_cod_trab,
				n30_nombres	LIKE rolt030.n30_nombres,
				flag_ident	LIKE rolt006.n06_flag_ident,
				comentarios	VARCHAR(30)
			END RECORD
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE rm_orden 	ARRAY[15] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE novedades	VARCHAR(100)
DEFINE vm_carg_arch	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp201.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)

LET vg_proceso  = 'rolp201'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
-- LET vg_codloc   = arg_val(4)
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

DEFINE salir 		INTEGER

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_201 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 1) 
OPEN FORM f_201 FROM '../forms/rolf201_1'
DISPLAY FORM f_201

CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existen configuraci�n general para este m�dulo.',
		'stop')
	EXIT PROGRAM
END IF

-- AQUI SE DEFINEN VALORES DE VARIABLES GLOBALES
LET vm_maxelm  = 1000
LET vm_max_det = 1000

LET salir = 0
WHILE (salir = 0)
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
	CALL control_ingresar()
	IF int_flag = 1 THEN
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION control_ingresar()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE comando		CHAR(100)
DEFINE resp 		VARCHAR(6)

INITIALIZE rm_par.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuraci�n general para este m�dulo.',
                'stop')
        EXIT PROGRAM
END IF
INITIALIZE rm_par.* TO NULL
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuraci�n para esta compa��a.',
                'stop')
        EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto,
                'Compa��a no est� activa.', 'stop')
        EXIT PROGRAM
END IF

LET rm_par.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_par.n32_mes_proceso = r_n01.n01_mes_proceso
LET rm_par.n_mes           =
        fl_justifica_titulo('I',
                fl_retorna_nombre_mes(rm_par.n32_mes_proceso), 12)

INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005
        WHERE n05_compania = vg_codcia AND n05_activo = 'S'
IF r_n05.n05_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe una liquidaci�n activa.', 'stop')
        EXIT PROGRAM
END IF

INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
        SELECT * FROM rolt032
                WHERE n32_compania    = vg_codcia  
                  AND n32_cod_liqrol  = r_n05.n05_proceso
                  AND n32_estado      = 'A'
                ORDER BY n32_fecha_ini DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
IF r_n32.n32_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No se ha registrado la liquidaci�n activa.', 
                                'stop')
        EXIT PROGRAM
END IF

IF r_n05.n05_fecini_act <> r_n32.n32_fecha_ini THEN
	CALL fl_mostrar_mensaje('La fecha de inicio de la liquidaci�n de '
                                || 'rol: ' || r_n32.n32_cod_liqrol || ' no '
				|| 'es correcta.', 
                                'stop')
        EXIT PROGRAM
END IF

LET rm_par.n32_cod_liqrol = r_n32.n32_cod_liqrol
LET rm_par.n32_fecha_ini  = r_n32.n32_fecha_ini
LET rm_par.n32_fecha_fin  = r_n32.n32_fecha_fin
LET rm_par.n32_moneda     = rg_gen.g00_moneda_base

CALL fl_lee_moneda(rg_gen.g00_moneda_base) RETURNING r_g13.*
CALL fl_lee_proceso_roles(rm_par.n32_cod_liqrol) RETURNING r_n03.*

LET rm_par.n_liqrol       = r_n03.n03_nombre
LET rm_par.n_moneda       = r_g13.g13_nombre

CALL lee_parametros()
IF int_flag THEN
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
        RETURN
END IF


IF NOT vm_carg_arch THEN

	CALL carga_trabajadores()

	CALL lee_valores_rubro()
	IF int_flag THEN
		LET int_flag = 0
		CLEAR FORM
		CALL limpia_pantalla()
		CALL mostrar_botones()
	        RETURN
	END IF

	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp = 'No' THEN
		LET int_flag = 0
		CLEAR FORM
		CALL limpia_pantalla()
		CALL mostrar_botones()
	        RETURN
	END IF

END IF


BEGIN WORK
LET int_flag = 0
CALL genera_novedades()
IF int_flag = 1 THEN
	LET int_flag = 0
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
	ROLLBACK WORK
	RETURN
END IF
COMMIT WORK
CALL fl_mostrar_mensaje('Proceso terminado OK.', 'info')
LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ',
               vg_codcia, ' X'
RUN comando
DECLARE q_n47 CURSOR FOR
	SELECT n47_cod_trab
		FROM rolt047
		WHERE n47_compania   = vg_codcia
		  AND n47_proceso    = 'VA'
		  AND n47_estado     = 'A'
		  AND n47_cod_liqrol = rm_par.n32_cod_liqrol
		  AND n47_fecha_ini  = rm_par.n32_fecha_ini
		  AND n47_fecha_fin  = rm_par.n32_fecha_fin
	UNION ALL
	SELECT n33_cod_trab
		FROM rolt033, rolt006
		WHERE n33_compania    = vg_codcia
		  AND n33_cod_liqrol  = rm_par.n32_cod_liqrol
		  AND n33_fecha_ini   = rm_par.n32_fecha_ini
		  AND n33_fecha_fin   = rm_par.n32_fecha_fin
		  AND n33_valor       > 0
		  AND n06_cod_rubro   = n33_cod_rubro
		  AND n06_flag_ident IN ('DM', 'DE')
FOREACH q_n47 INTO r_n47.n47_cod_trab
	LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ',
        	       vg_codcia, ' X ', r_n47.n47_cod_trab
	RUN comando
END FOREACH

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n06		RECORD LIKE rolt006.*

DEFINE resp 		VARCHAR(3)

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
                IF FIELD_TOUCHED(rm_par.*) THEN
                        LET int_flag = 0
                        CALL fl_mensaje_abandonar_proceso() RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
                                CLEAR FORM
				EXIT INPUT
                        END IF
		ELSE
                        LET int_flag = 1
                        CLEAR FORM
			EXIT INPUT
                END IF
       ON KEY(F2)
                IF INFIELD(n32_moneda) THEN
                        CALL fl_ayuda_monedas()
                                RETURNING r_g13.g13_moneda, r_g13.g13_nombre, 
					  r_g13.g13_decimales
                        IF r_g13.g13_moneda IS NOT NULL THEN
                                LET rm_par.n32_moneda = r_g13.g13_moneda
                                LET rm_par.n_moneda = r_g13.g13_nombre
                                DISPLAY BY NAME rm_par.*
                        END IF
                END IF
		IF INFIELD(n32_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING r_g34.g34_cod_depto, r_g34.g34_nombre
                        IF r_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_par.n32_cod_depto = r_g34.g34_cod_depto
				LET rm_par.n_depto       = r_g34.g34_nombre
                                DISPLAY BY NAME rm_par.n32_cod_depto,
						rm_par.n_depto
                        END IF
                END IF
                IF INFIELD(n33_cod_rubro) THEN
                        CALL fl_ayuda_rubros_generales_roles('00', 'T', 'T', 
                                                             'S', 'T', 'T')
                                RETURNING r_n06.n06_cod_rubro, 
					  r_n06.n06_nombre 
                        IF r_n06.n06_cod_rubro IS NOT NULL THEN
                                LET rm_par.n33_cod_rubro = r_n06.n06_cod_rubro
                                LET rm_par.n_rubro       = r_n06.n06_nombre
                                DISPLAY BY NAME rm_par.*
                        END IF
                END IF
		LET int_flag = 0
	ON KEY(F5)
		LET vm_carg_arch = 0
		IF control_cargar_archivo() THEN
			LET vm_carg_arch = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
	BEFORE INPUT
        	CALL dialog.keysetlabel('F5','Cargar Archivo')
        AFTER FIELD n32_moneda
                IF rm_par.n32_moneda IS NOT NULL THEN
                        CALL fl_lee_moneda(rm_par.n32_moneda)
                                RETURNING r_g13.*
                        IF r_g13.g13_moneda IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Moneda no exist
e.','exclamation')
				INITIALIZE rm_par.n_moneda TO NULL
				DISPLAY BY NAME rm_par.*
                                NEXT FIELD n32_moneda
                        END IF
                        IF r_g13.g13_estado = 'B' THEN
				INITIALIZE rm_par.n_moneda TO NULL
				DISPLAY BY NAME rm_par.*
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD n32_moneda
                        END IF
			LET rm_par.n32_moneda = r_g13.g13_moneda
			LET rm_par.n_moneda   = r_g13.g13_nombre
                ELSE
                        CALL fl_lee_moneda(rg_gen.g00_moneda_base)
                                RETURNING r_g13.*
                        LET rm_par.n32_moneda = rg_gen.g00_moneda_base
                        LET rm_par.n_moneda   = r_g13.g13_nombre
                END IF
		DISPLAY BY NAME rm_par.*
	AFTER FIELD n32_cod_depto
                IF rm_par.n32_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_par.n32_cod_depto)
                                RETURNING r_g34.*
                        IF r_g34.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Departamento no existe.','exclamation')
                                NEXT FIELD n32_cod_depto
                        END IF
			LET rm_par.n_depto = r_g34.g34_nombre
		ELSE
			LET rm_par.n_depto = NULL
                END IF
                DISPLAY BY NAME rm_par.n_depto
        AFTER FIELD n33_cod_rubro
                IF rm_par.n33_cod_rubro IS NOT NULL THEN
                        CALL fl_lee_rubro_roles(rm_par.n33_cod_rubro)
                                RETURNING r_n06.*
                        IF r_n06.n06_cod_rubro IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Rubro no exist
e.','exclamation')
				INITIALIZE rm_par.n_rubro TO NULL
				DISPLAY BY NAME rm_par.*
                                NEXT FIELD n33_cod_rubro
                        END IF
                        IF r_n06.n06_estado = 'B' THEN
				INITIALIZE rm_par.n_rubro TO NULL
				DISPLAY BY NAME rm_par.*
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD n33_cod_rubro
                        END IF
                        IF r_n06.n06_ing_usuario = 'N' THEN
				INITIALIZE rm_par.n_rubro TO NULL
				DISPLAY BY NAME rm_par.*
                                CALL fl_mostrar_mensaje('El rubro no puede ser ingresado por el usuario.', 'exclamation')
                                NEXT FIELD n33_cod_rubro
                        END IF
			LET rm_par.n33_cod_rubro = r_n06.n06_cod_rubro
			LET rm_par.n_rubro       = r_n06.n06_nombre
			SELECT * FROM rolt011
				WHERE n11_compania   = vg_codcia
				  AND n11_cod_liqrol = rm_par.n32_cod_liqrol
				  AND n11_cod_rubro  = r_n06.n06_cod_rubro
			IF STATUS = NOTFOUND THEN
				INITIALIZE rm_par.n33_cod_rubro, rm_par.n_rubro
					TO NULL
				DISPLAY r_n06.n06_nombre TO n_rubro
                                CALL fl_mostrar_mensaje('El rubro no esta asignado a esta quincena.', 'exclamation')
				DISPLAY BY NAME rm_par.*
                                NEXT FIELD n33_cod_rubro
			END IF
                ELSE
			INITIALIZE rm_par.n33_cod_rubro TO NULL
			INITIALIZE rm_par.n_rubro TO NULL
                END IF
		DISPLAY BY NAME rm_par.*
END INPUT

END FUNCTION



FUNCTION carga_trabajadores()
DEFINE query		CHAR(2000)
DEFINE expr_dep		VARCHAR(100)

LET expr_dep = NULL
IF rm_par.n32_cod_depto IS NOT NULL THEN
	LET expr_dep = '   AND n30_cod_depto = ', rm_par.n32_cod_depto
END IF
LET query = 'SELECT n30_cod_trab, n30_nombres, n33_valor ',
		' FROM rolt030, rolt033 ',
		' WHERE n30_compania    = ', vg_codcia,
		'   AND n30_estado      = "A" ',
		expr_dep CLIPPED,
		'   AND n30_fecha_ing  <= "', rm_par.n32_fecha_fin, '"',
		'   AND n33_compania    = n30_compania ',
 		'   AND n33_cod_liqrol  = "', rm_par.n32_cod_liqrol, '"',
		'   AND n33_fecha_ini   = "', rm_par.n32_fecha_ini, '"',
		'   AND n33_fecha_fin   = "', rm_par.n32_fecha_fin, '"',
		'   AND n33_cod_trab    = n30_cod_trab ',
		'   AND n33_cod_rubro   = ', rm_par.n33_cod_rubro,
	' UNION ',
		' SELECT n30_cod_trab, n30_nombres, n33_valor ',
			' FROM rolt030, rolt033 ',
			' WHERE n30_compania    = ', vg_codcia,
			'   AND n30_estado      = "I" ',
			expr_dep CLIPPED,
			'   AND n30_fecha_sal  >= "', rm_par.n32_fecha_ini, '"',
			'   AND n33_compania    = n30_compania ',
	 		'   AND n33_cod_liqrol  = "',rm_par.n32_cod_liqrol, '"',
			'   AND n33_fecha_ini   = "', rm_par.n32_fecha_ini, '"',
			'   AND n33_fecha_fin   = "', rm_par.n32_fecha_fin, '"',
			'   AND n33_cod_trab    = n30_cod_trab ',
			'   AND n33_cod_rubro   = ', rm_par.n33_cod_rubro,
	' INTO TEMP tmp_emp '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp

DECLARE q_trab CURSOR FOR SELECT * FROM tmp_emp ORDER BY n30_nombres

LET vm_numelm = 1
FOREACH q_trab INTO rm_scr[vm_numelm].*
	LET vm_numelm = vm_numelm + 1
	IF vm_numelm > vm_maxelm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
DROP TABLE tmp_emp

LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION lee_valores_rubro()
DEFINE i, j		SMALLINT
DEFINE resp		VARCHAR(6)

LET int_flag = 0
CALL set_count(vm_numelm)
INPUT ARRAY rm_scr WITHOUT DEFAULTS FROM ra_scr.*
	ON KEY(INTERRUPT)
        	LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso() RETURNING resp
                IF resp = 'Yes' THEN
                	LET int_flag = 1
                        EXIT INPUT
                END IF
	BEFORE INPUT
        	--#CALL dialog.keysetlabel('INSERT','')
        	--#CALL dialog.keysetlabel('DELETE','')
                LET vm_filas_pant = fgl_scr_size('ra_scr')
		CALL calcula_totales()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		DISPLAY i         TO num_row
		DISPLAY vm_numelm TO max_row
	BEFORE INSERT
		--#CANCEL INSERT
	BEFORE DELETE
		--#CANCEL DELETE
	AFTER FIELD n33_valor
		IF rm_scr[i].n33_valor IS NOT NULL THEN
			IF rm_scr[i].n33_valor < 0 THEN
				--NEXT FIELD n33_valor
			END IF
		ELSE
			LET rm_scr[i].n33_valor = 0
			DISPLAY rm_scr[i].* TO ra_scr[j].*
		END IF		
		CALL calcula_totales()
	AFTER INPUT 
		CALL calcula_totales()
END INPUT

END FUNCTION



FUNCTION limpia_pantalla()
DEFINE i		INTEGER

FOR i = 1  TO fgl_scr_size('ra_scr')
	INITIALIZE rm_scr[i].* TO NULL
	DISPLAY rm_scr[i].* TO ra_scr[i].*	
END FOR
END FUNCTION



FUNCTION calcula_totales()
DEFINE i		INTEGER
DEFINE tot_valor 	LIKE rolt033.n33_valor

LET tot_valor = 0
FOR i = 1 TO vm_numelm
	LET tot_valor = tot_valor + rm_scr[i].n33_valor	
END FOR 

DISPLAY BY NAME tot_valor

END FUNCTION



FUNCTION genera_novedades()

DEFINE i 		INTEGER

DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n33		RECORD LIKE rolt033.*

FOR i = 1 TO vm_numelm
	DELETE FROM rolt033	
		WHERE n33_compania   = vg_codcia
		  AND n33_cod_liqrol = rm_par.n32_cod_liqrol
		  AND n33_fecha_ini  = rm_par.n32_fecha_ini
		  AND n33_fecha_fin  = rm_par.n32_fecha_fin
		  AND n33_cod_trab   = rm_scr[i].n33_cod_trab 
		  AND n33_cod_rubro  = rm_par.n33_cod_rubro

        CALL fl_lee_rubro_roles(rm_par.n33_cod_rubro) RETURNING r_n06.*

	INITIALIZE r_n33.* TO NULL
	LET r_n33.n33_compania   = vg_codcia
	LET r_n33.n33_cod_liqrol = rm_par.n32_cod_liqrol
	LET r_n33.n33_fecha_ini  = rm_par.n32_fecha_ini
	LET r_n33.n33_fecha_fin  = rm_par.n32_fecha_fin
	LET r_n33.n33_cod_trab   = rm_scr[i].n33_cod_trab
	LET r_n33.n33_cod_rubro  = rm_par.n33_cod_rubro
	LET r_n33.n33_orden      = r_n06.n06_orden
	LET r_n33.n33_det_tot    = r_n06.n06_det_tot
	LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0
	LET r_n33.n33_cant_valor = r_n06.n06_cant_valor
			
	LET r_n33.n33_valor      = rm_scr[i].n33_valor
	INSERT INTO rolt033 VALUES (r_n33.*)
END FOR	

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
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversi�n ' ||
				    'para esta moneda',
				    'exclamation')
		INITIALIZE paridad TO NULL
	ELSE
		LET paridad = r_g14.g14_tasa 
	END IF
END IF

RETURN paridad

END FUNCTION



FUNCTION mostrar_botones()

DISPLAY 'C�digo'      		TO bt_cod_trab
DISPLAY 'Nombre Trabajador' 	TO bt_nom_trab
DISPLAY 'Valor Rubro' 		TO bt_valor

END FUNCTION



FUNCTION control_cargar_archivo()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE archivo		VARCHAR(255)

IF NOT cargar_datos_arch() THEN
	RETURN 0
END IF
LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 20
LET num_cols = 68
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf201_3 AT row_ini, 07 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf201_3 FROM '../forms/rolf201_3'
ELSE
	OPEN FORM f_rolf201_3 FROM '../forms/rolf201_3c'
END IF
DISPLAY FORM f_rolf201_3
LET vm_num_det = 0
CALL mostrar_botones_detalle2()
CALL borrar_detalle_arch()
CALL muestra_detalle_arch()
CALL borrar_detalle_arch()
CLOSE WINDOW w_rolf201_3
IF int_flag THEN
	DROP TABLE tmp_det_arch
	LET int_flag = 0
	RETURN 0
END IF
SELECT codigo, valor, n06_cod_rubro AS rubro
	FROM tmp_det_arch, rolt006
	WHERE flag_ident = n06_flag_ident
	INTO TEMP t1
DROP TABLE tmp_det_arch
BEGIN WORK
	WHENEVER ERROR CONTINUE
	UPDATE rolt033
		SET n33_valor =
			(SELECT valor
				FROM t1
				WHERE codigo = n33_cod_trab
				  AND rubro  = n33_cod_rubro) 
		WHERE n33_compania    = vg_codcia
		  AND n33_cod_liqrol  = rm_par.n32_cod_liqrol
		  AND n33_fecha_ini   = rm_par.n32_fecha_ini
		  AND n33_fecha_fin   = rm_par.n32_fecha_fin
		  AND EXISTS
			(SELECT 1 FROM t1
				WHERE codigo = n33_cod_trab
				  AND rubro  = n33_cod_rubro) 
		  --AND n33_valor       = 0
	IF STATUS <> 0 THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Ha ocurrido un ERROR al intentar cargar los datos del archivo en la NOMINA. Por favor LLAME AL ADMINISTRADOR.', 'exclamation')
		DROP TABLE t1
		RETURN 0
	END IF
	WHENEVER ERROR STOP
COMMIT WORK
CALL fl_mostrar_mensaje('Se cargaron los datos del archivo en la NOMINA.', 'info')
LET archivo = '$HOME/EXTRAS/VALORES_ADIC_', vg_usuario CLIPPED, '_',
		TODAY USING "yyyy-mm-dd", '_', TIME, '.csv'
LET archivo = 'mv -f VALORES_ADIC.csv ', archivo CLIPPED
RUN archivo
RUN 'rm -rf VALORES_ADIC.csv '
DROP TABLE t1
RETURN 1

END FUNCTION



FUNCTION cargar_datos_arch()
DEFINE query		CHAR(800)
DEFINE cuantos		INTEGER
DEFINE otras		SMALLINT
DEFINE mensaje		VARCHAR(200)

SELECT n30_cod_trab AS codigo, n30_nombres AS empleado, n30_sueldo_mes AS valor,
	n30_mon_sueldo AS flag_ident
	FROM rolt030
	WHERE n30_compania = 999
	INTO TEMP t1
RUN 'mv -f $HOME/tmp/VALORES_ADIC.csv .'
RUN 'dos2unix VALORES_ADIC.csv'
WHENEVER ERROR CONTINUE
LOAD FROM "VALORES_ADIC.csv" DELIMITER "," INSERT INTO t1
IF STATUS = 846 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque falta el codigo o el valor en alguna linea del archivo.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS = 847 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque uno de los registros tiene una COMA en vez del PUNTO DECIMAL.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS = -805 THEN
	DROP TABLE t1
	LET mensaje = 'No se puede cargar el archivo porque no existe en la ',
			'ruta: ', FGL_GETENV("HOME") CLIPPED, '/tmp/.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
IF STATUS <> 0 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque ha ocurrido un error. LLAME AL ADMINISTRADOR.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN 0
END IF
WHENEVER ERROR STOP
SELECT COUNT(*) INTO vm_num_det FROM t1
IF vm_num_det = 0 THEN
	DROP TABLE t1
	CALL fl_mostrar_mensaje('No se puede cargar el archivo porque esta vacio.', 'exclamation')
	RETURN 0
END IF
SELECT * FROM t1
	INTO TEMP tmp_det_arch
SELECT * FROM t1
	WHERE NOT EXISTS
		(SELECT 1 FROM rolt030
			WHERE n30_compania = vg_codcia
			  AND n30_cod_trab = codigo)
	INTO TEMP tmp_fal
DROP TABLE t1
SELECT codigo, empleado, flag_ident,
	"EMPLEADO CON ESTADO INACTIVO" AS comentario
	FROM tmp_det_arch, rolt030
	WHERE n30_compania = vg_codcia
	  AND n30_cod_trab = codigo
	  AND n30_estado   = "I"
	INTO TEMP tmp_nov
SELECT COUNT(*) INTO cuantos FROM tmp_nov
LET novedades = NULL
IF cuantos > 0 THEN
	LET novedades = 'EXISTEN EMPLEADOS CON ESTADO INACTIVO'
END IF
SELECT codigo, flag_ident, COUNT(*) AS ctos
	FROM tmp_det_arch
	GROUP BY 1, 2
	HAVING COUNT(*) > 1
	INTO TEMP t1
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos > 0 THEN
	IF novedades IS NULL THEN
		LET novedades = 'EXISTEN EMPLEADOS CON RUBROS REPETIDOS'
	ELSE
		LET novedades = novedades CLIPPED, ' Y TAMBIEN REPETIDO'
	END IF
	LET query = 'INSERT INTO tmp_nov ',
		'SELECT UNIQUE a.codigo, a.empleado, a.flag_ident, ',
		       '(SELECT "COD. EMPLEADO ESTA REPETIDO: " ',
				'|| t1.ctos FROM t1 ',
			'WHERE t1.codigo = a.codigo) AS comentario ',
		'FROM tmp_det_arch a ',
		'WHERE a.codigo IN ',
			'(SELECT t1.codigo FROM t1 ',
				'WHERE t1.codigo     = a.codigo ',
				'  AND t1.flag_ident = a.flag_ident) '
	PREPARE exec_nov1 FROM query
	EXECUTE exec_nov1
END IF
DROP TABLE t1
LET query = ' SELECT codigo, empleado, flag_ident, ',
			'CASE WHEN valor IS NULL ',
				'THEN "EMPLEADO SIN VALORES" ',
				'ELSE "EMPLEADO CON VALOR CERO" ',
			'END AS comentario ',
		'FROM tmp_det_arch ',
		'WHERE valor IS NULL ',
		'   OR valor <= 0 ',
		'INTO TEMP t1'
PREPARE exec_nov2 FROM query
EXECUTE exec_nov2
SELECT COUNT(*) INTO cuantos FROM t1
LET otras = 0
IF cuantos > 0 THEN
	IF novedades IS NULL THEN
		LET novedades = 'EXISTEN EMPLEADOS SIN LA COLUMNA VALOR'
	ELSE
		LET novedades = novedades CLIPPED, '. OTRAS NOVEDADES'
		LET otras     = 1
	END IF
	INSERT INTO tmp_nov SELECT * FROM t1
END IF
DROP TABLE t1
SELECT COUNT(*) INTO cuantos FROM tmp_fal
IF cuantos > 0 THEN
	IF novedades IS NULL THEN
		LET novedades = 'ESTOS COD. EMPLEADOS NO EXISTEN EN LA BASE'
	END IF
	IF NOT otras THEN
		LET novedades = novedades CLIPPED, '. OTRAS NOVEDADES'
	END IF
	INSERT INTO tmp_nov
		SELECT codigo, "N/A" AS empleado, flag_ident,
			"CODIGO EMPLEADO NO EXISTE" AS comentario
			FROM tmp_fal
END IF
SELECT COUNT(*) INTO cuantos FROM tmp_nov
DROP TABLE tmp_fal
IF cuantos > 0 THEN
	DROP TABLE tmp_det_arch
	CALL control_cargar_novedades()
	RETURN 0
END IF
DROP TABLE tmp_nov
RETURN 1

END FUNCTION



FUNCTION borrar_detalle_arch()
DEFINE i		SMALLINT

LET vm_num_det = 0
FOR i = 1 TO fgl_scr_size("r_det_arch")
	CLEAR r_det_arch[i].*
END FOR
FOR i = 1 TO vm_max_det
	INITIALIZE r_det_arch[i].* TO NULL
END FOR

END FUNCTION



FUNCTION muestra_detalle_arch()
DEFINE i, j, col, salir	SMALLINT
DEFINE resp		CHAR(6)
DEFINE query		CHAR(400)
DEFINE nom_rub		LIKE rolt006.n06_nombre
DEFINE valor		LIKE rolt006.n06_valor_fijo

LET col           = 4
LET rm_orden[col] = 'ASC'
LET vm_columna_1  = col
LET vm_columna_2  = 2
WHILE TRUE
	LET query = 'SELECT * FROM tmp_det_arch ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det2 FROM query
	DECLARE q_det2 CURSOR FOR det2
	LET vm_num_det = 1
        FOREACH q_det2 INTO r_det_arch[vm_num_det].*
                LET vm_num_det = vm_num_det + 1
                IF vm_num_det > vm_max_det THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_num_det = vm_num_det - 1
	LET salir    = 0
	LET int_flag = 0
	CALL set_count(vm_num_det)
	INPUT ARRAY r_det_arch WITHOUT DEFAULTS FROM r_det_arch.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag   = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_empleado(r_det_arch[i].n30_cod_trab)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT INPUT
		ON KEY(F16)
			LET col = 2
			EXIT INPUT
		ON KEY(F17)
			LET col = 3
			EXIT INPUT
		ON KEY(F18)
			LET col = 4
			EXIT INPUT
		--#BEFORE INPUT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
			--#CALL dialog.keysetlabel('DELETE','')
			--#CALL dialog.keysetlabel('INSERT','')
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#DISPLAY i TO cur_row
			--#DISPLAY vm_num_det TO max_row
			--#SELECT n06_nombre
				--#INTO nom_rub
				--#FROM rolt006
				--#WHERE n06_flag_ident =
					--#r_det_arch[i].flag_ident
			--#DISPLAY BY NAME nom_rub
		BEFORE DELETE
			--#CANCEL DELETE
		BEFORE INSERT
			--#CANCEL INSERT
		BEFORE FIELD val_rub
			LET valor = r_det_arch[i].val_rub
		AFTER FIELD val_rub
			LET r_det_arch[i].val_rub = valor
			DISPLAY r_det_arch[i].val_rub TO r_det_arch[j].val_rub
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF int_flag = 1 OR salir THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE

END FUNCTION



FUNCTION mostrar_botones_detalle2()

--#DISPLAY "Codigo"	TO tit_col1
--#DISPLAY "Empleado"	TO tit_col2
--#DISPLAY "Valor"	TO tit_col3
--#DISPLAY "Rb"		TO tit_col4

END FUNCTION



FUNCTION control_cargar_novedades()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 18
LET num_cols = 74
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf201_4 AT row_ini, 04 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf201_4 FROM '../forms/rolf201_4'
ELSE
	OPEN FORM f_rolf201_4 FROM '../forms/rolf201_4c'
END IF
DISPLAY FORM f_rolf201_4
LET vm_num_det = 0
CALL mostrar_botones_detalle3()
DISPLAY BY NAME novedades
CALL muestra_detalle_nov()
LET int_flag = 0
CLOSE WINDOW w_rolf201_4
RETURN

END FUNCTION



FUNCTION muestra_detalle_nov()
DEFINE i, j, col	SMALLINT
DEFINE query		CHAR(400)
DEFINE nom_rub		LIKE rolt006.n06_nombre

LET col           = 4
LET rm_orden[col] = 'DESC'
LET vm_columna_1  = col
LET vm_columna_2  = 1
WHILE TRUE
	LET query = 'SELECT * FROM tmp_nov ',
			' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE det3 FROM query
	DECLARE q_det3 CURSOR FOR det3
	LET vm_num_det = 1
        FOREACH q_det3 INTO r_det_nov[vm_num_det].*
                LET vm_num_det = vm_num_det + 1
                IF vm_num_det > vm_max_det THEN
                        EXIT FOREACH
                END IF
        END FOREACH
        LET vm_num_det = vm_num_det - 1
	LET int_flag = 0
	CALL set_count(vm_num_det)
	DISPLAY ARRAY r_det_nov TO r_det_nov.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL ver_empleado(r_det_nov[i].n30_cod_trab)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET col = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET col = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET col = 4
			EXIT DISPLAY
		--#BEFORE DISPLAY
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#BEFORE ROW
			--#LET i = arr_curr()
	        	--#LET j = scr_line()
			--#DISPLAY i TO cur_row
			--#DISPLAY vm_num_det TO max_row
			--#SELECT n06_nombre
				--#INTO nom_rub
				--#FROM rolt006
				--#WHERE n06_flag_ident =
					--#r_det_nov[i].flag_ident
			--#DISPLAY BY NAME nom_rub
		--#AFTER DISPLAY
			--#CONTINUE DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE tmp_nov

END FUNCTION



FUNCTION mostrar_botones_detalle3()

--#DISPLAY "Codigo"		TO tit_col1
--#DISPLAY "Empleado"		TO tit_col2
--#DISPLAY "Rb"			TO tit_col3
--#DISPLAY "Observaciones"	TO tit_col4

END FUNCTION



FUNCTION ver_empleado(codigo)
DEFINE codigo		LIKE rolt030.n30_cod_trab
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA',
	vg_separador, 'fuentes', vg_separador, run_prog, ' rolp108 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', codigo
RUN comando

END FUNCTION
