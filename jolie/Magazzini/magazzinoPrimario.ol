include "interfacciaMagazzinoPrimario.iol"
include "string_utils.iol"
include "console.iol"
include "math.iol"
include "time.iol"
include "ini_utils.iol"
include "database.iol"
include "../ServizioDistanza/DistanceInterface.iol"
include "../Fornitore/interfacciaFornitore.iol"
include "../Corriere/interfacciaCorriere.iol"
include "interfacciaMagazzinoSecondario.iol"

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

outputPort MagazzinoSecondario1 {
  Location: "socket://localhost:8001"
  Protocol: soap
  Interfaces: InterfacciaMagazzinoSecondario
}

outputPort MagazzinoSecondario2 {
  Location: "socket://localhost:8002"
  Protocol: soap
  Interfaces: InterfacciaMagazzinoSecondario
}

outputPort Corriere{
  Location: "socket://localhost:8400"
  Protocol: http
  Interfaces: InterfacciaCorriere
}


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
			.database = database;
			.driver = driver
		};

		connect@Database( connectionInfo )( void )
	}
}

define disconnettiDB {
  scope(scopeDisconnettiDB) {
    close@Database()()
  }
}

define inizializzaInfoMagazzini {
  scope(scopeInizializzaInfoMagazzini) {  

    connettiDB;

    scope(selection) {
      queryRequest = 
        "SELECT id, provincia, citta FROM magazzino ";
      query@Database( queryRequest )( queryResponse );
      // Il magazzino principale ha id 0
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
              daStampare = "Non era riservato in nessun magazzino"; log;
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
          if( idMagazzinoPiuVicino == null ) {
            daStampare = "Non era riservato in nessun magazzino"; log;
            idPezziMancanti.pezzi[indiceArray] = ordine.prodotti[i].pezzi[j];
            ++indiceArray
          } else {
            daStampare = "Era riservato nel magazzino: " + idMagazzinoPiuVicino; log;
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

	[eseguoOrdine ( ordine )( confermaSpedizioni ) {
		scope( eseguoOrdine ) {
			daStampare = "Inizio ad eseguire l'ordine"; log;
      for (i = 0, i < #ordine.prodotti, ++i){
        necessarioMontaggio = false;
        if (#ordine.prodotti[i].pezzi > 1){
          necessarioMontaggio = true
        };
        for (j = 0, j < #ordine.prodotti[i].pezzi, ++j){
          daStampare = "Pezzo da eseguire ordine " + ordine.prodotti[i].pezzi[j]; log;

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
          if( idMagazzinoPiuVicino == null ) {
            daStampare = "Non era riservato in nessun magazzino"; log;
            if(necessarioMontaggio == true){
              ordineSpedizione.cliente.nome = "Officina";
              ordineSpedizione.cliente.cognome = "ACME";
              ordineSpedizione.cliente.indirizzo.provincia = officina.provincia;
              ordineSpedizione.cliente.indirizzo.citta = officina.citta;
              ordineSpedizione.prodotti[0].pezzi[0] = ordine.prodotti[i].pezzi[j];
              richiestaSpedizione@Fornitore(ordineSpedizione)(esito);
              if(esito.valore==true){
                daStampare = "Spedizione all'officina confermata"; log;
                connettiDB;
                undef( updateRequest );
                updateRequest = "INSERT INTO pezzo_magazzino(id_pezzo, id_magazzino, quantita, riservati) VALUES" +
                "(:id_pez, :id_magaz, :quantita, :riservati)";
                updateRequest.id_magaz = 0;
                updateRequest.id_pez = ordine.prodotti[i].pezzi[j] + 0;
                updateRequest.quantita = 5;
                updateRequest.riservati = 0;
                update@Database( updateRequest )( ret );
                daStampare = "Inseriti i 5 elementi spediti dal fornitore nel database"; log;
                disconnettiDB
              }
            } else {
              ordineSpedizione.cliente << ordine.cliente;
              ordineSpedizione.prodotti[0].pezzi[0] = ordine.prodotti[i].pezzi[j];
              richiestaSpedizione@Fornitore(ordineSpedizione)(esito);
              if(esito.valore==true){
                daStampare = "Spedizione al cliente confermata"; log
              }
            }
          } else {
            daStampare = "Era riservato nel magazzino: " + idMagazzinoPiuVicino; log;
            connettiDB;
            undef( updateRequest );
            if (quantitaMagazzinoPiuVicino>1){
              updateRequest = "UPDATE pezzo_magazzino SET riservati = :riservati, quantita = :quantita WHERE id_pezzo = :id_pez AND id_magazzino = :id_magaz";
              updateRequest.quantita = (quantitaMagazzinoPiuVicino - 1);
              updateRequest.riservati = (numeroRiservatiMagazzinoPiuVicino - 1);
              updateRequest.id_magaz = idMagazzinoPiuVicino + 0;
              updateRequest.id_pez = ordine.prodotti[i].pezzi[j] + 0;
              update@Database( updateRequest )( ret );
              daStampare = "Ridotta la quantita del pezzo di un'unita"; log
            } else {
              updateRequest = "DELETE FROM pezzo_magazzino WHERE id_pezzo = :id_pez AND id_magazzino = :id_magaz";              
              updateRequest.id_magaz = idMagazzinoPiuVicino + 0;
              updateRequest.id_pez = ordine.prodotti[i].pezzi[j] + 0;
              update@Database( updateRequest )( ret );
              daStampare = "Cancellato elemento dal db"; log
            };
            disconnettiDB;
            daStampare = "necessarioMontaggio " + necessarioMontaggio; log;
            if( necessarioMontaggio == true ) {
              prodottoIDMagazzinoDestinatario.pezzo = ordine.prodotti[i].pezzi[j];
              prodottoIDMagazzinoDestinatario.idMagazzino = idMagazzinoPiuVicino;
              prodottoIDMagazzinoDestinatario.destinatario.nome = "Officina";
              prodottoIDMagazzinoDestinatario.destinatario.cognome = "ACME";
              prodottoIDMagazzinoDestinatario.destinatario.indirizzo.provincia = officina.provincia;
              prodottoIDMagazzinoDestinatario.destinatario.indirizzo.citta = officina.citta;
              daStampare = "Prima di spedisci dai magazzini"; log;
              spedisciDaMagazzini@MagazzinoPrimario (prodottoIDMagazzinoDestinatario)(esito)
            } else {
              prodottoIDMagazzinoDestinatario.pezzo = ordine.prodotti[i].pezzi[j];
              prodottoIDMagazzinoDestinatario.idMagazzino = idMagazzinoPiuVicino;
              prodottoIDMagazzinoDestinatario.destinatario << ordine.cliente;
              daStampare = "Prima di spedisci dai magazzini"; log;
              spedisciDaMagazzini@MagazzinoPrimario (prodottoIDMagazzinoDestinatario)(esito)
            }
          }
        }
      };
      confermaSpedizioni.valore = true
		}
	}] {daStampare = "Eseguita eseguoOrdine"; log}

  [ spedisciDaMagazzini (prodottoIDMagazzinoDestinatario)(esitoTotale){
    scope( spedisciDaMagazzini ) {
      daStampare = "Dentro a spedisciDaMagazzini"; log;
      if(prodottoIDMagazzinoDestinatario.idMagazzino == 0){
        ordineSpedizione.cliente << prodottoIDMagazzinoDestinatario.destinatario;
        ordineSpedizione.prodotti[0].pezzi[0] = prodottoIDMagazzinoDestinatario.pezzo;
        richiestaSpedizione@MagazzinoPrimario(ordineSpedizione)(esito);
        if(esito.valore==true){
          daStampare = "Spedizione dal magazzino " + prodottoIDMagazzinoDestinatario.idMagazzino + " confermata"; log
        };
        esitoTotale << esito
      } else if (prodottoIDMagazzinoDestinatario.idMagazzino == 1){
        ordineSpedizione.cliente << prodottoIDMagazzinoDestinatario.destinatario;
        ordineSpedizione.prodotti[0].pezzi[0] = prodottoIDMagazzinoDestinatario.pezzo;
        richiestaSpedizione@MagazzinoSecondario1(ordineSpedizione)(esito);
        if(esito.valore==true){
          daStampare = "Spedizione dal magazzino " + prodottoIDMagazzinoDestinatario.idMagazzino + " confermata"; log
        };
        esitoTotale << esito
      } else if (prodottoIDMagazzinoDestinatario.idMagazzino == 2){
        ordineSpedizione.cliente << prodottoIDMagazzinoDestinatario.destinatario;
        ordineSpedizione.prodotti[0].pezzi[0] = prodottoIDMagazzinoDestinatario.pezzo;
        richiestaSpedizione@MagazzinoSecondario2(ordineSpedizione)(esito);
        if(esito.valore==true){
          daStampare = "Spedizione dal magazzino " + prodottoIDMagazzinoDestinatario.idMagazzino + " confermata"; log
        };
        esitoTotale << esito
      } else {
        esitoTotale.valore = false
      }
    }
  }] {daStampare = "Eseguita spedisciDaMagazzini"; log}

  [richiestaSpedizione( ordine ) ( esitoSpedizione ) {
    scope( richiestaSpedizione ) {
      richiestaSpedizione@Corriere(ordine)(esitoRichiesta);
      esitoSpedizione << esitoRichiesta;
      if ( esitoSpedizione.valore == true ) {
        daStampare = "Il corriere ha confermato la spedizione."; log
      } else {
        daStampare = "Problema nella spedizione!"; log
      }
    }
  }] {daStampare = "Eseguita richiestaSpedizione"; log}
}