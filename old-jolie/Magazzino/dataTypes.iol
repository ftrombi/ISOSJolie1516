type Indirizzo:void {
	.nazione:string
	.provincia:string
	.citta:string
	.via:string
	.cap:string
}

type Cliente:void {
	.nome:string
	.cognome:string
	.indirizzo:Indirizzo
	.telefono:string
}

// COMPONENTI =========================
type Componente:void {
	.id:int
}

type Ordine:void {
	.listaComponenti*:Componente
	.indirizzoCliente:Indirizzo
}

type OrdineCiclo:void{
	.listaComponentiCiclo*:Componente
	.cliente:Cliente
}

type OrdineComponenti:void{
	.listaInfoComponenti*:InfoComponente
	.cliente:Cliente
}

type ComponenteIndirizzo:void {
	.componente:Componente
	.indirizzo:Indirizzo
}
//=====================================

// INFO COMPONENTI ====================
type InfoComponente:void {
	.componente:Componente
	.distanzaDalCliente:double
	.magazzino:Magazzino
	.daOrdinare:bool
}

type InfoComponenteIndirizzo:void{
	.infoComponente:InfoComponente
	.indirizzo:Indirizzo
}

type InfoComponenti:void {
	.listaInfoComponenti*:InfoComponente
}
//=====================================

// MAGAZZINO ==========================
type Magazzino:void {
	.id:int
	.indirizzo:Indirizzo
}

type Magazzini:void {
	.listaMagazzini*:Magazzino
}
// ====================================