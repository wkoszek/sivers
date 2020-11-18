include ERB::Util

class WoodEggEdit < Sinatra::Base

  configure do
    # set root one level up, since this routes file is inside subdirectory
    set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
    set :views, Proc.new { File.join(root, 'views/edit') }
  end

  use Rack::Auth::Basic, 'Wood Egg Editor' do |username, password|
    @@editor = Editor.find_by_email_pass(username, password)
  end

  before do
    redirect '/contact' if @@editor.nil?        # HACK: should say to contact me for password
    @editor = @@editor
    # Making this one book per editor, since that's the new deal.  If that changes, this changes:
    @book = @editor.book
    @todo_count = @editor.todo_count
    @done_count = @editor.done_count
  end

  get '/' do
    @unwritten = @book.howmany_essays_remain
    @pagetitle = 'HOME'
    erb :home
  end

  get '/next' do
    e = @editor.next_todo_essay
    if e.nil?
      redirect '/edit/'
    else
      redirect '/edit/essay/%d' % e.id
    end
  end

  get '/essay/:id' do
    @essay = Essay[params[:id]]
    redirect '/edit/' unless @essay.book == @book
    @question = @essay.question.question
    @answers = @essay.question.answers
    @content = (@essay.edited.nil? || @essay.edited.empty?) ? @essay.content : @essay.edited
    @rows = (@content.size / 80) + @content.split("\n").count
    @pagetitle = @question
    erb :essay
  end

  put '/essay/:id' do
    e = Essay[params[:id]]
    e.update(edited: params[:content].strip)
    if params[:submit] =~ /FINISHED/
      e.update(edited_at: Time.now)
      if params[:submit] =~ /STOP/
	redirect '/edit/'
      else
	redirect '/edit/next'
      end
    end
    redirect '/edit/essay/%d' % e.id
  end

  get '/todo' do
    @pagetitle = 'TO DO'
    questions = @editor.todo_questions
    topichash = Question.topichash(@book.country)
    @topicnest = Question.topicnest(questions, topichash)
    @question_to_essay_map = @editor.questions_id_map(@editor.todo_dataset)
    erb :questions
  end

  get '/done' do
    @pagetitle = 'DONE'
    questions = @editor.done_questions
    topichash = Question.topichash(@book.country)
    @topicnest = Question.topicnest(questions, topichash)
    @question_to_essay_map = @editor.questions_id_map(@editor.done_dataset)
    erb :questions
  end

  get '/editor-help' do
    root = File.dirname(File.dirname(File.realpath(__FILE__)))
    @markdowntut = File.read(File.join(root, 'doc/markdowntut.markdown'))
    @pagetitle = 'HELP'
    erb :help
  end

end
