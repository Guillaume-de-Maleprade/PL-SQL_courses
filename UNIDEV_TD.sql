/* 4A */
CREATE OR REPLACE PROCEDURE AjouterJourneeTravail ( p_codeSalarie Travailler.codeSalarie%TYPE, p_codeProjet Travailler.codeProjet%TYPE, p_dateTravail Travailler.dateTravail%TYPE) IS

BEGIN

INSERT INTO Travailler
VALUES (p_codeSalarie, p_dateTravail, p_codeProjet);

UPDATE Salaries
SET nbTotalJourneesTravail = nbTotalJourneesTravail + 1
WHERE codeSalarie = p_codeSalarie;

END;

CALL AjouterJourneeTravail('S2','P3','10/01/2014');

SELECT nbTotalJourneesTravail
FROM SALARIES
WHERE codeSalarie = 'S2';

/* 4B */
CREATE OR REPLACE TRIGGER ajouterJour AFTER INSERT ON Travailler
FOR EACH ROW

BEGIN
    UPDATE Salaries
    SET nbTotalJourneesTravail = nbTotalJourneesTravail + 1
    WHERE codeSalarie = :NEW.codeSalarie;

END;

INSERT INTO Travailler VALUES ('S1', '10/01/2014', 'P1');

SELECT nbTotalJourneesTravail
FROM SALARIES
WHERE codeSalarie = 'S1';

/* 5A */
CREATE OR REPLACE PROCEDURE AffecterSalarieEquipe(p_codeSalarie EtreAffecte.codeSalarie%TYPE, p_codeEquipe EtreAffecte.codeEquipe%TYPE) IS
v_nbEquipe NUMBER;

BEGIN
    SELECT COUNT(codeSalarie) INTO v_nbEquipe
    FROM EtreAffecte
    WHERE codeSalarie = p_codeSalarie;

    IF v_nbEquipe < 3 THEN
        INSERT INTO EtreAffecte
        VALUES (p_codeSalarie, p_codeEquipe);
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Le salarié est déjà affecté à au moins 3 équipes');
    END IF;
END;


CALL AffecterSalarieEquipe('S1','E3');

CALL AffecterSalarieEquipe('S8','E1');

SELECT *
FROM EtreAffecte
WHERE codeSalarie = 'S1' AND codeEquipe = 'E3';

SELECT *
FROM EtreAffecte
WHERE codeSalarie = 'S8' AND codeEquipe = 'E1';

/* 5B */
CREATE OR REPLACE TRIGGER afct_sal_eqp BEFORE INSERT ON EtreAffecte
FOR EACH ROW
DECLARE
v_nbEquipe NUMBER;

BEGIN
    SELECT COUNT(codeSalarie) INTO v_nbEquipe
    FROM EtreAffecte
    WHERE codeSalarie = :NEW.codeSalarie; 
    
    IF v_nbEquipe >= 3 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Le salarié est déjà affecté à au moins 3 équipes');
    END IF;
END;

INSERT INTO EtreAffecte VALUES ('S2', 'E4');

INSERT INTO EtreAffecte VALUES ('S7', 'E4');

SELECT *
FROM EtreAffecte
WHERE codeSalarie = 'S2' AND codeEquipe = 'E4';

SELECT *
FROM EtreAffecte
WHERE codeSalarie = 'S7' AND codeEquipe = 'E4';


/*5C*/
CREATE OR REPLACE TRIGGER afct_sal_eqp BEFORE INSERT OR UPDATE OF codeSalarie ON EtreAffecte
FOR EACH ROW
DECLARE
v_nbEquipe NUMBER;
PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
    SELECT COUNT(codeSalarie) INTO v_nbEquipe
    FROM EtreAffecte
    WHERE codeSalarie = :NEW.codeSalarie; 
    
    IF v_nbEquipe >= 3 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Le salarié est déjà affecté à au moins 3 équipes');
    END IF;
END;

UPDATE EtreAffecte
SET codeSalarie = 'S7'
WHERE codeSalarie = 'S2' AND codeEquipe = 'E4';

SELECT *
FROM EtreAffecte
WHERE codeSalarie = 'S7' AND codeEquipe = 'E4';

/* 6 */

CREATE OR REPLACE TRIGGER ajouterJour AFTER INSERT OR UPDATE OR DELETE ON Travailler
FOR EACH ROW

BEGIN
    IF (INSERTING) THEN
        UPDATE Salaries
        SET nbTotalJourneesTravail = nbTotalJourneesTravail + 1
        WHERE codeSalarie = :NEW.codeSalarie;
    END IF;
    IF (UPDATING) THEN
        UPDATE Salaries
        SET nbTotalJourneesTravail = nbTotalJourneesTravail + 1
        WHERE codeSalarie = :NEW.codeSalarie;
        UPDATE Salaries
        SET nbTotalJourneesTravail = nbTotalJourneesTravail - 1
        WHERE codeSalarie = :OLD.codeSalarie;
    END IF;
    IF (DELETING) THEN
        UPDATE Salaries
        SET nbTotalJourneesTravail = nbTotalJourneesTravail - 1
        WHERE codeSalarie = :OLD.codeSalarie;
    END IF;
END;

UPDATE Travailler
SET codeSalarie = 'S5'
WHERE codeSalarie = 'S1'
AND dateTravail = '10/01/2014';

