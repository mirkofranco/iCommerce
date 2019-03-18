DROP DATABASE IF EXISTS iCommerceFrancoChilese;

CREATE DATABASE iCommerceFrancoChilese;

USE iCommerceFrancoChilese;

/*CREA TABELLE*/
DROP TABLE IF EXISTS LOCALIZZAZIONE;
DROP TABLE IF EXISTS COMPOSIZIONE;
DROP TABLE IF EXISTS SPEDIZIONE_PRODOTTO;
DROP TABLE IF EXISTS INDIRIZZO_SPEDIZIONE_CLIENTE;
DROP TABLE IF EXISTS RESO;
DROP TABLE IF EXISTS SPEDIZIONE;
DROP TABLE IF EXISTS ORDINE;
DROP TABLE IF EXISTS STATO;
DROP TABLE IF EXISTS METODO_DI_PAGAMENTO_CLIENTE;
DROP TABLE IF EXISTS METODO_DI_PAGAMENTO;
DROP TABLE IF EXISTS CLIENTE;
DROP TABLE IF EXISTS PRODOTTO;
DROP TABLE IF EXISTS MAGAZZINO;
DROP TABLE IF EXISTS INDIRIZZO;
DROP TABLE IF EXISTS NAZIONE;
DROP TABLE IF EXISTS CATEGORIA;
DROP TABLE IF EXISTS VENDITORE;
DROP VIEW IF EXISTS numeroOrdini;
/* Creo le tabelle */

CREATE TABLE CATEGORIA(
	IDCategoria integer auto_increment primary key,
	Nome varchar(20) not null
)ENGINE = InnoDB;

CREATE TABLE VENDITORE(
	IDVenditore integer auto_increment primary key,
	Nome varchar(30) not null
)ENGINE = InnoDB;

CREATE TABLE NAZIONE(
	IDNazione varchar(2) primary key,
	Nome varchar(20) not null,
	Continente varchar(30) not null
)ENGINE = InnoDB;

CREATE TABLE INDIRIZZO(
	IDIndirizzo integer auto_increment primary key,
	Via varchar(50) not null,
	NumeroCivico varchar(4) not null,
	CAP varchar(5) not null,
	Citta varchar(40) not null,
	Provincia varchar(20) not null,
	Nazione varchar(2) not null,
	foreign key (Nazione) references NAZIONE(IDNazione)
)ENGINE = InnoDB;

CREATE TABLE MAGAZZINO(
	IDMagazzino varchar(20) primary key,
	Indirizzo integer not null,
	foreign key (Indirizzo) references INDIRIZZO(IDIndirizzo)
)ENGINE = InnoDB;

CREATE TABLE PRODOTTO(
	IDProdotto varchar(10) primary key,
	Categoria integer not null,
	Nome varchar(50) not null,
	Venditore integer not null,
	Prezzo float(2) not null,
	ScontoPercentuale integer not null default 0,
	QuantitaDisponibile integer not null default 0,
	foreign key (Categoria) references CATEGORIA(IDCategoria),
	foreign key (Venditore) references VENDITORE(IDVenditore)
)ENGINE = InnoDB;

CREATE TABLE CLIENTE(
	CodiceFiscale char(11) primary key,
	Nome varchar(20) not null,
	Cognome varchar(20) not null,
	Mail varchar(50) not null,
	Password varchar(30) not null,
	DataNascita date,
	Sesso char(1),
	isAzienda boolean not null,
	PartitaIVA varchar(11),
	IndirizzoFatturazione integer not null,
	isActive boolean not null default true,
	unique(Mail),
	foreign key (IndirizzoFatturazione) references INDIRIZZO(IDIndirizzo)
)ENGINE = InnoDB;

CREATE TABLE METODO_DI_PAGAMENTO(
	IDMetodo integer auto_increment primary key,
	Tipo varchar(20) not null,
	NomeIntestatario varchar(50),
	NumeroCarta varchar(11)
)ENGINE = InnoDB;

CREATE TABLE METODO_DI_PAGAMENTO_CLIENTE(
	Cliente char(11),
	MetodoPagamento integer,
	primary key (Cliente, MetodoPagamento),
	foreign key (Cliente) references CLIENTE(CodiceFiscale),
	foreign key (MetodoPagamento) references METODO_DI_PAGAMENTO(IDMetodo)
)ENGINE = InnoDB;

CREATE TABLE STATO(
	IDStato integer auto_increment primary key,
	Nome varchar(30) not null
)ENGINE = InnoDB;

