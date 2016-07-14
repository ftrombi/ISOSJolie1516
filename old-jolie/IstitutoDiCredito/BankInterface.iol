include "BankTypes.iol"

interface BankInterface {
	RequestResponse: requestVerification(verificationItem)(verificationResult)
}