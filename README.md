## Devbox for Symfony and PHP8 projects using docker

### What you will get at the end

* a Docker container in which you can SSH in
* PHP8.1 installed, with `composer` and `symfony` (PHP7 is on older tag)
* (optional) Neovim: same as vim but better, with php autocompletion
* (optional) Zsh: with my zshrc (that you can replace by yours

### Requirements

* Docker
* Docker [buildx](https://github.com/docker/buildx)

### Creation

```bash
docker build   --push  --tag   allansimon/docker-devbox-php:8.4 .
```

### Usage

### Extensive list of stuff installed

TODO

#### ZSH

##### aliases

```
alias gs="git status"
alias gm="git checkout master"
alias gp="git pull origin"
alias ga="git commit --amend"
```
