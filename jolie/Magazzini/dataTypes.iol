type Ordine:void {
  .cliente:Cliente
  .prodotti*:Prodotto
}

type Prodotto:void {
  .pezzi*:int
}

type Intero:void {
  .valore:int
}

type ProdottoIDMagazzinoCliente:void {
  .idMagazzino:int
  .pezzo:int
  .destinatario:Cliente
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

type Booleano:void{
  .valore:bool
}