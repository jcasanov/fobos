--------------------------------------------------------------------------------
-- Titulo           : rolp200.4gl - Generación novedades procesos roles  
-- Elaboracion      : 13-mar-2002
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp200 base modulo compania codigo_liq [cod_trab]
--                                   [liqrol] [fecha_ini] [fecha_fin]] 
-- Ultima Correccion: 04-dic-2003 
-- Motivo Correccion: Se permite generar liq. de rol para acta de finiquito
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
				n_mes		VARCHAR(12),
				cod_trab	LIKE rolt032.n32_cod_trab,
				n_trab		LIKE rolt030.n30_nombres
			END RECORD
DEFINE vm_flagliq	CHAR(1)
DEFINE vm_num_nov	SMALLINT
DEFINE vm_finiquito	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp200.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
-- Validar # parámetros correcto
IF num_args() <> 4  AND num_args() <> 6 AND num_args() <> 8 AND num_args() <> 9 
	THEN    
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 
                            'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vm_flagliq  = arg_val(4)
IF vm_flagliq <> 'S' AND vm_flagliq <> 'Q' AND vm_flagliq <> 'M' THEN
	CALL fgl_winmessage(vg_producto, 'Flag liquidación incorrecto, (S,Q,M).', 'stop')
	EXIT PROGRAM
END IF
LET vg_proceso  = 'rolp200'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	-- Asigna un valor por default a vg_codloc
				-- que luego puede ser reemplazado si se 
                                -- mantiene sin comentario la siguiente linea
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPTIONS
	INPUT WRAP,
	ACCEPT KEY F12
OPEN WINDOW w_201 AT 3,2 WITH 13 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST - 2) 
OPEN FORM f_201 FROM '../forms/rolf200_1'
DISPLAY FORM f_201
CALL control_generar()

END FUNCTION



FUNCTION control_generar()
DEFINE resp		VARCHAR(6)
DEFINE r_n01		RECORD LIKE rolt001.*  
DEFINE r_n05		RECORD LIKE rolt005.*  
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n47		RECORD LIKE rolt047.*
--DEFINE r_n70		RECORD LIKE rolt070.*
DEFINE mensaje		VARCHAR(250)
DEFINE num		SMALLINT
DEFINE comando		CHAR(100)

CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*

INITIALIZE rm_par.*, vm_finiquito TO NULL
IF num_args() = 6 THEN
	LET rm_par.cod_trab = arg_val(5)
	LET vm_finiquito    = arg_val(6)
END IF

IF num_args() = 8 OR num_args() = 9 THEN
	LET rm_par.cod_trab        = arg_val(5) 
	LET rm_par.n32_cod_liqrol  = arg_val(6)
	LET rm_par.n32_fecha_ini   = arg_val(7)
	LET rm_par.n32_fecha_fin   = arg_val(8)
	IF num_args() = 9 THEN
		LET vm_finiquito    = arg_val(9)
	END IF
	LET rm_par.n32_ano_proceso = r_n01.n01_ano_proceso
	LET rm_par.n32_mes_proceso = r_n01.n01_mes_proceso
	BEGIN WORK
	CALL genera_novedades()
	IF vm_num_nov > 0 AND vm_finiquito IS NULL THEN
		UPDATE rolt005 SET n05_activo     = 'S',
			           n05_fecini_act = rm_par.n32_fecha_ini,
			           n05_fecfin_act = rm_par.n32_fecha_fin
			WHERE n05_compania = vg_codcia AND 
		      	      n05_proceso  = rm_par.n32_cod_liqrol

	END IF
	COMMIT WORK
	LET comando = 'fglrun rolp203 ', vg_base, ' ', vg_modulo, ' ',
	               vg_codcia, ' X ', rm_par.cod_trab
	RUN comando
	EXIT PROGRAM
END IF	

CALL verifica_rubros_especiales()                            
IF rm_n00.n00_serial IS NULL THEN
	CALL fgl_winmessage(vg_producto,
		'No existe configuración general para este módulo.',
		'stop')
	EXIT PROGRAM
END IF
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
IF vm_flagliq = 'S' AND r_n01.n01_rol_semanal = 'N' THEN
	CALL fgl_winmessage(vg_producto,
		'Compañía no tiene configurada liquidación semanal.', 
		'stop')
	EXIT PROGRAM
END IF
IF vm_flagliq = 'Q' AND r_n01.n01_rol_quincen = 'N' THEN
	CALL fgl_winmessage(vg_producto,
		'Compañía no tiene configurada liquidación quincenal.', 
		'stop')
	EXIT PROGRAM
END IF
IF vm_flagliq = 'M' AND r_n01.n01_rol_mensual = 'N' THEN
	CALL fgl_winmessage(vg_producto,
		'Compañía no tiene configurada liquidación mensual.', 
		'stop')
	EXIT PROGRAM
END IF
LET rm_par.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_par.n32_mes_proceso = r_n01.n01_mes_proceso
LET rm_par.n_mes           = 
	fl_justifica_titulo('I', 
		fl_retorna_nombre_mes(rm_par.n32_mes_proceso), 12)
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania        = vg_codcia  AND 
	              n32_cod_liqrol[1,1] = vm_flagliq AND
		      n32_estado NOT IN ('E', 'F')
		ORDER BY n32_fecha_ini DESC
OPEN q_ultliq 
FETCH q_ultliq INTO r_n32.*
SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = vg_codcia AND n05_activo = 'S' 
IF status = NOTFOUND THEN
	IF r_n32.n32_compania IS NULL THEN
		CASE vm_flagliq
			WHEN 'S'
				LET rm_par.n32_cod_liqrol = 'S1'
			WHEN 'Q'
				LET rm_par.n32_cod_liqrol = 'Q1'
			WHEN 'M'
				LET rm_par.n32_cod_liqrol = 'ME'
		END CASE	
	ELSE
		IF r_n32.n32_estado = 'A' THEN 
			LET mensaje = 'Esta activo el proceso de roles ',
				       r_n32.n32_cod_liqrol, 
				      ' y en la rolt005 no se ha marcado.',
				      ' Arregle esta inconsistencia.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			EXIT PROGRAM
		END IF
		IF (r_n32.n32_cod_liqrol = 'ME' OR 
		    r_n32.n32_cod_liqrol = 'Q2') THEN
		   	IF (r_n32.n32_mes_proceso = r_n01.n01_mes_proceso AND
		            r_n32.n32_ano_proceso = r_n01.n01_ano_proceso) THEN
				CALL fl_mostrar_mensaje('Debe ejecutar cierre de mes.', 
                        			'stop')                         
                        	EXIT PROGRAM
			ELSE
				IF vm_flagliq = 'Q' THEN           
					LET rm_par.n32_cod_liqrol = 'Q1'
				ELSE
					LET rm_par.n32_cod_liqrol = 'ME'
				END IF
			END IF
		ELSE			
			LET num = r_n32.n32_cod_liqrol[2,2]
			LET num = num + 1	   
			LET rm_par.n32_cod_liqrol = vm_flagliq, num USING '&'
                END IF
	END IF
	CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_par.n32_cod_liqrol, 
			     rm_par.n32_ano_proceso, rm_par.n32_mes_proceso)
		RETURNING rm_par.n32_fecha_ini, rm_par.n32_fecha_fin
