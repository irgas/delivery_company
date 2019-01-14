  CREATE OR REPLACE PACKAGE "PKG_FIRMAKURIERSKA" IS
--procedury i funkcje do aplikacji

    PROCEDURE wprowadzklienta (
        v_nrklienta         NUMBER,
        v_nippesel          VARCHAR2,
        v_nazwafirmy        VARCHAR2,
        v_nazwisko          VARCHAR2,
        v_imie              VARCHAR2,
        v_kraj              VARCHAR2,
        v_miejscowosc       VARCHAR2,
        v_kodpocztowy       VARCHAR2,
        v_ulica             VARCHAR2,
        v_nrbudynku         VARCHAR2,
        v_nrlokalu          VARCHAR2,
        v_nrtelefonu        VARCHAR2,
        v_adresemail        VARCHAR2,
        v_rachunekbankowy   VARCHAR2
    );

    PROCEDURE wygeneruj_przesylke (
        v_nrprzesylki  VARCHAR2,
        v_nrnadawcy     NUMBER,
        v_nrodbiorcy    NUMBER,
        v_nrplatnosci   VARCHAR2
    );

    PROCEDURE wprowadz_zawartosc (
        v_nrprzesylki   VARCHAR2,
        v_waga          NUMBER,
        v_wysokosc      NUMBER,
        v_dlugosc       NUMBER,
        v_szerokosc     NUMBER
    );

    PROCEDURE aktualizuj_przesylke (
        v_nrprzesylki   VARCHAR2,
        v_zawartosc     VARCHAR2,
        v_uwagi         VARCHAR2
    );

--procedury i funkcje do generatora

    function daj_klienta return klienci_FK.nrklienta%type;

    FUNCTION daj_paczke RETURN paczki_FK.kodpaczki%TYPE;

    FUNCTION daj_pozycje(v_nrprzesylki przesylki_FK.nrprzesylki%type) RETURN zawartosci_przesylek_FK.pozycja%TYPE;

    PROCEDURE WPROWADZ_ZAWARTOSC(v_nrprzesylki przesylki_FK.nrprzesylki%TYPE);

    FUNCTION daj_stacje(
    v_nrprzesylki przesylki_FK.nrprzesylki%TYPE,
    v_zm varchar2
    )
    RETURN stacje_FK.stacja%type;

    PROCEDURE wprowadz_statusy(
    v_nrprzesylki przesylki_FK.nrprzesylki%TYPE,
    v_data date := sysdate
);

PROCEDURE generatordanych(
    v_data DATE DEFAULT sysdate
    );

PROCEDURE pozycjonowanie_po_usunieciu(
    v_nrprzesylki zawartosci_przesylek_fk.nrprzesylki%TYPE,
    v_pozycja zawartosci_przesylek_fk.pozycja%TYPE
    );

END;
/

  CREATE OR REPLACE PACKAGE BODY "PKG_FIRMAKURIERSKA" AS
--procedura wprowadzajaca nadawce/odbiorce do bazy

    PROCEDURE wprowadzklienta (
        v_nrklienta         NUMBER,
        v_nippesel          VARCHAR2,
        v_nazwafirmy        VARCHAR2,
        v_nazwisko          VARCHAR2,
        v_imie              VARCHAR2,
        v_kraj              VARCHAR2,
        v_miejscowosc       VARCHAR2,
        v_kodpocztowy       VARCHAR2,
        v_ulica             VARCHAR2,
        v_nrbudynku         VARCHAR2,
        v_nrlokalu          VARCHAR2,
        v_nrtelefonu        VARCHAR2,
        v_adresemail        VARCHAR2,
        v_rachunekbankowy   VARCHAR2
    )
    AS

        v_czyistnieje number;

    BEGIN

        SELECT COUNT(nrklienta)
        INTO v_czyistnieje
        FROM klienci_FK
        WHERE nrklienta = v_nrklienta;

        if v_czyistnieje = 0 then

        INSERT INTO klienci_FK VALUES (
            v_nrklienta,
            v_nippesel,
            v_nazwafirmy,
            v_nazwisko,
            v_imie,
            v_kraj,
            v_miejscowosc,
            v_kodpocztowy,
            v_ulica,
            v_nrbudynku,
            v_nrlokalu,
            v_nrtelefonu,
            v_adresemail,
            v_rachunekbankowy
        );

        ELSE
            update klienci_FK
                set nippesel = v_nippesel,
                    nazwafirmy = v_nazwafirmy,
                    nazwisko = v_nazwisko,
                    imie = v_imie,
                    kraj = v_kraj,
                    miejscowosc = v_miejscowosc,
                    kodpocztowy = v_kodpocztowy,
                    ulica = v_ulica,
                    nrbudynku = v_nrbudynku,
                    nrlokalu = v_nrlokalu,
                    nrtelefonu = v_nrtelefonu,
                    adresemail = v_adresemail,
                    rachunekbankowy = v_rachunekbankowy
                where nrklienta = v_nrklienta;

        END IF;

    END wprowadzklienta;

