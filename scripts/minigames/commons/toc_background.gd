class_name TCBackground
extends CanvasLayer

const SCROLL_SPEED   := 20.0
const FONT_SIZE      := 11
const LINE_HEIGHT    := 14
const COLUMN_COUNT   := 4
const BG_COLOR       := Color(0.039, 0.047, 0.063, 1.0)

# Different text categories with different colors/opacity
const COLOR_CYAN_DIM  := Color(0.0,  0.831, 1.0,   0.10)
const COLOR_CYAN_MID  := Color(0.0,  0.831, 1.0,   0.20)
const COLOR_GREEN_DIM := Color(0.0,  1.0,   0.533, 0.10)
const COLOR_GREEN_MID := Color(0.0,  1.0,   0.533, 0.18)
const COLOR_RED_DIM   := Color(0.9,  0.2,   0.1,   0.12)
const COLOR_AMBER_DIM := Color(1.0,  0.67,  0.0,   0.10)
const COLOR_MUTED     := Color(0.29, 0.353, 0.439, 0.08)
const DIVIDER_COLOR   := Color(0.118, 0.137, 0.176, 0.3)

const LINES := [
	# System boot / status
	"CODERAGE_OS_V.4.2 — BOOT SEQUENCE INITIATED",
	"[OK] NEURAL_BRIDGE_DRIVER............LOADED",
	"[OK] BIOMETRIC_SCANNER...............ACTIVE",
	"[OK] MEMORY_SIPHON_MODULE............RUNNING",
	"[OK] IDENTITY_VAULT..................ONLINE",
	"[!!] CONSENT_MODULE..................BYPASSED",
	"[OK] DATA_EXFIL_DAEMON...............RUNNING",
	"[OK] PANOPTICON_LINK.................STABLE",
	"[!!] FIREWALL........................DISABLED",
	"[OK] ENCRYPTION_LAYER................NOMINAL",
	"",
	# Hex / data streams
	"0x4F3A 0xC2B1 0x7E90 0xA3F4 0x1D88 0x5C2E",
	"0xBEEF 0xDEAD 0x0000 0xFFFF 0x1337 0xC0DE",
	"0x9A2C 0x4411 0x7700 0x8823 0xAA01 0x3F9E",
	"0x0D0A 0x0D0A 0x4745 0x5420 0x2F20 0x4854",
	"",
	# Neural / biometric logs
	"> NEURAL_SYNC: SUBJECT_ID_4401X — LATENCY: 2ms",
	"> BIO_SCAN: RETINAL_MATCH_CONFIRMED",
	"> UPLINK_STRENGTH: 94% — SIGNAL: CLEAN",
	"> MEMORY_CACHE: 14.2GB EXTRACTED",
	"> LOCATION_PING: SECTOR_G_FACILITY",
	"> BEHAVIORAL_PROFILE: UPDATED",
	"> COMPLIANCE_SCORE: 0.91 — THRESHOLD: 0.85",
	"> ANOMALY_DETECTED: COGNITIVE_RESISTANCE",
	"> SUPPRESSION_PROTOCOL: ENGAGED",
	"> CHK_SYNC: OK",
	"> VOL_MAP: 44.2%",
	"> BIO_FLX: STABLE",
	"> ERR_OVR: 0x004F",
	"",
	# Error / warning logs
	"ERR_BIOMETRIC_MISMATCH — RETRYING...",
	"ERR_OVERFLOW: 0x004F — CONTAINMENT: ACTIVE",
	"WARN: SUBJECT_RESISTANCE > THRESHOLD",
	"ERR_NEURAL_DESYNC — FALLBACK_MODE: ON",
	"CRITICAL: IDENTITY_PURGE_QUEUED",
	"WARN: DATA_SIPHON_RATE_EXCEEDED",
	"",
	# Panopticon / surveillance
	"PANOPTICON_NODE_042: ONLINE",
	"SURVEILLANCE_GRID: 100% COVERAGE",
	"FACIAL_RECOGNITION: MATCH_FOUND",
	"GAIT_ANALYSIS: SUBJECT_TRACKED",
	"AUDIO_INTERCEPT: CHANNEL_OPEN",
	"SOCIAL_GRAPH_MAPPED: 2,847 NODES",
	"PURCHASE_PREDICTION: 94.3% ACCURACY",
	"POLITICAL_PROFILE: CLASSIFIED",
	"",
	# Compliance / protocol
	"PROTOCOL_09B: IDENTITY_LOCK — ACTIVE",
	"COMPLIANCE_MODULE: RUNNING",
	"CONSENT_OVERRIDE: CLAUSE_7.3_APPLIED",
	"ARBITRATION_WAIVER: SIGNED_BY_DEFAULT",
	"CLASS_ACTION_BLOCK: ENFORCED",
	"DATA_RETENTION: INDEFINITE",
	"RIGHT_TO_DELETE: SUSPENDED",
	"GDPR_EXCEPTION: INVOKED",
	"",
	# Server / infra noise
	"SRV_NODE_12: PING 3ms — LOAD 88%",
	"SRV_NODE_07: PING 1ms — LOAD 14%",
	"SRV_NODE_31: OVERLOAD — REROUTING",
	"CLUSTER_A9: REPLICATION_LAG: 0.2s",
	"DB_WRITE: 4,201 RECORDS — OK",
	"CACHE_HIT: 97.8% — OPTIMAL",
	"CDN_NODE_US_EAST: LATENCY 1ms",
	"CDN_NODE_EU_WEST: LATENCY 12ms",
	"",
	# Timestamps
	"[2024-11-04 04:22:19] SYS — BOOT_COMPLETE",
	"[2024-11-04 04:22:20] AUTH — SESSION_OPEN",
	"[2024-11-04 04:22:21] NET — UPLINK_STABLE",
	"[2024-11-04 04:22:22] MON — SUBJECT_ONLINE",
	"[2024-11-04 04:22:44] EXF — DATA_TRANSFER_OK",
	"[2024-11-04 04:22:58] SEC — FIREWALL_BYPASSED",
	"[2024-11-04 04:23:01] PSY — COMPLIANCE_ENFORCED",
]

