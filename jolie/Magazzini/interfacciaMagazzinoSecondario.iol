include "dataTypes.iol"

interface InterfacciaMagazzinoSecondario {
  RequestResponse:
  richiestaSpedizione( Ordine )( Booleano )
}