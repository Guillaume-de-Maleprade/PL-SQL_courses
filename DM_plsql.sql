/*14*/
CREATE OR REPLACE FUNCTION moyenneEtudiantModule(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idModule IN Modules.idModule%TYPE) RETURN NUMBER IS
v_moyEtuMod NUMBER;
v_diviseur NUMBER;

CURSOR curs_noteEtudiant IS SELECT no.note, ma.coefficientMatiere
                            FROM notes no
                            JOIN Matieres ma ON ma.idMatiere = no.idMatiere
                            WHERE no.idEtudiant = p_idEtudiant
                            AND ma.idModule = p_idModule;

BEGIN
    v_moyEtuMod := 0;
    v_diviseur := 0;

    FOR v_ligne IN curs_noteEtudiant LOOP
        v_diviseur := v_diviseur + v_ligne.coefficientMatiere;
        v_moyEtuMod := v_moyEtuMod + (v_ligne.note * v_ligne.coefficientMatiere);
    END LOOP;

    v_moyEtuMod := v_moyEtuMod/v_diviseur;

    RETURN v_moyEtuMod;
END;

SELECT moyenneEtudiantModule('E6', 'M112')
FROM DUAL;


/*15*/
CREATE OR REPLACE FUNCTION valideEtudiantModule(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idModule IN Modules.idModule%TYPE)RETURN NUMBER IS
v_moyEtuMod NUMBER;

BEGIN
    SELECT moyenneEtudiantModule(p_idEtudiant, p_idModule) INTO v_moyEtuMod
    FROM DUAL;

    IF v_moyEtuMod >= 8 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;

END;

SELECT valideEtudiantModule('E6', 'M112')
FROM DUAL;


/*16*/
CREATE OR REPLACE FUNCTION moyenneEtudiantSemestre(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idSemestre IN Semestres.idSemestre%TYPE)RETURN NUMBER IS
v_moyEtuSem NUMBER;
v_moyTemp NUMBER;
v_diviseur NUMBER;
v_etuExists Etudiants.idEtudiant%TYPE;

CURSOR curs_modules IS      SELECT idModule, coefficientModule
                            FROM Modules
                            WHERE idSemestre = p_idSemestre;

BEGIN
    v_moyEtuSem := 0;
    v_diviseur := 0;

    SELECT DISTINCT no.idEtudiant INTO v_etuExists
    FROM Notes no
    JOIN Matieres ma ON ma.idMatiere = no.idMatiere
    JOIN Modules mo ON mo.idModule = ma.idModule
    JOIN Semestres s ON s.idSemestre = mo.idSemestre
    WHERE s.idSemestre = p_idSemestre AND no.idEtudiant = p_idEtudiant;

    IF v_etuExists = NULL THEN
        RETURN NULL;
    ELSE
        FOR v_ligne IN curs_modules LOOP
            SELECT moyenneEtudiantModule(p_idEtudiant, v_ligne.idModule) INTO v_moyTemp
            FROM DUAL;
            v_moyEtuSem := v_moyEtuSem + v_moyTemp * v_ligne.coefficientModule;
            v_diviseur := v_diviseur + v_ligne.coefficientModule;
        END LOOP;

        RETURN v_moyEtuSem/v_diviseur;
        
    END IF;
END;
    
SELECT moyenneEtudiantSemestre('E1', 'S1')
FROM DUAL;









/*17*/
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE affichageMoyEtudiantSemestre(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idSemestre IN Semestres.idSemestre%TYPE) IS
v_moyEtuMod NUMBER;
v_moyEtuSem NUMBER;

CURSOR curs_modules IS  SELECT idModule, coefficientModule, nomModule
                        FROM Modules
                        WHERE idSemestre = p_idSemestre;

CURSOR curs_matieres(c_idModule IN Modules.idModule%TYPE) IS    SELECT ma.idMatiere, ma.nomMatiere, no.note
                                                                FROM Matieres ma
                                                                JOIN Notes no ON no.idMatiere = ma.idMatiere
                                                                WHERE ma.idModule = c_idModule
                                                                AND no.idEtudiant = p_idEtudiant;


BEGIN
    affichageInfosEtudiant(p_idEtudiant);
    dbms_output.put_line('-------------------');
    FOR v_ligneMod IN curs_modules LOOP
        FOR v_ligneMat IN curs_matieres(v_ligneMod.idModule) LOOP
            dbms_output.put_line(v_ligneMat.nomMatiere||' : '||v_ligneMat.note);
        END LOOP;
        SELECT moyenneEtudiantModule(p_idEtudiant, v_ligneMod.idModule) INTO v_moyEtuMod
        FROM DUAL;
        dbms_output.put_line('Moyenne module '||v_ligneMod.nomModule||' : '||v_moyEtuMod);
        dbms_output.put_line('-------------------');
    END LOOP;
    SELECT moyenneEtudiantSemestre(p_idEtudiant, p_idSemestre) INTO v_moyEtuSem
    FROM DUAL;
    dbms_output.put_line('Moyenne semestre : '||v_moyEtuSem);
