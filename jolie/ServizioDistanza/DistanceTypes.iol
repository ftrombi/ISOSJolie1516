type Point: void{
	.citta: string
	.provincia: string
}

type DistanceRequest: void{

	.origin: Point
	//coordiante magazzino principale
	.destination: Point
}

type DistanceResponse: void{
	//variabili riguardanti il risultato ( se presente)
	.distance?: int
	
	//variabile contentente il messaggio di errore(se si è verificato)
	.message?: string
	
	//variabile contenente lo stato della richiesta (OK o ERROR) 
	.status: string
}