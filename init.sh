#!/usr/bin/env bash

# Printing colors

#-----------------------------------------
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37
#-----------------------------------------

red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
nc=$'\e[0m'

warn="${yel}WARN :${nc}"
error="${red}ERROR:${nc}"
info="INFO :"

# TODO - check if .vim/ is created, if not create & create undodir
# TODO - add create symlink for venv_hook.sh

# Files in dotfiles dir to be symlinked
files=(vimrc gitconfig zshrc ycm_extra_conf.py)

for file in ${files[@]}; do

    dest=~/.$file

    # Check if file exists and is a regular file
    if [ -L $dest ]; then
      printf "$info $dest is already symlinked --> skipping\n"

    # Check if file exists and is a regular file
    elif [ -f $dest ]; then
        printf "$error $dest already exists, backup original before symlinking! --> skipping\n"

    # File does not exist, so we can proceed with symlink
    else
        log=$(ln -sv $PWD/$file ~/.$file 2>&1)
        retval=$?
        if [ $retval -ne 0 ]; then
            printf "$error unable to symlink: $file"
            printf "${red}$log${nc}"
        else
            printf "$info ${grn}$log${nc}\n"
        fi
      fi
done