ELSE		
	IF (r_n05.n05_proceso[1,1] = 'S' AND vm_flagliq <> 'S') OR
	   (r_n05.n05_proceso[1,1] = 'Q' AND vm_flagliq <> 'Q') OR
	   (r_n05.n05_proceso[1,1] = 'M' AND vm_flagliq <> 'M') OR
	   (r_n05.n05_proceso[1,1] <> 'S' AND 
	    r_n05.n05_proceso[1,1] <> 'Q' AND 
	    r_n05.n05_proceso[1,1] <> 'M') THEN
	    	IF r_n05.n05_proceso <> 'AF' THEN
		   	CALL fl_mostrar_mensaje('Está activo el proceso: '
		   				|| r_n05.n05_proceso, 'stop')                         
		   	EXIT PROGRAM                                            
		END IF
	END IF
	IF r_n32.n32_compania IS NULL THEN
		LET r_n32.n32_cod_liqrol = r_n05.n05_proceso
		LET r_n32.n32_fecha_ini  = r_n05.n05_fecini_act
		LET r_n32.n32_fecha_fin  = r_n05.n05_fecfin_act
	END IF
	{--
	IF vm_finiquito IS NOT NULL AND r_n05.n05_proceso = 'AF' THEN
-- No se puede procesar dos actas de finiquito a la vez 
		INITIALIZE r_n70.* TO NULL
		SELECT * INTO r_n70.* FROM rolt070  
			WHERE n70_compania = vg_codcia
		  	  AND n70_cod_trab <> rm_par.cod_trab
			  AND n70_estado = 'A' 
		IF r_n70.n70_compania IS NOT NULL THEN
		   	CALL fl_mostrar_mensaje('Está activo el proceso: '
		   				|| r_n05.n05_proceso || ' para '
						|| 'otro trabajador.', 'stop')
		   	EXIT PROGRAM                                            
		END IF
	END IF
	--}
	IF r_n32.n32_estado <> 'A' AND vm_finiquito IS NULL THEN 
		LET mensaje = 'Esta activo el proceso de roles ',
			       r_n05.n05_proceso, 
			      ' en la rolt005 y en la rolt032',
			      ' no esta activo.',
			      ' Arregle esta inconsistencia.'
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	IF (r_n32.n32_fecha_ini <> r_n05.n05_fecini_act OR
	    r_n05.n05_fecini_act IS NULL) OR
	   (r_n32.n32_fecha_fin <> r_n05.n05_fecfin_act OR
	    r_n05.n05_fecfin_act IS NULL) THEN
		IF vm_finiquito IS NULL THEN
			LET mensaje = 'Inconsistencia en fecha de liquidacion: ',
				       r_n32.n32_cod_liqrol, 
				      ', entre rolt005 y rolt032.',
				      ' Arregle esta inconsistencia.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			EXIT PROGRAM
		END IF
	END IF
	LET rm_par.n32_cod_liqrol = r_n32.n32_cod_liqrol
	LET rm_par.n32_fecha_ini  = r_n32.n32_fecha_ini
	LET rm_par.n32_fecha_fin  = r_n32.n32_fecha_fin
END IF

IF vm_finiquito IS NOT NULL THEN
	LET rm_par.n32_ano_proceso = r_n01.n01_ano_proceso
	LET rm_par.n32_mes_proceso = r_n01.n01_mes_proceso

	LET num = r_n32.n32_cod_liqrol[2,2]
	LET num = num + 1	   
	CASE vm_flagliq
		WHEN 'S'
			IF num = 5 THEN
				LET num = 1
			END IF
			LET rm_par.n32_cod_liqrol = vm_flagliq, num USING '&'
		WHEN 'Q'
			IF num = 3 THEN
				LET num = 1
			END IF
			LET rm_par.n32_cod_liqrol = vm_flagliq, num USING '&'
	END CASE

	CALL fl_retorna_rango_fechas_proceso(vg_codcia, 
		rm_par.n32_cod_liqrol, rm_par.n32_ano_proceso, 
		rm_par.n32_mes_proceso)
		RETURNING rm_par.n32_fecha_ini, rm_par.n32_fecha_fin

	{--
	SELECT * INTO r_n70.* FROM rolt070
		WHERE n70_compania = vg_codcia
		  AND n70_cod_trab = rm_par.cod_trab
		  AND n70_estado   = 'A'

	IF rm_par.n32_fecha_fin < r_n70.n70_fec_sal THEN
		EXIT PROGRAM
	END IF
	--}
		
	BEGIN WORK
	CALL genera_novedades()
	COMMIT WORK
	EXIT PROGRAM
END IF

CALL fl_lee_proceso_roles(rm_par.n32_cod_liqrol) RETURNING r_n03.*
LET rm_par.n_liqrol = r_n03.n03_nombre

CALL lee_parametros()
IF int_flag THEN 
	RETURN
END IF
BEGIN WORK
CALL genera_novedades()
IF vm_num_nov > 0 THEN
	UPDATE rolt005 SET n05_activo     = 'S',
		           n05_fecini_act = rm_par.n32_fecha_ini,
		           n05_fecfin_act = rm_par.n32_fecha_fin
		WHERE n05_compania = vg_codcia AND 
	      	      n05_proceso  = rm_par.n32_cod_liqrol
END IF
COMMIT WORK
LET mensaje = 'Novedades de roles generadas: ', vm_num_nov USING '##&'
CALL fl_mostrar_mensaje(mensaje, 'info')
IF vm_num_nov > 0 THEN
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
END IF

