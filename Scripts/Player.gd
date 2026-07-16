extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var flagState: FlagStateManager = $FlagStateManager
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var jump_audio: AudioStreamPlayer2D = $JumpAudio
@onready var land_audio: AudioStreamPlayer2D = $LandAudio
@onready var attack_audio: AudioStreamPlayer2D = $AttackAudio
@onready var footstep_audio: AudioStreamPlayer2D = $FootstepAudio
@onready var run_particles: GPUParticles2D = $RunParticles
@onready var land_particles: GPUParticles2D = $LandParticles

const Flags = StateFlags.Flags;
const FlagsPriority = StateFlags.FlagsPriority;

const SPEED = 800.0
const SPEED_MOD = 30
const JUMP_VELOCITY = -750.0
const GRAVITY_MOD = 2
const COYOTE_TIME = 0.1 # in seconds
const ATTACK_BUFFER_TIME = 0.25 # in seconds
const JUMP_BUFFER_TIME = 0.15 # in seconds
const ATTACK_COOLDOWN_TIME = 0.25 # in seconds

const FOOTSTEPS_INTERVAL_MIN = 0.2;
const FOOTSTEPS_INTERVAL_MAX = 0.5;

const COLLISION_OFFSET_ATTACKING = 10;

var coyote_timer: float = 0.0;
var jump_buffer_timer: float = 0.0;
var attack_buffer_timer: float = 0.0;
var attack_cooldown_timer: float = 0.0;
var footstep_timer: float = 0.0;

var was_on_floor: bool = false;

var current_animation = "";

const Animations: Dictionary = {
	Flags.Idle: "Idle",
	Flags.Running: "Run",
	Flags.Jumping: "Jump",
	Flags.Falling: "Falling",
	Flags.Attacking: "Attacking",
}

const AttackSounds = [
	preload("uid://iac6vrdwnjhp"),
	preload("uid://dtycusfuestqi"),
]

const FootstepsRunDirt = [
	preload("uid://4wmbpnmpvy4f"),
	preload("uid://bskdth5vmx0uk"),
	preload("uid://bn278dk4cl53r"),
	preload("uid://p4cayxmtlkoi"),
	preload("uid://bfvolnq7jpd2k"),
]


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


func _update_particles() -> void:
	var should_emit: bool = flagState.Has( StateFlags.Flags.Running ) and flagState.HasNone( StateFlags.IN_AIR );
	
	if run_particles.emitting != should_emit:
		run_particles.emitting = should_emit;

	run_particles.position.x = -sign(velocity.x) * 5.0;


var _was_on_floor: bool = false;

func _handle_landing() -> void:
	var on_floor = is_on_floor();
	
	if on_floor and not _was_on_floor:
		land_particles.restart();
	
	_was_on_floor = on_floor;


func _handle_attack() -> void:
	if _can_attack():
		flagState.Add( Flags.Attacking );
		attack_buffer_timer = 0.0;
		current_animation = "";
		attack_audio.pitch_scale = randf_range( 0.8, 1.0 );
		attack_audio.stream = AttackSounds[ randi_range( 0, AttackSounds.size() -1 ) ];
		attack_audio.play();


func _handle_jump() -> void:
	if jump_buffer_timer > 0.0 and _can_jump():
		flagState.Add( Flags.Jumping );
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0;
		jump_buffer_timer = 0.0;
		current_animation = "";
		
		jump_audio.pitch_scale = randf_range( 0.8, 1.1 );
		jump_audio.play();


func _handle_footsteps( delta: float ) -> void:
	if flagState.HasNone( Flags.Running ) or flagState.HasAny( StateFlags.IN_AIR ):
		footstep_timer = 0.0;
		return;

	footstep_timer -= delta;
	if !( footstep_timer > 0.0 ):
		_play_footsteps();
		var speed_ratio: float = absf( velocity.x ) / SPEED;
		footstep_timer = lerpf( FOOTSTEPS_INTERVAL_MIN, FOOTSTEPS_INTERVAL_MAX, speed_ratio );

func _play_footsteps() -> void:
	footstep_audio.pitch_scale = randf_range( 0.8, 1.0 );
	footstep_audio.stream = FootstepsRunDirt[randi_range( 0, FootstepsRunDirt.size() -1 )];
	footstep_audio.play();


func _can_attack() -> bool:
	return !( attack_cooldown_timer > 0.0 ) and attack_buffer_timer > 0.0 and flagState.HasNone( Flags.Attacking );

func _can_jump() -> bool:
	return ( is_on_floor() or coyote_timer > 0.0 );

func _can_move() -> bool:
	return flagState.HasNone( Flags.Attacking ) or flagState.HasAny( StateFlags.IN_AIR );


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
	if is_on_floor():
		if flagState.Has( Flags.Falling ):
			land_audio.pitch_scale = randf_range( 0.8, 1.0 );
			land_audio.play();
			flagState.Remove( Flags.Falling );

		if velocity.x != 0 :
			flagState.Add( Flags.Running );
			idle_pending_counter = wait_frames;
		else:
			if idle_pending_counter <= 0:
				flagState.Remove( Flags.Running );
			idle_pending_counter -= 1;

		if flagState.Has( Flags.Jumping ):
			flagState.Remove( Flags.Falling );
	else:
		if velocity.y > 0:
			flagState.Add( Flags.Falling );
			flagState.Remove( Flags.Jumping );
	
	if flagState.HasNone( StateFlags.IN_ACTION ):
		flagState.Add( Flags.Idle );
	else:
		flagState.Remove( Flags.Idle );


func _update_input( delta: float ) -> void:		
	if Input.is_action_just_pressed("Attack"):
		attack_buffer_timer = ATTACK_BUFFER_TIME;
	elif attack_buffer_timer > 0.0:
		attack_buffer_timer -= delta;

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME;
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta;

	if not _can_move() or flagState.Has( Flags.Attacking ):
		return;
	
	direction = 0;
	if Input.is_action_pressed("Left") and direction != 1:
		direction = -1;
	elif Input.is_action_pressed("Right") and direction != -1:
		direction = 1;


func _update_movement( delta: float ) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MOD * delta

	velocity.x = 0.0;
	if _can_move():
		velocity.x = direction * SPEED * SPEED_MOD * delta


func _ready() -> void:
	animated_sprite_2d.animation_finished.connect( _on_animation_finished );


func _on_animation_finished() -> void:
	match animated_sprite_2d.animation:
		"Attacking":
			flagState.Remove( Flags.Attacking );
			current_animation = ""
			attack_cooldown_timer = ATTACK_COOLDOWN_TIME;
			pass


func _update_collisions() -> void:
	var offset: float = 0.0;

	if flagState.Has( Flags.Attacking ):
		offset = ( -1 if animated_sprite_2d.flip_h else 1 ) * COLLISION_OFFSET_ATTACKING;

	collision_shape_2d.position.x = offset;


func _physics_process(delta: float) -> void:
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta;

	_update_input( delta );
	_update_coyote( delta );
	_handle_jump();
	_handle_attack();
	_handle_footsteps( delta );
	_update_flags();
	_update_movement( delta );
	_update_animations();
	_update_collisions();
	_update_particles();
	_handle_landing();
	move_and_slide()

	flagState.debug_print_update()
