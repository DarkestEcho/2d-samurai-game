extends Node

class_name FlagStateManager

var _flags: int = StateFlags.Flags.None;

func Add( mask: int ) -> void:
	_flags |= mask;

func Remove( mask: int ) -> void:
	_flags &= ~mask

func Toggle( mask: int ) -> void:
	_flags ^= mask

func Has( mask: int ) -> bool:
	return ( _flags & mask ) == mask;

func HasAny( mask: int ) -> bool:
	return ( _flags & mask ) != 0;

func HasNone( mask: int ) -> bool:
	return ( _flags & mask ) == 0;

func Clear() -> void:
	_flags = StateFlags.Flags.None;

func GetFlags() -> int:
	return _flags;

func GetActiveFlagNames() -> Array[String]:
	var result: Array[String] = []
	for flag_name in StateFlags.Flags.keys():
		var flag_value = StateFlags.Flags[flag_name]
		if flag_value != 0 and Has(flag_value):
			result.append(flag_name)
	return result;