END FUNCTION




FUNCTION lee_parametros()              
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE resp		CHAR(10)
                
LET int_flag = 0
DISPLAY BY NAME rm_par.*
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		RETURN
	ON KEY(F2)
		{
		IF INFIELD(n32_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles() 
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_par.n32_cod_liqrol = r_n03.n03_proceso
				LET rm_par.n_liqrol       = r_n03.n03_nombre
				DISPLAY BY NAME rm_par.n32_cod_liqrol,
						rm_par.n_liqrol
			END IF
		END IF
		}
		IF INFIELD(cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia) 
				RETURNING r_n30.n30_cod_trab,
					  r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_par.cod_trab = r_n30.n30_cod_trab
				LET rm_par.n_trab   = r_n30.n30_nombres
				DISPLAY BY NAME rm_par.cod_trab, rm_par.n_trab  
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD cod_trab
		IF rm_par.cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia, rm_par.cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Codigo de trabajador no existe.', 'exclamation')
				NEXT FIELD cod_trab
			END IF
			LET rm_par.n_trab = r_n30.n30_nombres
			DISPLAY BY NAME rm_par.n_trab
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				--NEXT FIELD cod_trab
			END IF
			IF r_n30.n30_estado = 'J' THEN
				CALL fl_mostrar_mensaje('El trabajador es JUBILADO y no se le puede generar novedades por este proceso.', 'exclamation')
				NEXT FIELD cod_trab
			END IF
			INITIALIZE r_n32.* TO NULL
			DECLARE q_n32_act CURSOR FOR
				SELECT * FROM rolt032
					WHERE n32_compania   = vg_codcia
					  AND n32_cod_liqrol =
							rm_par.n32_cod_liqrol
					  AND n32_fecha_ini  =
							rm_par.n32_fecha_ini
					  AND n32_fecha_fin  =
							rm_par.n32_fecha_fin
					ORDER BY n32_fecha_fin DESC
			OPEN q_n32_act
			FETCH q_n32_act INTO r_n32.*
			CLOSE q_n32_act
			FREE q_n32_act
			IF r_n32.n32_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se han GENERADO NOVEDADES para esta QUINCENA, por lo tanto no puede generar novedades a este trabajador.', 'exclamation')
				NEXT FIELD cod_trab
			END IF
		ELSE
			CLEAR n_trab
			LET rm_par.n_trab = NULL
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
IF resp <> 'Yes' THEN
	LET int_flag = 1
END IF

END FUNCTION



FUNCTION genera_novedades()
DEFINE query		CHAR(3000)
DEFINE expr_trab	VARCHAR(100)
DEFINE orden		LIKE rolt032.n32_orden
DEFINE fecha_ini	LIKE rolt032.n32_fecha_ini
DEFINE fecha_fin	LIKE rolt032.n32_fecha_fin
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n10		RECORD LIKE rolt010.*
DEFINE r_n11		RECORD LIKE rolt011.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n33		RECORD LIKE rolt033.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE r_n46		RECORD LIKE rolt046.*
DEFINE r_n60		RECORD LIKE rolt060.*
DEFINE r_n61		RECORD LIKE rolt061.*
DEFINE r_n62		RECORD LIKE rolt062.*
DEFINE r_n63		RECORD LIKE rolt063.*
DEFINE r_n64		RECORD LIKE rolt064.*
DEFINE r_n65		RECORD LIKE rolt065.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE i, j		SMALLINT
DEFINE valor		DECIMAL(12,2)

LET i = 0
INITIALIZE r_n11.* TO NULL
DECLARE q_fr CURSOR FOR
	SELECT * FROM rolt011
		WHERE n11_compania   = vg_codcia
		  AND n11_cod_liqrol = rm_par.n32_cod_liqrol
		  AND n11_cod_rubro  = (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = "FM")
OPEN q_fr
FETCH q_fr INTO r_n11.*
CLOSE q_fr
FREE q_fr
IF r_n11.n11_compania IS NOT NULL THEN
	IF rm_par.cod_trab IS NOT NULL THEN
		CALL fl_lee_trabajador_roles(vg_codcia, rm_par.cod_trab)
			RETURNING r_n30.*
	END IF
	LET fecha_fin = MDY(MONTH(rm_par.n32_fecha_ini), 01,
				YEAR(rm_par.n32_fecha_ini)) - 1 UNITS DAY
	LET fecha_ini = MDY(MONTH(fecha_fin), 01, YEAR(fecha_fin))
	LET query = 'DELETE FROM rolt038 ',
			'WHERE n38_compania  = ', vg_codcia,
			'  AND n38_fecha_ini = "', fecha_ini, '"',
			'  AND n38_fecha_fin = "', fecha_fin, '"',
			'  AND n38_pago_iess = "N" '
	IF rm_par.cod_trab IS NOT NULL THEN
		LET query = query CLIPPED,
				'  AND n38_cod_trab  = ', rm_par.cod_trab
	END IF
	PREPARE del_fr FROM query
	WHENEVER ERROR CONTINUE
	EXECUTE del_fr 
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo borrar fondo de reserva (rolt038). Intente mas tarde.', 'stop')
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
END IF
LET query = 'DELETE FROM rolt033 ',
		'WHERE n33_compania       = ',  vg_codcia,
		    ' AND n33_cod_liqrol  = "', rm_par.n32_cod_liqrol, '"',
		    ' AND n33_fecha_ini   = "', rm_par.n32_fecha_ini, '"',
		    ' AND n33_fecha_fin   = "', rm_par.n32_fecha_fin, '"'
IF rm_par.cod_trab IS NOT NULL THEN
	LET query = query CLIPPED, ' AND n33_cod_trab = ', rm_par.cod_trab
END IF
PREPARE del_dl FROM query
WHENEVER ERROR CONTINUE
EXECUTE del_dl 
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar detalle de '
				|| 'liquidacion (rolt033). '
				|| 'Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
LET query = 'DELETE FROM rolt032 ',
		'WHERE n32_compania   =',  vg_codcia,
		 ' AND n32_cod_liqrol ="', rm_par.n32_cod_liqrol, '" ',
		 ' AND n32_fecha_ini  ="',  rm_par.n32_fecha_ini, '"',
		 ' AND n32_fecha_fin  ="',  rm_par.n32_fecha_fin, '"'
IF rm_par.cod_trab IS NOT NULL THEN
	LET query = query CLIPPED, ' AND n32_cod_trab = ', rm_par.cod_trab
END IF
PREPARE del_cl FROM query
WHENEVER ERROR CONTINUE
EXECUTE del_cl 
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo borrar cabecera de '
				|| 'liquidacion (rolt032). '
				|| 'Intente mas tarde.', 'stop')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_n32.* TO NULL
