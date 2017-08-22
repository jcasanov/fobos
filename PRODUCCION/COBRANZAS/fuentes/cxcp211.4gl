--------------------------------------------------------------------------------
-- Titulo           : cxcp211.4gl - Proceso Digitacion Retenciones de Facturas
-- Elaboracion      : 13-Mar-2008
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp211 base modulo compaÃ±Ã­a localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 		RECORD
				z20_codcli	LIKE cxct020.z20_codcli,
				z01_nomcli	LIKE cxct001.z01_nomcli,
				z20_areaneg	LIKE cxct020.z20_areaneg,
				g03_nombre	LIKE gent003.g03_nombre,
				tipo_venta	CHAR(1),
				devuelve	CHAR(1),
				rezagadas	CHAR(1),
				z20_linea	LIKE cxct020.z20_linea,
				g20_nombre	LIKE gent020.g20_nombre,
				z20_moneda	LIKE cxct020.z20_moneda,
				g13_nombre	LIKE gent013.g13_nombre,
				z20_paridad	LIKE cxct020.z20_paridad,
				z24_zona_cobro	LIKE cxct024.z24_zona_cobro,
				z06_nombre	LIKE cxct006.z06_nombre
			END RECORD
DEFINE rm_detalle	ARRAY[20000] OF RECORD
				z20_localidad	LIKE cxct020.z20_localidad,
				z20_tipo_doc	LIKE cxct020.z20_tipo_doc,
				num_doc		VARCHAR(20),
				z20_fecha_emi	LIKE cxct020.z20_fecha_emi,
				z20_fecha_vcto	LIKE cxct020.z20_fecha_vcto,
				z20_valor_cap	LIKE cxct020.z20_valor_cap,
				z20_saldo_cap	LIKE cxct020.z20_saldo_cap,
				valor_ret	DECIMAL(12,2),
				chequear	CHAR(1)
			END RECORD
DEFINE rm_adi		ARRAY[20000] OF RECORD
				z20_num_doc	LIKE cxct020.z20_num_doc,
				z20_dividendo	LIKE cxct020.z20_dividendo,
				num_sri		LIKE rept038.r38_num_sri,
				z20_cod_tran	LIKE cxct020.z20_cod_tran,
				z20_num_tran	LIKE cxct020.z20_num_tran,
				num_ret_sri	LIKE cajt014.j14_num_ret_sri,
				tipo_f		LIKE cajt010.j10_tipo_fuente,
				num_f		LIKE cajt010.j10_num_fuente
			END RECORD
DEFINE vm_num_sol	LIKE cxct024.z24_numero_sol
DEFINE vm_cod_tran	LIKE rept019.r19_cod_tran
DEFINE vm_tipo_fue	LIKE cajt010.j10_tipo_fuente
DEFINE vm_tipo_doc	LIKE cajt010.j10_tipo_destino
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_j02		RECORD LIKE cajt002.*
DEFINE rm_j04		RECORD LIKE cajt004.*
DEFINE rm_j14		RECORD LIKE cajt014.*
DEFINE rm_s00   	RECORD LIKE srit000.*
DEFINE rm_detret	ARRAY[50] OF RECORD
				j14_codigo_pago	LIKE cajt014.j14_codigo_pago,
				j14_tipo_ret	LIKE cajt014.j14_tipo_ret,
				j14_porc_ret	LIKE cajt014.j14_porc_ret,
				j14_codigo_sri	LIKE cajt014.j14_codigo_sri,
				c03_concepto_ret LIKE ordt003.c03_concepto_ret,
				j14_base_imp	LIKE cajt014.j14_base_imp,
				j14_valor_ret	LIKE cajt014.j14_valor_ret
			END RECORD
DEFINE fec_ini_por	ARRAY[50] OF LIKE cajt014.j14_fec_ini_porc
DEFINE rm_adi_r		ARRAY[50] OF RECORD
				tipo_fuente	LIKE cajt010.j10_tipo_fuente,
				cod_tr		LIKE cajt010.j10_tipo_destino,
				num_tr		LIKE cajt010.j10_num_destino,
				num_sri		LIKE rept038.r38_num_sri,
				tipo_doc	LIKE rept038.r38_tipo_doc
			END RECORD
DEFINE dias_tope	SMALLINT
DEFINE vm_num_ret	SMALLINT
DEFINE vm_max_ret	SMALLINT
DEFINE tot_base_imp	DECIMAL(12,2)
DEFINE tot_valor_ret	DECIMAL(12,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp211.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parÃ¡metros correcto
	CALL fl_mostrar_mensaje('NÃºmero de parÃ¡metros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp211'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
CALL fl_control_status_caja(vg_codcia, vg_codloc, 'S') RETURNING int_flag
IF int_flag <> 0 THEN
	RETURN
END IF	
CALL fl_chequeo_mes_proceso_cxc(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
CALL fl_lee_configuracion_sri(vg_codcia) RETURNING rm_s00.*
IF rm_s00.s00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada la compania de SRI.', 'stop')
	RETURN
END IF
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuración para esta compañía en el módulo de CONTABILIDAD.','stop')
	RETURN
END IF
CREATE TEMP TABLE tmp_ret
	(
		num_ret_sri		CHAR(21),
		autorizacion		VARCHAR(15,10),
		fecha_emi		DATE,
		cod_pago		CHAR(2),
		tipo_ret		CHAR(1),
		porc_ret		DECIMAL(5,2),
		codigo_sri		CHAR(6),
		concepto_ret		VARCHAR(200,100),
		base_imp		DECIMAL(12,2),
		valor_ret		DECIMAL(12,2),
		tipo_fuente		CHAR(2),
		cod_tr			CHAR(2),
		num_tr			VARCHAR(16),
		num_fac_sri		CHAR(21),
		tipo_doc		CHAR(2),
		numero_sol		INTEGER,
		fec_ini_porc		DATE
	)
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
OPEN WINDOW w_cxcf211_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcp211_1 FROM '../forms/cxcf211_1'
ELSE
	OPEN FORM f_cxcp211_1 FROM '../forms/cxcf211_1c'
END IF
DISPLAY FORM f_cxcp211_1
LET vm_cod_tran = 'FA'
LET vm_max_rows = 20000
LET dias_tope   = rm_s00.s00_dias_ret
--#DISPLAY 'LC'			TO tit_col1
--#DISPLAY 'TP'			TO tit_col2
--#DISPLAY 'Documento'      	TO tit_col3
--#DISPLAY 'Fecha Emi.'	 	TO tit_col4
--#DISPLAY 'Fecha Vcto.'	TO tit_col5
--#DISPLAY 'Valor Doc.'		TO tit_col6
--#DISPLAY 'Saldo Doc.'		TO tit_col7
--#DISPLAY 'Valor Ret.'		TO tit_col8
--#DISPLAY 'C'			TO tit_col9
LET vm_size_arr = fgl_scr_size('rm_detalle')
INITIALIZE rm_par.* TO NULL
LET rm_par.z20_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.z20_moneda) RETURNING r_g13.*
LET rm_par.g13_nombre = r_g13.g13_nombre
CALL calcula_paridad(rm_par.z20_moneda, rg_gen.g00_moneda_base)
	RETURNING rm_par.z20_paridad
LET rm_par.tipo_venta = 'T'
LET rm_par.devuelve   = 'N'
LET rm_par.rezagadas  = 'S'
DISPLAY BY NAME rm_par.*
CALL fl_retorna_caja(vg_codcia, vg_codloc, vg_usuario) RETURNING rm_j02.*
IF rm_j02.j02_codigo_caja IS NULL THEN
	CALL fl_mostrar_mensaje('No hay una caja asignada al usuario ' || vg_usuario || '.','stop')
	EXIT PROGRAM
END IF
IF (rm_j02.j02_aux_cont IS NULL) AND (vg_codloc <> 2 AND vg_codloc <> 4) THEN
	CALL fl_mostrar_mensaje('El codigo de caja asignada del usuario ' || vg_usuario CLIPPED || ' no tiene auxiliar contable.', 'stop')
	EXIT PROGRAM
END IF
IF rm_j02.j02_solicitudes = 'N' THEN
	LET rm_par.tipo_venta = 'C'
	LET rm_par.devuelve   = 'S'
ELSE
	IF rm_j02.j02_pre_ventas = 'N' AND rm_j02.j02_ordenes = 'N' THEN
		LET rm_par.tipo_venta = 'R'
	END IF
END IF
INITIALIZE rm_j04.* TO NULL
SELECT * INTO rm_j04.* FROM cajt004
	WHERE j04_compania    = vg_codcia
	  AND j04_localidad   = vg_codloc
	  AND j04_codigo_caja = rm_j02.j02_codigo_caja
	  AND j04_fecha_aper  = vg_fecha
	  AND j04_secuencia   =
		(SELECT MAX(j04_secuencia)
			FROM cajt004
			WHERE j04_compania    = vg_codcia
			  AND j04_localidad   = vg_codloc
			  AND j04_codigo_caja = rm_j02.j02_codigo_caja
			  AND j04_fecha_aper  = vg_fecha)
IF STATUS = NOTFOUND THEN 
	CALL fl_mostrar_mensaje('La caja no esta aperturada.', 'stop')
	EXIT PROGRAM
END IF
LET vm_tipo_fue = 'SC'
WHILE TRUE
	LET vm_tipo_doc = 'PG'
	CALL borrar_pantalla()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF ejecutar_carga_datos_temp() THEN
		CALL control_detalle()
		IF NOT int_flag THEN
			CALL control_generar_transaccion_ret()
		END IF
		DROP TABLE tmp_det
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_cxcf211_1
DROP TABLE tmp_ret
EXIT PROGRAM

END FUNCTION



FUNCTION borrar_pantalla()
DEFINE i		SMALLINT

DELETE FROM tmp_ret WHERE 1 = 1
INITIALIZE vm_num_sol, rm_j14.* TO NULL
LET vm_num_rows = 0
FOR i = 1 TO vm_size_arr 
	CLEAR rm_detalle[i].*
END FOR
CLEAR num_row, max_row, tot_val, tot_ret, tot_sal

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_z06		RECORD LIKE cxct006.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g20		RECORD LIKE gent020.*

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z20_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli,
					  r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.z20_codcli = r_z01.z01_codcli
				LET rm_par.z01_nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.z20_codcli,
						rm_par.z01_nomcli
				IF rm_par.tipo_venta <> 'C' THEN
					CONTINUE INPUT
				END IF
				CALL fl_lee_cliente_localidad(vg_codcia,
							vg_codloc,
							rm_par.z20_codcli)
			 		RETURNING r_z02.*
				LET rm_par.z24_zona_cobro = r_z02.z02_zona_cobro
				CALL fl_lee_zona_cobro(rm_par.z24_zona_cobro)
					RETURNING r_z06.*
				DISPLAY BY NAME rm_par.z24_zona_cobro,
						r_z06.z06_nombre
			END IF
		END IF
		IF INFIELD(z20_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING r_g03.g03_areaneg, r_g03.g03_nombre
			IF r_g03.g03_areaneg IS NOT NULL THEN
				LET rm_par.z20_areaneg = r_g03.g03_areaneg
				LET rm_par.g03_nombre  = r_g03.g03_nombre
				DISPLAY BY NAME rm_par.z20_areaneg,
						rm_par.g03_nombre
				CALL obtener_grupo(r_g03.g03_areaneg)
					RETURNING r_g20.*
				LET rm_par.z20_linea  = r_g20.g20_grupo_linea
				LET rm_par.g20_nombre = r_g20.g20_nombre
				DISPLAY BY NAME rm_par.z20_linea,
						rm_par.g20_nombre
			END IF
		END IF
		IF INFIELD(z20_linea) THEN
			CALL fl_ayuda_grupo_lineas(vg_codcia) 
				RETURNING r_g20.g20_grupo_linea,r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				LET rm_par.z20_linea  = r_g20.g20_grupo_linea
				LET rm_par.g20_nombre = r_g20.g20_nombre
				DISPLAY BY NAME rm_par.z20_linea,
						r_g20.g20_nombre
				CALL fl_lee_grupo_linea(vg_codcia,
							rm_par.z20_linea)
					RETURNING r_g20.*
				LET rm_par.z20_areaneg = r_g20.g20_areaneg
				CALL fl_lee_area_negocio(vg_codcia,
							rm_par.z20_areaneg)
					RETURNING r_g03.*
				LET rm_par.g03_nombre = r_g03.g03_nombre
				DISPLAY BY NAME rm_par.z20_areaneg,
						rm_par.g03_nombre
			END IF
		END IF
		IF INFIELD(z24_zona_cobro) THEN
			IF rm_par.tipo_venta = 'C' THEN
				CONTINUE INPUT
			END IF
			IF r_z02.z02_zona_cobro IS NOT NULL THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_zona_cobro('T', 'A')
				RETURNING r_z06.z06_zona_cobro, r_z06.z06_nombre
			IF r_z06.z06_zona_cobro IS NOT NULL THEN
				LET rm_par.z24_zona_cobro = r_z06.z06_zona_cobro
				LET rm_par.z06_nombre     = r_z06.z06_nombre
				DISPLAY BY NAME rm_par.z24_zona_cobro,
						rm_par.z06_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD z24_zona_cobro
		IF rm_par.tipo_venta = 'C' THEN
			LET rm_par.z24_zona_cobro = NULL
			LET rm_par.z06_nombre     = NULL
			DISPLAY BY NAME rm_par.z24_zona_cobro, rm_par.z06_nombre
			CONTINUE INPUT
		END IF
		CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
						rm_par.z20_codcli)
			RETURNING r_z02.*
		IF r_z02.z02_zona_cobro IS NOT NULL THEN
			--IF rm_par.z24_zona_cobro <> r_z02.z02_zona_cobro THEN
				LET rm_par.z24_zona_cobro = r_z02.z02_zona_cobro
				CALL fl_lee_zona_cobro(rm_par.z24_zona_cobro)
					RETURNING r_z06.*
				DISPLAY BY NAME rm_par.z24_zona_cobro,
						r_z06.z06_nombre
				CONTINUE INPUT
			--END IF
		END IF
	AFTER FIELD z20_codcli
		IF rm_par.z20_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.z20_codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD z20_codcli
			END IF
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z20_codcli
			END IF
			{--
			IF r_z01.z01_tipo_doc_id <> 'R' THEN
				CALL fl_mostrar_mensaje('Este cliente no tiene configurado RUC, por lo tanto no puede digitarle retenciones.', 'exclamation')
				NEXT FIELD z20_codcli
			END IF
			--}
			LET rm_par.z01_nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.z01_nomcli
			IF rm_par.tipo_venta <> 'C' THEN
				CONTINUE INPUT
			END IF
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_par.z20_codcli)
		 		RETURNING r_z02.*
			LET rm_par.z24_zona_cobro = r_z02.z02_zona_cobro
			CALL fl_lee_zona_cobro(rm_par.z24_zona_cobro)
				RETURNING r_z06.*
			DISPLAY BY NAME rm_par.z24_zona_cobro, r_z06.z06_nombre
		ELSE
			LET rm_par.z01_nomcli = NULL
			CLEAR z01_nomcli
		END IF
	AFTER FIELD z20_areaneg
		IF rm_par.z20_areaneg IS NULL THEN
			LET rm_par.z20_linea   = NULL
			LET rm_par.g20_nombre  = NULL
			LET rm_par.z20_areaneg = NULL
			LET rm_par.g03_nombre  = NULL
			DISPLAY BY NAME rm_par.*
			CONTINUE INPUT
		END IF
		CALL fl_lee_area_negocio(vg_codcia, rm_par.z20_areaneg)
			RETURNING r_g03.*
		IF r_g03.g03_areaneg IS NULL THEN
			CALL fl_mostrar_mensaje('Area de negocio no existe.', 'exclamation')
			LET rm_par.g20_nombre = NULL
			LET rm_par.z20_linea  = NULL
			LET rm_par.g03_nombre = NULL
			DISPLAY BY NAME rm_par.*
			NEXT FIELD z20_areaneg
		END IF
		LET rm_par.g03_nombre = r_g03.g03_nombre
		CALL obtener_grupo(r_g03.g03_areaneg) RETURNING r_g20.*
		LET rm_par.z20_linea  = r_g20.g20_grupo_linea
		LET rm_par.g20_nombre = r_g20.g20_nombre
		DISPLAY BY NAME rm_par.z20_linea, rm_par.g03_nombre,
				rm_par.g20_nombre
	AFTER FIELD z20_linea
		IF rm_par.z20_linea IS NULL THEN
			LET rm_par.z20_linea   = NULL
			LET rm_par.g20_nombre  = NULL
			LET rm_par.z20_areaneg = NULL
			LET rm_par.g03_nombre  = NULL
			DISPLAY BY NAME rm_par.*
			CONTINUE INPUT
		END IF
		CALL fl_lee_grupo_linea(vg_codcia, rm_par.z20_linea)
			RETURNING r_g20.*
		IF r_g20.g20_grupo_linea IS NULL THEN
			CALL fl_mostrar_mensaje('Grupo de linea no existe.','exclamation')
			LET rm_par.g20_nombre  = NULL
			LET rm_par.z20_areaneg = NULL
			LET rm_par.g03_nombre  = NULL
			DISPLAY BY NAME rm_par.*
			NEXT FIELD z20_linea
		END IF
		LET rm_par.g20_nombre  = r_g20.g20_nombre
		LET rm_par.z20_areaneg = r_g20.g20_areaneg
		CALL fl_lee_area_negocio(vg_codcia, rm_par.z20_areaneg)
			RETURNING r_g03.*
		LET rm_par.g03_nombre = r_g03.g03_nombre
		DISPLAY BY NAME rm_par.z20_areaneg, rm_par.g03_nombre,
				rm_par.g20_nombre
	AFTER FIELD z24_zona_cobro
		IF rm_par.tipo_venta = 'C' THEN
			LET rm_par.z24_zona_cobro = NULL
			LET rm_par.z06_nombre     = NULL
			DISPLAY BY NAME rm_par.z24_zona_cobro, rm_par.z06_nombre
			CONTINUE INPUT
		END IF
		IF rm_par.z24_zona_cobro IS NULL OR
		   rm_par.z24_zona_cobro <> r_z02.z02_zona_cobro
		THEN
			LET rm_par.z24_zona_cobro = r_z02.z02_zona_cobro
			CALL fl_lee_zona_cobro(rm_par.z24_zona_cobro)
				RETURNING r_z06.*
			LET rm_par.z06_nombre = r_z06.z06_nombre
			DISPLAY BY NAME rm_par.z24_zona_cobro, r_z06.z06_nombre
			CONTINUE INPUT
		END IF
		CALL fl_lee_zona_cobro(rm_par.z24_zona_cobro)
			RETURNING r_z06.*
		IF r_z06.z06_zona_cobro IS NULL THEN
			CALL fl_mostrar_mensaje('Zona de Cobro no existe.', 'exclamation')
			NEXT FIELD z24_zona_cobro
		END IF
		IF r_z06.z06_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD z24_zona_cobro
		END IF
		LET rm_par.z06_nombre = r_z06.z06_nombre
		DISPLAY BY NAME rm_par.z06_nombre
	AFTER INPUT
		IF rm_par.z24_zona_cobro IS NULL THEN
			IF rm_par.tipo_venta = 'C' THEN
				LET rm_par.z24_zona_cobro = NULL
				LET rm_par.z06_nombre     = NULL
				DISPLAY BY NAME rm_par.z24_zona_cobro,
						rm_par.z06_nombre
			ELSE
				CALL fl_mostrar_mensaje('Digite la Zona de Cobro.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		CALL fl_lee_zona_cobro(rm_par.z24_zona_cobro) RETURNING r_z06.*
		IF r_z06.z06_estado = 'B' THEN
			CALL fl_mostrar_mensaje('La Zona de Cobro esta con estado BLOQUEADO.', 'exclamation')
			NEXT FIELD z24_zona_cobro
		END IF
		LET rm_par.z06_nombre = r_z06.z06_nombre
END INPUT
IF rm_par.tipo_venta IS NULL THEN
	LET rm_par.tipo_venta = 'T'
END IF
IF rm_j02.j02_solicitudes = 'N' THEN
	LET rm_par.tipo_venta = 'C'
END IF
IF rm_par.devuelve IS NULL THEN
	LET rm_par.devuelve = 'N'
END IF
IF rm_par.rezagadas IS NULL THEN
	LET rm_par.rezagadas = 'N'
END IF
IF (rm_j02.j02_aux_cont IS NULL) AND
   (vg_codloc = 2 OR vg_codloc = 4 OR vg_codloc = 5)
THEN
	LET rm_par.tipo_venta = 'C'
	LET rm_par.devuelve   = 'S'
END IF
DISPLAY BY NAME rm_par.tipo_venta, rm_par.devuelve, rm_par.rezagadas

END FUNCTION



FUNCTION ejecutar_carga_datos_temp()
DEFINE tipo_f		LIKE cajt014.j14_tipo_fue
DEFINE query		CHAR(10000)
DEFINE expr_sub		CHAR(800)
DEFINE cuantos		INTEGER
DEFINE fec_ult		DATE

ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
CREATE TEMP TABLE tmp_det
	(
		z20_localidad		SMALLINT,
		z20_tipo_doc		CHAR(2),
		num_doc			VARCHAR(20),
		z20_fecha_emi		DATE,
		z20_fecha_vcto		DATE,
		z20_valor_cap		DECIMAL(12,2),
		z20_saldo_cap		DECIMAL(12,2),
		valor_ret		DECIMAL(12,2),
		cheq			CHAR(1),
		z20_num_doc		CHAR(15),
		z20_dividendo		SMALLINT,
		r38_num_sri		CHAR(21),
		z20_cod_tran		CHAR(2),
		z20_num_tran		DECIMAL(15,0),
		num_r_sri		CHAR(21),
		r38_tipo_fuente		CHAR(2),
		num_fuente		INTEGER
	)
IF rm_par.rezagadas = 'S' THEN
	CALL fecha_ultima() RETURNING fec_ult
	--LET dias_tope = (TODAY - MDY(01, 01, YEAR(fec_ult))) + 1
	LET dias_tope = (vg_fecha - MDY(01, 01, YEAR(vg_fecha) - 1)) + 1
END IF
CASE rm_par.z20_areaneg
	WHEN 1
		LET tipo_f   = 'PR'
		LET expr_sub = '   AND NOT EXISTS ',
 				'(SELECT 1 FROM ', retorna_base_loc() CLIPPED,
						'rept019 a ',
				'WHERE a.r19_compania   = z20_compania ',
				'  AND a.r19_localidad  = z20_localidad ',
				'  AND a.r19_cod_tran   = z20_cod_tran ',
				'  AND a.r19_num_tran   = z20_num_tran ',
				'  AND a.r19_tot_bruto <= ',
					' (SELECT SUM(r19_tot_bruto) ',
					'FROM ', retorna_base_loc() CLIPPED,
						'rept019 b ',
					'WHERE b.r19_compania = a.r19_compania',
					'  AND b.r19_localidad=a.r19_localidad',
					'  AND b.r19_cod_tran  IN ("DF", "AF")',
					'  AND b.r19_tipo_dev= a.r19_cod_tran ',
					'  AND b.r19_num_dev = a.r19_num_tran))'
	WHEN 2
		LET tipo_f   = 'OT'
		LET expr_sub = '   AND EXISTS ',
				'(SELECT 1 FROM talt023 ',
				'WHERE t23_compania    = z20_compania ',
				'  AND t23_localidad   = z20_localidad ',
				'  AND t23_num_factura = z20_num_tran ',
				'  AND NOT EXISTS ',
					'(SELECT 1 FROM talt028 ',
					'WHERE t28_compania  = t23_compania ',
					'  AND t28_localidad = t23_localidad ',
					'  AND t28_factura  = t23_num_factura))'
END CASE
IF rm_par.tipo_venta = 'R' OR rm_par.tipo_venta = 'T' THEN
	LET query = ' INSERT INTO tmp_det ',
		'SELECT z20_localidad, z20_tipo_doc, TRIM(z20_num_doc) ||',
		' "-" || LPAD(z20_dividendo, 2, 0) num_doc, z20_fecha_emi,',
		' z20_fecha_vcto, z20_valor_cap, z20_saldo_cap,',
		' 0.00 valor_ret, "N" cheq, z20_num_doc, z20_dividendo,',
		' r38_num_sri, z20_cod_tran, z20_num_tran,',
		' r38_num_sri num_r_sri, r38_tipo_fuente, "" ',
		' FROM cxct020, ', retorna_base_loc() CLIPPED, 'rept038 ',
		' WHERE z20_compania     = ', vg_codcia,
		'   AND z20_localidad    = ', vg_codloc,
		'   AND z20_codcli       = ', rm_par.z20_codcli,
		'   AND z20_areaneg      = ', rm_par.z20_areaneg,
		'   AND z20_moneda       = "', rm_par.z20_moneda, '"',
		'   AND z20_linea        = "', rm_par.z20_linea, '"',
		'   AND z20_saldo_cap    > 0 ',
		'   AND z20_dividendo    = 1 ',
		'   AND EXTEND(z20_fecha_emi, YEAR TO MONTH) >= ',
			'EXTEND(DATE("', vg_fecha, '" - ', dias_tope + 1, ' UNITS DAY), ',
				'YEAR TO MONTH) ',
		'   AND NOT EXISTS ',
			--'(SELECT 1 FROM ', retorna_base_loc() CLIPPED,
			'(SELECT 1 FROM cajt014 ',
				'WHERE j14_compania  = z20_compania ',
				'  AND j14_localidad = z20_localidad ',
				'  AND j14_tipo_fue  = "', tipo_f, '" ',
				'  AND j14_cod_tran  = z20_cod_tran ',
				'  AND j14_num_tran  = z20_num_tran)',
		expr_sub CLIPPED,
		'   AND r38_compania     = z20_compania ',
		'   AND r38_localidad    = z20_localidad ',
		'   AND r38_tipo_doc    IN ("FA", "NV") ',
		'   AND r38_tipo_fuente  = "', tipo_f, '" ',
		'   AND r38_cod_tran     = z20_cod_tran ',
		'   AND r38_num_tran     = z20_num_tran '
	PREPARE exec_tmp1 FROM query
	EXECUTE exec_tmp1
	LET query = ' INSERT INTO tmp_det ',
		'SELECT z20_localidad, z20_tipo_doc, TRIM(z20_num_doc) ||',
		' "-" || LPAD(z20_dividendo, 2, 0) num_doc, z20_fecha_emi,',
		' z20_fecha_vcto, z20_valor_cap, z20_saldo_cap,',
		' 0.00 valor_ret, "N" cheq, z20_num_doc, z20_dividendo,',
		' r38_num_sri, z20_cod_tran, z20_num_tran,',
		' r38_num_sri num_r_sri, r38_tipo_fuente, "" ',
		' FROM cxct020, ', retorna_base_loc() CLIPPED, 'rept038 ',
		' WHERE z20_compania     = ', vg_codcia,
		'   AND z20_localidad    = ', vg_codloc,
		'   AND z20_codcli       = ', rm_par.z20_codcli,
		'   AND z20_areaneg      = ', rm_par.z20_areaneg,
		'   AND z20_moneda       = "', rm_par.z20_moneda, '"',
		'   AND z20_linea        = "', rm_par.z20_linea, '"',
		'   AND z20_saldo_cap    = 0 ',
		'   AND z20_dividendo    = 1 ',
		'   AND EXTEND(z20_fecha_emi, YEAR TO MONTH) >= ',
			'EXTEND(DATE("', vg_fecha, '" - ', dias_tope + 1, ' UNITS DAY), ',
				'YEAR TO MONTH) ',
		'   AND NOT EXISTS ',
			--'(SELECT 1 FROM ', retorna_base_loc() CLIPPED,
			'(SELECT 1 FROM cajt014 ',
				'WHERE j14_compania  = z20_compania ',
				'  AND j14_localidad = z20_localidad ',
				'  AND j14_tipo_fue  = "', tipo_f, '" ',
				'  AND j14_cod_tran  = z20_cod_tran ',
				'  AND j14_num_tran  = z20_num_tran)',
		expr_sub CLIPPED,
		'   AND r38_compania     = z20_compania ',
		'   AND r38_localidad    = z20_localidad ',
		'   AND r38_tipo_doc    IN ("FA", "NV") ',
		'   AND r38_tipo_fuente  = "', tipo_f, '" ',
		'   AND r38_cod_tran     = z20_cod_tran ',
		'   AND r38_num_tran     = z20_num_tran '
	PREPARE exec_tmp2 FROM query
	EXECUTE exec_tmp2
	SELECT COUNT(*) INTO cuantos FROM tmp_det
	IF rm_par.tipo_venta = 'R' AND cuantos = 0 THEN
		ERROR ' ' ATTRIBUTE(NORMAL)
		CALL fl_mensaje_consulta_sin_registros()
		DROP TABLE tmp_det
		RETURN 0
	END IF
	IF rm_par.tipo_venta = 'R' THEN
		ERROR ' ' ATTRIBUTE(NORMAL)
		RETURN 1
	END IF
END IF
LET expr_sub = NULL
IF rm_par.z20_areaneg = 2 THEN
	LET expr_sub = '   AND EXISTS ',
			'(SELECT 1 FROM talt023 ',
			'WHERE t23_compania    = j10_compania ',
			'  AND t23_localidad   = j10_localidad ',
			'  AND t23_num_factura = j10_num_destino ',
			'  AND NOT EXISTS ',
				'(SELECT 1 FROM talt028 ',
				'WHERE t28_compania  = t23_compania ',
				'  AND t28_localidad = t23_localidad ',
				'  AND t28_factura  = t23_num_factura))'
END IF
LET query = 'INSERT INTO tmp_det ',
	'SELECT UNIQUE j10_localidad z20_localidad, "FA" z20_tipo_doc, ',
		'TRIM(j10_num_destino) || "-01" num_doc, ',
		'DATE(j10_fecha_pro) z20_fecha_emi, "", ',
		'j10_valor z20_valor_cap, 0.00, 0.00 valor_ret, ',
		'"N" cheq, j10_num_destino z20_num_doc, ',
		'1 z20_dividendo, r38_num_sri, j10_tipo_destino ',
		'z20_cod_tran, j10_num_destino z20_num_tran, ',
		'r38_num_sri num_r_sri, j10_tipo_fuente, ',
		'j10_num_fuente num_fuente ',
		' FROM cajt010, cajt011, rept038 ',
		' WHERE j10_compania        = ', vg_codcia,
		'   AND j10_localidad       = ', vg_codloc,
		'   AND j10_tipo_fuente     = "', tipo_f, '" ',
		'   AND j10_codcli          = ', rm_par.z20_codcli,
		'   AND j10_tipo_destino    = "', vm_cod_tran, '"',
		'   AND j10_estado          = "P" ',
		'   AND EXTEND(j10_fecha_pro, YEAR TO MONTH) >= ',
			'EXTEND(DATE("', vg_fecha, '" - ', dias_tope + 1, ' UNITS DAY), ',
				'YEAR TO MONTH) ',
		'   AND r38_compania        = j10_compania ',
		'   AND r38_localidad       = j10_localidad ',
		'   AND r38_tipo_doc       IN ("FA", "NV") ',
		'   AND r38_tipo_fuente     = j10_tipo_fuente ',
		'   AND r38_cod_tran        = j10_tipo_destino ',
		'   AND r38_num_tran        = j10_num_destino ',
		'   AND j11_compania        = j10_compania ',
		'   AND j11_localidad       = j10_localidad ',
		'   AND j11_tipo_fuente     = j10_tipo_fuente ',
		'   AND j11_num_fuente      = j10_num_fuente ',
		'   AND j11_codigo_pago    NOT IN ',
			'(SELECT j01_codigo_pago ',
			'FROM ', retorna_base_loc() CLIPPED, 'cajt001 ',
			'WHERE j01_compania  = j10_compania ',
			'  AND j01_retencion = "S") ',
		'   AND NOT EXISTS ',
			--'(SELECT 1 FROM ', retorna_base_loc() CLIPPED,
			'(SELECT 1 FROM cajt014 ',
				'WHERE j14_compania  = j10_compania ',
				'  AND j14_localidad = j10_localidad ',
				'  AND j14_tipo_fue  = "', tipo_f, '" ',
				'  AND j14_cod_tran  = j10_tipo_destino ',
				'  AND j14_num_tran  = j10_num_destino) ',
		expr_sub CLIPPED
PREPARE exec_tmp3 FROM query
EXECUTE exec_tmp3
LET dias_tope = rm_s00.s00_dias_ret
ERROR ' ' ATTRIBUTE(NORMAL)
SELECT COUNT(*) INTO cuantos FROM tmp_det
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_det
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION cargar_detalle()
DEFINE query		VARCHAR(200)

LET query = 'SELECT * FROM tmp_det ',
                ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
PREPARE cons_fac FROM query
DECLARE q_fact_c CURSOR FOR cons_fac
LET vm_num_rows = 1
FOREACH q_fact_c INTO rm_detalle[vm_num_rows].*, rm_adi[vm_num_rows].*
	LET vm_num_rows = vm_num_rows + 1
	IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
CALL calcular_total()

END FUNCTION



FUNCTION control_detalle()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE num_f		LIKE cajt010.j10_num_fuente
DEFINE val_ret		LIKE cajt014.j14_valor_ret
DEFINE i, j, col	SMALLINT
DEFINE salir, ordenar	SMALLINT
DEFINE resp		CHAR(6)
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE total_ret	DECIMAL(12,2)
DEFINE total_ef		DECIMAL(12,2)

OPTIONS 
	INSERT KEY F30,
	DELETE KEY F31
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 4
LET vm_columna_1           = col
LET vm_columna_2           = 2
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
LET salir                  = 0
WHILE NOT salir
	CALL cargar_detalle()
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, vm_num_rows)
	END IF
	LET ordenar  = 0
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
		ON KEY(INTERRUPT)
        		LET int_flag = 0
	                CALL fl_mensaje_abandonar_proceso() RETURNING resp
        	        IF resp = 'Yes' THEN
				LET salir    = 1
                		LET int_flag = 1
                        	EXIT INPUT
	                END IF
	       	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1()
		ON KEY(F5)
			LET i = arr_curr()
			LET j = scr_line()
			CALL ver_documento(i)
			ERROR '    Valor Original: ', 
			        valor_bruto USING '#,###,###,##&.##',
				'    No. SRI ', rm_adi[i].num_sri
			LET int_flag = 0
		ON KEY(F6)
			LET i = arr_curr()
			LET j = scr_line()
			CALL detalle_retenciones(i, j)
			LET val_ret = rm_detalle[i].valor_ret
			ERROR '    Valor Original: ', 
			        valor_bruto USING '#,###,###,##&.##',
				'    No. SRI ', rm_adi[i].num_sri
			LET int_flag = 0
		ON KEY(F7)
			LET i = arr_curr()
			LET j = scr_line()
			IF rm_detalle[i].z20_tipo_doc = 'FA' THEN
				IF vg_codloc = 2 OR vg_codloc = 4 OR
				   vg_codloc = 5
				THEN
					CALL fl_ver_transaccion_rep(vg_codcia,
							vg_codloc,
							rm_adi[i].z20_cod_tran,
							rm_adi[i].z20_num_tran)
				ELSE
					CALL retorna_num_fue(i) RETURNING num_f
					CALL retorna_ret_fac(i)
						RETURNING tipo_f, cod_tr,
								num_tr, num_s
				CALL fl_ver_comprobantes_emitidos_caja(tipo_f,
						num_f, rm_adi[i].z20_cod_tran,
						rm_adi[i].z20_num_tran,
						rm_par.z20_codcli)
				END IF
				ERROR '    Valor Original: ', 
			        	valor_bruto USING '#,###,###,##&.##',
					'    No. SRI ', rm_adi[i].num_sri
				LET int_flag = 0
			END IF
		ON KEY(F15)
			LET col     = 1
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F16)
			LET col     = 2
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F17)
			LET col     = 3
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F18)
			LET col     = 4
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F19)
			LET col     = 5
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F20)
			LET col     = 6
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F21)
			LET col     = 7
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F22)
			LET col     = 8
			LET ordenar = 1
			EXIT INPUT
		ON KEY(F23)
			LET col     = 9
			LET ordenar = 1
			EXIT INPUT
		--#BEFORE INPUT
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			LET salir   = 0
			LET ordenar = 0
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			CALL muestra_contadores_det(i, vm_num_rows)
			CASE rm_par.z20_areaneg
				WHEN 1
					CALL lee_factura_inv(vg_codcia,
							vg_codloc,
							rm_adi[i].z20_cod_tran,
							rm_adi[i].z20_num_tran)
						RETURNING r_r19.*
					LET valor_bruto = r_r19.r19_tot_bruto
							- r_r19.r19_tot_dscto
				WHEN 2
					CALL fl_lee_factura_taller(vg_codcia,
							vg_codloc,
							rm_adi[i].z20_num_tran)
						RETURNING r_t23.*
					LET valor_bruto = r_t23.t23_tot_bruto
							- r_t23.t23_vde_mo_tal
			END CASE
			ERROR '    Valor Original: ', 
			        valor_bruto USING '#,###,###,##&.##',
				'    No. SRI ', rm_adi[i].num_sri
		BEFORE FIELD valor_ret
			IF NOT FIELD_TOUCHED(valor_ret) THEN
				LET val_ret = rm_detalle[i].valor_ret
			END IF
		AFTER FIELD valor_ret
			IF FIELD_TOUCHED(valor_ret) THEN
				LET rm_detalle[i].valor_ret = val_ret
				DISPLAY rm_detalle[i].valor_ret TO
					rm_detalle[j].valor_ret
			END IF
		AFTER FIELD chequear
			IF FIELD_TOUCHED(chequear) OR
			   FIELD_TOUCHED(valor_ret) THEN
				IF rm_detalle[i].chequear = 'S' THEN
					CALL detalle_retenciones(i, j)
				ELSE
					CALL eliminar_retencion(i, j)
				END IF
			END IF
		AFTER INPUT
			--IF vg_codloc < 3 OR vg_codloc > 5 THEN
			IF rm_par.devuelve = 'S' THEN
				SELECT NVL(SUM(valor_ret), 0) INTO total_ret
				FROM tmp_ret
				WHERE num_ret_sri IN
					(SELECT num_r_sri
					FROM tmp_det
					WHERE r38_num_sri   = num_fac_sri
					  AND z20_cod_tran  = cod_tr
					  AND z20_num_tran  = num_tr
					  AND z20_saldo_cap = 0)
				SELECT NVL(j05_ef_apertura, 0) INTO total_ef
				FROM cajt005
				WHERE j05_compania    = rm_j04.j04_compania
				  AND j05_localidad   = rm_j04.j04_localidad
				  AND j05_codigo_caja = rm_j04.j04_codigo_caja
				  AND j05_fecha_aper  = rm_j04.j04_fecha_aper
				  AND j05_secuencia   = rm_j04.j04_secuencia
				  AND j05_moneda      = rm_par.z20_moneda
				IF total_ret > total_ef THEN
					CALL fl_mostrar_mensaje('El total a devolver al cliente es mayor al efectivo que existe en esta caja.', 'exclamation')
					CONTINUE INPUT
				END IF
			END IF
			LET salir = 1
	END INPUT
	IF NOT salir AND NOT ordenar THEN
		CONTINUE WHILE
	END IF
	IF int_flag THEN
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



