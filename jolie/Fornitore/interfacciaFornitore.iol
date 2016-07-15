include "../Magazzini/dataTypes.iol"

interface InterfacciaFornitore {
	RequestResponse:
  richiestaRiservaPezzi( Intero ) ( Booleano ),
  annullaRiservaPezzi( Prodotto )( ArrayBooleani )
}