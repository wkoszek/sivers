<script>
var ul = document.getElementById('shuffle');
var lis = ul.getElementsByTagName('li');
var lia = [];
var l = lis.length - 1;
for(l; l >= 0; l--) {
	lia.push(ul.removeChild(lis[l]));
}
var i = lia.length;
while (i--) {
	var j = Math.floor(Math.random() * (i + 1)),
		tmpi = lia[i],
		tmpj = lia[j];
	lia[i] = tmpj;
	lia[j] = tmpi;
}
i = lia.length;
while (i--) {
	ul.appendChild(lia.pop());
}
</script>
