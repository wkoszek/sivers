#\ -s thin -o 127.0.0.1 -E production -p 7008 -P muck-manager.pid 
require '../routes/muck-manager.rb'
run MuckManagerWeb