--procedura generujaca przesylke oraz wstawiajaca wiersz tymczasowy do tabeli platnosci

    PROCEDURE wygeneruj_przesylke (
        v_nrprzesylki    VARCHAR2,
        v_nrnadawcy     NUMBER,
        v_nrodbiorcy    NUMBER,
        v_nrplatnosci   VARCHAR2
    )
    IS
        v_kilometry   NUMBER;
        v_czyistnieje number;
    BEGIN

        SELECT COUNT(nrplatnosci)
            INTO v_czyistnieje
            FROM platnosci_FK
            where nrplatnosci = v_nrplatnosci;

        if v_czyistnieje = 0 then

        EXECUTE IMMEDIATE 'INSERT INTO platnosci_FK
    VALUES(:v_nrPlatnosci,1,1,0,''WIERSZ TYMCZASOWY'')'
            USING v_nrplatnosci;



        end if;




         SELECT COUNT(nrprzesylki)
            INTO v_czyistnieje
            FROM przesylki_FK
            where nrprzesylki = v_nrprzesylki;

        if v_czyistnieje = 0 then

        -- losowe generowanie kilometrow dla przesylki
        SELECT
            round(dbms_random.value(1,200) )
        INTO
            v_kilometry
        FROM
            dual;


        EXECUTE IMMEDIATE 'INSERT INTO przesylki_FK
    VALUES (:v_nrPrzesylki,:v_nrNadawcy,:v_nrOdbiorcy,:v_nrPlatnosci,NULL,NULL,0,:v_kliometry)'
            USING v_nrprzesylki,v_nrnadawcy,v_nrodbiorcy,v_nrplatnosci,v_kilometry;
        end if;

    END wygeneruj_przesylke;

--procedura wprowadzajaca do tabeli zawartosci_przesylek wierszy z iloscia paczek

    PROCEDURE wprowadz_zawartosc (
        v_nrprzesylki   VARCHAR2,
        v_waga          NUMBER,
        v_wysokosc      NUMBER,
        v_dlugosc       NUMBER,
        v_szerokosc     NUMBER
    ) IS

        v_czyistnieje      NUMBER := 0;
        v_pozycja          NUMBER(3,0) := 0;
        v_ilosc            NUMBER(5,0) := 0;
        v_cenazakupu       NUMBER(7,2) := 0;
        v_wartoscpozycji   NUMBER(7,2) := 0;
        v_objetosc         NUMBER := v_dlugosc * v_szerokosc * v_wysokosc;
        v_kodpaczki        paczki_FK.kodpaczki%TYPE;

        CURSOR c_kur IS
        SELECT
            kodpaczki
        FROM
            paczki_FK
        WHERE
            dlugosc * szerokosc * wysokosc > v_objetosc;

    BEGIN
--    pobieranie kodu paczki ktï¿½ra spelnia wymagania wprowadzonej paczki przez klienta
        FOR i IN c_kur LOOP
            v_kodpaczki := i.kodpaczki;
            EXIT WHEN i.kodpaczki IS NOT NULL;
        END LOOP;