DECLARE q_rub CURSOR FOR 
	SELECT * FROM rolt006 
		WHERE n06_estado  = 'A'
		  --AND n06_calculo = 'N'
		  AND n06_cod_rubro IN 
			(SELECT n11_cod_rubro FROM rolt011
			   	WHERE n11_compania   = vg_codcia
				  AND n11_cod_liqrol = rm_par.n32_cod_liqrol)
LET expr_trab = NULL
IF rm_par.cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n30_cod_trab    = ', rm_par.cod_trab
END IF
LET query = 'SELECT * FROM rolt030 ',
		' WHERE n30_compania    = ', vg_codcia,
		expr_trab CLIPPED,
		'   AND n30_estado      = "A" ',
		' UNION ',
		' SELECT * FROM rolt030 ',
			' WHERE n30_compania    = ', vg_codcia,
			expr_trab CLIPPED,
			'   AND n30_estado      = "I" ',
			'   AND n30_fecha_sal  >= "', rm_par.n32_fecha_ini, '"'
IF vg_codcia = 1 THEN
	LET query = query CLIPPED,
			' ORDER BY n30_compania, n30_cod_trab '	
END IF
PREPARE stmnt1 FROM query
DECLARE qu_trab CURSOR FOR stmnt1
CALL fl_lee_proceso_roles(rm_par.n32_cod_liqrol) RETURNING r_n03.*
LET orden = 0 
LET i = 0 
FOREACH qu_trab INTO r_n30.* 
	LET orden = orden + 1
	INITIALIZE r_n32.* TO NULL
	LET r_n32.n32_compania    = vg_codcia
	LET r_n32.n32_cod_liqrol  = rm_par.n32_cod_liqrol
	LET r_n32.n32_fecha_ini   = rm_par.n32_fecha_ini
	LET r_n32.n32_fecha_fin   = rm_par.n32_fecha_fin
	LET r_n32.n32_cod_trab    = r_n30.n30_cod_trab
	LET r_n32.n32_estado      = 'A'
	IF vm_finiquito IS NOT NULL THEN
		LET r_n32.n32_estado      = 'F'
	END IF
	LET r_n32.n32_cod_depto   = r_n30.n30_cod_depto
	LET r_n32.n32_sueldo      = r_n30.n30_sueldo_mes
	LET r_n32.n32_ano_proceso = rm_par.n32_ano_proceso
	LET r_n32.n32_mes_proceso = rm_par.n32_mes_proceso
	LET r_n32.n32_orden       = orden

-- OjO
	CASE 
		WHEN r_n03.n03_frecuencia = 'S' 
			LET r_n32.n32_dias_trab = rm_n00.n00_dias_semana
		WHEN r_n03.n03_frecuencia = 'Q' 
			LET r_n32.n32_dias_trab = rm_n00.n00_dias_mes / 2
		WHEN r_n03.n03_frecuencia = 'M' 
			LET r_n32.n32_dias_trab = rm_n00.n00_dias_mes
	END CASE
	IF r_n30.n30_fecha_ing > r_n32.n32_fecha_fin THEN
		CONTINUE FOREACH
	END IF
	IF r_n30.n30_fecha_reing > r_n32.n32_fecha_fin THEN
		CONTINUE FOREACH
	END IF
	LET i = i + 1
	LET fecha_ini = r_n32.n32_fecha_ini
	-- Si el empleado entro a trabajar luego de empezado el periodo
	IF fecha_ini < r_n30.n30_fecha_ing THEN
		LET fecha_ini           = r_n30.n30_fecha_ing
		LET r_n32.n32_dias_trab = r_n32.n32_fecha_fin - fecha_ini + 1
	END IF
	-- Si el empleado reingreso luego de empezado el periodo
	IF r_n30.n30_fecha_reing IS NOT NULL THEN
		IF fecha_ini < r_n30.n30_fecha_reing THEN
			LET fecha_ini = r_n30.n30_fecha_reing
			LET r_n32.n32_dias_trab = r_n32.n32_fecha_fin - fecha_ini + 1
		END IF
	END IF
