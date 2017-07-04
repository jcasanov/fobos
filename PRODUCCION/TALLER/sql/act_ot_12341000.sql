begin work;

-- UNA SOLA OT
update talt028 set t28_ot_nue = 1234
	where t28_compania  = 1
	  and t28_localidad = 1
	  and t28_num_dev   = 7;
update talt024 set t24_orden = 1234
	where t24_compania  = 1
	  and t24_localidad = 1
	  and t24_orden     = 1000;
update talt023 set t23_orden = 78
	where t23_compania  = 1
	  and t23_localidad = 1
	  and t23_orden     = 1000;
update talt024 set t24_orden = 78
	where t24_compania  = 1
	  and t24_localidad = 1
	  and t24_orden     = 1234;
update talt028 set t28_ot_nue = 78
	where t28_compania  = 1
	  and t28_localidad = 1
	  and t28_num_dev   = 7;
--


update talt023 set t23_orden = 121
	where t23_compania  = 1
	  and t23_localidad = 1
	  and t23_orden     = 1234;

commit work;
