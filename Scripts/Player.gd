extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var flagState: FlagStateManager = $FlagStateManager
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

const Flags = StateFlags.Flags;
const FlagsPriority = StateFlags.FlagsPriority;
const SPEED = 1000.0
const SPEED_MOD = 30
const JUMP_VELOCITY = -650.0
const GRAVITY_MOD = 1.5
const COYOTE_TIME = 0.12 # in seconds
const JUMP_BUFFER_TIME = 0.1 # in seconds

var coyote_timer: float = 0.0;
var jump_buffer_timer: float = 0.0;
var was_on_floor: bool = false;

var current_animation = "";

var Animations: Dictionary = {
	Flags.Idle: "Idle",
	Flags.Running: "Run",
	Flags.Jumping: "Jump",
	Flags.Falling: "Falling",
	Flags.Attacking: "Attacking",
}


func bin_count( value: int ) -> int:
	var count: int = 0;
	while value:
		count += value & 1;
		value >>= 1;
	return count;


func _update_coyote( delta: float ) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME;
		was_on_floor = true;
	elif coyote_timer > 0.0:
		coyote_timer -= delta;


func _handle_jump() -> void:
	if jump_buffer_timer > 0.0 and _can_jump():
		flagState.Add( Flags.Jumping );
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0;
		jump_buffer_timer = 0.0;
		current_animation = "";


func _can_jump() -> bool:
	return ( is_on_floor() or coyote_timer > 0.0 );

func _can_process_input() -> bool:
	return true;


func _get_animation() -> String:
	var animation: String = current_animation;
	var max_priority = -1;

	for key in Animations.keys():
		if flagState.Has( key ) and FlagsPriority[key] > max_priority:
			animation = Animations[key];
			max_priority = FlagsPriority[key];

	return animation;


func _update_animations() -> void:
	if direction != 0:
		animated_sprite_2d.flip_h = direction < 0;

	var new_animation = _get_animation();
	if new_animation == current_animation:
		return;
	
	animated_sprite_2d.animation = new_animation;
	animated_sprite_2d.play();
	current_animation = new_animation;
	print("Current Animation: " + current_animation );


var wait_frames: int = 3;
var idle_pending_counter: int = wait_frames;
var direction: int = 0;


func _update_flags() -> void:
	if Input.is_action_just_pressed("Attack"):
			flagState.Add( Flags.Attacking );

	if is_on_floor():
		flagState.Remove( Flags.Falling );

		if velocity.x != 0 :
			flagState.Remove( Flags.Idle );
			flagState.Add( Flags.Running );
			idle_pending_counter = wait_frames;
		else:
			if idle_pending_counter <= 0:
				flagState.Remove( Flags.Running );
				flagState.Add( Flags.Idle );
			idle_pending_counter -= 1;

		if flagState.Has( Flags.Jumping ):
			flagState.Remove( Flags.Falling );
			flagState.Remove( Flags.Idle );
	else:
		if velocity.y != 0:
			flagState.Remove( Flags.Idle );
		if velocity.y > 0:
			flagState.Add( Flags.Falling );
			flagState.Remove( Flags.Jumping );


func _update_input( delta: float ) -> void:
	if not _can_process_input():
		return;
	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME;
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta;
	
	direction = 0;
	if Input.is_action_pressed("Left") and direction != 1:
		direction = -1;
	elif Input.is_action_pressed("Right") and direction != -1:
		direction = 1;


func _update_movement( delta: float ) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MOD * delta
	
	velocity.x = direction * SPEED * SPEED_MOD * delta


func _ready() -> void:
	animated_sprite_2d.animation_finished.connect( _on_animation_finished );


func _on_animation_finished() -> void:
	match animated_sprite_2d.animation:
		"Attacking":
			flagState.Remove( Flags.Attacking );
			current_animation = "df"
			pass


func _physics_process(delta: float) -> void:
	_update_input( delta );
	_update_coyote( delta );
	_handle_jump();
	_update_flags();
	_update_movement( delta );
	_update_animations();


	if Input.is_action_just_pressed("PrintFlags"):
		print( flagState.GetActiveFlagNames() );

	move_and_slide()
