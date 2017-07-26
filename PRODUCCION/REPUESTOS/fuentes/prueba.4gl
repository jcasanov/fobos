DATABASE acero_gm


DEFINE r_r10		RECORD LIKE rept010.*



MAIN

	--CLOSE DATABASE
	--DATABASE "acero_qm@ACUIO01"
	DECLARE q_caca CURSOR FOR
		select r10_codigo, r10_fec_camprec, r10_usuario
		        --from acero_qm@ACUIO01:rept010
		        from rept010
		        where r10_compania = 1
		          and r10_estado   = 'A'
		          and date(r10_fec_camprec) = today - 2 units day
	FOREACH q_caca INTO r_r10.r10_codigo, r_r10.r10_fec_camprec,
				r_r10.r10_usuario
		DISPLAY r_r10.r10_codigo, '  ', r_r10.r10_fec_camprec, '  ',
			r_r10.r10_usuario
	END FOREACH

END MAIN
