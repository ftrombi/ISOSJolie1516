include "console.iol"
include "CorriereInterface.iol"

inputPort input{
	Location: "socket://localhost:8400"
	Protocol: http 
	Interfaces: CorriereInterface
}

execution{ concurrent }

main
{
	[richiestaSpedizione( ordine )( esito ) {
    println@Console(
      "Spedizione per " + ordine.cliente.nome +
      " " + ordine.cliente.cognome +
      " spedita correttamente presso " + ordine.cliente.indirizzo.citta +
      " (" + ordine.cliente.indirizzo.provincia + ")."
    );
    esito = true
	}]{ println@Console("Eseguita richiestaSpedizione")() }
}