--sprawdzenie czy istnieje jakas paczka w przesylce jesli nie nadaje pozycje nr 1
--jesli istnieje do ostatniego numeru pozycji dodaje 1

    v_pozycja := PKG_FIRMAKURIERSKA.DAJ_POZYCJE(v_nrprzesylki);

--sprawdzenie czy w przesylce znajduje sie juz paczka o podanym kodzie
--jesli nie istnieje otrzymuje ilosc 1 jesli istnieje do ilosci dodawana jest 1 wartosc

        SELECT
            COUNT(*)
        INTO
            v_czyistnieje
        FROM
            zawartosci_przesylek_FK
        WHERE
            kodpaczki = v_kodpaczki
            AND   nrprzesylki = v_nrprzesylki;

        IF
            v_czyistnieje < 1
        THEN
            v_ilosc := 1;
        ELSE
            SELECT
                ilosc
            INTO
                v_ilosc
            FROM
                zawartosci_przesylek_FK
            WHERE
                kodpaczki = v_kodpaczki
                AND   nrprzesylki = v_nrprzesylki;

            v_ilosc := v_ilosc + 1;
        END IF;

--wprowadzenie aktualnej ceny paczki

        SELECT
            cena
        INTO
            v_cenazakupu
        FROM
            paczki_FK
        WHERE
            kodpaczki = v_kodpaczki;

--obliczenie pozycji przesylki

        v_wartoscpozycji := v_cenazakupu * v_ilosc;

--sprawdzenie czy istnieje paczka o podanym kodzie jesli nie wprowadzany jest nowy wiersz
--jesli wiersz istnieje zmieniana jest tylko ilosc i wartoscpozycji;

        SELECT
            COUNT(*)
        INTO
            v_czyistnieje
        FROM
            zawartosci_przesylek_FK
        WHERE
            kodpaczki = v_kodpaczki
            AND   nrprzesylki = v_nrprzesylki;

        IF
            v_czyistnieje < 1
        THEN
            EXECUTE IMMEDIATE 'INSERT INTO zawartosci_przesylek_FK
    values(:v_pozycja,:v_nrprzesylki,:v_kodpaczki,:v_ilosc,:v_cenazakupu,:v_wartoscpozycji)'
                USING v_pozycja,v_nrprzesylki,v_kodpaczki,v_ilosc,v_cenazakupu,v_wartoscpozycji;
        ELSE
            UPDATE zawartosci_przesylek_FK
                SET
                    ilosc = v_ilosc,
                    wartoscpozycji = v_wartoscpozycji
            WHERE
                kodpaczki = v_kodpaczki
                AND   nrprzesylki = v_nrprzesylki;

        END IF;

    END wprowadz_zawartosc;

--procedura aktualizujaca kosztprzesylki,zawartosc i uwagi w tabeli przesylki

    PROCEDURE aktualizuj_przesylke (
        v_nrprzesylki   VARCHAR2,
        v_zawartosc     VARCHAR2,
        v_uwagi         VARCHAR2
    ) IS
        v_sum   NUMBER(7,2);
        v_kilometry number(5,0);
    BEGIN

--pobranie kosztu wszystkich paczek dla przesylki

        SELECT
            SUM(wartoscpozycji)
        INTO
            v_sum
        FROM
            zawartosci_przesylek_FK
        WHERE
            nrprzesylki = v_nrprzesylki;

        IF v_sum IS NULL THEN
        v_sum := 0;
        end if;

--pobranie kilometrow
        SELECT
            kilometry
        INTO
            v_kilometry
        FROM
            przesylki_FK
        WHERE
            nrprzesylki = v_nrprzesylki;

--obliczanie kosztu przesylki

    v_sum := v_sum + v_kilometry * 0.05;

