select r10_compania cia, r10_codigo item, r10_peso peso, r10_partida partida
	from acero_qm:rept010
	where r10_marca = 'MILWAU'
	into temp t1;
select count(*) total from t1;
unload to "restaurar_41_mil.unl" select * from t1;
drop table t1;
