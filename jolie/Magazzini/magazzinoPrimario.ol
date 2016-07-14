include "interfacciaMagazzinoPrimario.iol"
include "string_utils.iol"
include "console.iol"
include "math.iol"
include "time.iol"
include "database.iol"

/*include "../ServizioDistanza/DistanceInterface.iol"
include "../Fornitore/SupplierInterface.iol"
include "../Corriere/CorriereInterface.iol"*/

inputPort InputOrdine {
	Location: "socket://localhost:8000"
	Protocol: soap
	Interfaces: InterfacciaMagazzinoPrimario
}

outputPort MagazzinoPrimario {
	Location: "socket://localhost:8000"
	Protocol: soap
	Interfaces: InterfacciaMagazzinoPrimario
}

/*
outputPort MagazzinoSecondario1 {
	Location: "socket://localhost:8001"
	Protocol: soap
	Interfaces: InterfMagazzinoSecondario
}

outputPort CalcoloDistanze {
	Location: "socket://localhost:8100"
	Protocol: http
	Interfaces: DistanceInterface
}

outputPort SupplierServer {
	Location: "socket://localhost:8300"
	Protocol: http
	Interfaces: SupplierInterface
}

outputPort CorriereServer{
	Location: "socket://localhost:8400"
	Protocol: http
	Interfaces: CorriereInterface
}
*/

define log {
	getCurrentDateTime@Time(null)(ts); 
	println@Console(ts + " - " + daStampare)()
}

define leggiImpostazioni {
  parseIniFile@IniUtils("magazzinoPrimario.conf")(configInfo);

  username = configInfo.database.username;
  password = configInfo.database.password;
  host = configInfo.database.host;
  port = int(configInfo.database.port);
  database = configInfo.database.url;
  driver = configInfo.database.driver
}

define connettiDB {
	scope( scopeConnettiDB ) {
		install(DriverClassNotFound => messaggioDaStampare = "[ERROR] - Driver class not found"; log );
		install(InvalidDriver => messaggioDaStampare = "[ERROR] - Invalid driver"; log );
		install(ConnectionError => messaggioDaStampare = "[ERROR] - Connection error"; log );

		with ( connectionInfo ) {
			.username = username;
			.password = password;
			.host = host;
			.port = port;
			.database = database; // "." for memory-only
			.driver = driver
		};

		connect@Database( connectionInfo )( void )
	}
}

define disconnettiDB {
  scope(scopeDisconnettiDB) {
    close@Database()()
    //messaggioDaStampare = "disconnesso dal database"; log
  }
}

define inizializzaInfoMagazzini {
  scope(scopeInizializzaInfoMagazzini) {  

    connettiDB;

    scope(selection) {
      queryRequest = 
        "SELECT id, nazione, provincia, citta, via, cap FROM magazzino ";
      query@Database( queryRequest )( queryResponse );
      // Il magazzino principale ha id 1
      for(i = 0, i < #queryResponse.row, ++i) {
        magazzini[i].id = queryResponse.row[i].ID;
        magazzini[i].nazione = queryResponse.row[i].NAZIONE;
        magazzini[i].provincia = queryResponse.row[i].PROVINCIA;
        magazzini[i].citta = queryResponse.row[i].CITTA;
        magazzini[i].via = queryResponse.row[i].VIA;
        magazzini[i].cap = queryResponse.row[i].CAP;
      }
    };
    disconnettiDB
  }
}

execution{ concurrent }

init {
	daStampare = "Inizio procedura Magazzino Primario"; log;
	leggiImpostazioni;
	inizializzaInfoMagazzini;

	magazzinoPrimario << magazzini[0];
}

main {

	[verificaDisponibilitaERiservaPezzi ( Ordine )( InformazioniSpedizioni ) {
		scope( verificaDisponibilitaERiservaPezzi ) {

		}
	}] {daStampare = "Eseguita verificaDisponibilitaERiservaPezzi"; log}

	[eseguoOrdine ( Ordine )( ConfermeSpedizioni ) {
		scope( eseguoOrdine ) {
			
		}
	}] {daStampare = "Eseguita eseguoOrdine"; log}

}