--aktualizacja danych

        UPDATE przesylki_FK
            SET
                kosztprzesylki = v_sum,
                zawartosc = v_zawartosc,
                uwagidodoreczenia = v_uwagi
        WHERE
            nrprzesylki = v_nrprzesylki;

    END aktualizuj_przesylke;

    FUNCTION daj_klienta
   RETURN klienci_FK.nrklienta%TYPE
is

    v_klient klienci_FK.nrklienta%type;

begin

    SELECT round(dbms_random.VALUE(min(nrklienta),max(nrklienta)))
    into v_klient
    FROM klienci_FK;

    RETURN v_klient;

END daj_klienta;

    FUNCTION daj_paczke
   RETURN paczki_FK.kodpaczki%TYPE
IS
    v_paczka paczki_FK.kodpaczki%type;
BEGIN

    SELECT kodpaczki
        INTO v_paczka
            FROM(
                SELECT kodpaczki,DBMS_RANDOM.RANDOM
                    FROM paczki_FK
                        ORDER BY 2
                )where rownum < 2;

    return v_paczka;

END daj_paczke;

    FUNCTION daj_pozycje(v_nrprzesylki przesylki_FK.nrprzesylki%TYPE) RETURN zawartosci_przesylek_fk.pozycja%TYPE
is
    v_czyJest NUMBER;
    zawartosc_przesylki zawartosci_przesylek_fk%rowtype;
begin

    SELECT COUNT(*)
        INTO v_czyJest
        FROM ZAWARTOSCI_PRZESYLEK_FK
        WHERE nrprzesylki = v_nrprzesylki;

        IF v_czyJest = 0 THEN
            zawartosc_przesylki.pozycja := 1;
        ELSE

            SELECT pozycja
            INTO zawartosc_przesylki.pozycja
            FROM(
            SELECT pozycja
            FROM zawartosci_przesylek_FK
            WHERE nrprzesylki = v_nrprzesylki
            ORDER BY pozycja DESC
            )where rownum < 2;

            zawartosc_przesylki.pozycja := zawartosc_przesylki.pozycja + 1;

        END IF;

    return zawartosc_przesylki.pozycja;


END daj_pozycje;

    PROCEDURE WPROWADZ_ZAWARTOSC(
    v_nrprzesylki przesylki_fk.nrprzesylki%TYPE
)
IS
    zawartosc_przesylki zawartosci_przesylek_fk%rowtype;
    v_czyJest number;
BEGIN

        zawartosc_przesylki.pozycja := PKG_FIRMAKURIERSKA.DAJ_POZYCJE(v_nrprzesylki);

        zawartosc_przesylki.kodpaczki := pkg_firmakurierska.daj_paczke;

        SELECT COUNT(*)
        INTO v_czyJest
        FROM zawartosci_przesylek_fk
        WHERE kodpaczki = zawartosc_przesylki.kodpaczki
        and nrprzesylki = v_nrprzesylki;

        if v_czyJest > 0 then

        SELECT ilosc
        INTO zawartosc_przesylki.ilosc
        FROM zawartosci_przesylek_fk
        WHERE kodpaczki = zawartosc_przesylki.kodpaczki
        and nrprzesylki = v_nrprzesylki;

        zawartosc_przesylki.ilosc := zawartosc_przesylki.ilosc + 1;

        else

        SELECT round(dbms_random.VALUE(1,10))
        INTO zawartosc_przesylki.ilosc
        from dual;


        end if;

        SELECT cena
        INTO zawartosc_przesylki.cenazakupupaczki
        FROM paczki_fk
        WHERE kodpaczki = zawartosc_przesylki.kodpaczki;

        zawartosc_przesylki.wartoscpozycji := zawartosc_przesylki.ilosc * zawartosc_przesylki.cenazakupupaczki;

        SELECT COUNT(*)
        INTO v_czyJest
        FROM zawartosci_przesylek_FK
        WHERE kodpaczki = zawartosc_przesylki.kodpaczki
        and nrprzesylki = v_nrprzesylki;

        IF v_czyJest > 0 THEN

             UPDATE zawartosci_przesylek_FK
                SET ilosc = zawartosc_przesylki.ilosc
                    WHERE kodpaczki = zawartosc_przesylki.kodpaczki
                        AND nrprzesylki = v_nrprzesylki;


        ELSE

            INSERT INTO zawartosci_przesylek_FK
        VALUES(zawartosc_przesylki.pozycja,v_nrprzesylki,zawartosc_przesylki.kodpaczki,
            zawartosc_przesylki.ilosc,zawartosc_przesylki.cenazakupupaczki,zawartosc_przesylki.wartoscpozycji);

        END IF;
