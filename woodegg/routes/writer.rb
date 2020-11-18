#encoding: utf-8

class WoodEggWriter < Sinatra::Base

  configure do
    # set root one level up, since this routes file is inside subdirectory
    set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
    set :views, Proc.new { File.join(root, 'views/writer') }
  end

  use Rack::Auth::Basic, 'Wood Egg Writer' do |username, password|
    @@writer = Writer.find_by_email_pass(username, password)
  end

  before do
    redirect '/contact' if @@writer.nil?    # HACK: should say to contact me for password
    @writer = @@writer
    @book = @writer.books[0]   # one book per-writer in 2013 
    @country = @book.country
  end

  get '/' do
    @pagetitle = @writer.name + ' stats'
    @stats = @book.writer_progress
    @remaining = @book.howmany_essays_remain
    @days_remaining = @book.days_remaining
    @ideal_today = @book.ideal_today
    erb :home
  end

  # /write/th-list /write/sg-list etc
  get %r{(#{Countries.hsh.keys.map(&:downcase).join('|')})-list} do |cc|
    @country_code = cc
    @ccode = cc.upcase
    @cname = Countries.hsh[@ccode]
    @country_name = @cname.gsub(' ', '&nbsp;')
    @book ||= @writer.newest_book_for_country(@ccode)
    @questions = Question.needing_essays_for_book(@book.id)
    @topichash = Question.topichash(@ccode)
    @topicnest = Question.topicnest(@questions, @topichash)
    @pagetitle = @cname
    erb :questions
  end

  get '/question/:id' do
    @q = Question[params[:id]]
    redirect('/write/', 301) if @q.nil?
    @answers = @q.answers
    @tidbits = @q.tidbits
    @ccode = @q.country
    @cname = Countries.hsh[@ccode]
    @pagetitle = @q.question
    erb :question
  end

  post '/essay' do
    x = Essay.find(writer_id: @writer.id, question_id: params[:question_id])
    if x.nil?
      cc = Question[params[:question_id]].country
      b = Book.filter(country: cc).order(:id).last
      x = Essay.create(writer_id: @writer.id, question_id: params[:question_id], book_id: b.id, started_at: Time.now)
    end
    redirect "/write/essay/#{x.id}"
  end

  get '/essay/:id' do
    @essay = Essay[params[:id]]
    redirect '/' if @essay.nil?
    @question = @essay.question
    @pagetitle = @question.question
    @answers = @question.answers
    @tidbits = @question.tidbits
    @cname = Countries.hsh[@question.country]
    @subtopic = @question.template_question.subtopic
    @bodyid = 'write'
    erb :essay
  end

  post '/essay/:id' do
    x = Essay[params[:id]]
    if params[:submit] =~ /FINISH/
      x.update(content: params[:content], finished_at: Time.now)
      redirect '/write/essays/finished'
    else
      x.update(content: params[:content])
      redirect "/write/essay/#{x.id}"
    end
  end

  get '/essays/unfinished' do
    @pagetitle = 'Unfinished'
    @essays = @writer.essays_unfinished
    erb :essays
  end

  get '/essays/finished' do
    @pagetitle = 'Finished'
    @essays = @writer.essays_finished
    erb :essays
  end

  get %r{/essays/(#{Countries.hsh.keys.map(&:downcase).join('|')})/unfinished} do |cc|
    @country_code = cc
    @ccode = cc.upcase
    @book ||= @writer.newest_book_for_country(@ccode)
    @pagetitle = 'Unfinished'
    @essays = @book.essays_unfinished
    erb :essays
  end

  get %r{/essays/(#{Countries.hsh.keys.map(&:downcase).join('|')})/finished} do |cc|
    ccode = cc.upcase
    book = @writer.newest_book_for_country(ccode)
    essays = book.essays_finished
    questions = Question.filter(id: essays.map(&:question_id))
    topichash = Question.topichash(ccode)
    @topicnest = Question.topicnest(questions, topichash)
    @question_to_essay_map = {}
    essays.each {|e| @question_to_essay_map[e.question_id] = e.id}
    @pagetitle = 'Finished'
    erb :essays_nested
  end

  get '/writer-help' do
    root = File.dirname(File.dirname(File.realpath(__FILE__)))
    @markdowntut = File.read(File.join(root, 'doc/markdowntut.markdown'))
    @pagetitle = 'HELP'
    erb :help
  end

end
