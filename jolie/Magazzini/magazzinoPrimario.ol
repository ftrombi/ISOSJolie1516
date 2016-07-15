include "interfacciaMagazzinoPrimario.iol"
include "string_utils.iol"
include "console.iol"
include "math.iol"
include "time.iol"
include "ini_utils.iol"
include "database.iol"
include "../ServizioDistanza/DistanceInterface.iol"
include "../Fornitore/interfacciaFornitore.iol"

/*

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

outputPort CalcoloDistanze {
  Location: "socket://localhost:8100"
  Protocol: http
  Interfaces: DistanceInterface
}

outputPort Fornitore {
  Location: "socket://localhost:8300"
  Protocol: http
  Interfaces: InterfacciaFornitore
}
/*
outputPort MagazzinoSecondario1 {
	Location: "socket://localhost:8001"
	Protocol: soap
	Interfaces: InterfMagazzinoSecondario
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
        magazzini[i].citta = queryResponse.row[i].CITTA
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

	magazzinoPrimario << magazzini[0]
}

main {

	[verificaDisponibilitaERiservaPezzi ( ordine )( risultato ){
		scope( verificaDisponibilitaERiservaPezzi ){
      verificaDisponibilitaPezziNelDBERiservaDisponibili@MagazzinoPrimario(ordine)(idPezziMancanti);
      risultato.valore = true;
      daStampare = "#idPezziMancanti.pezzi " + #idPezziMancanti.pezzi; log;
      for (i = 0, i < #idPezziMancanti.pezzi, i++) {
        pezzoMancante.valore = idPezziMancanti.pezzi[i];
        daStampare = "pezzoMancante " + pezzoMancante.valore; log;
        richiestaRiservaPezzi@Fornitore(pezzoMancante)(confermaRiservaAvvenuta);     
        if (confermaRiservaAvvenuta.valore == false){
          risultato.valore = false
        }
      }
      /*if(#idPezziMancanti.pezzi > 0){
        daStampare = "Tornato da funzione fornitore"; log
        for (i = 0, i < #confermaRiservaAvvenuta.booleano, ++i){
          if (confermaRiservaAvvenuta.booleano[i] == false)
            risultato.valore = confermaRiservaAvvenuta.booleano[i]
        }
      }*/
		}
	}] {daStampare = "Eseguita verificaDisponibilitaERiservaPezzi"; log}

  [verificaDisponibilitaPezziNelDBERiservaDisponibili (ordine)(idPezziMancanti) {
    scope(verificaDisponibilitaPezziNelDBERiservaDisponibili) {
      indiceArray = 0;
      for (i = 0, i < #ordine.prodotti, ++i){
        pezziDiUnCiclo = false;
        if (#ordine.prodotti[i].pezzi > 0){
          pezziDiUnCiclo = true
        };
        daStampare = "Pezzi di un ciclo " + #ordine.prodotti[i].pezzi; log;
        for (j = 0, j < #ordine.prodotti[i].pezzi, ++j){
          scope(selection) {
            daStampare = "Pezzo query request " + ordine.prodotti[i].pezzi[j]; log;
            
            connettiDB;
            queryRequest = 
              "SELECT id_pezzo, id_magazzino, quantita, riservati FROM pezzo_magazzino " + 
              "WHERE id_pezzo = :id_pez AND quantita > riservati";
            queryRequest.id_pez = ordine.prodotti[i].pezzi[j];
            query@Database( queryRequest )( queryResponse );
            daStampare = "Eseguita query request"; log;
            disconnettiDB;

            idMagazzinoPiuVicino = null;
            distanzaMagazzinoPiuVicino = null;
            numeroRiservatiMagazzinoPiuVicino = null; 
            quantitaMagazzinoPiuVicino = null;
            
            for(k = 0, k < #queryResponse.row, ++k) {
              daStampare = "Query Response: " + queryResponse.row[k].ID_MAGAZZINO + " riservati " + queryResponse.row[i].RISERVATI; log;
              richiestaDistanza.origin.citta = magazzini[queryResponse.row[k].ID_MAGAZZINO].citta;
              richiestaDistanza.origin.provincia = magazzini[queryResponse.row[k].ID_MAGAZZINO].provincia;
              richiestaDistanza.destination.citta = ordine.cliente.indirizzo.citta;
              richiestaDistanza.destination.provincia = ordine.cliente.indirizzo.provincia;
              getBestDistance@CalcoloDistanze( richiestaDistanza ) ( rispostaDistanza );
              if (rispostaDistanza.status == "OK") {
                daStampare = "Distanza: " + rispostaDistanza.distance; log;
                if (distanzaMagazzinoPiuVicino == null){
                  idMagazzinoPiuVicino = queryResponse.row[k].ID_MAGAZZINO;
                  distanzaMagazzinoPiuVicino = rispostaDistanza.distance;
                  numeroRiservatiMagazzinoPiuVicino = queryResponse.row[k].RISERVATI;
                  quantitaMagazzinoPiuVicino = queryResponse.row[k].QUANTITA
                } else {
                  if (distanzaMagazzinoPiuVicino > rispostaDistanza.distance){
                    idMagazzinoPiuVicino = queryResponse.row[k].ID_MAGAZZINO;
                    distanzaMagazzinoPiuVicino = rispostaDistanza.distance;
                    numeroRiservatiMagazzinoPiuVicino = queryResponse.row[k].RISERVATI;
                    quantitaMagazzinoPiuVicino = queryResponse.row[k].QUANTITA
                  }
                }
              }
            };
            daStampare = "Distanza più vicino: " + distanzaMagazzinoPiuVicino; log;
            daStampare = "ID più vicino: " + idMagazzinoPiuVicino; log;
            daStampare = "Numero riservati più vicino: " + numeroRiservatiMagazzinoPiuVicino; log;
            if( idMagazzinoPiuVicino == null ) {
              idPezziMancanti.pezzi[indiceArray] = ordine.prodotti[i].pezzi[j];
              ++indiceArray
            } else {
              connettiDB;
              undef( updateRequest );
              updateRequest = "UPDATE pezzo_magazzino SET riservati = :riservati WHERE id_pezzo = :id_pez AND id_magazzino = :id_magaz";
              updateRequest.riservati = (numeroRiservatiMagazzinoPiuVicino + 1);
              updateRequest.id_magaz = idMagazzinoPiuVicino + 0;
              updateRequest.id_pez = ordine.prodotti[i].pezzi[j] + 0;
              update@Database( updateRequest )( ret );

              daStampare = "Uscito UPDATE sul db " + ret; log;
              disconnettiDB
            }
          }
        }
      };
      idPezziMancanti.pezzi[0] = 0
    }
  }] {daStampare = "Eseguita verificaDisponibilitaPezzi"; log}
/*
	[eseguoOrdine ( Ordine )( ConfermeSpedizioni ) {
		scope( eseguoOrdine ) {
			
		}
	}] {daStampare = "Eseguita eseguoOrdine"; log}
*/
}