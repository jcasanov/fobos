begin work;

delete from actt015 where 1 = 1;

delete from actt012 where 1 = 1;

delete from actt005 where 1 = 1;

load from "/acero/fobos/RESPALDO/DIARIO/acero_qm.exp/actt000255.unl"
	insert into actt005;

load from "/acero/fobos/RESPALDO/DIARIO/acero_qm.exp/actt000596.unl"
	insert into actt012;

load from "/acero/fobos/RESPALDO/DIARIO/acero_qm.exp/actt000595.unl"
	insert into actt015;

commit work;
