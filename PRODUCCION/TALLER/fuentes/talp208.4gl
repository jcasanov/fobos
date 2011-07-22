------------------------------------------------------------------------------
-- Titulo           : talp208.4gl - Aprobación crédito de ordenes de trabajo 
-- Elaboracion      : 22-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp208 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_tal		RECORD LIKE talt025.*
DEFINE rm_tal2		RECORD LIKE talt026.*
DEFINE rm_tal3		RECORD LIKE talt027.*
DEFINE rm_ord		RECORD LIKE talt023.*
DEFINE rm_mol		RECORD LIKE talt004.*
DEFINE vm_max_elm       SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE vm_ind_docs      SMALLINT
DEFINE vm_entro_inp    	SMALLINT
DEFINE vm_fec_vcto	DATE
DEFINE vm_total_cap     DECIMAL(11,2)
DEFINE vm_total_int     DECIMAL(11,2)
DEFINE vm_total_gen     DECIMAL(11,2)
DEFINE vm_plazo_dia	LIKE talt025.t25_plazo
DEFINE vm_areaneg	LIKE gent020.g20_areaneg
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_deto		ARRAY [100] OF RECORD
				t23_orden	LIKE talt023.t23_orden,
				t23_nom_cliente	LIKE talt023.t23_nom_cliente,
				t23_tot_neto	LIKE talt023.t23_tot_neto,
				t25_valor_cred	LIKE talt025.t25_valor_cred,
				t25_valor_ant	LIKE talt025.t25_valor_ant
			END RECORD
DEFINE rm_ta 		ARRAY [100] OF RECORD
				t26_dividendo	LIKE talt026.t26_dividendo,
				t26_fec_vcto	LIKE talt026.t26_fec_vcto,
				t26_valor_cap	LIKE talt026.t26_valor_cap,
				t26_valor_int	LIKE talt026.t26_valor_int,
				tit_valor_tot	DECIMAL(11,2)
			END RECORD
DEFINE rm_docs 		ARRAY[100] OF RECORD
        			t27_tipo        LIKE talt027.t27_tipo,
        			t27_numero	LIKE talt027.t27_numero,
        			z21_moneda	LIKE cxct021.z21_moneda,
        			z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
        			t27_valor       LIKE talt027.t27_valor,
        			tit_valor_usar	LIKE talt027.t27_valor
			END RECORD
DEFINE rm_ta_aux	ARRAY [100] OF RECORD
				t26_dividendo	LIKE talt026.t26_dividendo,
				t26_fec_vcto	LIKE talt026.t26_fec_vcto,
				t26_valor_cap	LIKE talt026.t26_valor_cap,
				t26_valor_int	LIKE talt026.t26_valor_int,
				tit_valor_tot	DECIMAL(11,2)
			END RECORD
DEFINE rm_docs_aux	ARRAY[100] OF RECORD
        			t27_tipo        LIKE talt027.t27_tipo,
        			t27_numero	LIKE talt027.t27_numero,
        			z21_moneda	LIKE cxct021.z21_moneda,
        			z21_fecha_emi	LIKE cxct021.z21_fecha_emi,
        			t27_valor       LIKE talt027.t27_valor,
        			tit_valor_usar	LIKE talt027.t27_valor
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp208.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp208'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i,j,l,col	SMALLINT
DEFINE query		VARCHAR(500)
DEFINE tipo		LIKE talt023.t23_tipo_ot
DEFINE r_tp		RECORD LIKE talt005.*

CALL fl_nivel_isolation()
LET vm_max_elm = 100
OPEN WINDOW w_mas AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_mas FROM "../forms/talf208_1"
FOR i = 1 TO vm_max_elm
	INITIALIZE rm_ta[i].*, rm_ta_aux[i].*, rm_docs[i].*, rm_docs_aux[i].*
		TO NULL
END FOR
INITIALIZE rm_tal.*, rm_tal2.*, rm_tal3.*, rm_ord.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET rm_orden[1] = 'ASC'
LET vm_columna_1 = 1
LET vm_columna_2 = 2
LET col          = 1
WHILE TRUE
	DISPLAY FORM f_mas
	DISPLAY 'Orden'      TO tit_col1
	DISPLAY 'Cliente'    TO tit_col2
	DISPLAY 'Total Neto' TO tit_col3
	DISPLAY 'Crédito'    TO tit_col4
	DISPLAY 'Dcto. a Favor'  TO tit_col5
	LET query = 'SELECT t23_orden, t23_nom_cliente, t23_tot_neto, ',
			' t25_valor_cred, t25_valor_ant, t23_tipo_ot ',
			' FROM talt023, OUTER talt025 ',
			' WHERE t23_compania  = ', vg_codcia, ' AND ',
			      ' t23_localidad = ', vg_codloc, ' AND ',
			      ' t23_estado = "C" AND ',
			      ' t23_compania  = t25_compania AND ',
			      ' t23_localidad = t25_localidad AND ',
			      ' t23_orden     = t25_orden',
			" ORDER BY ", vm_columna_1, ' ', rm_orden[vm_columna_1],
			        ', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	LET i = 1
	FOREACH q_deto INTO rm_deto[i].*, tipo
		IF rm_deto[i].t25_valor_cred IS NULL THEN
			LET rm_deto[i].t25_valor_cred = 0
			LET rm_deto[i].t25_valor_ant  = 0
		END IF
		CALL fl_lee_tipo_orden_taller(vg_codcia,tipo) RETURNING r_tp.*
		IF r_tp.t05_factura = 'N' THEN
			CONTINUE FOREACH
		END IF
		IF rm_deto[i].t23_tot_neto = 0 THEN
			CONTINUE FOREACH
		END IF
		LET i = i + 1
		IF i > vm_max_elm THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = i - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT PROGRAM
	END IF
	CALL set_count(i)
	LET int_flag = 0
	DISPLAY ARRAY rm_deto TO rm_deto.*
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores(j,i)
		BEFORE DISPLAY
			CALL dialog.keysetlabel('ACCEPT','')
		AFTER DISPLAY 
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET rm_ord.t23_orden = rm_deto[j].t23_orden
			CALL sub_menu()
			LET int_flag = 0
			EXIT DISPLAY
		ON KEY(F6)
			LET rm_ord.t23_orden = rm_deto[j].t23_orden
			CALL ver_orden()
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
		ON KEY(F19)
			LET col = 5
			EXIT DISPLAY
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

