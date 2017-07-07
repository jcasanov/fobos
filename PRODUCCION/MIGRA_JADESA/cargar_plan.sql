CREATE TEMP TABLE t_cta
	(
		cta			INTEGER,
		nom_cta		VARCHAR(100, 40),
		tip_cta		CHAR(1),
		tip_mov		CHAR(1),
		nivel		SMALLINT
	);

LOAD FROM "plan_cta_jadesa.csv" DELIMITER "|"
	INSERT INTO t_cta;

BEGIN WORK;

DELETE FROM ctbt010 WHERE 1 = 1;

INSERT INTO ctbt010
	(b10_compania, b10_cuenta, b10_descripcion, b10_estado, b10_tipo_cta,
	 b10_tipo_mov, b10_nivel, b10_saldo_ma, b10_permite_mov, b10_usuario,
	 b10_fecing)
	SELECT 1 AS cia, cta, nom_cta, "A" AS est, tip_cta,	tip_mov, nivel,
			"N" AS sal_ma, "N" AS per_mov, "FOBOS" AS usua, CURRENT AS fecing
		FROM t_cta;

COMMIT WORK;

DROP TABLE t_cta;
