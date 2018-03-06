#!/bin/sh

sed -nre "s/VERSION=\"\S+ \((.*)\)\"/\1/p" /etc/os-release
