delete from rolt010
	where n10_cod_rubro = 80;

load from "ajuste_ap_per_gye_ene14.unl" delimiter ","
	insert into rolt010;
