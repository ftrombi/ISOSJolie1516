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
    scope( richiestaRiservaPezzi ) {
        risultatoRiserva.valore = true
    }
  }] {daStampare = "Eseguita richiestaRiservaPezzi"; log}

  [annullaRiservaPezzi( prodotto ) ( esitoAnnullamento ) {
    scope( annullaRiservaPezzi ) {
      esitoAnnullamento.valore = true
    }
  }] {daStampare = "Eseguita annullaRiservaPezzi"; log}
}