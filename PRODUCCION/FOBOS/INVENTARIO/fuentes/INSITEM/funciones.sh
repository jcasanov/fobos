
inserta_division() {
 	dbaccess aceros 01_insdiv_ace.sql &> $INSERTA_HOME/division.log
	return $? 
}

inserta_linea() {
	dbaccess aceros 02_inslin_ace.sql &> $INSERTA_HOME/linea.log
	return $?
}

inserta_grupo() {
	dbaccess aceros 03_insgru_ace.sql &> $INSERTA_HOME/grupo.log
	return $?
}

inserta_clase() {
	dbaccess aceros 04_inscla_ace.sql &> $INSERTA_HOME/clase.log
	return $?
}

inserta_marca() {
	dbaccess aceros 05_insmar_ace.sql &> $INSERTA_HOME/marca.log
	return $?
}

inserta_unidad() {
	dbaccess aceros 06_insuni_ace.sql &> $INSERTA_HOME/unidad.log
	return $?
}

inserta_bodega() {
	dbaccess aceros 07_insbod_ace.sql &> $INSERTA_HOME/bodega.log
	return $?
}

inserta_capitulo() {
	dbaccess aceros 08_inscap_ace.sql &> $INSERTA_HOME/capitulo.log
	return $?
}

inserta_partida() {
	dbaccess aceros 09_inspar_ace.sql &> $INSERTA_HOME/partida.log
	return $?
}

inserta_item() {
	dbaccess aceros 10_insite_ace.sql &> $INSERTA_HOME/item.log
	return $?
}

compara_item() {
	dbaccess aceros compara_item.sql &> $INSERTA_HOME/compara_item.log
	return $?
}

getNuevosUIO() {
	cat $INSERTA_HOME/compara_item.log | grep "NUEVOS_UIO" | cut -f2 -d":"
}

getNuevosGYE() {
	cat $INSERTA_HOME/compara_item.log | grep "NUEVOS_GYE" | cut -f2 -d":"

}

error_msg() {
	echo -e "$1" 1>&2
	return 1
}
