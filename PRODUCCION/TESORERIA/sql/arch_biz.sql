CREATE TEMP TABLE tmp_arc_biz
        (
                tipo_reg                CHAR(5),        -- "BZDET"
                secuencia               SERIAL,         -- SEC.No.FILAS ARCH (6)
                cod_benefi              CHAR(18),       -- CODIGO PROV
                tipo_doc_id             CHAR(1),        -- C/R/P
                num_doc_id              CHAR(14),       -- CED/RUC/PAS
                nom_prov                CHAR(60),       -- p01_nomprov
                for_pago                CHAR(3),        -- CUE - CHE/COB/IMP/PEF
                cod_pais                CHAR(3),        -- SIEMPRE: 001
                cod_banco               CHAR(2),        -- 34
                tipo_cta                CHAR(2),        -- 03
                num_cta                 CHAR(20),       -- PON CTA. COR. Y BLANC
                cod_mon                 CHAR(1),        -- SIEMPRE: 1
                valor_pago              CHAR(15),       -- NO PONER CEROS
                concepto                CHAR(60),       -- REFERENCIA
                num_comprob             CHAR(15),       -- NUM. UNICO
                num_comp_ret            CHAR(15),       -- SIN GUIONES
                num_comp_iva            CHAR(15),       -- SIN GUIONES
                num_fact_sri            CHAR(20),       -- NORMAL
                cod_grupo               CHAR(10),       -- EN BLANCO
                desc_grupo              CHAR(50),       -- EN BLANCO
                dir_prov                CHAR(50),       -- p01_direccion1
                tel_prov                CHAR(20),       -- p01_telefono1
                cod_servicio            CHAR(3),        -- SIEMPRE: PRO
                autorizacion_sri        CHAR(10),       -- AUTORIZ. SRI
                fecha_validez           CHAR(10),       -- AAAAMMDD Y BLANCO
                referencia              CHAR(10),       -- EN BLANCO
                control_hor_ate         CHAR(1),        -- EN BLANCO
                cod_emp_bco             CHAR(5),        -- ASIGNADO POR EL BCO
                cod_sub_emp_bco         CHAR(6),        -- EN BLANCO
                sub_motivo_pag          CHAR(3)         -- SIEMPRE: RPA
        );

SELECT "BZDET" AS tip_arch, LPAD(p01_codprov, 18, " ") AS codprov,
	p01_tipo_doc AS tip_d_id,
	LPAD(p01_num_doc, 15 + (14 - LENGTH(p01_num_doc)), " ") AS num_d_id,
	LPAD(p01_nomprov[1, 60], 60, " ") AS nomprov, "CUE" AS for_pag,
	"001" AS codpais, "34" AS cod_bco, "03" AS tip_cta,
	LPAD(p24_numero_cta, 15 + (20 - LENGTH(p24_numero_cta)), " ") AS numcta,
	"1" AS codmon, REPLACE(LPAD(p24_total_che, 16, 0), ".", "") AS val_pago,
	LPAD(c10_referencia[1, 60], 60, " ") AS concep,
	LPAD(REPLACE(TRIM(c13_num_guia), "-", ""), 15, " ") AS num_com,
	(SELECT LPAD(REPLACE(p29_num_sri, "-", ""), 15, " ")
		FROM cxpt028, cxpt027, cxpt029
	WHERE p28_compania  = p20_compania
	  AND p28_localidad = p20_localidad
	  AND p28_codprov   = p20_codprov
	  AND p28_tipo_doc  = p20_tipo_doc
	  AND p28_num_doc   = p20_num_doc
	  AND p28_dividendo = 1
	  AND p28_secuencia = 1
	  AND p27_compania  = p28_compania
	  AND p27_localidad = p28_localidad
	  AND p27_num_ret   = p28_num_ret
	  AND p27_estado    = "A"
	  AND p29_compania  = p27_compania
	  AND p29_localidad = p27_localidad
	  AND p29_num_ret   = p27_num_ret) AS numcompret,
	LPAD(REPLACE(TRIM(c13_factura), "-", ""), 15 +
		(20 - LENGTH(REPLACE(TRIM(c13_factura), "-", ""))), " ")
		AS num_fac,
	" " AS cod_gr, " " AS des_gr,
	LPAD(p01_direccion1[1, 60], 61, " ") AS dirprov,
	LPAD(p01_telefono1, 10 + (20 - LENGTH(p01_telefono1)), " ") AS telprov,
	"PRO" AS cod_serv, LPAD(c13_num_aut, 10, " ") AS autoriz,
	LPAD(REPLACE(TO_CHAR(c13_fecha_cadu, "%Y/%m/%d") || "", "/", ""),
		10, " ") AS fec_validez,
	"          " AS referen,
	" " AS cont_hor_ate, "00000" AS codempbco, "      " AS codsub_empbco,
	"RPA" AS sub_mot_pag
	FROM cxpt024, cxpt022, cxpt023, cxpt020, cxpt001, ordt010, ordt013
	WHERE p24_compania   = 1
	  AND p24_localidad  = 1
	  --AND p24_orden_pago = 14812
	  --AND p24_orden_pago = 14815
	  --AND p24_orden_pago = 14816
	  --AND p24_orden_pago = 14820
	  --AND p24_orden_pago = 14821
	  AND p24_orden_pago = 14809
	  AND p22_compania   = p24_compania
	  AND p22_localidad  = p24_localidad
	  AND p22_orden_pago = p24_orden_pago
	  AND p23_compania   = p22_compania
	  AND p23_localidad  = p22_localidad
	  AND p23_codprov    = p22_codprov
	  AND p23_tipo_trn   = p22_tipo_trn
	  AND p23_num_trn    = p22_num_trn
	  AND p20_compania   = p23_compania
	  AND p20_localidad  = p23_localidad
	  AND p20_codprov    = p23_codprov
	  AND p20_tipo_doc   = p23_tipo_doc
	  AND p20_num_doc    = p23_num_doc
	  AND p20_dividendo  = p23_div_doc
	  AND p01_codprov    = p20_codprov
	  AND c10_compania   = p20_compania
	  AND c10_localidad  = p20_localidad
	  AND c10_numero_oc  = p20_numero_oc
	  AND c13_compania   = c10_compania
	  AND c13_localidad  = c10_localidad
	  AND c13_numero_oc  = c10_numero_oc
	  AND c13_estado     = "A"
	INTO TEMP t1;

