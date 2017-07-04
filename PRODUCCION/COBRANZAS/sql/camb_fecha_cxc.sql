begin work;

	update cxct021
		set z21_fecha_emi = mdy (12, 31, 2008)
		where z21_compania  = 1
		  and z21_localidad = 1
		  and z21_tipo_doc  = 'NI'
		  and z21_num_doc   between 5 and 19
		  and z21_fecha_emi >= mdy (01, 01, 2009);

	update cxct020
		set z20_fecha_emi = mdy (12, 31, 2008)
		where z20_compania  = 1
		  and z20_localidad = 1
		  and z20_tipo_doc  = 'DI'
		  and z20_num_doc   in ('755', '756', '757', '758', '759',
					'760', '761', '762', '763', '764',
					'765', '766', '767', '768', '769',
					'770', '771', '772', '773', '774',
					'775', '776', '777', '778', '779',
					'780', '782', '783', '784', '785',
					'786', '787', '788', '789', '790',
					'791', '792', '793', '794', '795',
					'796', '797', '798', '799', '800',
					'801', '802', '803', '804', '805',
					'806', '807', '808')
		  and z20_fecha_emi >= mdy (01, 01, 2009);

commit work;
