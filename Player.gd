extends RigidBody3D

# Sensibilidad del ratón para rotación
var mouse_sensitivity := 0.001
# Entrada de rotación en el eje Y (torsión)
var twist_input := 0.0
# Entrada de rotación en el eje X (inclinación)
var pitch_input := 0.0
# Distancia de movimiento por cada paso de cuadrícula
var grid_size := 1.0
# Indica si el jugador está en movimiento
var is_moving := false

# Referencia al nodo TwistPivot
@onready var twist_pivot := $TwistPivot
# Referencia al nodo PitchPivot
@onready var pitch_pivot := $TwistPivot/PitchPivot
# Referencia al timer
@onready var move_timer := $MoveTimer

# Llamado cuando el nodo entra en el árbol de la escena por primera vez.
func _ready() -> void:
	# Configura el modo del ratón para que esté capturado (oculto y confinado a la ventana)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Llamado cada fotograma. 'delta' es el tiempo transcurrido desde el fotograma anterior.
func _process(delta) -> void:
	# Funcion que maneja el movimiento 3D
	handle3DMovement(delta);
	#if not is_moving:
		#handle_grid_movement(delta)
	# Funcion que maneja el movimiento de la camara alrrededor del player
	handleCameraMovement();
	
# Llamado cuando hay entrada que no ha sido manejada (como movimiento del ratón)
func _unhandled_input(event: InputEvent) -> void:
	# Si el evento es movimiento del ratón
	if event is InputEventMouseMotion:
		# Si el ratón está capturado (modo de entrada activo)
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# Ajusta la entrada de torsión e inclinación basándose en el movimiento relativo del ratón
			twist_input = - event.relative.x * mouse_sensitivity
			pitch_input = - event.relative.y * mouse_sensitivity

func handle3DMovement(delta) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	# Aplica una fuerza central al RigidBody en base a la entrada del usuario
	apply_central_force(twist_pivot.basis * input * 1200.0 * delta)

func handleCameraMovement() -> void:
	# Si se presiona la acción de cancelar (usualmente la tecla 'Esc')
	if Input.is_action_just_pressed("ui_cancel"):
		# Cambia el modo del ratón a visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	# Rota el nodo TwistPivot en el eje Y (torsión)
	twist_pivot.rotate_y(twist_input)
	# Rota el nodo PitchPivot en el eje X (inclinación)
	pitch_pivot.rotate_x(pitch_input)
	# Limita la rotación en el eje X de PitchPivot para evitar giros excesivos
	pitch_pivot.rotation.x = clamp(
		pitch_pivot.rotation.x,
		-0.5,
		0.5
	)
	# Reinicia las entradas de rotación para el siguiente fotograma
	twist_input = 0.0
	pitch_input = 0.0

func handle_grid_movement(delta) -> void:
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_back")
	
	if input != Vector3.ZERO and not is_moving:
		# Normalizar y escalar el input por el tamaño de la cuadrícula
		input = input.normalized() * grid_size
		var force = twist_pivot.basis * input * 10 # Incrementar el factor de fuerza
		
		# Aplicar la fuerza al objeto
		apply_central_impulse(force)
		
		# Iniciar el cooldown
		is_moving = true
		await get_tree().create_timer(0.2).timeout # Reducir el tiempo de cooldown
		is_moving = false


