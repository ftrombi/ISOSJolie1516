include "DistanceTypes.iol"

interface DistanceInterface {
	RequestResponse: getBestDistance(DistanceRequest)(DistanceResponse)
}