CREATE TABLE ORDINE(
	IDOrdine integer auto_increment primary key,
	Cliente char(11) not null,
	Data date not null,
	MetodoPagamento integer not null,
	IndirizzoSpedizione integer not null,
	StatoOrdine integer not null,
	foreign key (Cliente) references CLIENTE(CodiceFiscale),
	foreign key (MetodoPagamento) references METODO_DI_PAGAMENTO(IDMetodo),
	foreign key (IndirizzoSpedizione) references INDIRIZZO(IDIndirizzo),
	foreign key (StatoOrdine) references STATO(IDStato)
)ENGINE = InnoDB;

CREATE TABLE SPEDIZIONE(
	IDSpedizione integer auto_increment primary key,
	Ordine integer not null,
	isInternazionale boolean not null,
	DataConsegna date not null,
	foreign key (Ordine) references ORDINE(IDOrdine)
)ENGINE = InnoDB;

CREATE TABLE RESO(
	IDReso integer auto_increment primary key,
	Prodotto varchar(10) not null,
	Ordine integer not null,
	DataReso date not null,
	QuantitaResa integer not null,
	unique(Prodotto, Ordine),
	foreign key (Prodotto) references PRODOTTO(IDProdotto),
	foreign key (Ordine) references ORDINE(IDOrdine)
)ENGINE = InnoDB;

CREATE TABLE INDIRIZZO_SPEDIZIONE_CLIENTE(
	Indirizzo integer not null,
	Cliente char(11) not null,
	primary key(Indirizzo, Cliente),
	foreign key (Indirizzo) references INDIRIZZO(IDIndirizzo),
	foreign key (Cliente) references CLIENTE(CodiceFiscale)
)ENGINE = InnoDB;

CREATE TABLE SPEDIZIONE_PRODOTTO(
	Spedizione integer not null,
	Prodotto varchar(10) not null,
	QuantitaSpedita integer not null,
	primary key (Spedizione, Prodotto),
	foreign key (Spedizione) references SPEDIZIONE(IDSpedizione),
	foreign key (Prodotto) references PRODOTTO(IDProdotto)
)ENGINE = InnoDB;

CREATE TABLE COMPOSIZIONE(
	Ordine integer not null,
	Prodotto varchar(10) not null,
	QuantitaOrdinata integer not null,
	primary key (Ordine, Prodotto),
	foreign key (Ordine) references ORDINE(IDOrdine),
	foreign key (Prodotto) references PRODOTTO(IDProdotto)
) ENGINE = InnoDB;

CREATE TABLE LOCALIZZAZIONE(
	Magazzino varchar(20) not null,
	Prodotto varchar(10) not null,
	QuantitaDisponibile integer not null default 0,
	primary key (Magazzino, Prodotto),
	foreign key (Magazzino) references MAGAZZINO(IDMagazzino),
	foreign key (Prodotto) references PRODOTTO(IDProdotto)
)ENGINE = InnoDB;

CREATE VIEW numeroOrdini AS
	SELECT C.CodiceFiscale, COUNT(*) AS NumeroOrdini
	FROM CLIENTE AS C 
		INNER JOIN ORDINE AS O ON C.CodiceFiscale = O.Cliente
	GROUP BY C.CodiceFiscale ;
	

/*CREA PROCEDURE*/
/* Stored Procedures */

DROP PROCEDURE IF EXISTS aggiornaDisponibilita;
DROP PROCEDURE IF EXISTS aggiungPezziMagazzino;
DROP PROCEDURE IF EXISTS ordiniNonEvasi;
DROP PROCEDURE IF EXISTS stampaProdottiOrdinati;


/* Impone la quantià disponibile di un prodotto uguale alla somma
	delle quantità di quel prodotto nei vari magazzini */
DELIMITER $$
CREATE PROCEDURE aggiornaDisponibilita(IN codiceProdotto varchar(10))
	BEGIN
	UPDATE PRODOTTO
	SET QuantitaDisponibile = (
		SELECT SUM(QuantitaDisponibile)
		FROM LOCALIZZAZIONE
		WHERE Prodotto = codiceProdotto
		GROUP BY codiceProdotto
	)
	WHERE IDProdotto = codiceProdotto ;
	END $$ 
DELIMITER ;
/*
	Aggiunge pezzi di un certo prodotto in un certo magazzino.
	I dati in input si ritengono corretti
*/
DELIMITER $$
CREATE PROCEDURE aggiungPezziMagazzino(IN codiceMagazzino varchar(20), IN codiceProdotto varchar(10), IN daAggiungere integer)
	BEGIN
	START TRANSACTION;
	UPDATE LOCALIZZAZIONE
	SET QuantitaDisponibile = QuantitaDisponibile + daAggiungere
	WHERE Magazzino = codiceMagazzino AND Prodotto = codiceProdotto;
	UPDATE PRODOTTO
	SET QuantitaDisponibile = QuantitaDisponibile + daAggiungere
	WHERE IDProdotto = codiceProdotto;
	COMMIT WORK;
END $$
DELIMITER ;

