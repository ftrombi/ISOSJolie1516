type Ordine:void {
  .cliente:Cliente
  .prodotti*:Prodotto
}

type Prodotto:void {
  .pezzi*:int
}

type Cliente:void {
  .nome:string
  .cognome:string
  .indirizzo:Indirizzo
}

type Indirizzo:void {
  .provincia:string
  .citta:string
}

type ArrayBooleani:void {
  .booleano*:bool
}

type Booleano:void{
  .valore:bool
}