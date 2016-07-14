include "dataTypes.iol"

interface InterfacciaMagazzinoPrimario {
	RequestResponse:
	verificaDisponibilitaERiservaPezzi ( Ordine )( InformazioniSpedizioni ),
	eseguoOrdine ( Ordine )( ConfermeSpedizioni )
}