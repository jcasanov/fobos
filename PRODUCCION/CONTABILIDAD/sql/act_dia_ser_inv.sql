select b12_fec_proceso fecha, b12_compania cia, b12_tipo_comp tp,
	b12_num_comp num,
b12_glosa, b12_subtipo, b04_nombre, b13_cuenta, b13_glosa
from ctbt012,ctbt013, ctbt004
where
b12_compania = b13_compania AND
b12_tipo_comp = b13_tipo_comp AND
b12_num_comp = b13_num_comp AND
b12_subtipo = b04_subtipo AND
b12_compania = b04_compania
AND b13_cuenta = "11400101006"
--AND b13_cuenta = "61010101001"
AND b12_subtipo <> 25;
