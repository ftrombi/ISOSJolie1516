include "console.iol"
include "SupplierInterface.iol"

inputPort input{
	Location: "socket://localhost:8300"
	Protocol: http 
	Interfaces: SupplierInterface
}

execution{ concurrent }

main
{
	[ requestOrder(request)(response) {
		response.message = "Oggetto: " + request.idElement + " inviato al magazzino principale."
	}]
}