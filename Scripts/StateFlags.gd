class_name StateFlags

enum Flags
{
	None = 0,
	
	# Movement
	Idle      = 1 << 0,
	Running   = 1 << 1,
	Jumping   = 1 << 2,
	Falling   = 1 << 3,
	Attacking = 1 << 4,
};

const IN_AIR = Flags.Jumping | Flags.Falling;
const IN_ACTION = Flags.Running | Flags.Jumping | Flags.Falling | Flags.Attacking;

const FlagsPriority: Dictionary = {
	Flags.Idle: 0,
	Flags.Running: 1,
	Flags.Jumping: 2,
	Flags.Falling: 2,
	Flags.Attacking: 3,
}
