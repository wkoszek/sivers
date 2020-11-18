#\ -s thin -o 127.0.0.1 -E production -p 7002 -P kyc.pid 
require '../routes/kyc.rb'
run KYC
