#\ -s thin -o 127.0.0.1 -E production -p 7004 -P woodegg.pid 
require '../routes/woodegg.rb'
run WoodEgg
