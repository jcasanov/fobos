
  drop table te;
select p20_codprov,p20_tipo_doc, p20_num_doc, p20_dividendo,
	p20_valor_cap + p20_valor_int
	val_original, p20_saldo_cap + p20_saldo_int saldo,
	sum(p23_valor_cap + p23_valor_int) aplicado_det
	from cxpt020, cxpt023
	where p20_codprov   = p23_codprov and
	      p20_tipo_doc  = p23_tipo_doc and
	      p20_num_doc   = p23_num_doc  and
	      p20_dividendo = p23_div_doc
	group by 1,2,3,4,5,6
	into temp te;
select *, val_original - saldo aplicado_cab from
	te where (val_original - saldo) * -1 <> aplicado_det
        order by 1,3
