#!/bin/bash

hugo -d docs
git add content/** docs/**
git commit
git push
