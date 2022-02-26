# nimclog

This is nim port of commitlog with a tighter scope

## Why ?

size, binary size.

also, to get better at nimlang

## Features

- Categorize git's logs into `["build","chore","ci","docs","feat","fix","perf","refactor","revert","style","test"]`
- Doesn't support scoped commits right now
- That's about it.

## Usage

```sh
# for everything
nimclog

# for a specific range
nimclog --start=<gitrevision> --end=<gitrevision>

# shorthand props for the same
nimclog -s=<gitrevision>
nimclog -e=<gitrevision>

```

## Installation

Cross compiled binaries can be found on the releases pages.
Windows builds have not been tested, please report if you find any issues running them.

You can also compile it on your own system using `nim` or `nimble`

```sh
nimble build
# or
nim c src/nimclog.nim
```

## License

[MIT](/LICENSE)