END FUNCTION



FUNCTION sub_menu()
DEFINE resp		CHAR(6)
DEFINE flag,i		SMALLINT

OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_tal FROM "../forms/talf208_2"
DISPLAY FORM f_tal
CALL mostrar_botones_detalle_cre()
LET vm_entro_inp   = 0
INITIALIZE rm_mol.*, rm_tal.t25_orden, rm_tal3.t27_orden TO NULL
LET vm_scr_lin            = 0
LET vm_ind_docs           = 0
LET vm_plazo_dia          = 0
LET vm_fec_vcto           = NULL
LET rm_tal.t25_compania   = vg_codcia
LET rm_tal.t25_localidad  = vg_codloc
LET rm_tal2.t26_compania  = vg_codcia
LET rm_tal2.t26_localidad = vg_codloc
LET rm_tal3.t27_compania  = vg_codcia
LET rm_tal3.t27_localidad = vg_codloc
CALL encerar_totales()
CALL bloqueo_orden() RETURNING flag
IF flag THEN
	CLOSE FORM f_tal
	CLOSE WINDOW wf
	RETURN
END IF	
CALL mostrar_registro(rm_ord.t23_orden)
IF rm_tal.t25_orden IS NULL THEN
	CALL cargar_cabecera_default()
ELSE
	CALL cargar_fecha_plazo()
	CALL sacar_total()
	FOR i = 1 TO fgl_scr_size('rm_ta')
		IF i <= rm_tal.t25_dividendos THEN
			DISPLAY rm_ta[i].tit_valor_tot TO rm_ta[i].tit_valor_tot
		ELSE
			CLEAR rm_ta[i].tit_valor_tot
		END IF
	END FOR
	DISPLAY BY NAME vm_fec_vcto, vm_plazo_dia
END IF
MENU 'OPCIONES'
	BEFORE MENU
		SHOW OPTION 'Grabar'
		SHOW OPTION 'Crédito'
		SHOW OPTION 'Dcto. a Favor'
		SHOW OPTION 'Orden de Trabajo'
		IF rm_tal.t25_dividendos > vm_scr_lin THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
       	COMMAND KEY('C') 'Crédito' 'Créditos a un registro corriente. '
		CALL control_creditos()
		IF rm_tal.t25_dividendos > vm_scr_lin THEN
               	        SHOW OPTION 'Detalle'
		ELSE
        		HIDE OPTION 'Detalle'
	        END IF
       	COMMAND KEY('F') 'Dcto. a Favor' 'Documentos a favor del cliente. '
		CALL control_anticipos()
       	COMMAND KEY('G') 'Grabar' 'Graba el cédito del cliente. '
		IF rm_tal.t25_plazo IS NULL THEN
			CALL fgl_winmessage(vg_producto, 'Digite forma de pago', 'stop')
		ELSE
			CALL grabar()
			EXIT MENU
		END IF
       	COMMAND KEY('V') 'Orden de Trabajo' 'Ver orden actual. '
		CALL ver_orden()
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir al menú principal. '
		EXIT MENU
END MENU
CLOSE FORM f_tal
CLOSE WINDOW wf

END FUNCTION



FUNCTION bloqueo_orden()

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upord CURSOR FOR SELECT * FROM talt023
	WHERE t23_compania  = vg_codcia AND 
	      t23_localidad = vg_codloc AND 
	      t23_orden     = rm_ord.t23_orden
	FOR UPDATE
OPEN q_upord
FETCH q_upord INTO rm_ord.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN 1
END IF
IF rm_ord.t23_cod_cliente IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Orden de Trabajo no tiene el código del cliente','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION control_creditos()
DEFINE saldo_vencido		SMALLINT

CALL validar_saldo_vencido_cliente() RETURNING saldo_vencido
IF NOT saldo_vencido THEN
	CALL encerar_totales()
	CALL leer_cabecera()
	IF rm_tal.t25_valor_cred > 0 AND rm_tal.t25_interes = 0
	AND NOT int_flag THEN
		CALL leer_detalle()
	END IF
END IF
 
END FUNCTION



FUNCTION validar_saldo_vencido_cliente()
DEFINE r_cxc		RECORD LIKE cxct000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE saldo_venc       LIKE cxct030.z30_saldo_venc
DEFINE moneda		LIKE gent013.g13_moneda

CALL fl_retorna_saldo_vencido(vg_codcia,rm_ord.t23_cod_cliente)
	RETURNING moneda, saldo_venc
IF saldo_venc > 0 THEN
	CALL fl_lee_moneda(moneda) RETURNING r_mon.*
	CALL fgl_winmessage(vg_producto,'El cliente tiene un saldo vencido de ' || saldo_venc || ' en la moneda ' || r_mon.g13_nombre || '.','exclamation')
	CALL fl_lee_compania_cobranzas(vg_codcia) RETURNING r_cxc.*
	IF r_cxc.z00_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto,'No existe un registro de configuración para la compañía en cobranzas.','stop')
		EXIT PROGRAM
	END IF
	{IF r_cxc.z00_bloq_vencido = 'S' AND rm_ord.t23_cont_cred = 'R' THEN
		RETURN 1
	END IF}
