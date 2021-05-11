#!/bin/bash

reload_runner=false

for var in "$@"
do
  if [ "$var" == "--reload-runner" ]; then
    reload_runner=true;
  fi
done

args=""

if [ $reload_runner = true ]; then
  args="$args --build-arg runner-rev=\"$(date | sed "s/ //g")\""
fi

docker build --build-arg commit=$1 $args -t dpctf:$2 .
