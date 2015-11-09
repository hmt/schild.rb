require 'sequel'
require 'minitest/autorun'
require 'minitest/rg'
require 'envyable'

Envyable.load('./config/env.yml', 'local_test')
if RUBY_ENGINE == 'jruby'
  ENV['S_ADAPTER'] = "jdbc:mysql"
end

require 'schild'
include SchildErweitert