END IF
RETURN 0

END FUNCTION



FUNCTION grabar()
DEFINE indice           SMALLINT
DEFINE r_tal		RECORD LIKE talt025.*
DEFINE valor		LIKE cajt010.j10_valor

WHENEVER ERROR STOP
INITIALIZE r_tal.* TO NULL
LET rm_tal.t25_orden      = rm_ord.t23_orden
LET rm_tal2.t26_orden     = rm_ord.t23_orden
LET rm_tal3.t27_orden     = rm_ord.t23_orden
LET rm_tal.t25_compania   = vg_codcia
LET rm_tal.t25_localidad  = vg_codcia
LET rm_tal2.t26_compania  = vg_codcia
LET rm_tal2.t26_localidad = vg_codcia
LET rm_tal3.t27_compania  = vg_codcia
LET rm_tal3.t27_localidad = vg_codcia
IF rm_tal.t25_valor_cred > 0 THEN
	LET rm_ord.t23_cont_cred = 'R'
ELSE
	LET rm_ord.t23_cont_cred = 'C'
END IF
CALL sacar_areaneg()
LET valor = rm_ord.t23_tot_neto - rm_tal.t25_valor_ant - rm_tal.t25_valor_cred
CALL fl_lee_cabecera_credito_taller(vg_codcia,vg_codloc,rm_ord.t23_orden)
	RETURNING r_tal.*
IF r_tal.t25_compania IS NULL THEN
	INSERT INTO talt025 VALUES (rm_tal.*)
ELSE
	UPDATE talt025 SET t25_valor_ant  = rm_tal.t25_valor_ant,
			   t25_valor_cred = rm_tal.t25_valor_cred,
			   t25_interes    = rm_tal.t25_interes,
			   t25_dividendos = rm_tal.t25_dividendos,
			   t25_plazo      = rm_tal.t25_plazo
		WHERE t25_compania  = vg_codcia
		  AND t25_localidad = vg_codloc
		  AND t25_orden     = rm_ord.t23_orden
END IF
IF vm_ind_docs > 0 THEN
	DELETE FROM talt027 WHERE t27_compania = vg_codcia
			AND t27_localidad      = vg_codloc
			AND t27_orden          = rm_tal3.t27_orden
END IF
DELETE FROM talt026 WHERE t26_compania = vg_codcia
		AND t26_localidad      = vg_codloc
		AND t26_orden          = rm_tal2.t26_orden
DELETE FROM cajt010 WHERE j10_compania = vg_codcia
		AND j10_localidad      = vg_codloc
		AND j10_tipo_fuente    = 'OT'
		AND j10_num_fuente     = rm_ord.t23_orden
FOR indice = 1 TO rm_tal.t25_dividendos
	INSERT INTO talt026 VALUES (rm_tal2.t26_compania,
		rm_tal2.t26_localidad, rm_tal2.t26_orden,
		rm_ta[indice].t26_dividendo, rm_ta[indice].t26_valor_cap,
		rm_ta[indice].t26_valor_int, rm_ta[indice].t26_fec_vcto)
END FOR
FOR indice = 1 TO vm_ind_docs
	IF rm_docs[indice].tit_valor_usar > 0 THEN
		INSERT INTO talt027 VALUES (rm_tal3.t27_compania,
			rm_tal3.t27_localidad, rm_tal3.t27_orden,
			rm_docs[indice].t27_tipo, rm_docs[indice].t27_numero,
   		     	rm_docs[indice].tit_valor_usar)
	END IF
END FOR
INSERT INTO cajt010 VALUES(vg_codcia,vg_codloc,'OT',rm_ord.t23_orden,vm_areaneg,
	'A',rm_ord.t23_cod_cliente,rm_ord.t23_nom_cliente,rm_ord.t23_moneda,
	valor,CURRENT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg_usuario,
	CURRENT)
LET int_flag = 0
UPDATE talt023 SET t23_cont_cred = rm_ord.t23_cont_cred
	WHERE CURRENT OF q_upord
COMMIT WORK
CALL fl_mensaje_registro_ingresado()
WHENEVER ERROR STOP

END FUNCTION



FUNCTION control_anticipos()
DEFINE r_cxc		RECORD LIKE cxct021.*
DEFINE r_ant		RECORD LIKE talt027.*
DEFINE valor_ant_ori	LIKE talt025.t25_valor_ant
DEFINE l		SMALLINT

OPEN WINDOW w_ant AT 06,14
        WITH FORM '../forms/talf208_3'
        ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST,
                   BORDER)
