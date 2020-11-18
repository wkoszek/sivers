#!/usr/bin/env ruby
require '../models.rb'
require 'fileutils'

# HINT: probably want to do them all,like this:
# for i in KH CN HK IN ID JP KR MY MN MM PH SG LK TW TH VN ; do ruby book-output.rb $i ; done

# get country code
unless ARGV[0] && Countries.hsh.keys.include?(ARGV[0].upcase)
  raise "\nUSAGE: ./book-output.rb {country_code}"
end

# create output directories
country_code = ARGV[0].upcase
basedir = "/tmp/we14/#{Countries.hsh[country_code].gsub(' ', '')}2014"
puts "OUTPUT DIRECTORY: #{basedir}"
Dir.mkdir(basedir) unless File.directory?(basedir)
outdir = basedir + '/manuscript'
Dir.mkdir(outdir) unless File.directory?(outdir)
imgdir = outdir + '/images'
Dir.mkdir(imgdir) unless File.directory?(imgdir)

# get book & initialize array of filenames to be put in Book.txt
book = Book.filter(country: country_code).last
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
topicnest = Question.topicnest(book.questions, Question.topichash(country_code))
topicnest.each do |t|
  chapter += 1
  outfile = 'chapter%02d.txt' % chapter
  filenames << outfile
  File.open(outdir + '/' + outfile, 'w') do |f|
    f.puts '# ' + t[0] + "\n\n"
    t[1].each do |subtopic, questions|
      # page break before each subtopic
      f.puts "{pagebreak}\n\n"
      f.puts '# ' + subtopic + "\n\n"
      questions.each do |q|
        essay = q.essays[0].edited
	f.puts '## ' + q.question + "\n\n"
	f.puts essay.gsub("\r", '').h4_to_bold + "\n\n"
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
  f.puts '## Writer:' + "\n\n"
  book.writers.each do |r|
    f.puts '### ' + r.company + "\n\n"
    photo = 'writer-%d.jpg' % r.id
    f.puts "![](images/%s)\n\n" % photo
    f.puts "#{r.bio}\n\n"
    FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
  end
  f.puts '## Manager:' + "\n\n"
  f.puts "### Karol Gajda\n\n"
  photo = 'karol.jpg'
  f.puts "![](images/%s)\n\n" % photo
  f.puts "Karol Gajda currently lives in the beautifully underrated Eastern European city of Wrocław, Poland and helps businesses around the world sell more and more effectively via email. Working on Wood Egg prompted his decision to head back to SE Asia in the second half of 2014. Get in touch with Karol at <http://www.KarolGajda.com/>\n\n" 
  FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
  f.puts '## 2014 Researchers:' + "\n\n"
  book.researchers.each do |r|
    next if r.bio.nil?
    f.puts '### ' + r.company + "\n\n"
    photo = 'researcher-%d.jpg' % r.id
    f.puts "![](images/%s)\n\n" % photo
    f.puts "#{r.bio}\n\n"
    FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
  end
  f.puts '## 2013 Researchers:' + "\n\n"
  Book[book.id - 16].researchers.each do |r|
    next if r.bio.nil?
    f.puts '### ' + r.company + "\n\n"
    photo = 'researcher-%d.jpg' % r.id
    f.puts "![](images/%s)\n\n" % photo
    f.puts "#{r.bio}\n\n"
    FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
  end
  f.puts '## Editor:' + "\n\n"
  book.editors.each do |r|
    f.puts '### ' + r.company + "\n\n"
    photo = 'editor-%d.jpg' % r.id
    f.puts "![](images/%s)\n\n" % photo
    f.puts "#{r.bio}\n\n"
    FileUtils.cp('/srv/public/woodegg/public/images/300/' + photo, imgdir + '/' + photo)
  end
  f.puts book.credits
end

# index of files, for ebook making:
File.open(outdir + '/Book.txt', 'w') do |f|
  f.puts filenames.join("\n")
end

