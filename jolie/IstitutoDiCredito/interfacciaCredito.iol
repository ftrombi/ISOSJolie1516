include "../Magazzini/dataTypes.iol"
include "tipiCredito.iol"

interface InterfacciaCredito {
	RequestResponse:
  richiestaVerifica( Cliente )( Booleano )
}