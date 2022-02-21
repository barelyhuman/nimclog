#!/bin/bash

set -euxo pipefail

build_commands=('
    choosenim stable \
    ; nim c -d:release -o:bin/linux-amd64/nimclog src/nimclog.nim \
    ; nim c -d:release --cpu:arm64 --os:linux -o:bin/linux-arm64/nimclog src/nimclog.nim \
    ; nim c -d:release --os:macosx --cpu:amd64 -o:bin/darwin-amd64/nimclog src/nimclog.nim \
    ; nim c -d:release -d:mingw --cpu:i386 -o:bin/windows-386/nimclog.exe src/nimclog.nim \
    ; nim c -d:release -d:mingw --cpu:amd64 -o:bin/windows-amd64/nimclog.exe src/nimclog.nim
')

docker run -it --rm -v `pwd`:/usr/local/src \
   chrishellerappsian/docker-nim-cross:latest \
   /bin/bash -c "choosenim stable; $build_commands"