FUNCTION calcular_total()
DEFINE tot_val, tot_ret	DECIMAL(14,2)
DEFINE tot_sal		DECIMAL(14,2)
DEFINE i		SMALLINT

LET tot_val = 0
LET tot_ret = 0
LET tot_sal = 0
FOR i = 1 TO vm_num_rows
	LET tot_val = tot_val + rm_detalle[i].z20_valor_cap
	LET tot_ret = tot_ret + rm_detalle[i].valor_ret
	LET tot_sal = tot_sal + rm_detalle[i].z20_saldo_cap
END FOR
DISPLAY BY NAME tot_val, tot_ret, tot_sal

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION calcula_paridad(moneda_ori, moneda_dest)
DEFINE moneda_ori	LIKE veht036.v36_moneda
DEFINE moneda_dest	LIKE veht036.v36_moneda
DEFINE paridad		LIKE veht036.v36_paridad_mb
DEFINE r_g14		RECORD LIKE gent014.*

IF moneda_ori = moneda_dest THEN
	LET paridad = 1 
ELSE
	CALL fl_lee_factor_moneda(moneda_ori, moneda_dest) RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('No existe factor de conversiÃ³n para esta moneda.','exclamation')
		LET paridad = NULL
	ELSE
		LET paridad = r_g14.g14_tasa
	END IF
END IF
RETURN paridad

END FUNCTION



