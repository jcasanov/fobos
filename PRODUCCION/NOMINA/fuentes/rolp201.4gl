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
DEFINE rm_scr ARRAY[1000] OF RECORD
	n33_cod_trab		LIKE rolt033.n33_cod_trab,
	n_trab			LIKE rolt030.n30_nombres,
	n33_valor		LIKE rolt033.n33_valor
END RECORD



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp201.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
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
		'No existen configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF

-- AQUI SE DEFINEN VALORES DE VARIABLES GLOBALES
LET vm_maxelm = 1000

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
                'No existe configuración general para este módulo.',
                'stop')
        EXIT PROGRAM
END IF
INITIALIZE rm_par.* TO NULL
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
LET rm_par.n_mes           =
        fl_justifica_titulo('I',
                fl_retorna_nombre_mes(rm_par.n32_mes_proceso), 12)

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
LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ',
               vg_codcia, ' X'
RUN comando
DECLARE q_n47 CURSOR FOR
	SELECT * FROM rolt047
		WHERE n47_compania   = vg_codcia
		  AND n47_proceso    = 'VA'
		  AND n47_estado     = 'A'
		  AND n47_cod_liqrol = rm_par.n32_cod_liqrol
		  AND n47_fecha_ini  = rm_par.n32_fecha_ini
		  AND n47_fecha_fin  = rm_par.n32_fecha_fin
FOREACH q_n47 INTO r_n47.*
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


{
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
}
