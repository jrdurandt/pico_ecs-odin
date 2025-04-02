package ecs

import c "core:c"

when ODIN_OS == .Linux {
	foreign import lib "lib/linux/libpico_ecs.a"
} else when ODIN_OS == .Darwin {
	foreign import lib "lib/darwin/libpico_ecs.a"
} else when ODIN_OS == .Windows {
	foreign import lib "lib/windows/pico_ecs.lib"
}

ecs_t :: struct {
}

ecs_id_t :: c.uint32_t
ecs_ret_t :: c.int8_t
ecs_dt_t :: c.double

ecs_constructor_func :: #type proc "c" (
	ecs: ^ecs_t,
	entity_id: ecs_id_t,
	ptr: rawptr,
	args: rawptr,
) -> ecs_id_t

ecs_deconstructor_func :: #type proc "c" (
	ecs: ^ecs_t,
	entity_id: ecs_id_t,
	ptr: rawptr,
) -> ecs_id_t

ecs_system_fn :: #type proc "c" (
	ecs: ^ecs_t,
	entities: [^]ecs_id_t,
	entity_count: c.int,
	dt: ecs_dt_t,
	udata: rawptr,
) -> ecs_ret_t

ecs_added_fn :: #type proc "c" (ecs: ^ecs_t, entity_id: ecs_id_t, udata: rawptr)

ecs_removed_fn :: #type proc "c" (ecs: ^ecs_t, entity_id: ecs_id_t, udata: rawptr)

@(default_calling_convention = "c", link_prefix = "ecs_")
foreign lib {
	new :: proc(entity_count: c.size_t, mem_ctx: rawptr) -> ^ecs_t ---
	free :: proc(ecs: ^ecs_t) ---
	reset :: proc(ecs: ^ecs_t) ---

	register_component :: proc(ecs: ^ecs_t, size: c.size_t, constructor: ecs_constructor_func, destructor: ecs_deconstructor_func) -> ecs_id_t ---
	register_system :: proc(ecs: ^ecs_t, system_cb: ecs_system_fn, add_cb: ecs_added_fn, remove_cb: ecs_removed_fn, udata: rawptr) -> ecs_id_t ---
	require_component :: proc(ecs: ^ecs_t, sys_id: ecs_id_t, comp_id: ecs_id_t) ---
	exclude_component :: proc(ecs: ^ecs_t, sys_id: ecs_id_t, comp_id: ecs_id_t) ---
	enable_system :: proc(ecs: ^ecs_t, sys_id: ecs_id_t) ---
	disable_system :: proc(ecs: ^ecs_t, sys_id: ecs_id_t) ---
	create :: proc(ecs: ^ecs_t) -> ecs_id_t ---
	is_ready :: proc(ecs: ^ecs_t, entity_id: ecs_id_t) -> c.bool ---
	destroy :: proc(ecs: ^ecs_t, entity_id: ecs_id_t) ---
	has :: proc(ecs: ^ecs_t, entity_id: ecs_id_t, comp_id: ecs_id_t) -> c.bool ---
	add :: proc(ecs: ^ecs_t, entity_id: ecs_id_t, comp_id: ecs_id_t, args: rawptr) -> rawptr ---
	get :: proc(ecs: ^ecs_t, entity_id: ecs_id_t, comp_id: ecs_id_t) -> rawptr ---
	remove :: proc(ecs: ^ecs_t, entity_id: ecs_id_t, comp_id: ecs_id_t) ---
	queue_destroy :: proc(ecs: ^ecs_t, entity_id: ecs_id_t) ---
	queue_remove :: proc(ecs: ^ecs_t, entity_id: ecs_id_t, comp_id: ecs_id_t) ---
	update_system :: proc(ecs: ^ecs_t, sys_id: ecs_id_t, dt: ecs_dt_t) -> ecs_ret_t ---
	update_systems :: proc(ecs: ^ecs_t, dt: ecs_dt_t) -> ecs_ret_t ---
}

import "base:runtime"
import "core:fmt"
import "core:testing"

pos_comp: ecs_id_t

@(test)
test :: proc(t: ^testing.T) {
	// Creates concrete ECS instance
	ecs := new(1024, nil)
	defer free(ecs)

	//Create components
	// Pos :: struct {
	// 	x: f32,
	// 	y: f32,
	// }
	//
	Pos :: [2]f32

	Vel :: struct {
		vx: f32,
		vy: f32,
	}

	Rect :: struct {
		x: u32,
		y: u32,
		w: u32,
		z: u32,
	}

	//Register components
	pos_comp = register_component(ecs, size_of(Pos), nil, nil)
	vel_comp := register_component(ecs, size_of(Vel), nil, nil)
	rect_comp := register_component(ecs, size_of(Rect), nil, nil)


	//Create system update proc
	system_update := proc "c" (
		ecs: ^ecs_t,
		entities: [^]ecs_id_t,
		entity_count: c.int,
		dt: ecs_dt_t,
		udata: rawptr,
	) -> ecs_ret_t {
		context = runtime.default_context()
		for entity_id in entities[0:entity_count] {
			fmt.printfln("%v", entity_id)

			pos := cast(^Pos)get(ecs, entity_id, pos_comp)
			fmt.printfln("Pos: %v", pos)
		}
		return 0
	}

	//Register systems
	system_1 := register_system(ecs, system_update, nil, nil, nil)
	system_2 := register_system(ecs, system_update, nil, nil, nil)
	system_3 := register_system(ecs, system_update, nil, nil, nil)

	// System1 requires PosComp compnents
	require_component(ecs, system_1, pos_comp)

	// System2 requires both PosComp and VelComp components
	require_component(ecs, system_2, pos_comp)
	require_component(ecs, system_2, vel_comp)

	// System3 requires the PosComp, VelComp, and RectComp components
	require_component(ecs, system_3, pos_comp)
	require_component(ecs, system_3, vel_comp)
	require_component(ecs, system_3, rect_comp)

	fmt.printfln("----------")
	// Create three entities
	e1 := create(ecs)
	e2 := create(ecs)
	e3 := create(ecs)
	fmt.printfln("Created entities: %d, %d, %d", e1, e2, e3)

	fmt.printfln("----------")
	fmt.printfln("PosComp added to %d", e1)
	add(ecs, e1, pos_comp, nil)
	(cast(^Pos)get(ecs, e1, pos_comp)).x = 1

	fmt.printfln("----------")
	fmt.printfln("PosComp added to %d", e2)
	fmt.printfln("VelComp added to %d", e2)
	add(ecs, e2, pos_comp, nil)
	add(ecs, e2, vel_comp, nil)

	fmt.printfln("----------")
	fmt.printfln("PosComp added to %d", e3)
	fmt.printfln("VelComp added to %d", e3)
	fmt.printfln("RectComp added to %d", e3)
	add(ecs, e3, pos_comp, nil)
	add(ecs, e3, vel_comp, nil)
	add(ecs, e3, rect_comp, nil)

	fmt.printfln("----------")
	fmt.println("Executing system 1")
	update_system(ecs, system_1, 0.0)

	fmt.println("Executing system 2")
	update_system(ecs, system_2, 0.0)

	fmt.println("Executing system 3")
	update_system(ecs, system_3, 0.0)

	fmt.printfln("Last")
}
