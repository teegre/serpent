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
# M : 2022/02/21
# D : 

# shellcheck source=/home/tigerlost/projets/serpent/src/lib/core.sh
source "/home/tigerlost/projets/serpent/src/lib/core.sh"

# MUTE=1

LEVEL=${1-:1}
PAUSE=0
LIFE=9
current_score=0

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
      ((SCORE+=(SNAKELEN-TARGET)*1000))

      display_header

      unset END
      SNAKELEN=1
      sleep 2
      ((LEVEL++))
      clear
      display_level_intro
      IFS= read -rsN 100 -t 0.005
      sleep 2
      init_level || { echo "WHAT??? IT'S OVER???"; exit; }
      current_score=$SCORE
    else
      case $key in
        h   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "left" ]]  || { DIRECTION="left";  playsnd move; } ;;
        j   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "down" ]]  || { DIRECTION="down";  playsnd move; } ;;
        k   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "up" ]]    || { DIRECTION="up";    playsnd move; } ;;
        l   ) ((PAUSE==1)) && continue; [[ $DIRECTION == "right" ]] || { DIRECTION="right"; playsnd move; } ;;
        " " ) ((PAUSE=!PAUSE)); playsnd pause
      esac
      ((PAUSE==1)) && STATE="$(set_color 7)$(set_color $SNAKECOLOR) PAUSED $(set_color 0)" || STATE="$(clrtoeol)"

      display_header

      ((PAUSE==1)) && sleep 0.5
      ((PAUSE == 0)) && {
        if  snake_move; then
          [[ $DIRECTION == "left" || $DIRECTION == "right" ]] && sleep 0.0625
          [[ $DIRECTION == "up" || $DIRECTION == "down" ]] && sleep 0.125
        else   
          if (( TAIL == 1 )); then
            playsnd die2
          else
            playsnd die
          fi
          snake_destroy
          sleep 2
          ((LIFE--))
          ((LIFE==-1)) && break
          SCORE=$current_score
          SNAKELEN=1
          clear
          display_level_intro
          IFS= read -rsN 100 -t 0.005
          sleep 2
          clear
          init_level
        fi
      }
    fi
  done

  playsnd over
  set_color 7
  set_color $SNAKECOLOR
  lecho $((POS[BY]+2)) $((OFFX)) " GAME OVER "
  IFS= read -rsN 100 -t 0.005
  echo
}

init_tips || echo "failed."
display_level_intro
IFS= read -rsN 100 -t 0.005
sleep 2
init_level || { echo; exit; }
gameloop
