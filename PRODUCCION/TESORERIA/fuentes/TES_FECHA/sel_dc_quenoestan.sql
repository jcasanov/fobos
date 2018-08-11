select count(*) tot_r19 from rept019 where r19_cod_tran = 'DC';
select count(*) tot_p22 from cxpt022
	where p22_referencia matches 'DEV. COMPRA LOCAL #*';
select p22_fecing, trim(p22_referencia), p22_total_cap
	from cxpt022
	where p22_referencia matches 'DEV. COMPRA LOCAL #*'
	order by 1, 2;
select p21_fecha_emi, trim(p21_referencia), p21_valor
	from cxpt021
	where p21_referencia matches 'DEVOLUCION (COMPRA LOCAL)*'
	order by 1, 2;
