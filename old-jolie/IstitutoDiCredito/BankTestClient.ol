include "BankInterface.iol"
include "console.iol"

outputPort BankServer{
	Location: "socket://localhost:8200"
	Protocol: http
	Interfaces: BankInterface
}

main{
	request.id = "123465798987654321";
	requestVerification@BankServer(request)(response);
	if( response.message == true ) {
		println@Console("True")() 
	} else {
		println@Console("False")() 
	}
}