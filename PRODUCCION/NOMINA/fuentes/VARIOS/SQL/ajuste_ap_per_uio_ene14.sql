delete from rolt010
	where n10_cod_rubro = 125;

load from "ajuste_ap_per_uio_ene14.unl" delimiter ","
	insert into rolt010;
