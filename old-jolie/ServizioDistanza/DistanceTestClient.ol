include "DistanceInterface.iol"
include "console.iol"
outputPort DistanceServer{
	Location: "socket://localhost:8100"
	Protocol: http
	Interfaces: DistanceInterface
}

main{
	distanceRequest.origin.citta = "Collecchio";
	distanceRequest.origin.provincia = "PR";
	
	
	distanceRequest.destination.citta = "Parma";
	distanceRequest.destination.provincia = "PR";
	
	
	getBestDistance@DistanceServer(distanceRequest)(response);
	
	println@Console(response.status)();
	if(response.status == "OK"){
		println@Console(response.distance)()
	}else{
		println@Console(response.message)()
	}
	
}