DATABASE diteca

{
Noviembre 27, 2004

Este programa se encarga de generar mails de alerta a los diferentes usuarios
cuando se cumplan las condiciones apropiadas. 

El programa va a estar divido en funciones por cada modulo para el que se 
genere algun mail de alerta, esa funcion llamara a una o varias funciones,
una por cada condicion que genere un mail.
}

DEFINE rm_e01		RECORD LIKE mailt001.*

MAIN

	CALL mail_to_maquinarias()

END MAIN



FUNCTION mail_to_maquinarias()

	CALL maq_verifica_servicio_postventa()

END FUNCTION


FUNCTION maq_verifica_servicio_postventa()

DEFINE continuar	SMALLINT
DEFINE linea		VARCHAR(100)
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_m11		RECORD LIKE maqt011.*
DEFINE r_m12		RECORD LIKE maqt012.*
DEFINE cliente		CHAR(30)

	INITIALIZE r_m11.* TO NULL
	DECLARE q_m11 CURSOR FOR
		SELECT * FROM maqt011
		 WHERE m11_compania  = 1
		   AND m11_estado    = 'A'
		   AND m11_fecha_sgte_rev <= (TODAY + 7)
		 UNION 
		SELECT * FROM maqt011
		 WHERE m11_compania  = 1
		   AND m11_estado    = 'A'
		   AND m11_fecha_sgte_rev IS NULL      
		   AND TODAY >= m11_fecha_ent + 30
		ORDER BY 4, 2 

	OPEN  q_m11
	FETCH q_m11 INTO r_m11.*
	CLOSE q_m11

	IF r_m11.m11_fecha_sgte_rev IS NULL THEN
		LET r_m11.m11_fecha_sgte_rev = r_m11.m11_fecha_ent + 30
	END IF

	IF r_m11.m11_compania IS NULL THEN
		RETURN
	END IF

	DISPLAY '[DITECA] Chequeo maquinarias '

	DISPLAY 'Este correo fue generado automaticamente por el sistema PHOBOS '
	DISPLAY ' '
	DISPLAY 'No intente responder a este correo, cualquier duda consulte al '
	DISPLAY 'Administrador del sistema o envie un mail a systemguards@gmail.com '
	DISPLAY ' '
	DISPLAY ' '
	DISPLAY 'A continuacion se muestra un listado de las maquinas que estan  '
	DISPLAY 'marcados como proximos a un chequeo. Por favor, confirme con los '
	DISPLAY 'clientes para realizar el chequeo. '
	DISPLAY ' '
	DISPLAY ' '
	DISPLAY 'MODELO           SERIE                      CLIENTE                       PROXIMA REVISION '

	LET continuar = 0
	FOREACH q_m11 INTO r_m11.*
		INITIALIZE r_m12.* TO NULL
		DECLARE q_m12 CURSOR FOR
			SELECT * FROM maqt012
			 WHERE m12_compania  = r_m11.m11_compania
			   AND m12_modelo    = r_m11.m11_modelo
			   AND m12_secuencia = r_m11.m11_secuencia
			 ORDER BY m12_compania,  m12_modelo, m12_secuencia, m12_fecha DESC 
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

		UPDATE maqt011 SET m11_estado = 'C'
		 WHERE m11_compania  = r_m11.m11_compania
		   AND m11_modelo    = r_m11.m11_modelo
		   AND m11_secuencia = r_m11.m11_secuencia

		SELECT * INTO r_z01.* FROM cxct001
		 WHERE z01_codcli = r_m11.m11_codcli

		LET cliente = r_z01.z01_nomcli[1,30]
		LET linea = r_m11.m11_modelo, '  ', r_m11.m11_serie, '  ', cliente, '  ', 
					r_m11.m11_fecha_sgte_rev USING 'yyyy-mm-dd'
			 
		DISPLAY linea CLIPPED  
	END FOREACH

	DISPLAY '.' 

	INITIALIZE rm_e01.* TO NULL
	SELECT * INTO rm_e01.* FROM mailt001 
	 WHERE e01_compania  = r_m11.m11_compania
 	   AND e01_localidad = 1         
 	   AND e01_modulo    = 'GE'

	DISPLAY rm_e01.e01_mail_admin CLIPPED 

	INITIALIZE rm_e01.* TO NULL
	SELECT * INTO rm_e01.* FROM mailt001 
	 WHERE e01_compania  = 1
 	   AND e01_localidad = 1
 	   AND e01_modulo    = 'MA'

	DISPLAY rm_e01.e01_mail_admin CLIPPED 
	DISPLAY ''

END FUNCTION
