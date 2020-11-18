#\ -s thin -o 127.0.0.1 -E development -p 7001 -P words.pid 
require '../routes/words.rb'
run Words
