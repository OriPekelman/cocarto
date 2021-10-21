#!/usr/bin/env bash

function linux() {
    command="psql -c \"create user gxis with password 'gxis' superuser\""
    sudo su postgres -c "$command"
}

function macos() {
    psql -c "create user gxis with password 'gxis' superuser"
}

case $(uname -s) in
    Linux*)     linux;;
    Darwin*)    macos;;
    *)          echo "Unknow system '$(uname -s)'"; exit 1
esac
