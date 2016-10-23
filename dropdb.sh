#!/bin/sh
mysql -uroot -p1tism0db -e 'DROP DATABASE IF EXISTS Teresa;'
mysql -uroot -p1tism0db -e 'CREATE DATABASE Teresa;'
redis-cli flushall