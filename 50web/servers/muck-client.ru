#\ -s thin -o 127.0.0.1 -E production -p 7006 -P muck-client.pid 
require '../routes/muck-client.rb'
run MuckClientWeb
