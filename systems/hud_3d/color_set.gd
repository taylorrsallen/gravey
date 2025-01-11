class_name ColorSet extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var primary: Color
@export var secondary: Color
@export var tertiary: Color
@export var background: Color

var _default_primary: Color
var _default_secondary: Color
var _default_tertiary: Color
var _default_background: Color

var _current_primary: Color
var _current_secondary: Color
var _current_tertiary: Color
var _current_background: Color

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_primary() -> Color: return _current_primary
func get_secondary() -> Color: return _current_secondary
func get_tertiary() -> Color: return _current_tertiary
func get_background() -> Color: return _current_background

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	_default_primary = primary
	_default_secondary = secondary
	_default_tertiary = tertiary
	_default_background = background

func reset() -> void:
	primary = _default_primary
	secondary = _default_secondary
	tertiary = _default_tertiary
	background = _default_background

func update(delta: float) -> void:
	_current_primary = _current_primary.lerp(primary, delta)
	_current_secondary = _current_secondary.lerp(secondary, delta)
	_current_tertiary = _current_tertiary.lerp(tertiary, delta)
	_current_background = _current_background.lerp(background, delta)
