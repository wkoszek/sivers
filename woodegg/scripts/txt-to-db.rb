# For importing text files, named with country code, into each book
require '../models.rb'

filepath = '/tmp/SALESCOPY/SALESCOPY-%s.txt'

Countries.hsh.keys.each do |cc|
  puts 'doing country %s' % cc
  infile = File.read(filepath % cc).strip
  puts 'infile size %d' % infile.size
  book = Book.filter(country: cc).first
  puts 'book title %s' % book.title
  book.update(salescopy: infile)
  puts "UPDATED\n"
end
