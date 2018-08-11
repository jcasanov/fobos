DATABASE aceros



MAIN

	CALL ejecuta_proceso()

END MAIN



FUNCTION ejecuta_proceso()
DEFINE base_loc		CHAR(10)
DEFINE tot_r		INTEGER
DEFINE tot_r11_nac	INTEGER

SET ISOLATION TO DIRTY READ
select 'acero_gm' base, count(*) total_reg from acero_gm:rept011
	where r11_bodega in (select r02_codigo from acero_gm:rept002
				where r02_tipo      <> 'S'
				  and r02_area       = 'R'
				  and r02_localidad  = 1)
	into temp t1
UNLOAD TO "t1.txt" SELECT * FROM t1

CALL inserta_otras_bases('"acero_gc_r11"', 2)
CALL inserta_otras_bases('"acero_qm_r11"', 3)
CALL inserta_otras_bases('"acero_qs_r11"', 4)

CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE acero_gm
WHENEVER ERROR STOP

SET ISOLATION TO DIRTY READ
select 'acero_gm' base, count(*) total_reg
	from rept011
	WHERE r11_compania = 17
	INTO TEMP t1
DELETE FROM t1
LOAD FROM "t1.txt" INSERT INTO t1
LOAD FROM "t2.txt" INSERT INTO t1
LOAD FROM "t3.txt" INSERT INTO t1
LOAD FROM "t4.txt" INSERT INTO t1
DECLARE q_t1 CURSOR FOR select UNIQUE base, total_reg from t1 ORDER BY 1
FOREACH q_t1 INTO base_loc, tot_r
	DISPLAY base_loc CLIPPED, ' ', tot_r USING "##,##&", ' en rept011'
END FOREACH
select NVL(sum(total_reg), 0) INTO tot_r11_nac from t1
DISPLAY 'Total de registro nacional ', tot_r11_nac USING "###,##&"
drop table t1

END FUNCTION



FUNCTION inserta_otras_bases(bd, loc)
DEFINE bd		CHAR(15)
DEFINE loc		LIKE gent002.g02_localidad
DEFINE base_ser		CHAR(25)
DEFINE query		CHAR(800)

CASE loc
	WHEN 2
		LET base_ser = 'acero_gc@ACGYE02'
	WHEN 3
		LET base_ser = 'acero_qm@ACUIO01'
	WHEN 4
		LET base_ser = 'acero_qs@ACUIO02'
END CASE
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base_ser
WHENEVER ERROR STOP
SET ISOLATION TO DIRTY READ
LET query =' select ', bd CLIPPED, ' base, count(*) total_reg ',
		' from rept011 ',
		' where r11_bodega in (select r02_codigo ',
				' from rept002 ',
				' where r02_tipo      <> "S" ',
				'   and r02_area       = "R" ',
				'   and r02_localidad  = ', loc, ')',
		' INTO TEMP t1 '
PREPARE cons_bas FROM query
EXECUTE cons_bas
CASE loc
	WHEN 2
		UNLOAD TO "t2.txt" SELECT * FROM t1
	WHEN 3
		UNLOAD TO "t3.txt" SELECT * FROM t1
	WHEN 4
		UNLOAD TO "t4.txt" SELECT * FROM t1
END CASE

END FUNCTION
