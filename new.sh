#/bin/bash

docker run --rm -it -v ~/blog:/src klakegg/hugo new posts/$1.md
open ./content/posts/$1.md