CALL mostrar_botones_detalle_ant()
IF rm_tal3.t27_orden IS NULL THEN
	LET rm_tal3.t27_orden = rm_ord.t23_orden
	CALL sacar_areaneg()
	DECLARE q_ant2 CURSOR FOR SELECT * FROM talt027
		WHERE t27_compania = vg_codcia
		AND t27_localidad  = vg_codloc
		AND t27_orden      = rm_ord.t23_orden
	DECLARE q_ant1 CURSOR FOR SELECT * FROM cxct021
        	        WHERE z21_compania  = vg_codcia
                	  AND z21_localidad = vg_codloc
	                  AND z21_codcli    = rm_ord.t23_cod_cliente
        	          AND z21_areaneg   = vm_areaneg
                	  AND z21_moneda    = rm_ord.t23_moneda
	                  AND z21_saldo     > 0
                ORDER BY z21_fecha_emi
	LET vm_ind_docs = 1
	FOREACH q_ant1 INTO r_cxc.*
		LET rm_docs[vm_ind_docs].t27_tipo       = r_cxc.z21_tipo_doc
		LET rm_docs[vm_ind_docs].t27_numero     = r_cxc.z21_num_doc
		LET rm_docs[vm_ind_docs].z21_moneda     = r_cxc.z21_moneda
		LET rm_docs[vm_ind_docs].z21_fecha_emi  = r_cxc.z21_fecha_emi
		LET rm_docs[vm_ind_docs].t27_valor      = r_cxc.z21_saldo
		LET rm_docs[vm_ind_docs].tit_valor_usar = 0
		LET vm_ind_docs = vm_ind_docs + 1
	        IF vm_ind_docs > vm_max_elm THEN
			CALL fl_mensaje_arreglo_incompleto()
			EXIT PROGRAM
       	        	--EXIT FOREACH
	        END IF
	END FOREACH
	LET vm_ind_docs = vm_ind_docs - 1
	FOREACH q_ant2 INTO r_ant.*
	        FOR l = 1 TO vm_ind_docs
        	        IF rm_docs[l].t27_tipo = r_ant.t27_tipo
 	                AND rm_docs[l].t27_numero = r_ant.t27_numero THEN
	                        LET rm_docs[l].tit_valor_usar = r_ant.t27_valor
        	                EXIT FOR
	                END IF
        	END FOR
	END FOREACH
END IF
CLOSE q_ant1
CLOSE q_ant2
IF vm_ind_docs = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_ant
	RETURN
END IF
FOR l = 1 TO vm_ind_docs
	LET rm_docs_aux[l].* = rm_docs[l].*
END FOR
DISPLAY rm_ord.t23_tot_neto TO tit_neto
LET int_flag = 0
LET valor_ant_ori = rm_tal.t25_valor_ant
CALL leer_anticipos()
CLOSE WINDOW w_ant
IF int_flag THEN
	RETURN
END IF
IF rm_tal.t25_valor_ant <> valor_ant_ori THEN
	IF rm_tal.t25_valor_cred > 0 THEN
		LET rm_tal.t25_valor_cred = rm_ord.t23_tot_neto
						- rm_tal.t25_valor_ant
		CALL muestra_detalle_default()
	END IF
END IF
DISPLAY BY NAME rm_tal.t25_valor_ant, rm_tal.t25_valor_cred
CALL sin_credito()

END FUNCTION



FUNCTION leer_anticipos()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE valor		LIKE talt027.t27_valor

OPTIONS INPUT WRAP,
	INSERT KEY F13,
	DELETE KEY F14
LET i = 1
LET resul = 0
LET int_flag = 0
WHILE TRUE
	CALL set_count(vm_ind_docs)
	INPUT ARRAY rm_docs WITHOUT DEFAULTS FROM rm_docs.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso()
       		               	RETURNING resp
       			IF resp = 'Yes' THEN
               			LET int_flag = 1
				FOR k = 1 TO vm_ind_docs
					LET rm_docs[k].* = rm_docs_aux[k].*
				END FOR
	        		RETURN
        	       	END IF	
		BEFORE INPUT
			CALL dialog.keysetlabel("DELETE","")
			CALL dialog.keysetlabel("INSERT","")
		BEFORE ROW
        		LET i = arr_curr()
	       		LET j = scr_line()
			CALL sacar_total_ant() RETURNING resul
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD tit_valor_usar
	                LET valor = rm_docs[i].tit_valor_usar
		AFTER FIELD tit_valor_usar
			IF rm_docs[i].tit_valor_usar IS NOT NULL THEN
				IF rm_docs[i].tit_valor_usar
				> rm_docs[i].t27_valor THEN
					CALL fgl_winmessage(vg_producto,'El valor debe ser menor o igual al saldo','exclamation')
					NEXT FIELD tit_valor_usar
				END IF
				CALL fl_retorna_precision_valor(
						rm_ord.t23_moneda,
						rm_docs[i].tit_valor_usar)
	                               	RETURNING rm_docs[i].tit_valor_usar
        	               	DISPLAY rm_docs[i].tit_valor_usar
					TO rm_docs[j].tit_valor_usar
				CALL sacar_total_ant() RETURNING resul
			ELSE
				LET rm_docs[i].tit_valor_usar = valor
				DISPLAY rm_docs[i].tit_valor_usar
					TO rm_docs[j].tit_valor_usar
			END IF
		AFTER INPUT
			CALL sacar_total_ant() RETURNING resul
			IF resul = 1 THEN
				CALL fgl_winmessage(vg_producto,'El total de anticipos no puede ser mayor que el neto de la orden','exclamation')
				NEXT FIELD tit_valor_usar
			END IF
			EXIT WHILE
	END INPUT
END WHILE

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE orden		LIKE talt023.t23_orden
DEFINE nomcli		LIKE talt023.t23_nom_cliente
DEFINE r_tal		RECORD LIKE talt025.*
DEFINE plazo_dia	LIKE talt025.t25_plazo
DEFINE fec_vcto		DATE
DEFINE i		SMALLINT