FUNCTION ver_documento(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
IF rm_detalle[i].z20_fecha_vcto IS NOT NULL THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
			vg_separador, 'fuentes', vg_separador, run_prog,
			'cxcp200 ', vg_base, ' ', vg_modulo, ' ', vg_codcia,
			' ', vg_codloc, ' ', rm_par.z20_codcli, ' "',
			rm_detalle[i].z20_tipo_doc, '" ', rm_adi[i].z20_num_doc,
			' ', rm_adi[i].z20_dividendo
ELSE
	LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CAJA',
			vg_separador, 'fuentes', vg_separador, run_prog,
			'cajp203 ', vg_base, ' CG ', vg_codcia,' ',
			rm_detalle[i].z20_localidad, ' "', rm_adi[i].tipo_f,
			'" ', rm_adi[i].num_f
END IF
RUN comando

END FUNCTION



FUNCTION eliminar_retencion(i, j)
DEFINE i, j		SMALLINT

LET rm_detalle[i].valor_ret = 0
LET rm_detalle[i].chequear  = 'N'
CALL borrar_retencion(rm_adi[i].num_ret_sri, i)
LET rm_adi[i].num_ret_sri   = NULL
INITIALIZE rm_j14.j14_num_ret_sri, tot_valor_ret TO NULL
LET vm_num_ret = 0
CALL actualizar_det_ret(i)
DISPLAY rm_detalle[i].valor_ret TO rm_detalle[j].valor_ret
DISPLAY rm_detalle[i].chequear  TO rm_detalle[j].chequear
CALL calcular_total()

END FUNCTION



FUNCTION detalle_retenciones(i, j)
DEFINE i, j		SMALLINT
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_s21		RECORD LIKE srit021.*
DEFINE cont_cred	LIKE cajt001.j01_cont_cred

IF rm_detalle[i].z20_saldo_cap = 0 AND rm_par.devuelve = 'S' THEN
	LET cont_cred = "R"
	IF rm_par.tipo_venta <> 'T' THEN
		LET cont_cred = rm_par.tipo_venta
	END IF
	CALL fl_lee_tipo_pago_caja(vg_codcia, "RR", cont_cred) RETURNING r_j01.*
	IF (r_j01.j01_aux_cont IS NULL) AND (vg_codloc <> 2 AND vg_codloc <> 4)
	THEN
		CALL fl_mostrar_mensaje('No existe configurado el auxiliar contable para retenciones que se van a cargar a facturas sin saldos.', 'exclamation')
		RETURN
	END IF
END IF
IF rm_par.rezagadas = 'N' THEN
	INITIALIZE r_s21.* TO NULL
	DECLARE q_s21 CURSOR FOR
		SELECT * FROM srit021
			WHERE s21_compania  = vg_codcia
			  AND s21_localidad = vg_codloc
			  AND s21_anio     = YEAR(rm_detalle[i].z20_fecha_emi)
			  AND s21_mes      = MONTH(rm_detalle[i].z20_fecha_emi)
	OPEN q_s21
	FETCH q_s21 INTO r_s21.*
	CLOSE q_s21
	FREE q_s21
	IF r_s21.s21_compania IS NOT NULL THEN
		IF r_s21.s21_estado = 'C' OR r_s21.s21_estado = 'D' THEN
			CALL fl_mostrar_mensaje('No puede digitar retenciones de esta fecha porque el anexo de ventas ya no esta en proceso.', 'exclamation')
			RETURN
		END IF
	END IF
END IF
CALL control_retenciones(i) RETURNING rm_detalle[i].valor_ret
IF rm_detalle[i].valor_ret IS NULL THEN
	LET rm_detalle[i].valor_ret = 0
	LET rm_detalle[i].chequear  = 'N'
END IF
IF rm_detalle[i].valor_ret > 0 THEN
	LET rm_detalle[i].chequear  = 'S'
END IF
LET rm_adi[i].num_ret_sri = rm_j14.j14_num_ret_sri
DISPLAY rm_detalle[i].valor_ret TO rm_detalle[j].valor_ret
DISPLAY rm_detalle[i].chequear  TO rm_detalle[j].chequear
CALL actualizar_det_ret(i)
CALL calcular_total()

END FUNCTION



FUNCTION actualizar_det_ret(i)
DEFINE i		SMALLINT

UPDATE tmp_det
	SET valor_ret = rm_detalle[i].valor_ret,
	    cheq      = rm_detalle[i].chequear,
	    num_r_sri = rm_j14.j14_num_ret_sri
	WHERE z20_localidad = vg_codloc
	  AND z20_tipo_doc  = rm_detalle[i].z20_tipo_doc
	  AND z20_num_doc   = rm_adi[i].z20_num_doc
	  AND z20_dividendo = rm_adi[i].z20_dividendo

END FUNCTION



FUNCTION control_retenciones(i)
DEFINE i		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE j10_tipo_destino	LIKE cajt010.j10_tipo_destino
DEFINE j10_num_destino	LIKE cajt010.j10_num_destino
DEFINE row_ini, col_ini	SMALLINT
DEFINE row_fin, col_fin	SMALLINT
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE valor_impto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE flete		DECIMAL(14,2)
DEFINE valor_fact	DECIMAL(14,2)

LET row_ini = 04
LET row_fin = 20
LET col_ini = 02
LET col_fin = 78
IF vg_gui = 0 THEN
	LET row_ini = 05
	LET row_fin = 18
	LET col_ini = 03
	LET col_fin = 77
END IF
OPEN WINDOW w_cxcf211_2 AT row_ini, col_ini WITH row_fin ROWS, col_fin COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_cxcf211_2 FROM '../forms/cxcf211_2'
ELSE
	OPEN FORM f_cxcf211_2 FROM '../forms/cxcf211_2c'
END IF
DISPLAY FORM f_cxcf211_2
LET vm_num_ret = 0
LET vm_max_ret = 50
CALL borrar_retenciones()
--#DISPLAY 'TP'		 TO tit_col1
--#DISPLAY 'T'		 TO tit_col2
--#DISPLAY '%'		 TO tit_col3
--#DISPLAY 'Cod. SRI' 	 TO tit_col4
--#DISPLAY 'Descripcion' TO tit_col5
--#DISPLAY 'Base Imp.'	 TO tit_col6
--#DISPLAY 'Valor Ret.'	 TO tit_col7
DISPLAY BY NAME rm_adi[i].num_sri
LET j10_tipo_destino = rm_adi[i].z20_cod_tran
LET j10_num_destino  = rm_adi[i].z20_num_tran
CASE rm_par.z20_areaneg
	WHEN 1
		CALL lee_factura_inv(vg_codcia, vg_codloc,
				rm_adi[i].z20_cod_tran, rm_adi[i].z20_num_tran)
			RETURNING r_r19.*
		LET valor_bruto = r_r19.r19_tot_bruto - r_r19.r19_tot_dscto
		LET valor_impto = r_r19.r19_tot_neto  - r_r19.r19_tot_bruto +
					r_r19.r19_tot_dscto - r_r19.r19_flete
		LET subtotal    = valor_bruto + valor_impto
		LET flete       = r_r19.r19_flete
		LET valor_fact  = subtotal + flete
	WHEN 2
		CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
						rm_adi[i].z20_num_tran)
			RETURNING r_t23.*
		--LET valor_bruto = r_t23.t23_tot_bruto - r_t23.t23_tot_dscto
		LET valor_bruto = r_t23.t23_tot_bruto - r_t23.t23_vde_mo_tal
		LET valor_impto = r_t23.t23_val_impto
		LET subtotal    = valor_bruto + valor_impto
		LET flete       = NULL
		LET valor_fact  = subtotal
END CASE
DISPLAY rm_par.z20_codcli TO j10_codcli
DISPLAY rm_par.z01_nomcli TO j10_nomcli
DISPLAY BY NAME valor_bruto, valor_impto, subtotal, flete, valor_fact,
		j10_tipo_destino, j10_num_destino
CALL ingreso_retenciones(i)
LET int_flag = 0
CLOSE WINDOW w_cxcf211_2
RETURN tot_valor_ret

END FUNCTION



FUNCTION ingreso_retenciones(i)
DEFINE i		SMALLINT
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut

LET numero_ret = rm_adi[i].num_ret_sri
CALL cargar_retenciones(numero_ret, i)
CALL lee_retenciones(numero_ret, i)
IF int_flag THEN
	IF registros_retenciones(rm_j14.j14_num_ret_sri, i) = 0 THEN
		INITIALIZE rm_j14.j14_num_ret_sri, tot_valor_ret TO NULL
		LET vm_num_ret = 0
	END IF
ELSE
	CALL borrar_retencion(numero_ret, i)
	FOR i = 1 TO vm_num_ret
		INSERT INTO tmp_ret
			VALUES(rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
				rm_j14.j14_fecha_emi, rm_detret[i].*,
				rm_adi_r[i].*, NULL, fec_ini_por[i])
	END FOR
END IF

END FUNCTION



FUNCTION borrar_retenciones()
DEFINE i		SMALLINT

INITIALIZE rm_j14.* TO NULL
FOR i = 1 TO fgl_scr_size('rm_detret')
	CLEAR rm_detret[i].*
END FOR
FOR i = 1 TO vm_max_ret
	INITIALIZE rm_detret[i].* TO NULL
END FOR
CLEAR j14_num_ret_sri, j14_autorizacion, j14_fecha_emi, num_row, max_row,
	tot_base_imp, tot_valor_ret, j10_codcli, j10_nomcli, valor_bruto,
	valor_impto, subtotal, flete, --j10_tipo_fuente, j10_num_fuente,
	j10_tipo_destino, j10_num_destino, num_sri, concepto_ret

END FUNCTION



FUNCTION cargar_retenciones(numero_ret, i)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE i		SMALLINT
DEFINE tipo_fue		LIKE ordt002.c02_tipo_fuente
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE num_f		LIKE cajt010.j10_num_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE tip_d		LIKE rept038.r38_tipo_doc
DEFINE cod_pag		LIKE cajt091.j91_codigo_pago
DEFINE query		CHAR(8000)
DEFINE expr_sql		VARCHAR(100)
DEFINE expr_tip		VARCHAR(150)
DEFINE expr_par		VARCHAR(200)
DEFINE l, lim, ctos	INTEGER

CALL retorna_num_fue(i) RETURNING num_f
CALL retorna_ret_fac(i) RETURNING tipo_f, cod_tr, num_tr, num_s
IF registros_retenciones(numero_ret, i) = 0 THEN
	LET cod_pag  = "RT"
	LET expr_par = '   AND z08_defecto        = "S" '
	SELECT COUNT(*)
		INTO ctos
		FROM gent010
		WHERE g10_compania = vg_codcia
		  AND g10_codcobr  = rm_par.z20_codcli
		  AND g10_estado   = "A"
	IF ctos > 0 THEN
		LET cod_pag  = "RJ"
		LET expr_par = '   AND z08_defecto        = "N" ',
				'   AND z08_flete          = "N" '
	END IF
	CASE tipo_f
		WHEN "PR" LET tipo_fue = 'B'
		WHEN "OT" LET tipo_fue = 'S'
	END CASE
	CALL retorna_tipo_doc(i, tipo_f) RETURNING tip_d
	LET expr_tip = ', "', tip_d,'" tip_doc, z08_fecha_ini_porc fec_ini_porc'
	LET query = 'SELECT "", "", "", j91_codigo_pago, ',
			' CASE WHEN ("', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B") OR',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T") OR "RJ" = "',
						cod_pag CLIPPED, '"',
				'THEN z08_tipo_ret ',
			' END, ',
			' CASE WHEN ("', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B") OR',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0) OR ',
				' ("', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T") OR "RJ" = "',
						cod_pag CLIPPED, '"',
				'THEN z08_porcentaje ',
			' END, ',
			' z08_codigo_sri, c03_concepto_ret, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" OR "RJ" = "',
						cod_pag CLIPPED, '" THEN',
			' (SELECT r23_tot_bruto - r23_tot_dscto ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', vg_codloc,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'OR "RJ" = "', cod_pag CLIPPED, '" THEN',
			' (SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'OR "RJ" = "', cod_pag CLIPPED, '" THEN',
			' (SELECT t23_val_mo_tal - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T" ',
				'OR "RJ" = "', cod_pag CLIPPED, '" THEN',
			' (SELECT t23_tot_bruto - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			--' ELSE 0 ',
			' END, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" ',
				'OR "RJ" = "', cod_pag CLIPPED, '" THEN',
			' (SELECT r23_tot_bruto - r23_tot_dscto ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', vg_codloc,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "B" AND ',
				'(SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'OR "RJ" = "', cod_pag CLIPPED, '" THEN',
			' (SELECT t23_val_mo_cti ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "S" AND ',
				'(SELECT t23_val_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f, ') > 0 ',
				'OR "RJ" = "', cod_pag CLIPPED, '" THEN',
			' (SELECT t23_val_mo_tal - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" AND ',
					'c03_tipo_fuente = "T" ',
				'OR "RJ" = "', cod_pag CLIPPED, '" THEN',
			' (SELECT t23_tot_bruto - t23_vde_mo_tal ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			--' ELSE 0 ',
			' END * (c02_porcentaje / 100),',
			' "', tipo_f, '" tipo_f, "', cod_tr, '" cod_tr, "',
			num_tr, '" num_tr, "', num_s, '" num_sri ',
			expr_tip CLIPPED,
			' FROM cxct008, ordt003, ordt002, cajt091 ',
			' WHERE z08_compania       = ', vg_codcia,
			'   AND z08_codcli         = ', rm_par.z20_codcli,
			expr_par CLIPPED,
			'   AND c03_compania       = z08_compania ',
			'   AND c03_tipo_ret       = z08_tipo_ret ',
			'   AND c03_porcentaje     = z08_porcentaje ',
			'   AND c03_codigo_sri     = z08_codigo_sri ',
			'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
			'   AND c03_estado         = "A" ',
			'   AND c02_compania       = c03_compania ',
			'   AND c02_tipo_ret       = c03_tipo_ret ',
			'   AND c02_porcentaje     = c03_porcentaje ',
			'   AND c02_estado         = "A" ',
			'   AND j91_compania       = c02_compania ',
			'   AND j91_codigo_pago    = "', cod_pag CLIPPED, '"',
			'   AND j91_cont_cred      = "R" ',
			'   AND j91_tipo_ret       = c02_tipo_ret ',
			'   AND j91_porcentaje     = c02_porcentaje ',
		' UNION ',
		' SELECT "", "", "", j91_codigo_pago, z08_tipo_ret,',
			' z08_porcentaje, c03_codigo_sri, c03_concepto_ret,',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', vg_codloc,
				'  AND r23_numprev   = ', num_f,
				')',
			' ELSE 0 ',
			' END, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', vg_codloc,
				'  AND r23_numprev   = ', num_f,
				')',
			' ELSE 0 ',
			' END * (c02_porcentaje / 100),',
			' "', tipo_f, '" tipo_f, "', cod_tr, '" cod_tr, "',
			num_tr, '" num_tr, "', num_s, '" num_sri ',
			expr_tip CLIPPED,
			' FROM cxct008, ordt003, ordt002, cajt091 ',
			' WHERE z08_compania       = ', vg_codcia,
			'   AND z08_codcli         = ', rm_par.z20_codcli,
			'   AND z08_flete          = "S" ',
			'   AND c03_compania       = z08_compania ',
			'   AND c03_tipo_ret       = z08_tipo_ret ',
			'   AND c03_porcentaje     = z08_porcentaje ',
			'   AND c03_codigo_sri     = z08_codigo_sri ',
			'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
			'   AND c03_estado         = "A" ',
			'   AND c02_compania       = c03_compania ',
			'   AND c02_tipo_ret       = c03_tipo_ret ',
			'   AND c02_porcentaje     = c03_porcentaje ',
			'   AND c02_estado         = "A" ',
			'   AND j91_compania       = c02_compania ',
			'   AND j91_codigo_pago    = "', cod_pag CLIPPED, '"',
			'   AND j91_cont_cred      = "R" ',
			'   AND j91_tipo_ret       = c02_tipo_ret ',
			'   AND j91_porcentaje     = c02_porcentaje ',
			'   AND EXISTS (SELECT 1 FROM ',
					retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', vg_codloc,
				'  AND r23_numprev   = ', num_f,
				'  AND r23_flete     > 0) ',
		' UNION ',
		' SELECT "", "", "", j91_codigo_pago, z08_tipo_ret,',
			' z08_porcentaje, c03_codigo_sri, c03_concepto_ret,',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_tot_neto - r23_tot_bruto + ',
					'r23_tot_dscto - r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', vg_codloc,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" THEN',
			' (SELECT t23_val_impto ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			' ELSE 0 ',
			' END, ',
			' CASE WHEN "', tipo_f, '" = "PR" AND ',
					'c03_tipo_fuente = "B" THEN',
			' (SELECT r23_tot_neto - r23_tot_bruto + ',
					'r23_tot_dscto - r23_flete ',
				'FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
				'WHERE r23_compania  = z08_compania ',
				'  AND r23_localidad = ', vg_codloc,
				'  AND r23_numprev   = ', num_f,
				')',
			'      WHEN "', tipo_f, '" = "OT" THEN',
			' (SELECT t23_val_impto ',
				'FROM talt023 ',
				'WHERE t23_compania  = z08_compania ',
				'  AND t23_localidad = ', vg_codloc,
				'  AND t23_orden     = ', num_f,
				')',
			' ELSE 0 ',
			' END * (c02_porcentaje / 100),',
			' "', tipo_f, '" tipo_f, "', cod_tr, '" cod_tr, "',
			num_tr, '" num_tr, "', num_s, '" num_sri ',
			expr_tip CLIPPED,
			' FROM cxct008, ordt003, ordt002, cajt091 ',
			' WHERE z08_compania       = ', vg_codcia,
			'   AND z08_codcli         = ', rm_par.z20_codcli,
			'   AND z08_tipo_ret       = "I" ',
			'   AND c03_compania       = z08_compania ',
			'   AND c03_tipo_ret       = z08_tipo_ret ',
			'   AND c03_porcentaje     = z08_porcentaje ',
			'   AND c03_codigo_sri     = z08_codigo_sri ',
			'   AND c03_fecha_ini_porc = z08_fecha_ini_porc ',
			'   AND c03_estado         = "A" ',
			'   AND c02_compania       = c03_compania ',
			'   AND c02_tipo_ret       = c03_tipo_ret ',
			'   AND c02_porcentaje     = c03_porcentaje ',
			'   AND c02_estado         = "A" ',
			'   AND c02_tipo_fuente    = "', tipo_fue, '"',
			'   AND j91_compania       = c02_compania ',
			'   AND j91_codigo_pago    = "', cod_pag CLIPPED, '"',
			'   AND j91_cont_cred      = "R" ',
			'   AND j91_tipo_ret       = c02_tipo_ret ',
			'   AND j91_porcentaje     = c02_porcentaje '
ELSE
	LET expr_sql = NULL
	IF numero_ret IS NOT NULL THEN
		LET expr_sql = '   AND num_ret_sri = "', numero_ret CLIPPED, '"'
	END IF
	LET query = 'SELECT num_ret_sri, autorizacion, fecha_emi, cod_pago,',
			' tipo_ret, porc_ret, codigo_sri, concepto_ret,',
			' base_imp, valor_ret, tipo_fuente, cod_tr, num_tr,',
			' num_fac_sri, tipo_doc, fec_ini_porc ',
			' FROM tmp_ret ',
			' WHERE tipo_fuente = "', tipo_f, '"',
			expr_sql CLIPPED,
			'   AND cod_tr      = "', cod_tr, '"',
			'   AND num_tr      = "', num_tr, '"'
END IF
PREPARE cons_ret FROM query
DECLARE q_cons_ret CURSOR FOR cons_ret
LET vm_num_ret = 1
FOREACH q_cons_ret INTO rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
			rm_j14.j14_fecha_emi, rm_detret[vm_num_ret].*,
			rm_adi_r[vm_num_ret].*, fec_ini_por[vm_num_ret]
	IF rm_detret[vm_num_ret].j14_tipo_ret IS NULL THEN
		CONTINUE FOREACH
	END IF
	IF registros_retenciones(numero_ret, i) = 0 THEN
		IF LENGTH(rm_detret[vm_num_ret].j14_codigo_sri) < 2 THEN
			INITIALIZE rm_j14.* TO NULL
			LET rm_detret[vm_num_ret].j14_codigo_sri   = NULL
			LET rm_detret[vm_num_ret].c03_concepto_ret = NULL
		END IF
	END IF
	IF LENGTH(rm_j14.j14_num_ret_sri) < 14 THEN
		LET rm_j14.j14_num_ret_sri = NULL
	END IF
	LET vm_num_ret = vm_num_ret + 1
	IF vm_num_ret > vm_max_ret THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_ret = vm_num_ret - 1
IF vm_num_ret = 0 THEN
	RETURN
END IF
IF rm_j14.j14_num_ret_sri IS NULL THEN
	RETURN
END IF
LET lim = vm_num_ret
IF lim > fgl_scr_size('rm_detret') THEN
	LET lim = fgl_scr_size('rm_detret')
END IF
FOR l = 1 TO lim
	DISPLAY rm_detret[l].* TO rm_detret[l].*
END FOR
CALL calcular_tot_retencion(lim)

END FUNCTION



FUNCTION lee_retenciones(numero_ret, i)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE i		SMALLINT
DEFINE salir		SMALLINT

LET salir = 0
WHILE NOT salir
	CALL lee_cabecera_ret(numero_ret, i)
	IF int_flag THEN
		OPTIONS INPUT WRAP
		EXIT WHILE
	END IF
	OPTIONS INPUT WRAP
	CALL lee_detalle_ret(i) RETURNING salir
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_cabecera_ret(numero_ret, i)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE i		SMALLINT
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE codloc		LIKE cajt014.j14_localidad
DEFINE resp		CHAR(6)
DEFINE fecha, fecha2	DATE
DEFINE fecha_min	DATE
DEFINE fecha_tope	DATE
DEFINE fin_mes, fec_ult	DATE
DEFINE fec_pro		DATE
DEFINE mensaje		VARCHAR(200)
DEFINE cambi		SMALLINT

OPTIONS INPUT NO WRAP
IF rm_j14.j14_fecha_emi IS NULL THEN
	LET rm_j14.j14_fecha_emi = vg_fecha
