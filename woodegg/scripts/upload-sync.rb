require File.dirname(File.dirname(File.realpath(__FILE__))) + '/models.rb'

begin
  u = Upload.sync_next
  puts u
end while u != false

