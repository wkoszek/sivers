#!/usr/bin/env ruby
require '../models.rb'
require 'kramdown'

# HINT: probably want to do them all,like this:
# for i in KH CN HK IN ID JP KR MY MN MM PH SG LK TW TH VN ; do ruby book-html.rb $i ; done

# get country code
unless ARGV[0] && Countries.hsh.keys.include?(ARGV[0].upcase)
  raise "\nUSAGE: ./book-html.rb {country_code}"
end

# create output file
country_code = ARGV[0].upcase
book = Book.filter(country: country_code).last
outfile = "/tmp/we14#{country_code.downcase}.html"
html = '<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>%s</title>
<style>
body { max-width: 40em; margin: 0 auto; font-family: Georgia; }
h1, h2, h3, h4 {font-family: Verdana, sans-serif; }
div.essay h3, div.essay h4 { font-weight: normal; margin-bottom: 0; }
h2 { margin-top: 2em; }
</style>
</head>
<body>
<h1>%s</h1>
' % [book.title, book.title]

# go through each topic as a chapter
topicnest = Question.topicnest(book.questions, Question.topichash(country_code))
topicnest.each do |t|
  html << "\n<hr>\n<h1>%s</h1>\n" % t[0]
  t[1].each do |subtopic, questions|
    html << "\n<h2>%s</h2>\n" % subtopic
    questions.each do |q|
      html << "\n<h3>%s</h3>\n" % q.question
      e = q.essays[1]
      html << "<div class=\"essay\">\n"
      if e && e.edited
	html << Kramdown::Document.new(e.edited).to_html
      elsif e && e.content
	html << Kramdown::Document.new(e.content).to_html
      else
	html << '…'
      end
      html << "\n</div>\n"
    end
  end
end

html << "\n</body>\n</html>\n"
File.open(outfile, 'w') {|f| f.puts html}
puts "#{outfile} written"