END WPROWADZ_ZAWARTOSC;

    FUNCTION daj_stacje(
    v_nrprzesylki przesylki_fk.nrprzesylki%TYPE,
    v_zm varchar2
    )
    RETURN stacje_FK.stacja%type
is
    v_stacja stacje_fk.stacja%type;
    v_czyJest NUMBER;
    v_rodzaj char(3);
BEGIN

    v_rodzaj := upper(v_zm);

    IF v_rodzaj = 'N' THEN

    SELECT
        count(*)
    INTO
        v_czyJest
    FROM
        stacje_FK
    WHERE
        upper(miejscowosc) LIKE upper( (
            SELECT
                miejscowosc
            FROM
                klienci_FK
            WHERE
                nrklienta = (SELECT nrnadawcy
                                FROM przesylki_FK
                                    where nrprzesylki = v_nrprzesylki)
        ) );

    if v_czyJest > 0 then

    SELECT
        stacja
    INTO
        v_stacja
    FROM
        stacje_FK
    WHERE
        upper(miejscowosc) LIKE upper( (
            SELECT
                miejscowosc
            FROM
                klienci_FK
            WHERE
                nrklienta = (SELECT nrnadawcy
                                FROM przesylki_FK
                                    where nrprzesylki = v_nrprzesylki)
        ) )
        AND   ROWNUM < 2;

    else

            SELECT stacja
            into v_stacja
            FROM(
                SELECT stacja,DBMS_RANDOM.RANDOM
                    FROM stacje_FK
                        ORDER BY 2
                )WHERE ROWNUM < 2;

    END IF;
    END IF;

    IF v_rodzaj = 'O' THEN

    SELECT
        count(*)
    INTO
        v_czyJest
    FROM
        stacje_FK
    WHERE
        upper(miejscowosc) LIKE upper( (
            SELECT
                miejscowosc
            FROM
                klienci_FK
            WHERE
                nrklienta = (SELECT nrodbiorcy
                                FROM przesylki_FK
                                    where nrprzesylki = v_nrprzesylki)
        ) );

    if v_czyJest > 0 then

    SELECT
        stacja
    INTO
        v_stacja
    FROM
        stacje_FK
    WHERE
        upper(miejscowosc) LIKE upper( (
            SELECT
                miejscowosc
            FROM
                klienci_FK
            WHERE
                nrklienta = (SELECT nrodbiorcy
                                FROM przesylki_FK
                                    where nrprzesylki = v_nrprzesylki)
        ) )
        AND   ROWNUM < 2;

    else

            SELECT stacja
            into v_stacja
            FROM(
                SELECT stacja,DBMS_RANDOM.RANDOM
                    FROM stacje_FK
                        ORDER BY 2
                )WHERE ROWNUM < 2;

    END IF;
    END IF;



    RETURN v_stacja;
END daj_stacje;

    PROCEDURE wprowadz_statusy(
    v_nrprzesylki przesylki_FK.nrprzesylki%TYPE,
    v_data date := sysdate
)
is
    v_stacjanadawcy stacje_FK.stacja%TYPE;
    v_stacjaodbiorcy stacje_FK.stacja%type;
