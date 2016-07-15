include "console.iol"
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
      for (i = 0, i < #prodotto.pezzi, ++i) {
        risultatoRiserva[i] = true
      }
    }
  }] {daStampare = "Eseguita richiestaRiservaPezzi"; log}

  [annullaRiservaPezzi( prodotto ) ( esitoAnnullamento ) {
    scope( annullaRiservaPezzi ) {
      for (i = 0, i < #prodotto.pezzi, ++i) {
        esitoAnnullamento[i] = true
      }
    }
  }] {daStampare = "Eseguita annullaRiservaPezzi"; log}
}