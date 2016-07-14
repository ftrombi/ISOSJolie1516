include "interfacciaMagazzinoPrimario.iol"
include "string_utils.iol"
include "console.iol"
include "math.iol"
include "time.iol"

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

execution{ concurrent }

init {
	daStampare = "Inizio procedura Magazzino Primario"; log;
	idMagazzinoPrimario = 0;
	
	// il magazzino primario conosce gli id di tutti gli altri magazzini secondari
	idMagazzinoSecondario1 = 1;

	magazzinoPrimario.id = idMagazzinoPrimario;
	magazzinoPrimario.indirizzo.nazione = "italia";
	magazzinoPrimario.indirizzo.provincia = "pr";
	magazzinoPrimario.indirizzo.citta = "compiano";
	magazzinoPrimario.indirizzo.via = "via marco rossi sidoli";
	magazzinoPrimario.indirizzo.cap = "43053";
	// Componenti presenti nel magazzino primario
	listino[0] = 123;
	listino[1] = 345;
	listino[2] = 567;
	listino[3] = 890;
	listino[4] = 234
}

main {

	[ricercaComponentiMagazzini ( ordine )( risultatoRicerca ) {
		scope( scopeRicercaComponentiMagazzini ) {
			for (i = 0, i < #ordine.listaComponenti, ++i) {
				componenteDaCercare.componente = ordine.listaComponenti[i];
				componenteDaCercare.indirizzo = ordine.indirizzoCliente;
				ricercaComponenteMagazzinoPrimario@MagazzinoPrimario( componenteDaCercare )( infoComponente );
				infoComponenteIndirizzo.infoComponente = infoComponente;
				infoComponenteIndirizzo.indirizzo = ordine.indirizzoCliente;
				ricercaComponenteMagazzino@MagazzinoSecondario1( infoComponenteIndirizzo )( infoComponente );
				risultatoRicerca.listaInfoComponenti[i] = infoComponente
			}
		}
	}] {daStampare = "Eseguita ricercaComponentiMagazzini"; log}

	[ricercaComponenteMagazzinoPrimario( componenteDaCercare )( infoComponente ) {
		scope( scopeRicercaComponenteMagazzinoPrimario ) {
			infoComponente.componente.id = componenteDaCercare.componente.id;
			infoComponente.distanzaDalCliente = null;
			infoComponente.magazzino.id = -1;
			infoComponente.daOrdinare = true;
			i = 0;
			while ( i < #listino && infoComponente.daOrdinare == true ){
				if (componenteDaCercare.componente.idComponente == listino[i]) {
					richiestaDistanza.origin.citta = magazzinoPrimario.indirizzo.citta;
					richiestaDistanza.origin.provincia = magazzinoPrimario.indirizzo.provincia;
					richiestaDistanza.destination.citta = componenteDaCercare.indirizzo.citta;
					richiestaDistanza.destination.provincia = componenteDaCercare.indirizzo.provincia;
					getBestDistance@CalcoloDistanze( richiestaDistanza ) ( rispostaDistanza );
					if (rispostaDistanza.status == "OK") {
						distanzaAttuale = rispostaDistanza.distance
					}
					else {
						distanzaAttuale = null;
						daStampare = rispostaDistanza.message; log
					};
					if (infoComponente.distanzaDalCliente == null || distanzaAttuale < infoComponente.distanzaDalCliente) {
						infoComponente.distanzaDalCliente = distanzaAttuale;
						infoComponente.magazzino.id = idMagazzinoPrimario;
						riservaComponente@MagazzinoPrimario( infoComponente )( statoRiserva );
						infoComponente.daOrdinare = false
					}
				};
				i++
			}
		}
	}] {daStampare = "Eseguita ricercaComponenteMagazzinoPrimario"}

	[rilasciaComponente ( infoComponenteDaRilasciare )( risposta ) {
		scope ( scopeRilasciaComponenti ) {
			if (infoComponenteDaRilasciare.magazzino.id == idMagazzinoPrimario) {
				daStampare = "Componente " + infoComponenteDaRilasciare.componente.id + " rilasciato dal MAGAZZINO PRIMARIO"; log
			}
			else if (infoComponenteDaRilasciare.magazzino.id == idMagazzinoSecondario1) {
				rilasciaComponente@MagazzinoSecondario1 ( infoComponenteDaRilasciare ) ( risposta1 );
				daStampare = risposta1; log
			};
			// un else if per ogni magazzino secondario
			risposta = daStampare
		}
	}] {daStampare = "Eseguita rilasciaComponenti"; log}

	[riservaComponente ( infoComponenteDaRiservare )( risposta ) {
		scope ( scopeRiservaComponenti ) {
			if (infoComponenteDaRiservare.magazzino.id == idMagazzinoPrimario) {
				daStampare = "Componente " + infoComponenteDaRiservare.componente.id + " riservato nel MAGAZZINO PRIMARIO"; log
			}
			else if (infoComponenteDaRiservare.magazzino.id == idMagazzinoSecondario1) {
				riservaComponente@MagazzinoSecondario1 ( infoComponenteDaRiservare ) ( risposta1 );
				daStampare = risposta1; log
			};
			// un else if per ogni magazzino secondario
			risposta = daStampare
		}
	}] {daStampare = "Eseguita riservaComponenti"; log}

	[assolvoOrdineCiclo ( ordineCiclo )( risposta ) {
		scope ( scopeAssolvoOrdineCiclo ) {
			// Dopo questo for ho tutti i componenti nel magazzino primario
			for (i = 0, i < #ordineCiclo.listaComponenti, ++i) {
				componenteDaCercare.componente = ordineCiclo.listaComponenti[i];
				componenteDaCercare.indirizzo = ordineCiclo.cliente.indirizzo;
				ricercaComponenteMagazzinoPrimario@MagazzinoPrimario( componenteDaCercare )( infoComponenteRisultato );
				if (infoComponente.daOrdinare == true){
					infoComponenteIndirizzo.infoComponente = infoComponenteRisultato;
					infoComponenteIndirizzo.indirizzo = ordineCiclo.cliente.indirizzo;
					ricercaComponenteMagazzino@MagazzinoSecondario1( infoComponenteIndirizzo )( infoComponenteRisultato );
					if( infoComponente.daOrdinare == false ) {
						spedisciAlMagazzinoPrimario@MagazzinoSecondario1( infoComponenteRisultato.componente )( rispostaSpedizione );
					} else {
						richiestaOrdineFornitore.idElement = infoComponenteRisultato.componente.id;
						requestOrder@SupplierServer( richiestaOrdineFornitore )( rispostaOrdineFornitore );
						daStampare = rispostaOrdineFornitore.message; log;
					};
				} 
			}
			assembloESpedisco@MagazzinoPrimario( ordineCiclo )( risultatoSpedizione );
			risposta = risultatoSpedizione
		}
	}] {daStampare = "Eseguita assolvoOrdineCiclo"; log}

	[assembloESpedisco ( ordineCiclo )( risposta ) {
		scope ( scopeAssembloESpedisco ) {
			daStampare = "Assemblato ciclo con le customizzazioni.";
			log;
			random@Math()(idCasualeCicloAssemblato);
			idCasualeCicloAssemblato = idCasualeCicloAssemblato * 100;
			richiestaSpediz.idMagazzinoPartenza = idMagazzinoPrimario;
			richiestaSpediz.idPacco = idCasualeCicloAssemblato;
			richiestaSpediz.nome = ordineCiclo.cliente.nome;
			richiestaSpediz.cognome = ordineCiclo.cliente.nome;
			richiestaSpediz.nazione = ordineCiclo.cliente.indirizzo.nazione;
			richiestaSpediz.provincia = ordineCiclo.cliente.indirizzo.provincia;
			richiestaSpediz.citta = ordineCiclo.cliente.indirizzo.citta;
			richiestaSpediz.via = ordineCiclo.cliente.indirizzo.via;
			richiestaSpediz.cap = ordineCiclo.cliente.indirizzo.cap;
			richiestaSpediz.telefono = ordineCiclo.cliente.telefono;
			richiestaSpedizione@CorriereServer( richiestaSpediz )( response );
			daStampare = response.statoConsegna; log;
			risposta = true
		}
	}] {daStampare = "Eseguita assembloESpedisco"; log}

	[assolvoOrdineComponenti ( ordineComponenti )( risposta ) {
		scope ( scopeAssolvoOrdineComponenti ) {
			for (i = 0, i < #ordineComponenti.listaInfoComponenti, ++i) {
				if( ordineComponenti.listaInfoComponenti[i].daOrdinare == false ) {
					richiestaSpediz.idMagazzinoPartenza = ordineComponenti.listaInfoComponenti[i].magazzino.id;
					richiestaSpediz.idPacco = ordineComponenti.listaInfoComponenti[i].componente.id;
					richiestaSpediz.nome = ordineComponenti.cliente.nome;
					richiestaSpediz.cognome = ordineComponenti.cliente.nome;
					richiestaSpediz.nazione = ordineComponenti.cliente.indirizzo.nazione;
					richiestaSpediz.provincia = ordineComponenti.cliente.indirizzo.provincia;
					richiestaSpediz.citta = ordineComponenti.cliente.indirizzo.citta;
					richiestaSpediz.via = ordineComponenti.cliente.indirizzo.via;
					richiestaSpediz.cap = ordineComponenti.cliente.indirizzo.cap;
					richiestaSpediz.telefono = ordineComponenti.cliente.telefono;
					richiestaSpedizione@CorriereServer( richiestaSpediz )( response );
					daStampare = response.statoConsegna; log
				} else {
					richiestaOrdineFornitore.idElements = ordineComponenti.listaInfoComponenti[i].componente.id;
					requestOrder@SupplierServer(richiestaOrdineFornitore)(rispostaOrdineFornitore);
					daStampare = rispostaOrdineFornitore.message; log;
					richiestaSpediz.idMagazzinoPartenza = idMagazzinoPrimario;
					richiestaSpediz.idPacco = ordineComponenti.listaInfoComponenti[i].id;
					richiestaSpediz.nome = ordineComponenti.cliente.nome;
					richiestaSpediz.cognome = ordineComponenti.cliente.nome;
					richiestaSpediz.nazione = ordineComponenti.cliente.indirizzo.nazione;
					richiestaSpediz.provincia = ordineComponenti.cliente.indirizzo.provincia;
					richiestaSpediz.citta = ordineComponenti.cliente.indirizzo.citta;
					richiestaSpediz.via = ordineComponenti.cliente.indirizzo.via;
					richiestaSpediz.cap = ordineComponenti.cliente.indirizzo.cap;
					richiestaSpediz.telefono = ordineComponenti.cliente.telefono;
					richiestaSpedizione@CorriereServer( richiestaSpediz )( response );
					daStampare = response.statoConsegna; log
				}
			};
			risposta = true
		}
	}] {daStampare = "Eseguita assolvoOrdineComponenti"; log}
}