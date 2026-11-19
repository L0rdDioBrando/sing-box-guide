#!/bin/bash

set -e

git pull

mdbook build /home/bopsifox/sing-box-guide -d ~/sing-box-guide/book
