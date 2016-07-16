include "dataTypes.iol"

interface InterfacciaMagazzinoPrimario {
	RequestResponse:
	verificaDisponibilitaERiservaPezzi ( Ordine )( Booleano ),
	eseguoOrdine ( Ordine )( Booleano ),
  verificaDisponibilitaPezziNelDBERiservaDisponibili (Ordine)(Prodotto),
  annulloOrdine (Ordine)(Booleano),
  spedisciDaMagazzini(ProdottoIDMagazzinoCliente)(Booleano),
  richiestaSpedizione( Ordine )( Booleano ),
  assemblaCicloESpedisci( Ordine )( Booleano )
}