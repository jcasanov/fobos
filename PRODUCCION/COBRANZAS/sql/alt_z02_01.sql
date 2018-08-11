begin work;

	alter table "fobos".cxct002
		add z02_num_pagos			smallint		before z02_usuario;

	alter table "fobos".cxct002
		add z02_dia_entre_pago		smallint        before z02_usuario;

	alter table "fobos".cxct002
		add z02_max_entre_pago		smallint        before z02_usuario;

--rollback work;
commit work;
