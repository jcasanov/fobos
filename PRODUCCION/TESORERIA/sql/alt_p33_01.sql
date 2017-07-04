begin work;

	alter table "fobos".cxpt033
		add (p33_fec_aut_ant char(14) before p33_num_aut_ant);

	alter table "fobos".cxpt033
		add (p33_fec_aut_nue char(14) before p33_num_aut_nue);

commit work;
