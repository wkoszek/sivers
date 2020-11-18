__END__
require '../models.rb'
# for every line that starts with "###", add another "#" to the beginning of it

# essay ID# 3327 is start of 2014 books 
Essay.where('id >= 3327').each do |e|
  if (e.content.nil? == false) && (e.content.include? '###')
    nu = e.content.split("\n").map {|l| (l[0,3] == '###') ? "##{l}" : l}.join("\n")
    e.update(content: nu)
  end
  if (e.edited.nil? == false) && (e.edited.include? '###')
    nu = e.edited.split("\n").map {|l| (l[0,3] == '###') ? "##{l}" : l}.join("\n")
    e.update(edited: nu)
  end
end