END IF
LET int_flag = 0
INPUT BY NAME rm_j14.j14_num_ret_sri, rm_j14.j14_autorizacion,
	rm_j14.j14_fecha_emi
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(j14_num_ret_sri, j14_autorizacion,
					j14_fecha_emi)
		THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD j14_autorizacion
		IF rm_j14.j14_autorizacion IS NULL THEN
			DECLARE q_aut CURSOR FOR
				SELECT autorizacion
					FROM tmp_ret
			OPEN q_aut
			FETCH q_aut INTO rm_j14.j14_autorizacion
			DISPLAY BY NAME rm_j14.j14_autorizacion
			CLOSE q_aut
			FREE q_aut
		END IF
	BEFORE FIELD j14_fecha_emi
		LET fecha = NULL
		DECLARE q_fec CURSOR FOR
			SELECT fecha_emi
				FROM tmp_ret
				WHERE num_ret_sri = rm_j14.j14_num_ret_sri
		OPEN q_fec
		FETCH q_fec INTO fecha
		IF fecha IS NULL THEN
			LET cambi = 1
			LET fecha = rm_j14.j14_fecha_emi
		ELSE
			LET cambi = 0
			LET rm_j14.j14_fecha_emi = fecha
		END IF
		DISPLAY BY NAME rm_j14.j14_fecha_emi
		CLOSE q_fec
		FREE q_fec
	AFTER FIELD j14_num_ret_sri
		IF NOT valido_num_ret(rm_j14.j14_num_ret_sri) THEN
			NEXT FIELD j14_num_ret_sri
		END IF
		CALL lee_num_retencion(i) RETURNING r_j14.*
		IF r_j14.j14_num_ret_sri IS NOT NULL THEN
			IF r_j14.j14_num_ret_sri = rm_j14.j14_num_ret_sri AND
			   (r_j14.j14_num_ret_sri <> numero_ret OR
			    numero_ret IS NULL)
			THEN
				CALL fl_mostrar_mensaje('Este numero de retencion ya ha sido ingresado.', 'exclamation')
				NEXT FIELD j14_num_ret_sri
			END IF
		END IF
	AFTER FIELD j14_autorizacion
		IF LENGTH(rm_j14.j14_autorizacion) <> 10 THEN
			CALL fl_mostrar_mensaje('El numero de la autorizacion ingresado es incorrecto.', 'exclamation')
			NEXT FIELD j14_autorizacion
		END IF
		{-- OJO
		IF rm_j14.j14_autorizacion[1, 1] <> '1' THEN
			CALL fl_mostrar_mensaje('Numero de Autorizacion es incorrecto.', 'exclamation')
			NEXT FIELD j14_autorizacion
		END IF
		--}
		IF NOT fl_valida_numeros(rm_j14.j14_autorizacion) THEN
			NEXT FIELD j14_autorizacion
		END IF
	AFTER FIELD j14_fecha_emi
		IF rm_j14.j14_fecha_emi IS NULL THEN
			LET rm_j14.j14_fecha_emi = fecha
			DISPLAY BY NAME rm_j14.j14_fecha_emi
		END IF
		IF NOT cambi THEN
			LET rm_j14.j14_fecha_emi = fecha
			DISPLAY BY NAME rm_j14.j14_fecha_emi
			CONTINUE INPUT
		END IF
		LET fecha_min  = DATE(rm_detalle[i].z20_fecha_emi)
		LET fin_mes    = MDY(MONTH(fecha_min), 01, YEAR(fecha_min))
				+ 1 UNITS MONTH - 1 UNITS DAY
		LET fecha_tope = fin_mes + (dias_tope + 1) UNITS DAY
		IF rm_j14.j14_fecha_emi > vg_fecha THEN
			CALL fl_mostrar_mensaje('La fecha de retencion no puede ser mayor a la fecha de hoy.', 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		LET fec_ult = NULL
		--IF fin_mes < (TODAY - (dias_tope + 1) UNITS DAY) THEN
			CALL fecha_ultima() RETURNING fec_ult
			IF (YEAR(fec_ult) <> YEAR(rm_j14.j14_fecha_emi) AND
			    YEAR(vg_fecha) <> YEAR(rm_j14.j14_fecha_emi))
			THEN
				{--
				LET mensaje = 'No se puede cargar retenciones ',
						'a una factura con fecha de ',
						'mas de ',
						dias_tope + 1 USING "<<&",
						' dias, ó con una fecha de un ',
				--}
				LET mensaje = 'No se puede cargar retenciones ',
						'a una factura de un año ',
						'que esta CERRADO o DECLARADO.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				NEXT FIELD j14_fecha_emi
			END IF
			LET fecha_tope = fec_ult - 1 UNITS DAY
		--END IF
		{--
		IF (EXTEND(fec_ult - 1 UNITS DAY, YEAR TO MONTH) = 
		    EXTEND(rm_j14.j14_fecha_emi, YEAR TO MONTH))
		THEN
			LET mensaje = 'No se puede cargar retenciones ',
					'a una factura de este mes ',
					'porque esta CERRADO o DECLARADO en ',
					'el módulo del SRI.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		--}
		IF rm_j14.j14_fecha_emi < fecha_min THEN
			LET mensaje = 'La fecha de emision del comprobante no',
					' puede ser menor que la fecha de',
					' factura (',
					fecha_min USING "dd-mm-yyyy", ').'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		{--
		IF rm_j14.j14_fecha_emi > fecha_tope THEN
			LET mensaje = 'La fecha de emision del comprobante no',
					' puede ser mayor a ',
					dias_tope + 1 USING "<<&",
					' dias que la ',
					'fecha fin de mes de factura (',
					fin_mes USING "dd-mm-yyyy", ').'
				LET mensaje = 'No se puede cargar retenciones ',
						'a una factura de un año ',
						'que esta CERRADO o DECLARADO.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		--}
		LET fecha2 = rm_j14.j14_fecha_emi
		IF YEAR(vg_fecha) <> YEAR(rm_j14.j14_fecha_emi) THEN
			LET fecha2 = fec_ult
			IF fecha2 IS NULL THEN
				LET fecha2 = rm_j14.j14_fecha_emi
			END IF
		END IF
		IF fecha2 <= rm_b00.b00_fecha_cm THEN
			CALL fl_mostrar_mensaje('No puede digitar retenciones con fecha de un mes cerrado en CONTABILIDAD.','exclamation')
			NEXT FIELD j14_fecha_emi
		END IF
		LET fin_mes = MDY(MONTH(fecha2), 01, YEAR(fecha2))
				+ 1 UNITS MONTH - 1 UNITS DAY
		CALL fecha_ultima() RETURNING fec_ult
		IF fecha2 < fec_ult THEN
			LET fec_pro = MDY(MONTH(fec_ult), 01,
					YEAR(fec_ult))
					+ 1 UNITS MONTH - 1 UNITS DAY
		ELSE
			LET fec_pro = fecha2
		END IF
		IF fecha_bloqueada(vg_codcia, MONTH(fec_pro),YEAR(fec_pro)) THEN
			NEXT FIELD j14_fecha_emi
		END IF
END INPUT

END FUNCTION



FUNCTION fecha_ultima()
DEFINE fec_ult		DATE
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE bas_aux		CHAR(20)
DEFINE query		CHAR(800)

LET codloc  = vg_codloc
LET bas_aux = vg_base
IF vg_codloc = 4 OR vg_codloc = 5 THEN
	LET codloc  = 3
	LET bas_aux = 'acero_qm'
END IF
LET query = 'SELECT MAX(MDY(s21_mes, 01, s21_anio) ',
		'+ 1 UNITS MONTH - 1 UNITS DAY) + 1 UNITS DAY ',
		'FROM ', bas_aux CLIPPED, ':srit021 ',
		'WHERE s21_compania   = ', vg_codcia,
		'  AND s21_localidad  = ', codloc,
		'  AND s21_estado    IN ("D", "C") '
PREPARE c_fec_ult FROM query
DECLARE q_fec_ult CURSOR FOR c_fec_ult
OPEN q_fec_ult
FETCH q_fec_ult INTO fec_ult
CLOSE q_fec_ult
FREE q_fec_ult
RETURN fec_ult

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	CALL fl_mostrar_mensaje('No puede digitar retenciones de una fecha bloqueada en CONTABILIDAD.','exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION lee_detalle_ret(posi)
DEFINE posi		SMALLINT
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_z09		RECORD LIKE cxct009.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c03		RECORD LIKE ordt003.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE cont_cred	LIKE cajt014.j14_cont_cred
DEFINE base_imp		LIKE cajt014.j14_base_imp
DEFINE valor_bruto	DECIMAL(14,2)
DEFINE valor_impto	DECIMAL(14,2)
DEFINE subtotal		DECIMAL(14,2)
DEFINE flete		DECIMAL(14,2)
DEFINE valor_fact	DECIMAL(14,2)
DEFINE resp		CHAR(6)
DEFINE i,j,l, k, hay_ri	SMALLINT
DEFINE salir, flag_c	SMALLINT
DEFINE max_row, resul	SMALLINT

OPTIONS 
	INSERT KEY F10,
	DELETE KEY F11
IF vm_num_ret > 0 THEN
	CALL calcular_tot_retencion(vm_num_ret)
ELSE
	LET vm_num_ret = 1
END IF
LET cont_cred = 'R'
LET salir     = 0
LET int_flag  = 0
CALL set_count(vm_num_ret)
INPUT ARRAY rm_detret WITHOUT DEFAULTS FROM rm_detret.*
	ON KEY(INTERRUPT)
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j14_codigo_pago) THEN
			CALL fl_ayuda_forma_pago(vg_codcia, cont_cred, 'A', 'S')
				RETURNING r_j01.j01_codigo_pago,
					  r_j01.j01_nombre,
					  r_j01.j01_cont_cred
			IF r_j01.j01_codigo_pago IS NOT NULL THEN
				LET rm_detret[i].j14_codigo_pago =
							r_j01.j01_codigo_pago
				DISPLAY rm_detret[i].j14_codigo_pago TO
					rm_detret[j].j14_codigo_pago
			END IF
		END IF
		IF INFIELD(j14_porc_ret) THEN
			CALL fl_ayuda_retenciones(vg_codcia,
					rm_detret[i].j14_codigo_pago, 'A')
				RETURNING r_c02.c02_tipo_ret,
					  r_c02.c02_porcentaje, r_c02.c02_nombre
			IF r_c02.c02_tipo_ret IS NOT NULL THEN
				LET rm_detret[i].j14_tipo_ret =
							r_c02.c02_tipo_ret
				LET rm_detret[i].j14_porc_ret =
							r_c02.c02_porcentaje
				IF rm_detret[i].j14_codigo_sri IS NULL THEN
					CALL codigo_sri_defecto(vg_codcia,
							rm_par.z20_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
					RETURNING rm_detret[i].j14_codigo_sri,
							fec_ini_por[i]
				END IF
				CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
					RETURNING r_c03.*
				LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				DISPLAY rm_detret[i].* TO rm_detret[j].*
			END IF
		END IF
		IF INFIELD(j14_codigo_sri) THEN
			CALL fl_ayuda_codigos_sri(vg_codcia,
					rm_detret[i].j14_tipo_ret,
					rm_detret[i].j14_porc_ret, 'A',
					rm_par.z20_codcli, 'C')
				RETURNING r_c03.c03_codigo_sri,
					  r_c03.c03_concepto_ret,
					  r_c03.c03_fecha_ini_porc
			IF r_c03.c03_codigo_sri IS NOT NULL THEN
				LET rm_detret[i].j14_codigo_sri =
							r_c03.c03_codigo_sri
				LET fec_ini_por[i] = r_c03.c03_fecha_ini_porc
				LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
				DISPLAY rm_detret[i].* TO rm_detret[j].*
				DISPLAY rm_detret[i].c03_concepto_ret TO
					concepto_ret
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		LET int_flag = 0
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
		--#CALL dialog.keysetlabel("F5","Cabecera")
	BEFORE ROW
		LET i = arr_curr()
		LET j = scr_line()
		LET max_row = arr_count()
		IF i > max_row THEN
			LET max_row = max_row + 1
		END IF
		CALL muestra_contadores_det(i, max_row)
		CALL calcular_tot_retencion(max_row)
		DISPLAY rm_detret[i].c03_concepto_ret TO concepto_ret
	BEFORE FIELD j14_base_imp
		LET base_imp = rm_detret[i].j14_base_imp
	AFTER FIELD j14_codigo_pago
		IF rm_detret[i].j14_codigo_pago IS NULL THEN
			IF fgl_lastkey() <> fgl_keyval('up') THEN
				NEXT FIELD j14_codigo_pago
			ELSE
				CONTINUE INPUT
			END IF
		END IF 
		CALL fl_lee_tipo_pago_caja(vg_codcia,
					rm_detret[i].j14_codigo_pago, cont_cred)
			RETURNING r_j01.*		
		IF r_j01.j01_codigo_pago IS NULL THEN
			CALL fl_mostrar_mensaje('Forma Pago de Retencion no existe.','exclamation')
			NEXT FIELD j14_codigo_pago
		END IF
		IF r_j01.j01_estado = 'B' THEN
			CALL fl_mostrar_mensaje('Forma de Pago esta bloqueada.','exclamation')
			NEXT FIELD j14_codigo_pago
		END IF
		IF NOT fl_determinar_si_es_retencion(vg_codcia,
					rm_detret[i].j14_codigo_pago, cont_cred)
		THEN
			CALL fl_mostrar_mensaje('Esta Forma de Pago, no es de Retencion.','exclamation')
			NEXT FIELD j14_codigo_pago
		END IF
	AFTER FIELD j14_porc_ret
		SELECT UNIQUE j91_tipo_ret
			INTO rm_detret[i].j14_tipo_ret
			FROM cajt091
			WHERE j91_compania    = vg_codcia
			  AND j91_codigo_pago = rm_detret[i].j14_codigo_pago
			  AND j91_cont_cred   = cont_cred
		IF rm_detret[i].j14_porc_ret IS NOT NULL THEN
			CALL fl_lee_tipo_retencion(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
				RETURNING r_c02.*
			IF r_c02.c02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este porcentaje de retencion.', 'exclamation')
				NEXT FIELD j14_porc_ret
			END IF
			IF r_c02.c02_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El porcentaje de retencion esta bloqueado.', 'exclamation')
				NEXT FIELD j14_porc_ret
			END IF
			IF rm_detret[i].j14_codigo_sri IS NULL THEN
				CALL codigo_sri_defecto(vg_codcia,
						rm_par.z20_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret)
					RETURNING rm_detret[i].j14_codigo_sri,
							fec_ini_por[i]
			END IF
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
				RETURNING r_c03.*
			LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
			DISPLAY rm_detret[i].* TO rm_detret[j].*
			DISPLAY rm_detret[i].c03_concepto_ret TO concepto_ret
		ELSE
			LET rm_detret[i].j14_tipo_ret = NULL
		END IF
		DISPLAY rm_detret[i].j14_tipo_ret TO rm_detret[j].j14_tipo_ret
	AFTER FIELD j14_codigo_sri
		IF rm_detret[i].j14_codigo_sri IS NOT NULL THEN
			CALL fl_lee_codigos_sri(vg_codcia,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i])
				RETURNING r_c03.*
			IF r_c03.c03_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe configurado este codigo del SRI.', 'exclamation')
				NEXT FIELD j14_codigo_sri
			END IF
			IF r_c03.c03_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El codigo del SRI esta bloqueado.', 'exclamation')
				NEXT FIELD j14_codigo_sri
			END IF
			LET rm_detret[i].c03_concepto_ret =
							r_c03.c03_concepto_ret
			IF NOT tiene_aux_cont_retencion(
				rm_detret[i].j14_codigo_pago, cont_cred, 0)
			THEN
				CALL fl_lee_det_retencion_cli(vg_codcia,
						rm_par.z20_codcli,
						rm_detret[i].j14_tipo_ret,
						rm_detret[i].j14_porc_ret,
						rm_detret[i].j14_codigo_sri,
						fec_ini_por[i],
						rm_detret[i].j14_codigo_pago,
						cont_cred)
					RETURNING r_z09.*
				IF r_z09.z09_aux_cont IS NULL THEN
					CALL fl_mostrar_mensaje('No existe auxiliar contable para este codigo de SRI en este tipo de retencion.', 'exclamation')
					NEXT FIELD j14_codigo_sri
				END IF
			END IF
		ELSE
			LET rm_detret[i].c03_concepto_ret = NULL
		END IF
		DISPLAY rm_detret[i].c03_concepto_ret TO
			rm_detret[j].c03_concepto_ret
		DISPLAY rm_detret[i].c03_concepto_ret TO concepto_ret
		LET flag_c = 0
		IF rm_detret[i].j14_base_imp <> base_imp THEN
			LET flag_c = 1
		END IF
		CALL calcular_retencion(i, j, flag_c)
		CALL calcular_tot_retencion(max_row)
	AFTER FIELD j14_base_imp
		LET flag_c = 0
		IF rm_detret[i].j14_base_imp <> base_imp THEN
			LET flag_c = 1
		END IF
		CALL calcular_retencion(i, j, flag_c)
		CALL calcular_tot_retencion(max_row)
	AFTER FIELD j14_valor_ret
		CALL calcular_retencion(i, j, 0)
		CALL calcular_tot_retencion(max_row)
	AFTER DELETE
		LET max_row = max_row - 1
		IF max_row <= 0 THEN
			LET max_row = 1
		END IF
		CALL calcular_tot_retencion(max_row)
	AFTER INPUT
		LET vm_num_ret = arr_count()
		CALL calcular_tot_retencion(vm_num_ret)
		FOR l = 1 TO vm_num_ret - 1
			FOR k = l + 1 TO vm_num_ret
				IF (rm_detret[l].j14_codigo_pago =
				    rm_detret[k].j14_codigo_pago) AND
				   (rm_detret[l].j14_tipo_ret =
				    rm_detret[k].j14_tipo_ret) AND
				   (rm_detret[l].j14_porc_ret =
				    rm_detret[k].j14_porc_ret) AND
				   (rm_detret[l].j14_codigo_sri =
				    rm_detret[k].j14_codigo_sri) AND
				   (fec_ini_por[l] = fec_ini_por[k])
				THEN
					CALL fl_mostrar_mensaje('Existen un mismo tipo de porcentaje y codigo del SRI mas de una vez en el detalle.', 'exclamation')
					CONTINUE INPUT
				END IF
			END FOR
		END FOR
		CASE rm_par.z20_areaneg
			WHEN 1
				CALL lee_factura_inv(vg_codcia, vg_codloc,
						rm_adi[posi].z20_cod_tran,
						rm_adi[posi].z20_num_tran)
					RETURNING r_r19.*
				LET valor_bruto = r_r19.r19_tot_bruto -
							r_r19.r19_tot_dscto
				LET valor_impto = r_r19.r19_tot_neto -
							r_r19.r19_tot_bruto +
							r_r19.r19_tot_dscto -
							r_r19.r19_flete
				LET subtotal    = valor_bruto +
								valor_impto
				LET flete       = r_r19.r19_flete
				LET valor_fact  = subtotal + flete
			WHEN 2
				CALL fl_lee_factura_taller(vg_codcia,
						vg_codloc,
						rm_adi[posi].z20_num_tran)
					RETURNING r_t23.*
				LET valor_bruto = r_t23.t23_tot_bruto -
							r_t23.t23_vde_mo_tal
				LET valor_impto = r_t23.t23_val_impto
				LET subtotal    = valor_bruto +
								valor_impto
				LET flete       = NULL
				LET valor_fact  = subtotal
		END CASE
		LET hay_ri = 0
		FOR l = 1 TO vm_num_ret
			IF rm_detret[l].j14_codigo_pago = 'RI' THEN
				LET hay_ri = 1
				EXIT FOR
			END IF
		END FOR
		IF NOT hay_ri THEN
			LET valor_fact = valor_fact - valor_impto
		END IF
		IF tot_base_imp > valor_fact THEN
			CALL fl_mostrar_mensaje('El total de la base imponible no puede ser mayor que el valor de la factura.', 'exclamation')
			CONTINUE INPUT
		END IF
		LET resul = 0
		FOR l = 1 TO vm_num_ret
			IF rm_detret[l].j14_codigo_sri IS NULL OR
			   fec_ini_por[l] IS NULL
			THEN
				LET resul = 1
				EXIT FOR
			END IF
		END FOR
		IF resul THEN
			CONTINUE INPUT
		END IF
		FOR l = 1 TO vm_num_ret
			CALL retorna_ret_fac(posi)
				RETURNING rm_adi_r[l].tipo_fuente,
						rm_adi_r[l].cod_tr,
						rm_adi_r[l].num_tr,
						rm_adi_r[l].num_sri
			CALL retorna_tipo_doc(posi, rm_adi_r[l].tipo_fuente)
				RETURNING rm_adi_r[l].tipo_doc
		END FOR
		LET salir = 1
END INPUT
RETURN salir

END FUNCTION



FUNCTION valido_num_ret(num_ret_sri)
DEFINE num_ret_sri	LIKE cajt014.j14_num_ret_sri
DEFINE lim		SMALLINT

IF LENGTH(num_ret_sri) < 14 THEN
	CALL fl_mostrar_mensaje('El nÃºmero del documento ingresado es incorrecto.', 'exclamation')
	RETURN 0
END IF
IF num_ret_sri[4, 4] <> '-' OR num_ret_sri[8, 8] <> '-' THEN
	CALL fl_mostrar_mensaje('Faltan los guiones.', 'exclamation')
	RETURN 0
END IF
IF num_ret_sri[1, 3] = '000' OR num_ret_sri[5, 7] = '000' THEN
	CALL fl_mostrar_mensaje('Los prefijos son incorrectos. No pueden ser 000.', 'exclamation')
	RETURN 0
END IF
IF LENGTH(num_ret_sri[1, 7]) <> 7 THEN
	CALL fl_mostrar_mensaje('Digite correctamente el punto de venta o el punto de emision.', 'exclamation')
	RETURN 0
END IF
{--
LET lim = LENGTH(num_ret_sri)
IF NOT fl_solo_numeros(num_ret_sri[9, lim]) THEN
	CALL fl_mostrar_mensaje('Digite solo numeros para el numero del comprobante.', 'exclamation')
	RETURN 0
END IF
--}
IF NOT fl_valida_numeros(num_ret_sri[1, 3]) THEN
	RETURN 0
END IF
IF NOT fl_valida_numeros(num_ret_sri[5, 7]) THEN
	RETURN 0
END IF
LET lim = LENGTH(num_ret_sri)
IF NOT fl_valida_numeros(num_ret_sri[9, lim]) THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION calcular_retencion(i, j, flag)
DEFINE i, j, flag	SMALLINT

IF rm_detret[i].j14_valor_ret IS NOT NULL AND NOT flag THEN
	RETURN
END IF
IF rm_detret[i].j14_valor_ret > 0 AND NOT flag THEN
	RETURN
END IF
LET rm_detret[i].j14_valor_ret = rm_detret[i].j14_base_imp *
				(rm_detret[i].j14_porc_ret / 100)
DISPLAY rm_detret[i].j14_base_imp  TO rm_detret[i].j14_base_imp
DISPLAY rm_detret[i].j14_valor_ret TO rm_detret[i].j14_valor_ret

END FUNCTION



FUNCTION calcular_tot_retencion(lim)
DEFINE i, lim		SMALLINT

LET tot_base_imp  = 0
LET tot_valor_ret = 0
FOR i = 1 TO lim
	LET tot_base_imp  = tot_base_imp  + rm_detret[i].j14_base_imp
	LET tot_valor_ret = tot_valor_ret + rm_detret[i].j14_valor_ret
END FOR
DISPLAY BY NAME tot_base_imp, tot_valor_ret

END FUNCTION



FUNCTION lee_num_retencion(i)
DEFINE i		SMALLINT
DEFINE r_j14		RECORD LIKE cajt014.*

INITIALIZE r_j14.* TO NULL
DECLARE q_j14 CURSOR FOR
	SELECT cajt014.*
		FROM cajt014, cajt010
		WHERE j14_compania     = vg_codcia
		  AND j14_localidad    = vg_codloc
		  AND j14_tipo_fuente IN ("PR", "OT")
		  AND j14_num_ret_sri  = rm_j14.j14_num_ret_sri
		  AND j10_compania     = j14_compania
		  AND j10_localidad    = j14_localidad
		  AND j10_tipo_fuente  = j14_tipo_fuente
		  AND j10_num_fuente   = j14_num_fuente
		  AND j10_codcli       = rm_par.z20_codcli
OPEN q_j14
FETCH q_j14 INTO r_j14.*
IF STATUS = NOTFOUND THEN
	CALL retorna_num_ret(i, 1) RETURNING r_j14.j14_num_ret_sri
END IF
CLOSE q_j14
FREE q_j14
RETURN r_j14.*

END FUNCTION



FUNCTION registros_retenciones(numero_ret, i)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE i		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tra		LIKE cajt010.j10_tipo_destino
DEFINE num_tra		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE query		CHAR(500)
DEFINE cuantos		INTEGER

CALL retorna_ret_fac(i) RETURNING tipo_f, cod_tra, num_tra, num_s
CALL retorna_num_ret(i, 0) RETURNING tipo_f
LET query = 'SELECT COUNT(*) tot_reg ',
		' FROM tmp_ret ',
		' WHERE tipo_fuente = "', tipo_f, '"',
		'   AND num_ret_sri = "', numero_ret CLIPPED, '"',
		'   AND cod_tr      = "', cod_tra, '"',
		'   AND num_tr      = ', num_tra
LET query = query CLIPPED, ' INTO TEMP t1'
PREPARE exec_contar FROM query
EXECUTE exec_contar
SELECT tot_reg INTO cuantos FROM t1
DROP TABLE t1
RETURN cuantos

END FUNCTION



FUNCTION tiene_aux_cont_retencion(codigo_pago, cont_cred, flag)
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE cont_cred	LIKE cajt001.j01_cont_cred
DEFINE flag		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b42		RECORD LIKE ctbt042.*
DEFINE r_j01		RECORD LIKE cajt001.*
DEFINE r_j91		RECORD LIKE cajt091.*
DEFINE tipo_ret		LIKE cajt091.j91_tipo_ret
DEFINE porc_ret		LIKE cajt091.j91_porcentaje
DEFINE resul		SMALLINT

INITIALIZE r_b42.* TO NULL
SELECT * INTO r_b42.*
	FROM ctbt042
	WHERE b42_compania    = vg_codcia
	  AND b42_localidad   = vg_codloc
CALL fl_lee_cuenta(r_b42.b42_compania, r_b42.b42_retencion) RETURNING r_b10.*
LET resul = 1
IF vg_codloc = 2 OR vg_codloc = 4 OR vg_codloc = 5 THEN
	RETURN resul
END IF
IF r_b10.b10_compania IS NULL THEN
	SELECT UNIQUE j91_tipo_ret
		INTO tipo_ret
		FROM cajt091
		WHERE j91_compania    = vg_codcia
		  AND j91_codigo_pago = codigo_pago
		  AND j91_cont_cred   = cont_cred
	CALL fl_lee_det_tipo_ret_caja(vg_codcia, codigo_pago, cont_cred,
					tipo_ret, porc_ret)
		RETURNING r_j91.*
	IF r_j91.j91_aux_cont IS NULL THEN
		CALL fl_lee_tipo_pago_caja(vg_codcia, codigo_pago,
						cont_cred)
			RETURNING r_j01.*
		IF r_j01.j01_aux_cont IS NULL THEN
			LET resul = 0
		END IF
	END IF
END IF
IF NOT resul AND flag THEN
	CALL fl_mostrar_mensaje('No existen auxiliares contables para este tipo de forma de pago. LLAME AL ADMINISTRADOR.', 'exclamation')
END IF
RETURN resul

END FUNCTION



FUNCTION codigo_sri_defecto(codcia, codcli, tipo_ret, porc_ret)
DEFINE codcia		LIKE cxct008.z08_compania
DEFINE codcli		LIKE cxct008.z08_codcli
DEFINE tipo_ret		LIKE cxct008.z08_tipo_ret
DEFINE porc_ret		LIKE cxct008.z08_porcentaje
DEFINE cod_sri		LIKE cxct008.z08_codigo_sri
DEFINE fec_ini		LIKE ordt003.c03_fecha_ini_porc
DEFINE query		CHAR(1200)

INITIALIZE cod_sri, fec_ini TO NULL
LET query = 'SELECT c03_codigo_sri, c03_fecha_ini_porc, ',
		' CASE WHEN z08_codcli IS NULL ',
			' THEN "S" ',
			' ELSE "N" ',
		' END defecto ',
		' FROM ordt003, OUTER cxct008 ',
		' WHERE c03_compania       = ', codcia,
		'   AND c03_tipo_ret       = "', tipo_ret, '"',
		'   AND c03_porcentaje     = ', porc_ret,
		'   AND c03_estado         = "A"',
		'   AND z08_compania       = c03_compania ',
		'   AND z08_codcli         = ', codcli,
		'   AND z08_tipo_ret       = c03_tipo_ret ',
		'   AND z08_porcentaje     = c03_porcentaje ',
		'   AND z08_codigo_sri     = c03_codigo_sri ',
		'   AND z08_fecha_ini_porc = c03_fecha_ini_porc ',
		'   AND c03_fecha_fin_porc IS NULL ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DECLARE q_sri2 CURSOR FOR
	SELECT c03_codigo_sri, c03_fecha_ini_porc
		FROM t1 WHERE defecto = "S"
OPEN q_sri2
FETCH q_sri2 INTO cod_sri, fec_ini
CLOSE q_sri2
FREE q_sri2
DROP TABLE t1
RETURN cod_sri, fec_ini

END FUNCTION



FUNCTION retorna_ret_fac(i)
DEFINE i		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tr		LIKE cajt010.j10_tipo_destino
DEFINE num_tr		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri

CASE rm_par.z20_areaneg
	WHEN 1 LET tipo_f = 'PR'
	WHEN 2 LET tipo_f = 'OT'
END CASE
LET cod_tr = rm_adi[i].z20_cod_tran
LET num_tr = rm_adi[i].z20_num_tran
LET num_s  = rm_adi[i].num_sri
RETURN tipo_f, cod_tr, num_tr, num_s

END FUNCTION



FUNCTION retorna_num_fue(i)
DEFINE i		SMALLINT
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE num_f		LIKE cajt010.j10_num_fuente

CASE rm_par.z20_areaneg
	WHEN 1
		CALL lee_factura_inv(vg_codcia, vg_codloc,
				rm_adi[i].z20_cod_tran, rm_adi[i].z20_num_tran)
			RETURNING r_r19.*
		CALL lee_cabecera_preventa_loc(r_r19.r19_compania,
						r_r19.r19_localidad,
						r_r19.r19_cod_tran,
						r_r19.r19_num_tran)
			RETURNING r_r23.*
		LET num_f = r_r23.r23_numprev
	WHEN 2
		CALL fl_lee_factura_taller(vg_codcia, vg_codloc,
					rm_adi[i].z20_num_tran)
			RETURNING r_t23.*
		LET num_f = r_t23.t23_orden
END CASE
RETURN num_f

END FUNCTION



FUNCTION retorna_num_ret(i, flag)
DEFINE i, flag		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tra		LIKE cajt010.j10_tipo_destino
DEFINE num_tra		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE num_ret		LIKE cajt014.j14_num_ret_sri
DEFINE query		CHAR(600)
DEFINE expr_sql		VARCHAR(200)
DEFINE campo		VARCHAR(12)

LET num_ret  = NULL
CALL retorna_ret_fac(i) RETURNING tipo_f, cod_tra, num_tra, num_s
LET campo    = 'tipo_fuente'
LET expr_sql = NULL
IF flag THEN
	LET campo    = 'num_ret_sri'
	LET expr_sql = ' tipo_fuente = "', tipo_f, '"   AND '
END IF
LET query = 'SELECT UNIQUE ', campo CLIPPED,
		' FROM tmp_ret ',
		' WHERE ',
		expr_sql CLIPPED,
		' cod_tr      = "', cod_tra, '"',
		'   AND num_tr      = ', num_tra
LET query = query CLIPPED, ' INTO TEMP t1'
PREPARE exec_ret FROM query
EXECUTE exec_ret
SELECT * INTO num_ret FROM t1
DROP TABLE t1
RETURN num_ret CLIPPED

END FUNCTION



FUNCTION borrar_retencion(numero_ret, posi)
DEFINE numero_ret	LIKE cajt011.j11_num_ch_aut
DEFINE posi		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE cod_tra		LIKE cajt010.j10_tipo_destino
DEFINE num_tra		LIKE cajt010.j10_num_destino
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE query		CHAR(500)

IF numero_ret IS NULL THEN
	RETURN
END IF
CALL retorna_ret_fac(posi) RETURNING tipo_f, cod_tra, num_tra, num_s
IF tipo_f = vm_tipo_fue THEN
	CALL retorna_num_ret(posi, 0) RETURNING tipo_f
END IF
LET query = 'DELETE FROM tmp_ret ',
		' WHERE tipo_fuente = "', tipo_f, '"',
		'   AND num_ret_sri = "', numero_ret CLIPPED,'"',
		'   AND cod_tr      = "', cod_tra, '"',
		'   AND num_tr      = ', num_tra
PREPARE exec_del_ret FROM query
EXECUTE exec_del_ret

END FUNCTION



FUNCTION lee_factura_inv(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*

CALL fl_lee_cabecera_transaccion_rep(codcia, codloc, cod_tran, num_tran)
	RETURNING r_r19.*
IF r_r19.r19_compania IS NULL THEN
	CALL lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
		RETURNING r_r19.*
END IF
RETURN r_r19.*

END FUNCTION



FUNCTION lee_cabecera_transaccion_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept019.r19_compania
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(400)

INITIALIZE r_r19.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	RETURN r_r19.*
END IF
IF cod_tran IS NULL AND num_tran IS NULL THEN
	RETURN r_r19.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept019 ',
		' WHERE r19_compania  = ', codcia,
		'   AND r19_localidad = ', codloc,
		'   AND r19_cod_tran  = "', cod_tran, '"',
		'   AND r19_num_tran  = ', num_tran
PREPARE cons_f_loc FROM query
DECLARE q_cons_f_loc CURSOR FOR cons_f_loc
OPEN q_cons_f_loc
FETCH q_cons_f_loc INTO r_r19.*
CLOSE q_cons_f_loc
FREE q_cons_f_loc
RETURN r_r19.*

END FUNCTION



FUNCTION lee_cabecera_preventa_loc(codcia, codloc, cod_tran, num_tran)
DEFINE codcia		LIKE rept023.r23_compania
DEFINE codloc		LIKE rept023.r23_localidad
DEFINE cod_tran		LIKE rept023.r23_cod_tran
DEFINE num_tran		LIKE rept023.r23_num_tran
DEFINE r_r23		RECORD LIKE rept023.*
DEFINE query		CHAR(400)

INITIALIZE r_r23.* TO NULL
IF NOT (codloc = 2 OR codloc = 4) THEN
	SELECT * INTO r_r23.*
		FROM rept023
		WHERE r23_compania  = codcia
		  AND r23_localidad = codloc
		  AND r23_cod_tran  = cod_tran
		  AND r23_num_tran  = num_tran
	RETURN r_r23.*
END IF
LET query = 'SELECT * FROM ', retorna_base_loc() CLIPPED, 'rept023 ',
		' WHERE r23_compania  = ', codcia,
		'   AND r23_localidad = ', codloc,
		'   AND r23_cod_tran  = "', cod_tran, '"',
		'   AND r23_num_tran  = ', num_tran
PREPARE cons_p_loc FROM query
DECLARE q_cons_p_loc CURSOR FOR cons_p_loc
OPEN q_cons_p_loc
FETCH q_cons_p_loc INTO r_r23.*
CLOSE q_cons_p_loc
FREE q_cons_p_loc
RETURN r_r23.*

END FUNCTION



FUNCTION retorna_base_loc()
DEFINE base_loc		VARCHAR(10)

LET base_loc = NULL
IF NOT (vg_codloc = 2 OR vg_codloc = 4 OR vg_codloc = 5) THEN
	RETURN base_loc CLIPPED
END IF
SELECT g56_base_datos INTO base_loc
	FROM gent056
	WHERE g56_compania  = vg_codcia
	  AND g56_localidad = vg_codloc
IF base_loc IS NOT NULL THEN
	LET base_loc = base_loc CLIPPED, ':'
END IF
RETURN base_loc CLIPPED

END FUNCTION



FUNCTION retorna_tipo_doc(posi, tipo_f)
DEFINE posi		SMALLINT
DEFINE tipo_f		LIKE cajt010.j10_tipo_fuente
DEFINE tip_d		LIKE rept038.r38_tipo_doc
DEFINE query		CHAR(1000)

LET query = 'SELECT r38_tipo_doc '
IF (vg_codloc = 2 OR vg_codloc = 4 OR vg_codloc = 5) THEN
	LET query = query CLIPPED,
		' FROM ', retorna_base_loc() CLIPPED, 'rept038'
ELSE
	LET query = query CLIPPED, ' FROM rept038'
END IF
LET query = query CLIPPED,
		' WHERE r38_compania    = ', vg_codcia,
		'   AND r38_localidad   = ', vg_codloc,
		'   AND r38_tipo_fuente = "', tipo_f, '"',
		'   AND r38_cod_tran    = "', rm_adi[posi].z20_cod_tran, '"',
		'   AND r38_num_tran    = ', rm_adi[posi].z20_num_tran
LET tip_d = NULL
PREPARE cons_r38_2 FROM query
DECLARE q_cons_r38_2 CURSOR FOR cons_r38_2
OPEN q_cons_r38_2
FETCH q_cons_r38_2 INTO tip_d
CLOSE q_cons_r38_2
FREE q_cons_r38_2
RETURN tip_d

END FUNCTION



FUNCTION control_generar_transaccion_ret()
DEFINE total		DECIMAL(12,2)
DEFINE cuantos		INTEGER

SELECT NVL(SUM(valor_ret), 0) INTO total FROM tmp_ret WHERE 1 = 1
IF total <= 0 THEN
	CALL fl_mostrar_mensaje('No se proceso ninguna retencion.', 'info')
	RETURN
END IF
SELECT * FROM tmp_ret
	WHERE EXISTS
		(SELECT 1 FROM tmp_det
			WHERE z20_cod_tran    = cod_tr
			  AND z20_num_tran    = num_tr
			  AND r38_num_sri     = num_fac_sri
			  AND (z20_saldo_cap  = 0
			   OR  z20_fecha_vcto IS NULL))
	INTO TEMP t1
DELETE FROM tmp_ret
	WHERE EXISTS
		(SELECT tmp_det.* FROM tmp_det
			WHERE tmp_det.z20_cod_tran    = tmp_ret.cod_tr
			  AND tmp_det.z20_num_tran    = tmp_ret.num_tr
			  AND tmp_det.r38_num_sri     = tmp_ret.num_fac_sri
			  AND (tmp_det.z20_saldo_cap  = 0
			   OR  tmp_det.z20_fecha_vcto IS NULL))
SELECT COUNT(*) INTO cuantos FROM tmp_ret
IF cuantos > 0 THEN
	IF NOT genera_transaccion_retencion('P') THEN
		RETURN
	END IF
END IF
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos > 0 THEN
	DROP TABLE tmp_ret
	SELECT * FROM t1 INTO TEMP tmp_ret
	DROP TABLE t1
	IF NOT genera_transaccion_retencion('A') THEN
		RETURN
	END IF
ELSE
	DROP TABLE t1
END IF
CALL fl_mostrar_mensaje('Proceso Terminado OK. ', 'info')

END FUNCTION



FUNCTION genera_transaccion_retencion(tipo)
DEFINE tipo		LIKE cxct024.z24_tipo
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE resul		SMALLINT
DEFINE segundo		SMALLINT

CREATE TEMP TABLE tmp_doc
	(
		num_reten	CHAR(21),
		tipo_sol	CHAR(2),
		num_sol		INTEGER,
		tip_trn		CHAR(2),
		num_trn		INTEGER,
		tip_ec		CHAR(2),
		num_ec		INTEGER,
		fecha_pro	DATE
	)
BEGIN WORK
	DECLARE q_ret_doc CURSOR WITH HOLD FOR
		--SELECT UNIQUE num_ret_sri, cod_pago, tipo_ret, porc_ret
		SELECT UNIQUE num_ret_sri
			FROM tmp_ret
			ORDER BY num_ret_sri
	LET segundo = 1
	FOREACH q_ret_doc INTO r_ret_p.*
		IF rm_par.devuelve = 'S' AND tipo = 'A' THEN
			IF NOT genera_documento_deudor(r_ret_p.*) THEN
				DROP TABLE tmp_doc
				WHENEVER ERROR STOP
				ROLLBACK WORK
				RETURN 0
			END IF
		END IF
		IF NOT genera_solicitud_cobro(tipo, r_ret_p.*) THEN
			DROP TABLE tmp_doc
			WHENEVER ERROR STOP
			ROLLBACK WORK
			RETURN 0
		END IF
		IF NOT genera_forma_pago(r_ret_p.*, segundo) THEN
			DROP TABLE tmp_doc
			WHENEVER ERROR STOP
			ROLLBACK WORK
			RETURN 0
		END IF
		CALL actualiza_acumulados_tipo_transaccion('I')
		CALL actualiza_detalle_retencion(1)
		CALL inserta_fecha_pro(r_ret_p.num_ret_s)
		IF rm_par.devuelve = 'S' AND tipo = 'A' THEN
			CALL generar_aplicacion_documentos(r_ret_p.num_ret_s,
								segundo)
				RETURNING resul, r_z22.*
			IF NOT resul THEN
				DROP TABLE tmp_doc
				WHENEVER ERROR STOP
				ROLLBACK WORK
				RETURN 0
			END IF
			--IF vg_codloc < 3 OR vg_codloc > 5 THEN
			--IF vg_codloc <> 2 AND vg_codloc <> 4 THEN
				CALL generar_egreso_efectivo_caja(r_ret_p.num_ret_s)
					RETURNING resul, r_j10.*
				IF NOT resul THEN
					DROP TABLE tmp_doc
					WHENEVER ERROR STOP
					ROLLBACK WORK
					RETURN 0
				END IF
			--END IF
			UPDATE tmp_doc
				SET tip_trn = r_z22.z22_tipo_trn,
				    num_trn = r_z22.z22_num_trn,
				    tip_ec  = r_j10.j10_tipo_fuente,
				    num_ec  = r_j10.j10_num_fuente
				WHERE num_reten = r_ret_p.num_ret_s
				  AND tipo_sol  = vm_tipo_fue
				  AND num_sol   = vm_num_sol
		END IF
		LET segundo = segundo + 1
	END FOREACH
COMMIT WORK
IF vg_base <> 'acero_gc' AND vg_base <> 'acero_qs' THEN
	DECLARE q_doc CURSOR WITH HOLD FOR
		SELECT UNIQUE tipo_sol, num_sol, tip_trn, num_trn, tip_ec,
			num_ec
			FROM tmp_doc
			ORDER BY 1, 2
	FOREACH q_doc INTO vm_tipo_fue, vm_num_sol, r_z22.z22_tipo_trn,
				r_z22.z22_num_trn, r_j10.j10_tipo_fuente,
				r_j10.j10_num_fuente
		CALL fl_contabilizacion_trans_caja_ret(vg_codcia, vg_codloc,
							vm_tipo_fue, vm_num_sol,
							r_z22.z22_tipo_trn,
							r_z22.z22_num_trn)
		IF r_z22.z22_tipo_trn IS NULL THEN
			CONTINUE FOREACH
		END IF
		IF tipo = 'P' THEN
			CONTINUE FOREACH
		END IF
		CALL fl_contabilizacion_trans_caja_ret(vg_codcia, vg_codloc,
						r_z22.z22_tipo_trn,
						r_z22.z22_num_trn,
						vm_tipo_fue, vm_num_sol)
		{-- OJO
		IF vg_codloc >= 3 AND vg_codloc <= 5 THEN
			CONTINUE FOREACH
		END IF
		--}
		UPDATE cajt010
			SET j10_tip_contable =
				(SELECT UNIQUE z40_tipo_comp
					FROM cxct040
					WHERE z40_compania  = j10_compania
					  AND z40_localidad = j10_localidad
					  AND z40_codcli    = j10_codcli
					  AND z40_tipo_doc  = r_z22.z22_tipo_trn
					  AND z40_num_doc   =r_z22.z22_num_trn),
			    j10_num_contable =
				(SELECT UNIQUE z40_num_comp
					FROM cxct040
					WHERE z40_compania  = j10_compania
					  AND z40_localidad = j10_localidad
					  AND z40_codcli    = j10_codcli
					  AND z40_tipo_doc  = r_z22.z22_tipo_trn
					  AND z40_num_doc   = r_z22.z22_num_trn)
			WHERE j10_compania    = vg_codcia
			  AND j10_localidad   = vg_codloc
			  AND j10_tipo_fuente = r_j10.j10_tipo_fuente
			  AND j10_num_fuente  = r_j10.j10_num_fuente
	END FOREACH
END IF
BEGIN WORK
	CALL actualiza_detalle_retencion(1)
COMMIT WORK
DECLARE q_impr CURSOR FOR SELECT UNIQUE num_sol FROM tmp_doc ORDER BY 1
FOREACH q_impr INTO vm_num_sol
	CALL imprime_comprobante(vm_num_sol)
END FOREACH
IF vg_base <> 'acero_gc' AND vg_base <> 'acero_qs' THEN
	CALL imprime_contabilizacion()
END IF
DROP TABLE tmp_doc
RETURN 1

END FUNCTION



FUNCTION genera_solicitud_cobro(tipo, r_ret_p)
DEFINE tipo		LIKE cxct024.z24_tipo
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE r_z24		RECORD LIKE cxct024.*

CALL generar_cabecera_solicitud_cobro(tipo, r_ret_p.*) RETURNING r_z24.*
IF r_z24.z24_compania IS NULL THEN
	RETURN 0
END IF
IF tipo = 'P' THEN
	IF NOT genera_detalle_solicitud_cobro(r_z24.*, r_ret_p.*) THEN
		RETURN 0
	END IF
END IF
IF NOT actualiza_caja(r_z24.*) THEN
	RETURN 0
END IF
IF NOT actualiza_zona_cobr_z02(r_z24.*) THEN
	RETURN 0
END IF
LET vm_num_sol = r_z24.z24_numero_sol
RETURN 1

END FUNCTION



FUNCTION generar_cabecera_solicitud_cobro(tipo, r_ret_p)
DEFINE tipo		LIKE cxct024.z24_tipo
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE r_z24, r_sol	RECORD LIKE cxct024.*

INITIALIZE r_z24.* TO NULL
LET r_z24.z24_compania   = vg_codcia
LET r_z24.z24_localidad  = vg_codloc
WHILE TRUE
	SELECT NVL(MAX(z24_numero_sol), 0) + 1
		INTO r_z24.z24_numero_sol
		FROM cxct024
		WHERE z24_compania  = vg_codcia
		  AND z24_localidad = vg_codloc
	CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc,
					r_z24.z24_numero_sol)
		RETURNING r_sol.*
	IF r_sol.z24_numero_sol IS NULL THEN
		EXIT WHILE
	END IF
END WHILE
LET r_z24.z24_areaneg    = rm_par.z20_areaneg
LET r_z24.z24_linea      = rm_par.z20_linea
LET r_z24.z24_codcli     = rm_par.z20_codcli
LET r_z24.z24_tipo       = tipo
LET r_z24.z24_estado     = 'A'
LET r_z24.z24_referencia = 'SOLICITUD COBRO POR RETENCION'
IF tipo = 'A' THEN
	LET r_z24.z24_referencia = 'SOLICITUD COBRO X RETENCION A FAVOR'
END IF
LET r_z24.z24_moneda     = rm_par.z20_moneda
LET r_z24.z24_paridad    = rm_par.z20_paridad
LET r_z24.z24_tasa_mora  = 0
IF tipo = 'P' THEN
	SELECT NVL(SUM(valor_ret), 0)
		INTO r_z24.z24_total_cap
		FROM tmp_ret
		WHERE num_ret_sri IN
			(SELECT num_r_sri
				FROM tmp_det
				WHERE r38_num_sri   = num_fac_sri
				  AND z20_cod_tran  = cod_tr
				  AND z20_num_tran  = num_tr
				  AND z20_saldo_cap > 0)
		  --AND cod_pago    = r_ret_p.cod_pago
		  --AND tipo_ret    = r_ret_p.tipo_ret
		  --AND porc_ret    = r_ret_p.porc_ret
	UPDATE tmp_ret
		SET numero_sol = r_z24.z24_numero_sol
		WHERE num_ret_sri IN
			(SELECT num_r_sri
				FROM tmp_det
				WHERE r38_num_sri   = num_fac_sri
				  AND z20_cod_tran  = cod_tr
				  AND z20_num_tran  = num_tr
				  AND z20_saldo_cap > 0)
		  --AND cod_pago    = r_ret_p.cod_pago
		  --AND tipo_ret    = r_ret_p.tipo_ret
		  --AND porc_ret    = r_ret_p.porc_ret
ELSE
	SELECT NVL(SUM(valor_ret), 0)
		INTO r_z24.z24_total_cap
		FROM tmp_ret
		WHERE num_ret_sri = r_ret_p.num_ret_s
		  --AND cod_pago    = r_ret_p.cod_pago
		  --AND tipo_ret    = r_ret_p.tipo_ret
		  --AND porc_ret    = r_ret_p.porc_ret
	UPDATE tmp_ret
		SET numero_sol = r_z24.z24_numero_sol
		WHERE num_ret_sri = r_ret_p.num_ret_s
		  --AND cod_pago    = r_ret_p.cod_pago
		  --AND tipo_ret    = r_ret_p.tipo_ret
		  --AND porc_ret    = r_ret_p.porc_ret
END IF
LET r_z24.z24_total_int  = 0
LET r_z24.z24_total_mora = 0
LET r_z24.z24_zona_cobro = rm_par.z24_zona_cobro
IF rm_par.tipo_venta = 'C' THEN
	LET r_z24.z24_zona_cobro = NULL
END IF
LET r_z24.z24_subtipo    = 1
LET r_z24.z24_usuario    = vg_usuario
LET r_z24.z24_fecing     = fl_current()
INSERT INTO cxct024 VALUES (r_z24.*)
RETURN r_z24.*

END FUNCTION



FUNCTION genera_detalle_solicitud_cobro(r_z24, r_ret_p)
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z25		RECORD LIKE cxct025.*
DEFINE cod_tran		LIKE cxct020.z20_cod_tran
DEFINE num_tran		LIKE cxct020.z20_num_tran
DEFINE val_r		LIKE cxct020.z20_valor_cap
DEFINE intentar		SMALLINT
DEFINE done, i		SMALLINT

LET intentar = 1
LET done     = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
	DECLARE q_z25 CURSOR FOR
		SELECT * FROM cxct025
			WHERE z25_compania   = r_z24.z24_compania
			  AND z25_localidad  = r_z24.z24_localidad
			  AND z25_numero_sol = r_z24.z24_numero_sol
		FOR UPDATE
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done     = 1
	END IF
	WHENEVER ERROR STOP
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF
FOREACH q_z25
	DELETE FROM cxct025 WHERE CURRENT OF q_z25         
END FOREACH
LET r_z25.z25_compania   = r_z24.z24_compania
LET r_z25.z25_localidad  = r_z24.z24_localidad
LET r_z25.z25_numero_sol = r_z24.z24_numero_sol
LET r_z25.z25_codcli     = r_z24.z24_codcli
LET r_z25.z25_valor_mora = 0
LET r_z25.z25_valor_int  = 0
LET r_z25.z25_orden      = 0
FOR i = 1 TO vm_num_rows
	IF rm_detalle[i].valor_ret <= 0 OR rm_detalle[i].chequear = 'N' THEN
		CONTINUE FOR
	END IF
	DECLARE q_ret_det_sol CURSOR FOR
		SELECT cod_tr, num_tr, NVL(SUM(valor_ret), 0)
			FROM tmp_ret
			WHERE numero_sol  = r_z24.z24_numero_sol
			  AND num_fac_sri = rm_adi[i].num_sri
			  AND num_ret_sri = r_ret_p.num_ret_s
			  --AND cod_pago    = r_ret_p.cod_pago
			  --AND tipo_ret    = r_ret_p.tipo_ret
			  --AND porc_ret    = r_ret_p.porc_ret
			GROUP BY 1, 2
	FOREACH q_ret_det_sol INTO cod_tran, num_tran, val_r
		CALL fl_lee_documento_deudor_cxc(vg_codcia, r_z24.z24_localidad,
				r_z24.z24_codcli, rm_detalle[i].z20_tipo_doc,
				rm_adi[i].z20_num_doc, rm_adi[i].z20_dividendo)
			RETURNING r_z20.*
		IF r_z20.z20_saldo_cap <= 0 OR val_r < 0 THEN
			CONTINUE FOR
		END IF
		IF r_z20.z20_cod_tran = cod_tran AND
		   r_z20.z20_num_tran = num_tran
		THEN
			LET r_z25.z25_orden     = r_z25.z25_orden + 1
			LET r_z25.z25_tipo_doc  = rm_detalle[i].z20_tipo_doc
	    		LET r_z25.z25_num_doc   = rm_adi[i].z20_num_doc  
		    	LET r_z25.z25_dividendo = rm_adi[i].z20_dividendo
		    	--LET r_z25.z25_valor_cap = rm_detalle[i].valor_ret
		    	LET r_z25.z25_valor_cap = val_r
			INSERT INTO cxct025 VALUES (r_z25.*)
		END IF
	END FOREACH
END FOR
LET done = 1
UPDATE cxct024
	SET z24_total_cap =
		(SELECT NVL(SUM(z25_valor_cap), 0)
			FROM cxct025
			WHERE z25_compania   = z24_compania
			  AND z25_localidad  = z24_localidad
			  AND z25_numero_sol = z24_numero_sol)
	WHERE z24_compania   = r_z24.z24_compania
	  AND z24_localidad  = r_z24.z24_localidad
	  AND z24_numero_sol = r_z24.z24_numero_sol
RETURN done

END FUNCTION



FUNCTION actualiza_caja(r_z24)
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE intentar, done	SMALLINT

CALL fl_lee_cliente_general(r_z24.z24_codcli) RETURNING r_z01.*
LET intentar = 1
LET done     = 0
WHILE (intentar)
	WHENEVER ERROR CONTINUE
	DECLARE q_j10 CURSOR FOR
		SELECT * FROM cajt010
			WHERE j10_compania    = r_z24.z24_compania
			  AND j10_localidad   = r_z24.z24_localidad
			  AND j10_tipo_fuente = vm_tipo_fue
			  AND j10_num_fuente  =	r_z24.z24_numero_sol
		FOR UPDATE
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done     = 1
	END IF
	WHENEVER ERROR STOP
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF
OPEN q_j10
FETCH q_j10 INTO r_j10.*
IF STATUS = NOTFOUND THEN
	INITIALIZE r_j10.* TO NULL
	LET r_j10.j10_compania    = r_z24.z24_compania
	LET r_j10.j10_localidad   = r_z24.z24_localidad
	LET r_j10.j10_tipo_fuente = vm_tipo_fue
	LET r_j10.j10_num_fuente  = r_z24.z24_numero_sol
	LET r_j10.j10_areaneg     = r_z24.z24_areaneg
	LET r_j10.j10_estado      = 'A'
	LET r_j10.j10_codcli      = r_z24.z24_codcli
	LET r_j10.j10_nomcli      = r_z01.z01_nomcli
	LET r_j10.j10_moneda      = r_z24.z24_moneda
	SELECT NVL(SUM(z25_valor_cap), 0)
		INTO r_j10.j10_valor
		FROM cxct025
		WHERE z25_compania   = r_z24.z24_compania
		  AND z25_localidad  = r_z24.z24_localidad
		  AND z25_numero_sol = r_z24.z24_numero_sol
	IF r_j10.j10_valor = 0 THEN
		LET r_j10.j10_valor = r_z24.z24_total_cap + r_z24.z24_total_int
	END IF
	LET r_j10.j10_fecha_pro   = fl_current()
	LET r_j10.j10_codigo_caja = rm_j02.j02_codigo_caja
	LET r_j10.j10_usuario     = vg_usuario 
	LET r_j10.j10_fecing      = fl_current()
	INSERT INTO cajt010 VALUES(r_j10.*)
ELSE
	LET r_j10.j10_areaneg     = r_z24.z24_areaneg
	LET r_j10.j10_codcli      = r_z24.z24_codcli
	LET r_j10.j10_nomcli      = r_z01.z01_nomcli
	LET r_j10.j10_moneda      = r_z24.z24_moneda
	SELECT NVL(SUM(z25_valor_cap), 0)
		INTO r_j10.j10_valor
		FROM cxct025
		WHERE z25_compania   = r_z24.z24_compania
		  AND z25_localidad  = r_z24.z24_localidad
		  AND z25_numero_sol = r_z24.z24_numero_sol
	IF r_j10.j10_valor = 0 THEN
		LET r_j10.j10_valor = r_z24.z24_total_cap + r_z24.z24_total_int
	END IF
	LET r_j10.j10_fecha_pro   = fl_current()
	LET r_j10.j10_codigo_caja = rm_j02.j02_codigo_caja
	LET r_j10.j10_usuario     = vg_usuario
	LET r_j10.j10_fecing      = fl_current()
	UPDATE cajt010 SET * = r_j10.* WHERE CURRENT OF q_j10
END IF
CLOSE q_j10
FREE q_j10
RETURN done

END FUNCTION



FUNCTION actualiza_zona_cobr_z02(r_z24)
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE intentar		SMALLINT
DEFINE done    		SMALLINT
DEFINE r_z02		RECORD LIKE cxct002.*

LET intentar = 1
LET done = 0
CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc, r_z24.z24_codcli)
	RETURNING r_z02.*
IF r_z02.z02_zona_cobro IS NOT NULL THEN
	RETURN 1
END IF
WHILE (intentar)
	WHENEVER ERROR CONTINUE
		DECLARE q_z02 CURSOR FOR
			SELECT * FROM cxct002
				WHERE z02_compania  = vg_codcia
				  AND z02_localidad = vg_codloc
				  AND z02_codcli    = r_z02.z02_codcli
			FOR UPDATE
	WHENEVER ERROR STOP
	IF STATUS < 0 THEN
		LET intentar = mensaje_intentar()
	ELSE
		LET intentar = 0
		LET done = 1
	END IF
END WHILE
IF NOT intentar AND NOT done THEN
	RETURN done
END IF
OPEN q_z02
FETCH q_z02 INTO r_z02.*
UPDATE cxct002
	SET z02_zona_cobro = r_z24.z24_zona_cobro
	WHERE CURRENT OF q_z02
CLOSE q_z02
FREE q_z02
RETURN done

END FUNCTION



FUNCTION genera_forma_pago(r_ret_p, segundo)
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE segundo		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*

CALL graba_detalle_forma_pago(r_ret_p.*) RETURNING r_j10.*
IF r_j10.j10_compania IS NULL THEN
	RETURN 0
END IF
IF NOT generar_trans_pago(r_j10.*, segundo) THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION graba_detalle_forma_pago(r_ret_p)
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j11		RECORD LIKE cajt011.*
DEFINE secuencia 	LIKE cajt011.j11_secuencia

INITIALIZE r_j11.* TO NULL
CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fue, vm_num_sol)
	RETURNING r_j10.*
DECLARE q_for CURSOR FOR
	SELECT num_ret_sri, cod_pago, NVL(SUM(valor_ret), 0)
		FROM tmp_ret
		WHERE numero_sol  = vm_num_sol
		  AND num_ret_sri = r_ret_p.num_ret_s
		GROUP BY 1, 2
		ORDER BY 1, 2
LET secuencia = 1
FOREACH q_for INTO r_j11.j11_num_ch_aut, r_j11.j11_codigo_pago, r_j11.j11_valor
	LET r_j11.j11_compania    = r_j10.j10_compania
	LET r_j11.j11_localidad   = r_j10.j10_localidad
	LET r_j11.j11_tipo_fuente = r_j10.j10_tipo_fuente
	LET r_j11.j11_num_fuente  = r_j10.j10_num_fuente
	LET r_j11.j11_protestado  = 'N'
	LET r_j11.j11_secuencia   = secuencia
	LET r_j11.j11_moneda      = rm_par.z20_moneda
	LET r_j11.j11_paridad     = rm_par.z20_paridad
	LET secuencia             = secuencia + 1
	INSERT INTO cajt011 VALUES (r_j11.*)
	CALL grabar_detalle_retencion(r_j10.*, r_j11.j11_secuencia,
				r_j11.j11_codigo_pago, r_ret_p.*)
END FOREACH
RETURN r_j10.*

END FUNCTION



FUNCTION grabar_detalle_retencion(r_j10, secuencia, codigo_pago, r_ret_p)
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE secuencia	LIKE cajt011.j11_secuencia
DEFINE codigo_pago	LIKE cajt001.j01_codigo_pago
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE num_s		LIKE rept038.r38_num_sri
DEFINE cod_tran		LIKE rept019.r19_cod_tran
DEFINE num_tran		LIKE rept019.r19_num_tran
DEFINE cont_cred	LIKE rept019.r19_cont_cred
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE i		SMALLINT

INITIALIZE r_j14.* TO NULL
DECLARE q_ret2 CURSOR FOR
	SELECT num_ret_sri, autorizacion, fecha_emi, cod_pago, tipo_ret,
		porc_ret, codigo_sri, concepto_ret, base_imp, valor_ret,
		num_fac_sri, cod_tr, num_tr, fec_ini_porc
		FROM tmp_ret
		WHERE cod_pago    = codigo_pago
		  AND num_ret_sri = r_ret_p.num_ret_s
		 -- AND cod_pago    = r_ret_p.cod_pago
		 -- AND tipo_ret    = r_ret_p.tipo_ret
		 -- AND porc_ret    = r_ret_p.porc_ret
LET i = 1
FOREACH q_ret2 INTO r_j14.j14_num_ret_sri, r_j14.j14_autorizacion,
			r_j14.j14_fecha_emi, rm_detret[i].*, num_s, cod_tran,
			num_tran, fec_ini_por[i]
	LET r_j14.j14_compania     = vg_codcia
	LET r_j14.j14_localidad    = vg_codloc
	LET r_j14.j14_tipo_fuente  = r_j10.j10_tipo_fuente
	LET r_j14.j14_num_fuente   = r_j10.j10_num_fuente
	LET r_j14.j14_secuencia    = secuencia
	LET r_j14.j14_codigo_pago  = codigo_pago
	LET r_j14.j14_sec_ret      = i
	CALL fl_lee_cliente_general(r_j10.j10_codcli) RETURNING r_z01.*
	LET r_j14.j14_cedruc       = r_z01.z01_num_doc_id
	LET r_j14.j14_razon_social = r_j10.j10_nomcli
	LET r_j14.j14_num_fact_sri = num_s
	CASE rm_par.z20_areaneg
		WHEN 1
			CALL fl_lee_cabecera_transaccion_rep(vg_codcia,
						vg_codloc, cod_tran, num_tran)
				RETURNING r_r19.*
			IF r_r19.r19_compania IS NULL THEN
				CALL lee_cabecera_transaccion_loc(vg_codcia,
							vg_codloc,
							rm_adi[i].z20_cod_tran,
							rm_adi[i].z20_num_tran)
					RETURNING r_r19.*
			END IF
			LET r_j14.j14_fec_emi_fact = DATE(r_r19.r19_fecing)
			LET cont_cred              = r_r19.r19_cont_cred
		WHEN 2
			CALL fl_lee_factura_taller(vg_codcia,vg_codloc,num_tran)
				RETURNING r_t23.*
			LET r_j14.j14_fec_emi_fact = DATE(r_t23.t23_fec_factura)
			LET cont_cred              = r_t23.t23_cont_cred
	END CASE
	IF r_j14.j14_fec_emi_fact IS NULL THEN
		LET r_j14.j14_fec_emi_fact = vg_fecha
	END IF
	LET r_j14.j14_tipo_ret     = rm_detret[i].j14_tipo_ret
	LET r_j14.j14_porc_ret     = rm_detret[i].j14_porc_ret
	LET r_j14.j14_codigo_sri   = rm_detret[i].j14_codigo_sri
	LET r_j14.j14_fec_ini_porc = fec_ini_por[i]
	LET r_j14.j14_base_imp     = rm_detret[i].j14_base_imp
	LET r_j14.j14_valor_ret    = rm_detret[i].j14_valor_ret
	LET r_j14.j14_cont_cred    = cont_cred
	LET r_j14.j14_cod_tran     = cod_tran
	LET r_j14.j14_num_tran     = num_tran
	LET r_j14.j14_tipo_comp    = NULL
	LET r_j14.j14_num_comp     = NULL
	LET r_j14.j14_usuario      = vg_usuario
	LET r_j14.j14_fecing       = fl_current()
	INSERT INTO cajt014 VALUES (r_j14.*)
	LET i = i + 1
END FOREACH

END FUNCTION



FUNCTION generar_trans_pago(r_j10, segundo)
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE segundo		SMALLINT
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE resp		CHAR(10)
DEFINE comando		VARCHAR(80)

DEFINE fecha_actual DATETIME YEAR TO SECOND

LET fecha_actual = fl_current()

CALL valida_num_solicitud(r_j10.*) RETURNING r_z24.*
IF r_z24.z24_compania IS NULL THEN
	RETURN 0
END IF
CASE r_z24.z24_tipo
	WHEN 'P'
		CALL genera_ingreso_caja_pg(r_j10.*, r_z24.*, segundo)
			RETURNING r_z22.*
		IF r_z22.z22_compania IS NULL THEN
			RETURN 0
		END IF
		LET r_j10.j10_tipo_destino = r_z22.z22_tipo_trn
		LET r_j10.j10_num_destino  = r_z22.z22_num_trn
	WHEN 'A'
		CALL genera_ingreso_caja_pr(r_z24.*) RETURNING r_z21.*
		IF r_z21.z21_compania IS NULL THEN
			RETURN 0
		END IF
		LET r_j10.j10_tipo_destino = r_z21.z21_tipo_doc
		LET r_j10.j10_num_destino  = r_z21.z21_num_doc
END CASE
UPDATE cxct024
	SET z24_estado = 'P'
	WHERE CURRENT OF q_nsol 
CALL fl_genera_saldos_cliente(r_z24.z24_compania, r_z24.z24_localidad,
				r_z24.z24_codcli)
UPDATE cajt010
	SET j10_estado       = 'P',
	    j10_tipo_destino = r_j10.j10_tipo_destino,
	    j10_num_destino  = r_j10.j10_num_destino,
	    j10_fecha_pro    = fecha_actual
	WHERE CURRENT OF q_ccaj
RETURN 1

END FUNCTION



FUNCTION valida_num_solicitud(r_j10)
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_z24		RECORD LIKE cxct024.*

WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
DECLARE q_ccaj CURSOR FOR
	SELECT * FROM cajt010 
		WHERE j10_compania    = r_j10.j10_compania
		  AND j10_localidad   = r_j10.j10_localidad
		  AND j10_tipo_fuente = r_j10.j10_tipo_fuente
		  AND j10_num_fuente  = r_j10.j10_num_fuente
	FOR UPDATE 
OPEN q_ccaj 
FETCH q_ccaj INTO r_j10.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe solicitud en Caja.','exclamation')
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Registro de Caja esta bloqueado por otro usuario.','exclamation')
	EXIT PROGRAM
END IF
IF r_j10.j10_estado = "*" THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Registro en Caja tiene estado *','exclamation')
	EXIT PROGRAM
END IF
INITIALIZE r_z24.* TO NULL
DECLARE q_nsol CURSOR FOR
	SELECT * FROM cxct024
		WHERE z24_compania   = vg_codcia
		  AND z24_localidad  = vg_codloc
		  AND z24_numero_sol = vm_num_sol
	FOR UPDATE
OPEN q_nsol
FETCH q_nsol INTO r_z24.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe solicitud cobro.','exclamation')
	EXIT PROGRAM
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Solicitud cobro esta bloqueada por otro usuario.', 'exclamation')
	EXIT PROGRAM
END IF
IF r_z24.z24_estado <> 'A' THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Solicitud cobro no esta activa.','exclamation')
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
RETURN r_z24.*

END FUNCTION



FUNCTION genera_ingreso_caja_pg(r_j10, r_z24, segundo)
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE segundo		SMALLINT
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE r_z25		RECORD LIKE cxct025.*
DEFINE resul, i		SMALLINT
DEFINE resp		CHAR(6)
DEFINE intentar		INTEGER
DEFINE tot_cap		DECIMAL(14,2)
DEFINE tot_int		DECIMAL(14,2)
DEFINE tot_mora		DECIMAL(14,2)

SET LOCK MODE TO WAIT 1
INITIALIZE r_z22.* TO NULL
LET r_z22.z22_compania   = r_j10.j10_compania
LET r_z22.z22_localidad  = r_j10.j10_localidad
LET r_z22.z22_codcli     = r_z24.z24_codcli
LET r_z22.z22_tipo_trn   = vm_tipo_doc
CALL generar_secuencia_z22(r_z22.*) RETURNING resul, r_z22.z22_num_trn
IF NOT resul THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_z22.z22_areaneg    = r_j10.j10_areaneg
LET r_z22.z22_referencia = 'SOLIC. COBRO: ',
				r_z24.z24_numero_sol USING '#####&',
				' POR RETENCION.'
LET r_z22.z22_fecha_emi  = vg_fecha
LET r_z22.z22_moneda     = r_z24.z24_moneda
LET r_z22.z22_paridad    = r_z24.z24_paridad
LET r_z22.z22_tasa_mora  = 0
LET r_z22.z22_total_cap  = r_z24.z24_total_cap
LET r_z22.z22_total_int  = r_z24.z24_total_int
LET r_z22.z22_total_mora = r_z24.z24_total_mora
LET r_z22.z22_zona_cobro = r_z24.z24_zona_cobro
IF rm_par.tipo_venta = 'C' THEN
	LET r_z22.z22_zona_cobro = NULL
END IF
LET r_z22.z22_origen     = 'A'
LET r_z22.z22_usuario    = vg_usuario
LET r_z22.z22_fecing     = fl_current() + segundo UNITS SECOND
INSERT INTO cxct022 VALUES (r_z22.*)
DECLARE q_ddoc CURSOR FOR 
	SELECT * FROM cxct025
		WHERE z25_compania   = r_z24.z24_compania
		  AND z25_localidad  = r_z24.z24_localidad
		  AND z25_numero_sol = r_z24.z24_numero_sol
		ORDER BY z25_orden
LET i        = 0
LET tot_cap  = 0
LET tot_int  = 0
LET tot_mora = 0
FOREACH q_ddoc INTO r_z25.*
	IF r_z25.z25_valor_cap + r_z25.z25_valor_int <= 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor a pagar <= 0','stop')
		EXIT PROGRAM
	END IF
	CALL fl_lee_documento_deudor_cxc(r_z24.z24_compania,r_z24.z24_localidad,
			r_z22.z22_codcli, r_z25.z25_tipo_doc, r_z25.z25_num_doc,
			r_z25.z25_dividendo)
		RETURNING r_z20.*
	IF r_z20.z20_compania IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe documento: ' || r_z25.z25_tipo_doc || ' ' || r_z25.z25_num_doc || ' ' || r_z25.z25_dividendo, 'stop')
		EXIT PROGRAM
	END IF
	IF r_z25.z25_valor_cap > r_z20.z20_saldo_cap THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor capital a pagar mayor que saldo del documento: ' || r_z25.z25_tipo_doc || ' ' || r_z25.z25_num_doc || ' ' || r_z25.z25_dividendo, 'stop')
		EXIT PROGRAM
	END IF
	IF r_z25.z25_valor_int > r_z20.z20_saldo_int THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Valor interÃ©s a pagar mayor que saldo del documento: ' || r_z25.z25_tipo_doc || ' ' || r_z25.z25_num_doc || ' ' || r_z25.z25_dividendo, 'stop')
		EXIT PROGRAM
	END IF
	LET i = i + 1
	INITIALIZE r_z23.* TO NULL
    	LET r_z23.z23_compania 	 = r_z25.z25_compania
    	LET r_z23.z23_localidad  = r_z25.z25_localidad
    	LET r_z23.z23_codcli     = r_z24.z24_codcli
    	LET r_z23.z23_tipo_trn 	 = r_z22.z22_tipo_trn
    	LET r_z23.z23_num_trn 	 = r_z22.z22_num_trn
    	LET r_z23.z23_orden      = i
    	LET r_z23.z23_areaneg 	 = r_z22.z22_areaneg
    	LET r_z23.z23_tipo_doc 	 = r_z20.z20_tipo_doc
    	LET r_z23.z23_num_doc 	 = r_z20.z20_num_doc
    	LET r_z23.z23_div_doc 	 = r_z20.z20_dividendo
    	LET r_z23.z23_valor_cap  = r_z25.z25_valor_cap  * -1
    	LET r_z23.z23_valor_int  = r_z25.z25_valor_int  * -1
    	LET r_z23.z23_valor_mora = r_z25.z25_valor_mora * -1
    	LET r_z23.z23_saldo_cap  = r_z20.z20_saldo_cap 
    	LET r_z23.z23_saldo_int  = r_z20.z20_saldo_int
	LET tot_cap              = tot_cap  + r_z25.z25_valor_cap
	LET tot_int              = tot_int  + r_z25.z25_valor_int
	LET tot_mora             = tot_mora + r_z25.z25_valor_mora
	LET intentar = 1
	WHILE intentar
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO WAIT 1
		INSERT INTO cxct023 VALUES (r_z23.*)
		IF STATUS <> 0 THEN
			LET int_flag = 0
			CALL fl_hacer_pregunta('Se esta generando primero una transacción que esta actualizando el saldo del documento. Si desea intentar generar el PG nuevamente presione SI, de lo contrario presione NO.', 'Yes')
				RETURNING resp
			IF resp <> 'Yes' THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				EXIT PROGRAM
			END IF
			CONTINUE WHILE
		END IF
		LET intentar = 0
	END WHILE
	LET intentar = 1
	WHILE intentar
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO WAIT 1
		UPDATE cxct020
			SET z20_saldo_cap = z20_saldo_cap - r_z25.z25_valor_cap,
			    z20_saldo_int = z20_saldo_int - r_z25.z25_valor_int
			WHERE z20_compania  = r_z25.z25_compania
			  AND z20_localidad = r_z25.z25_localidad
			  AND z20_codcli    = r_z24.z24_codcli
			  AND z20_tipo_doc  = r_z20.z20_tipo_doc
			  AND z20_num_doc   = r_z20.z20_num_doc
			  AND z20_dividendo = r_z20.z20_dividendo
		IF STATUS <> 0 THEN
			LET int_flag = 0
			CALL fl_hacer_pregunta('Al momento otra transacción esta actualizando el saldo del documento. Si desea intentar generar el PG nuevamente presione SI, de lo contrario presione NO.', 'Yes')
				RETURNING resp
			IF resp <> 'Yes' THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				EXIT PROGRAM
			END IF
			CONTINUE WHILE
		END IF
		LET intentar = 0
	END WHILE
	WHENEVER ERROR STOP
END FOREACH	
IF tot_cap <> r_z24.z24_total_cap OR tot_int <> r_z24.z24_total_int THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No cuadran valores en cabecera y detalle de solicitud cobro.','stop')
	EXIT PROGRAM
END IF
RETURN r_z22.*

END FUNCTION



FUNCTION genera_ingreso_caja_pr(r_z24)
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE resul		SMALLINT

SET LOCK MODE TO WAIT 1
INITIALIZE r_z21.* TO NULL
LET vm_tipo_doc          = 'PR'
LET r_z21.z21_compania   = vg_codcia
LET r_z21.z21_localidad  = vg_codloc
LET r_z21.z21_codcli     = r_z24.z24_codcli
LET r_z21.z21_tipo_doc   = vm_tipo_doc
CALL generar_secuencia_z21(r_z21.*) RETURNING resul, r_z21.z21_num_doc
IF NOT resul THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET r_z21.z21_areaneg    = rm_par.z20_areaneg
LET r_z21.z21_linea      = r_z24.z24_linea
SELECT UNIQUE num_ret_sri
	INTO r_z21.z21_num_sri
	FROM tmp_ret
	WHERE numero_sol = r_z24.z24_numero_sol
LET r_z21.z21_referencia = 'DOC. RT P/ FA - SIN SALDO '--, r_z21.z21_cod_tran,
				--'-', r_z21.z21_num_tran USING "<<<<<<<&"
LET r_z21.z21_fecha_emi  = vg_fecha
LET r_z21.z21_moneda     = r_z24.z24_moneda
LET r_z21.z21_paridad    = r_z24.z24_paridad
LET r_z21.z21_val_impto  = 0
LET r_z21.z21_valor      = r_z24.z24_total_cap
LET r_z21.z21_saldo      = r_z24.z24_total_cap
LET r_z21.z21_subtipo    = r_z24.z24_subtipo
LET r_z21.z21_origen     = 'A'
LET r_z21.z21_usuario    = vg_usuario
LET r_z21.z21_fecing     = fl_current()
INSERT INTO cxct021 VALUES (r_z21.*)
RETURN r_z21.*

END FUNCTION



FUNCTION actualiza_acumulados_tipo_transaccion(flag)
DEFINE flag 		CHAR(1)
DEFINE codigo_pago	LIKE cajt011.j11_codigo_pago
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor		LIKE cajt013.j13_valor
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j13		RECORD LIKE cajt013.*

CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fue, vm_num_sol)
	RETURNING r_j10.*
DECLARE q_cajas_j13 CURSOR FOR
	SELECT j11_codigo_pago, j11_moneda, SUM(j11_valor)
		FROM cajt011
		WHERE j11_compania    = vg_codcia
		  AND j11_localidad   = vg_codloc
		  AND j11_tipo_fuente = r_j10.j10_tipo_fuente
		  AND j11_num_fuente  = r_j10.j10_num_fuente
	GROUP BY j11_codigo_pago, j11_moneda
FOREACH q_cajas_j13 INTO codigo_pago, moneda, valor
	IF flag = 'D' THEN
		LET valor = valor * (-1)
	END IF
	SET LOCK MODE TO WAIT 3
	WHENEVER ERROR CONTINUE
		DECLARE q_j13 CURSOR FOR 
			SELECT * FROM cajt013
				WHERE j13_compania     = vg_codcia
				  AND j13_localidad    = vg_codloc
				  AND j13_codigo_caja  = rm_j02.j02_codigo_caja
				  AND j13_fecha        = vg_fecha
				  AND j13_moneda       = moneda
				  AND j13_trn_generada = r_j10.j10_tipo_destino
				  AND j13_codigo_pago  = codigo_pago
			FOR UPDATE
	WHENEVER ERROR STOP
	SET LOCK MODE TO NOT WAIT
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pueden actualizar los acumulados.','exclamation')
		EXIT PROGRAM
	END IF
	INITIALIZE r_j13.* TO NULL
	OPEN q_j13
	FETCH q_j13 INTO r_j13.*
		IF STATUS = NOTFOUND THEN
			LET r_j13.j13_compania     = vg_codcia
			LET r_j13.j13_localidad    = vg_codloc
			LET r_j13.j13_codigo_caja  = rm_j02.j02_codigo_caja
			LET r_j13.j13_fecha        = vg_fecha
			LET r_j13.j13_moneda       = moneda
			LET r_j13.j13_trn_generada = r_j10.j10_tipo_destino
			LET r_j13.j13_codigo_pago  = codigo_pago
			LET r_j13.j13_valor        = valor
			INSERT INTO cajt013 VALUES(r_j13.*)
		ELSE
			UPDATE cajt013
				SET j13_valor = j13_valor + valor
				WHERE CURRENT OF q_j13
		END IF
	CLOSE q_j13
	FREE q_j13
END FOREACH

END FUNCTION



FUNCTION actualiza_detalle_retencion(flag)
DEFINE flag		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_j14		RECORD LIKE cajt014.*
DEFINE r_z40		RECORD LIKE cxct040.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE cont_cred	LIKE cajt014.j14_cont_cred
DEFINE expr_sql		CHAR(1500)
DEFINE expr_con		CHAR(400)
DEFINE query		CHAR(3500)

CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fue, vm_num_sol)
	RETURNING r_j10.*
