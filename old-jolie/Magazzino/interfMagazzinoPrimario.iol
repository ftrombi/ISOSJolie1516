include "dataTypes.iol"

interface InterfMagazzinoPrimario {
	RequestResponse:
	ricercaComponentiMagazzini ( Ordine )( InfoComponenti ),
	ricercaComponenteMagazzinoPrimario ( ComponenteIndirizzo )( InfoComponente ),
	rilasciaComponente ( InfoComponente ) ( string ),
	riservaComponente ( InfoComponente ) ( string ),
	assolvoOrdineCiclo ( OrdineCiclo ) ( bool ),
	assembloESpedisco ( OrdineCiclo )( bool ),
	assolvoOrdineComponenti ( OrdineComponenti )( bool )
}