BEGIN

    SELECT PKG_FIRMAKURIERSKA.DAJ_STACJE(v_nrprzesylki,'N')
        into v_stacjanadawcy
        from dual;

    SELECT PKG_FIRMAKURIERSKA.DAJ_STACJE(v_nrprzesylki,'O')
        into v_stacjaodbiorcy
        from dual;



    INSERT INTO statusy_FK
    values(v_data,v_nrprzesylki,'KUR','Przesy³ka nadana. Czeka na odbiór kuriera.');

    INSERT INTO statusy_FK
    values(v_data+ 1,v_nrprzesylki,'KUR','Przesy³ka nadana. Kurier odebra³ przesy³kê.');

    INSERT INTO statusy_FK
    values(v_data+ 1.25,v_nrprzesylki,v_stacjanadawcy,'Przyjêto w magazynie.');

    INSERT INTO statusy_FK
    values(v_data+ 1.50,v_nrprzesylki,v_stacjanadawcy,'Wyjœcie z magazynu.');

    INSERT INTO statusy_FK
    values(v_data+ 2,v_nrprzesylki,v_stacjaodbiorcy,'Przyjêto w magazynie.');

    INSERT INTO statusy_FK
    values(v_data+ 2.25,v_nrprzesylki,v_stacjaodbiorcy,'Wyjœcie z magazynu.');

    INSERT INTO statusy_FK
    values(v_data+ 2.50,v_nrprzesylki,v_stacjaodbiorcy,'Wydanie kurierowi.');

    INSERT INTO statusy_FK
    values(v_data+ 2.75,v_nrprzesylki,'KUR','Przesy³ka dorêczona.');

END;

PROCEDURE generatordanych(
    v_data DATE default sysdate
    )
    is
    przesylka przesylki_fk%rowtype;
    v_nrplatnosci platnosci_FK.nrplatnosci%TYPE;
    v_jakaPlatnosc NUMBER;
    v_czyJest number;
