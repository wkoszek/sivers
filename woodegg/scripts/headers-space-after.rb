require '../models.rb'
# header lines need a blank line before and after them

# essay ID# 3327 is start of 2014 books 
Essay.where('id >= 3327').each do |e|
  if (e.content.nil? == false) && (e.content.include? '##')
    old_lines = e.content.split("\n")
    new_lines = []
    old_lines.each_with_index do |line, i|
      if line[0,2] == '##'
#       if (i > 0) && (old_lines[i - 1].strip != '')
#         new_lines << ''
#       end
        new_lines << line
        if (old_lines[i + 1].nil? == false) && (old_lines[i + 1].strip != '')
          new_lines << ''
        end
      else
	new_lines << line
      end
    end
    e.update(content: new_lines.join("\n"))
  end
  if (e.edited.nil? == false) && (e.edited.include? '##')
    old_lines = e.edited.split("\n")
    new_lines = []
    old_lines.each_with_index do |line, i|
      if line[0,2] == '##'
#       if (i > 0) && (old_lines[i - 1].strip != '')
#         new_lines << ''
#       end
        new_lines << line
        if (old_lines[i + 1].nil? == false) && (old_lines[i + 1].strip != '')
          new_lines << ''
        end
      else
	new_lines << line
      end
    end
    e.update(edited: new_lines.join("\n"))
  end
end