END;

CALL affichageMoyEtudiantSemestre('E10','S3');





/*18*/
SET SERVEROUTPUT ON;
CREATE OR REPLACE FUNCTION valideSemestre(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idSemestre IN Semestres.idSemestre%TYPE) RETURN VARCHAR IS
v_valide VARCHAR(1);
v_moyEtuMod NUMBER;
v_moyEtuSem NUMBER;

CURSOR curs_modules IS  SELECT idModule FROM Modules WHERE idSemestre = p_idSemestre;

BEGIN
    v_valide := 'O';
    FOR v_ligne IN curs_modules LOOP
        SELECT moyenneEtudiantModule(p_idEtudiant, v_ligne.idModule) INTO v_moyEtuMod
        FROM DUAL;
        IF v_moyEtuMod < 8 THEN
            v_valide := 'N';
        END IF;
    END LOOP;
    SELECT moyenneEtudiantSemestre(p_idEtudiant, p_idSemestre) INTO v_moyEtuSem FROM DUAL;
    IF v_moyEtuSem < 10 THEN
        v_valide := 'N';
    END IF;

    RETURN v_valide;
END;

SELECT valideSemestre('E17','S2')
FROM DUAL;


/*19*/
SET SERVEROUTPUT ON;
CREATE OR REPLACE FUNCTION classementEtudiantSemestre(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idSemestre IN Semestres.idSemestre%TYPE) RETURN NUMBER IS
v_rank NUMBER; v_moyEtuSemA NUMBER; v_moyEtuSemB NUMBER; v_rankInter NUMBER;


CURSOR curs_Etudiants IS    SELECT no.idEtudiant, moyenneEtudiantSemestre(no.idEtudiant, p_idSemestre)
                            FROM Notes no
                            JOIN Matieres ma ON ma.idMatiere = no.idMatiere
                            JOIN Modules mo ON mo.idModule = ma.idModule
                            WHERE mo.idSemestre = p_idSemestre
                            GROUP BY no.idEtudiant
                            ORDER BY moyenneEtudiantSemestre(no.idEtudiant, p_idSemestre) DESC;

BEGIN
    v_rank := 1;
    v_rankInter := v_rank; 
    v_moyEtuSemB := 21;
    FOR v_ligne IN curs_Etudiants LOOP
        SELECT moyenneEtudiantSemestre(v_ligne.idEtudiant, p_idSemestre) INTO v_moyEtuSemA
        FROM DUAL;
        IF v_moyEtuSemA != v_moyEtuSemB THEN
            v_rank := v_rankInter;
        END IF;
        IF v_ligne.idEtudiant = p_idEtudiant THEN
            RETURN v_rank;
        END IF;
        v_rankInter := v_rankInter + 1;
        SELECT moyenneEtudiantSemestre(v_ligne.idEtudiant, p_idSemestre) INTO v_moyEtuSemB
        FROM DUAL;
    END LOOP;
END;

SELECT classementEtudiantSemestre('E21', 'S2')
FROM DUAL;

/*
SELECT ROW_NUMBER() OVER(PARTITION BY mo.idSemestre ORDER BY moyenneEtudiantSemestre(no.idEtudiant, 'S2') DESC) AS Row#
FROM Notes no
JOIN Matieres ma ON ma.idMatiere = no.idMatiere
JOIN Modules mo ON mo.idModule = ma.idModule
WHERE no.idEtudiant = 'E21';
*/
/*20*/
SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE affichageResEtudiantSemestre(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idSemestre IN Semestres.idSemestre%TYPE) IS

BEGIN
    dbms_output.put_line('Resultat : '|| valideSemestre(p_idEtudiant, p_idSemestre));
    dbms_output.put_line('Classement : '|| classementEtudiantSemestre(p_idEtudiant, p_idSemestre));
END;

CALL affichageResEtudiantSemestre('E10', 'S3');

/*21*/ SET SERVEROUTPUT ON;
CREATE OR REPLACE PROCEDURE affichageReleveNotes(p_idEtudiant IN Etudiants.idEtudiant%TYPE, p_idSemestre IN Semestres.idSemestre%TYPE) IS

BEGIN
    affichageMoyEtudiantSemestre(p_idEtudiant, p_idSemestre);
    dbms_output.put_line('--------------------');
    affichageResEtudiantSemestre(p_idEtudiant, p_idSemestre);
END;

CALL affichageReleveNotes('E10','S4');
CALL affichageReleveNotes('E9','S4');