/* Stampa gli ordini non evasi */
DELIMITER $$
CREATE PROCEDURE ordiniNonEvasi (IN cliente varchar(11))
BEGIN
	SELECT O.IDOrdine
	FROM ORDINE AS O
	WHERE O.Cliente = cliente AND O.StatoOrdine <> 5 ;
END $$
DELIMITER ;


/* La seconda query stampa tutti i prodotti ( e gli ordini di appartenenza ) ordinati da un certo cliente.
Avendo la necessità di rendere la query parametrica viene implementata come stored procedure*/
DELIMITER $$
CREATE PROCEDURE stampaProdottiOrdinati(IN cliente varchar(11))
BEGIN 
	SELECT O.IDOrdine, O.Cliente, C.Nome, C.Cognome, O.Data, P.Nome
	FROM ORDINE AS O
		INNER JOIN CLIENTE AS C ON O.Cliente = C.CodiceFiscale
		INNER JOIN COMPOSIZIONE AS CO ON O.IDOrdine = CO.Ordine
		INNER JOIN PRODOTTO AS P ON CO.Prodotto = P.IDProdotto
	WHERE O.Cliente = cliente ;
END $$
DELIMITER ;

/*CREA TRIGGER*/


DROP TRIGGER IF EXISTS  quantitaNonNegativa;
DROP TRIGGER IF EXISTS verficaLocalizzazione;
DROP TRIGGER IF EXISTS aggiornaDisponibilita;
DROP TRIGGER IF EXISTS verificaOrdine;
DROP TRIGGER IF EXISTS verificaReso;
DROP TRIGGER IF EXISTS contrassegnoDefault;


/* Controllo della non negatività della quantità di un prodotto inserito */
DELIMITER $$
CREATE TRIGGER quantitaNonNegativa
BEFORE INSERT ON PRODOTTO
FOR EACH ROW
BEGIN
	IF new.QuantitaDisponibile < 0 THEN
		SIGNAL SQLSTATE VALUE '45000'
			SET MESSAGE_TEXT = '[TABLE: PRODOTTO] - QuantitaDisponibile non valida';
	END IF;
	SET NEW.QuantitaDisponibile = 0;
END; $$
DELIMITER ;

/*Controllo quantitità prodotto non negativa in LOCALIZZAZIONE*/
DELIMITER $$
CREATE TRIGGER verficaLocalizzazione
BEFORE INSERT ON LOCALIZZAZIONE
FOR EACH ROW
BEGIN
    IF new.QuantitaDisponibile < 0 THEN
        SIGNAL SQLSTATE VALUE '45000'
			SET MESSAGE_TEXT = '[TABLE: LOCALIZZAZIONE] - QuantitaDisponibile non valida';
	END IF;
END; $$
DELIMITER ;


/* Aggiorna la QuantitaDisponibile in PRODOTTO quando viene inserito collegata a un
	magazzino*/
DELIMITER $$
CREATE TRIGGER aggiornaDisponibilita
AFTER INSERT ON LOCALIZZAZIONE
FOR EACH ROW
BEGIN
	CALL aggiornaDisponibilita(NEW.Prodotto);
END; $$
DELIMITER ;


/* Verifica che l'indirizzo di spedizione dell'ordine e il metodo di pagamento
	appartengano al cliente che ha effettuato l'ordine */
DELIMITER $$
CREATE TRIGGER verificaOrdine
BEFORE INSERT ON ORDINE
FOR EACH ROW
BEGIN
	DECLARE numeroIndirizzi INTEGER;
	DECLARE numeroMetodi INTEGER;
	SELECT COUNT(*) INTO numeroIndirizzi
	FROM INDIRIZZO_SPEDIZIONE_CLIENTE AS IC
	WHERE IC.Cliente = NEW.Cliente AND IC.Indirizzo = NEW.IndirizzoSpedizione;
	IF numeroIndirizzi = 0 THEN
		SIGNAL SQLSTATE VALUE '45000'
			SET MESSAGE_TEXT = '[TABLE : ORDINI] - Indirizzo di spedizione deve essere un indirizzo del cliente';
    END IF;
	SELECT COUNT(*) INTO numeroMetodi
	FROM METODO_DI_PAGAMENTO_CLIENTE AS MC
	WHERE MC.Cliente = NEW.Cliente AND MC.MetodoPagamento = NEW.MetodoPagamento;
	IF numeroMetodi = 0 THEN
		SIGNAL SQLSTATE VALUE '45000'
			SET MESSAGE_TEXT = '[TABLE : ORDINI] - Il metodo di pagamento ordine deve appartenere al cliente';
    END IF;
END; $$
DELIMITER ;


