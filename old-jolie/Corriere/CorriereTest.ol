include "CorriereInterface.iol"
include "console.iol"

outputPort CorriereServer{
	Location: "socket://localhost:8400"
	Protocol: http
	Interfaces: CorriereInterface
}

main{
    request.idMagazzinoPartenza = 0;
	request.idPacco = "id1";
	request.nome = "Luca";
	request.cognome = "Lucato";
	request.nazione = "Italia";
	request.provincia = "PR";
	request.citta = "Collecchio";
	request.via = "Via Primo 2";
	request.cap = "43044";
	request.telefono = "3380880182";
	richiestaSpedizione@CorriereServer(request)(response);
	println@Console(response.statoConsegna)()
}