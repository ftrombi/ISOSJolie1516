include "console.iol"
include "time.iol"
include "string_utils.iol"
include "interfacciaMagazzinoSecondario.iol"
include "../Corriere/interfacciaCorriere.iol"

inputPort input{
  Location: "socket://localhost:8002"
  Protocol: soap 
  Interfaces: InterfacciaMagazzinoSecondario
}

outputPort Corriere {
  Location: "socket://localhost:8400"
  Protocol: http
  Interfaces: InterfacciaCorriere
}

execution{ concurrent }

define log {
  getCurrentDateTime@Time(null)(ts); 
  println@Console(ts + " - " + daStampare)()
}

main
{
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

/*println@Console(
      "Richiesta di spedizione a " + ordine.cliente.nome +
      " " + ordine.cliente.cognome +
      " accettata. Confermata spedizione verso " + ordine.cliente.indirizzo.citta +
      " (" + ordine.cliente.indirizzo.provincia + ")."
    )();*/