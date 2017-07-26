set isolation to dirty read;

begin work;

	update rept010
		set r10_uni_med = "M2"
		where r10_compania  = 1
		  and r10_uni_med   = "M"
		  and r10_cod_clase = "801.P650";

commit work;
