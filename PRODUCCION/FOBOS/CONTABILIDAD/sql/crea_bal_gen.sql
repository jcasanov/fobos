--DROP TABLE t_bal_gen;

CREATE TABLE t_bal_gen
	(
		b11_compania		INTEGER		NOT NULL,
		b11_cuenta		CHAR(12)	NOT NULL,
		b11_moneda		CHAR(2)		NOT NULL,
		b11_ano			SMALLINT	NOT NULL,
		b11_db_ano_ant		DECIMAL(14,2)	NOT NULL,
		b11_cr_ano_ant		DECIMAL(14,2)	NOT NULL
	) IN datadbs LOCK MODE ROW;

CREATE UNIQUE INDEX "fobos".i01_pk_t_bal_gen
	ON "fobos".t_bal_gen
		(b11_compania, b11_cuenta, b11_moneda, b11_ano)
	IN idxdbs;

CREATE INDEX "fobos".i01_fk_t_bal_gen
	ON "fobos".t_bal_gen
		(b11_compania, b11_cuenta)
	IN idxdbs;

ALTER TABLE "fobos".t_bal_gen
	ADD CONSTRAINT
		PRIMARY KEY (b11_compania, b11_cuenta, b11_moneda, b11_ano)
		CONSTRAINT "fobos".pk_t_bal_gen;

ALTER TABLE "fobos".t_bal_gen
	ADD CONSTRAINT
		(FOREIGN KEY (b11_compania, b11_cuenta)
		 REFERENCES "fobos".ctbt010
		 CONSTRAINT "fobos".fk_01_t_bal_gen);