/*Verifica tutti i vincoli che sussistono sulla tabella RESO*/
DELIMITER $$
CREATE TRIGGER verificaReso
BEFORE INSERT ON RESO
FOR EACH ROW
BEGIN
	/* Il prodotto deve appartenere all'ordine a cui il reso si riferisce */
	DECLARE numeroProdotti INTEGER;
    SELECT COUNT(*) INTO numeroProdotti
    FROM COMPOSIZIONE AS C
    WHERE C.Prodotto = NEW.Prodotto AND C.Ordine = NEW.Ordine;
    IF numeroProdotti = 0 THEN
    	SIGNAL SQLSTATE VALUE '45000'
    		SET MESSAGE_TEXT = '[TABLE : RESO] - Il prodotto deve appartenere a ordine a cui il reso si riferisce';
    END IF;
    /*La quantità di prodotto resa deve essere minore o uguale a quella ordinata */
    IF NEW.QuantitaResa > (
    	SELECT C.QuantitaOrdinata
    	FROM COMPOSIZIONE as C
    	WHERE NEW.Ordine = C.Ordine AND NEW.Prodotto = C.Prodotto
    	) THEN
    		SIGNAL SQLSTATE VALUE '45000'
    			SET MESSAGE_TEXT = '[TABLE : RESO] - La quantità resa deve essere minore o uguale alla quantità ordinata';
    END IF;
    /* Il reso di un prodotto può essere richiesto al massimo dopo 14 giorni dalla data di consegna */
    IF DATEDIFF(new.DataReso, (
    	SELECT S.DataConsegna
    	FROM SPEDIZIONE AS S
    		INNER JOIN SPEDIZIONE_PRODOTTO AS SP ON S.IDSpedizione = SP.Spedizione
    	WHERE SP.Prodotto = NEW.Prodotto )) > 14 THEN
    		SIGNAL SQLSTATE VALUE '45000'
    			SET MESSAGE_TEXT = '[TABLE : RESO] - Il reso può essere richiesto al massimo dopo 14 giorni';
    END IF;
END; $$
DELIMITER ;



/*Inserisce come metodo di pagamento di default per ogni nuovo cliente il contrassegno*/
DELIMITER $$
CREATE TRIGGER `contrassegnoDefault`
AFTER INSERT ON `CLIENTE`
FOR EACH ROW
BEGIN
	insert into METODO_DI_PAGAMENTO_CLIENTE values(new.CodiceFiscale, '1');
END; $$
DELIMITER ;

/*CREA FUNZIONI*/
DROP FUNCTION IF EXISTS numeroOrdini;
DROP FUNCTION IF EXISTS prezzoProdotto;
DROP FUNCTION IF EXISTS totaleSpesoCliente;

DELIMITER $$
CREATE FUNCTION numeroOrdini(cliente varchar(11), numeroMesi integer)
RETURNS INTEGER
BEGIN
	DECLARE numero INTEGER;
	SELECT COUNT(*) INTO numero
	FROM ORDINE AS O
	WHERE O.Cliente = cliente AND DATEDIFF(CURDATE(), O.Data) < numeroMesi * 30;
	RETURN numero;
END; $$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION prezzoProdotto(codiceProdotto varchar(10))
RETURNS FLOAT(2)
BEGIN
	DECLARE scontoPercentuale INTEGER;
	DECLARE prezzo FLOAT(2);
	SELECT P.ScontoPercentuale INTO scontoPercentuale
	FROM PRODOTTO AS P
	WHERE P.IDProdotto = codiceProdotto ;
    SELECT P.Prezzo INTO prezzo 
    FROM PRODOTTO AS P
    WHERE P.IDProdotto =  codiceProdotto;
    
	RETURN prezzo - (scontoPercentuale/100 * prezzo);
END; $$
DELIMITER ;

DELIMITER $$
CREATE FUNCTION totaleSpesoCliente(cliente  varchar(11))
RETURNS FLOAT(2)
BEGIN
	DECLARE totale FLOAT(2);
	DECLARE numeroOrdini INTEGER;
	SELECT SUM(CM.QuantitaOrdinata * prezzoProdotto(CM.Prodotto)) INTO totale
	FROM ORDINE AS O
		INNER JOIN CLIENTE AS C ON O.Cliente = C.CodiceFiscale 
		INNER JOIN COMPOSIZIONE AS CM ON CM.Ordine = O.IDOrdine
	WHERE C.CodiceFiscale = cliente ;
	SELECT COUNT(*) INTO numeroOrdini 
	FROM ORDINE AS O
	WHERE O.Cliente = cliente;
	IF numeroOrdini = 0 THEN
			RETURN 0;
	END IF;
	RETURN totale;
END; $$
DELIMITER ;


/*INSERIMENTO DATI*/


