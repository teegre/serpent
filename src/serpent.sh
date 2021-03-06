#! /usr/bin/env bash

#  _______ _______ ______ ______ _______ _______ _______ 
# |     __|    ___|   __ \   __ \    ___|    |  |_     _|
# |__     |    ___|      <    __/    ___|       | |   |  
# |_______|_______|___|__|___|  |_______|__|____| |___|  
# 
# Copyright (C) 2022, Stéphane MEYER.
# 
# This program is free software: you can redistribute it and/or modify
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
# SERPENT
# C : 2022/02/21
# M : 2022/03/06
# D : Main program.

# shellcheck source=/home/tigerlost/.local/lib/serpent/core.sh
source "$HOME/.local/lib/serpent/core.sh"

# MUTE=1

LEVEL=${1-:1}
LIFE=9
PAUSE=0

clear
stty -echo
hidecursor

trap 'showcursor; stty echo; exit' INT EXIT

# Gameloop
gameloop() {
  while :; do
    IFS= read -rsn 1 -t 0.005 key

    if (( END == 1 )); then

      snake_exit
      compute_final_score
      unset END
      sleep 2
      ((LEVEL++))
      start_level || return 1
      current_score=$SCORE

    else
      case $key in
        h   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "left" ]]  || { DIRECTION="left";  ((KEYSTROKE++)); playsnd move; } ;;
        j   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "down" ]]  || { DIRECTION="down";  ((KEYSTROKE++)); playsnd move; } ;;
        k   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "up" ]]    || { DIRECTION="up";    ((KEYSTROKE++)); playsnd move; } ;;
        l   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "right" ]] || { DIRECTION="right"; ((KEYSTROKE++)); playsnd move; } ;;
        " " ) ((PAUSE=!PAUSE)); playsnd pause
      esac

      [[ $key == " " ]] && ((PAUSE==1)) && {
        STATE="$(set_color 7) PAUSED $(set_color 0)"
        display_header
        make_menu h $((POS[BY]+2)) $((POS[TX]+8)) "CONTINUE" "TITLE"
        case $? in
          0) playsnd pause; ((PAUSE=0)) ;;
          1) ((PAUSE=0)); STATE=""; reset_game; return 0;
        esac
      }
      [[ $key == " " ]] && ((PAUSE==0)) && {
        STATE="$(clrtoeol)"
        display_header
        key=""
      }

      ((PAUSE==1)) && sleep 0.75
      ((PAUSE == 0)) && {
        if snake_move; then
          [[ $DIRECTION == "left" || $DIRECTION == "right" ]] && sleep 0.0625
          [[ $DIRECTION == "up" || $DIRECTION == "down" ]] && sleep 0.125
        else   
          if (( TAIL == 1 )); then
            playsnd die2
            unset TAIL
          else
            playsnd die
          fi
          snake_destroy
          sleep 2
          ((LIFE--))
          ((LIFE==-1)) && break
          SCORE=$current_score
          start_level
        fi
      }
    fi
  done

  playsnd over
  set_color 7
  set_color $((LEVELCOLOR))
  lecho $((POS[BY]+2)) $((OFFX)) " GAME OVER "
  set_color 0
  IFS= read -rsN 100 -t 0.005
  sleep 2
  reset_game # TODO continue!! (with countdown and music => reset lives + score
  
}

running=1
init_tips || echo "no tips?"
while (( running == 1 )); do
  if init_title; then
    gameloop || running=0;
  else
    running=0
  fi
done

clear
