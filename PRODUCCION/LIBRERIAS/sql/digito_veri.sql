--DROP PROCEDURE fp_digito_veri;
CREATE PROCEDURE fp_digito_veri (cedruc CHAR(15)) RETURNING INT;

	DEFINE suma, i, lim	INT;
	DEFINE residuo_suma	INT;
	DEFINE num		INT;

	ON EXCEPTION IN (-1213)
		RETURN 0;
	END EXCEPTION;
	LET lim = 10;
	IF (LENGTH(cedruc) <> lim) AND (LENGTH(cedruc) <> 13) THEN
		RETURN 0;
	END IF;
	IF (cedruc[1, 2] > 22) OR (cedruc[1, 2] = 00) THEN
		RETURN 0;
	END IF;
	IF LENGTH(cedruc) = 13 THEN
		IF cedruc[11, 13] <> '001' OR cedruc[11, 12] <> '00' THEN
			RETURN 0;
		END IF;
	END IF;
	LET suma 	 = 0;
	LET residuo_suma = NULL;
	IF cedruc[3, 3] = 9 THEN
		LET suma         = cedruc[1, 1] * 4;
		LET suma         = suma + cedruc[2, 2] * 3;
		LET suma         = suma + cedruc[3, 3] * 2;
		LET suma         = suma + cedruc[4, 4] * 7;
		LET suma         = suma + cedruc[5, 5] * 6;
		LET suma         = suma + cedruc[6, 6] * 5;
		LET suma         = suma + cedruc[7, 7] * 4;
		LET suma         = suma + cedruc[8, 8] * 3;
		LET suma         = suma + cedruc[9, 9] * 2;
		LET residuo_suma = 11 - MOD(suma, 11);
		IF residuo_suma >= lim THEN
			LET residuo_suma = 11 - residuo_suma;
		END IF;
		LET num = cedruc[10, 10];
		IF num = residuo_suma THEN
			RETURN 1;
		END IF;
	END IF;
	IF (cedruc[3, 3] = 6) OR (cedruc[3, 3] = 8) THEN
		LET suma         = cedruc[1, 1] * 3;
		LET suma         = suma + cedruc[2, 2] * 2;
		LET suma         = suma + cedruc[3, 3] * 7;
		LET suma         = suma + cedruc[4, 4] * 6;
		LET suma         = suma + cedruc[5, 5] * 5;
		LET suma         = suma + cedruc[6, 6] * 4;
		LET suma         = suma + cedruc[7, 7] * 3;
		LET suma         = suma + cedruc[8, 8] * 2;
		LET residuo_suma = 11 - MOD(suma, 11);
		IF residuo_suma >= lim THEN
			LET residuo_suma = 11 - residuo_suma;
		END IF;
		LET num = cedruc[9, 9];
		IF num = residuo_suma THEN
			RETURN 1;
		END IF;
	END IF;
	IF ((cedruc[3, 3] < 3) OR (cedruc[3, 3] > 5)) AND (cedruc[3, 3] <> 7)
	THEN
		LET suma = 0;
		FOR i = 1 TO lim - 1
			LET num = SUBSTR(cedruc, i, 1);
			IF MOD(i, 2) <> 0 THEN
				LET num = num * 2;
				IF num > 9 THEN
					LET num = num - 9;
				END IF;
			END IF;
			LET suma = suma + num;
		END FOR;
		LET num          = SUBSTR(cedruc, lim, 1);
		LET residuo_suma = 10 - MOD(suma, 10);
		IF residuo_suma >= lim THEN
			LET residuo_suma = 10 - residuo_suma;
		END IF;
		IF num = residuo_suma THEN
			RETURN 1;
		END IF;
	END IF;
	RETURN 0;

END PROCEDURE;
