extends "res://tests/base_test.gd"

const ChainBridgeScript := preload("res://systems/chain_bridge.gd")


func test_off_chain_stub() -> void:
	var c := ChainBridgeScript.new()
	check_eq(c.is_on_chain(), false, "not on chain")
	var result: Dictionary = c.connect_wallet()
	check_eq(result.get("ok"), false, "connect not ok")
	check((result.get("message", "") as String).contains("not available"), "clear message")
	c.free()
