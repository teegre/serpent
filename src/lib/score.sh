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
# SCORE
# C : 2022/03/03
# M : 2022/02/05
# D : Score calculation and related utilities.

# scoring system
#
# for each apple eaten:
#  500 pts if time is 0
#  100 pts otherwise
#  → value x ( pts / time_in_seconds )
# when level is finished:
#  if accuracy is greater than zero:
#    → accuracy * 1000 pts
#
# accuracy:
# if the level does not contain inside walls, the maximum 
# number of moves allowed is 3 (which means 3 keystrokes),
# otherwise it is set to 4.
# the player gets +1 accuracy pt if the condition is met,
# otherwise accuracy is decremented.
#
# 1up:
# get one extra life every 10k pts.

declare -i start_time
declare -i current_score=0
export current_score
declare -i SCORE=0
declare -i ACCURACY=0
declare -i KEYSTROKE=0
declare -i MAXMOVE=0

timer_start() {
  ((start_time=EPOCHSECONDS))
}

score_reset() {
  ACCURACY=0
  KEYSTROKE=0
  (( ${#WALLPOS[@]} > 0 )) && 
    MAXMOVE=4 || 
    MAXMOVE=3
  timer_start
}

compute_accuracy() {
  ((ACCURACY=KEYSTROKE>MAXMOVE?ACCURACY-1:ACCURACY+1))
  KEYSTROKE=0
}

compute_apple_score() {
  local end_time pts
  ((end_time=EPOCHSECONDS-start_time))
  if (( end_time == 0 )); then
    pts=500
    end_time=1
  else
    pts=100
  fi
  ((SCORE+=AV*(pts/end_time)))
  display_header
}

compute_final_score() {
  local life
  if (( ACCURACY >0 )); then
    ((SCORE+=ACCURACY*1000))
  else
    return
  fi
  display_header
  ((life=(SCORE/10000)-(current_score/10000)))
  if (( life > 0 )); then
    while (( life > 0 )); do
      ((life--))
      oneup 1
      sleep 0.25
    done
  else
    playsnd score
  fi
}

display_accuracy() {
  set_color $((COLORS[RANDOM%${#COLORS[@]}]))
  (( ACCURACY > 0 ))  && accuracy_msg=" +${ACCURACY} "
  (( ACCURACY <= 0 )) && accuracy_msg=" ${ACCURACY} "
  set_color 7
  lecho $((POS[EY]))  $((POS[EX]-${#accuracy_msg}+1)) "$accuracy_msg"
  set_color 0
  sleep 2
}

oneup() {
  ((LIFE+=$1))
  display_header
  set_color $((COLORS[1]))
  set_color 7
  lecho $((POS[EY])) $((POS[EX]+2)) " 1UP! "
  playsnd 1up
  sleep 0.75
  set_color 0
  lecho $((POS[EY])) $((POS[EX]+2)) "      "
}
