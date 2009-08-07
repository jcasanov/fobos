set isolation to dirty read;
select b12_tipo_comp, b12_num_comp, b12_usuario, b12_fec_proceso,
	b12_fecing, b12_fec_modifi, b12_origen,
        b12_num_cheque, b10_descripcion
from ctbt012, ctbt010, ctbt013
where b12_estado = 'E' and b12_tipo_comp = 'EG'	and
	month(b12_fec_proceso) < 8 and
	month(b12_fec_modifi) >= 8 and
	b13_cuenta matches '110102*' and
	b12_compania = b13_compania and
	b12_tipo_comp = b13_tipo_comp and
	b12_num_comp = b13_num_comp and
	b13_compania = b10_compania and
	b13_cuenta = b10_cuenta
	order by 4
