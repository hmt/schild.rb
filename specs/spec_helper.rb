# encoding: UTF-8
require 'sequel'
require 'minitest/autorun'
require 'minitest/rg'
require 'envyable'
Envyable.load('./config/env.yml', 'local_test')

require 'schild'
include SchildErweitert
