extends Node

const C := {
	"black": "0d1014", "dark": "161c24", "panel": "1e2733", "line": "3c4a5c",
	"white": "f2f5f8", "gray": "9aa6b4", "dgray": "5a6674",
	"blue": "3f79d8", "cyan": "62c8ec", "red": "d84a3c", "dred": "8c2a22",
	"green": "58b04a", "lgreen": "7fd45a", "yellow": "f2c94c", "orange": "ee8b3a",
	"purple": "9a5fd0", "brown": "7a5230",
}

func c(n: String) -> Color:
	if C.has(n):
		return Color.html(C[n])
	return Color.MAGENTA

func team(t: int) -> Color:
	if t == 0:
		return c("cyan")
	return c("red")
