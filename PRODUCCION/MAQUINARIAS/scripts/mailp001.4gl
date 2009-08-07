DATABASE diteca

DEFINE rm_e01		RECORD LIKE mailt001.*

MAIN

	CALL mail_to_maquinarias()

END MAIN



FUNCTION mail_to_maquinarias()
DEFINE continuar	SMALLINT
DEFINE linea		VARCHAR(80)
DEFINE r_m11		RECORD LIKE maqt011.*
DEFINE r_m12		RECORD LIKE maqt012.*

	INITIALIZE r_m11.* TO NULL
	DECLARE q_m11 CURSOR FOR
		SELECT * FROM maqt011
		 WHERE m11_compania  = 1
		   AND m11_estado    = 'A'
		   AND m11_fecha_sgte_rev BETWEEN TODAY AND (TODAY + 7)
		   AND TODAY BETWEEN m11_fecha_ent 
			 	  AND m11_fecha_ent + m11_garantia_meses 
                                      UNITS MONTH 
		ORDER BY m11_provincia, m11_canton, m11_modelo,
                         m11_codcli,    m11_nomcli

	OPEN  q_m11
	FETCH q_m11 INTO r_m11.*
	CLOSE q_m11

	IF r_m11.m11_compania IS NULL THEN
		RETURN
	END IF

	RUN "echo '[DITECA] Chequeo maquinarias' >> fobos_mail"

	LET continuar = 0
	FOREACH q_m11 INTO r_m11.*
		INITIALIZE r_m12.* TO NULL
		DECLARE q_m12 CURSOR FOR
			SELECT * FROM maqt012
			 WHERE m12_compania  = r_m11.m11_compania
			   AND m12_modelo    = r_m11.m11_modelo
			   AND m12_secuencia = r_m11.m11_secuencia
			 ORDER BY m12_compania,  m12_modelo,
                                  m12_secuencia, m12_fecha DESC 
		OPEN  q_m12 
		FETCH q_m12 INTO r_m12.*
		CLOSE q_m12
		FREE  q_m12

		IF r_m12.m12_compania IS NOT NULL THEN
			IF r_m12.m12_horometro > r_m11.m11_garantia_horas
			THEN
				CONTINUE FOREACH
			END IF
		END IF

		UPDATE maqt011 SET m11_estado = 'P'
		 WHERE m11_compania  = r_m11.m11_compania
		   AND m11_modelo    = r_m11.m11_modelo
		   AND m11_secuencia = r_m11.m11_secuencia

		LET linea = 'MODELO: ' || r_m11.m11_modelo CLIPPED,
			    ' SERIE: ' || r_m11.m11_serie  CLIPPED,
			    ' CLIENTE: ' || r_m11.m11_nomcli  CLIPPED 
			 
		RUN "echo '" || linea CLIPPED || "' >> fobos_mail" 
	END FOREACH

	RUN "echo . >> fobos_mail"

	INITIALIZE rm_e01.* TO NULL
	SELECT * INTO rm_e01.* FROM mailt001 
	 WHERE e01_compania  = r_m11.m11_compania
 	   AND e01_localidad = 1         
 	   AND e01_modulo    = 'GE'

	RUN "echo " || rm_e01.e01_mail_admin CLIPPED || " >> fobos_mail"

	INITIALIZE rm_e01.* TO NULL
	SELECT * INTO rm_e01.* FROM mailt001 
	 WHERE e01_compania  = 1
 	   AND e01_localidad = 1
 	   AND e01_modulo    = 'MA'

	RUN "mail " || rm_e01.e01_mail_admin CLIPPED || " < fobos_mail "
--	RUN "echo '' > fobos_mail "

END FUNCTION