INSERT INTO NAZIONE VALUES ('IT', 'Italia', 'Europa');
INSERT INTO NAZIONE VALUES ('EN', 'England', 'Europa');
INSERT INTO NAZIONE VALUES ('DE', 'Deutschland', 'Europa');
INSERT INTO NAZIONE VALUES ('N1', 'Nazione1', 'Continente1');
INSERT INTO NAZIONE VALUES ('N2', 'Nazione2', 'Continente2');
INSERT INTO NAZIONE VALUES ('N3', 'Nazione3', 'Continente1');
INSERT INTO NAZIONE VALUES ('N4', 'Nazione4', 'Continente3');
INSERT INTO NAZIONE VALUES ('N5', 'Nazione5', 'Continente2');
INSERT INTO NAZIONE VALUES ('N6', 'Nazione6', 'Continente3');
INSERT INTO NAZIONE VALUES ('N7', 'Nazione7', 'Continente4');
INSERT INTO NAZIONE VALUES ('N8', 'Nazione8', 'Continente5');
INSERT INTO NAZIONE VALUES ('N9', 'Nazione9', 'Continente2');

INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via Roma', '10', '35100', 'Padova', 'Padova', 'IT');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via Venezia', '100', '35100', 'Padova', 'Padova', 'IT');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Santa Croce', '200', '30135', 'Venezia', 'Venezia', 'IT');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Downing Street', '10', 'SW1A', 'London', 'London', 'EN');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Willy-Brandt-Straße', '/', '10557', 'Berlin', 'Berlin', 'DE');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via1', '1', '10000', 'Citta1', 'Provincia1', 'N1');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via2', '2', '20000', 'Citta2', 'Provincia2', 'N2');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via3', '3', '30000', 'Citta3', 'Provincia3', 'N3');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via4', '4', '40000', 'Citta4', 'Provincia4', 'N4');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via5', '5', '50000', 'Citta5', 'Provincia5', 'N5');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via6', '6', '60000', 'Citta6', 'Provincia6', 'N6');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via7', '7', '70000', 'Citta7', 'Provincia7', 'N7');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via8', '8', '80000', 'Citta8', 'Provincia8', 'N8');
INSERT INTO INDIRIZZO (`Via`, `NumeroCivico`, `CAP`, `Citta`, `Provincia`, `Nazione`) values ('Via9', '9', '90000', 'Citta9', 'Provincia9', 'N9');

INSERT INTO MAGAZZINO VALUES('Mag1', 5);
INSERT INTO MAGAZZINO VALUES('Mag2', 12);
INSERT INTO MAGAZZINO VALUES('Mag3', 14);
INSERT INTO MAGAZZINO VALUES('Mag4', 7);
INSERT INTO MAGAZZINO VALUES('Mag5', 2);
INSERT INTO MAGAZZINO VALUES('Mag6', 1);
INSERT INTO MAGAZZINO VALUES('Mag7', 3);

insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Contrassegno', NULL, NULL);
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Mario Rossi', '12345678901');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Antonio Verdi', '09876543210');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Giuseppe Verdi', '09876543211');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome1 Cognome1', '1359843524');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome2 Cognome2', '1822486918');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome3 Cognome3', '1441576633');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome4 Cognome4', '1900006867');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome5 Cognome5', '1119339557');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome6 Cognome6', '1192215658');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome7 Cognome7', '1202203615');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome8 Cognome8', '1419915059');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome9 Cognome9', '1439489202');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome10 Cognome10', '1763075259');
insert into METODO_DI_PAGAMENTO (`Tipo`, `NomeIntestatario`, `NumeroCarta`) values ('Carta di Credito', 'Nome11 Cognome11', '1885851726');

