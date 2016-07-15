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
        "SELECT id, provincia, citta FROM magazzino ";
      query@Database( queryRequest )( queryResponse );
      // Il magazzino principale ha id 1
      for(i = 0, i < #queryResponse.row, ++i) {
        magazzini[i].id = queryResponse.row[i].ID;
        magazzini[i].provincia = queryResponse.row[i].PROVINCIA;
        magazzini[i].citta = queryResponse.row[i].CITTA;
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

	[verificaDisponibilitaERiservaPezzi ( ordine )( risultato ){
		scope( verificaDisponibilitaERiservaPezzi ){
      indiceArray = 0;
      for (i = 0, i < #ordine.prodotti, ++i){
        for (j = 0, i < #ordine.prodotti[i].pezzi, ++i){
          pezziNecessari[indiceArray] = ordine.prodotti[i].pezzi[j];
          ++indiceArray
        }
      }
      verificaDisponibilitaPezziNelDBERiservaDisponibili@MagazzinoPrimario(ordine)(idPezziMancanti);
      if(#idPezziMancanti > 0){
        richiestaRiservaPezzi@Fornitore(idPezziMancanti)(confermaRiservaAvvenuta);
        for (i = 0, i < #confermaRiservaAvvenuta, ++i){
          if (confermaRiservaAvvenuta[i] == false)
            risultato = confermaRiservaAvvenuta[i]
        }
      }
		}
	}] {daStampare = "Eseguita verificaDisponibilitaERiservaPezzi"; log}

  [verificaDisponibilitaPezziNelDBERiservaDisponibili (ordine)(idPezziMancanti) {
    scope(verificaDisponibilitaPezziNelDBERiservaDisponibili) {
      connettiDB;
      indiceArray = 0;
      for (i = 0, i < #ordine.prodotti, ++i){
        pezziDiUnCiclo = false;
        if (#ordine.prodotti[i].pezzi > 1){
          pezziDiUnCiclo = true;
        }
        for (j = 0, j < #ordine.prodotti[i].pezzi, ++j){
          scope(selection) {
            queryRequest = 
              "SELECT id_pezzo, id_magazzino, quantita, riservati FROM pezzo_magazzino " + 
              "WHERE id_pezzo = :id_pez AND quantita > riservati";
            queryRequest.id_pez = ordine.prodotti[i].pezzi[j];
            query@Database( queryRequest )( queryResponse );
            idMagazzinoPiuVicino = null;
            distanzaMagazzinoPiuVicino = null;
            numeroRiservatiMagazzinoPiuVicino = null;
            for(i = 0, i < #queryResponse.row, ++i) {
              richiestaDistanza.origin.citta = magazzini[queryResponse.row[i].ID_MAGAZZINO].citta;
              richiestaDistanza.origin.provincia = magazzini[queryResponse.row[i].ID_MAGAZZINO].provincia;
              richiestaDistanza.destination.citta = ordine.cliente.indirizzo.citta;
              richiestaDistanza.destination.provincia = ordine.cliente.indirizzo.provincia;
              getBestDistance@CalcoloDistanze( richiestaDistanza ) ( rispostaDistanza );
              if (rispostaDistanza.status == "OK") {
                if (distanzaMagazzinoPiuVicino == null){
                  idMagazzinoPiuVicino = queryResponse.row[i].ID_MAGAZZINO;
                  distanzaMagazzinoPiuVicino = rispostaDistanza.distance;
                  numeroRiservatiMagazzinoPiuVicino = queryResponse.row[i].RISERVATI;
                } else {
                  if (distanzaMagazzinoPiuVicino > rispostaDistanza.distance){
                    idMagazzinoPiuVicino = queryResponse.row[i].ID_MAGAZZINO;
                    distanzaMagazzinoPiuVicino = rispostaDistanza.distance;
                    numeroRiservatiMagazzinoPiuVicino = queryResponse.row[i].RISERVATI;
                  }
                }
              }
            }
            if( idMagazzinoPiuVicino == null ) {
              idPezziMancanti[indiceArray] = ordine.prodotti[i].pezzi[j];
              ++indiceArray;
            } else {
              scope(update) {
                undef( updateRequest );
                updateRequest =
                      "UPDATE pezzo_magazzino " + 
                      "SET riservati = :riservato " + 
                      "WHERE id_magazzino = :id_magaz AND id_pezzo = :id_pez)";
                  updateRequest.riservato = numeroRiservatiMagazzinoPiuVicino + 1;
                  updateRequest.id_magaz = idMagazzinoPiuVicino;
                  updateRequest.id_pez = ordine.prodotti[i].pezzi[j];
                  update@Database( updateRequest )( ret )
              }
            }
          }
        }
      }
      disconnettiDB
    }
  }] {daStampare = "Eseguita verificaDisponibilitaPezzi"; log}

	[eseguoOrdine ( Ordine )( ConfermeSpedizioni ) {
		scope( eseguoOrdine ) {
			
		}
	}] {daStampare = "Eseguita eseguoOrdine"; log}

}