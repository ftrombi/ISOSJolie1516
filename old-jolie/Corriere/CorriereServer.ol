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
	[richiestaSpedizione(request)(response) {
		response.statoConsegna = "Oggetto: " + request.idPacco + " spedito in " + request.via + " " + request.citta + " " +  request.provincia + " " + request.nazione
	}]{ println@Console("eseguito richiestaSpedizione")() }
}