insert into CLIENTE VALUES('CODFISC0001', 'Mario', 'Rossi', 'mario.rossi@project.com', 'password1', '1960-01-01', 'M', '0', NULL, '1', '1');
insert into CLIENTE VALUES('CODFISC0002', 'Antonio', 'Verdi', 'antonio.verdi@project.it', 'password2', '1980-05-25', 'M', '0', NULL, '2', '1');
insert into CLIENTE VALUES('CODFISC0003', 'Giulia', 'Milano', 'giulia_milano@project.cloud', 'password3', '1990-09-12', 'F', '0', NULL, '2', '1');
insert into CLIENTE VALUES('CODFISC4', 'Nome4', 'Cognome4', 'email4@project.com', 'password4', '1971-7-7', 'M', '0', NULL, '4', '1');
insert into CLIENTE VALUES('CODFISC5', 'Nome5', 'Cognome5', 'email5@project.com', 'password5', '1972-2-8', 'F', '0', NULL, '5', '1');
insert into CLIENTE VALUES('CODFISC6', 'Nome6', 'Cognome6', 'email6@project.com', 'password6', '1963-7-9', 'F', '0', NULL, '6', '1');
insert into CLIENTE VALUES('CODFISC7', 'Nome7', 'Cognome7', 'email7@project.com', 'password7', '1984-11-3', 'F', '0', NULL, '7', '1');
insert into CLIENTE VALUES('CODFISC8', 'Nome8', 'Cognome8', 'email8@project.com', 'password8', '1951-7-18', 'M', '0', NULL, '8', '1');
insert into CLIENTE VALUES('CODFISC9', 'Nome9', 'Cognome9', 'email9@project.com', 'password9', '1952-10-11', 'M', '0', NULL, '9', '1');
insert into CLIENTE VALUES('CODFISC10', 'Nome10', 'Cognome10', 'email10@project.com', 'password10', '1974-12-12', 'M', '0', NULL, '10', '1');
insert into CLIENTE VALUES('CODFISC11', 'Nome11', 'Cognome11', 'email11@project.com', 'password11', '1973-8-27', 'F', '0', NULL, '11', '1');
insert into CLIENTE VALUES('CODFISC12', 'Nome12', 'Cognome12', 'email12@project.com', 'password12', '1978-12-9', 'M', '0', NULL, '12', '1');
insert into CLIENTE VALUES('CODFISC13', 'Nome13', 'Cognome13', 'email13@project.com', 'password13', '1962-6-2', 'M', '0', NULL, '13', '1');
insert into CLIENTE VALUES('CODFISC14', 'Nome14', 'Cognome14', 'email14@project.com', 'password14', '1968-1-30', 'F', '0', NULL, '14', '1');
insert into CLIENTE VALUES('CODFISC15', 'NomeAzienda15', 'NULL', 'azienda15@project.com', 'password15', '1983-9-26', 'NULL', '0', 'PIVA15', '4', '1');
insert into CLIENTE VALUES('CODFISC16', 'NomeAzienda16', 'NULL', 'azienda16@project.com', 'password16', '1982-3-7', 'NULL', '0', 'PIVA16', '2', '1');
insert into CLIENTE VALUES('CODFISC17', 'NomeAzienda17', 'NULL', 'azienda17@project.com', 'password17', '1985-3-18', 'NULL', '0', 'PIVA17', '6', '1');
insert into CLIENTE VALUES('CODFISC18', 'NomeAzienda18', 'NULL', 'azienda18@project.com', 'password18', '1989-9-23', 'NULL', '0', 'PIVA18', '8', '1');
insert into CLIENTE VALUES('CODFISC19', 'NomeAzienda19', 'NULL', 'azienda19@project.com', 'password19', '1957-10-30', 'NULL', '0', 'PIVA19', '1', '1');

INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC4', '4');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC5', '5');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC6', '6');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC7', '7');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC8', '8');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC9', '9');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC10', '10');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC11', '11');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC12', '12');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC13', '13');
INSERT INTO `METODO_DI_PAGAMENTO_CLIENTE` (`Cliente`, `MetodoPagamento`) VALUES ('CODFISC14', '14');

INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('1', 'CODFISC0001');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('2', 'CODFISC0002');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('3', 'CODFISC0003');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('4', 'CODFISC4');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('5', 'CODFISC5');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('6', 'CODFISC6');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('7', 'CODFISC7');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('8', 'CODFISC8');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('9', 'CODFISC9');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('10', 'CODFISC10');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('11', 'CODFISC11');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('12', 'CODFISC12');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('13', 'CODFISC13');
INSERT INTO `INDIRIZZO_SPEDIZIONE_CLIENTE` (`Indirizzo`, `Cliente`) VALUES ('14', 'CODFISC14');

INSERT INTO CATEGORIA (`Nome`) VALUES ('Elettronica');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Informatica');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Moda');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Salute e Benessere');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Prodotti per la casa');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Auto');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Sport');
INSERT INTO CATEGORIA (`Nome`) VALUES ('CD e Vinili');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Film');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Tempo libero');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Cancelleria');
INSERT INTO CATEGORIA (`Nome`) VALUES ('Libri');

insert into VENDITORE (`Nome`) VALUES ('Apple Inc.');
insert into VENDITORE (`Nome`) VALUES ('Microsoft Corporation');
insert into VENDITORE (`Nome`) VALUES ('Venditore1');
insert into VENDITORE (`Nome`) VALUES ('Venditore2');
insert into VENDITORE (`Nome`) VALUES ('Venditore3');
insert into VENDITORE (`Nome`) VALUES ('Venditore4');
insert into VENDITORE (`Nome`) VALUES ('Venditore5');
insert into VENDITORE (`Nome`) VALUES ('Venditore6');
insert into VENDITORE (`Nome`) VALUES ('Venditore7');
insert into VENDITORE (`Nome`) VALUES ('Venditore8');
insert into VENDITORE (`Nome`) VALUES ('Venditore9');
insert into VENDITORE (`Nome`) VALUES ('Venditore10');

