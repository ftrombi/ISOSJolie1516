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

	magazzinoPrimario << magazzini[0];
  officina << magazzini[0]
}

main {

	[verificaDisponibilitaERiservaPezzi ( ordine )( risultato ){
		scope( verificaDisponibilitaERiservaPezzi ){
      verificaDisponibilitaPezziNelDBERiservaDisponibili@MagazzinoPrimario(ordine)(idPezziMancanti);
      risultato.valore = true;
      for (i = 0, i < #idPezziMancanti.pezzi, i++) {
        pezzoMancante.valore = idPezziMancanti.pezzi[i];
        richiestaRiservaPezzi@Fornitore(pezzoMancante)(confermaRiservaAvvenuta);     
        if (confermaRiservaAvvenuta.valore == false){
          risultato.valore = false
        };
        daStampare = "Pezzo " + pezzoMancante.valore + " ordinato al fornitore"; log
      }
		}
	}] {daStampare = "Eseguita verificaDisponibilitaERiservaPezzi"; log}

  [verificaDisponibilitaPezziNelDBERiservaDisponibili (ordine)(idPezziMancanti) {
    scope(verificaDisponibilitaPezziNelDBERiservaDisponibili) {
      indiceArray = 0;
      for (i = 0, i < #ordine.prodotti, ++i){
        necessarioMontaggio = false;
        if (#ordine.prodotti[i].pezzi > 1){
          necessarioMontaggio = true
        };
        for (j = 0, j < #ordine.prodotti[i].pezzi, ++j){
          scope(selection) {
            daStampare = "Pezzo richiesto " + ordine.prodotti[i].pezzi[j]; log;
            
            connettiDB;
            queryRequest = 
              "SELECT id_pezzo, id_magazzino, quantita, riservati FROM pezzo_magazzino " + 
              "WHERE id_pezzo = :id_pez AND quantita > riservati";
            queryRequest.id_pez = ordine.prodotti[i].pezzi[j];
            query@Database( queryRequest )( queryResponse );
            disconnettiDB;

            idMagazzinoPiuVicino = null;
            distanzaMagazzinoPiuVicino = null;
            numeroRiservatiMagazzinoPiuVicino = null; 
            quantitaMagazzinoPiuVicino = null;
            
            for(k = 0, k < #queryResponse.row, ++k) {
              daStampare = "Trovati " + queryResponse.row[k].QUANTITA + " nel magazzino: " + queryResponse.row[k].ID_MAGAZZINO + ", di cui riservati " + queryResponse.row[i].RISERVATI; log;
              richiestaDistanza.origin.citta = magazzini[queryResponse.row[k].ID_MAGAZZINO].citta;
              richiestaDistanza.origin.provincia = magazzini[queryResponse.row[k].ID_MAGAZZINO].provincia;
              if (necessarioMontaggio == true) {
                richiestaDistanza.destination.citta = officina.citta;
                richiestaDistanza.destination.provincia = officina.provincia
              } else {
                richiestaDistanza.destination.citta = ordine.cliente.indirizzo.citta;
                richiestaDistanza.destination.provincia = ordine.cliente.indirizzo.provincia
              };
              getBestDistance@CalcoloDistanze( richiestaDistanza ) ( rispostaDistanza );
              if (rispostaDistanza.status == "OK") {
                daStampare = "Distante: " + rispostaDistanza.distance; log;
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
            daStampare = "Magazzino più vicino: " + idMagazzinoPiuVicino; log;
            daStampare = "Distanza più vicino: " + distanzaMagazzinoPiuVicino; log;
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

              daStampare = "Elemento riservato sul db "; log;
              disconnettiDB
            }
          }
        }
      }
    }
  }] {daStampare = "Eseguita verificaDisponibilitaPezzi"; log}

  [annulloOrdine (ordine)(risultato){
    scope (annulloOrdine){
      daStampare = "Inizio ad annullare l'ordine"; log;
      indiceArray = 0;
      for (i = 0, i < #ordine.prodotti, ++i){
        necessarioMontaggio = false;
        if (#ordine.prodotti[i].pezzi > 1){
          necessarioMontaggio = true
        };
        for (j = 0, j < #ordine.prodotti[i].pezzi, ++j){
          daStampare = "Pezzo da annullare " + ordine.prodotti[i].pezzi[j]; log;

          connettiDB;
          queryRequest = 
            "SELECT id_pezzo, id_magazzino, quantita, riservati FROM pezzo_magazzino " + 
            "WHERE id_pezzo = :id_pez AND riservati > 0";
          queryRequest.id_pez = ordine.prodotti[i].pezzi[j];
          query@Database( queryRequest )( queryResponse );
          disconnettiDB;

          idMagazzinoPiuVicino = null;
          distanzaMagazzinoPiuVicino = null;
          numeroRiservatiMagazzinoPiuVicino = null; 
          quantitaMagazzinoPiuVicino = null;
          
          for(k = 0, k < #queryResponse.row, ++k) {
            daStampare = "Trovati " + queryResponse.row[k].QUANTITA + " nel magazzino: " + queryResponse.row[k].ID_MAGAZZINO + ", di cui riservati " + queryResponse.row[i].RISERVATI; log;
            richiestaDistanza.origin.citta = magazzini[queryResponse.row[k].ID_MAGAZZINO].citta;
            richiestaDistanza.origin.provincia = magazzini[queryResponse.row[k].ID_MAGAZZINO].provincia;
            if (necessarioMontaggio == true) {
              richiestaDistanza.destination.citta = officina.citta;
              richiestaDistanza.destination.provincia = officina.provincia
            } else {
              richiestaDistanza.destination.citta = ordine.cliente.indirizzo.citta;
              richiestaDistanza.destination.provincia = ordine.cliente.indirizzo.provincia
            };
            getBestDistance@CalcoloDistanze( richiestaDistanza ) ( rispostaDistanza );
            if (rispostaDistanza.status == "OK") {
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
          daStampare = "Era riservato nel magazzino: " + idMagazzinoPiuVicino; log;
          if( idMagazzinoPiuVicino == null ) {
            idPezziMancanti.pezzi[indiceArray] = ordine.prodotti[i].pezzi[j];
            ++indiceArray
          } else {
            connettiDB;
            undef( updateRequest );
            updateRequest = "UPDATE pezzo_magazzino SET riservati = :riservati WHERE id_pezzo = :id_pez AND id_magazzino = :id_magaz";
            updateRequest.riservati = (numeroRiservatiMagazzinoPiuVicino - 1);
            updateRequest.id_magaz = idMagazzinoPiuVicino + 0;
            updateRequest.id_pez = ordine.prodotti[i].pezzi[j] + 0;
            update@Database( updateRequest )( ret );

            daStampare = "Cancellata la riserva del pezzo "; log;
            disconnettiDB
          }
        }
      };
      risultato.valore = true;
      for (i = 0, i < #idPezziMancanti.pezzi, i++) {
        pezzoMancante.valore = idPezziMancanti.pezzi[i];
        annullaRiservaPezzi@Fornitore(pezzoMancante)(confermaRiservaAvvenuta);     
        if (confermaRiservaAvvenuta.valore == false){
          risultato.valore = false
        };
        daStampare = "Annullato dal fornitore il pezzo " + pezzoMancante.valore; log
      }
    }
  }] {daStampare = "Eseguita annulloOrdine"; log}

/*
	[eseguoOrdine ( Ordine )( ConfermeSpedizioni ) {
		scope( eseguoOrdine ) {
			
		}
	}] {daStampare = "Eseguita eseguoOrdine"; log}
*/
}