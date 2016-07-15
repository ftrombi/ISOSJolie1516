include "interfacciaMagazzinoPrimario.iol"
include "console.iol"
include "string_utils.iol"

outputPort MagazzinoPrimario{
  Location: "socket://localhost:8000"
  Protocol: soap
  Interfaces: InterfacciaMagazzinoPrimario
}

main{
  ordine.cliente.nome = "Sebastian";
  ordine.cliente.cognome = "Angus";
  ordine.cliente.indirizzo.citta = "Collecchio";
  ordine.cliente.indirizzo.provincia = "PR";

  ordine.prodotti[0].pezzi[0] = 0;
  ordine.prodotti[0].pezzi[1] = 1;
  ordine.prodotti[1].pezzi[0] = 2;
  ordine.prodotti[1].pezzi[1] = 3;
  ordine.prodotti[1].pezzi[2] = 4;

  verificaDisponibilitaERiservaPezzi@MagazzinoPrimario ( ordine )( risultato );

  println@Console(risultato)()
}