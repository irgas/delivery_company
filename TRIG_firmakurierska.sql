
  CREATE OR REPLACE TRIGGER "AKTUALIZACJA_PLATNOSCI_FK"
BEFORE UPDATE ON przesylki_FK
FOR EACH ROW
BEGIN
    UPDATE platnosci_FK
        SET koszt = :NEW.kosztprzesylki
        WHERE nrplatnosci = :NEW.nrplatnosci;


END;
/

  CREATE OR REPLACE TRIGGER "AKTUALIZACJA_PRZESYLKI_FK" AFTER
insert or update or delete ON zawartosci_przesylek_FK
DECLARE
    v_suma NUMBER;
    v_nrprzesylki przesylki_FK.nrprzesylki%TYPE;
    v_czyjest number;
BEGIN

    SELECT COUNT(*)
    INTO v_czyjest
    FROM tymczasowa_przesylka_FK;

    IF v_czyjest > 0 THEN

    SELECT nrprzesylki
    INTO v_nrprzesylki
    FROM tymczasowa_przesylka_FK
    where rownum < 2;

    END IF;

    SELECT COUNT(*)
    INTO v_czyjest
    FROM zawartosci_przesylek_FK
    WHERE nrprzesylki = v_nrprzesylki;

    IF v_czyjest > 0 THEN

    SELECT SUM(wartoscpozycji)
    INTO v_suma
    FROM zawartosci_przesylek_FK
    WHERE nrprzesylki = v_nrprzesylki;
    end if;

    IF v_suma IS NULL THEN
        v_suma := 0;
    end if;

    UPDATE przesylki_FK
    SET kosztprzesylki = v_suma
    WHERE nrprzesylki = v_nrprzesylki;


END;
/

  CREATE OR REPLACE TRIGGER "AKTUALIZUJ_KWOTE_FK"
after UPDATE of ilosc
ON zawartosci_przesylek_FK
BEGIN

    UPDATE zawartosci_przesylek_FK
    SET wartoscpozycji = ilosc*CENAZAKUPUPACZKI;


END;
/

  CREATE OR REPLACE TRIGGER "AKTUALIZUJ_PRZESYLKI_FK" BEFORE
    INSERT or update or delete ON zawartosci_przesylek_FK
    FOR EACH ROW
DECLARE
    v_suma   NUMBER;
    v_ile number;
BEGIN
    CASE
        WHEN inserting THEN

            SELECT
                COUNT(*)
            INTO
                :new.pozycja
            FROM
                zawartosci_przesylek_FK
            WHERE
                nrprzesylki =:new.nrprzesylki;

            IF
                :new.pozycja = 0
            THEN
                :new.pozycja := 1;
            ELSE
                :new.pozycja :=:new.pozycja + 1;
            END IF;

            SELECT
                cena
            INTO
                :new.cenazakupupaczki
            FROM
                paczki_FK
            WHERE
                kodpaczki =:new.kodpaczki;

            :new.wartoscpozycji :=:new.ilosc *:new.cenazakupupaczki;

              INSERT INTO tymczasowa_przesylka_FK(nrprzesylki)
            values(:new.nrprzesylki);

        WHEN updating THEN

            SELECT
                cena
            INTO
                :new.cenazakupupaczki
            FROM
                paczki_FK
            WHERE
                kodpaczki =:NEW.kodpaczki;

            INSERT INTO tymczasowa_przesylka_FK(nrprzesylki)
            values(:old.nrprzesylki);

        WHEN deleting THEN


            INSERT INTO tymczasowa_przesylka_FK(nrprzesylki)
            values(:old.nrprzesylki);

    END CASE;
END;
/

  CREATE OR REPLACE TRIGGER "GENERUJ_NUMER_KLIENTA_FK"
before INSERT ON klienci_FK
FOR EACH ROW
BEGIN

    IF :NEW.nrklienta IS NULL THEN
    SELECT SEQ_FK_klienci.NEXTVAL
        INTO :NEW.nrklienta
        FROM dual;
    end if;

END;

/

  CREATE OR REPLACE TRIGGER "GENERUJ_NUMER_PLATNOSCI_FK"
before INSERT ON platnosci_FK
FOR EACH ROW
BEGIN

    IF :NEW.nrplatnosci IS NULL THEN
    SELECT lpad(SEQ_FK_PLATNOSCI.NEXTVAL,10,'0')
        INTO :NEW.nrplatnosci
        FROM dual;
    end if;

END;
/

  CREATE OR REPLACE TRIGGER "GENERUJ_NUMER_PRZESYLKI_FK"
before INSERT ON przesylki_FK
FOR EACH ROW
BEGIN

    IF :NEW.nrprzesylki IS NULL THEN
    SELECT lpad(SEQ_FK_przesylki.NEXTVAL,10,'0')
        INTO :NEW.nrprzesylki
        FROM dual;
    end if;

END;
/