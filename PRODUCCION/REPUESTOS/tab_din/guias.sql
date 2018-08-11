SELECT YEAR(r95_fecing) AS anio,
	CASE WHEN MONTH(r95_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r95_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r95_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r95_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r95_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r95_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r95_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r95_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r95_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r95_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r95_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r95_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r95_fecha_emi AS fecha,
	CASE WHEN r95_estado = 'A' THEN "ACTIVO"
	     WHEN r95_estado = 'C' THEN "PROCESADO"
	     WHEN r95_estado = 'E' THEN "ELIMINADO"
	END AS estado,
	CASE WHEN r95_motivo = 'V' THEN "VENTAS"
	     WHEN r95_motivo = 'D' THEN "DEVOLUCION"
	     WHEN r95_motivo = 'I' THEN "IMPORTACION"
	     WHEN r95_motivo = 'N' THEN "TRANSFERENCIA"
	END AS motivo,
	r95_guia_remision AS numero,
	r95_persona_guia AS persona_guia,
	r95_persona_dest AS destinatario,
	r95_num_sri AS num_sri,
	r95_usuario AS usuario
	FROM rept095
	WHERE r95_compania = 1
	ORDER BY r95_num_sri ASC;
