DATABASE acero_qm
DEFINE vm_codcia		SMALLINT
DEFINE vm_codloc_mat		SMALLINT
DEFINE vm_codloc_age		SMALLINT
DEFINE vm_tipo_doc, vm_tipo_trn	CHAR(2)

MAIN

CALL startlog('errores')
LET vm_codcia     = 1
LET vm_codloc_mat = 3
LET vm_codloc_age = 4
LET vm_tipo_doc   = 'NC'
LET vm_tipo_trn   = 'AJ'
delete from tr_cxct001 where 1 = 1;
delete from tr_cxct002 where 1 = 1;
delete from tr_cxct020 where 1 = 1;
delete from tr_cxct021 where 1 = 1;
delete from tr_cxct022 where 1 = 1;
delete from tr_cxct023 where 1 = 1;
load from 'tr_cxct001.txt' insert into tr_cxct001;
load from 'tr_cxct002.txt' insert into tr_cxct002;
load from 'tr_cxct020.txt' insert into tr_cxct020;
load from 'tr_cxct021.txt' insert into tr_cxct021;
load from 'tr_cxct022.txt' insert into tr_cxct022;
load from 'tr_cxct023.txt' insert into tr_cxct023;
update tr_cxct001 set z01_usuario = 'FOBOS' where 1 = 1;
update tr_cxct002 set z02_usuario = 'FOBOS' where 1 = 1;
update tr_cxct020 set z20_usuario = 'FOBOS' where 1 = 1;
update tr_cxct021 set z21_usuario = 'FOBOS' where 1 = 1;
update tr_cxct022 set z22_usuario = 'FOBOS' where 1 = 1;
BEGIN WORK
CALL carga_cartera_sur_a_matriz()
CALL carga_notas_credito()
CALL recalcula_saldo_doc(vm_codloc_age)
COMMIT WORK

END MAIN



FUNCTION carga_cartera_sur_a_matriz()
DEFINE r_z20		RECORD LIKE tr_cxct020.*

SET LOCK MODE TO WAIT
DECLARE q_doc CURSOR FOR SELECT * FROM tr_cxct020
FOREACH q_doc INTO r_z20.*
	DISPLAY r_z20.z20_tipo_doc, ' ', r_z20.z20_num_doc
	CALL verifica_cliente(r_z20.z20_compania, r_z20.z20_localidad, 
			      r_z20.z20_codcli)
	SELECT * FROM cxct020 
		WHERE z20_compania  = r_z20.z20_compania  AND 
		      z20_localidad = r_z20.z20_localidad AND 
		      z20_codcli    = r_z20.z20_codcli    AND 
		      z20_tipo_doc  = r_z20.z20_tipo_doc  AND 
		      z20_num_doc   = r_z20.z20_num_doc   AND 
		      z20_dividendo = r_z20.z20_dividendo
	IF status <> NOTFOUND THEN
		DISPLAY 'Ya existe documento en cxct020.'
		CONTINUE FOREACH
	END IF
	INSERT INTO cxct020 VALUES (r_z20.*)
	CALL fl_genera_saldos_cliente(r_z20.z20_compania, r_z20.z20_localidad,
				      r_z20.z20_codcli)
END FOREACH

END FUNCTION



FUNCTION carga_notas_credito()
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z21		RECORD LIKE tr_cxct021.*
DEFINE r_z22		RECORD LIKE tr_cxct022.*
DEFINE r_z23		RECORD LIKE tr_cxct023.*
DEFINE i		SMALLINT
DEFINE num_reg		INTEGER
DEFINE num_reg_sec	INTEGER
DEFINE num_min		INTEGER
DEFINE num_act		INTEGER
DEFINE incremento	SMALLINT
DEFINE valor		DECIMAL(12,2)

SET LOCK MODE TO WAIT
DECLARE qu_vnc CURSOR FOR SELECT ROWID, * FROM tr_cxct021
	WHERE z21_tipo_doc = vm_tipo_doc AND z21_localidad = vm_codloc_age
