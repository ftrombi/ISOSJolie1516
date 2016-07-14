include "SupplierInterface.iol"
include "console.iol"

outputPort SupplierServer{
	Location: "socket://localhost:8300"
	Protocol: http
	Interfaces: SupplierInterface
}

main{
	request.idElement = "id1";
	requestOrder@SupplierServer(request)(response);
	println@Console(response.message)()
}