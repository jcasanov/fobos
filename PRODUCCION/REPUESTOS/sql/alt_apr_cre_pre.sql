begin work;

	rename column "fobos".rept000.r00_cred_auto to r00_fact_sin_stock;

	rename column "fobos".cxct002.z02_cupocred_mb to z02_cupcred_aprob;

	rename column "fobos".cxct002.z02_cupocred_ma to z02_cupcred_xaprob;

--rollback work;
commit work;
