#!/bin/bash

docker run --rm -it -v ~/blog:/src klakegg/hugo -d docs
git add content/** docs/**
git commit
git push