FOREACH qu_vnc INTO num_reg, r_z21.*
	DISPLAY 'Verificando: ', r_z21.z21_tipo_doc, ' ', r_z21.z21_num_doc
	SELECT * FROM cxct021 
		WHERE z21_compania  = r_z21.z21_compania  AND 
	              z21_localidad = r_z21.z21_localidad AND 
	              z21_codcli    = r_z21.z21_codcli    AND 
	              z21_tipo_doc  = r_z21.z21_tipo_doc  AND 
	              z21_num_doc   = r_z21.z21_num_doc
	IF status <> NOTFOUND THEN
		DELETE FROM tr_cxct021 WHERE ROWID = num_reg	
	END IF
	CALL verifica_cliente(r_z21.z21_compania, r_z21.z21_localidad, 
			      r_z21.z21_codcli)
	SELECT * FROM cxct002 
		WHERE z02_compania  = r_z21.z21_compania  AND 
		      z02_localidad = r_z21.z21_localidad AND 
		      z02_codcli    = r_z21.z21_codcli
	IF status = NOTFOUND THEN
		DISPLAY 'Borrando de tr_cxct021...'
		DELETE FROM tr_cxct021 WHERE ROWID = num_reg	
	END IF
END FOREACH
DECLARE qu_vtr CURSOR FOR SELECT ROWID, * FROM tr_cxct022
	WHERE z22_tipo_trn = vm_tipo_doc AND z22_localidad = vm_codloc_age
FOREACH qu_vtr INTO num_reg, r_z22.*
	SELECT * FROM cxct022 
		WHERE z22_compania  = r_z22.z22_compania  AND 
	              z22_localidad = r_z22.z22_localidad AND 
	              z22_codcli    = r_z22.z22_codcli    AND 
	              z22_tipo_trn  = r_z22.z22_tipo_trn  AND 
                      z22_fecing    = r_z22.z22_fecing    AND
		      z22_total_cap = r_z22.z22_total_cap
	IF status <> NOTFOUND THEN
		DELETE FROM tr_cxct022 WHERE ROWID = num_reg	
		DELETE FROM tr_cxct023
			WHERE z23_compania  = r_z22.z22_compania  AND 
	                      z23_localidad = r_z22.z22_localidad AND 
	                      z23_codcli    = r_z22.z22_codcli    AND 
	                      z23_tipo_trn  = r_z22.z22_tipo_trn  AND 
	                      z23_num_trn   = r_z22.z22_num_trn
	END IF
END FOREACH
SELECT MIN(z22_num_trn) INTO num_min FROM tr_cxct022
	WHERE z22_tipo_trn = vm_tipo_trn
IF num_min IS NULL THEN
	RETURN
END IF
LET num_act = NULL
SELECT ROWID, g15_numero INTO num_reg_sec, num_act FROM gent015
	WHERE g15_compania  = vm_codcia     AND 
	      g15_localidad = vm_codloc_age AND 
	      g15_modulo    = 'CO'          AND 
	      g15_tipo      = vm_tipo_trn
IF num_act IS NULL THEN
	RETURN
END IF
IF num_min <= num_act THEN
	LET incremento = num_act - num_min + 1
	DECLARE rt CURSOR FOR 
		SELECT ROWID, * FROM tr_cxct022 WHERE z22_tipo_trn = vm_tipo_trn
			ORDER BY z22_num_trn DESC
	FOREACH rt INTO num_reg, r_z22.*
		UPDATE tr_cxct022 SET z22_num_trn = z22_num_trn + incremento
			WHERE ROWID = num_reg
		UPDATE tr_cxct023 SET z23_num_trn = z23_num_trn + incremento
			WHERE z23_compania  = r_z22.z22_compania  AND 
		              z23_localidad = r_z22.z22_localidad AND 
		              z23_codcli    = r_z22.z22_codcli    AND 
		              z23_tipo_trn  = r_z22.z22_tipo_trn  AND 
		              z23_num_trn   = r_z22.z22_num_trn
	END FOREACH
END IF
DECLARE q_nc CURSOR FOR SELECT * FROM tr_cxct021
	WHERE z21_tipo_doc = vm_tipo_doc AND z21_localidad = vm_codloc_age
	ORDER BY z21_fecing