insert into STATO (`Nome`) VALUES ('Ordine ricevuto');
insert into STATO (`Nome`) VALUES ('Pagamento ricevuto');
insert into STATO (`Nome`) VALUES ('In lavorazione');
insert into STATO (`Nome`) VALUES ('In preparazione alla spedizione');
insert into STATO (`Nome`) VALUES ('Spedito');

insert into PRODOTTO values('AAPL1', '1', 'Apple iPhone X 64GB', '1',  1189, 0, 10);
insert into PRODOTTO values('AAPL2', '2', 'Apple MacBook Pro 15 256GB', '1',  2899, 0, 3);
insert into PRODOTTO values('MS1', '2', 'Microsoft Surface Laptop 512GB-i7-16GB', 2, 2549,0, 5);
insert into PRODOTTO values('COD1', '1', 'Nome Prodotto1', '4',  2395, 3, 1);
insert into PRODOTTO values('COD2', '12', 'Nome Prodotto2', '2',  2490, 5, 23);
insert into PRODOTTO values('COD3', '7', 'Nome Prodotto3', '5',  2288, 9, 52);
insert into PRODOTTO values('COD4', '4', 'Nome Prodotto4', '7',  2449, 0, 31);
insert into PRODOTTO values('COD5', '6', 'Nome Prodotto5', '2',  2320, 5, 12);
insert into PRODOTTO values('COD6', '11', 'Nome Prodotto6', '3',  844, 3, 68);
insert into PRODOTTO values('COD7', '6', 'Nome Prodotto7', '11',  11, 0, 69);
insert into PRODOTTO values('COD8', '3', 'Nome Prodotto8', '12',  21, 8, 32);
insert into PRODOTTO values('COD9', '2', 'Nome Prodotto9', '7',  13, 1, 56);
insert into PRODOTTO values('COD10', '12', 'Nome Prodotto10', '5',  28, 7, 78);
insert into PRODOTTO values('COD11', '6', 'Nome Prodotto11', '4',  44, 0, 66);
insert into PRODOTTO values('COD12', '8', 'Nome Prodotto12', '3',  16, 0, 89);
insert into PRODOTTO values('COD13', '9', 'Nome Prodotto13', '1',  47, 7, 15);
insert into PRODOTTO values('COD14', '9', 'Nome Prodotto14', '3',  37, 0, 79);
insert into PRODOTTO values('COD15', '7', 'Nome Prodotto15', '10',  32, 6, 41);
insert into PRODOTTO values('COD16', '5', 'Nome Prodotto16', '12',  27, 6, 55);

INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag1', 'COD1', '7');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag2', 'COD2', '5');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag3', 'COD3', '19');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag4', 'COD4', '12');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag5', 'COD5', '1');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag6', 'COD6', '2');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag7', 'COD7', '3');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag1', 'COD8', '7');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag2', 'COD9', '5');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag3', 'COD10', '19');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag4', 'COD11', '12');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag5', 'COD12', '1');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag6', 'COD13', '2');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag7', 'COD14', '3');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag1', 'COD14', '7');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag2', 'COD13', '5');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag3', 'COD12', '19');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag4', 'COD15', '12');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag5', 'COD10', '1');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag6', 'COD9', '2');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag7', 'COD8', '3');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag2', 'COD8', '5');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag3', 'COD9', '19');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag4', 'COD10', '12');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag5', 'COD11', '1');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag6', 'COD12', '2');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag7', 'COD13', '3');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag1', 'COD3', '7');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag2', 'COD4', '5');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag3', 'COD5', '19');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag4', 'COD6', '12');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag5', 'COD7', '1');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag6', 'COD8', '2');
INSERT INTO `LOCALIZZAZIONE` (`Magazzino`, `Prodotto`, `QuantitaDisponibile`) VALUES ('Mag7', 'COD9', '3');

INSERT INTO `ORDINE` VALUES (1, 'CODFISC0001', '2018-01-15', 1, 1, 3);
INSERT INTO `ORDINE` VALUES (2, 'CODFISC4', '2018-01-14', 4, 4, 3);
INSERT INTO `ORDINE` VALUES (3, 'CODFISC5', '2018-01-03', 5, 5, 1);

INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('1', 'COD1', '1');
INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('1', 'COD3', '1');
INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('3', 'COD4', '5');
INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('2', 'COD7', '2'); 
INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('2', 'COD6', '3');
INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('1', 'COD12', '2');
INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('1', 'COD9', '4');
INSERT INTO `COMPOSIZIONE` (`Ordine`, `Prodotto`, `QuantitaOrdinata`) VALUES ('2', 'COD3', '1');

