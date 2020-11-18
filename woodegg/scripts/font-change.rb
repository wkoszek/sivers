require '../models.rb'
# Essays with Chinese, Japanese, Korean, or Thai fonts need to have tags before and after them. 
# The after tag is always {latinfont}
# http://www.ruby-doc.org/core-2.0.0/Regexp.html - Ruby Regexp for finding them:
# {chinesefont} = /\p{Han}/
# {japanesefont} = /\p{Hiragana}/ || /\p{Katakana}/ ?
#   maybe  /([一-龠]+|[ぁ-ゔ]+|[ァ-ヴー]+|[ａ-ｚＡ-Ｚ０-９]+[々〆〤]+)/u but not catching chars like 。
# {koreanfont} = /\p{Hangul}/
# {thaifont} = /\p{Thai}/

puts "\nCHINESE:"
%w(CN HK SG TW).each do |cc|
  book = Book.where(country: cc).order(:id).last
  re = /(\p{Han}+)/
  book.essays.each do |sa|
    if sa.edited && re === sa.edited
      new_edited_text = sa.edited.gsub(re, '{chinesefont}\1{latinfont}')
      sa.update(edited: new_edited_text)
      print "#{sa.id} "
    end
  end
end

puts "\nJAPANESE:"
book = Book.where(country: 'JP').order(:id).last
book.essays.each do |sa|
  if sa.edited && (/\p{Hiragana}/ === sa.edited || /\p{Katakana}/ === sa.edited)
    print "#{sa.id} "
  end
end

puts "\nKOREAN:"
book = Book.where(country: 'KR').order(:id).last
re = /(\p{Hangul}+)/
book.essays.each do |sa|
  if sa.edited && re === sa.edited
    new_edited_text = sa.edited.gsub(re, '{koreanfont}\1{latinfont}')
    sa.update(edited: new_edited_text)
    print "#{sa.id} "
  end
end

puts "\nTHAI:"
book = Book.where(country: 'TH').order(:id).last
book.essays.each do |sa|
  if sa.edited && /\p{Thai}/ === sa.edited
    print "#{sa.id} "
  end
end

