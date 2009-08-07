SELECT * FROM ctbt011 WHERE b11_compania = 1 
                        AND b11_cuenta   = '31050101001' 
                        AND b11_moneda   = 'DO'
                        AND b11_ano      = 2004;

SELECT b11_compania, b11_cuenta, b11_moneda, 2000,
	SUM(b11_db_ano_ant) as debito_ano_ant, 
 	SUM(b11_cr_ano_ant) as credito_ano_ant,
	SUM(b11_db_mes_01)  as debito_mes_01,
	SUM(b11_db_mes_02)  as debito_mes_02,
	SUM(b11_db_mes_03)  as debito_mes_03,
	SUM(b11_db_mes_04)  as debito_mes_04,
	SUM(b11_db_mes_05)  as debito_mes_05,
	SUM(b11_db_mes_06)  as debito_mes_06,
	SUM(b11_db_mes_07)  as debito_mes_07,
	SUM(b11_db_mes_08)  as debito_mes_08,
	SUM(b11_db_mes_09)  as debito_mes_09,
	SUM(b11_db_mes_10)  as debito_mes_10,
	SUM(b11_db_mes_11)  as debito_mes_11,
	SUM(b11_db_mes_12)  as debito_mes_12,
	SUM(b11_cr_mes_01)  as credito_mes_01,
	SUM(b11_cr_mes_02)  as credito_mes_02,
	SUM(b11_cr_mes_03)  as credito_mes_03,
	SUM(b11_cr_mes_04)  as credito_mes_04,
	SUM(b11_cr_mes_05)  as credito_mes_05,
	SUM(b11_cr_mes_06)  as credito_mes_06,
	SUM(b11_cr_mes_07)  as credito_mes_07,
	SUM(b11_cr_mes_08)  as credito_mes_08,
	SUM(b11_cr_mes_09)  as credito_mes_09,
	SUM(b11_cr_mes_10)  as credito_mes_10,
	SUM(b11_cr_mes_11)  as credito_mes_11,
	SUM(b11_cr_mes_12)  as credito_mes_12
   FROM ctbt011 
  WHERE b11_compania = 1 
    AND b11_cuenta   = '31050101001' 
    AND b11_moneda   = 'DO' 
    AND b11_ano BETWEEN 2001 AND 2003
  GROUP BY 1,2,3,4;
