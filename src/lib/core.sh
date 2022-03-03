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
# CORE
# C : 2022/02/21
# M : 2022/02/21
# D : 

# shellcheck source=/home/tigerlost/projets/serpent/src/lib/curse.sh
source "/home/tigerlost/projets/serpent/src/lib/curse.sh"
# shellcheck source=/home/tigerlost/projets/serpent/src/lib/level.sh
source "/home/tigerlost/projets/serpent/src/lib/level.sh"

# SOUND ASSETS
SNDDIR="$HOME"/projets/serpent/snd

declare -i SNAKELEN  # snake length
SNAKELEN=1   # length
SH="☻" # snake head
STL=""
STR=""
STU=""
STD=""
AV=1 # apple
AC=0 # apple color
SNAKECOLOR=0
LEVEL=1
TARGET=30 # target snake length
SCORE=0

get_min_index() {
  local len low hi
  ((len=${#SNAKEPOS[@]}))
  for hi in "${!SNAKEPOS[@]}"; do :; done
  ((low=hi-len+1))
  echo $((low))
}

snake_collision() {
  # detect snake collision:
  # snake -> level boundaries
  # snake -> walls

  local y x wy wx

  y=$1
  x=$2
  
  # level boundaries
  (( y < POS[TY] )) && return 0
  (( y > POS[BY] )) && return 0
  (( x < POS[TX] )) && return 0
  (( x > POS[BX] )) && return 0

  # walls
  local pos
  for pos in "${WALLPOS[@]}"; do
    (( wy=pos >> 8 ))
    (( wx=pos & MASK ))
    (( y == wy && x == wx )) && return 0
  done

  return 1

}

snake_out() {
  # detect whether snake has entered an exit

  local y x

  # unpack snake position
  (( y=SNAKEPOS[-1] >> 8 ))
  (( x=SNAKEPOS[-1] & MASK ))

  (( y == POS[EY] && x == POS[EX] )) && return 0
  return 1

}

snake_move() {
  local hy hx y x i idx

  (( hy=SNAKEPOS[-1] >> 8 ))
  (( hx=SNAKEPOS[-1] & MASK ))

  (( END == 1 )) || {
  
    case "$DIRECTION" in
      left ) ((hx--)); ST="$STL" ;;
      right) ((hx++)); ST="$STR" ;;
      up   ) ((hy--)); ST="$STU" ;;
      down ) ((hy++)); ST="$STD"
    esac

  }

  snake_collision $((hy)) $((hx)) && return 1

  set_color $SNAKECOLOR

  # reached exit
  ((hy == POS[EY] && hx == POS[EX])) && {
    (( SNAKELEN<TARGET )) && return 1
    (( y=SNAKEPOS[idx] >> 8 ))
    (( x=SNAKEPOS[idx] & MASK ))
    lecho $((y)) $((x)) " "
    set_color 7
    lecho $((POS[EY])) $((POS[EX])) "E"
    set_color 0
    set_color $SNAKECOLOR
    (( y=SNAKEPOS[-1] >> 8 ))
    (( x=SNAKEPOS[-1] & MASK ))
    lecho $((y)) $((x)) "$ST"
    set_color 0
    END=1
    return
  }

  # head
  SNAKEPOS+=( $(( (hy << 8) | hx )) )
  lecho $((hy)) $((hx)) "$SH"
  
  # ate an apple
  eat_apple $((hy)) $((hx)) && local WON=1

  idx="$(get_min_index)"

  # lecho $((POS[BY]+1)) $((POS[TX]+1)) "${hy},${hx},$idx,$((idx+SNAKELEN-1)),${SNAKELEN},${#SNAKEPOS[@]} → $TARGET"; clrtoeol

  # tail
  local t=0 
  for ((i=idx+1;i<idx+${#SNAKEPOS[@]}-1;i++)); do
    ((t++))
    (( y=SNAKEPOS[i] >> 8 ))
    (( x=SNAKEPOS[i] & MASK ))
    ((hy == y && hx == x)) && {
      {
        echo "t=$((t)) i=$((i)) idx=$((idx)) len=$SNAKELEN hy=$((hy)) hx=$((hx)) y=$((y)) x=$((x))"
        echo "snake position"
        echo "${!SNAKEPOS[*]}"
        echo "${SNAKEPOS[*]}"
        echo "apples position"
        echo "${!APPLEPOS[*]}"
        echo "${APPLEPOS[*]}"
      } >> ".log"
      playsnd hurt
      export TAIL=1
      sleep 0.5
      return 1
    }
    lecho $((y)) $((x)) "$ST"
  done

  (( y=SNAKEPOS[idx] >> 8 ))
  (( x=SNAKEPOS[idx] & MASK ))

  if ((WON == 1)); then
    ((SNAKELEN+=AV))
    lecho $((y)) $((x)) "$ST"
    local timer_end bonus
    ((timer_end=EPOCHSECONDS-TIMER))
    if ((timer_end == 0)); then
      bonus=500
      timer_end=1
    else
      bonus=100
    fi
    ((SCORE+=AV*(bonus/timer_end)))
    if (( SNAKELEN >= TARGET )); then
      random_target exit
    else
      SNAKECOLOR=$AC
      ((TIMER=EPOCHSECONDS))
      random_target
    fi
  elif (( SNAKELEN < ${#SNAKEPOS[@]} )); then
    idx="$(get_min_index)"
    lecho $((y)) $((x)) " "
    unset "SNAKEPOS[$idx]"
  fi

  # lecho $((y)) $((x)) "$ST"
  set_color 0

}

snake_destroy() {
  local idx i y x color
  idx="$(get_min_index)"

  for ((i=idx+SNAKELEN-1;i>=idx;i--)); do
    set_color $((COLORS[RANDOM%${#COLORS[@]}]))
    (( y=SNAKEPOS[i] >> 8 ))
    (( x=SNAKEPOS[i] & MASK ))
    lecho $((y)) $((x)) "█"
    sleep 0.03125
  done
  set_color $((COLORS[RANDOM%${#COLORS[@]}]))
  set_color 7
  ((y == 0)) && ((y=(POS[BY]-POS[TY])/2))
  lecho $((y)) $((OFFX+3)) " ▶▶▶ $SNAKELEN "
  set_color 0
  
}

snake_exit() {
  local pos y x

  playsnd enter

  for pos in "${SNAKEPOS[@]}"; do
    (( y=pos >> 8 ))
    (( x=pos & MASK ))
    lecho $((y)) $((x)) " "
    sleep 0.0625
  done
  playsnd close
}

eat_apple() {
  local y x pos ay ax av ac

  # snake head position
  y=$1
  x=$2

  for pos in "${!APPLEPOS[@]}"; do
    (( ay=APPLEPOS[pos] >> 20 ))
    (( ax=(APPLEPOS[pos] >> 12) & MASK ))
    (( ac=(APPLEPOS[pos] >> 4) & MASK ))
    (( av=APPLEPOS[pos] & 0x0F ))
    (( y == ay && x == ax )) && {
      playsnd eat
      ((AV=av))
      ((AC=ac))
      unset "APPLEPOS[$pos]"
      return 0
    }
  done

  return 1
}

random_target() {
  local y x c restart

  restart=0

  [[ $1 == "exit" ]] && { local show_exit=1; }
  (( ${#APPLEPOS[@]} > 0 && show_exit == 0 )) && return
  [[ $SPAWN != "random" && ${POS[EY]} ]] && return

  while :; do

    ((y=RANDOM%(POS[BY]-POS[TY])+POS[TY]+1))
    ((x=RANDOM%(POS[BX]-POS[TX])+POS[TX]+1))

    # check snake
    for c in "${SNAKEPOS[@]}"; do
      ((y == (c >> 8) && x == (c & MASK))) && { restart=1; break; }
    done
    (( restart == 0 )) && {
      # check walls
      for c in "${WALLPOS[@]}"; do
        ((y == (c >> 8) && x == (c & MASK))) && { restart=1; break; }
      done
    }

    (( restart == 0 )) && {
      local ac
      ((ac=COLORS[RANDOM%${#COLORS[@]}]))
      set_color $((ac))
      set_color 1
      lecho $((y)) $((x)) "×"
      sleep 0.0625
      set_color 7

      if [[ $show_exit ]]; then
        lecho $((y)) $((x)) "E"
        ((POS[EY]=y))
        ((POS[EX]=x))
        playsnd exit
        set_color 0
      else
        local av
        ((av=(RANDOM%9)+1))
        lecho $((y)) $((x)) $((av))
        playsnd spawn
        ((TIMER=EPOCHSECONDS))
        set_color 0
        APPLEPOS+=( $(( (y << 20) | (x << 12) | (ac << 4) | av )) )
      fi

      return
    }
  restart=0
  done
}

playsnd() {
  [[ $MUTE ]] && return 1
  which aplay > /dev/null || { MUTE=1; return 1; }
  case $1 in
    level ) aplay "$SNDDIR/level.wav" 2> /dev/null ;;
    eat   ) (aplay "$SNDDIR/eat.wav" 2> /dev/null) & ;;
    move  ) (aplay "$SNDDIR/move.wav" 2> /dev/null) & ;;
    spawn ) (aplay "$SNDDIR/spawn.wav" 2> /dev/null) & ;;
    exit  ) (aplay "$SNDDIR/exit.wav" 2> /dev/null) & ;;
    enter ) (aplay "$SNDDIR/enter.wav" 2> /dev/null) & ;;
    close ) aplay "$SNDDIR/close.wav" 2> /dev/null ;;
    pause ) aplay "$SNDDIR/pause.wav" 2> /dev/null ;;
    hurt  ) (aplay "$SNDDIR/hurt.wav" 2> /dev/null) & ;;
    die   ) (aplay "$SNDDIR/die.wav" 2> /dev/null) & ;;
    die2  ) (aplay "$SNDDIR/die2.wav" 2> /dev/null) & ;;
    over  ) ( aplay "$SNDDIR/over.wav" 2> /dev/null) & ;;
  esac
}
