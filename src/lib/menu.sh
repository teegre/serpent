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
# MENU
# C : 2022/03/05
# M : 2022/03/05
# D : Simple menu system

make_menu() {
  # display a simple menu and wait for user input.
  # return index of selected item.
  # 
  # usage: make_menu <layout> <y> <x> <item1> <item2> ... <itemN>
  #
  # layout: either "h" or "v"
  #
  # <h> <j> <k> <l> to navigate,
  # <space> to validate highlighted menu item.

  declare -a menuitems

  local opt oy ox my mx item idx
  local selected key

  opt=${1,,}; shift
  my=$1; shift
  mx=$1; shift
  ((oy=my)); ((ox=mx))
  selected=0

  if [[ $opt =~ ^v.*$ ]]; then
    vertical=1
  elif [[ $opt =~ ^h.*$ ]]; then
    vertical=0
  else
    echo "error: invalid layout."
    return 255
  fi

  for item in "$@"; do
    menuitems+=( "$item" )
  done

  local active=1

  while (( active == 1 )); do
    ((my=oy))
    ((mx=ox))

    for idx in "${!menuitems[@]}"; do
      item="${menuitems[$idx]}"
      set_color $((LEVELCOLOR))
      (( idx == selected )) && set_color 7
      lecho $((my)) $((mx)) " ${item} "

      (( vertical == 0 )) && ((mx+=${#item}+2))
      (( vertical == 1 )) && ((my++))

      set_color 0
    done

    read -rsN 1 key

    case $key in
      h  ) (( vertical == 0 )) && { playsnd move; ((selected--)); } ;;
      j  ) (( vertical == 1 )) && { playsnd move; ((selected++)); } ;;
      k  ) (( vertical == 1 )) && { playsnd move; ((selected--)); } ;;
      l  ) (( vertical == 0 )) && { playsnd move; ((selected++)); } ;;
      " ") active=0;
    esac

    ((selected=selected>${#menuitems[@]}-1?0:selected))
    ((selected=selected<0?${#menuitems[@]}-1:selected))

  done

  return $((selected))
}
