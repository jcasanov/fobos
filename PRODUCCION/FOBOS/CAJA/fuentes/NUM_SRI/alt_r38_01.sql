--rollback work;
begin work;

--drop index "fobos".375_2997;

{--
drop index "fobos".i01_pk_rept038;
alter table "fobos".rept038 drop constraint "fobos".pk_rept038;
alter table "fobos".rept038 drop r38_tipo_doc;
--}

alter table "fobos".rept038 drop constraint "fobos".pk_rept038;

alter table "fobos".rept038 add (r38_tipo_doc char(2) before r38_tipo_fuente);

--------------------------------------------------------------------------------
-- QUERY PARA OBTENER LAS NOTAS DE VENTA

CREATE TEMP TABLE tmp_sri
	(r38_tipo_fuente	CHAR(2),
	 r38_num_tran		INTEGER,
	 j10_nomcli		VARCHAR(50),
	 r19_fecing		DATE,
	 r38_num_sri		CHAR(16));

SELECT g37_fecha_emi
	FROM gent037
	WHERE g37_compania  in (1, 2)
	  AND g37_tipo_doc   = 'NV'
	  AND g37_secuencia  = (select min(a.g37_secuencia)
				from gent037 a
				where a.g37_compania = g37_compania
				  and a.g37_tipo_doc = g37_tipo_doc)
	into temp tmp_fec;

SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli, DATE(j10_fecha_pro)
	fecha_pro, r38_num_sri, j10_tipo_destino
	FROM cajt010, OUTER rept038
	WHERE j10_compania        in (1, 2)
	  AND DATE(j10_fecha_pro) >= (select g37_fecha_emi from tmp_fec)
	  AND j10_tipo_destino    = "FA"
	  AND r38_compania        = j10_compania
	  AND r38_localidad       = j10_localidad
	  AND r38_tipo_fuente     = j10_tipo_fuente
	  AND r38_cod_tran        = j10_tipo_destino
	  AND r38_num_tran        = j10_num_destino
	INTO TEMP t1;

drop table tmp_fec;

SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli, fecha_pro, r38_num_sri
	FROM t1, rept019, cxct001
	WHERE j10_tipo_fuente    = "PR"
	  AND r19_compania      in (1, 2)
	  AND r19_cod_tran       = j10_tipo_destino
	  AND r19_num_tran       = j10_num_destino
	  AND z01_codcli         = r19_codcli
	  AND LENGTH(r19_cedruc) = 10
UNION
SELECT j10_tipo_fuente, j10_num_destino, j10_nomcli, fecha_pro, r38_num_sri
	FROM t1, talt023, cxct001
	WHERE j10_tipo_fuente  = "OT"
	  AND t23_compania    in (1, 2)
	  AND t23_num_factura  = j10_num_destino
	  AND z01_codcli       = t23_cod_cliente
	  AND z01_tipo_doc_id <> "R"
	INTO TEMP t2;

INSERT INTO tmp_sri SELECT * FROM t2;

DROP TABLE t1;

DROP TABLE t2;

update rept038
	set r38_tipo_doc = 'NV'
	where r38_num_sri in
		(select a.r38_num_sri from tmp_sri a
			where a.r38_tipo_fuente = r38_tipo_fuente
			  and a.r38_num_tran    = r38_num_tran
			  and a.r38_num_sri     = r38_num_sri)
	  and r38_num_tran in
		(select a.r38_num_tran from tmp_sri a
			where a.r38_tipo_fuente = r38_tipo_fuente
			  and a.r38_num_tran    = r38_num_tran
			  and a.r38_num_sri     = r38_num_sri);

drop table tmp_sri;

update rept038 set r38_tipo_doc = 'FA' where r38_tipo_doc is null;
--------------------------------------------------------------------------------

alter table "fobos".rept038 modify (r38_tipo_doc char(2) not null);

create unique index "fobos".i01_pk_rept038 on "fobos".rept038
	(r38_compania, r38_localidad, r38_tipo_doc, r38_tipo_fuente,
		r38_cod_tran, r38_num_tran)
	in idxdbs;

alter table "fobos".rept038
	add constraint
		primary key (r38_compania, r38_localidad, r38_tipo_doc,
				r38_tipo_fuente, r38_cod_tran, r38_num_tran)
			constraint "fobos".pk_rept038;

commit work;
