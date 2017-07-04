begin work;

set constraints for "fobos".cxct023 disabled;
set constraints for "fobos".cxct022 disabled;
--set constraints for "fobos".cxct020 disabled;

update "fobos".cxct023
	set z23_localidad = 3
	where z23_compania  = 1
	  and z23_localidad = 4
	  and z23_codcli    in(1391, 28741, 28917)
	  and z23_tipo_trn  = 'AJ'
	  and z23_num_trn   in(7683, 7684, 7685, 7686);

update "fobos".cxct022
	set z22_localidad = 3
	where z22_compania  = 1
	  and z22_localidad = 4
	  and z22_codcli    in(1391, 28741, 28917)
	  and z22_tipo_trn  = 'AJ'
	  and z22_num_trn   in(7683, 7684, 7685, 7686);

update "fobos".cxct020
	set z20_localidad = 3
	where z20_compania  = 1
	  and z20_localidad = 4
	  and z20_codcli    in(1391, 28741, 28917)
	  and z20_tipo_doc  = 'FA'
	  and z20_num_doc   in(28464, 28248, 28561, 28634)
	  and z20_dividendo = 1;

set constraints for "fobos".cxct023 enabled;
set constraints for "fobos".cxct022 enabled;
--set constraints for "fobos".cxct020 enabled;

commit work;
