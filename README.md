# Redis library for Lua

## Features

  - Optionally asynchronous
  - Compatible with Lua 5.1, 5.2, 5.3 and [LuaJIT](http://luajit.org/)
  - [Subscribe (PubSub) mode](http://redis.io/topics/pubsub)
  - Automatic pipelining (if you use more than one coroutine)

## Why not **_________**?

  - [redis-lua](https://github.com/nrk/redis-lua)?
      - Not asynchronous
      - Relies on [luasocket](http://www.impa.br/~diego/software/luasocket)
      - Architecture doesn't support subscribe mode
  - [lluv-redis](https://github.com/moteus/lua-lluv-redis)?
      - Requires lluv/libuv
  - [lua-resty-redis](https://github.com/openresty/lua-resty-redis)?
      - Only works inside of openresty/nginx
  - [lua-hiredis](https://github.com/agladysh/lua-hiredis)?
      - Not asynchronous
      - Relies on hiredis C module
      - Architecture doesn't support subscribe mode
  - [sidereal](https://github.com/silentbicycle/sidereal)?
      - Unmaintained
      - Asynchronous mode not really composable
      - Relies on [luasocket](http://www.impa.br/~diego/software/luasocket)
  - [fend-redis](https://github.com/chatid/fend-redis)?
      - Unmaintained
      - Relies on hiredis C module
      - requires ffi


# Status

This project is a work in progress and not ready for production use.

[![Build Status](https://travis-ci.org/daurnimator/lredis.svg)](https://travis-ci.org/daurnimator/lredis)
[![Coverage Status](https://coveralls.io/repos/daurnimator/lredis/badge.svg?branch=master&service=github)](https://coveralls.io/github/daurnimator/lredis?branch=master)


# Installation

It's recommended to install lredis by using [luarocks](https://luarocks.org/).
This will automatically install run-time lua dependencies for you.

  $ luarocks install --server=http://luarocks.org/dev lredis

## Dependencies

  - [cqueues](http://25thandclement.com/~william/projects/cqueues.html) >= 20150907
  - [fifo](https://github.com/daurnimator/fifo.lua)

### For running tests

  - [luacheck](https://github.com/mpeterv/luacheck)
  - [busted](http://olivinelabs.com/busted/)
  - [luacov](https://keplerproject.github.io/luacov/)


# Development

## Getting started

  - Clone the repo:
    ```
    $ git clone https://github.com/daurnimator/lredis.git
    $ cd lredis
    ```

  - Install dependencies
    ```
    $ luarocks install --only-deps lredis-scm-0.rockspec
    ```

  - Lint the code (check for common programming errors)
    ```
    $ luacheck .
    ```

  - Run tests and view coverage report ([install tools first](#for-running-tests))
    ```
    $ busted -c
    $ luacov && less luacov.report.out
    ```

  - Install your local copy:
    ```
    $ luarocks make lredis-scm-0.rockspec
    ```
