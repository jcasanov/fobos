select r19_codcli, r19_nomcli, r38_num_sri
	from rept038, rept019
	where r38_num_sri [9, 21] in (38232, 38235, 38238, 38239, 38241, 38244,
					38247)
	  and r19_cod_tran = r38_cod_tran
	  and r19_num_tran = r38_num_tran
	order by 1, 2, 3;
