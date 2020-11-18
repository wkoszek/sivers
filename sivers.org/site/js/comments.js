(function() {
	/* Putting form in separate-loaded js file here hides it from evil bots. */
	function showForm(uri) {
		/* no more comments for these URLs */
		if (uri === '/inlove' || uri === '/ss') {
			return '<h1>Comments</h1><div id="commentlist"></div>';
		} else {
			return '<header><h1>Your thoughts? Please leave a reply:</h1><form action="/comments" method="post"><label for="name_field">Your Name</label><input type="text" name="name" id="name_field" value="" /><label for="email_field">Your Email &nbsp; <span class="small">(private for my eyes only)</span></label><input type="email" name="email" id="email_field" value="" /><label for="comment">Comment</label><textarea name="comment" id="comment" cols="80" rows="10"></textarea><br><input name="submit" type="submit" class="submit" value="submit comment" /></form></header><h1>Comments</h1><div id="commentlist"></div>';
		}
	}
	function getComments(uri) {
		/* When comment posted, redirects user back to /page#comment-1234
		 * but this xhr is still cached, not showing their comment!
		 * So add this ?reload to end of URL so it's not cached */
		var alt = (/comment-\d+/.test(window.location.hash)) ? '?reload' : '';
		try {
			var xhr = new XMLHttpRequest();
			xhr.onreadystatechange = function() {
				if(xhr.readyState == 4 && xhr.status == 200) {
					document.getElementById('commentlist').innerHTML = xhr.responseText;
				}
			};
			xhr.open('get', '/sivers_comments' + uri + alt, true);
			xhr.send(null);
		} catch(e) { }
	}
	var isLoaded = false;
	function showComments() {
		if(isLoaded) { return; }
		document.getElementById('comments').innerHTML = showForm(location.pathname);
		getComments(location.pathname);
		isLoaded = true;
		window.onscroll = null;
	}
	function weHitBottom() {
		var contentHeight = document.getElementById('content').offsetHeight;
		var y1 = (window.pageYOffset !== undefined) ? window.pageYOffset : (document.documentElement || document.body.parentNode || document.body).scrollTop;
		var y2 = (window.innerHeight !== undefined) ? window.innerHeight : document.documentElement.clientHeight;
		var y = y1 + y2;
		if (y >= contentHeight) { showComments(); }
	}
	weHitBottom();
	if(isLoaded === false) { window.onscroll = weHitBottom; }
	if(/comment-\d+/.test(location.hash)) { showComments(); }
})();
