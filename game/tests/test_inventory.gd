extends "res://tests/base_test.gd"
## Containers, carried health items, the full popup, the heal button, the coat, drops and
## saves. Fresh instances only: no autoloads, no physics (the GameState is injected).

const GameStateScript := preload("res://systems/game_state.gd")
const SaveSystemScript := preload("res://systems/save_system.gd")
const SettingsScript := preload("res://systems/settings.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const HealthPickupScript := preload("res://items/health_pickup.gd")
const ContainerPickupScript := preload("res://items/container_pickup.gd")
const ItemCatalogScript := preload("res://systems/item_catalog.gd")

const STARTER: String = "starter_container"
const TEMP_DIR := "user://test_tmp_inventory"


## A GameState holding the starter container.
func _with_container() -> GameStateScript:
	var gs: GameStateScript = GameStateScript.new()
	gs.try_equip_container(STARTER)
	return gs


func _pickup(gs: GameStateScript, id: String) -> HealthPickupScript:
	var p: HealthPickupScript = HealthPickupScript.new()
	p.item_id = id
	p.game_state = gs
	return p


# --- Data ---------------------------------------------------------------------------

func test_item_and_container_data() -> void:
	var k: Variant = ItemCatalogScript.health_item("kongomul")
	check(k != null and k.display_name == "콩고물" and k.heal_half_hearts == 2 and k.grants_coat, "콩고물: heal 1 heart + coat")
	var j: Variant = ItemCatalogScript.health_item("jocheong")
	check(j != null and j.display_name == "조청" and j.heal_half_hearts == 2 and not j.grants_coat, "조청")
	var g: Variant = ItemCatalogScript.health_item("ggul")
	check(g != null and g.display_name == "꿀" and g.heal_half_hearts == 2 and not g.grants_coat, "꿀")
	var c: Variant = ItemCatalogScript.container(STARTER)
	check(c != null and c.capacity == 3 and c.display_name == "Starter container", "starter container, capacity 3")
	check(ItemCatalogScript.health_item("../../evil") == null, "unknown ids never become paths")
	check(ItemCatalogScript.container("nope") == null, "unknown container")


# --- Container and pickups -----------------------------------------------------------

func test_no_container_means_carried_items_cannot_be_picked_up() -> void:
	var gs := GameStateScript.new()
	check_eq(gs.has_container(), false, "starts with no container")
	var p := _pickup(gs, "ggul")
	check_eq(p.try_collect(), false, "not picked up")
	check_eq(p.consumed, false, "it stays where it is")
	check_eq(gs.items.size(), 0, "nothing carried")
	check_eq(gs.popup_open(), false, "no popup without a container")
	check_eq(gs.try_pickup_item("ggul"), GameStateScript.Pickup.NO_CONTAINER, "reason")
	p.free()
	gs.free()


func test_a_container_pickup_equips_it_and_a_second_one_stays() -> void:
	var gs := GameStateScript.new()
	var c := ContainerPickupScript.new()
	c.game_state = gs
	check_eq(c.try_collect(), true, "picked up")
	check_eq(gs.container_id, STARTER, "equipped")
	check_eq(gs.inventory_capacity, 3, "capacity 3")
	var c2 := ContainerPickupScript.new()
	c2.game_state = gs
	check_eq(c2.try_collect(), false, "a second container is left on the ground")
	check_eq(c2.consumed, false, "still there")
	var p := _pickup(gs, "ggul")
	check_eq(p.try_collect(), true, "items can be picked up now")
	check_eq(gs.items, ["ggul"] as Array[String], "carried")
	c.free()
	c2.free()
	p.free()
	gs.free()


func test_carried_items_never_heal_on_touch() -> void:
	var gs := _with_container()
	gs.take_damage(6)
	var p := _pickup(gs, "jocheong")
	check(p.try_collect(), "picked up")
	check_eq(gs.hearts, 8, "no healing on touch, even when hurt")
	p.free()
	gs.free()


func test_capacity_three_and_the_fourth_opens_the_popup() -> void:
	var gs := _with_container()
	var picks: Array[HealthPickupScript] = []
	for id: String in ["kongomul", "jocheong", "ggul", "ggul"]:
		picks.append(_pickup(gs, id))
	for i: int in 3:
		check(picks[i].try_collect(), "pickup %d fits" % (i + 1))
	check_eq(gs.items.size(), 3, "three carried")
	check_eq(picks[3].try_collect(), false, "the 4th is not taken")
	check_eq(gs.items.size(), 3, "still three")
	check_eq(gs.popup_item_id, "ggul", "the popup is asking about the 4th")
	for p: HealthPickupScript in picks:
		p.free()
	gs.free()


func test_popup_use_it_now_heals_and_removes_the_pickup() -> void:
	var gs := _with_container()
	for id: String in ["ggul", "ggul", "ggul"]:
		gs.try_pickup_item(id)
	gs.take_damage(6)
	var p := _pickup(gs, "jocheong")
	p.try_collect()
	check(gs.popup_open(), "popup open")
	check_eq(gs.resolve_popup(true), true, "use it now")
	check_eq(gs.hearts, 10, "healed 1 heart")
	check_eq(p.consumed, true, "the pickup is gone")
	check_eq(gs.popup_open(), false, "popup closed")
	check_eq(gs.items.size(), 3, "inventory unchanged")
	p.free()
	gs.free()


func test_popup_drop_it_and_closing_leave_it_on_the_ground() -> void:
	var gs := _with_container()
	for id: String in ["ggul", "ggul", "ggul"]:
		gs.try_pickup_item(id)
	gs.take_damage(6)
	var p := _pickup(gs, "kongomul")
	p.try_collect()
	check_eq(gs.resolve_popup(false), true, "drop it")
	check_eq(p.consumed, false, "left on the ground")
	check_eq(gs.hearts, 8, "nothing healed")
	check_eq(gs.coat, false, "no coat")
	check_eq(p.try_collect(), false, "standing on it does not re-open the popup")
	check_eq(gs.popup_open(), false, "popup stays closed until he steps off")
	p.free()
	gs.free()


func test_popup_use_is_greyed_out_when_it_would_do_nothing() -> void:
	var gs := _with_container()
	for id: String in ["ggul", "ggul", "ggul"]:
		gs.try_pickup_item(id)
	# Hearts full, no coat item: nothing to do.
	check_eq(gs.would_do_nothing("jocheong"), true, "full hearts, no coat: greyed")
	# Hearts full but a 콩고물 would give the coat: not greyed.
	check_eq(gs.would_do_nothing("kongomul"), false, "full hearts, coat to gain: allowed")
	gs.open_popup("jocheong")
	check_eq(gs.resolve_popup(true), false, "greyed-out use is refused")
	check_eq(gs.popup_open(), true, "popup stays open")
	gs.resolve_popup(false)
	# A coat is already on, hearts full: even 콩고물 does nothing.
	gs.coat = true
	check_eq(gs.would_do_nothing("kongomul"), true, "full hearts, coat already on: greyed")
	# Hurt: anything heals.
	gs.take_damage(2)
	check_eq(gs.would_do_nothing("jocheong"), false, "hurt: allowed")
	check_eq(gs.would_do_nothing("kongomul"), false, "hurt with a coat on: still heals")
	gs.free()


# --- Heal button ---------------------------------------------------------------------

func test_heal_order_ties_resolve_coat_last_then_oldest() -> void:
	var gs := _with_container()
	for id: String in ["kongomul", "ggul", "jocheong"]:
		gs.try_pickup_item(id)
	# All heal 2: the non-coat items first (oldest first), 콩고물 last.
	var order: Array[int] = gs.heal_order()
	check_eq(order, [1, 2, 0] as Array[int], "ggul, jocheong, then kongomul")
	gs.take_damage(10)
	check_eq(gs.heal_button(), "ggul", "1st press")
	check_eq(gs.heal_button(), "jocheong", "2nd press")
	check_eq(gs.heal_button(), "kongomul", "3rd press")
	check_eq(gs.hearts, 10, "4 half-hearts + 3 x 2 = 10")
	check_eq(gs.coat, true, "the 콩고물 gave its coat")
	check_eq(gs.items.size(), 0, "all used")
	gs.free()


func test_oldest_goes_first_among_equals() -> void:
	var gs := _with_container()
	for id: String in ["jocheong", "ggul"]:
		gs.try_pickup_item(id)
	gs.take_damage(10)
	check_eq(gs.heal_button(), "jocheong", "the older of two equal items")
	gs.free()


func test_settings_default_wins_when_held_and_falls_back_when_not() -> void:
	var gs := _with_container()
	for id: String in ["ggul", "jocheong", "kongomul"]:
		gs.try_pickup_item(id)
	gs.take_damage(10)
	check_eq(gs.heal_button("kongomul"), "kongomul", "the default item is used first")
	check_eq(gs.heal_button("kongomul"), "ggul", "not held any more: the normal order")
	check_eq(gs.heal_button("nonsense"), "jocheong", "an unknown default falls back too")
	gs.free()


func test_heal_button_at_full_hearts_uses_nothing() -> void:
	var gs := _with_container()
	gs.try_pickup_item("kongomul")
	check_eq(gs.heal_button(), "", "nothing used")
	check_eq(gs.items.size(), 1, "still carried")
	check_eq(gs.coat, false, "and no coat from the button at full hearts")
	gs.free()


func test_heal_caps_at_14_half_hearts() -> void:
	var gs := _with_container()
	for id: String in ["ggul", "ggul"]:
		gs.try_pickup_item(id)
	gs.take_damage(1)
	check_eq(gs.heal_button(), "ggul", "used")
	check_eq(gs.hearts, 14, "capped at 7 hearts")
	check_eq(gs.heal_button(), "", "now full: nothing")
	check_eq(gs.items.size(), 1, "second one kept")
	gs.free()


func test_heal_button_does_nothing_with_no_items_or_when_dead() -> void:
	var gs := _with_container()
	gs.take_damage(4)
	check_eq(gs.heal_button(), "", "no items")
	gs.try_pickup_item("ggul")
	gs.take_damage(100)
	check_eq(gs.heal_button(), "", "dead: nothing")
	check_eq(gs.items.size(), 1, "kept")
	gs.free()


func test_the_player_heal_request_reads_the_settings_default() -> void:
	var gs := _with_container()
	for id: String in ["ggul", "jocheong"]:
		gs.try_pickup_item(id)
	gs.take_damage(8)
	var settings := SettingsScript.new()
	settings.heal_default = "jocheong"
	var p: DdeokScript = DdeokScript.new()
	p.game_state = gs
	p.settings = settings
	check_eq(p.request_heal(), true, "used something")
	check_eq(gs.items, ["ggul"] as Array[String], "the default item went first")
	p.free()
	settings.free()
	gs.free()


# --- Inventory screen use / drop ------------------------------------------------------

func test_inventory_screen_can_use_a_kongomul_at_full_hearts_for_the_coat() -> void:
	var gs := _with_container()
	gs.try_pickup_item("kongomul")
	check_eq(gs.use_item_at(0), true, "used")
	check_eq(gs.coat, true, "coat gained")
	check_eq(gs.hearts, 14, "still full")
	check_eq(gs.items.size(), 0, "used up")
	gs.try_pickup_item("jocheong")
	check_eq(gs.use_item_at(0), false, "a 조청 at full hearts would do nothing: refused")
	check_eq(gs.items.size(), 1, "and kept")
	gs.free()


# --- Coat -----------------------------------------------------------------------------

func test_coat_blocks_one_hits_damage_only_and_does_not_stack() -> void:
	var gs := _with_container()
	gs.try_pickup_item("kongomul")
	gs.try_pickup_item("kongomul")
	gs.take_damage(2)
	gs.heal_button()
	check_eq(gs.coat, true, "coat on")
	check_eq(gs.hearts, 14, "healed")
	gs.take_damage(2)
	check_eq(gs.heal_button(), "kongomul", "a second 콩고물 while coated")
	check_eq(gs.hearts, 14, "still heals")
	check_eq(gs.coat, true, "one coat, not stacked")
	check_eq(gs.take_hit(2), true, "the coat absorbs the hit")
	check_eq(gs.hearts, 14, "no damage")
	check_eq(gs.coat, false, "coat used up: it was ONE hit, not two")
	check_eq(gs.take_hit(2), false, "the next hit lands")
	check_eq(gs.hearts, 12, "damage taken")
	gs.free()


func test_a_coated_player_takes_knockback_and_invulnerability_but_no_damage() -> void:
	var gs := GameStateScript.new()
	gs.coat = true
	var p: DdeokScript = DdeokScript.new()
	p.game_state = gs
	check_eq(p.hurt(2, -1.0), true, "the hit registers")
	check_eq(gs.hearts, 14, "no damage")
	check_eq(gs.coat, false, "coat gone")
	check(absf(p.velocity.x) > 0.0 and p.velocity.y > 0.0, "knockback applied: " + str(p.velocity))
	check_eq(p.is_invulnerable(), true, "invulnerability frames still happen")
	check_eq(p.state_name(), "hurt", "hurt state")
	p.free()
	gs.free()


func test_the_pit_kills_through_the_coat() -> void:
	var gs := GameStateScript.new()
	gs.coat = true
	var p: DdeokScript = DdeokScript.new()
	p.game_state = gs
	p.kill()
	check_eq(gs.hearts, 0, "falling out of the world ignores the coat")
	p.free()
	gs.free()


# --- Drop -----------------------------------------------------------------------------

func test_drop_removes_the_item_and_announces_it() -> void:
	var gs := _with_container()
	for id: String in ["ggul", "jocheong"]:
		gs.try_pickup_item(id)
	var dropped: Array[String] = []
	gs.item_dropped.connect(func(id: String) -> void: dropped.append(id))
	check_eq(gs.drop_item_at(0), "ggul", "slot 0 dropped")
	check_eq(gs.items, ["jocheong"] as Array[String], "the rest keep their order")
	check_eq(dropped, ["ggul"] as Array[String], "the 떡 is told to put it on the ground")
	check_eq(gs.drop_item_at(5), "", "an empty slot drops nothing")
	gs.free()


func test_a_dropped_pickup_cannot_be_picked_up_for_a_second() -> void:
	var gs := _with_container()
	var p := _pickup(gs, "ggul")
	p.pickup_delay = DdeokScript.DROP_REPICK_DELAY_S
	check_eq(DdeokScript.DROP_REPICK_DELAY_S, 1.0, "about 1 s")
	check_eq(p.try_collect(), false, "not at once")
	p.tick(0.9)
	check_eq(p.try_collect(), false, "not after 0.9 s")
	p.tick(0.2)
	check_eq(p.try_collect(), true, "after 1.1 s")
	check_eq(gs.items.size(), 1, "carried again")
	p.free()
	gs.free()


# --- Save -----------------------------------------------------------------------------

func test_save_and_load_keep_container_items_in_order_and_coat() -> void:
	var s := SaveSystemScript.new()
	s.save_path = TEMP_DIR + "/slot.json"
	var a := _with_container()
	for id: String in ["jocheong", "kongomul", "ggul"]:
		a.try_pickup_item(id)
	a.coat = true
	check(s.save_game(a), "save ok")
	check_eq(SaveSystemScript.SAVE_VERSION, 1, "save_version stays 1 (additive keys)")
	var b := GameStateScript.new()
	check(s.load_game(b), "load ok: " + s.last_error)
	check_eq(b.container_id, STARTER, "container")
	check_eq(b.inventory_capacity, 3, "capacity")
	check_eq(b.items, ["jocheong", "kongomul", "ggul"] as Array[String], "items, in order")
	check_eq(b.coat, true, "coat")
	DirAccess.remove_absolute(s.save_path)
	DirAccess.remove_absolute(TEMP_DIR)
	s.free()
	a.free()
	b.free()


func test_an_old_save_without_the_new_keys_loads_with_no_container_and_no_coat() -> void:
	var gs := _with_container()
	gs.coat = true
	gs.from_dict({"hearts": 6, "items": []})
	check_eq(gs.container_id, "", "no container")
	check_eq(gs.coat, false, "no coat")
	check_eq(gs.hearts, 6, "the rest loads")
	gs.from_dict({"container_id": "not_a_container", "coat": "yes"})
	check_eq(gs.container_id, "", "unknown container ignored")
	check_eq(gs.coat, false, "a non-bool coat ignored")
	gs.free()