-- OjO
	LET r_n32.n32_dias_falt   = 0
	LET r_n32.n32_moneda      = r_n30.n30_mon_sueldo 
	LET r_n32.n32_paridad     = 1
	IF r_n32.n32_moneda <> rg_gen.g00_moneda_base THEN
		CALL fl_lee_factor_moneda(r_n32.n32_moneda, rg_gen.g00_moneda_base)
				RETURNING r_g14.*
		IF r_g14.g14_serial IS NULL THEN
			CALL fl_mostrar_mensaje('No hay paridad cambiaria para la moneda: ' || r_n32.n32_moneda,'exclamation')
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		LET r_n32.n32_paridad = r_g14.g14_tasa
	END IF
	LET r_n32.n32_tipo_pago   = r_n30.n30_tipo_pago
	LET r_n32.n32_bco_empresa = r_n30.n30_bco_empresa
	LET r_n32.n32_cta_empresa = r_n30.n30_cta_empresa
	LET r_n32.n32_cta_trabaj  = r_n30.n30_cta_trabaj
	LET r_n32.n32_tot_gan     = 0
	LET r_n32.n32_tot_ing     = 0
	LET r_n32.n32_tot_egr     = 0
	LET r_n32.n32_tot_neto    = 0
	LET r_n32.n32_usuario     = vg_usuario
	LET r_n32.n32_fecing      = CURRENT
	INSERT INTO rolt032 VALUES (r_n32.*)
	LET j = 0
	FOREACH q_rub INTO r_n06.*
		LET j = j + 1
		INITIALIZE r_n33.* TO NULL
		LET r_n33.n33_compania   = r_n32.n32_compania
		LET r_n33.n33_cod_liqrol = r_n32.n32_cod_liqrol
		LET r_n33.n33_fecha_ini  = r_n32.n32_fecha_ini
		LET r_n33.n33_fecha_fin  = r_n32.n32_fecha_fin
		LET r_n33.n33_cod_trab   = r_n32.n32_cod_trab
		LET r_n33.n33_cod_rubro  = r_n06.n06_cod_rubro
		LET r_n33.n33_orden      = r_n06.n06_orden
		LET r_n33.n33_det_tot    = r_n06.n06_det_tot
		LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0
		LET r_n33.n33_cant_valor = r_n06.n06_cant_valor
		LET r_n33.n33_valor      = r_n06.n06_valor_fijo
		CALL fl_retorna_valor_rubro_trabajador(r_n33.n33_compania,
				r_n33.n33_cod_liqrol, r_n33.n33_cod_rubro,
				r_n33.n33_cod_trab)
			RETURNING r_n10.*
		IF r_n10.n10_compania IS NOT NULL THEN
			IF r_n10.n10_fecha_ini IS NULL THEN
				LET r_n33.n33_valor = r_n10.n10_valor
			ELSE
				IF r_n32.n32_fecha_fin >= r_n10.n10_fecha_ini
				AND r_n32.n32_fecha_fin <= r_n10.n10_fecha_fin
				THEN
					LET r_n33.n33_valor = r_n10.n10_valor
				END IF
			END IF
		END IF
		{--
		IF r_n10.n10_valor IS NOT NULL THEN
			IF r_n10.n10_cod_liqrol IS NULL THEN
				LET r_n33.n33_valor = r_n10.n10_valor
			ELSE
				IF r_n10.n10_cod_liqrol = r_n33.n33_cod_liqrol 
				THEN
					LET r_n33.n33_valor = r_n10.n10_valor
				END IF 
			END IF
		END IF
		--}
		IF r_n06.n06_flag_ident = 'HN' THEN
			LET r_n33.n33_valor = r_n32.n32_dias_trab *
					      rm_n00.n00_horas_dia
		END IF
		IF r_n06.n06_flag_ident = 'DT' THEN
			LET r_n33.n33_valor = r_n32.n32_dias_trab 
		END IF
		INSERT INTO rolt033 VALUES (r_n33.*)
	END FOREACH
	IF j = 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se genero detalle de novedades. Chequear configuraciones rubros.','exclamation')
		EXIT PROGRAM
	END IF
	CALL retorna_sobregiro_pendiente(r_n32.*) 
		RETURNING valor, r_n06.*
	IF valor > 0 THEN
		CALL fl_lee_rubro_liq_trabajador(vg_codcia,               
				rm_par.n32_cod_liqrol,	                  
			 	rm_par.n32_fecha_ini,                     
			 	rm_par.n32_fecha_fin,                     
			 	r_n30.n30_cod_trab,                       
			 	r_n06.n06_cod_rubro)                      	
			RETURNING r_n33.*                                 
		IF r_n33.n33_compania IS NULL THEN                        
			CALL inserta_rubro_trabajador(r_n06.*, r_n32.*)   
		END IF                                                    
		CALL actualiza_detalle_liquidacion(valor,
				r_n32.n32_compania,  r_n32.n32_cod_liqrol,
				r_n32.n32_fecha_ini, r_n32.n32_fecha_fin, 
				r_n32.n32_cod_trab,  r_n06.n06_cod_rubro) 
	END IF		
END FOREACH
LET vm_num_nov = i
LET query = 'SELECT n45_num_prest, n45_cod_rubro, n45_cod_trab, n46_saldo ',
		' FROM rolt030, rolt045, rolt046 ',
		' WHERE n30_compania    = ', vg_codcia,
		expr_trab CLIPPED,
		'   AND n30_estado      = "A" ',
		'   AND n45_compania    = n30_compania ',
		'   AND n45_cod_trab    = n30_cod_trab ',
		'   AND n45_estado     IN ("A", "R") ',
		'   AND n46_compania    = n45_compania ',
		'   AND n46_num_prest   = n45_num_prest ',
		'   AND n46_cod_liqrol  = "', rm_par.n32_cod_liqrol, '"',
		'   AND n46_fecha_ini   = "', rm_par.n32_fecha_ini, '"',
		'   AND n46_fecha_fin   = "', rm_par.n32_fecha_fin, '"',
		'   AND n46_saldo       > 0 ',
		' UNION ',
		' SELECT n45_num_prest, n45_cod_rubro, n45_cod_trab, n46_saldo',
			' FROM rolt030, rolt045, rolt046 ',
			' WHERE n30_compania    = ', vg_codcia,
			expr_trab CLIPPED,
			'   AND n30_estado      = "I" ',
			'   AND n30_fecha_sal  >= "', rm_par.n32_fecha_ini, '"',
			'   AND n45_compania    = n30_compania ',
			'   AND n45_cod_trab    = n30_cod_trab ',
			'   AND n45_estado     IN ("A", "R") ',
			'   AND n46_compania    = n45_compania ',
			'   AND n46_num_prest   = n45_num_prest ',
			'   AND n46_cod_liqrol  = "', rm_par.n32_cod_liqrol,'"',
			'   AND n46_fecha_ini   = "', rm_par.n32_fecha_ini, '"',
			'   AND n46_fecha_fin   = "', rm_par.n32_fecha_fin, '"',
			'   AND n46_saldo       > 0 '
PREPARE cons_prest FROM query
DECLARE q_prest CURSOR FOR cons_prest
FOREACH q_prest INTO r_n45.n45_num_prest, r_n45.n45_cod_rubro, 
		     r_n45.n45_cod_trab, r_n46.n46_saldo 
	IF rm_par.cod_trab IS NOT NULL THEN
		IF r_n45.n45_cod_trab <> rm_par.cod_trab THEN
			CONTINUE FOREACH
		END IF
	END IF	
	CALL fl_lee_rubro_liq_trabajador(vg_codcia, 
					 rm_par.n32_cod_liqrol,
	                		 rm_par.n32_fecha_ini,	
	                		 rm_par.n32_fecha_fin,	
	                		 r_n45.n45_cod_trab,	
	                		 r_n45.n45_cod_rubro)
		RETURNING r_n33.*
	IF r_n33.n33_compania IS NULL THEN	
		CALL fl_lee_rubro_roles(r_n45.n45_cod_rubro)
			RETURNING r_n06.*
                LET r_n33.n33_compania   = vg_codcia
                LET r_n33.n33_cod_liqrol = rm_par.n32_cod_liqrol
                LET r_n33.n33_fecha_ini  = rm_par.n32_fecha_ini 
                LET r_n33.n33_fecha_fin  = rm_par.n32_fecha_fin 
                LET r_n33.n33_cod_trab   = r_n45.n45_cod_trab  
	        LET r_n33.n33_cod_rubro  = r_n45.n45_cod_rubro 
	        LET r_n33.n33_orden      = r_n06.n06_orden     
	        LET r_n33.n33_det_tot    = r_n06.n06_det_tot   
	        LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0 
                LET r_n33.n33_cant_valor = r_n06.n06_cant_valor
                LET r_n33.n33_num_prest  = r_n45.n45_num_prest
                LET r_n33.n33_valor      = r_n46.n46_saldo
                INSERT INTO rolt033 VALUES (r_n33.*)
     	END IF
     	UPDATE rolt033 SET n33_valor     = r_n46.n46_saldo,
     			   n33_num_prest = r_n45.n45_num_prest
     		WHERE n33_compania   = vg_codcia AND              
                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND  
                      n33_fecha_ini  = rm_par.n32_fecha_ini AND   
                      n33_fecha_fin  = rm_par.n32_fecha_fin AND  
                      n33_cod_trab   = r_n45.n45_cod_trab AND 
                      n33_cod_rubro  = r_n45.n45_cod_rubro    