BEGIN

    IF v_data = sysdate THEN

    FOR I IN 1..20 LOOP

    SELECT lpad(seq_fk_platnosci.NEXTVAL,10,'0')
    INTO v_nrplatnosci
    from dual;


    SELECT lpad(seq_fk_przesylki.NEXTVAL,10,'0')
    INTO przesylka.nrprzesylki
    from dual;

    loop
    SELECT PKG_FIRMAKURIERSKA.DAJ_KLIENTA
    INTO przesylka.nrnadawcy
    FROM dual;

        SELECT COUNT(*)
        INTO v_czyjest
        FROM klienci_FK
        WHERE nrklienta = przesylka.nrnadawcy;

        exit when v_czyjest > 0;

    END LOOP;

    loop

    SELECT PKG_FIRMAKURIERSKA.DAJ_KLIENTA
    INTO przesylka.nrodbiorcy
    from dual;

        SELECT COUNT(*)
        INTO v_czyjest
        FROM klienci_FK
        WHERE nrklienta = przesylka.nrodbiorcy;

        exit when v_czyjest > 0;

    end loop;

    SELECT round(dbms_random.VALUE(0,200))
    into przesylka.kilometry
    from dual;


    SELECT round(dbms_random.VALUE(1,3))
    INTO v_jakaPlatnosc
    from dual;


    IF v_jakaPlatnosc = 1 THEN

    INSERT INTO platnosci_FK
    values (v_nrplatnosci,przesylka.nrnadawcy,1,0,'Zap³aacony');

    END IF;

    IF v_jakaPlatnosc = 2 THEN

    INSERT INTO platnosci_FK
    VALUES (v_nrplatnosci,przesylka.nrnadawcy,1,0,'Zap³acono przez PAYU');
    END IF;

    IF v_jakaPlatnosc = 3 THEN

    INSERT INTO platnosci_FK
    values (v_nrplatnosci,przesylka.nrodbiorcy,1,0,'P³atnoœæ przy odbiorze');

    END IF;

    INSERT INTO przesylki_FK
    VALUES (przesylka.nrprzesylki,przesylka.nrnadawcy,przesylka.nrodbiorcy,v_nrplatnosci,
    'Brak informacji o zawartoœci przesy³ki','Brak uwag',0,przesylka.kilometry);


    PKG_FIRMAKURIERSKA.WPROWADZ_ZAWARTOSC(przesylka.nrprzesylki);
    PKG_FIRMAKURIERSKA.WPROWADZ_STATUSY(przesylka.nrprzesylki,v_data);
    commit;
    end loop;

    else

    FOR I IN 0..40 LOOP

    for j in 1..20 loop

    SELECT lpad(seq_fk_platnosci.NEXTVAL,10,'0')
    INTO v_nrplatnosci
    from dual;

    SELECT lpad(seq_fk_przesylki.NEXTVAL,10,'0')
    INTO przesylka.nrprzesylki
    from dual;

    loop
    SELECT PKG_FIRMAKURIERSKA.DAJ_KLIENTA
    INTO przesylka.nrnadawcy
    FROM dual;

        SELECT COUNT(*)
        INTO v_czyjest
        FROM klienci_FK
        WHERE nrklienta = przesylka.nrnadawcy;

        exit when v_czyjest > 0;

    END LOOP;

    loop

    SELECT PKG_FIRMAKURIERSKA.DAJ_KLIENTA
    INTO przesylka.nrodbiorcy
    from dual;

        SELECT COUNT(*)
        INTO v_czyjest
        FROM klienci_FK
        WHERE nrklienta = przesylka.nrodbiorcy;

        exit when v_czyjest > 0;

    end loop;

    SELECT round(dbms_random.VALUE(0,200))
    into przesylka.kilometry
    from dual;

    SELECT round(dbms_random.VALUE(1,3))
    INTO v_jakaPlatnosc
    from dual;

    IF v_jakaPlatnosc = 1 THEN

    INSERT INTO platnosci_FK
    values (v_nrplatnosci,przesylka.nrnadawcy,1,0,'Zap³acony');

    elsif v_jakaPlatnosc = 2 then

    INSERT INTO platnosci_fk
    values (v_nrplatnosci,przesylka.nrnadawcy,1,0,'Zap³acono przez PAYU');

    elsif v_jakaPlatnosc = 3 then

    INSERT INTO platnosci_fk
    values (v_nrplatnosci,przesylka.nrodbiorcy,1,0,'P³atnoœæ przy odbiorze');

    end if;

    INSERT INTO przesylki_fk
    VALUES (przesylka.nrprzesylki,przesylka.nrnadawcy,przesylka.nrodbiorcy,v_nrplatnosci,
    'Brak informacji o zawartoœci przesy³ki','Brak uwag',0,przesylka.kilometry);

    PKG_FIRMAKURIERSKA.WPROWADZ_ZAWARTOSC(przesylka.nrprzesylki);
    PKG_FIRMAKURIERSKA.WPROWADZ_STATUSY(przesylka.nrprzesylki,v_data+I);
    commit;
    END LOOP;
    END LOOP;
    END IF;
END;

PROCEDURE pozycjonowanie_po_usunieciu(
    v_nrprzesylki zawartosci_przesylek_fk.nrprzesylki%TYPE,
    v_pozycja zawartosci_przesylek_fk.pozycja%TYPE
    )
    is
    v_maxpoz zawartosci_przesylek_fk.pozycja%TYPE;
    v_czyjest number;
BEGIN

    SELECT COUNT(*)
    INTO v_czyJest
    FROM zawartosci_przesylek_FK
    where nrprzesylki = v_nrprzesylki;

    if v_czyjest > 0 then


    SELECT MAX(pozycja)
    INTO v_maxpoz
    FROM zawartosci_przesylek_FK
    where nrprzesylki = v_nrprzesylki;

    DELETE FROM zawartosci_przesylek_FK
    where pozycja = v_pozycja and nrprzesylki = v_nrprzesylki;



    if v_pozycja != v_maxpoz then

    UPDATE zawartosci_przesylek_FK
        SET pozycja = v_pozycja
        WHERE nrprzesylki = v_nrprzesylki AND pozycja = v_maxpoz;

    END IF;
    else
    DELETE FROM zawartosci_przesylek_FK
        where pozycja = v_pozycja and nrprzesylki = v_nrprzesylki;
    end if;
end;

END pkg_firmakurierska;

/
