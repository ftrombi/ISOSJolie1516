include "dataTypes.iol"

interface InterfacciaMagazzinoPrimario {
	RequestResponse:
	verificaDisponibilitaERiservaPezzi ( Ordine )( Booleano ),
	eseguoOrdine ( Ordine )( ArrayBooleani ),
  verificaDisponibilitaPezziNelDBERiservaDisponibili (Ordine)(Prodotto),
  annullamentoOrdine ( Ordine )( Booleano ),
  rilascioPezziRiservatiNelDB (Ordine)(Prodotto)
}