IF NOT flag THEN
	DELETE FROM cajt014
		WHERE j14_compania    = vg_codcia
		  AND j14_localidad   = vg_codloc
		  AND j14_tipo_fuente = r_j10.j10_tipo_fuente
		  AND j14_num_fuente  = r_j10.j10_num_fuente
	RETURN
END IF
INITIALIZE r_j14.*, r_z40.* TO NULL
SELECT * INTO r_z40.*
	FROM cxct040
	WHERE z40_compania  = vg_codcia
	  AND z40_localidad = vg_codloc
	  AND z40_codcli    = r_j10.j10_codcli
	  AND z40_tipo_doc  = r_j10.j10_tipo_destino
	  AND z40_num_doc   = r_j10.j10_num_destino
LET r_j14.j14_tipo_comp = r_z40.z40_tipo_comp
LET r_j14.j14_num_comp  = r_z40.z40_num_comp
LET expr_sql = 'j14_tipo_doc  = (SELECT UNIQUE tipo_doc FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc= j14_fec_ini_porc), ',
		'j14_tipo_fue  = (SELECT UNIQUE tipo_fuente FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc= j14_fec_ini_porc), ',
		'j14_cod_tran  = (SELECT UNIQUE cod_tr FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc= j14_fec_ini_porc), ',
		'j14_num_tran  = (SELECT UNIQUE num_tr FROM tmp_ret ',
				'WHERE num_ret_sri = j14_num_ret_sri ',
				'  AND num_fac_sri = j14_num_fact_sri ',
				'  AND tipo_ret    = j14_tipo_ret ',
				'  AND porc_ret    = j14_porc_ret ',
				'  AND codigo_sri  = j14_codigo_sri ',
				'  AND fec_ini_porc= j14_fec_ini_porc) '
