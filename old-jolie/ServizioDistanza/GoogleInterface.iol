type GoogleDistanceRequest: void{
	.origins: string
	.destinations: string
	.mode: string
	.language: string
}

type GoogleRowElementValue: void{
	.text: string
	.value: int
}

type GoogleRowElement:void {
	.elements[0,*]: GoogleRowElementField
}

type GoogleRowElementField: void{
	.distance: GoogleRowElementValue
	.duration: GoogleRowElementValue
	.status: string
}

type GoogleResponse: void{
	.destination_addresses[0,*]: string
	.origin_addresses[0,*]: string
	.rows[0,*]: GoogleRowElement	
	.status: string
}

interface GoogleInterface {
	RequestResponse: json(GoogleDistanceRequest)(GoogleResponse)
}