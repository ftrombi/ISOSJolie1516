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
  .nazione:string
  .provincia:string
  .citta:string
  .via:string
  .cap:string
}

type ConfermeSpedizioni:void {
  .conferme*:bool
}

type InformazioniSpedizioni:void {
  .dateSpedizioni*:string
}