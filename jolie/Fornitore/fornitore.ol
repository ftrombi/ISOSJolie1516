include "console.iol"
include "time.iol"
include "string_utils.iol"
include "interfacciaFornitore.iol"

inputPort input{
	Location: "socket://localhost:8300"
	Protocol: http 
	Interfaces: InterfacciaFornitore
}

execution{ concurrent }

define log {
  getCurrentDateTime@Time(null)(ts); 
  println@Console(ts + " - " + daStampare)()
}

init {
  daStampare = "Inizio procedura Fornitore"; log
}

main
{
	[richiestaRiservaPezzi( prodotto ) ( risultatoRiserva ) {
    daStampare = "Richiesta riserva pezzi accolta."; log;
    scope( richiestaRiservaPezzi ) {
        risultatoRiserva.valore = true
    }
  }] {daStampare = "Eseguita richiestaRiservaPezzi"; log}

  [annullaRiservaPezzi( prodotto ) ( esitoAnnullamento ) {
    daStampare = "Riserva pezzi annullata correttamente."; log;
    scope( annullaRiservaPezzi ) {
      esitoAnnullamento.valore = true
    }
  }] {daStampare = "Eseguita annullaRiservaPezzi"; log}

  [richiestaSpedizione( ordine ) ( esitoSpedizione ) {
    daStampare = "Richiesta di spedizione a " + ordine.cliente.nome +
      " " + ordine.cliente.cognome +
      " accettata. Confermata spedizione verso " + ordine.cliente.indirizzo.citta +
      " (" + ordine.cliente.indirizzo.provincia + ")."; log;
    scope( richiestaSpedizione ) {
      esitoSpedizione.valore = true
    }
  }] {daStampare = "Eseguita richiestaSpedizione"; log}
}