begin work;

	update cxpt021
		set p21_val_impto = (select r19_tot_neto -
									(r19_tot_bruto - r19_tot_dscto)
								from rept019
								where r19_compania  = p21_compania
								  and r19_cod_tran  = 'DC'
								  and r19_num_tran  = p21_num_doc),
		    p21_cod_tran  = 'DC',
		    p21_num_tran  = (select r19_num_tran
								from rept019
								where r19_compania  = p21_compania
								  and r19_cod_tran  = 'DC'
								  and r19_num_tran  = p21_num_doc)
		where p21_compania = 1
		  and p21_tipo_doc = 'NC';

	select p21_num_doc, p21_num_tran, p21_val_impto, p21_valor
		from cxpt021
		where p21_tipo_doc = 'NC';

--rollback work;
commit work;