INITIALIZE orden TO NULL
INITIALIZE plazo_dia TO NULL
INITIALIZE fec_vcto TO NULL
INITIALIZE r_tal.* TO NULL
CALL encerar_totales()
LET int_flag = 0
INPUT BY NAME vm_fec_vcto, vm_plazo_dia, rm_tal.t25_dividendos,
	rm_tal.t25_interes
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(vm_fec_vcto, vm_plazo_dia,
			rm_tal.t25_dividendos, rm_tal.t25_interes)
		THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET vm_entro_inp = 0
				CALL sacar_total()
				LET vm_fec_vcto          = fec_vcto
				LET vm_plazo_dia         = plazo_dia
				LET rm_tal.t25_dividendos = r_tal.t25_dividendos
				LET rm_tal.t25_interes    = r_tal.t25_interes 
				LET rm_tal.t25_plazo      = r_tal.t25_plazo 
				IF fec_vcto IS NOT NULL THEN
					LET rm_tal.t25_valor_cred =
							r_tal.t25_valor_cred
				ELSE
					LET rm_tal.t25_valor_cred = 0
				END IF
				LET rm_tal.t25_valor_ant  = r_tal.t25_valor_ant 
				DISPLAY BY NAME rm_ord.t23_orden, vm_plazo_dia,
						vm_fec_vcto,
						rm_tal.t25_dividendos,
						rm_tal.t25_interes,
						rm_tal.t25_plazo,
						rm_tal.t25_valor_cred,
						rm_tal.t25_valor_ant
				LET int_flag = 1
				RETURN
                	END IF
		ELSE
			RETURN
		END IF
	ON KEY(F6)
		CALL ver_orden()
	BEFORE INPUT
		LET vm_entro_inp = 1
		DISPLAY BY NAME rm_ord.t23_orden
		CALL muestra_cabecera()
		IF rm_tal.t25_valor_cred = 0 THEN
			LET rm_tal.t25_valor_cred = rm_ord.t23_tot_neto
							- rm_tal.t25_valor_ant
			DISPLAY BY NAME rm_tal.t25_valor_cred
		END IF
		LET fec_vcto             = vm_fec_vcto
		LET plazo_dia	         = vm_plazo_dia
		LET r_tal.t25_dividendos = rm_tal.t25_dividendos
		LET r_tal.t25_interes    = rm_tal.t25_interes 
		LET r_tal.t25_plazo      = rm_tal.t25_plazo 
		LET r_tal.t25_valor_cred = rm_tal.t25_valor_cred
		LET r_tal.t25_valor_ant  = rm_tal.t25_valor_ant 
	AFTER FIELD vm_fec_vcto
		IF vm_fec_vcto IS NOT NULL THEN
			IF vm_fec_vcto < TODAY + 1 THEN
				CALL fgl_winmessage(vg_producto,'Esta fecha no es válida. Mínimo un día más que la fecha de hoy','exclamation')
				NEXT FIELD vm_fec_vcto
			END IF
		ELSE
			LET vm_fec_vcto = fec_vcto
			DISPLAY BY NAME vm_fec_vcto
		END IF
	AFTER FIELD vm_plazo_dia
		IF vm_plazo_dia IS NULL THEN
			LET vm_plazo_dia = plazo_dia
			DISPLAY BY NAME vm_plazo_dia
		END IF
	AFTER FIELD t25_dividendos
		IF rm_tal.t25_dividendos IS NULL THEN
			LET rm_tal.t25_dividendos = r_tal.t25_dividendos
			DISPLAY BY NAME rm_tal.t25_dividendos
		END IF
	AFTER FIELD t25_interes
		IF rm_tal.t25_interes IS NULL THEN
			LET rm_tal.t25_interes = r_tal.t25_interes
			DISPLAY BY NAME rm_tal.t25_interes
		END IF
	AFTER INPUT 
		IF rm_tal.t25_dividendos = 0 THEN
			LET rm_tal.t25_valor_cred = 0
			CALL sin_credito()
			CALL encerar_totales()
			CALL mostrar_total()
			RETURN
		END IF
		IF vm_fec_vcto IS NULL THEN
			CALL fgl_winmessage(vg_producto,'Digíte la fecha de vencimiento del primer pago','exclamation')
			NEXT FIELD vm_fec_vcto
		END IF
		IF vm_plazo_dia > 0 THEN
			CALL calcula_plazo()
			DISPLAY BY NAME rm_tal.t25_plazo
		ELSE
			CALL fgl_winmessage(vg_producto,'Especifique días dividendos para los pagos','exclamation')
			NEXT FIELD vm_plazo_dia
		END IF
		IF (fec_vcto <> vm_fec_vcto OR plazo_dia <> vm_plazo_dia
		OR r_tal.t25_dividendos <> rm_tal.t25_dividendos
		OR r_tal.t25_interes <> rm_tal.t25_interes)
		OR rm_ta[1].t26_dividendo IS NULL THEN
			CALL muestra_detalle_default()
		END IF
		LET vm_entro_inp = 0
		FOR i = 1 TO rm_tal.t25_dividendos
			LET rm_ta_aux[i].* = rm_ta[i].* 
		END FOR
END INPUT

END FUNCTION



FUNCTION cargar_cabecera_default()
DEFINE r_loc		RECORD LIKE cxct002.*
DEFINE r_are		RECORD LIKE cxct003.*
DEFINE num_reg		INTEGER

LET rm_tal.t25_valor_ant  = 0
LET rm_tal.t25_interes    = 0
LET rm_tal.t25_dividendos = 0
LET rm_tal.t25_plazo 	  = 0
CALL fl_lee_cliente_localidad(vg_codcia,vg_codloc,rm_ord.t23_cod_cliente)
	RETURNING r_loc.*
LET num_reg = 0
SELECT COUNT(*) INTO num_reg FROM talt026
	WHERE t26_compania = vg_codcia
	AND t26_localidad  = vg_codloc
	AND t26_orden      = rm_ord.t23_orden
