select * from cxpt021 where p21_saldo < 0;
--drop table te;
select p21_codprov, p21_tipo_doc, p21_num_doc, p21_valor, p21_saldo,
	sum(p23_valor_cap) val_aplicado
	from cxpt021, cxpt023
	where p21_tipo_doc = p23_tipo_favor and
	      p21_num_doc  = p23_doc_favor
	group by 1,2,3,4,5
	into temp te;
select * from te where (p21_valor - p21_saldo) * -1 <> val_aplicado;
