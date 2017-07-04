SET ISOLATION TO DIRTY READ;

SELECT a.j04_localidad AS local,
	a.j04_fecha_aper AS fec_ape,
	a.j04_codigo_caja AS cod_caj,
	j02_nombre_caja AS nom_caj,
	(b.j05_ef_apertura + b.j05_ef_ing_dia - b.j05_ef_egr_dia) AS tot_ef,
	(b.j05_ch_apertura + b.j05_ch_ing_dia - b.j05_ch_egr_dia) AS tot_ch,
	((b.j05_ef_apertura + b.j05_ef_ing_dia - b.j05_ef_egr_dia) +
	 (b.j05_ch_apertura + b.j05_ch_ing_dia - b.j05_ch_egr_dia)) AS tot
	FROM cajt004 a, cajt005 b, cajt002
	WHERE a.j04_compania    = 1
	  AND a.j04_fecha_aper  =
		(SELECT MAX(c.j04_fecha_aper)
			FROM cajt004 c
			WHERE c.j04_compania    = a.j04_compania
			  AND c.j04_localidad   = a.j04_localidad
			  AND c.j04_codigo_caja = a.j04_codigo_caja
			  AND c.j04_fecha_aper  < TODAY)
	  AND a.j04_secuencia   =
		(SELECT MAX(c.j04_secuencia)
			FROM cajt004 c
			WHERE c.j04_compania    = a.j04_compania
			  AND c.j04_localidad   = a.j04_localidad
			  AND c.j04_codigo_caja = a.j04_codigo_caja
			  AND c.j04_fecha_aper  = a.j04_fecha_aper
			  AND c.j04_fecha_aper  < TODAY)
	  AND b.j05_compania    = a.j04_compania
	  AND b.j05_localidad   = a.j04_localidad
	  AND b.j05_codigo_caja = a.j04_codigo_caja
	  AND b.j05_fecha_aper  = a.j04_fecha_aper
	  AND b.j05_secuencia   = a.j04_secuencia
	  AND ((b.j05_ef_apertura + b.j05_ef_ing_dia - b.j05_ef_egr_dia) +
	 	(b.j05_ch_apertura + b.j05_ch_ing_dia - b.j05_ch_egr_dia)) <> 0
	  AND j02_compania      = a.j04_compania
	  AND j02_localidad     = a.j04_localidad
	  AND j02_codigo_caja   = a.j04_codigo_caja
	INTO TEMP tmp_val_caj;

CREATE TEMP TABLE tmp_egr
	(

		compania	integer,
		localidad	smallint,
		tipo_fuente	char(2),
		num_fuente	serial,
		estado		char(1),
		nomcli		varchar(100,50),
		moneda		char(2),
		valor		decimal(12,2),
		fecha_pro	datetime year to second,
		codigo_caja	smallint,
		tipo_destino	char(2),
		num_destino	char(15),
		referencia	varchar(120,0),
		banco		integer,
		numero_cta	char(15),
		usuario		varchar(10,5),
		fecing		datetime year to second

	) IN datadbs LOCK MODE ROW;

INSERT INTO tmp_egr
	(compania, localidad, tipo_fuente, num_fuente, estado, nomcli, moneda,
	 valor, fecha_pro, codigo_caja, tipo_destino, referencia, banco,
	 numero_cta, usuario, fecing)
	SELECT 1, local, "EC", 0, "P", "Egreso de caja cierre general", "DO",
		tot_ef, CURRENT, cod_caj, "EC", "EGRESO EN EFECTIVO NO " ||
		"CONTABILIZADO DE CIE/APE FECHA : " ||
		TO_CHAR(TODAY, "%d-%m-%Y"), 3, "5009000787", "FOBOS", CURRENT
		FROM tmp_val_caj
		WHERE tot_ef > 0;

INSERT INTO tmp_egr
	(compania, localidad, tipo_fuente, num_fuente, estado, nomcli, moneda,
	 valor, fecha_pro, codigo_caja, tipo_destino, referencia, banco,
	 numero_cta, usuario, fecing)
	SELECT 1, local, "EC", 0, "P", "Egreso de caja cierre general", "DO",
		0.00, CURRENT, cod_caj, "EC", "EGRESO DE CHEQUES NO " ||
		"CONTABILIZADO DE CIE/APE FECHA : " ||
		TO_CHAR(TODAY, "%d-%m-%Y"), 3, "5009000787", "FOBOS", CURRENT
		FROM tmp_val_caj
		WHERE tot_ch > 0;

DROP TABLE tmp_val_caj;

CREATE TEMP TABLE tmp_t1
	(

		compania	integer,
		localidad	smallint,
		tipo_fuente	char(2),
		num_fuente	integer,
		estado		char(1),
		nomcli		varchar(100,50),
		moneda		char(2),
		valor		decimal(12,2),
		fecha_pro	datetime year to second,
		codigo_caja	smallint,
		tipo_destino	char(2),
		num_destino	char(15),
		referencia	varchar(120,0),
		banco		integer,
		numero_cta	char(15),
		usuario		varchar(10,5),
		fecing		datetime year to second

	) IN datadbs LOCK MODE ROW;

