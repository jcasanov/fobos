database aceros

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

main

CALL verificar_dias_validez_sri()

end main



FUNCTION verificar_dias_validez_sri()
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE dias		SMALLINT
DEFINE mensaje		VARCHAR(200)
DEFINE icono		VARCHAR(11)

DECLARE q_g37 CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania  = 1
		  AND g37_localidad = 1
		  AND g37_tipo_doc  = 'FA'
		ORDER BY g37_fecha_exp DESC
OPEN q_g37
FETCH q_g37 INTO r_g37.*
let r_g37.g37_fecha_exp = TODAY + 30 UNITS DAY
LET dias = r_g37.g37_fecha_exp - mdy(arg_val(1), arg_val(2), 2003)
IF dias >= 0 AND dias <= 30 THEN
	LET mensaje = 'Faltan ', dias USING "<&", ' días para que caduquen'
	LET icono   = 'info'
	IF dias = 1 THEN
		LET mensaje = 'Falta un día para que caduquen'
		LET icono   = 'exclamation'
	END IF
	IF dias = 0 THEN
		LET mensaje = 'Hoy caducan'
		LET icono   = 'stop'
	END IF
 	LET mensaje = mensaje CLIPPED, ' los formularios de facturas. ',
			'Llame al ADMINISTRADOR.'
	display mensaje, ' ', icono
	--CALL fl_mostrar_mensaje(mensaje, icono)
END IF

END FUNCTION
