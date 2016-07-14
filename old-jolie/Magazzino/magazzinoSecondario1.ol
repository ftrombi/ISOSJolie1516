include "interfMagazzinoSecondario.iol"
include "string_utils.iol"
include "console.iol"
include "time.iol"
include "../ServizioDistanza/DistanceInterface.iol"

inputPort InputOrdine {
	Location: "socket://localhost:8001"
	Protocol: soap
	Interfaces: InterfMagazzinoSecondario
}

outputPort CalcoloDistanze {
	Location: "socket://localhost:8100"
	Protocol: http
	Interfaces: DistanceInterface
}

outputPort MagazzinoPrimario {
	Location: "socket://localhost:8000"
	Protocol: soap
	Interfaces: InterfMagazzinoPrimario
}

define log {
	getCurrentDateTime@Time(null)(ts); 
	println@Console(ts + " - " + daStampare)()
}

init {
	daStampare = "Inizio procedura Magazzino Secondario 1"; log;
	idMagazzinoSecondario = 1;
	magazzinoSecondario.id = idMagazzinoSecondario;
	magazzinoSecondario.indirizzo.nazione = "italia";
	magazzinoSecondario.indirizzo.provincia = "na";
	magazzinoSecondario.indirizzo.citta = "napoli";
	magazzinoSecondario.indirizzo.via = "via umberto pierantoni";
	magazzinoSecondario.indirizzo.cap = "80126";
	// Componenti presenti nel magazzino secondario 1
	listino[0] = 234;
	listino[1] = 456;
	listino[2] = 678;
	listino[3] = 890;
	listino[4] = 123
}

main {
	[ricercaComponenteMagazzino( infoComponenteIndirizzo )( infoRisultato ) {
		scope( scopeRicercaComponenteMagazzino ) {
			i = 0;
			while ( i < #listino ){
				if (infoComponenteIndirizzo.infoComponente.componente.id == listino[i]) {
					richiestaDistanza.origin.citta = magazzinoSecondario.indirizzo.citta;
					richiestaDistanza.origin.provincia = magazzinoSecondario.indirizzo.provincia;
					richiestaDistanza.destination.citta = infoComponenteIndirizzo.indirizzo.citta;
					richiestaDistanza.destination.provincia = infoComponenteIndirizzo.indirizzo.provincia;
					getBestDistance@CalcoloDistanze( richiestaDistanza ) ( rispostaDistanza );
					if (rispostaDistanza.status == "OK") {
						distanzaAttuale = rispostaDistanza.distance
					}
					else {
						distanzaAttuale = null;
						daStampare = rispostaDistanza.message; log
					};
					if (infoComponenteIndirizzo.infoComponente.distanzaDalCliente == null || distanzaAttuale < infoComponenteIndirizzo.infoComponente.distanzaDalCliente) {
						rilasciaComponente@MagazzinoPrimario( infoComponenteIndirizzo.infoComponente )(esitoRilascio);
						infoRisultato.componente.id = info.componente.id;
						infoRisultato.distanzaDalCliente = distanzaAttuale;
						infoRisultato.magazzino.id = idMagazzinoSecondario;
						infoRisultato.daOrdinare = false;
						riservaComponente@MagazzinoPrimario( infoRisultato )(esitoRiserva)
					}
				};
				i++
			}
		}
	}] {daStampare = "Eseguita ricercaComponentiMagazzini"; log}

	[rilasciaComponente ( componeneteDaRilasciare ) ( risposta ) {
		scope( scopeRilasciaComponente ) {
			risposta = "Componente " + componenteDaRilasciare.componente.id + " rilasciato dal MAGAZZINO SECONDARIO 1"
		}
	}] {daStampare = "Eseguita rilasciaComponente"; log}

	[riservaComponente ( componeneteDaRiservare ) ( risposta ) {
		scope( scopeRiservaComponente ) {
			risposta = "Componente " + componeneteDaRiservare.componente.id + " riservato nel MAGAZZINO SECONDARIO 1"
		}
	}] {daStampare = "Eseguita riservaComponente"; log}

	[spedisciAlMagazzinoPrimario ( componenteDaSpedire ) ( risposta ) {
		scope( scopeSpedisciAlMagazzinoPrimario ) {
			risposta = true;
		}
	}] {daStampare = "Eseguita spedisciAlMagazzinoPrimario"; log}
}