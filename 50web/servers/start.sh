for i in kyc.ru inbox.ru sivers.data.ru sivers.org.ru woodegg.ru
do echo $i
	head -1 $i
	rackup -D $i
done
