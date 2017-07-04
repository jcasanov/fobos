
trans_fa_tr_01() {
 	dbaccess aceros 01_trans_fa_tr.sql &> $TRANS_FA_TR_HOME/01_trans_fa_tr.log
	return $? 
}

trans_fa_tr_03() {
	dbaccess aceros 03_trans_fa_tr.sql &> $TRANS_FA_TR_HOME/03_trans_fa_tr.log
	return $?
}

trans_fa_tr_04() {
	dbaccess aceros 04_trans_fa_tr.sql &> $TRANS_FA_TR_HOME/04_trans_fa_tr.log
	return $?
}

compara_fa_tr() {
	dbaccess aceros compara_fa_tr.sql &> $TRANS_FA_TR_HOME/compara_fa_tr.log
	return $?
}

getNuevosGMQM() {
	cat $TRANS_FA_TR_HOME/compara_fa_tr.log | grep "NUEVOS_GM_QM" | cut -f2 -d":"
}

getNuevosGMQS() {
	cat $TRANS_FA_TR_HOME/compara_fa_tr.log | grep "NUEVOS_GM_QS" | cut -f2 -d":"
}

getNuevosQMGM() {
	cat $TRANS_FA_TR_HOME/compara_fa_tr.log | grep "NUEVOS_QM_GM" | cut -f2 -d":"
}

getNuevosQMQS() {
	cat $TRANS_FA_TR_HOME/compara_fa_tr.log | grep "NUEVOS_QM_QS" | cut -f2 -d":"
}

getNuevosQSGM() {
	cat $TRANS_FA_TR_HOME/compara_fa_tr.log | grep "NUEVOS_QS_GM" | cut -f2 -d":"
}

getNuevosQSQM() {
	cat $TRANS_FA_TR_HOME/compara_fa_tr.log | grep "NUEVOS_QS_QM" | cut -f2 -d":"
}

error_msg() {
	echo -e "$1" 1>&2
	return 1
}