INSERT INTO tmp_t1
	SELECT compania, localidad, tipo_fuente, CAST(num_fuente AS INTEGER),
		estado, nomcli, moneda, valor, fecha_pro, codigo_caja,
		tipo_destino, num_destino, referencia, banco, numero_cta,
		usuario, fecing
		FROM tmp_egr;

DROP TABLE tmp_egr;

UPDATE tmp_t1
	SET num_fuente = num_fuente +
			NVL((SELECT MAX(j10_num_fuente)
				FROM cajt010
				WHERE j10_compania    = compania
				  AND j10_localidad   = localidad
				  AND j10_tipo_fuente = tipo_fuente), 0)
	WHERE 1 = 1;

UPDATE tmp_t1
	SET num_destino = num_fuente
	WHERE 1 = 1;

SELECT * FROM tmp_t1
	INTO TEMP tmp_egr;

DROP TABLE tmp_t1;

--select localidad, num_fuente from tmp_egr order by 1, 2;

SELECT j11_compania AS cia,
	j11_localidad AS loc,
	j11_tipo_fuente AS tip_f,
	j11_num_fuente AS num_f,
	j11_secuencia AS secuen,
	num_fuente AS num_egr
	FROM tmp_egr, cajt010, cajt011
	WHERE valor               = 0
	  AND j10_compania        = compania
	  AND j10_localidad       = localidad
	  AND j10_estado          = "P"
	  AND DATE(j10_fecha_pro) < TODAY
	  AND j10_codigo_caja     = codigo_caja
	  AND j11_compania        = j10_compania
	  AND j11_localidad       = j10_localidad
	  AND j11_tipo_fuente     = j10_tipo_fuente
	  AND j11_num_fuente      = j10_num_fuente
	  AND j11_codigo_pago     = "CH"
	  AND j11_num_egreso      IS NULL
	INTO TEMP tmp_j11;

UNLOAD TO "egr_che_sur.unl" SELECT * FROM tmp_j11;

--select loc, num_egr, count(*) tot_reg from tmp_j11 group by 1, 2 order by 1, 2;

--SET LOCK MODE TO WAIT 20;

--
BEGIN WORK;

	INSERT INTO cajt010
		(j10_compania, j10_localidad, j10_tipo_fuente, j10_num_fuente,
		 j10_estado, j10_nomcli, j10_moneda, j10_valor, j10_fecha_pro,
		 j10_codigo_caja, j10_tipo_destino, j10_num_destino,
		 j10_referencia, j10_banco, j10_numero_cta, j10_usuario,
		 j10_fecing) 
		SELECT * FROM tmp_egr;

	INSERT INTO cajt013
		SELECT compania, localidad, codigo_caja, TODAY, moneda,
			tipo_fuente, "EF", SUM(valor)
			FROM tmp_egr
			GROUP BY 1, 2, 3, 4, 5, 6, 7;

	UPDATE cajt005
		SET j05_ef_apertura = 0,
		    j05_ch_apertura = 0
		WHERE j05_fecha_aper = TODAY
		  AND EXISTS
			(SELECT 1 FROM tmp_egr
				WHERE compania    = j05_compania
				  AND localidad   = j05_localidad
				  AND codigo_caja = j05_codigo_caja);

	UPDATE cajt011
		SET j11_num_egreso = (SELECT num_egr
					FROM tmp_j11
					WHERE cia    = j11_compania
					  AND loc    = j11_localidad
					  AND tip_f  = j11_tipo_fuente
					  AND num_f  = j11_num_fuente
					  AND secuen = j11_secuencia)
		WHERE EXISTS
			(SELECT 1 FROM tmp_j11
				WHERE cia     = j11_compania
				  AND loc     = j11_localidad
				  AND tip_f   = j11_tipo_fuente
				  AND num_f   = j11_num_fuente
				  AND secuen  = j11_secuencia
				  AND num_egr = 4);

	UPDATE cajt011
		SET j11_num_egreso = (SELECT num_egr
					FROM tmp_j11
					WHERE cia    = j11_compania
					  AND loc    = j11_localidad
					  AND tip_f  = j11_tipo_fuente
					  AND num_f  = j11_num_fuente
					  AND secuen = j11_secuencia)
		WHERE EXISTS
			(SELECT 1 FROM tmp_j11
				WHERE cia     = j11_compania
				  AND loc     = j11_localidad
				  AND tip_f   = j11_tipo_fuente
				  AND num_f   = j11_num_fuente
				  AND secuen  = j11_secuencia
				  AND num_egr = 5);

	UPDATE cajt011
		SET j11_num_egreso = (SELECT num_egr
					FROM tmp_j11
					WHERE cia    = j11_compania
					  AND loc    = j11_localidad
					  AND tip_f  = j11_tipo_fuente
					  AND num_f  = j11_num_fuente
					  AND secuen = j11_secuencia)
		WHERE EXISTS
			(SELECT 1 FROM tmp_j11
				WHERE cia     = j11_compania
				  AND loc     = j11_localidad
				  AND tip_f   = j11_tipo_fuente
				  AND num_f   = j11_num_fuente
				  AND secuen  = j11_secuencia
				  AND num_egr BETWEEN 6 AND 7);

--SET LOCK MODE TO NOT WAIT;

--ROLLBACK WORK;
COMMIT WORK;
--

DROP TABLE tmp_j11;
DROP TABLE tmp_egr;