IF r_j10.j10_tipo_fuente <> 'SC' THEN
	LET expr_sql = 'j14_tipo_doc  = "', vm_tipo_doc, '", ',
			'j14_tipo_fue  = "', r_j10.j10_tipo_fuente CLIPPED,
					'", ',
			'j14_cod_tran  = "', r_j10.j10_tipo_destino CLIPPED,
					'", ',
			'j14_num_tran  = "', r_j10.j10_num_destino CLIPPED,
					'"'
END IF
LET expr_con = NULL
IF r_j14.j14_tipo_comp IS NOT NULL THEN
	LET expr_con = ',     j14_tipo_comp = "', r_j14.j14_tipo_comp CLIPPED,
			'", ',
			'     j14_num_comp  = "', r_j14.j14_num_comp CLIPPED,
			'" '
END IF
WHENEVER ERROR CONTINUE
LET query = 'UPDATE cajt014 ',
		' SET ', expr_sql CLIPPED,
			expr_con CLIPPED,
		' WHERE j14_compania    = ', vg_codcia,
		'   AND j14_localidad   = ', vg_codloc,
		'   AND j14_tipo_fuente = "', r_j10.j10_tipo_fuente, '"',
		'   AND j14_num_fuente  = ', r_j10.j10_num_fuente
PREPARE exec_j14 FROM query
EXECUTE exec_j14
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo actualizar en el detalle de retenciones (cajt014) los datos de la factura y el diario contable. Llame al ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
DECLARE q_j14_cr CURSOR FOR
	SELECT * FROM cajt014
		WHERE j14_compania    = vg_codcia
		  AND j14_localidad   = vg_codloc
		  AND j14_tipo_fuente = r_j10.j10_tipo_fuente
		  AND j14_num_fuente  = r_j10.j10_num_fuente
