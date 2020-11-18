require '../models.rb'

combined_text = ''

get_text_after_string = 'time and knowledge.'

(17..32).each do |i|
  b = Book[i]

  c = b.credits
  starting_point = c.index(get_text_after_string) + get_text_after_string.length
  new_text = c[starting_point..-1].strip

  if new_text.length > 3
    combined_text << "### %s\n\n%s\n\n" % [Countries.hsh[b.country], new_text]
  end
end

puts combined_text
