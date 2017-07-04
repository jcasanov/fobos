--------------------------------------------------------------------------------
-- Titulo           : rolp256.4gl - Mantenimiento dias/sobretiempos/multas
-- Elaboracion      : 05-Sep-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp256 base modulo compania
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
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
				n33_cod_rubro	LIKE rolt033.n33_cod_rubro,
				n_rubro		LIKE rolt006.n06_nombre,
				n32_moneda	LIKE rolt032.n32_moneda,
				n_moneda	LIKE gent013.g13_nombre
			END RECORD
DEFINE rm_scr		ARRAY[1000] OF RECORD
				n33_cod_trab	LIKE rolt033.n33_cod_trab,
				n_trab		LIKE rolt030.n30_nombres,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE rm_totales	RECORD
				total01		DECIMAL(12,2),
				total02		DECIMAL(12,2),
				total03		DECIMAL(12,2),
				total04		DECIMAL(12,2),
				total05		DECIMAL(12,2),
				total06		DECIMAL(12,2),
				total07		DECIMAL(12,2),
				total08		DECIMAL(12,2),
				total09		DECIMAL(12,2),
				total10		DECIMAL(12,2),
				total11		DECIMAL(12,2),
				total12		DECIMAL(12,2)
			END RECORD
DEFINE vm_filas_pant 	INTEGER
DEFINE vm_numelm 	INTEGER
DEFINE vm_maxelm 	INTEGER



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp256.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp256'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
-- LET vg_codloc   = arg_val(4)
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE salir 		INTEGER

CALL fl_nivel_isolation()
OPEN WINDOW w_rolp256 AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_rolf256 FROM '../forms/rolf256_1'
DISPLAY FORM f_rolf256
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existen configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF
LET vm_maxelm = 1000
LET salir     = 0
WHILE (salir = 0)
	CLEAR FORM
	LET vm_numelm = 0
	CALL limpia_pantalla()
	CALL mostrar_botones()
	CALL datos_liquidacion()
	CALL control_ingresar()
	IF int_flag = 1 THEN
		LET salir = 1
	END IF
END WHILE

END FUNCTION



FUNCTION datos_liquidacion()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_g13		RECORD LIKE gent013.*

INITIALIZE rm_par.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración general para este módulo.',
                'stop')
        EXIT PROGRAM
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto,
                'No existe configuración para esta compañía.',
                'stop')
        EXIT PROGRAM
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fgl_winmessage(vg_producto,
                'Compañía no está activa.', 'stop')
        EXIT PROGRAM
END IF
LET rm_par.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_par.n32_mes_proceso = r_n01.n01_mes_proceso
CALL retorna_mes()
INITIALIZE r_n05.* TO NULL
SELECT * INTO r_n05.* FROM rolt005
        WHERE n05_compania = vg_codcia AND n05_activo = 'S'
IF r_n05.n05_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe una liquidación activa.', 'stop')
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
        CALL fl_mostrar_mensaje('No se ha registrado la liquidación activa.', 
                                'stop')
        EXIT PROGRAM
