insert into rolt050
	select n50_compania, case when n50_cod_rubro = 29 then 40 else 79 end,
		n50_cod_depto, n50_aux_cont
		from rolt050
		where n50_cod_rubro in (29, 74);

insert into rolt051
	select n51_compania, case when n51_cod_rubro = 29 then 40 else 79 end,
		n51_aux_cont
		from rolt051
		where n51_cod_rubro in (29, 74);

insert into rolt052
	select n52_compania, case when n52_cod_rubro = 29 then 40 else 79 end,
		n52_cod_trab, n52_aux_cont
		from rolt052
		where n52_cod_rubro in (29, 74);
