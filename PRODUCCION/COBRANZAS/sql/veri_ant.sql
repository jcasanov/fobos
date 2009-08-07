select z21_codcli, z21_tipo_doc, z21_num_doc, z21_valor, z21_saldo,
	sum(z23_valor_cap) val_aplicado
	from cxct021, cxct023
	where z21_tipo_doc = z23_tipo_favor and
	      z21_num_doc  = z23_doc_favor
	group by 1,2,3,4,5
	into temp te;
select * from te where (z21_valor - z21_saldo) * -1 <> val_aplicado