END IF
IF r_n05.n05_fecini_act <> r_n32.n32_fecha_ini THEN
	CALL fl_mostrar_mensaje('La fecha de inicio de la liquidación de '
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
DISPLAY BY NAME rm_par.*

END FUNCTION



FUNCTION control_ingresar()
DEFINE comando		CHAR(100)
DEFINE resp 		VARCHAR(6)

CALL lee_parametros()
IF int_flag THEN
	CLEAR FORM
	CALL limpia_pantalla()
	CALL mostrar_botones()
        RETURN
END IF
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
LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ', vg_codcia, ' X'
RUN comando

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE resp 		VARCHAR(3)

LET int_flag = 0
INPUT BY NAME rm_par.n33_cod_rubro WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
                IF FIELD_TOUCHED(rm_par.n33_cod_rubro) THEN
                        LET int_flag = 0
                        CALL fl_mensaje_abandonar_proceso() RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
				EXIT INPUT
                        END IF
		ELSE
                        LET int_flag = 1
			EXIT INPUT
                END IF
       ON KEY(F2)
                IF INFIELD(n33_cod_rubro) THEN
                        CALL fl_ayuda_rubros_dias_tiempos()
				RETURNING r_n06.n06_cod_rubro, r_n06.n06_nombre 
                        IF r_n06.n06_cod_rubro IS NOT NULL THEN
                                LET rm_par.n33_cod_rubro = r_n06.n06_cod_rubro
                                LET rm_par.n_rubro       = r_n06.n06_nombre
                                DISPLAY BY NAME rm_par.*
                        END IF
                END IF
		LET int_flag = 0
	ON KEY(F5)
		CALL control_consulta()
		LET int_flag = 0
	ON KEY(F6)
		CALL control_imprimir()
		LET int_flag = 0
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
			IF NOT valido_rubro() THEN
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



FUNCTION valido_rubro()

DECLARE q_rub CURSOR FOR
	SELECT n06_cod_rubro
		FROM rolt006
		WHERE n06_estado      = 'A'
		  AND n06_ing_usuario = 'S'
		  AND n06_calculo     = 'N'
		  AND (n06_flag_ident IN ('H5', 'H1', 'C1', 'MU')
		   OR  n06_cod_rubro  IN
			(SELECT n08_rubro_base
				FROM rolt006 a, rolt008
				WHERE a.n06_flag_ident = 'DT'
				  AND a.n06_estado     = 'A'
				  AND n08_cod_rubro    = n06_cod_rubro))
		  AND n06_cod_rubro    = rm_par.n33_cod_rubro
OPEN q_rub
FETCH q_rub
IF STATUS = NOTFOUND THEN
	CLOSE q_rub
	FREE q_rub
	CALL fl_mostrar_mensaje('Este rubro no es un rubro de dias, sobretiempos, comisiones o multas.', 'exclamation')
	RETURN 0
END IF
CLOSE q_rub
FREE q_rub
RETURN 1

END FUNCTION



FUNCTION carga_trabajadores()

DECLARE q_trab CURSOR FOR
	SELECT n30_cod_trab, n30_nombres, n33_valor
	FROM rolt030, rolt033
	WHERE n30_compania    = vg_codcia
	  AND n30_estado      = 'A'
	  AND n30_fecha_ing  <= rm_par.n32_fecha_fin
	  AND n33_compania    = n30_compania
 	  AND n33_cod_liqrol  = rm_par.n32_cod_liqrol
	  AND n33_fecha_ini   = rm_par.n32_fecha_ini
	  AND n33_fecha_fin   = rm_par.n32_fecha_fin
	  AND n33_cod_trab    = n30_cod_trab
	  AND n33_cod_rubro   = rm_par.n33_cod_rubro
	ORDER BY n30_nombres
LET vm_numelm = 1
FOREACH q_trab INTO rm_scr[vm_numelm].*
	IF rm_scr[vm_numelm].n33_valor = 0 THEN
		LET rm_scr[vm_numelm].n33_valor = NULL
	END IF
	LET vm_numelm = vm_numelm + 1
	IF vm_numelm > vm_maxelm THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
	END IF
END FOREACH
LET vm_numelm = vm_numelm - 1

END FUNCTION



FUNCTION lee_valores_rubro()
DEFINE i, j, salir	INTEGER
DEFINE resp		VARCHAR(6)

LET int_flag = 0
OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
LET salir = 0
WHILE (salir = 0)
CALL set_count(vm_numelm)
INPUT ARRAY rm_scr WITHOUT DEFAULTS FROM rm_scr.*
	ON KEY(INTERRUPT)
        	LET int_flag = 0
                CALL fl_mensaje_abandonar_proceso() RETURNING resp
                IF resp = 'Yes' THEN
                	LET int_flag = 1
                        EXIT INPUT
                END IF
	ON KEY(F5)
		CALL control_consulta()
		LET int_flag = 0
	ON KEY(F6)
		CALL control_imprimir()
		LET int_flag = 0
	BEFORE INPUT
        	--#CALL dialog.keysetlabel('INSERT','')
        	--#CALL dialog.keysetlabel('DELETE','')
                LET vm_filas_pant = fgl_scr_size('rm_scr')
		CALL calcula_totales()
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		DISPLAY i         TO num_row
		DISPLAY vm_numelm TO max_row
	BEFORE INSERT
		LET salir = 0
		EXIT INPUT
	AFTER FIELD n33_valor
		IF rm_scr[i].n33_valor IS NOT NULL THEN
			IF rm_scr[i].n33_valor < 0 THEN
				--NEXT FIELD n33_valor
			END IF
		ELSE
			LET rm_scr[i].n33_valor = NULL
			DISPLAY rm_scr[i].* TO rm_scr[j].*
		END IF		
		CALL calcula_totales()
	AFTER INPUT 
		CALL calcula_totales()
		LET salir = 1
END INPUT
IF int_flag = 1 THEN
	LET salir = 1
END IF
END WHILE

END FUNCTION



FUNCTION limpia_pantalla()
DEFINE i		INTEGER

FOR i = 1  TO fgl_scr_size('rm_scr')
	INITIALIZE rm_scr[i].* TO NULL
	DISPLAY rm_scr[i].* TO rm_scr[i].*	
END FOR

END FUNCTION



FUNCTION calcula_totales()
DEFINE i		INTEGER
DEFINE tot_valor 	LIKE rolt033.n33_valor

LET tot_valor = 0
FOR i = 1 TO vm_numelm
	IF rm_scr[i].n33_valor IS NULL THEN
		CONTINUE FOR
	END IF
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
	IF rm_scr[i].n33_valor IS NOT NULL THEN
		LET r_n33.n33_valor = rm_scr[i].n33_valor
	ELSE
		LET r_n33.n33_valor = 0
	END IF
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
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fgl_winmessage(vg_producto, 
				    'No existe factor de conversión ' ||
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

DISPLAY 'Código'      		TO bt_cod_trab
DISPLAY 'Nombre Trabajador' 	TO bt_nom_trab
DISPLAY 'Valor Rubro' 		TO bt_valor

END FUNCTION



FUNCTION control_consulta()

CALL lee_parametros2()
IF int_flag THEN
	CALL datos_liquidacion()
	RETURN
END IF
CALL control_imprimir()
CALL datos_liquidacion()

END FUNCTION



FUNCTION lee_parametros2()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE anio		LIKE rolt039.n39_ano_proceso
DEFINE mes		LIKE rolt039.n39_mes_proceso
DEFINE mes_aux		LIKE rolt039.n39_mes_proceso
DEFINE resp      	CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_par.n32_cod_liqrol, rm_par.n32_ano_proceso,
	rm_par.n32_mes_proceso
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_par.n32_cod_liqrol, rm_par.n32_ano_proceso,
				 rm_par.n32_mes_proceso)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			EXIT INPUT
		END IF       	
	ON KEY(F2)
		IF INFIELD(n32_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso, r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_par.n32_cod_liqrol = r_n03.n03_proceso
				LET rm_par.n_liqrol       = r_n03.n03_nombre
				DISPLAY BY NAME rm_par.n32_cod_liqrol,
						rm_par.n_liqrol
			END IF
		END IF
		IF INFIELD(n32_mes_proceso) THEN
			CALL fl_ayuda_mostrar_meses()
				RETURNING mes_aux, rm_par.n_mes
			IF mes_aux IS NOT NULL THEN
				LET rm_par.n32_mes_proceso = mes_aux
				DISPLAY BY NAME rm_par.n32_mes_proceso,
						rm_par.n_mes
			END IF
                END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n32_ano_proceso
		LET anio = rm_par.n32_ano_proceso
	BEFORE FIELD n32_mes_proceso
		LET mes = rm_par.n32_mes_proceso
	AFTER FIELD n32_cod_liqrol
		IF rm_par.n32_cod_liqrol IS NOT NULL THEN
			CALL fl_lee_proceso_roles(rm_par.n32_cod_liqrol)
				RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('El Proceso no existe en la Compañía.', 'exclamation')
                        	NEXT FIELD n32_cod_liqrol
			END IF
			LET rm_par.n_liqrol = r_n03.n03_nombre
			DISPLAY BY NAME rm_par.n_liqrol
			IF r_n03.n03_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
                        	NEXT FIELD n32_cod_liqrol
			END IF
		ELSE
			LET rm_par.n_liqrol = NULL
			DISPLAY BY NAME rm_par.n_liqrol
		END IF
	AFTER FIELD n32_ano_proceso
		IF rm_par.n32_ano_proceso IS NOT NULL THEN
			IF rm_par.n32_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n32_ano_proceso
			END IF
		ELSE
			LET rm_par.n32_ano_proceso = anio
			DISPLAY BY NAME rm_par.n32_ano_proceso
		END IF
		CALL mostrar_fechas()
	AFTER FIELD n32_mes_proceso
		IF rm_par.n32_mes_proceso IS NULL THEN
			LET rm_par.n32_mes_proceso = mes
			DISPLAY BY NAME rm_par.n32_mes_proceso
		END IF
		CALL retorna_mes()
		DISPLAY BY NAME rm_par.n_mes
		CALL mostrar_fechas()
	AFTER INPUT
		INITIALIZE r_n32.* TO NULL
		DECLARE q_liqact CURSOR FOR
			SELECT * FROM rolt032
				WHERE n32_compania   = vg_codcia
				  AND n32_cod_liqrol = rm_par.n32_cod_liqrol
				  AND n32_fecha_ini  = rm_par.n32_fecha_ini
				  AND n32_fecha_fin  = rm_par.n32_fecha_fin
				ORDER BY n32_fecha_fin DESC
		OPEN q_liqact
		FETCH q_liqact INTO r_n32.*
		IF r_n32.n32_compania IS NULL THEN
			CALL fl_mostrar_mensaje('Liquidación no se ha generado todavía.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION retorna_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_par.n32_mes_proceso), 10)
	RETURNING rm_par.n_mes

END FUNCTION 



FUNCTION mostrar_fechas()

CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_par.n32_cod_liqrol,
				rm_par.n32_ano_proceso, rm_par.n32_mes_proceso)
	RETURNING rm_par.n32_fecha_ini, rm_par.n32_fecha_fin
DISPLAY BY NAME rm_par.n32_fecha_ini, rm_par.n32_fecha_fin

END FUNCTION 



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
IF vm_numelm = 0 THEN
	DECLARE q_trab2 CURSOR FOR
		SELECT n30_cod_trab, n30_nombres, 0.00
		FROM rolt030
		WHERE n30_compania   = vg_codcia
		  AND n30_estado     = 'A'
		  AND n30_fecha_ing <= rm_par.n32_fecha_fin
		ORDER BY n30_nombres
	LET vm_numelm = 1
	FOREACH q_trab2 INTO rm_scr[vm_numelm].*
		IF rm_scr[vm_numelm].n33_valor = 0 THEN
			LET rm_scr[vm_numelm].n33_valor = NULL
		END IF
		LET vm_numelm = vm_numelm + 1
		IF vm_numelm > vm_maxelm THEN
			CALL fl_mensaje_arreglo_incompleto()
			EXIT PROGRAM
		END IF
	END FOREACH
	LET vm_numelm = vm_numelm - 1
END IF
START REPORT reporte_datos_rol TO PIPE comando
LET rm_totales.total01 = 0
LET rm_totales.total02 = 0
LET rm_totales.total03 = 0
LET rm_totales.total04 = 0
LET rm_totales.total05 = 0
LET rm_totales.total06 = 0
LET rm_totales.total07 = 0
LET rm_totales.total08 = 0
LET rm_totales.total09 = 0
LET rm_totales.total10 = 0
LET rm_totales.total11 = 0
LET rm_totales.total12 = 0
FOR i = 1 TO vm_numelm
	OUTPUT TO REPORT reporte_datos_rol(i)
END FOR
FINISH REPORT reporte_datos_rol

END FUNCTION



REPORT reporte_datos_rol(i)
DEFINE i		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(19)
DEFINE val01		DECIMAL(12,2)
DEFINE val02		DECIMAL(12,2)
DEFINE val03		DECIMAL(12,2)
DEFINE val04		DECIMAL(12,2)
DEFINE val05		DECIMAL(12,2)
DEFINE val06		DECIMAL(12,2)
DEFINE val07		DECIMAL(12,2)
DEFINE val08		DECIMAL(12,2)
DEFINE val09		DECIMAL(12,2)
DEFINE val10		DECIMAL(12,2)
DEFINE val11		DECIMAL(12,2)
DEFINE val12		DECIMAL(12,2)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET titulo      = "DATOS PARA EL ROL FECHA: ",
				rm_par.n32_fecha_fin USING "dd-mm-yyyy"
	CALL fl_justifica_titulo('C', titulo, 46) RETURNING titulo
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 010, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 014, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_comp
	SKIP 1 LINES
	CALL fl_justifica_titulo('D', 'USUARIO: ' || vg_usuario, 19)
		RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	PRINT COLUMN 001, r_g01.g01_razonsocial CLIPPED,
	      COLUMN 125, 'PAG. ', PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 042, '** LIQUIDACION : ', rm_par.n32_cod_liqrol, ' ',
		rm_par.n_liqrol CLIPPED
	PRINT COLUMN 042, '** PERIODO     : ',
		rm_par.n32_fecha_ini USING "dd-mm-yyyy", '  -  ',
		rm_par.n32_fecha_fin USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA IMPRESION  : ', DATE(TODAY) USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 113, usuario
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 040, 'V A L O R E S  P O R  D I A S',
	      COLUMN 080, 'H O R A S',
	      COLUMN 102, 'V A C A C I O N E S'
	PRINT COLUMN 001, 'COD.',
	      COLUMN 011, 'E M P L E A D O S',
	      COLUMN 034, ' TRAB.',
	      COLUMN 041, ' FALT.',
	      COLUMN 048, '  ENF.',
	      COLUMN 055, '  VAC.',
	      COLUMN 062, '  MAT.',
	      COLUMN 069, '  LIC.',
	      COLUMN 076, '   50%',
	      COLUMN 083, '  100%',
	      COLUMN 090, 'COMISIONES',
	      COLUMN 101, 'TOTAL GAN.',
	      COLUMN 112, '    CHEQUE',
	      COLUMN 123, '    MULTAS'
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'

ON EVERY ROW
	NEED 3 LINES
	LET val01 = valor_rubro('DT', i)
	LET val02 = valor_rubro('DF', i)
	LET val03 = valor_rubro('DE', i)
	LET val04 = valor_rubro('DV', i)
	LET val05 = valor_rubro('DM', i)
	LET val06 = valor_rubro('DL', i)
	LET val07 = valor_rubro('H5', i)
	LET val08 = valor_rubro('H1', i)
	LET val09 = valor_rubro('C1', i)
	LET val10 = valor_rubro('VV', i)
	LET val11 = valor_rubro('XV', i)
	LET val12 = valor_rubro('MU', i)
	PRINT COLUMN 001, rm_scr[i].n33_cod_trab	USING "<<&&&",
	      COLUMN 007, rm_scr[i].n_trab[1, 26]	CLIPPED,
	      COLUMN 034, val01				USING "##&.##",
	      COLUMN 041, val02				USING "###.##",
	      COLUMN 048, val03				USING "###.##",
	      COLUMN 055, val04				USING "###.##",
	      COLUMN 062, val05				USING "###.##",
	      COLUMN 069, val06				USING "###.##",
	      COLUMN 076, val07				USING "###.##",
	      COLUMN 083, val08				USING "###.##",
	      COLUMN 090, val09				USING "###,###.##",
	      COLUMN 101, val10				USING "###,###.##",
	      COLUMN 112, val11				USING "###,###.##",
	      COLUMN 123, val12				USING "###,###.##"
	LET rm_totales.total01 = rm_totales.total01 + val01
	IF val02 IS NOT NULL THEN
		LET rm_totales.total02 = rm_totales.total02 + val02
	END IF
	IF val03 IS NOT NULL THEN
		LET rm_totales.total03 = rm_totales.total03 + val03
	END IF
	IF val04 IS NOT NULL THEN
		LET rm_totales.total04 = rm_totales.total04 + val04
	END IF
	IF val05 IS NOT NULL THEN
		LET rm_totales.total05 = rm_totales.total05 + val05
	END IF
	IF val06 IS NOT NULL THEN
		LET rm_totales.total06 = rm_totales.total06 + val06
	END IF
	IF val07 IS NOT NULL THEN
		LET rm_totales.total07 = rm_totales.total07 + val07
	END IF
	IF val08 IS NOT NULL THEN
		LET rm_totales.total08 = rm_totales.total08 + val08
	END IF
	IF val09 IS NOT NULL THEN
		LET rm_totales.total09 = rm_totales.total09 + val09
	END IF
	IF val10 IS NOT NULL THEN
		LET rm_totales.total10 = rm_totales.total10 + val10
	END IF
	IF val11 IS NOT NULL THEN
		LET rm_totales.total11 = rm_totales.total11 + val11
	END IF
	IF val12 IS NOT NULL THEN
		LET rm_totales.total12 = rm_totales.total12 + val12
	END IF

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 034, '------';
	IF rm_totales.total02 > 0 THEN
		PRINT COLUMN 041, '------';
	ELSE
		PRINT COLUMN 041, '      ';
	END IF
	IF rm_totales.total03 > 0 THEN
		PRINT COLUMN 048, '------';
	ELSE
		PRINT COLUMN 048, '      ';
	END IF
	IF rm_totales.total04 > 0 THEN
		PRINT COLUMN 055, '------';
	ELSE
		PRINT COLUMN 055, '      ';
	END IF
	IF rm_totales.total05 > 0 THEN
		PRINT COLUMN 062, '------';
	ELSE
		PRINT COLUMN 062, '      ';
	END IF
	IF rm_totales.total06 > 0 THEN
		PRINT COLUMN 069, '------';
	ELSE
		PRINT COLUMN 069, '      ';
	END IF
	IF rm_totales.total07 > 0 THEN
		PRINT COLUMN 076, '------';
	ELSE
		PRINT COLUMN 076, '      ';
	END IF
	IF rm_totales.total08 > 0 THEN
		PRINT COLUMN 083, '------';
	ELSE
		PRINT COLUMN 083, '      ';
	END IF
	IF rm_totales.total09 > 0 THEN
		PRINT COLUMN 090, '----------';
	ELSE
		PRINT COLUMN 090, '          ';
	END IF
	IF rm_totales.total10 > 0 THEN
		PRINT COLUMN 101, '----------';
	ELSE
		PRINT COLUMN 101, '          ';
	END IF
	IF rm_totales.total11 > 0 THEN
		PRINT COLUMN 112, '----------';
	ELSE
		PRINT COLUMN 112, '          ';
	END IF
	IF rm_totales.total12 > 0 THEN
		PRINT COLUMN 123, '----------'
	ELSE
		PRINT COLUMN 123, '          '
	END IF
	PRINT COLUMN 021, 'TOTALES ==>',
	      COLUMN 034, rm_totales.total01		USING "##&.##";
	IF rm_totales.total02 > 0 THEN
		PRINT COLUMN 041, rm_totales.total02	USING "###.##";
	END IF
	IF rm_totales.total03 > 0 THEN
		PRINT COLUMN 048, rm_totales.total03	USING "###.##";
	END IF
	IF rm_totales.total04 > 0 THEN
		PRINT COLUMN 055, rm_totales.total04	USING "###.##";
	END IF
	IF rm_totales.total05 > 0 THEN
		PRINT COLUMN 062, rm_totales.total05	USING "###.##";
	END IF
	IF rm_totales.total06 > 0 THEN
		PRINT COLUMN 069, rm_totales.total06	USING "###.##";
	END IF
	IF rm_totales.total07 > 0 THEN
		PRINT COLUMN 076, rm_totales.total07	USING "###.##";
	END IF
	IF rm_totales.total08 > 0 THEN
		PRINT COLUMN 083, rm_totales.total08	USING "###.##";
	END IF
	IF rm_totales.total09 > 0 THEN
		PRINT COLUMN 090, rm_totales.total09	USING "###,###.##";
	END IF
	IF rm_totales.total10 > 0 THEN
		PRINT COLUMN 101, rm_totales.total10	USING "###,###.##";
	END IF
	IF rm_totales.total11 > 0 THEN
		PRINT COLUMN 112, rm_totales.total11	USING "###,###.##";
	END IF
	IF rm_totales.total12 > 0 THEN
		PRINT COLUMN 123, rm_totales.total12	USING "###,###.##";
	END IF
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION valor_rubro(flag_ident, i)
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE i		SMALLINT
DEFINE cod_rub		LIKE rolt006.n06_cod_rubro
DEFINE r_n33		RECORD LIKE rolt033.*

DECLARE q_rub_v CURSOR FOR
	SELECT n06_cod_rubro FROM rolt006 WHERE n06_flag_ident = flag_ident
OPEN q_rub_v
FETCH q_rub_v INTO cod_rub
CLOSE q_rub_v
FREE q_rub_v
CALL fl_lee_rubro_liq_trabajador(vg_codcia, rm_par.n32_cod_liqrol,
				rm_par.n32_fecha_ini, rm_par.n32_fecha_fin,
				rm_scr[i].n33_cod_trab, cod_rub)
	RETURNING r_n33.*
IF r_n33.n33_valor = 0 AND flag_ident <> 'DT' THEN
	LET r_n33.n33_valor = NULL
END IF
RETURN r_n33.n33_valor

END FUNCTION