FOREACH q_nc INTO r_z21.*
	--DISPLAY r_z21.z21_tipo_doc, ' ', r_z21.z21_num_doc
	INSERT INTO cxct021 VALUES (r_z21.*)
	DECLARE qu_dmov CURSOR FOR 
		SELECT * FROM tr_cxct023
			WHERE z23_compania   = r_z21.z21_compania   AND 
			      z23_localidad  = r_z21.z21_localidad  AND 
			      z23_codcli     = r_z21.z21_codcli     AND 
			      z23_tipo_favor = r_z21.z21_tipo_doc   AND 
			      z23_doc_favor  = r_z21.z21_num_doc   
			ORDER BY z23_orden
	LET i = 0
	FOREACH qu_dmov INTO r_z23.*
		SELECT ROWID, * INTO num_reg, r_z20.* FROM cxct020 
			WHERE z20_compania  = r_z23.z23_compania  AND 
		              z20_localidad = r_z23.z23_localidad AND 
		              z20_codcli    = r_z23.z23_codcli    AND 
		              z20_tipo_doc  = r_z23.z23_tipo_doc  AND 
		              z20_num_doc   = r_z23.z23_num_doc   AND 
		              z20_dividendo = r_z23.z23_div_doc
		IF status = NOTFOUND THEN
			CONTINUE FOREACH
		END IF
		LET i = i + 1
		LET r_z20.z20_saldo_cap = r_z20.z20_saldo_cap + 
					  r_z23.z23_valor_cap
		LET r_z20.z20_saldo_int = r_z20.z20_saldo_int + 
					  r_z23.z23_valor_int
		IF r_z20.z20_saldo_cap >= 0 AND r_z20.z20_saldo_int >= 0 THEN
			UPDATE cxct020 SET z20_saldo_cap = r_z20.z20_saldo_cap,
			                   z20_saldo_int = r_z20.z20_saldo_int
				WHERE ROWID = num_reg
		END IF
		SELECT * FROM cxct022
			WHERE z22_compania  = r_z23.z23_compania  AND 
		              z22_localidad = r_z23.z23_localidad AND 
		              z22_codcli    = r_z23.z23_codcli    AND 
		              z22_tipo_trn  = r_z23.z23_tipo_trn  AND 
		              z22_num_trn   = r_z23.z23_num_trn
		IF status = NOTFOUND THEN
			IF r_z20.z20_saldo_cap >= 0 AND r_z20.z20_saldo_int >= 0 THEN
			INSERT INTO cxct022 SELECT * FROM tr_cxct022
				WHERE z22_compania  = r_z23.z23_compania  AND 
		                      z22_localidad = r_z23.z23_localidad AND 
		                      z22_codcli    = r_z23.z23_codcli    AND 
		                      z22_tipo_trn  = r_z23.z23_tipo_trn  AND 
		                      z22_num_trn   = r_z23.z23_num_trn
			END IF
		END IF
		IF r_z20.z20_saldo_cap >= 0 AND r_z20.z20_saldo_int >= 0 THEN
			INSERT INTO cxct023 VALUES (r_z23.*)	
		ELSE 
			LET valor = (r_z23.z23_valor_cap + r_z23.z23_valor_int)
					* -1
			UPDATE cxct021 SET z21_saldo = z21_saldo + valor
				WHERE z21_compania  = r_z21.z21_compania  AND 
	                              z21_localidad = r_z21.z21_localidad AND 
	                              z21_codcli    = r_z21.z21_codcli    AND 
	                              z21_tipo_doc  = r_z21.z21_tipo_doc  AND 
	                              z21_num_doc   = r_z21.z21_num_doc
		END IF
		UPDATE gent015 SET g15_numero = r_z23.z23_num_trn
			WHERE ROWID = num_reg_sec
	END FOREACH	
	IF i = 0 AND r_z21.z21_valor <> r_z21.z21_saldo THEN
		DELETE FROM cxct021
			WHERE z21_compania   = r_z21.z21_compania   AND 
		              z21_localidad  = r_z21.z21_localidad  AND 
		              z21_codcli     = r_z21.z21_codcli     AND 
		              z21_tipo_doc   = r_z21.z21_tipo_doc   AND 
		              z21_num_doc    = r_z21.z21_num_doc   
	END IF
	UPDATE gent015 SET g15_numero = r_z21.z21_num_doc 
		WHERE g15_compania  = r_z21.z21_compania  AND 
	              g15_localidad = r_z21.z21_localidad AND 
	              g15_modulo    = 'CO'                AND 
	              g15_tipo      = vm_tipo_doc
	CALL fl_genera_saldos_cliente(r_z21.z21_compania, r_z21.z21_localidad,
				      r_z21.z21_codcli)
END FOREACH
	
END FUNCTION



