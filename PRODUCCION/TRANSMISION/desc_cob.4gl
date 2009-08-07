DATABASE diteca_qm

DEFINE vg_codcia		LIKE gent001.g01_compania
DEFINE vg_codloc		LIKE gent002.g02_localidad

MAIN

CALL startlog('errores')
LET vg_codcia = 1
LET vg_codloc = 4
CALL descarga_cartera()

END MAIN



FUNCTION descarga_cartera()

UNLOAD TO "tr_cxct020.txt" SELECT * FROM cxct020 
	WHERE z20_compania  = vg_codcia AND 
	      z20_localidad = vg_codloc AND 
	      TODAY - DATE(z20_fecing) <= 30 AND 
	      z20_saldo_cap > 0;
UNLOAD TO "tr_cxct001.txt"
	SELECT UNIQUE cxct001.* from cxct020, cxct001
		WHERE z20_compania  = vg_codcia 
		  AND z20_localidad = vg_codloc
		  AND z20_codcli    = z01_codcli
	UNION 
	SELECT UNIQUE cxct001.* from cxct021, cxct001
		WHERE z21_compania  = vg_codcia 
		  AND z21_localidad = vg_codloc
		  AND z21_codcli    = z01_codcli
UNLOAD TO "tr_cxct002.txt"
	SELECT * FROM cxct002
		WHERE z02_codcli
			IN (SELECT UNIQUE z20_codcli
				FROM cxct020
				WHERE z20_compania  = vg_codcia
				  AND z20_localidad = vg_codloc)
	UNION 
	SELECT * FROM cxct002
		WHERE z02_codcli
			IN (SELECT UNIQUE z21_codcli
				FROM cxct021
				WHERE z21_compania  = vg_codcia
				  AND z21_localidad = vg_codloc)
UNLOAD TO "tr_cxct021.txt" SELECT * FROM cxct021
	WHERE z21_compania  = vg_codcia AND 
	      z21_localidad = vg_codloc
UNLOAD TO "tr_cxct022.txt" SELECT * FROM cxct022
	WHERE z22_compania  = vg_codcia AND 
	      z22_localidad = vg_codloc
UNLOAD TO "tr_cxct023.txt" SELECT * FROM cxct023
	WHERE z23_compania  = vg_codcia AND 
	      z23_localidad = vg_codloc

END FUNCTION