DELETE Travailler
WHERE codeSalarie = 'S5'
AND dateTravail = '10/01/2014';


SELECT nbTotalJourneesTravail
FROM Salaries
WHERE codeSalarie = 'S1';

SELECT nbTotalJourneesTravail
FROM Salaries
WHERE codeSalarie = 'S5';

SELECT nbTotalJourneesTravail
FROM Salaries
WHERE codeSalarie = 'S5';

/* 7 */
CREATE OR REPLACE TRIGGER verifChef BEFORE INSERT OR UPDATE ON Equipes
FOR EACH ROW
DECLARE
v_membre Equipes.codeSalarieChef%TYPE;

BEGIN
    
    SELECT ea.codeSalarie INTO v_membre
    FROM EtreAffecte ea
    JOIN Equipes eq ON eq.codeEquipe = ea.codeEquipe
    WHERE ea.codeSalarie = :NEW.codeSalarieChef;

    IF v_membre = null THEN
        RAISE_APPLICATION_ERROR(-20001, 'Le salarié n''est pas dans cette équipe');
    END IF;

END;
/*A TESTER ------------------------------------------------*/


/* 8 */


/* 9 */
CREATE OR REPLACE VIEW Affectations(codeSalarie, nomSalarie, prenomSalarie, codeEquipe, nomEquipe) AS
    SELECT s.codeSalarie, s.nomSalarie, s.prenomSalarie, eq.codeEquipe, eq.nomEquipe
    FROM Salaries s
    JOIN EtreAffecte ea ON ea.codeSalarie = s.codeSalarie
    JOIN Equipes eq ON eq.codeEquipe = ea.codeEquipe;

INSERT INTO Affectations
VALUES ('S9', 'Zétofrais','Mélanie','E5','Indigo');







/* 10 */
CREATE OR REPLACE TRIGGER trigger_affectation INSTEAD OF INSERT ON Affectations
FOR EACH ROW
DECLARE
v_codeEquipe NUMBER;
v_codeSalarie NUMBER;

BEGIN
    SELECT COUNT(codeSalarie) INTO v_codeSalarie
    FROM Salaries
    WHERE codeSalarie = :NEW.codeSalarie;
    IF v_codeSalarie = 0 THEN
        INSERT INTO SALARIES VALUES (:NEW.codeSalarie, :NEW.nomSalarie, :NEW.prenomSalarie, 0);
    END IF;
    SELECT COUNT(codeEquipe) INTO v_codeEquipe
    FROM Equipes
    WHERE codeEquipe = :NEW.codeEquipe;
    IF v_codeEquipe = 0 THEN
        INSERT INTO EQUIPES VALUES (:NEW.codeEquipe, :NEW.nomEquipe, null);
    END IF;
    INSERT INTO EtreAffecte VALUES (:NEW.codeSalarie, :NEW.codeEquipe);
END;


INSERT INTO Affectations
VALUES ('S9', 'Zétofrais','Mélanie','E5','Indigo');

INSERT INTO Affectations
VALUES('S9','Zétofrais','Mélanie','E4','Mars');

INSERT INTO Affectations
VALUES ('S5', 'Umule','Jacques','E6','Europa');

INSERT INTO Affectations
VALUES ('S10', 'Zeblouse','Agathe','E7','Galileo');

/*10.2*/
CREATE OR REPLACE TRIGGER trigger_affectation INSTEAD OF INSERT ON Affectations
FOR EACH ROW
DECLARE
v_nbCodeEquipe NUMBER;
v_nbCodeSalarie NUMBER;
v_equipe NUMBER;
v_salarie NUMBER;

BEGIN
    SELECT COUNT(*) INTO v_salarie
    FROM Salaries
    WHERE codeSalarie = :NEW.codeSalarie
    AND nomSalarie = :NEW.nomSalarie
    AND prenomSalarie = :NEW.prenomSalarie;

    SELECT COUNT(*) INTO v_Equipe
    FROM Equipes
    WHERE codeEquipe = :NEW.codeEquipe
    AND nomEquipe = :NEW.nomEquipe;

    IF v_salarie = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Les données sur le salarié '||:NEW.codeSalarie||' sont fausses');
    ELSIF v_Equipe = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Les données sur l''équipe '||:NEW.codeEquipe||' sont fausses');
    END IF;

    SELECT COUNT(codeSalarie) INTO v_salarie
    FROM Salaries
    WHERE codeSalarie = :NEW.codeSalarie;
    IF v_salarie = 0 THEN
        INSERT INTO SALARIES VALUES (:NEW.codeSalarie, :NEW.nomSalarie, :NEW.prenomSalarie, 0);
    END IF;
    SELECT COUNT(codeEquipe) INTO v_nbCodeEquipe
    FROM Equipes
    WHERE codeEquipe = :NEW.codeEquipe;
    IF v_nbCodeEquipe = 0 THEN
        INSERT INTO EQUIPES VALUES (:NEW.codeEquipe, :NEW.nomEquipe, null);
    END IF;
    INSERT INTO EtreAffecte VALUES (:NEW.codeSalarie, :NEW.codeEquipe);
END;


INSERT INTO Affectations VALUES('S9','Ouzy','Jacques','E6','Europa');
INSERT INTO Affectations VALUES('S9','Zétofrais','Mélanie','E6','Galileo');