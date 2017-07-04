set isolation to dirty read;

begin work;

	update rept010
		set r10_uni_med = "M2"
		where r10_compania  = 1
		  and r10_uni_med   = "UNIDAD"
		  and r10_cod_grupo in ('800', '801');

commit work;
