include "console.iol"
include "math.iol"
include "time.iol"
include "interfacciaCredito.iol"

inputPort input{
	Location: "socket://localhost:8200"
	Protocol: http 
	Interfaces: InterfacciaCredito
}

define log {
  getCurrentDateTime@Time(null)(ts); 
  println@Console(ts + " - " + daStampare)()
}

execution { concurrent }

init {
  daStampare = "Inizio procedura Istituto di credito"; log
}

main
{
	[richiestaVerifica( infoPagamento )( esito ) {
		random@Math()( r );
		if ( r <= 0.3 ) {
			esito.valore = false;
			daStampare = "Il cliente " + infoPagamento.cliente.nome +
				" " + infoPagamento.cliente.cognome +
				" non ha effettuato correttamente il pagamento."; log
		}
		else {
			esito.valore = true;
			daStampare = "Il cliente " + infoPagamento.cliente.nome +
				" " + infoPagamento.cliente.cognome +
				" ha effettuato correttamente il pagamento."; log
		}
	}]{ daStampare = "Invocata richiestaVerifica"; log }
}