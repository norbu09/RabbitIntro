require 'rubygems'
require 'mq'

EM.run {
  amq = MQ.new
  amq.queue("test").subscribe do |login|
    puts login
  end
}
