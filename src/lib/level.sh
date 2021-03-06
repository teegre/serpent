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
# M : 2022/03/12
# D : Level display and related functions.

LEVELDIR="$HOME/.local/share/serpent/res/levels"
TIPFILE="$HOME/.local/share/serpent/res/tips.info"

# tips
declare -a TIPS

# level number
declare -i LEVEL; LEVEL=1

declare -i LEVELCOLOR

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
    export SHL="◀" # snake head pointing left
    export SHR="▶" # snake head pointing right
    export SHU="▲" # snake head pointing up
    export SHD="▼" # snake head pointing down
    export ST="O"
    return 1
  }

  local line param value
  while read -r line; do
    [[ $line =~ [[:space:]]*(.+)*[[:space:]]*=[[:space:]]*(.+)$ ]] && {

      param="${BASH_REMATCH[1],,}"
      value="${BASH_REMATCH[2]}"

      case $param in
        direction ) export DIRECTION="${value,,}";;
        spawn     ) export SPAWN="${value,,}"    ;;
        target    ) export TARGET="${value}"   ;;
        head_left ) export SHL="${value}"      ;;
        head_right) export SHR="${value}"      ;;
        head_up   ) export SHU="${value}"      ;;
        head_down ) export SHD="${value}"      ;;
        tail      ) export ST="${value}"       ;;
      esac
    }
  done < "$f"

  SHL="${SHL:-"◀"}"
  SHR="${SHR:-"▶"}"
  SHU="${SHU:-"▲"}"
  SHD="${SHD:-"▼"}"
  ST="${ST:-"O"}"

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
  declare -gA WALLPOS

  SNAKELEN=1

  local map
  map="${LEVELDIR}/level_${LEVEL}.map"

  [[ -s $map ]] || return 1

  mapfile board < "$map"
  read_level_info || return 1

  # level height and width
  ((h=${#board[@]}))
  ((w=${#board[0]}))

  set_level_offset $((h)) $((w))

  LEVELCOLOR=$((COLORS[RANDOM%${#COLORS[@]}]))
  set_color $((LEVELCOLOR))

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
           line+=" "
           ;;
        W) 
           WALLPOS[$(( ((y+OFFY) << 8) | (x+OFFX) ))]=1
           line+=" "
           ;;
        E)
           POS[EY]=$((y+OFFY))
           POS[EX]=$((x+OFFX))
           line+=" "
           ;;
        *) 
           POS["$char"Y]=$((y+OFFY))
           POS["$char"X]=$((x+OFFX))
           line+=" "
      esac
    done

    # display line
    lecho $((y+OFFY)) $((OFFX)) "$line"
    line=""

  done

  set_color 0

  # pack snake initial position
  local i
  for ((i=0; i<SNAKELEN; i++)); do
    SNAKEPOS+=( $(( (POS[SY] << 8) | (POS[SX]+i) )) )
  done

  # display apples
  local a c v
  for a in "${APPLEPOS[@]}"; do
    ((y=a >> 20))
    ((x=(a >> 12) & MASK))
    ((c=(a >> 4) & MASK))
    ((v=a & 0x0F))
    set_color $((c)); set_color 7
    lecho $((y)) $((x)) $((v))
  done


  # display exit
  [[ $SPAWN == "fixed" ]] && {
    set_color $((LEVELCOLOR))
    lecho $((POS[EY])) $((POS[EX])) "E"
  }

  set_color 0
  set_color $((LEVELCOLOR))

  # display walls
  for a in "${!WALLPOS[@]}"; do
    ((y=a >> 8))
    ((x=a & MASK))
    lecho $((y)) $((x)) "#"
  done

  display_header

  [[ $SPAWN == "random" ]] && random_target

  return 0

}

display_header() {
  # display level number, remaining lives and score
  # on the game screen.

  local score_msg lives_msg target_msg
  score_msg="SCORE: ${SCORE}"
  lives_msg="☻ × $LIFE"
  target_msg="◀ ▶ $TARGET"

  set_color $((LEVELCOLOR))

  lecho $((POS[TY]-2)) $((POS[TX])) "LEVEL $LEVEL "
  lecho $((POS[TY]-2)) $((((OFFX+POS[BX])/2)-${#lives_msg})) " $lives_msg "
  lecho $((POS[TY]-2)) $((POS[BX]-${#score_msg})) " $score_msg "
  lecho $((POS[TY]-1)) $((POS[TX])) " $target_msg "
  lecho $((POS[BY]+2)) $((OFFX)) "$STATE"
}

display_level_intro() {
  # display level
  local level_msg lives_msg

  level_msg=" LEVEL $LEVEL "
  lives_msg="☻ × $LIFE"

  local y x color

  clear

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

start_level() {
  display_level_intro
  IFS= read -rsN 100 -t 0.005
  sleep 2
  clear
  init_level || return 1
  set_level_accuracy
}