FOREACH q_j14_cr INTO r_j14.*
	CASE r_j10.j10_areaneg
		WHEN 1
			CALL lee_factura_inv(r_j14.j14_compania,
						r_j14.j14_localidad,
						r_j14.j14_cod_tran,
						r_j14.j14_num_tran)
				RETURNING r_r19.*
			LET cont_cred = r_r19.r19_cont_cred
		WHEN 2
			CALL fl_lee_factura_taller(r_j14.j14_compania,
							r_j14.j14_localidad,
							r_j14.j14_num_tran)
				RETURNING r_t23.*
			LET cont_cred = r_t23.t23_cont_cred
	END CASE
	IF cont_cred = 'R' THEN
		CONTINUE FOREACH
	END IF
	UPDATE cajt014
		SET j14_cont_cred = cont_cred
		WHERE j14_compania    = r_j14.j14_compania
		  AND j14_localidad   = r_j14.j14_localidad
		  AND j14_tipo_fuente = r_j14.j14_tipo_fuente
		  AND j14_num_fuente  = r_j14.j14_num_fuente
		  AND j14_secuencia   = r_j14.j14_secuencia
		  AND j14_codigo_pago = r_j14.j14_codigo_pago
		  AND j14_num_ret_sri = r_j14.j14_num_ret_sri
		  AND j14_sec_ret     = r_j14.j14_sec_ret
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se pudo actualizar en el tipo de pago de retenciones (cajt014) con datos de la factura. Llame al ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
END FOREACH
WHENEVER ERROR STOP

END FUNCTION



FUNCTION genera_documento_deudor(r_ret_p)
DEFINE r_ret_p		RECORD
				num_ret_s		CHAR(21),
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2)
			END RECORD
DEFINE r_ret		RECORD
				num_ret_sri		CHAR(21),
				autorizacion		VARCHAR(15,10),
				fecha_emi		DATE,
				cod_pago		CHAR(2),
				tipo_ret		CHAR(1),
				porc_ret		DECIMAL(5,2),
				codigo_sri		CHAR(6),
				concepto_ret		VARCHAR(200,100),
				base_imp		DECIMAL(12,2),
				valor_ret		DECIMAL(12,2),
				tipo_fuente		CHAR(2),
				cod_tr			CHAR(2),
				num_tr			VARCHAR(16),
				num_fac_sri		CHAR(21),
				tipo_doc		CHAR(2),
				numero_sol		INTEGER,
				fec_ini_p		DATE
			END RECORD
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE resul		SMALLINT

DECLARE q_di CURSOR FOR
	SELECT * FROM tmp_ret
		WHERE num_ret_sri = r_ret_p.num_ret_s
		  --AND cod_pago    = r_ret_p.cod_pago
		  --AND tipo_ret    = r_ret_p.tipo_ret
		  --AND porc_ret    = r_ret_p.porc_ret
FOREACH q_di INTO r_ret.*
	INITIALIZE r_z20.* TO NULL
	LET r_z20.z20_compania   = vg_codcia
	LET r_z20.z20_localidad  = vg_codloc
	LET r_z20.z20_codcli     = rm_par.z20_codcli
	LET r_z20.z20_tipo_doc   = 'DI'
	LET r_z20.z20_dividendo  = 1
	CALL generar_secuencia(r_z20.*) RETURNING resul, r_z20.z20_num_doc
	IF NOT resul THEN
		RETURN 0
	END IF
	LET r_z20.z20_areaneg    = rm_par.z20_areaneg
	LET r_z20.z20_referencia = 'DOC.RT ', r_ret_p.num_ret_s CLIPPED,
					' P/FA-SIN SALDO'
	LET r_z20.z20_fecha_emi  = vg_fecha
	LET r_z20.z20_fecha_vcto = r_z20.z20_fecha_emi + 1 UNITS DAY
	LET r_z20.z20_tasa_int   = 0 
	LET r_z20.z20_tasa_mora  = 0
	LET r_z20.z20_moneda     = rm_par.z20_moneda
	LET r_z20.z20_paridad    = rm_par.z20_paridad
	LET r_z20.z20_val_impto  = 0
	LET r_z20.z20_valor_cap  = r_ret.valor_ret
	LET r_z20.z20_valor_int  = 0
	LET r_z20.z20_saldo_cap  = r_z20.z20_valor_cap
	LET r_z20.z20_saldo_int  = 0
	LET r_z20.z20_cartera    = 1
	LET r_z20.z20_linea      = rm_par.z20_linea
	LET r_z20.z20_subtipo    = 1
	LET r_z20.z20_origen     = 'A'
	LET r_z20.z20_cod_tran   = r_ret.cod_tr
	LET r_z20.z20_num_tran   = r_ret.num_tr
	LET r_z20.z20_num_sri    = r_ret_p.num_ret_s
	LET r_z20.z20_usuario    = vg_usuario
	LET r_z20.z20_fecing     = fl_current()
	INSERT INTO cxct020 VALUES (r_z20.*)
END FOREACH
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_z20.z20_codcli)
RETURN 1

END FUNCTION



FUNCTION inserta_fecha_pro(num_ret_s)
DEFINE num_ret_s	CHAR(21)
DEFINE fecha		DATE

CALL retorna_fecha_pro(num_ret_s) RETURNING fecha
INSERT INTO tmp_doc
	VALUES (num_ret_s, vm_tipo_fue, vm_num_sol, NULL, NULL,NULL,NULL, fecha)

END FUNCTION



FUNCTION retorna_fecha_pro(num_ret_s)
DEFINE num_ret_s	CHAR(21)
DEFINE r_ret		RECORD
				fecha_emi	DATE,
				num_tr		VARCHAR(16),
				num_fac_sri	CHAR(21)
			END RECORD
DEFINE fecha		DATE
DEFINE i		SMALLINT

DECLARE q_fecha CURSOR FOR
	SELECT fecha_emi, num_tr, num_fac_sri
		FROM tmp_ret
		WHERE num_ret_sri = num_ret_s
FOREACH q_fecha INTO r_ret.*
	LET fecha = r_ret.fecha_emi
	FOR i = 1 TO vm_num_rows
		IF (rm_adi[i].num_sri = r_ret.num_fac_sri) AND
		   (rm_adi[i].z20_num_tran = r_ret.num_tr)
		THEN
			IF EXTEND(rm_detalle[i].z20_fecha_emi, YEAR TO MONTH) <>
			   EXTEND(r_ret.fecha_emi, YEAR TO MONTH)
			THEN
				LET fecha = rm_detalle[i].z20_fecha_emi
			END IF
		END IF
	END FOR
END FOREACH
RETURN fecha

END FUNCTION



FUNCTION generar_aplicacion_documentos(num_ret_s, segundo)
DEFINE num_ret_s	CHAR(21)
DEFINE segundo		SMALLINT
DEFINE r_j10		RECORD LIKE cajt010.*
DEFINE r_z20, r_z20_2	RECORD LIKE cxct020.*
DEFINE r_z21, r_z21_2	RECORD LIKE cxct021.*
DEFINE r_z22, r_z22_2	RECORD LIKE cxct022.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE mensaje		VARCHAR(200)
DEFINE resul		SMALLINT
DEFINE resp		CHAR(6)
DEFINE intentar		INTEGER

INITIALIZE r_z21.*, r_z22.*, r_z23.* TO NULL
CALL fl_lee_cabecera_caja(vg_codcia, vg_codloc, vm_tipo_fue, vm_num_sol)
	RETURNING r_j10.*
WHENEVER ERROR CONTINUE
DECLARE q_aplic CURSOR FOR
	SELECT * FROM cxct021
		WHERE z21_compania  = r_j10.j10_compania
		  AND z21_localidad = r_j10.j10_localidad
		  AND z21_codcli    = r_j10.j10_codcli
		  AND z21_tipo_doc  = r_j10.j10_tipo_destino
		  AND z21_num_doc   = r_j10.j10_num_destino
	FOR UPDATE
