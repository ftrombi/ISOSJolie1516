include "console.iol"
include "time.iol"
include "interfacciaCorriere.iol"

inputPort input{
	Location: "socket://localhost:8400"
	Protocol: http 
	Interfaces: InterfacciaCorriere
}

define log {
  getCurrentDateTime@Time(null)(ts); 
  println@Console(ts + " - " + daStampare)()
}

execution{ concurrent }

init {
  daStampare = "Inizio procedura Corriere"; log
}

main
{
	[richiestaSpedizione( ordine )( esito ) {
    daStampare = "Spedizione per " + ordine.cliente.nome +
      " " + ordine.cliente.cognome +
      " spedita correttamente presso " + ordine.cliente.indirizzo.citta +
      " (" + ordine.cliente.indirizzo.provincia + ")."; log;
    esito.valore = true
	}]{ daStampare = "Eseguita richiestaSpedizione"; log }
}