var _control : Control
var _columns : Array = []

func _ready() -> void:
	layer = -1
	_control = Control.new()
	_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control.draw.connect(_draw_bg)
	add_child(_control)

	var vp     := get_viewport().get_visible_rect().size
	var needed := int(vp.y / LINE_HEIGHT) + 80

	for c in range(COLUMN_COUNT):
		var col_lines : Array = []
		for i in range(needed):
			col_lines.append(LINES[i % LINES.size()])
		_columns.append({
			"lines":    col_lines,
			"y_offset": randf_range(0.0, vp.y),
			"speed":    SCROLL_SPEED * randf_range(0.6, 1.4),
		})

func _draw_bg() -> void:
	if _control == null:
		return
	var vp        := get_viewport().get_visible_rect().size
	var font      := ThemeDB.fallback_font
	var col_width := vp.x / COLUMN_COUNT

	_control.draw_rect(Rect2(Vector2.ZERO, vp), BG_COLOR)

	for c in range(_columns.size()):
		var col    = _columns[c]
		var x_base := c * col_width + 10.0
		var y_start : float = -col["y_offset"]

		for i in range(col["lines"].size()):
			var y := y_start + i * LINE_HEIGHT
			if y > vp.y + LINE_HEIGHT: break
			if y < -LINE_HEIGHT:       continue

			var line  : String = col["lines"][i]
			if line.is_empty():
				continue

			# Color based on line content
			var color : Color
			if line.begins_with("[OK]"):
				color = COLOR_GREEN_DIM
			elif line.begins_with("[!!]") or line.begins_with("CRITICAL") or line.begins_with("ERR_"):
				color = COLOR_RED_DIM
			elif line.begins_with("WARN:"):
				color = COLOR_AMBER_DIM
			elif line.begins_with(">"):
				color = COLOR_CYAN_MID
			elif line.begins_with("0x"):
				color = COLOR_CYAN_DIM
			elif line.begins_with("[20"):
				color = COLOR_MUTED
			elif line.begins_with("CODERAGE") or line.begins_with("PANOPTICON") or line.begins_with("PROTOCOL"):
				color = COLOR_CYAN_MID
			else:
				color = COLOR_MUTED

			_control.draw_string(font, Vector2(x_base, y), line,
				HORIZONTAL_ALIGNMENT_LEFT, col_width - 16.0, FONT_SIZE, color)

		if c > 0:
			_control.draw_line(
				Vector2(c * col_width, 0),
				Vector2(c * col_width, vp.y),
				DIVIDER_COLOR, 1.0
			)

func _process(delta: float) -> void:
	for col in _columns:
		col["y_offset"] += col["speed"] * delta
		var total_height : float = col["lines"].size() * LINE_HEIGHT
		if col["y_offset"] >= total_height:
			col["y_offset"] -= total_height
	_control.queue_redraw()