FUNCTION fl_genera_saldos_cliente(codcia, codloc, codcli)
DEFINE codcia		LIKE cxct020.z20_compania
DEFINE codloc		LIKE cxct020.z20_localidad
DEFINE codcli		LIKE cxct020.z20_codcli
DEFINE areaneg		LIKE cxct020.z20_areaneg
DEFINE moneda		LIKE cxct020.z20_moneda
DEFINE r		RECORD LIKE cxct030.*
DEFINE rd		RECORD LIKE cxct020.*
DEFINE rg		RECORD LIKE gent000.*
DEFINE valor		DECIMAL(14,2)
DEFINE vencido		DECIMAL(14,2)
DEFINE pvencer		DECIMAL(14,2)
DEFINE i		SMALLINT

UPDATE cxct030
	SET z30_saldo_venc  = 0, 
	    z30_saldo_xvenc = 0, 
	    z30_saldo_favor = 0
	WHERE z30_compania  = codcia AND
	      z30_localidad = codloc AND
	      z30_codcli    = codcli 

DECLARE q_acdo CURSOR FOR SELECT * FROM cxct020
	WHERE z20_compania  = codcia AND
	      z20_localidad = codloc AND
	      z20_codcli    = codcli AND
	      z20_saldo_cap + z20_saldo_int > 0
LET i = 0
FOREACH q_acdo INTO rd.*
	LET i = i + 1
	LET pvencer = rd.z20_saldo_cap + rd.z20_saldo_int
	LET vencido = 0
	IF rd.z20_fecha_vcto - TODAY < 0 THEN
		LET vencido = rd.z20_saldo_cap + rd.z20_saldo_int
		LET pvencer = 0
	END IF
	CALL fl_lee_resumen_saldo_cliente(codcia, codloc, rd.z20_areaneg, 
			rd.z20_codcli, rd.z20_moneda)
		RETURNING r.*
	IF r.z30_compania IS NULL THEN
		INSERT INTO cxct030 VALUES (rd.z20_compania, rd.z20_localidad, 
			rd.z20_areaneg, rd.z20_codcli, rd.z20_moneda, 
			vencido, pvencer, 0)
	ELSE
		UPDATE cxct030 SET z30_saldo_xvenc = z30_saldo_xvenc + pvencer,
				   z30_saldo_venc  = z30_saldo_venc  + vencido
			WHERE z30_compania  = codcia AND
		              z30_localidad = codloc AND
		              z30_areaneg   = rd.z20_areaneg AND
		              z30_codcli    = codcli AND
		              z30_moneda    = rd.z20_moneda
	END IF
END FOREACH
DECLARE q_dant CURSOR FOR SELECT z21_areaneg, z21_moneda, SUM(z21_saldo)
	FROM cxct021
	WHERE z21_compania  = codcia AND
	      z21_localidad = codloc AND
	      z21_codcli    = codcli 
	GROUP BY 1,2
FOREACH q_dant INTO areaneg, moneda, valor
	LET i = i + 1
	CALL fl_lee_resumen_saldo_cliente(codcia, codloc, areaneg, 
					  codcli, moneda)
		RETURNING r.*
	IF r.z30_compania IS NULL THEN
		INSERT INTO cxct030 VALUES (codcia, codloc, areaneg, codcli, 
					    moneda, 0, 0, valor)
	ELSE
		UPDATE cxct030 SET z30_saldo_favor = valor
			WHERE z30_compania  = codcia AND
		              z30_localidad = codloc AND
		              z30_areaneg   = areaneg AND
		              z30_codcli    = codcli AND
		              z30_moneda    = moneda
	END IF
END FOREACH
IF i = 0 THEN
	CALL fl_lee_configuracion_facturacion() RETURNING rg.*
	CALL fl_lee_resumen_saldo_cliente(codcia, codloc, 1, 
					  codcli, rg.g00_moneda_base)
		RETURNING r.*
	IF r.z30_compania IS NULL THEN
		CALL verifica_cliente(codcia, codloc, codcli)
		INSERT INTO cxct030 VALUES (codcia, codloc, 1, codcli, 
					    rg.g00_moneda_base, 0, 0, 0)
	END IF
END IF

END FUNCTION



FUNCTION fl_lee_configuracion_facturacion()
DEFINE r		RECORD LIKE gent000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM gent000 
	WHERE g00_serial = (SELECT MAX(g00_serial) FROM gent000)
RETURN r.*

END FUNCTION



