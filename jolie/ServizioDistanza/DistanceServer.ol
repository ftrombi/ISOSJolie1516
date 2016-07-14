include "console.iol"
include "GoogleInterface.iol"
include "DistanceInterface.iol"

outputPort GoogleService {
	Location: "socket://maps.googleapis.com:80/maps/api/distancematrix/"
	Protocol: http { .method = "get" }
	Interfaces: GoogleInterface
}

inputPort input{
	Location: "socket://localhost:8100"
	Protocol: http 
	Interfaces: DistanceInterface
}

execution{ concurrent }

main
{
	[getBestDistance(request)(response) {
		//imposto la richiesta a google
		googleDistanceRequest.origins = request.origin.citta + "+" + request.origin.provincia;
		googleDistanceRequest.destinations = request.destination.citta + "+" + request.destination.provincia;
		googleDistanceRequest.mode = "driving";
		googleDistanceRequest.language = "it-IT";
		
		//eseguo la richiesta verso google
		json@GoogleService(googleDistanceRequest)(googleResponse);
		
		if(googleResponse.status == "OK"){			
			response.distance = googleResponse.rows[0].elements[0].distance.value;
			response.status = "OK"
		} else if(googleResponse.status == "NOT_FOUND"){
			response.message = "BAD COORDINATES";
			response.status = "ERROR"
		} else if(googleResponse.status == "ZERO_RESULTS"){
			response.message = "ZERO RESULTS";
			response.status = "ERROR"
		} else{
			response.message = "UNKNOW";
			response.status = "ERROR"
		}
	}]
	
}