IF num_reg <> 0 THEN
	CALL cargar_fecha_plazo()
ELSE
	IF r_loc.z02_credit_dias > 0 THEN
		LET rm_tal.t25_plazo = r_loc.z02_credit_dias  
	ELSE
		CALL sacar_areaneg()
		CALL fl_lee_cliente_areaneg(vg_codcia,vg_codloc,
				vm_areaneg,rm_ord.t23_cod_cliente)
			RETURNING r_are.*
		LET rm_tal.t25_plazo = r_are.z03_credit_dias
	END IF
	LET vm_plazo_dia = 0
	LET vm_fec_vcto  = NULL
END IF
IF num_reg = 0 THEN
	LET rm_tal.t25_valor_cred = 0
END IF
--CALL calcula_plazo()
CALL muestra_cabecera()

END FUNCTION



FUNCTION cargar_fecha_plazo()
DEFINE r_tal2		RECORD LIKE talt026.*
DEFINE i		SMALLINT

DECLARE q_ant3 CURSOR FOR SELECT * FROM talt026
	WHERE t26_compania = vg_codcia
	AND t26_localidad  = vg_codloc
	AND t26_orden      = rm_ord.t23_orden
LET i = 1
LET vm_fec_vcto = NULL 
FOREACH q_ant3 INTO r_tal2.*
	IF i = 1 THEN
		LET vm_fec_vcto = r_tal2.t26_fec_vcto
		LET vm_plazo_dia = 30
	ELSE
		LET vm_plazo_dia = r_tal2.t26_fec_vcto - vm_fec_vcto
		EXIT FOREACH
	END IF
	LET i = i + 1
END FOREACH

END FUNCTION



FUNCTION muestra_cabecera()

CALL fl_lee_tipo_vehiculo(vg_codcia,rm_ord.t23_modelo) RETURNING rm_mol.*
CALL fl_retorna_precision_valor(rm_ord.t23_moneda,rm_tal.t25_valor_ant)
	RETURNING rm_tal.t25_valor_ant
--LET rm_tal.t25_valor_cred = rm_ord.t23_tot_neto - rm_tal.t25_valor_ant
CALL fl_retorna_precision_valor(rm_ord.t23_moneda,rm_tal.t25_valor_cred)
	RETURNING rm_tal.t25_valor_cred
DISPLAY rm_ord.t23_estado TO tit_est
DISPLAY 'CERRADA' TO tit_estado
DISPLAY rm_ord.t23_modelo TO tit_modelo
DISPLAY rm_mol.t04_linea TO tit_linea
DISPLAY rm_ord.t23_nom_cliente TO tit_cliente
DISPLAY rm_ord.t23_tot_neto TO tit_neto_cre
DISPLAY BY NAME vm_fec_vcto, vm_plazo_dia, rm_tal.t25_plazo,
		rm_tal.t25_valor_cred, rm_tal.t25_valor_ant, rm_tal.t25_interes,
		rm_tal.t25_dividendos 

END FUNCTION



FUNCTION calcula_plazo()

LET rm_tal.t25_plazo = (vm_fec_vcto - TODAY) + ((rm_tal.t25_dividendos - 1) *
			vm_plazo_dia)

END FUNCTION



FUNCTION sacar_areaneg()
DEFINE r_lin		RECORD LIKE talt001.*
DEFINE r_grp		RECORD LIKE gent020.*

CALL fl_lee_linea_taller(vg_codcia,rm_mol.t04_linea)
	RETURNING r_lin.*
CALL fl_lee_grupo_linea(vg_codcia,r_lin.t01_grupo_linea)
	RETURNING r_grp.*
IF r_grp.g20_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto,'No hay línea de venta en Taller','stop')
	EXIT PROGRAM
END IF
LET vm_areaneg = r_grp.g20_areaneg

END FUNCTION



FUNCTION muestra_detalle_default()
DEFINE i		SMALLINT

LET rm_ta[1].t26_fec_vcto  = vm_fec_vcto 
FOR i = 1 TO rm_tal.t25_dividendos
	LET rm_ta[i].t26_dividendo = i
	IF i < rm_tal.t25_dividendos THEN
		LET rm_ta[i + 1].t26_fec_vcto  = rm_ta[i].t26_fec_vcto
						+ vm_plazo_dia
	END IF
	LET rm_ta[i].t26_valor_cap = rm_tal.t25_valor_cred/rm_tal.t25_dividendos
	IF rm_tal.t25_interes > 0 THEN
		CALL calculo_valor_interes(i)
	ELSE
		LET rm_ta[i].t26_valor_int = rm_tal.t25_interes 
	END IF
	CALL fl_retorna_precision_valor(rm_ord.t23_moneda,
					rm_ta[i].t26_valor_cap)
        	RETURNING rm_ta[i].t26_valor_cap
	CALL fl_retorna_precision_valor(rm_ord.t23_moneda,
					rm_ta[i].t26_valor_int)
        	RETURNING rm_ta[i].t26_valor_int
END FOR
CALL sacar_total()
LET rm_ta[rm_tal.t25_dividendos].t26_valor_cap = 
	rm_ta[rm_tal.t25_dividendos].t26_valor_cap + rm_tal.t25_valor_cred
	- vm_total_cap 
CALL sacar_total()
CALL muestra_lineas_detalle()
CALL mostrar_total()

END FUNCTION



FUNCTION calculo_valor_interes(lim)
DEFINE lim,i		SMALLINT
DEFINE valor_cap_acum	LIKE talt026.t26_valor_cap

LET valor_cap_acum = 0
FOR i = 1 TO lim - 1
	LET valor_cap_acum = valor_cap_acum + rm_ta[i].t26_valor_cap
