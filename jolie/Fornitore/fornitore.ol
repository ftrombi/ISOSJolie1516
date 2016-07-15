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
    println@Console( "Richiesta riserva pezzi accolta." )()
    scope( richiestaRiservaPezzi ) {
        risultatoRiserva.valore = true
    }
  }] {daStampare = "Eseguita richiestaRiservaPezzi"; log}

  [annullaRiservaPezzi( prodotto ) ( esitoAnnullamento ) {
    println@Console( "Riserva pezzi annullata correttamente." )()
    scope( annullaRiservaPezzi ) {
      for (i = 0, i < #prodotto.pezzi, ++i) {
        esitoAnnullamento.booleano[i] = true
      }
    }
  }] {daStampare = "Eseguita annullaRiservaPezzi"; log}
}