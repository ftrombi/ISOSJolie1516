include "../Magazzini/dataTypes.iol"

interface InterfacciaFornitore {
	RequestResponse:
  richiestaRiservaPezzi( Prodotto ) ( ArrayBooleani )
  annullaRiservaPezzi( Prodotto )( ArrayBooleani )
}