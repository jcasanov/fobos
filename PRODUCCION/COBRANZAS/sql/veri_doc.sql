
drop table te;
select z20_codcli, z20_tipo_doc, z20_num_doc, z20_dividendo,
	z20_valor_cap + z20_valor_int
	val_original, z20_saldo_cap + z20_saldo_int saldo,
	sum(z23_valor_cap + z23_valor_int) aplicado_det
	from cxct020, cxct023
	where z20_codcli    = z23_codcli and
	      z20_tipo_doc  = z23_tipo_doc and
	      z20_num_doc   = z23_num_doc  and
	      z20_dividendo = z23_div_doc
	group by 1,2,3,4,5,6
	into temp te;
select *, val_original - saldo aplicado_cab from
	te where (val_original - saldo) * -1 <> aplicado_det
        order by 1,3
