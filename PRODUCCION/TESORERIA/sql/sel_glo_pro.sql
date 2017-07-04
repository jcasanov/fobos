SELECT b12_compania cia, b12_tipo_comp tp, b12_num_comp num,
	b12_benef_che, b12_glosa glo_ant,
	REPLACE(b12_glosa, "001-001-0187020", "001-001-0187217") glosa,
	b12_fec_proceso fec
	FROM ctbt012
	WHERE b12_compania = 1
	  AND b12_glosa    LIKE "%001-001-0187020%"
	INTO TEMP tmp_b12;
SELECT b13_compania cia, b13_tipo_comp tp, b13_num_comp num, b13_secuencia sec,
	b13_cuenta cta, b13_codprov prov, b13_glosa glo_ant,
	REPLACE(b13_glosa, "001-001-0187020", "001-001-0187217") glosa,
	b13_fec_proceso fec
	FROM ctbt013
	WHERE b13_compania = 1
	  AND b13_glosa    LIKE "%001-001-0187020%"
	INTO TEMP tmp_b13;
select * from tmp_b12 order by fec;
select * from tmp_b13 order by fec;
drop table tmp_b12;
drop table tmp_b13;
