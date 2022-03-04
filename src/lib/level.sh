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
# LEVEL
# C : 2022/02/28
# M : 2022/03/03
# D : 

LEVELDIR="$HOME/projets/serpent/levels"
TIPFILE="$HOME/projets/serpent/res/tips.info"

# tips
declare -a TIPS

# level number
declare -i LEVEL; LEVEL=1

declare -i OFFY # y offset | for centering level
declare -i OFFX # x offset | on the screen

# 8 bits mask for unpacking coordinates
declare -i MASK
export MASK
(( MASK=~(~0 << 8) ))

set_level_offset() {
  local height width
  
  height=$1
  width=$2

  get_scr_size
  ((OFFY=(LINES-height)/2))
  ((OFFX=(COLUMNS-width)/2))
  unset LINES COLUMNS
}

init_tips() {
  [[ -s $TIPFILE ]] || { NOTIPS=1; return 1; }
  mapfile -t TIPS < "$TIPFILE"
}

get_random_tip() {
  echo "${TIPS[RANDOM%${#TIPS[@]}]}"
}

get_tip() {
  local idx=$1
  ((idx >= 0 && idx < ${#TIPS[idx]}-1)) &&
    echo "${TIPS[idx]}"
}

read_level_info() {
  # level info:
  # direction = [ left <right> up down ]
  # spawn = [ <random> fixed ]
  # target = 30 or more
  # survival = [ yes <no> ]

  local f

  f="${LEVELDIR}/level_${LEVEL}.info"

  [[ -s ${f} ]] || {
    # use default values if no file is present
    export DIRECTION="right"
    export SPAWN="random"
    export TARGET=30
    return 1
  }

  local line param value
  while read -r line; do
    [[ $line =~ [[:space:]]*(.+)[[:space:]]*=[[:space:]]*(.+)$ ]] && {

      param="${BASH_REMATCH[1],,}"
      value="${BASH_REMATCH[2]}"

      case $param in
        direction ) export DIRECTION="${value,,}";;
        spawn     ) export SPAWN="${value,,}"    ;;
        target    ) export TARGET="${value}"   ;;
        head      ) export SH="${value}"       ;;
        tail_left ) export STL="${value}"      ;;
        tail_right) export STR="${value}"      ;;
        tail_up   ) export STU="${value}"      ;;
        tail_down ) export STD="${value}"      ;;
      esac
    }
  done < "$f"

  return 0
}

init_level() {
  local h w
  local board
  local y x line char
  local color

  unset POS SNAKEPOS APPLEPOS WALLPOS

  # coordinates TY TX BY BX SY SX EY EX
  declare -gA POS

  # arrays containing packed coordinates.
  declare -ga SNAKEPOS
  declare -ga APPLEPOS
  declare -ga WALLPOS

  local map
  map="${LEVELDIR}/level_${LEVEL}.map"

  [[ -s $map ]] || return 1

  mapfile board < "$map"
  read_level_info || return 1

  # level height and width
  ((h=${#board[@]}))
  ((w=${#board[0]}))

  set_level_offset $((h)) $((w))

  local color
  color=$((COLORS[RANDOM%${#COLORS[@]}]))
  line="$(set_color $color)"

  # board coordinates
  for y in "${!board[@]}"; do

    for ((x=0; x<${#board[$y]}; x++)); do

      char="${board[$y]:$x:1}"

      [[ $char =~ [A-Z0-9] ]] || {
        line+="$char"
        continue
      }

      # T top left
      # B bottom right
      # S snake
      # 1-9 apple (can be >1 )
      # W wall brick (can be >1)
      # E level exit

      # apples and walls
      case $char in
        [1-9])
           ((color=COLORS[RANDOM%${#COLORS[@]}]))
           # packing values in  26 bits
           # 8       8       6     4
           # YYYYYYYYXXXXXXXXCCCCCCVVVV
           # YYYYYYYY000000000000000000
           # 20
           # 00000000XXXXXXXX0000000000
           #         12
           # 0000000000000000CCCCCC0000
           #                 4
           # 0000000000000000000000VVVV
           
           APPLEPOS+=( $(( ((y+OFFY) << 20) | ((x+OFFX) << 12) | (color << 4) | char )) )
           line+="\e[${color}m\e[7m${char}\e[0m"
           ;;
        W) 
           WALLPOS+=( $(( ((y+OFFY) << 8) | (x+OFFX) )) )
           line+="#"
           ;;
        E)
           POS[EY]=$((y+OFFY))
           POS[EX]=$((x+OFFX))
           ((color=COLORS[RANDOM%${#COLORS[@]}]))
           line+="\e[${color}m\e[7mE\e[0m"
           ;;
        *) 
           POS["$char"Y]=$((y+OFFY))
           POS["$char"X]=$((x+OFFX))
           line+=" "
      esac
    done

    # display line
    lecho $((y+OFFY)) $((OFFX)) "$line"
    line="$(set_color $color)"

  done

  set_color 0

  # pack snake initial position
  local i
  for ((i=0; i<SNAKELEN; i++)); do
    SNAKEPOS+=( $(( (POS[SY] << 8) | (POS[SX]+i) )) )
  done

  (( ${#APPLEPOS[@]} == 0 )) && random_target

  return 0

}

display_header() {
  # display level number, remaining lives and score
  # on the game screen.

  local score_msg lives_msg
  score_msg="SCORE: ${SCORE}"
  lives_msg="☻ × $LIFE"

  lecho $((POS[TY]-2)) $((POS[TX])) "LEVEL $LEVEL "
  lecho $((POS[TY]-2)) $((POS[BX]-${#score_msg})) " $score_msg "
  lecho $((POS[TY]-2)) $((((OFFX+POS[BX])/2)-${#lives_msg})) " $lives_msg "
  lecho $((POS[BY]+2)) $((OFFX)) "$STATE"
}

display_level_intro() {
  # display level
  local level_msg lives_msg

  level_msg=" LEVEL $LEVEL "
  lives_msg="☻ × $LIFE"

  local y x color

  get_scr_size
  ((y=(LINES/2)-1))
  ((x=(COLUMNS-${#level_msg})/2))
  ((color=COLORS[RANDOM%${#COLORS[@]}]))
  set_color $color
  set_color 7
  lecho $((y)) $((x)) "$level_msg"
  set_color 0
  # ((color=COLORS[RANDOM%${#COLORS[@]}]))
  set_color $color
  ((x=(COLUMNS-${#lives_msg})/2))
  lecho $((y+1)) $((x)) "$lives_msg"
  [[ $NOTIPS ]] || {
    local tip
    tip="$(get_random_tip)"
    ((x=(COLUMNS-${#tip})/2))
    lecho $((y+4)) $((x)) "$tip"
  }
  set_color 0
  playsnd level
}
