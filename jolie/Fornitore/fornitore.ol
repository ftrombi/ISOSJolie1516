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

main
{
	[richiestaRiservaPezzi( prodotto ) ( risultatoRiserva ) {
    println@Console( "Richiesta riserva pezzi accolta." )();
    scope( richiestaRiservaPezzi ) {
        risultatoRiserva.valore = true
    }
  }] {daStampare = "Eseguita richiestaRiservaPezzi"; log}

  [annullaRiservaPezzi( prodotto ) ( esitoAnnullamento ) {
    println@Console( "Riserva pezzi annullata correttamente." )();
    scope( annullaRiservaPezzi ) {
      esitoAnnullamento.valore = true
    }
  }] {daStampare = "Eseguita annullaRiservaPezzi"; log}

  [richiestaSpedizione( ordine ) ( esitoSpedizione ) {
    println@Console(
      "Richiesta di spedizione a " + ordine.cliente.nome +
      " " + ordine.cliente.cognome +
      " accettata. Confermata spedizione verso " + ordine.cliente.indirizzo.citta +
      " (" + ordine.cliente.indirizzo.provincia + ")."
    )();
    scope( richiestaSpedizione ) {
      esitoSpedizione.valore = true
    }
  }] {daStampare = "Eseguita richiestaSpedizione"; log}
}