END FOR
LET rm_ta[lim].t26_valor_int = (rm_tal.t25_valor_cred - valor_cap_acum)
				* (rm_tal.t25_interes / 100)
				* (vm_plazo_dia / 360)

END FUNCTION



FUNCTION leer_detalle()
DEFINE resul		SMALLINT
DEFINE resp             CHAR(6)
DEFINE i,j,k		SMALLINT
DEFINE fec_vcto		LIKE talt026.t26_fec_vcto
DEFINE valor_cap	LIKE talt026.t26_valor_cap

OPTIONS INPUT WRAP,
	INSERT KEY F13,
	DELETE KEY F14
LET i = 1
LET resul = 0
CALL encerar_totales()
LET int_flag = 0
WHILE TRUE
	CALL set_count(rm_tal.t25_dividendos)
	INPUT ARRAY rm_ta WITHOUT DEFAULTS FROM rm_ta.*
		ON KEY(INTERRUPT)
       			LET int_flag = 0
	               	CALL fl_mensaje_abandonar_proceso()
       		               	RETURNING resp
       			IF resp = 'Yes' THEN
				FOR k = 1 TO rm_tal.t25_dividendos
					LET rm_ta[k].*  = rm_ta_aux[k].*
				END FOR
				CALL muestra_lineas_detalle()
               			LET int_flag = 1
	        		RETURN 
        	       	END IF	
		ON KEY(F6)
			CALL ver_orden()
		BEFORE INPUT
			CALL dialog.keysetlabel("DELETE","")
			CALL dialog.keysetlabel("INSERT","")
			LET vm_scr_lin = fgl_scr_size('rm_ta')
		BEFORE ROW
        		LET i = arr_curr()
       			LET j = scr_line()
			CALL sacar_total()
		BEFORE INSERT
			EXIT INPUT
		BEFORE FIELD t26_fec_vcto
                	LET fec_vcto = rm_ta[i].t26_fec_vcto
		BEFORE FIELD t26_valor_cap
        	        LET valor_cap = rm_ta[i].t26_valor_cap
		AFTER FIELD t26_fec_vcto
			IF rm_ta[i].t26_fec_vcto IS NOT NULL THEN
				IF rm_ta[i].t26_fec_vcto < TODAY + 1 THEN
					CALL fgl_winmessage(vg_producto,'Esta fecha no es válida. Mínimo un día más que la fecha de hoy','exclamation')
					NEXT FIELD t26_fec_vcto
				END IF
			ELSE
				LET rm_ta[i].t26_fec_vcto = fec_vcto
				DISPLAY rm_ta[i].t26_fec_vcto
					TO rm_ta[j].t26_fec_vcto
	        	END IF
		AFTER FIELD t26_valor_cap
			IF rm_ta[i].t26_valor_cap IS NOT NULL THEN
				CALL fl_retorna_precision_valor(
							rm_ord.t23_moneda,
							rm_ta[i].t26_valor_cap)
	                               	RETURNING rm_ta[i].t26_valor_cap
        	               	DISPLAY rm_ta[i].t26_valor_cap
					TO rm_ta[j].t26_valor_cap
				CALL sacar_total()
			ELSE
				LET rm_ta[i].t26_valor_cap = valor_cap
				DISPLAY rm_ta[i].t26_valor_cap
					TO rm_ta[j].t26_valor_cap
			END IF
			DISPLAY rm_ta[i].tit_valor_tot
				TO rm_ta[j].tit_valor_tot
		AFTER INPUT
			CALL sacar_total()
			CALL validar_campos() RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD t26_fec_vcto
			END IF
			IF resul = 2 THEN
				NEXT FIELD t26_valor_cap
			END IF
			EXIT WHILE
	END INPUT
END WHILE
RETURN

END FUNCTION



FUNCTION validar_campos()
DEFINE i,j		SMALLINT

IF vm_total_cap <> rm_tal.t25_valor_cred THEN
	CALL fgl_winmessage(vg_producto,'Existen valores de capital no válidos, corrijalos','exclamation')
	RETURN 2
END IF
LET j = rm_tal.t25_dividendos - 1
FOR i = 1 TO j
	IF rm_ta[i].t26_fec_vcto >= rm_ta[i + 1].t26_fec_vcto THEN
		CALL fgl_winmessage(vg_producto,'Existen fechas de dividendos no válidas, corrijalas','exclamation')
		RETURN 1
	END IF
END FOR
LET rm_tal.t25_plazo = rm_ta[j + 1].t26_fec_vcto - TODAY
LET vm_fec_vcto      = rm_ta[1].t26_fec_vcto
DISPLAY BY NAME vm_fec_vcto, rm_tal.t25_plazo
RETURN 0

END FUNCTION



FUNCTION sin_credito()
DEFINE l		SMALLINT

IF rm_tal.t25_valor_cred = 0 THEN
	FOR l = 1 TO vm_scr_lin
		INITIALIZE rm_ta[l].* TO NULL
		CLEAR rm_ta[l].*
	END FOR
	LET rm_tal.t25_dividendos = 0
	LET rm_tal.t25_plazo      = 0
	LET rm_tal.t25_interes    = 0
	LET vm_plazo_dia          = 0
	LET vm_fec_vcto           = NULL
	DISPLAY BY NAME rm_tal.t25_dividendos, vm_fec_vcto, rm_tal.t25_plazo,
			rm_tal.t25_interes, vm_plazo_dia, rm_tal.t25_valor_cred
END IF

END FUNCTION



FUNCTION sacar_total_ant()
DEFINE i		SMALLINT

