include "../Magazzini/dataTypes.iol"
interface InterfacciaCorriere {
	RequestResponse:
  richiestaSpedizione( Ordine )( Booleano )
}