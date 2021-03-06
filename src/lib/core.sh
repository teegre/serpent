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
# M : 2022/03/24
# D : Core functions.

# shellcheck source=/home/tigerlost/.local/lib/serpent/curse.sh
source "$HOME/.local/lib/serpent/curse.sh"
# shellcheck source=/home/tigerlost/.local/lib/serpent/level.sh
source "$HOME/.local/lib/serpent/level.sh"
# shellcheck source=/home/tigerlost/.local/lib/serpent/score.sh
source "$HOME/.local/lib/serpent/score.sh"
# shellcheck source=/home/tigerlost/.local/lib/serpent/menu.sh
source "$HOME/.local/lib/serpent/menu.sh"

# shellcheck source=/home/tigerlost/.local/lib/serpent/title.sh
source "$HOME/.local/lib/serpent/title.sh"

# ASSETS
RESDIR="$HOME/.local/share/serpent/res"
SNDDIR="$RESDIR/snd"

declare -i SNAKELEN=1  # snake length
# SH="☻" # snake head
AV=1 # apple
AC=0 # apple color
SNAKECOLOR=0

reset_game() {
  LEVEL=1
  LIFE=9
  score_reset
  unset POS SNAKEPOS APPLEPOS WALLPOS
}

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

  local pos y x

  ((pos=SNAKEPOS[-1]))
  ((y=pos >> 8))
  ((x=pos & MASK))
  
  # level boundaries
  (( y < POS[TY] )) && return 0
  (( y > POS[BY] )) && return 0
  (( x < POS[TX] )) && return 0
  (( x > POS[BX] )) && return 0

  # walls
  [[ ${WALLPOS["$pos"]} == 1 ]] && return 0

  return 1

}

snake_out() {
  # detect whether snake has entered an exit door

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
      left ) ((hx--)); SH="$SHL" ;;
      right) ((hx++)); SH="$SHR" ;;
      up   ) ((hy--)); SH="$SHU" ;;
      down ) ((hy++)); SH="$SHD"
    esac

  }

  snake_collision && return 1

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

  # tail
  local t=0 
  for ((i=idx+1;i<idx+${#SNAKEPOS[@]}-1;i++)); do
    ((t++))
    (( y=SNAKEPOS[i] >> 8 ))
    (( x=SNAKEPOS[i] & MASK ))
    ((hy == y && hx == x)) && {
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
    compute_apple_score
    if (( SNAKELEN >= TARGET )); then
      random_target exit
    else
      SNAKECOLOR=$AC
      random_target
    fi
    timer_start
  elif (( SNAKELEN < ${#SNAKEPOS[@]} )); then
    idx="$(get_min_index)"
    lecho $((y)) $((x)) " "
    unset "SNAKEPOS[$idx]"
  fi

  set_color 0
}

snake_destroy() {
  local idx i y x color
  idx="$(get_min_index)"

  for ((i=idx+SNAKELEN-1;i>=idx;i--)); do
    set_color $((COLORS[RANDOM%${#COLORS[@]}]))
    (( y=SNAKEPOS[i] >> 8 ))
    (( x=SNAKEPOS[i] & MASK ))
    (( y == 0 || x == 0 )) && continue
    lecho $((y)) $((x)) "█"
    # sleep 0.03125
  done
  set_color $((COLORS[RANDOM%${#COLORS[@]}]))
  set_color 7
  ((y == 0)) && ((y=(POS[BY]-POS[TY])/2))
  lecho $((y)) $((OFFX+3)) " ◀ ▶ $SNAKELEN "
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
  compute_accuracy
  playsnd close
  display_accuracy
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
      compute_accuracy
      return 0
    }
  done

  return 1
}

random_target() {
  local y x c restart

  restart=0

  [[ $SPAWN != "random" && ${POS[EY]} ]] && return
  [[ $1 == "exit" ]] && { local show_exit=1; }
  # (( ${#APPLEPOS[@]} > 0 && show_exit == 0 )) && return

  while :; do

    ((y=RANDOM%(POS[BY]-POS[TY])+POS[TY]+1))
    ((x=RANDOM%(POS[BX]-POS[TX])+POS[TX]+1))

    # check snake
    for c in "${SNAKEPOS[@]}"; do
      ((y == (c >> 8) && x == (c & MASK))) && { restart=1; break; }
    done
    (( restart == 0 )) && {
      # check walls
      [[ ${WALLPOS[$((y << 8 | x))]} ]] && continue

      # for c in "${WALLPOS[@]}"; do
        # ((y == (c >> 8) && x == (c & MASK))) && { restart=1; break; }
      # done
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
    level )  aplay "$SNDDIR/level.wav" 2> /dev/null    ;;
    move  ) (aplay "$SNDDIR/move.wav"  2> /dev/null) & ;;
    eat   ) (aplay "$SNDDIR/eat.wav"   2> /dev/null) & ;;
    spawn ) (aplay "$SNDDIR/spawn.wav" 2> /dev/null) & ;;
    exit  ) (aplay "$SNDDIR/exit.wav"  2> /dev/null) & ;;
    enter ) (aplay "$SNDDIR/enter.wav" 2> /dev/null) & ;;
    close )  aplay "$SNDDIR/close.wav" 2> /dev/null    ;;
    score )  aplay "$SNDDIR/score.wav" 2> /dev/null    ;;
    1up   ) (aplay "$SNDDIR/1up.wav"   2> /dev/null) & ;;
    pause )  aplay "$SNDDIR/pause.wav" 2> /dev/null    ;;
    hurt  ) (aplay "$SNDDIR/hurt.wav"  2> /dev/null) & ;;
    die   ) (aplay "$SNDDIR/die.wav"   2> /dev/null) & ;;
    die2  ) (aplay "$SNDDIR/die2.wav"  2> /dev/null) & ;;
    over  ) (aplay "$SNDDIR/over.wav"  2> /dev/null) & ;;
  esac
}
