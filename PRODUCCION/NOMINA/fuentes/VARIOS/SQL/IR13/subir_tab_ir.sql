select n15_compania cia, n15_ano anio, n15_secuencia sec, n15_base_imp_ini base,
	n15_base_imp_fin base_top, n15_fracc_base frac_bas, n15_porc_ir porc,
	n15_usuario usua
	from rolt015
	where n15_compania = 999
	into temp t1;

load from "tab_ir_2013.unl" insert into t1;

begin work;
	
	insert into rolt015
		(n15_compania, n15_ano, n15_secuencia, n15_base_imp_ini,
		 n15_base_imp_fin, n15_fracc_base, n15_porc_ir,
		 n15_usuario, n15_fecing)
		select cia, anio, sec, base, base_top, frac_bas, porc, usua,
			current
			from t1;

commit work;
--rollback work;

drop table t1;