INSERT INTO tmp_arc_biz
        (tipo_reg, secuencia, cod_benefi, tipo_doc_id, num_doc_id, nom_prov,
         for_pago, cod_pais, cod_banco, tipo_cta, num_cta, cod_mon, valor_pago,
         concepto, num_comprob, num_comp_ret, num_comp_iva, num_fact_sri,
         cod_grupo, desc_grupo, dir_prov, tel_prov, cod_servicio,
         autorizacion_sri, fecha_validez, referencia, control_hor_ate,
         cod_emp_bco, cod_sub_emp_bco, sub_motivo_pag)
        SELECT tip_arch, 1, codprov, tip_d_id, num_d_id, nomprov, for_pag,
                codpais, cod_bco, tip_cta, numcta, codmon, val_pago, concep,
                num_com, numcompret, numcompret AS numcompiva, num_fac,
                LPAD(cod_gr, 10, " "), LPAD(des_gr, 50, " "), dirprov,
                telprov, cod_serv, autoriz, fec_validez, LPAD(referen, 10, " "),
                cont_hor_ate, codempbco, LPAD(codsub_empbco, 6, " "),
                sub_mot_pag
                FROM t1;

DROP TABLE t1;

UNLOAD TO "arch_biz.unl" DELIMITER ","
SELECT tipo_reg, LPAD(secuencia, 6, 0) AS secuencia, cod_benefi, tipo_doc_id,
        num_doc_id, nom_prov, for_pago, cod_pais, cod_banco, tipo_cta, num_cta,
        cod_mon, valor_pago, concepto, num_comprob, num_comp_ret, num_comp_iva,
        num_fact_sri, LPAD(cod_grupo, 10, " ") AS cod_grupo,
        LPAD(desc_grupo, 50, " ") AS desc_grupo, dir_prov, tel_prov,
        cod_servicio, autorizacion_sri, fecha_validez,
        LPAD(referencia, 10, " ") AS referencia, control_hor_ate,
        cod_emp_bco, LPAD(cod_sub_emp_bco, 6, " ") AS cod_sub_emp_bco,
        sub_motivo_pag
        FROM tmp_arc_biz;
--        INTO TEMP t1;

DROP TABLE tmp_arc_biz;

{
UNLOAD TO "arch_biz.unl" DELIMITER ","
        SELECT * FROM t1
                ORDER BY secuencia;

DROP TABLE t1;
}
