class_name TCBackground
extends CanvasLayer

# ── CONFIG ────────────────────────────────────────────────────────────────────
const TC_SCROLL_SPEED  := 18.0
const TC_FONT_SIZE     := 11
const TC_LINE_HEIGHT   := 14
const TC_COLUMN_COUNT  := 3
const TC_TEXT_COLOR    := Color(0.72, 0.72, 0.78, 0.55)
const TC_BG_COLOR      := Color(0.96, 0.96, 0.98, 1.0)

const TC_LINES := [
	"1. ACCEPTANCE OF TERMS",
	"By accessing or using this Service, you agree to be bound by these Terms and Conditions.",
	"If you do not agree to all terms herein, you must immediately cease all use of this Service.",
	"2. GRANT OF LICENSE",
	"Subject to your compliance, we grant you a limited, non-exclusive, non-transferable,",
	"revocable license to access and use the Service solely for your personal, non-commercial use.",
	"3. DATA COLLECTION AND PRIVACY",
	"We collect information you provide directly, including but not limited to: name, email address,",
	"device identifiers, IP addresses, location data, biometric data, usage patterns,",
	"behavioral analytics, and any content you generate, transmit, or store through the Service.",
	"4. SHARING OF PERSONAL DATA",
	"We may share your personal information with third-party partners, affiliates, advertisers,",
	"data brokers, government agencies upon lawful request, and any entity we deem appropriate.",
	"5. MODIFICATIONS TO SERVICE",
	"We reserve the right to modify, suspend, or discontinue the Service at any time without notice.",
	"Your continued use following any modification constitutes acceptance of the new Terms.",
	"6. LIMITATION OF LIABILITY",
	"To the fullest extent permitted by applicable law, in no event shall we be liable for any",
	"indirect, incidental, special, exemplary, consequential, or punitive damages whatsoever.",
	"7. INDEMNIFICATION",
	"You agree to defend, indemnify, and hold harmless the Company and its officers, directors,",
	"employees, and agents from any claims, liabilities, damages, losses, and expenses arising",
	"out of or in any way connected with your access to or use of the Service.",
	"8. ARBITRATION AGREEMENT",
	"Any dispute arising out of or relating to these Terms shall be resolved by binding arbitration.",
	"You waive your right to a jury trial and to participate in any class action lawsuit.",
	"9. AUTO-RENEWAL CLAUSE",
	"Your subscription will automatically renew at the end of each billing cycle unless cancelled",
	"at least 30 days prior to the renewal date via certified mail to our registered office.",
	"10. GOVERNING LAW",
	"These Terms shall be governed by and construed in accordance with the laws of the jurisdiction",
	"in which the Company is incorporated, without regard to conflict of law provisions.",
	"11. INTELLECTUAL PROPERTY",
	"All content, trademarks, logos, and data on this Service are the exclusive property of",
	"the Company and may not be reproduced without express written permission.",
	"12. TERMINATION",
	"We may terminate or suspend your account immediately, without prior notice or liability,",
	"for any reason whatsoever, including without limitation if you breach these Terms.",
	"13. COOKIE POLICY",
	"We use cookies and similar tracking technologies to track activity on our Service.",
	"By continuing to use the Service, you consent to our use of all cookie categories.",
	"14. THIRD PARTY LINKS",
	"The Service may contain links to third-party websites. We have no control over and assume",
	"no responsibility for the content, privacy policies, or practices of any third-party sites.",
	"15. ENTIRE AGREEMENT",
	"These Terms constitute the entire agreement between you and the Company regarding the Service",
	"and supersede all prior agreements, representations, and understandings of any kind.",
	"Last updated: See footer. Version 47.3.1-rc2. Subject to change without notice.",
	"© All rights reserved. Unauthorized reproduction prohibited. Void where restricted.",
	"This document contains 14,892 words. Estimated reading time: 2 hours 17 minutes.",
	"By clicking any button you confirm you have read and understood all terms herein.",
]

# ── INTERNAL STATE ────────────────────────────────────────────────────────────
var _control  : Control
var _columns  : Array = []

# ── SETUP ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = -1  # always behind everything

	_control = Control.new()
	_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_control.draw.connect(_draw_tc)
	add_child(_control)

	var vp     := get_viewport().get_visible_rect().size
	var needed := int(vp.y / TC_LINE_HEIGHT) + 60

	for c in range(TC_COLUMN_COUNT):
		var col_lines : Array = []
		for i in range(needed):
			col_lines.append(TC_LINES[i % TC_LINES.size()])
		_columns.append({
			"lines":    col_lines,
			"y_offset": randf_range(0.0, vp.y),
			"speed":    TC_SCROLL_SPEED * randf_range(0.7, 1.3),
		})

# ── DRAW ──────────────────────────────────────────────────────────────────────
func _draw_tc() -> void:
	if _control == null:
		return
	var vp        := get_viewport().get_visible_rect().size
	var font      := ThemeDB.fallback_font
	var col_width := vp.x / TC_COLUMN_COUNT

	_control.draw_rect(Rect2(Vector2.ZERO, vp), TC_BG_COLOR)

	for c in range(_columns.size()):
		var col    = _columns[c]
		var x_base := c * col_width + 8.0
		var y_start : float = -col["y_offset"]

		for i in range(col["lines"].size()):
			var y := y_start + i * TC_LINE_HEIGHT
			if y > vp.y + TC_LINE_HEIGHT: break
			if y < -TC_LINE_HEIGHT:       continue

			var line  : String = col["lines"][i]
			var color := TC_TEXT_COLOR
			if line.length() > 0 and line[0].is_valid_int() and line.contains("."):
				color = Color(0.35, 0.35, 0.55, 0.75)

			_control.draw_string(font, Vector2(x_base, y), line,
				HORIZONTAL_ALIGNMENT_LEFT, col_width - 16.0, TC_FONT_SIZE, color)

		if c > 0:
			_control.draw_line(
				Vector2(c * col_width, 0), Vector2(c * col_width, vp.y),
				Color(0.75, 0.75, 0.82, 0.4), 1.0
			)

# ── PROCESS ───────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	for col in _columns:
		col["y_offset"] += col["speed"] * delta
		var total_height : float = col["lines"].size() * TC_LINE_HEIGHT
		if col["y_offset"] >= total_height:
			col["y_offset"] -= total_height
	_control.queue_redraw()