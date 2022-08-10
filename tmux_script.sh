#!/bin/bash

# First paramater after command is the session name, second is the project dir

session="${1}"
sesssion_exists=$(tmux list-sessions | grep $session)

if [ "$sesssion_exists" = "" ]
then

	tmux new-session -d -s $session

	tmux rename-window -t 1 "server"

	tmux new-window -t $session:2 -n "nvim"
	tmux send-keys -t "nvim" "cd ~/code/dev/${2}" C-m "nvim" C-m
	tmux select-window -t nvim
	#tmux split-window -v
	#tmux select-pane -t 0
	#tmux resize-pane -D 20
	tmux select-pane -t 1
	tmux send-keys "cd ~/code/dev/${2}" C-m

	tmux select-window -t server
	#tmux split-window -h
	#tmux select-layout even-horizontal
	tmux select-pane -t 0
	tmux send-keys "cd ~/code/dev/${2}" C-m
	#tmux select-pane -t 1
	#tmux resize-pane -R 20
	#tmux send-keys "cd ~/code/dev/${2}" C-m

	tmux new-window -t $session:3 -n "terminal"
	tmux send-keys "cd ~/code/dev/${2}" C-m
fi

tmux attach-session -t $session:1