END FOREACH
FREE q_prest

CALL fl_lee_parametros_club_roles(vg_codcia) RETURNING r_n60.*
IF r_n60.n60_compania IS NULL THEN
	RETURN	
END IF

IF rm_par.n32_cod_liqrol[1] = r_n60.n60_frec_aporte THEN
	LET query = 'SELECT n61_cod_trab, n61_cuota ',
			' FROM rolt030, rolt061 ',
			' WHERE n30_compania     = ', vg_codcia,
			expr_trab CLIPPED,
			'   AND n30_estado       = "A" ',
			'   AND n30_cod_trab     NOT IN (8, 271, 190) ',
			'   AND n61_compania     = n30_compania ',
			'   AND n61_cod_trab     = n30_cod_trab ',
			'   AND n61_fec_sal_club IS NULL ',
			' UNION ',
			' SELECT n61_cod_trab, n61_cuota ',
				' FROM rolt030, rolt061 ',
				' WHERE n30_compania     = ', vg_codcia,
				expr_trab CLIPPED,
				'   AND n30_estado       = "I" ',
				'   AND n30_cod_trab     NOT IN (8, 271, 190) ',
				'   AND n30_fecha_sal    >= "',
						rm_par.n32_fecha_ini, '"',
				'   AND n61_compania     = n30_compania ',
				'   AND n61_cod_trab     = n30_cod_trab ',
				'   AND n61_fec_sal_club IS NULL '
	PREPARE cons_afi_clu FROM query
	DECLARE q_afi_club CURSOR FOR cons_afi_clu
	FOREACH q_afi_club INTO r_n61.n61_cod_trab, r_n61.n61_cuota 
		IF rm_par.cod_trab IS NOT NULL THEN
			IF r_n61.n61_cod_trab <> rm_par.cod_trab THEN
				CONTINUE FOREACH
			END IF
		END IF	
		CALL fl_lee_rubro_liq_trabajador(vg_codcia, 
						 rm_par.n32_cod_liqrol,
		                		 rm_par.n32_fecha_ini,	
		                		 rm_par.n32_fecha_fin,	
		                		 r_n61.n61_cod_trab,	
		                		 r_n60.n60_rub_aporte)
			RETURNING r_n33.*
		IF r_n33.n33_compania IS NULL THEN	
			CALL fl_lee_rubro_roles(r_n60.n60_rub_aporte)
				RETURNING r_n06.*
	                LET r_n33.n33_compania   = vg_codcia
	                LET r_n33.n33_cod_liqrol = rm_par.n32_cod_liqrol
	                LET r_n33.n33_fecha_ini  = rm_par.n32_fecha_ini 
	                LET r_n33.n33_fecha_fin  = rm_par.n32_fecha_fin 
	                LET r_n33.n33_cod_trab   = r_n61.n61_cod_trab  
		        LET r_n33.n33_cod_rubro  = r_n60.n60_rub_aporte 
		        LET r_n33.n33_orden      = r_n06.n06_orden     
		        LET r_n33.n33_det_tot    = r_n06.n06_det_tot   
		        LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0 
	                LET r_n33.n33_cant_valor = r_n06.n06_cant_valor
	                LET r_n33.n33_valor      = r_n61.n61_cuota
	                INSERT INTO rolt033 VALUES (r_n33.*)
	     	END IF
	     	UPDATE rolt033 SET n33_valor = r_n61.n61_cuota
	     		WHERE n33_compania   = vg_codcia AND              
	                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND  
	                      n33_fecha_ini  = rm_par.n32_fecha_ini AND   
	                      n33_fecha_fin  = rm_par.n32_fecha_fin AND  
	                      n33_cod_trab   = r_n61.n61_cod_trab AND 
	                      n33_cod_rubro  = r_n60.n60_rub_aporte    
	END FOREACH
	FREE q_afi_club
END IF

LET query = 'SELECT n64_num_prest, n64_cod_rubro, n64_cod_trab, n65_saldo ',
		' FROM rolt030, rolt064, rolt065 ',
		' WHERE n30_compania     = ', vg_codcia,
		expr_trab CLIPPED,
		'   AND n30_estado       = "A" ',
		'   AND n64_compania     = n30_compania ',
		'   AND n64_cod_trab     = n30_cod_trab ',
		'   AND n64_estado      <> "E" ',
		'   AND n64_val_prest + n64_val_interes - n64_descontado > 0 ',
		'   AND n64_compania     = n65_compania ',
		'   AND n64_num_prest    = n65_num_prest ',
		'   AND n65_cod_liqrol   = "', rm_par.n32_cod_liqrol, '" ',
		'   AND n65_fecha_ini    = "', rm_par.n32_fecha_ini, '" ',
		'   AND n65_fecha_fin    = "', rm_par.n32_fecha_fin, '" ',
		'   AND n65_saldo        > 0 ',
		' UNION ',
		' SELECT n64_num_prest, n64_cod_rubro, n64_cod_trab, n65_saldo',
			' FROM rolt030, rolt064, rolt065 ',
			' WHERE n30_compania     = ', vg_codcia,
			expr_trab CLIPPED,
			'   AND n30_estado       = "I" ',
			'   AND n30_fecha_sal   >= "', rm_par.n32_fecha_ini,'"',
			'   AND n64_compania     = n30_compania ',
			'   AND n64_cod_trab     = n30_cod_trab ',
			'   AND n64_estado      <> "E" ',
			'   AND n64_val_prest + n64_val_interes - ',
					'n64_descontado > 0 ',
			'   AND n64_compania     = n65_compania ',
			'   AND n64_num_prest    = n65_num_prest ',
			'   AND n65_cod_liqrol   = "',rm_par.n32_cod_liqrol,'"',
			'   AND n65_fecha_ini    = "', rm_par.n32_fecha_ini,'"',
			'   AND n65_fecha_fin    = "', rm_par.n32_fecha_fin,'"',
			'   AND n65_saldo        > 0 '
