require 'rubygems'
require 'mq'

EM.run {
  amq = MQ.new
  queue = amq.queue("log")
  %w[scott nic robi].each { |login|
      queue.publish(login)
  }
}
