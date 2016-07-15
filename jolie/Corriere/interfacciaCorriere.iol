include "../Magazzini/dataTypes.iol"
interface CorriereInterface {
	RequestResponse:
  richiestaSpedizione( Ordine )( Booleano )
}