PREPARE cons_pre_clu FROM query
DECLARE q_prest_club CURSOR FOR cons_pre_clu
FOREACH q_prest_club INTO r_n64.n64_num_prest, r_n64.n64_cod_rubro, 
		     r_n64.n64_cod_trab, r_n65.n65_saldo 
	IF rm_par.cod_trab IS NOT NULL THEN
		IF r_n64.n64_cod_trab <> rm_par.cod_trab THEN
			CONTINUE FOREACH
		END IF
	END IF	
	CALL fl_lee_rubro_liq_trabajador(vg_codcia, 
					 rm_par.n32_cod_liqrol,
	                		 rm_par.n32_fecha_ini,	
	                		 rm_par.n32_fecha_fin,	
	                		 r_n64.n64_cod_trab,	
	                		 r_n64.n64_cod_rubro)
		RETURNING r_n33.*
	IF r_n33.n33_compania IS NULL THEN	
		CALL fl_lee_rubro_roles(r_n64.n64_cod_rubro)
			RETURNING r_n06.*
                LET r_n33.n33_compania   = vg_codcia
                LET r_n33.n33_cod_liqrol = rm_par.n32_cod_liqrol
                LET r_n33.n33_fecha_ini  = rm_par.n32_fecha_ini 
                LET r_n33.n33_fecha_fin  = rm_par.n32_fecha_fin 
                LET r_n33.n33_cod_trab   = r_n64.n64_cod_trab  
	        LET r_n33.n33_cod_rubro  = r_n64.n64_cod_rubro 
	        LET r_n33.n33_orden      = r_n06.n06_orden     
	        LET r_n33.n33_det_tot    = r_n06.n06_det_tot   
	        LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0 
                LET r_n33.n33_cant_valor = r_n06.n06_cant_valor
                LET r_n33.n33_prest_club = r_n64.n64_num_prest
                LET r_n33.n33_valor      = r_n65.n65_saldo
                INSERT INTO rolt033 VALUES (r_n33.*)
     	END IF
     	UPDATE rolt033 SET n33_valor      = r_n65.n65_saldo,
     			   n33_prest_club = r_n64.n64_num_prest
     		WHERE n33_compania   = vg_codcia AND              
                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND  
                      n33_fecha_ini  = rm_par.n32_fecha_ini AND   
                      n33_fecha_fin  = rm_par.n32_fecha_fin AND  
                      n33_cod_trab   = r_n64.n64_cod_trab AND 
                      n33_cod_rubro  = r_n64.n64_cod_rubro    
END FOREACH
FREE q_prest_club

LET query = 'SELECT rolt062.*, rolt063.* ',
		' FROM rolt030, rolt063, rolt062 ',
		' WHERE n30_compania     = ', vg_codcia,
		expr_trab CLIPPED,
		'   AND n30_estado       = "A" ',
		'   AND n63_compania     = n30_compania ',
		'   AND n63_cod_trab     = n30_cod_trab ',
		'   AND n63_cod_liqrol   = "', rm_par.n32_cod_liqrol, '" ',
		'   AND n63_fecha_ini    = "', rm_par.n32_fecha_ini, '" ',
		'   AND n63_fecha_fin    = "', rm_par.n32_fecha_fin, '" ',
		'   AND n63_estado       = "A" ',
		'   AND n62_compania     = n63_compania ',
		'   AND n62_cod_almacen  = n63_cod_almacen ',
		' UNION ',
		' SELECT rolt062.*, rolt063.* ',
			' FROM rolt030, rolt063, rolt062 ',
			' WHERE n30_compania     = ', vg_codcia,
			expr_trab CLIPPED,
			'   AND n30_estado       = "I" ',
			'   AND n30_fecha_sal   >= "', rm_par.n32_fecha_ini,'"',
			'   AND n63_compania     = n30_compania ',
			'   AND n63_cod_trab     = n30_cod_trab ',
			'   AND n63_cod_liqrol   = "',rm_par.n32_cod_liqrol,'"',
			'   AND n63_fecha_ini    = "', rm_par.n32_fecha_ini,'"',
			'   AND n63_fecha_fin    = "', rm_par.n32_fecha_fin,'"',
			'   AND n63_estado       = "A" ',
			'   AND n62_compania     = n63_compania ',
			'   AND n62_cod_almacen  = n63_cod_almacen '
PREPARE cons_casa FROM query
DECLARE q_casacom CURSOR FOR cons_casa
FOREACH q_casacom INTO r_n62.*, r_n63.* 
	IF rm_par.cod_trab IS NOT NULL THEN
		IF r_n63.n63_cod_trab <> rm_par.cod_trab THEN
			CONTINUE FOREACH
		END IF
	END IF	
	CALL fl_lee_rubro_liq_trabajador(vg_codcia, 
					 rm_par.n32_cod_liqrol,
	                		 rm_par.n32_fecha_ini,	
	                		 rm_par.n32_fecha_fin,	
	                		 r_n63.n63_cod_trab,	
	                		 r_n62.n62_cod_rubro)
		RETURNING r_n33.*
	IF r_n33.n33_compania IS NULL THEN	
		CALL fl_lee_rubro_roles(r_n62.n62_cod_rubro)
			RETURNING r_n06.*
                LET r_n33.n33_compania   = vg_codcia
                LET r_n33.n33_cod_liqrol = rm_par.n32_cod_liqrol
                LET r_n33.n33_fecha_ini  = rm_par.n32_fecha_ini 
                LET r_n33.n33_fecha_fin  = rm_par.n32_fecha_fin 
                LET r_n33.n33_cod_trab   = r_n63.n63_cod_trab  
	        LET r_n33.n33_cod_rubro  = r_n62.n62_cod_rubro 
	        LET r_n33.n33_orden      = r_n06.n06_orden     
	        LET r_n33.n33_det_tot    = r_n06.n06_det_tot   
	        LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0 
                LET r_n33.n33_cant_valor = r_n06.n06_cant_valor
                LET r_n33.n33_valor      = r_n63.n63_valor
                INSERT INTO rolt033 VALUES (r_n33.*)
     	END IF
     	UPDATE rolt033 SET n33_valor      = r_n63.n63_valor
     		WHERE n33_compania   = vg_codcia AND              
                      n33_cod_liqrol = rm_par.n32_cod_liqrol AND  
                      n33_fecha_ini  = rm_par.n32_fecha_ini AND   
                      n33_fecha_fin  = rm_par.n32_fecha_fin AND  
                      n33_cod_trab   = r_n63.n63_cod_trab AND 
                      n33_cod_rubro  = r_n62.n62_cod_rubro    
