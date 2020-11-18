#!/usr/bin/env ruby
require '../models.rb'
require 'fileutils'

# create output directories
country_code = 'AA'
basedir = "/tmp/we14/Asia2014"
puts "OUTPUT DIRECTORY: #{basedir}"
Dir.mkdir(basedir) unless File.directory?(basedir)
outdir = basedir + '/manuscript'
Dir.mkdir(outdir) unless File.directory?(outdir)
imgdir = outdir + '/images'
Dir.mkdir(imgdir) unless File.directory?(imgdir)

# initialize array of filenames to be put in Book.txt
book = Book[33]
filenames = []

# cover = title_page.jpg = 1650 pixels wide and 2400 pixels high at 300 PPI
FileUtils.cp('/srv/public/woodegg/public/images/we14/we14cover-%s.jpg' % country_code, imgdir + '/title_page.jpg')

# start with chapter00.txt - the intro
chapter = 0
outfile = 'chapter%02d.txt' % chapter
filenames << outfile
File.open(outdir + '/' + outfile, 'w') do |f|
  f.puts book.intro.gsub("\r", '')
  photo = 'derek.jpg'
  f.puts "\n\n![](images/%s)\n\n" % photo
  FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
end

# go through each topic as a chapter
topicnest = TemplateQuestion.nested_common
# key=topic, value=hash of subtopics
topicnest.each do |tt, st_hash|
  chapter += 1
  outfile = 'chapter%02d.txt' % chapter
  filenames << outfile
  File.open(outdir + '/' + outfile, 'w') do |f|
    f.puts '# ' + tt.topic + "\n\n"
    # key=subtopic, value=array of template_questions
    st_hash.each do |st, tq_array|
      # page break before each subtopic
      f.puts "{pagebreak}\n\n"
      f.puts '# ' + st.subtopic + "\n\n"
      # for each template_question, go through .questions
      tq_array.each do |tq|
	# page break before each question
	f.puts "{pagebreak}\n\n"
	f.puts '## ' + tq.question + "\n\n"
	tq.questions.each do |q|
          essay = q.essays[0].edited
	  f.puts '### ' + Countries.hsh[q.country].upcase + "\n\n"
	  f.puts essay.gsub("\r", '').h4_to_bold + "\n\n"
	end
      end
    end
  end
end

# final page = credits (+ copy images while at it)
chapter += 1
outfile = 'chapter%02d.txt' % chapter
filenames << outfile
File.open(outdir + '/' + outfile, 'w') do |f|
  f.puts '# CREDITS' + "\n\n"
  f.puts '## Manager:' + "\n\n"
  f.puts "### Karol Gajda\n\n"
  photo = 'karol.jpg' 
  f.puts "![](images/%s)\n\n" % photo
  f.puts "Karol Gajda currently lives in the beautifully underrated Eastern European city of Wrocław, Poland and helps businesses around the world sell more and more effectively via email. Working on Wood Egg prompted his decision to head back to SE Asia in the second half of 2014. Get in touch with Karol at <http://www.KarolGajda.com/>\n\n" 
  FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
  f.puts '## Writers:' + "\n\n"
  Countries.hsh.each do |cc, cn|
    f.puts '### ' + cn + "\n\n"
    book = Book.where(country: cc).order(:id).last
    book.writers.each do |r|
      f.puts '#### ' + r.company + "\n\n"
      photo = 'writer-%d.jpg' % r.id
      f.puts "![](images/%s)\n\n" % photo
      f.puts "#{r.bio}\n\n"
      FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
    end
  end
  f.puts '## 2014 Researchers:' + "\n\n"
  Countries.hsh.each do |cc, cn|
    f.puts '### ' + cn + "\n\n"
    book = Book.where(country: cc).order(:id).last
    book.researchers.each do |r|
      next if r.bio.nil?
      f.puts '#### ' + r.company + "\n\n"
      photo = 'researcher-%d.jpg' % r.id
      f.puts "![](images/%s)\n\n" % photo
      f.puts "#{r.bio}\n\n"
      FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
    end
  end
  f.puts '## 2013 Researchers:' + "\n\n"
  Countries.hsh.each do |cc, cn|
    f.puts '### ' + cn + "\n\n"
    book = Book.where(country: cc).order(:id).first
    book.researchers.each do |r|
      next if r.bio.nil?
      f.puts '#### ' + r.company + "\n\n"
      photo = 'researcher-%d.jpg' % r.id
      f.puts "![](images/%s)\n\n" % photo
      f.puts "#{r.bio}\n\n"
      FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
    end
  end
  f.puts '## Editors:' + "\n\n"
  Countries.hsh.each do |cc, cn|
    f.puts '### ' + cn + "\n\n"
    book = Book.where(country: cc).order(:id).last
    book.editors.each do |r|
      f.puts '#### ' + r.company + "\n\n"
      photo = 'editor-%d.jpg' % r.id
      f.puts "![](images/%s)\n\n" % photo
      f.puts "#{r.bio}\n\n"
      FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
    end
  end
  book = Book[33]
  f.puts book.credits
end

# index of files, for ebook making:
File.open(outdir + '/Book.txt', 'w') do |f|
  f.puts filenames.join("\n")
end

