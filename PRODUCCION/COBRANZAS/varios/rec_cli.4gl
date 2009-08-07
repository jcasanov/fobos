DATABASE diteca

MAIN
DEFINE codcli		INTEGER

DECLARE q1 CURSOR FOR SELECT UNIQUE z20_codcli FROM cxct020
FOREACH q1 INTO codcli
	DISPLAY codcli
	CALL fl_genera_saldos_cliente(1,1,codcli)
END FOREACH
DECLARE q2 CURSOR FOR SELECT UNIQUE z21_codcli FROM cxct021
FOREACH q2 INTO codcli
	DISPLAY codcli
	CALL fl_genera_saldos_cliente(1,1,codcli)
END FOREACH

END MAIN
