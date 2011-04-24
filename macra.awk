#!/usr/bin/nawk -f
#
# Macra - general purpose macro preprocessor
# 
# Copyright (C) 2011 aike. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in
#      the documentation and/or other materials provided with the
#      distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# History:
# 2011-04-03
#   First version.
# 

BEGIN {
	SingleLine = 0
	MultiLine = 1
	OutFlag = 0

	LibPath = "C:\\lib\\macra\\"

	# constants for IF_DEF directive
	CondNone = 0
	CondShow = 1
	CondMask = 2
	CondSP = 0
	IfdefCondition[CondSP] = CondNone

	# -D option
	argc = ARGC
	for (i = 0; i < argc; i++) {
		if (ARGV[i] ~ /^-D[a-zA-Z0-9_]+$/) {
			v = ARGV[i]
			gsub(/^-D/, "", v)
			gHash[v] = ""
			ARGC--
		}
	}
}

{ eval($0) }


function shift(arr, i, size, endregx,       j) {
	for (j = i + 1; j <= size; j++) {
		arr[i] = arr[i] " " arr[j]
		if (match(arr[j], endregx)) {
			break
		}
	}
	i++
	j++
	while (j <= size) {
		arr[i++] = arr[j++]
	}
	return i - 1
}

function split2(str, arr,        fields, i) {
	fields = split(str, arr)
	for (i = 1; i <= fields; i++) {

		if ((arr[i] == "\"") || (match(arr[i], /^".*[^"]$/))) {
			fields = shift(arr, i, fields, "\"$")
		}

		if ((arr[i] == "(") || (match(arr[i], /^\(.*[^\)]$/))) {
			fields = shift(arr, i, fields, "\\)$")
		}
	}

	return fields
}

function eval(line,      token, s, pushedfile) {

	num_fields = split2(line, token)

	# comment character
	if (token[1] ~ /^#.*/) {
		# do nothing
	}

	# IF_DEF directive
	else if (token[1] == "IF_DEF") {
		CondSP += 1
		if (token[2] in gHash) {
			IfdefCondition[CondSP] = CondShow
		} else {
			IfdefCondition[CondSP] = CondMask
		}
	}

	# IF_NOT_DEF directive
	else if (token[1] == "IF_NOT_DEF") {
		CondSP += 1
		if (token[2] in gHash) {
			IfdefCondition[CondSP] = CondMask
		} else {
			IfdefCondition[CondSP] = CondShow
		}
	}

	# ELSE directive
	else if ((IfdefCondition[CondSP] == CondShow) && (token[1] == "ELSE")) {
		IfdefCondition[CondSP] = CondMask
	}

	else if ((IfdefCondition[CondSP] == CondMask) && (token[1] == "ELSE")) {
		IfdefCondition[CondSP] = CondShow
	}

	# END_IF directive
	else if  (token[1] == "END_IF") {
		CondSP -= 1
	}

	else if (IfdefCondition[CondSP] == CondMask) {
		# do nothing
	}


	# macro definition
	else if (token[1] == "defmacro") {
		if (num_fields > 2) {
			# one line macro
			s = token[3]
			for (i = 4; i <= num_fields; i++)
				s = s " " token[i]
			gType[token[2]] = SingleLine
		} else {
			# multi line macro
			s = ""
			while (getline2() > 0) {
				if (gLineBuffer ~ /endmacro/) break
				s = s "\n" gLineBuffer
			}
			gsub(/^\n/, "", s)
			gType[token[2]] = MultiLine
		}
		gHash[token[2]] = s
	}

	# macro expansion
	else if (token[1] in gHash) {
		if (gType[token[1]] == SingleLine) {
			s = line
			gsub(/[^ 	].+$/, "", s)
			printf("%s", s)
		}
		s = gHash[token[1]]
		gsub(/&1/, token[2], s)
		gsub(/&2/, token[3], s)
		gsub(/&3/, token[4], s)
		gsub(/&4/, token[5], s)
		gsub(/&5/, token[6], s)
		gsub(/&6/, token[7], s)
		gsub(/&7/, token[8], s)
		gsub(/&8/, token[9], s)
		evalLines(s)
	}

	# include directive
	else if (token[1] == "include") {
		pushedfile = gCurrentFile
		gCurrentFile = token[2]
		if (substr(gCurrentFile, 1, 1) == "<") {
			gsub(/</, "", gCurrentFile)
			gsub(/>/, "", gCurrentFile)
			gCurrentFile = LibPath gCurrentFile
		} else {
			gsub(/"/, "", gCurrentFile)
		}
		while (getline2() > 0) {
			eval(gLineBuffer)
		}
		close(gCurrentFile)
		gCurrentFile = pushedfile
	}

	# normal line
	else {
		if ((line != "") || (OutFlag == 1)) {

			# inline macro expansion
			while (match(line, /\$\([a-zA-Z0-9_#]+\)/) > 0) {
				left  = substr(line, 1, RSTART - 1)
				right = substr(line, RSTART + RLENGTH)
				key   = substr(line, RSTART + 2, RLENGTH - 3)
				if (key in gHash) {
					line = left gHash[key] right
				} else {
					line = left "#ERROR[" key "]#" right
				}
			}

			printf("%s\n", line)
			OutFlag = 1
		}
	}
}

function getline2() {
	if (gCurrentFile == "") {
		return getline gLineBuffer
	} else {
		return getline gLineBuffer < gCurrentFile
	}
}

function evalLines(lines,	  line, n, i) {
	n = split(lines, line, "\n")
	for (i = 1; i <= n; i++) {
		eval(line[i])
	}
}

###############################

