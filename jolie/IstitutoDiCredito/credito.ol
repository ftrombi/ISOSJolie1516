include "console.iol"
include "math.iol"
include "interfacciaCredito.iol"

inputPort input{
	Location: "socket://localhost:8200"
	Protocol: http 
	Interfaces: InterfacciaCredito
}

execution { concurrent }

main
{
	[richiestaVerifica( infoPagamento )( esito ) {
		random@Math()( r );
		if ( r <= 0.3 ) {
			esito.valore = false;
			println@Console(
				"Il cliente " + infoPagamento.cliente.nome +
				" " + infoPagamento.cliente.cognome +
				" non ha effettuato correttamente il pagamento."
			)()
		}
		else {
			esito.valore = true;
			println@Console(
				"Il cliente " + infoPagamento.cliente.nome +
				" " + infoPagamento.cliente.cognome +
				" ha effettuato correttamente il pagamento."
			)()
		}
	}]{ println@Console( "Invocata richiestaVerifica" )() }
}