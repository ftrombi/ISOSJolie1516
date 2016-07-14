include "dataTypes.iol"

interface InterfMagazzinoSecondario {
	RequestResponse:
	ricercaComponenteMagazzino ( InfoComponenteIndirizzo )( InfoComponente ),
	rilasciaComponente ( InfoComponente )( string ),
	riservaComponente ( InfoComponente )( string ),
	spedisciAlMagazzinoPrimario ( Componente )( bool )
}