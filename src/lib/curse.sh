# shellcheck shell=bash

#  _______ _______ ______ ______ _______ _______ _______ 
# |     __|    ___|   __ \   __ \    ___|    |  |_     _|
# |__     |    ___|      <    __/    ___|       | |   |  
# |_______|_______|___|__|___|  |_______|__|____| |___|  
# 
# This file is part of Serpent.
# Copyright (C) 2022, Stéphane MEYER.
# 
# Serpent is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>
#
# CURSE
# C : 2022/02/21
# M : 2022/02/21
# D : 

# colors
COLORS=( 31 32 33 34 35 36 37 )
export COLORS

set_color() {
  local color
  color=$1
  printf '\e[%bm' "$color"
}

get_scr_size() {
  shopt -s checkwinsize; (:;:)
}

locate() {
  # move cursor position.
  local y x
  y="$1"; x="$2"
  printf '\e[%d;%dH' $((y)) $((x))
}

lecho() {
  # move cursor position and print text.
  local y x text
  y="$1"; x="$2"; text="$3"
  locate $((y)) $((x))
  printf "%b" "$text"
}

clrscr() {
  # clear the screen.
  printf '\e[2J\x1b[H'
}

clrtoeol() {
  # clear from current position to the end of the line.
  printf '\e[K'
}

clrtoeos() {
  # clear from current position to the end of the screen.
  printf '\e[0J'
}

clrline() {
  # clear line at current position.
  printf '\e[2K'
}

hidecursor() {
  # hide cursor.
  printf '\e[?25l'
}

showcursor() {
  # show cursor.
  printf '\e[?25h'
}

savecursor() {
  # save cursor position.
  printf '\e[s'
}

restorecursor() {
  # restore previously saved cursor position.
  printf '\e[u'
}

