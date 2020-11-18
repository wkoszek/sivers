Dir['r*'].sort.each do |f|
  /r([0-9]+)-([0-9]{4})([0-9]{2})([0-9]{2})/.match f
  researcher_id = $1.to_i
  created_at = '%s-%s-%s' % [$2, $3, $4]
  bytes = FileTest.size(f)
  mime_type = `file -ib #{f}`.split(';').shift
  sql = "INSERT INTO uploads (created_at, researcher_id, bytes, mime_type, their_filename, our_filename) VALUES "
  sql << "('#{created_at}', #{researcher_id}, #{bytes}, '#{mime_type}', 'via Dropbox', '#{f}');"
  puts sql
end
