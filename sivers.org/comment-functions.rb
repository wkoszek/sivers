def fmt(html)
	html.gsub(%r{(^|\s)(https?://\S+)}, '\1<a href="\2">\2</a>').gsub("\n", '<br>')
end

def li(row)
	'<li id="comment-%d"><cite>%s (%s) <a href="#comment-%d">#</a></cite><p>%s</p></li>' %
		[row['id'], row['name'], row['created_at'], row['id'], fmt(row['html'])]
end

def ol(rows)
	rows.inject('<ol>') {|html, row| html += li(row) ; html} + '</ol>'
end

def qry(db, uri)
	res = db.exec_params("SELECT id, created_at, name, html FROM sivers.comments
		WHERE uri=$1 ORDER BY id", [uri])
	return '' if res.ntuples == 0
	ol(res)
end

