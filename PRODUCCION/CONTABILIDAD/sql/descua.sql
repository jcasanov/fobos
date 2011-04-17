begin work;

select b12_tipo_comp, b12_num_comp,
	(select sum(b13_valor_base) from ctbt013
		where b13_compania  = b12_compania
		  and b13_tipo_comp = b12_tipo_comp
		  and b13_num_comp  = b12_num_comp
		  and b13_valor_base > 0) as debito,
	(select (sum(b13_valor_base) * (-1)) from ctbt013
		where b13_compania  = b12_compania
		  and b13_tipo_comp = b12_tipo_comp
		  and b13_num_comp  = b12_num_comp
		  and b13_valor_base < 0) as credito,
	b12_origen
from ctbt012
where b12_compania = 1
  and b12_estado = 'M'
  and year(b12_proceso) >= 2010
into temp tt_asientos;

delete from tt_asientos where debito = credito;

select * from tt_asientos;

rollback work;
