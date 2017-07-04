set isolation to dirty read;

begin work;

	update rept010
		set r10_uni_med = "UNIDAD"
		where r10_compania = 1
		  and r10_uni_med  = "UNI";

commit work;
