@echo off

set _git_cmd='git.exe for-each-ref --format="%%(refname)" refs/heads/'
for /f "delims=*" %%g in (%_git_cmd%) do (
    git.exe sup %%g
)
