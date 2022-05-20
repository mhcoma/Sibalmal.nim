#? replace(sub="\t", by=" ")

import deques
import math
import std/strutils

type Interpreter = object
	func_index: int
	code_index: int
	storage_index: int
	loop_level: int
	loop_skip: bool
	codes: seq[string]
	loop_index: Deque[int]
	storage: array[26, Deque[float]]

proc open(inter: var Interpreter, filename: string) =
	var file: File
	var line: string

	try:
		file = open("test.sibalmal", fmRead)
		while file.readLine(line):
			inter.codes.add(line)
		inter.func_index = 0
		inter.code_index = 0
		inter.storage_index = 0
		inter.loop_level = 0
		inter.loop_skip = false
	except IOError as e:
		echo "I/O error: " & e.msg

template curr_storage(inter: var Interpreter): Deque[float] =
	inter.storage[inter.storage_index]

template c_front(inter: var Interpreter): float =
	inter.curr_storage.peekFirst

template c_push(inter: var Interpreter, v: float) =
	inter.curr_storage.addFirst(v)

template c_pop(inter: var Interpreter) =
	inter.curr_storage.popFirst

template c_not_empty(inter: var Interpreter): bool =
	inter.curr_storage.len > 0

template c_has_two(inter: var Interpreter): bool =
	inter.curr_storage.len > 1

proc interprete(inter: var Interpreter): bool =
	if inter.code_index >= inter.codes[inter.func_index].len:
		return false
	let code = ord(inter.codes[inter.func_index][inter.code_index])

	# echo inter.code_index, ", ", inter.codes[inter.func_index].len, ", ", chr(code)

	
	if inter.loop_skip:
		inc(inter.code_index)
		if code == ord('\\'):
			if inter.loop_level == inter.loop_index.len:
				inter.loop_skip = false
			else: dec(inter.loop_level)
		elif code == ord('?'):
			inc(inter.loop_level)
		return true

	if code >= ord('a') and code <= ord('z'):
		inter.storage_index = code - 97
	elif code >= ord('A') and code <= ord('Z'):
		if inter.c_not_empty:
			inter.storage[code - 65].addFirst(inter.c_pop)
	elif code >= ord('0') and code <= ord('9'):
		inter.c_push(float(code - 48))
	else:
		case code
		of ord(':'):
			if inter.c_not_empty:
				inter.c_push(inter.c_front)
		of ord(';'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(b)
				inter.c_push(a)
		of ord('.'):
			if inter.c_has_two:
				inter.c_push(inter.curr_storage.popLast)
		of ord(','):
			if inter.c_has_two:
				inter.curr_storage.addLast(inter.c_pop)
		of ord('+'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(a + b)
		of ord('-'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(a - b)
		of ord('*'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(a * b)
		of ord('/'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(a / b)
		of ord('%'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(a mod b)
		of ord('='):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(float(a == b))
		of ord('>'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(float(a > b))
		of ord('<'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(float(a < b))
		of ord('&'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(float(bool(a) and bool(b)))
		of ord('|'):
			if inter.c_has_two:
				let b = inter.c_pop
				let a = inter.c_pop
				inter.c_push(float(bool(a) or bool(b)))
		of ord('~'):
			if inter.c_not_empty:
				inter.c_push(float(not bool(inter.c_pop)))
		of ord('#'):
			if inter.c_not_empty:
				stdout.write int(inter.c_pop)
		of ord('^'):
			if inter.c_not_empty:
				stdout.write inter.c_pop
		of ord('@'):
			if inter.c_not_empty:
				stdout.write char(int(inter.c_pop))
		of ord(' '):
			if inter.c_not_empty:
				inter.c_pop
		of ord('`'):
			inter.c_push(parseFloat(readLine(stdin)))
		of ord('\''):
			inter.c_push(float(int(readChar(stdin))))
		of ord('\"'):
			let line_end = int(inter.c_pop)
			var temp_deque: Deque[float]
			if line_end == 0:
				for i in readLine(stdin):
					temp_deque.addFirst(float(ord(i)))
			else:
				var temp_end = true
				while temp_end:
					for i in readLine(stdin):
						if line_end == ord(i):
							temp_end = false
							break
						temp_deque.addFirst(float(ord(i)))
			for i in temp_deque:
				inter.c_push(i)
		of ord('?'):
			if inter.c_not_empty:
				if (bool(inter.c_pop)):
					inter.loop_index.addFirst(inter.code_index - 1)
					inc(inter.loop_level)
				else:
					inter.loop_skip = true
			else:
				inter.loop_skip = true
		of ord('\\'):
			inter.code_index = inter.loop_index.popFirst
			dec(inter.loop_level)
		of ord('!'):
			inter.loop_skip = true
		else:
			discard
	inc(inter.code_index)
	return true

proc loop(inter: var Interpreter) =
	while true:
		if not inter.interprete:
			break

var s: Interpreter

s.open("test.sibalmal")
s.loop