INSERT INTO `SPEDIZIONE` (`IDSpedizione`, `Ordine`, `isInternazionale`, `DataConsegna`) VALUES ('1', '1', '0', '2018-01-19');
INSERT INTO `SPEDIZIONE` (`IDSpedizione`, `Ordine`, `isInternazionale`, `DataConsegna`) VALUES ('2', '2', '0', '2018-01-31');
INSERT INTO `SPEDIZIONE` (`IDSpedizione`, `Ordine`, `isInternazionale`, `DataConsegna`) VALUES ('3', '3', '1', '2018-01-24');

INSERT INTO `SPEDIZIONE_PRODOTTO` (`Spedizione`, `Prodotto`, `QuantitaSpedita`) VALUES ('1', 'COD1', '1');
INSERT INTO `SPEDIZIONE_PRODOTTO` (`Spedizione`, `Prodotto`, `QuantitaSpedita`) VALUES ('1', 'COD3', '1');
INSERT INTO `SPEDIZIONE_PRODOTTO` (`Spedizione`, `Prodotto`, `QuantitaSpedita`) VALUES ('3', 'COD4', '5');
INSERT INTO `SPEDIZIONE_PRODOTTO` (`Spedizione`, `Prodotto`, `QuantitaSpedita`) VALUES ('2', 'COD7', '2'); 
INSERT INTO `SPEDIZIONE_PRODOTTO` (`Spedizione`, `Prodotto`, `QuantitaSpedita`) VALUES ('2', 'COD6', '3');

INSERT INTO `RESO` (`IDReso`, `Prodotto`, `Ordine`, `DataReso`, `QuantitaResa`) VALUES ('1', 'COD1', '1', '2018-01-18', '1');
INSERT INTO `RESO` (`IDReso`, `Prodotto`, `Ordine`, `DataReso`, `QuantitaResa`) VALUES ('2', 'COD4', '3', '2018-01-16', '3');

/*QUERY AS VIEW*/
DROP VIEW IF EXISTS ProdottiInMagazzino;
DROP VIEW IF EXISTS ProdottiNonOrdinati; 
DROP VIEW IF EXISTS ClientiAzienda;
DROP VIEW IF EXISTS NumeroOrdiniClienti;
DROP VIEW IF EXISTS ClientiNumeroMassimoOrdini;
DROP VIEW IF EXISTS TotaleSpesoClienti;

/* Per ogni magazzino la lista di prodotti presenti con la quantità */
CREATE VIEW ProdottiInMagazzino AS
SELECT L.Magazzino, L.Prodotto AS CodiceProdotto, P.Nome, L.QuantitaDisponibile
FROM LOCALIZZAZIONE AS L
	INNER JOIN PRODOTTO AS P ON L.Prodotto = P.IDProdotto
ORDER BY L.Magazzino ;


/* Ritorna l'elenco dei codici dei prodotti che non sono mai stati ordinati */
CREATE VIEW ProdottiNonOrdinati AS
SELECT P.IDProdotto
FROM PRODOTTO AS P
WHERE P.IDProdotto <> ALL (
	SELECT C.Prodotto
	FROM COMPOSIZIONE AS C) ;


/* Lista dei cliente che sono di tipo azienda */
CREATE VIEW ClientiAzienda AS
SELECT C.PartitaIVA, C.Nome, C.IndirizzoFatturazione
FROM CLIENTE AS C
WHERE C.PartitaIVA IS NOT NULL ;



/* Stampa il numero di ordini degli ultimi sei mesi e dell'ultimo anno per ogni cliente */
CREATE VIEW  NumeroOrdiniClienti AS 
SELECT C.CodiceFiscale, C.Nome, C.Cognome, C.PartitaIVA, numeroOrdini(C.CodiceFiscale, 6) AS NumeroOrdiniSeiMesi, numeroOrdini(C.CodiceFiscale, 12) AS NumeroOrdiniUltimoAnno
FROM CLIENTE AS C
WHERE C.isActive = true;


/* Ritorna il codice fiscale del cliente che ha effettuato il numero massimo degli ordini */
CREATE VIEW ClientiNumeroMassimoOrdini AS
SELECT NO.CodiceFiscale, NO.NumeroOrdini
FROM  numeroOrdini AS NO
WHERE NO.NumeroOrdini >= ALL(
		SELECT NO.NumeroOrdini
		FROM numeroOrdini as NO) ;

/* Stampa per ogni cliente il totale speso in iCommerce */
CREATE VIEW TotaleSpesoClienti AS
SELECT C.CodiceFiscale, totaleSpesoCliente(C.CodiceFiscale)
FROM CLIENTE AS C 
ORDER BY C.CodiceFiscale;
