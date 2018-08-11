select s26_cod_for_pago as cod_p,
		s26_forma_de_pago as descripcion,
		s26_fecha_ini as fec_ini
	from srit026
	where s26_fecha_fin is null
	order by 1;