LET rm_tal.t25_valor_ant = 0
FOR i = 1 TO vm_ind_docs
	LET rm_tal.t25_valor_ant = rm_tal.t25_valor_ant
					+ rm_docs[i].tit_valor_usar
END FOR
DISPLAY rm_tal.t25_valor_ant TO t25_valor_ant
IF rm_tal.t25_valor_ant > rm_ord.t23_tot_neto THEN
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION sacar_total()
DEFINE i		SMALLINT

CALL encerar_totales()
FOR i = 1 TO rm_tal.t25_dividendos
	CALL sumar_totales(i)
END FOR
CALL mostrar_total()

END FUNCTION



FUNCTION encerar_totales()

LET vm_total_cap = 0
LET vm_total_int = 0
LET vm_total_gen = 0

END FUNCTION



FUNCTION sumar_totales(i)
DEFINE i		SMALLINT

LET rm_ta[i].tit_valor_tot = rm_ta[i].t26_valor_cap + rm_ta[i].t26_valor_int
CALL fl_retorna_precision_valor(rm_ord.t23_moneda,rm_ta[i].tit_valor_tot)
	RETURNING rm_ta[i].tit_valor_tot
LET vm_total_cap = vm_total_cap + rm_ta[i].t26_valor_cap
LET vm_total_int = vm_total_int + rm_ta[i].t26_valor_int
LET vm_total_gen = vm_total_gen + rm_ta[i].tit_valor_tot

END FUNCTION



FUNCTION ver_orden()

IF rm_ord.t23_orden IS NULL THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'TALLER',
	vg_separador, 'fuentes', vg_separador, '; fglrun talp204 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_ord.t23_orden,
	' ', 'O'
RUN vm_nuevoprog

END FUNCTION



FUNCTION mostrar_registro(num_orden)
DEFINE num_orden	LIKE talt023.t23_orden

LET rm_tal.t25_interes    = 0
LET rm_tal.t25_dividendos = 1
CALL fl_lee_cabecera_credito_taller(vg_codcia, vg_codloc, num_orden)
	RETURNING rm_tal.*
DISPLAY num_orden TO t23_orden
CALL muestra_cabecera()
CALL muestra_detalle(num_orden)

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE talt023.t23_orden
DEFINE query            VARCHAR(400)
DEFINE i  		SMALLINT

LET vm_scr_lin = fgl_scr_size('rm_ta')
LET int_flag = 0
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_ta[i].* TO NULL
        CLEAR rm_ta[i].*
END FOR
LET i = 1
LET query = 'SELECT t26_dividendo,t26_fec_vcto,t26_valor_cap,t26_valor_int ' ||
		'FROM talt026 ' ||
                'WHERE t26_compania = ' || vg_codcia ||
		' AND t26_localidad = ' || vg_codloc ||
		' AND t26_orden = ' || num_reg || ' ORDER BY 1' 
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET rm_tal.t25_dividendos = 0
FOREACH q_cons1 INTO rm_ta[i].*
        LET rm_tal.t25_dividendos = rm_tal.t25_dividendos + 1
        LET i = i + 1
        IF rm_tal.t25_dividendos > vm_max_elm THEN
        	LET rm_tal.t25_dividendos = rm_tal.t25_dividendos - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
IF rm_tal.t25_dividendos > 0 THEN
        LET int_flag = 0
	CALL muestra_lineas_detalle()
END IF
CALL sacar_total()
IF int_flag THEN
        RETURN
END IF
CALL set_count(rm_tal.t25_dividendos)

END FUNCTION



FUNCTION muestra_lineas_detalle()
DEFINE i		SMALLINT
DEFINE lineas		SMALLINT

LET lineas = fgl_scr_size('rm_ta')
FOR i = 1 TO lineas
	IF i <= rm_tal.t25_dividendos THEN
		DISPLAY rm_ta[i].* TO rm_ta[i].*
	ELSE
		CLEAR rm_ta[i].*
	END IF
END FOR

END FUNCTION



FUNCTION muestra_detalle_arr()
DEFINE i,j		SMALLINT

CALL set_count(rm_tal.t25_dividendos)
DISPLAY ARRAY rm_ta TO rm_ta.*
	BEFORE ROW
		LET i = arr_curr()
        	LET j = scr_line()
		DISPLAY rm_ta[i].tit_valor_tot TO rm_ta[j].tit_valor_tot
	BEFORE DISPLAY
		LET vm_scr_lin = fgl_scr_size('rm_ta')
		CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY

END FUNCTION



FUNCTION mostrar_total()

DISPLAY vm_total_cap TO tit_total_cap
DISPLAY vm_total_int TO tit_total_int
DISPLAY vm_total_gen TO tit_total_gen

END FUNCTION



FUNCTION muestra_contadores(cor,num)
DEFINE cor,num	         SMALLINT
                                                                                
DISPLAY "" AT 19,1
DISPLAY cor, " de ", num AT 19, 4
                                                                                
END FUNCTION



FUNCTION mostrar_botones_detalle_cre()

DISPLAY 'No.'           TO tit_col1
DISPLAY 'Fec. Vcto.'    TO tit_col2
DISPLAY 'Valor Capital' TO tit_col3
DISPLAY 'Valor Interés' TO tit_col4
DISPLAY 'Valor Total'   TO tit_col5

END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_botones_detalle_ant()

DISPLAY 'Tipo Documento'   TO tit_col6
DISPLAY 'Mon'              TO tit_col7
DISPLAY 'Fecha Emi.'       TO tit_col8
DISPLAY 'Saldo Documento'  TO tit_col9
DISPLAY 'Valor a Utilizar' TO tit_col10

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
