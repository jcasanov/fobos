{
select * from cxct022 where z22_num_trn = 4
}
select z22_codcli, z22_tipo_trn, z22_num_trn, z22_usuario, z22_fecing
	from cxct023, cxct022
	where z23_saldo_cap < 0 and
		z22_compania = z23_compania and
		z22_localidad = z23_localidad and
		z22_codcli    = z23_codcli and
		z22_tipo_trn  = z23_tipo_trn and
		z22_num_trn   = z23_num_trn
