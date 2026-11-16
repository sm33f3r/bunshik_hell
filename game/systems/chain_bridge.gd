extends Node
## Autoload "ChainBridge": the only door to Sui. Off-chain stub for now.
## No network calls, no key handling, no wallet code.


func is_on_chain() -> bool:
	return false


func connect_wallet() -> Dictionary:
	return {
		"ok": false,
		"error": "not_available",
		"message": "Wallet connection is not available in this build.",
	}
