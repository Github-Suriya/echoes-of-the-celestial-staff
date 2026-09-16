class_name BossPerception
extends EnemyPerception

## BossPerception
## Specialized perception controller for boss encounters.
## Inherits EnemyPerception for full architectural reuse, adding BossData configuration support.

func configure_boss(data: BossData) -> void:
	if data == null:
		return
	detection_range = data.detection_range
	lose_target_range = data.detection_range * 1.5
	require_line_of_sight = false # Boss maintains awareness inside the sealed arena
