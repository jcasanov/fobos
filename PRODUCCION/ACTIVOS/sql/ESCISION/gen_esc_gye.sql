SELECT a10_compania AS cia,
	a10_grupo_act AS grp_act,
	a10_codigo_bien AS acti,
	"DEPRECIACION POR ESCISION" AS ref,
	a10_locali_ori AS loc_o,
	a10_cod_depto AS dep_o,
	"" AS loc_d,
	"" AS dep_d,
	a10_porc_deprec AS porc_d,
	0.00 AS porc_r,
	((a10_valor_mb - a10_tot_dep_mb) -
	CASE WHEN a10_grupo_act <> 1
		THEN ((a10_val_dep_mb / 30) * 13)
		ELSE 0.00
	END) * (-1) AS val_act,
	0.00 AS val_alt,
	CASE WHEN a10_grupo_act <> 1
		THEN ((a10_val_dep_mb / 30) * 13) * (-1)
		ELSE 0.00
	END AS val_d_p,
	a10_estado AS est,
	a10_fecha_baja AS fec_baj,
	a10_tot_dep_mb AS tot_dep_ori
	FROM actt010
	WHERE a10_compania  = 1
	  AND a10_grupo_act < 4
	  AND a10_estado    = "S"
	INTO TEMP tmp_act;

UNLOAD TO "activos_gye_ori.unl"
	SELECT cia, acti, est, fec_baj, tot_dep_ori
		FROM tmp_act;

CREATE TEMP TABLE tmp_a12
	(
		compania         integer,
		codigo_tran      char(2),
		numero_tran      serial,
		codigo_bien      integer,
		referencia       varchar(100,40),
		locali_ori       smallint,
		depto_ori        smallint,
		locali_dest      smallint,
		depto_dest       smallint,
		porc_deprec      decimal(4,2),
		porc_reval       decimal(4,2),
		valor_mb         decimal(12,2),
		valor_ma         decimal(12,2),
		tipcomp_gen      char(2),
		numcomp_gen      char(8),
		usuario          varchar(10,5),
		fecing           datetime year to second
	) in datadbs lock mode row;

SELECT * FROM tmp_a12
	INTO TEMP t1;

INSERT INTO tmp_a12
	(compania, codigo_tran, numero_tran, codigo_bien, referencia,
	 locali_ori, depto_ori, locali_dest, depto_dest, porc_deprec,
	 porc_reval, valor_mb, valor_ma, tipcomp_gen, numcomp_gen, usuario,
	 fecing)
	SELECT a.cia, "DP", (SELECT a05_numero + 1
				FROM actt005
				WHERE a05_compania    = a.cia
				  AND a05_codigo_tran = "DP"),
	a.acti, a.ref, a.loc_o, a.dep_o, a.loc_d, a.dep_d, a.porc_d, a.porc_r,
	a.val_d_p, a.val_alt, "DC", "13011109", "FOBOS", "2013-01-13 00:00:00"
	FROM tmp_act a
	WHERE a.grp_act <> 1
	  AND a.acti     = (SELECT MIN(b.acti)
				FROM tmp_act b
				WHERE b.grp_act <> 1);

INSERT INTO tmp_a12
	(compania, codigo_tran, numero_tran, codigo_bien, referencia,
	 locali_ori, depto_ori, locali_dest, depto_dest, porc_deprec,
	 porc_reval, valor_mb, valor_ma, tipcomp_gen, numcomp_gen, usuario,
	 fecing)
	SELECT a.cia, "DP", 0, a.acti, a.ref, a.loc_o, a.dep_o, a.loc_d,
		a.dep_d, a.porc_d, a.porc_r, a.val_d_p, a.val_alt, "DC",
		"13011109", "FOBOS", "2013-01-13 00:00:00"
	FROM tmp_act a
	WHERE a.grp_act <> 1
	  AND a.acti    NOT IN (SELECT codigo_bien FROM tmp_a12);

INSERT INTO t1
	(compania, codigo_tran, numero_tran, codigo_bien, referencia,
	 locali_ori, depto_ori, locali_dest, depto_dest, porc_deprec,
	 porc_reval, valor_mb, valor_ma, tipcomp_gen, numcomp_gen, usuario,
	 fecing)
	SELECT a.cia, "ES", 0, a.acti, "BAJA POR ESCISION DEL ACTIVO.",
		a.loc_o, a.dep_o, a.loc_d, a.dep_d, a.porc_d, a.porc_r,
		a.val_act, a.val_alt, "DC", "13011110", "FOBOS",
		"2013-01-13 00:00:00"
	FROM tmp_act a;

INSERT INTO tmp_a12
	SELECT * FROM t1;

DROP TABLE t1;

BEGIN WORK;

	UPDATE ctbt012
		SET b12_subtipo = 61
		WHERE b12_compania  = 1
		  AND b12_tipo_comp = "DC"
		  AND b12_num_comp  = "13011109";

	INSERT INTO actt012
		(a12_compania, a12_codigo_tran, a12_numero_tran,
		 a12_codigo_bien, a12_referencia, a12_locali_ori, a12_depto_ori,
		 a12_locali_dest, a12_depto_dest, a12_porc_deprec,
		 a12_porc_reval, a12_valor_mb, a12_valor_ma, a12_tipcomp_gen,
		 a12_numcomp_gen, a12_usuario, a12_fecing)
		SELECT * FROM tmp_a12;

	UPDATE actt005
		SET a05_numero = (SELECT MAX(a12_numero_tran)
					FROM actt012
					WHERE a12_compania    = a05_compania
					  AND a12_codigo_tran = a05_codigo_tran)
		WHERE a05_compania     = 1
		  AND a05_codigo_tran IN
			(SELECT UNIQUE codigo_tran
				FROM tmp_a12);

	UPDATE actt010
		SET a10_estado     = "C",
		    a10_fecha_baja = NVL((SELECT UNIQUE DATE(fecing)
					FROM tmp_a12
					WHERE compania    = a10_compania
					  AND codigo_bien = a10_codigo_bien),
					MDY(01, 13, 2013)),
		    a10_tot_dep_mb = a10_tot_dep_mb +
					NVL((SELECT SUM(valor_mb) * (-1)
					FROM tmp_a12
					WHERE compania    = a10_compania
					  AND codigo_bien = a10_codigo_bien), 0)
		WHERE a10_compania     = 1
		  AND a10_codigo_bien IN (SELECT acti FROM tmp_act);

--ROLLBACK WORK;
COMMIT WORK;

DROP TABLE tmp_act;
DROP TABLE tmp_a12;
