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
# TITLE
# C : 2022/03/06
# M : 2022/03/06
# D : Title screen

init_title() {
  local map h w y line
  declare -a title
  
  map="${RESDIR}/title.info"

  mapfile title < "$map"

  ((h=${#title[@]}))
  ((w=${#title[0]}))

  set_level_offset $((h)) $((w))

  ((y=OFFY-2))

  ((LEVELCOLOR=COLORS[RANDOM%${#COLORS[@]}]))
  set_color $((LEVELCOLOR))

  clear

  for line in "${title[@]}"; do
    lecho $((y)) $((OFFX)) "$line"
    ((y++))
  done
  
  make_menu v $((OFFY+h-1)) $((OFFX+(w/2)-2)) " PLAY " "SINGLE" "RANDOM" " QUIT "
  case $? in
    0) start_level ;;
    1) clear; return 1 ;;
    2) clear; return 1 ;;
    3) clear; return 1 ;;
  esac

}

