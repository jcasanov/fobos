select count(*) tot_ite_gm
	from acero_gm@idsgye01:rept010
	where r10_compania = 1;
select count(*) tot_ite_gc
	from acero_gc@idsgye01:rept010
	where r10_compania = 1;
select count(*) tot_ite_qm
	from acero_qm@idsuio01:rept010
	where r10_compania = 1;
select count(*) tot_ite_qs
	from acero_qs@idsuio02:rept010
	where r10_compania = 1;
