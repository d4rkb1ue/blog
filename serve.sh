#!/bin/bash

docker run -p 1313:1313 --rm -it -v ~/blog:/src klakegg/hugo server
