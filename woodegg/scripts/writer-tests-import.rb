require '../models.rb'

Writer.filter(active: true).each do |w|
  book = w.books[0]
  w.person.test_essays.each do |t|
    h = {
      writer_id: w.id,
      question_id: t.question_id,
      started_at: Time.now,
      content: t.content,
      book_id: book.id}
    Essay.create(h)
  end
end
