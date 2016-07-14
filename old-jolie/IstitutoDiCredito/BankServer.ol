include "console.iol"
include "math.iol"
include "BankInterface.iol"

inputPort input{
	Location: "socket://localhost:8200"
	Protocol: http 
	Interfaces: BankInterface
}

execution { concurrent }

main
{
	[requestVerification(request)(response) {
		random@Math()(result);
		if(result <= 0.3)
			response.message = false
		else
			response.message = true
	}]{ println@Console("invocata requestVerification")() }
}