END FOREACH
FREE q_casacom

END FUNCTION



FUNCTION fl_lee_proceso_rol_compania(codcia, cod_liqrol)
DEFINE codcia		LIKE rolt032.n32_compania  
DEFINE cod_liqrol	LIKE rolt032.n32_cod_liqrol
DEFINE r_n05		RECORD LIKE rolt005.*      

SELECT * INTO r_n05.* FROM rolt005
	WHERE n05_compania = codcia AND
	      n05_proceso  = cod_liqrol
RETURN r_n05.*                    

END FUNCTION



FUNCTION retorna_sobregiro_pendiente(r_n32) 
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE valor		DECIMAL(12,2)
DEFINE fecha		DATE

SELECT * INTO r_n06.* FROM rolt006                                            
	WHERE n06_flag_ident = 'SI'                              
DECLARE q_sobre CURSOR FOR
	SELECT n33_valor, n33_fecha_ini FROM rolt033
		WHERE n33_compania   = r_n32.n32_compania AND 
		      n33_fecha_ini  < r_n32.n32_fecha_ini AND  
		      n33_fecha_fin  < r_n32.n32_fecha_fin AND   
		      n33_cod_trab   = r_n32.n32_cod_trab AND  	
		      n33_cod_rubro  = r_n06.n06_cod_rubro 
		ORDER BY 2 DESC
LET valor = 0
OPEN q_sobre
FETCH q_sobre INTO valor, fecha
SELECT * INTO r_n06.* FROM rolt006                                            
	WHERE n06_flag_ident = 'SE'
RETURN valor, r_n06.*

END FUNCTION



FUNCTION verifica_rubros_especiales()                            
                                                                 
{
SELECT * FROM rolt006                                            
	WHERE n06_det_tot = 'TI'                                 
IF status = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No está configurado el rubro'   
			|| ' de TOTAL INGRESOS.', 'stop')        
	EXIT PROGRAM                                             
END IF                                                           
SELECT * FROM rolt006                                            
	WHERE n06_det_tot = 'TE'                                 
IF status = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No está configurado el rubro'   
			|| ' de TOTAL DESCUENTOS.', 'stop')      
	EXIT PROGRAM                                             
END IF                                                           
SELECT * FROM rolt006                                            
	WHERE n06_det_tot = 'TN'                                 
IF status = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No está configurado el rubro '  
			|| ' de TOTAL NETO.', 'stop')            
	EXIT PROGRAM                                             
END IF                                                           
}
SELECT * FROM rolt006                                            
	WHERE n06_flag_ident = 'SI'                              
IF status = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No está configurado el rubro '  
			|| ' de INGRESO POR SOBREGIRO.', 'stop') 
END IF                                                           
SELECT * FROM rolt006                                            
	WHERE n06_flag_ident = 'SE'                              
IF status = NOTFOUND THEN                                        
	CALL fl_mostrar_mensaje('No está configurado el rubro '  
			|| ' de DESCUENTO POR SOBREGIRO.', 'stop') 
END IF                                                           
                                                                 
END FUNCTION    



FUNCTION inserta_rubro_trabajador(r_n06, r_n32)                                                          
DEFINE r_n06		RECORD LIKE rolt006.*           
DEFINE r_n32		RECORD LIKE rolt032.*           
DEFINE r_n33		RECORD LIKE rolt033.*           
                                                        
INITIALIZE r_n33.* TO NULL                              
LET r_n33.n33_compania   = r_n32.n32_compania           
LET r_n33.n33_cod_liqrol = r_n32.n32_cod_liqrol         
LET r_n33.n33_fecha_ini  = r_n32.n32_fecha_ini          
LET r_n33.n33_fecha_fin  = r_n32.n32_fecha_fin          
LET r_n33.n33_cod_trab   = r_n32.n32_cod_trab           
LET r_n33.n33_cod_rubro  = r_n06.n06_cod_rubro          
LET r_n33.n33_orden      = r_n06.n06_orden              
LET r_n33.n33_det_tot    = r_n06.n06_det_tot            
LET r_n33.n33_imprime_0  = r_n06.n06_imprime_0          
LET r_n33.n33_cant_valor = r_n06.n06_cant_valor         
LET r_n33.n33_valor      = 0                            
INSERT INTO rolt033 VALUES (r_n33.*)                    
                                                        
END FUNCTION                                            



FUNCTION actualiza_detalle_liquidacion(valor, codcia, cod_liqrol, fecha_ini,
	fecha_fin, cod_trab, cod_rubro)                                     
DEFINE valor		DECIMAL(12,2)                                       
DEFINE codcia		LIKE rolt033.n33_compania                           
DEFINE cod_liqrol	LIKE rolt033.n33_cod_liqrol                         
DEFINE fecha_ini	LIKE rolt033.n33_fecha_ini                          
DEFINE fecha_fin	LIKE rolt033.n33_fecha_fin                          
DEFINE cod_trab		LIKE rolt033.n33_cod_trab                           
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro                          
                                                                            
UPDATE rolt033 SET n33_valor = valor                                        
	WHERE n33_compania   = codcia   AND                                 
              n33_cod_liqrol = cod_liqrol AND                               
              n33_fecha_ini  = fecha_ini  AND                               
              n33_fecha_fin  = fecha_fin  AND                               
              n33_cod_trab   = cod_trab   AND                               
              n33_cod_rubro  = cod_rubro                                    
                                                                            
END FUNCTION                                                                
