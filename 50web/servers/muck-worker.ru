#\ -s thin -o 127.0.0.1 -E production -p 7007 -P muck-worker.pid 
require '../routes/muck-worker.rb'
run MuckWorkerWeb
