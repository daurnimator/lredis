# Redis library for Lua

## Features

  - Optionally asynchronous
  - Compatible with Lua 5.1, 5.2, 5.3 and [LuaJIT](http://luajit.org/)

# Status

This project is a work in progress and not ready for production use.

[![Build Status](https://travis-ci.org/daurnimator/lredis.svg)](https://travis-ci.org/daurnimator/lredis)
[![Coverage Status](https://coveralls.io/repos/daurnimator/lredis/badge.svg?branch=master&service=github)](https://coveralls.io/github/daurnimator/lredis?branch=master)


# Installation

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