FUNCTION fl_lee_resumen_saldo_cliente(codcia, codloc, areaneg, codcli, moneda)
DEFINE codcia		LIKE cxct030.z30_compania 
DEFINE codloc		LIKE cxct030.z30_localidad 
DEFINE areaneg		LIKE cxct030.z30_areaneg 
DEFINE codcli		LIKE cxct030.z30_codcli 
DEFINE moneda		LIKE cxct030.z30_moneda 
DEFINE r 		RECORD LIKE cxct030.* 

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM cxct030 
	WHERE z30_compania  = codcia AND
	      z30_localidad = codloc AND
	      z30_areaneg   = areaneg AND
	      z30_codcli    = codcli AND
	      z30_moneda    = moneda
RETURN r.* 

END FUNCTION



FUNCTION verifica_cliente(compania, localidad, codcli)
DEFINE compania		LIKE cxct020.z20_compania
DEFINE localidad	LIKE cxct020.z20_localidad
DEFINE codcli		LIKE cxct020.z20_codcli

SELECT * FROM cxct001
	WHERE z01_codcli = codcli
IF status = NOTFOUND THEN
	INSERT INTO cxct001
		SELECT * FROM tr_cxct001 
			WHERE z01_codcli = codcli
END IF
SELECT * FROM cxct002
	WHERE z02_compania  = compania  AND 
	      z02_localidad = localidad AND 
	      z02_codcli    = codcli
IF status = NOTFOUND THEN
	INSERT INTO cxct002 
		SELECT * FROM tr_cxct002
			WHERE z02_compania  = compania  AND 
	      	              z02_localidad = localidad AND 
	      	              z02_codcli    = codcli
END IF

END FUNCTION



FUNCTION recalcula_saldo_doc(codloc)
DEFINE codloc			LIKE gent002.g02_localidad
DEFINE saldo_doc, saldo_trn	DECIMAL(12,2)
DEFINE r_z20			RECORD LIKE cxct020.*
DEFINE asterisco		CHAR(1)
DEFINE codcli			LIKE cxct001.z01_codcli
DEFINE tot_cap, tot_int		DECIMAL(12,2)
DEFINE ref			CHAR(10)
DEFINE numreg			INTEGER

DECLARE q_ucli CURSOR FOR
	SELECT UNIQUE z22_codcli FROM tr_cxct022
		WHERE z22_localidad = codloc
FOREACH q_ucli INTO codcli
	DECLARE q_dcli CURSOR FOR SELECT *, ROWID FROM cxct020
		WHERE z20_compania  = vm_codcia AND 
		      z20_localidad = codloc AND
		      z20_codcli    = codcli
	FOREACH q_dcli INTO r_z20.*, numreg
		SELECT SUM(z23_valor_cap), SUM(z23_valor_int)
			INTO tot_cap, tot_int
			FROM cxct023
			WHERE z23_compania  = vm_codcia AND 
		              z23_localidad = codloc AND
		              z23_codcli    = codcli    AND 
		              z23_tipo_doc  = r_z20.z20_tipo_doc  AND 
		              z23_num_doc   = r_z20.z20_num_doc   AND 
		              z23_div_doc   = r_z20.z20_dividendo
		IF tot_cap IS NULL THEN
			LET tot_cap = 0
		END IF
		IF tot_int IS NULL THEN
			LET tot_int = 0
		END IF
		LET saldo_trn = r_z20.z20_valor_cap + r_z20.z20_valor_int +
				tot_cap + tot_int
		LET saldo_doc = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
		LET asterisco = NULL
		LET ref = r_z20.z20_referencia[1,10]
		IF saldo_trn <> saldo_doc THEN
			LET asterisco = '*'
		DISPLAY r_z20.z20_localidad, ' ',
			--r_z20.z20_codcli, ' ',
			r_z20.z20_tipo_doc, ' ',
			r_z20.z20_num_doc, ' ',
			r_z20.z20_dividendo, ' ',
			--r_z20.z20_valor_cap, ' ',
			--r_z20.z20_valor_int, ' ',
			saldo_doc, ' ',
			saldo_trn, ' ', 
			ref, ' ',
			asterisco
			UPDATE cxct020 SET z20_saldo_cap = z20_valor_cap + 
							   tot_cap,
			                   z20_saldo_int = z20_valor_int + 
							   tot_int
				WHERE ROWID = numreg
		END IF
	END FOREACH
	CALL fl_genera_saldos_cliente(vm_codcia, codloc, codcli)
END FOREACH

END FUNCTION
