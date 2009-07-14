require 'rubygems'
require 'mq'

EM.run {
  amq = MQ.new
  amq.queue("log").subscribe do |login|
    puts login
  end
}