OPEN q_aplic
FETCH q_aplic INTO r_z21.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	LET mensaje = 'El documento ', r_j10.j10_tipo_destino, '-',
			r_j10.j10_num_destino USING "<<<<<<<&",
			' esta bloqueado por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0, r_z22.*
END IF
IF STATUS = NOTFOUND THEN
	WHENEVER ERROR STOP
	LET mensaje = 'El documento ', r_j10.j10_tipo_destino, '-',
			r_j10.j10_num_destino USING "<<<<<<<&",
			' ya no existe como documento. Llame al ADMINISTRADOR.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0, r_z22.*
END IF
WHENEVER ERROR STOP
LET r_z22.z22_compania   = vg_codcia
LET r_z22.z22_localidad  = vg_codloc
LET r_z22.z22_codcli     = r_j10.j10_codcli
LET r_z22.z22_tipo_trn   = 'AR'
CALL generar_secuencia_z22(r_z22.*) RETURNING resul, r_z22.z22_num_trn
IF NOT resul THEN
	RETURN 0, r_z22.*
END IF
LET r_z22.z22_areaneg    = r_j10.j10_areaneg
LET r_z22.z22_referencia = 'APLIC. COBRO: ',
				r_j10.j10_num_fuente USING '#####&',
				' EN RETENCIONES.'
LET r_z22.z22_fecha_emi  = vg_fecha
LET r_z22.z22_moneda     = r_j10.j10_moneda
LET r_z22.z22_paridad    = rm_par.z20_paridad
LET r_z22.z22_tasa_mora  = 0
LET r_z22.z22_total_cap  = 0
LET r_z22.z22_total_int  = 0
LET r_z22.z22_total_mora = 0
LET r_z22.z22_subtipo    = 1
LET r_z22.z22_origen     = 'A'
LET r_z22.z22_usuario    = vg_usuario
LET r_z22.z22_fecing     = fl_current() + segundo UNITS SECOND
INSERT INTO cxct022 VALUES (r_z22.*)
LET r_z23.z23_compania   = r_z22.z22_compania
LET r_z23.z23_localidad  = r_z22.z22_localidad
LET r_z23.z23_codcli     = r_z22.z22_codcli
LET r_z23.z23_tipo_trn   = r_z22.z22_tipo_trn
LET r_z23.z23_num_trn    = r_z22.z22_num_trn
LET r_z23.z23_orden      = 1
LET r_z23.z23_areaneg    = r_z22.z22_areaneg
LET r_z23.z23_valor_cap  = 0
LET r_z23.z23_valor_int  = 0
LET r_z23.z23_valor_mora = 0
LET r_z23.z23_saldo_cap  = 0
LET r_z23.z23_saldo_int  = 0
DECLARE q_di_aplic CURSOR FOR
	SELECT * FROM cxct020
		WHERE z20_compania  = r_z22.z22_compania
		  AND z20_localidad = r_z22.z22_localidad
		  AND z20_codcli    = r_z22.z22_codcli
		  AND z20_tipo_doc  = 'DI'
		  AND z20_num_sri   = num_ret_s
		  AND z20_saldo_cap > 0
LET resul = 1
FOREACH q_di_aplic INTO r_z20.*
	WHENEVER ERROR CONTINUE
	INITIALIZE r_z20_2.* TO NULL
	DECLARE q_proc CURSOR FOR
		SELECT * FROM cxct020
			WHERE z20_compania  = r_z20.z20_compania
			  AND z20_localidad = r_z20.z20_localidad
			  AND z20_codcli    = r_z20.z20_codcli
			  AND z20_tipo_doc  = r_z20.z20_tipo_doc
			  AND z20_num_doc   = r_z20.z20_num_doc
			  AND z20_dividendo = r_z20.z20_dividendo
		FOR UPDATE
	OPEN q_proc
	FETCH q_proc INTO r_z20_2.*
	IF STATUS < 0 THEN
		WHENEVER ERROR STOP
		LET mensaje = 'El documento ', r_z20_2.z20_tipo_doc CLIPPED,
				' ', r_z20_2.z20_num_doc CLIPPED, '-',
				r_z20_2.z20_dividendo CLIPPED USING '&&',
				' del cliente esta siendo modificado por otro ',
				'usuario.'
		CALL fl_mostrar_mensaje(mensaje, 'exclamation')
		LET resul = 0
		EXIT FOREACH
	END IF
	WHENEVER ERROR STOP
	IF r_z20_2.z20_saldo_cap = 0 THEN
		CONTINUE FOREACH
	END IF
	LET r_z23.z23_tipo_doc   = r_z20.z20_tipo_doc
	LET r_z23.z23_num_doc    = r_z20.z20_num_doc
	LET r_z23.z23_div_doc    = r_z20.z20_dividendo
	LET r_z23.z23_tipo_favor = r_z21.z21_tipo_doc
	LET r_z23.z23_doc_favor  = r_z21.z21_num_doc
	LET r_z23.z23_saldo_cap  = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
	LET r_z23.z23_saldo_int  = r_z20.z20_saldo_int
	IF r_z20_2.z20_saldo_cap <> r_z23.z23_saldo_cap THEN
		CALL fl_mostrar_mensaje('No puede realizar el ajuste de documentos al cliente en este momento.', 'stop')
		LET resul = 0
		EXIT FOREACH
	END IF
	LET r_z23.z23_valor_cap  = r_z23.z23_saldo_cap * (-1)
	LET r_z23.z23_valor_int  = r_z23.z23_saldo_int * (-1)
	LET r_z22.z22_total_cap  = r_z22.z22_total_cap + r_z23.z23_valor_cap
	LET r_z22.z22_total_int  = r_z22.z22_total_int + r_z23.z23_valor_int
	LET intentar = 1
	WHILE intentar
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO WAIT 1
		INSERT INTO cxct023 VALUES(r_z23.*)
		IF STATUS <> 0 THEN
			LET int_flag = 0
			CALL fl_hacer_pregunta('Se esta generando primero una transacción que esta actualizando el saldo del documento. Si desea intentar generar el AJ nuevamente presione SI, de lo contrario presione NO.', 'Yes')
				RETURNING resp
			IF resp <> 'Yes' THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				EXIT PROGRAM
			END IF
			CONTINUE WHILE
		END IF
		LET intentar = 0
	END WHILE
	LET r_z23.z23_orden = r_z23.z23_orden + 1
	LET intentar = 1
	WHILE intentar
		WHENEVER ERROR CONTINUE
		SET LOCK MODE TO WAIT 1
		UPDATE cxct020
			SET z20_saldo_cap = z20_saldo_cap + r_z23.z23_valor_cap,
			    z20_saldo_int = z20_saldo_int + r_z23.z23_valor_int
			WHERE CURRENT OF q_proc
		IF STATUS <> 0 THEN
			LET int_flag = 0
			CALL fl_hacer_pregunta('Al momento otra transacción esta actualizando el saldo del documento. Si desea intentar generar el AJ nuevamente presione SI, de lo contrario presione NO.', 'Yes')
				RETURNING resp
			IF resp <> 'Yes' THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				EXIT PROGRAM
			END IF
			CONTINUE WHILE
		END IF
		LET intentar = 0
	END WHILE
	WHENEVER ERROR STOP
	CLOSE q_proc
	FREE q_proc
END FOREACH
WHENEVER ERROR CONTINUE
DECLARE q_up2 CURSOR FOR
	SELECT * FROM cxct022
		WHERE z22_compania  = r_z22.z22_compania
		  AND z22_localidad = r_z22.z22_localidad
		  AND z22_codcli    = r_z22.z22_codcli
		  AND z22_tipo_trn  = r_z22.z22_tipo_trn
		  AND z22_num_trn   = r_z22.z22_num_trn
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_z22_2.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	LET mensaje = 'La transaccion ', r_z22_2.z22_tipo_trn CLIPPED,
			'-', r_z22_2.z22_num_trn USING "<<<<<<&",
			' esta siendo modificada por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0, r_z22.*
END IF
WHENEVER ERROR STOP
UPDATE cxct022
	SET z22_total_cap = r_z22.z22_total_cap,
	    z22_total_int = r_z22.z22_total_int
	WHERE CURRENT OF q_up2
CLOSE q_up2
FREE q_up2
WHENEVER ERROR CONTINUE
DECLARE q_up3 CURSOR FOR
	SELECT * FROM cxct021
		WHERE z21_compania  = r_z21.z21_compania
		  AND z21_localidad = r_z21.z21_localidad
		  AND z21_codcli    = r_z21.z21_codcli
		  AND z21_tipo_doc  = r_z21.z21_tipo_doc
		  AND z21_num_doc   = r_z21.z21_num_doc
	FOR UPDATE
OPEN q_up3
FETCH q_up3 INTO r_z21_2.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	LET mensaje = 'El documento ', r_z21_2.z21_tipo_doc CLIPPED,
			'-', r_z21_2.z21_num_doc USING "<<<<<<&",
			' esta siendo modificado por otro usuario.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 0, r_z22.*
END IF
WHENEVER ERROR STOP
UPDATE cxct021
	SET z21_saldo = z21_saldo + r_z22.z22_total_cap
	WHERE CURRENT OF q_up3
CLOSE q_up3
FREE q_up3
CALL fl_genera_saldos_cliente(vg_codcia, vg_codloc, r_z22.z22_codcli)
RETURN resul, r_z22.*

END FUNCTION



FUNCTION generar_egreso_efectivo_caja(num_ret_s)
DEFINE num_ret_s	CHAR(21)
DEFINE r_j05		RECORD LIKE cajt005.*
DEFINE r_j10, r_j10_2	RECORD LIKE cajt010.*
DEFINE r_j13		RECORD LIKE cajt013.*
DEFINE resul, salir	SMALLINT

LET resul = 1
INITIALIZE r_j05.*, r_j10.*, r_j13.* TO NULL
LET r_j10.j10_compania     = vg_codcia
LET r_j10.j10_localidad    = vg_codloc
LET r_j10.j10_tipo_fuente  = 'EC'
WHILE TRUE
	SELECT NVL(MAX(j10_num_fuente) + 1, 1)
		INTO r_j10.j10_num_fuente
		FROM cajt010
		WHERE j10_compania    = r_j10.j10_compania
		  AND j10_localidad   = r_j10.j10_localidad
		  AND j10_tipo_fuente = r_j10.j10_tipo_fuente
	CALL fl_lee_cabecera_caja(r_j10.j10_compania, r_j10.j10_localidad,
				r_j10.j10_tipo_fuente, r_j10.j10_num_fuente)
		RETURNING r_j10_2.*
	IF r_j10_2.j10_compania IS NULL THEN
		EXIT WHILE
	END IF
END WHILE
LET r_j10.j10_areaneg      = rm_par.z20_areaneg
LET r_j10.j10_estado       = 'P'
LET r_j10.j10_codcli       = rm_par.z20_codcli
LET r_j10.j10_nomcli       = rm_par.z01_nomcli
LET r_j10.j10_moneda       = rm_par.z20_moneda
SELECT NVL(SUM(valor_ret), 0)
	INTO r_j10.j10_valor
	FROM tmp_ret
	WHERE num_ret_sri = num_ret_s
LET r_j10.j10_fecha_pro    = fl_current()
LET r_j10.j10_codigo_caja  = rm_j02.j02_codigo_caja 
LET r_j10.j10_tipo_destino = r_j10.j10_tipo_fuente
LET r_j10.j10_num_destino  = r_j10.j10_num_fuente
LET r_j10.j10_referencia   = 'EGRESO DE CAJA # ',
				r_j10.j10_num_fuente USING "<<<<<<&",
				'. POR DEVOLUCION DE EFECTIVO EN RETENCIONES.'
LET r_j10.j10_banco        = 0
LET r_j10.j10_numero_cta   = 0
LET r_j10.j10_fecing       = fl_current()
LET r_j10.j10_usuario      = vg_usuario
INSERT INTO cajt010 VALUES (r_j10.*)
WHENEVER ERROR CONTINUE
DECLARE q_j05 CURSOR FOR
	SELECT * FROM cajt005
		WHERE j05_compania    = r_j10.j10_compania
		  AND j05_localidad   = r_j10.j10_localidad
		  AND j05_codigo_caja = r_j10.j10_codigo_caja
		  AND j05_fecha_aper  = rm_j04.j04_fecha_aper
		  AND j05_secuencia   = rm_j04.j04_secuencia
		  AND j05_moneda      = r_j10.j10_moneda
	FOR UPDATE
OPEN q_j05
FETCH q_j05 INTO r_j05.*
IF STATUS = NOTFOUND THEN 
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('La caja no esta aperturada.', 'exclamation')
	RETURN 0, r_j10.*
END IF
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('La caja esta bloqueada por otro usuario.', 'exclamation')
	RETURN 0, r_j10.*
END IF
UPDATE cajt005
	SET j05_ef_egr_dia = j05_ef_egr_dia + r_j10.j10_valor
	WHERE CURRENT OF q_j05
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mostrar_mensaje('No se pudo actualizar los acumulados de caja. Llame al ADMINISTRADOR.', 'exclamation')
	RETURN 0, r_j10.*
END IF
WHENEVER ERROR STOP
LET salir = 0
WHILE NOT salir
	SET LOCK MODE TO WAIT 1
	WHENEVER ERROR CONTINUE
	DECLARE q_j13_2 CURSOR FOR 
		SELECT * FROM cajt013
			WHERE j13_compania     = r_j10.j10_compania
			  AND j13_localidad    = r_j10.j10_localidad
			  AND j13_codigo_caja  = r_j10.j10_codigo_caja
			  AND j13_fecha        = vg_fecha
	 		  AND j13_moneda       = r_j10.j10_moneda
			  AND j13_trn_generada = r_j10.j10_tipo_fuente
			  AND j13_codigo_pago  = 'EF'
		FOR UPDATE
	OPEN q_j13_2
	FETCH q_j13_2 INTO r_j13.*
	IF STATUS < 0 THEN
		SET LOCK MODE TO NOT WAIT
		CALL fl_mostrar_mensaje('No se pueden actualizar los acumulados.', 'stop')
		WHENEVER ERROR STOP
		LET resul = 0
		LET salir = 1
		CONTINUE WHILE
	END IF
	IF (STATUS <> NOTFOUND) THEN
		UPDATE cajt013
			SET j13_valor = j13_valor + r_j10.j10_valor
			WHERE CURRENT OF q_j13_2
		IF STATUS < 0 THEN
			WHENEVER ERROR STOP
			CALL fl_mostrar_mensaje('No se pudo actualizar los acumulados de efectivo del dia. Llame al ADMINISTRADOR.', 'exclamation')
			LET resul = 0
			LET salir = 1
			CONTINUE WHILE
		END IF
	ELSE
		INSERT INTO cajt013
			VALUES(r_j10.j10_compania, r_j10.j10_localidad,
				r_j10.j10_codigo_caja, vg_fecha, r_j10.j10_moneda,
				r_j10.j10_tipo_fuente, 'EF', r_j10.j10_valor)
	END IF
	CLOSE q_j13_2
	FREE q_j13_2
	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR STOP
	LET salir = 1
END WHILE
RETURN resul, r_j10.*

END FUNCTION



FUNCTION generar_secuencia(r_z20)
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE num_doc		LIKE cxct020.z20_num_doc
DEFINE resul		INTEGER

LET num_doc = NULL
WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', r_z20.z20_tipo_doc)
		RETURNING num_doc
	IF num_doc <= 0 THEN
		LET resul = 0
		EXIT WHILE
	END IF
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc, r_z20.z20_codcli,
					r_z20.z20_tipo_doc, num_doc,
					r_z20.z20_dividendo)
		RETURNING r_z20.*
	IF r_z20.z20_compania IS NULL THEN
		LET resul = 1
		EXIT WHILE
	END IF
END WHILE
RETURN resul, num_doc

END FUNCTION



FUNCTION generar_secuencia_z21(r_z21)
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE num_trn		LIKE cxct021.z21_num_doc
DEFINE resul		INTEGER

LET num_trn = NULL
WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', r_z21.z21_tipo_doc)
		RETURNING num_trn
	IF num_trn <= 0 THEN
		LET resul = 0
		EXIT WHILE
	END IF
	CALL fl_lee_documento_favor_cxc(vg_codcia, vg_codloc, r_z21.z21_codcli,
					r_z21.z21_tipo_doc, num_trn)
		RETURNING r_z21.*
	IF r_z21.z21_compania IS NULL THEN
		LET resul = 1
		EXIT WHILE
	END IF
END WHILE
RETURN resul, num_trn

END FUNCTION



FUNCTION generar_secuencia_z22(r_z22)
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE num_trn		LIKE cxct022.z22_num_trn
DEFINE resul		INTEGER

LET num_trn = NULL
WHILE TRUE
	CALL fl_actualiza_control_secuencias(vg_codcia, vg_codloc, vg_modulo,
						'AA', r_z22.z22_tipo_trn)
		RETURNING num_trn
	IF num_trn <= 0 THEN
		LET resul = 0
		EXIT WHILE
	END IF
	CALL fl_lee_transaccion_cxc(vg_codcia, vg_codloc, r_z22.z22_codcli,
					r_z22.z22_tipo_trn, num_trn)
		RETURNING r_z22.*
	IF r_z22.z22_compania IS NULL THEN
		LET resul = 1
		EXIT WHILE
	END IF
END WHILE
RETURN resul, num_trn

END FUNCTION



FUNCTION imprime_comprobante(num_sol)
DEFINE num_sol		LIKE cxct024.z24_numero_sol
DEFINE r_z24		RECORD LIKE cxct024.*
DEFINE comando		VARCHAR(250)
DEFINE run_prog, prog	CHAR(10)

INITIALIZE comando TO NULL
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
CALL fl_lee_solicitud_cobro_cxc(vg_codcia, vg_codloc, num_sol) RETURNING r_z24.*
IF r_z24.z24_tipo = 'A' THEN
	LET prog = 'cajp401 '
ELSE
	LET prog = 'cajp400 '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CAJA', vg_separador,
		'fuentes', vg_separador, run_prog, prog, vg_base,' "CG" ',
		vg_codcia, ' ', vg_codloc, ' ', num_sol
RUN comando

END FUNCTION



FUNCTION imprime_contabilizacion()
DEFINE r_z22		RECORD LIKE cxct022.*
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE resp		CHAR(6)

CALL fl_hacer_pregunta('Desea imprimir la contabilizacion generada ?', 'No')
	RETURNING resp
IF resp <> 'Yes' THEN
	RETURN
END IF
DECLARE q_imp_c1 CURSOR FOR
	SELECT UNIQUE tipo_sol, num_sol
		FROM tmp_doc
		ORDER BY 1, 2
FOREACH q_imp_c1 INTO vm_tipo_fue, vm_num_sol
	INITIALIZE tipo_comp, num_comp TO NULL
	SELECT z40_tipo_comp, z40_num_comp
		INTO tipo_comp, num_comp
		FROM cajt010, cxct040
		WHERE j10_compania    = vg_codcia
		  AND j10_localidad   = vg_codloc
		  AND j10_tipo_fuente = vm_tipo_fue
		  AND j10_num_fuente  = vm_num_sol
		  AND z40_compania    = j10_compania
		  AND z40_localidad   = j10_localidad
		  AND z40_codcli      = j10_codcli
		  AND z40_tipo_doc    = j10_tipo_destino
		  AND z40_num_doc     = j10_num_destino
	IF tipo_comp IS NULL THEN
		CONTINUE FOREACH
	END IF
	CALL imprime_diario(tipo_comp, num_comp)
END FOREACH
DECLARE q_imp_c2 CURSOR FOR
	SELECT UNIQUE tip_trn, num_trn
		FROM tmp_doc
		ORDER BY 1, 2
FOREACH q_imp_c2 INTO r_z22.z22_tipo_trn, r_z22.z22_num_trn
	INITIALIZE tipo_comp, num_comp TO NULL
	SELECT z40_tipo_comp, z40_num_comp
		INTO tipo_comp, num_comp
		FROM cxct040
		WHERE z40_compania  = vg_codcia
		  AND z40_localidad = vg_codloc
		  AND z40_codcli    = rm_par.z20_codcli
		  AND z40_tipo_doc  = r_z22.z22_tipo_trn
		  AND z40_num_doc   = r_z22.z22_num_trn
	IF tipo_comp IS NULL THEN
		CONTINUE FOREACH
	END IF
	CALL imprime_diario(tipo_comp, num_comp)
END FOREACH

END FUNCTION



FUNCTION imprime_diario(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE comando		VARCHAR(250)
DEFINE run_prog		CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'TESORERIA',
		vg_separador, 'fuentes', vg_separador, run_prog, 'cxpp403 ',
		vg_base, ' TE ', vg_codcia, ' ', vg_codloc, ' "', tipo_comp,
		'" ', num_comp
RUN comando

END FUNCTION



FUNCTION mensaje_intentar()
DEFINE intentar		SMALLINT
DEFINE resp		CHAR(6)

LET intentar = 1
CALL fl_hacer_pregunta('Registro bloqueado por otro usuario, desea intentarlo nuevamente','No')
	RETURNING resp
IF resp = 'No' THEN
	CALL fl_mensaje_abandonar_proceso() RETURNING resp
	IF resp = 'Yes' THEN
		LET intentar = 0
	END IF	
END IF
RETURN intentar

END FUNCTION



FUNCTION obtener_grupo(areaneg)
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE r_g20		RECORD LIKE gent020.*

INITIALIZE r_g20.* TO NULL
DECLARE q_g20 CURSOR FOR
	SELECT * FROM gent020
		WHERE g20_compania = vg_codcia
		  AND g20_areaneg  = areaneg
OPEN q_g20
FETCH q_g20 INTO r_g20.*
CLOSE q_g20
FREE q_g20
RETURN r_g20.*

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

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
DISPLAY '<F5>      Ver Factura'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Retenciones'              AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F7>      Transaccion'              AT a,2
DISPLAY  'F7' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F8>      Imprimir'                 AT a,2
DISPLAY  'F8' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
