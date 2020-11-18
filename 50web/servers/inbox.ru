#\ -s thin -o 127.0.0.1 -E production -p 7003 -P inbox.pid 
require '../routes/inbox.rb'
run Inbox
