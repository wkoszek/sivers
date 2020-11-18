#encoding: utf-8
require 'kramdown'
include ERB::Util

class WoodEggET < Sinatra::Base

  configure do
    # set root one level up, since this routes file is inside subdirectory
    set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
    set :views, Proc.new { File.join(root, 'views/et') }
    # re-use the Q&A public CSS
    set :public_folder, Proc.new { File.join(root, 'public-qa') }
  end

  use Rack::Auth::Basic, 'WoodEgg Editor Test' do |email, id|
    @@person = Person.find(id: id, email: email)
  end

  before do
    pass if request.path_info == '/country'
    @countries = @@person.countries_with_statvalue('14e')
    redirect '/et/country' unless @countries.count > 0
    @country_questions = TestEssay.question_pairs_for(@countries)
    @question_ids = TestEssay.question_ids_for(@countries)
    @person = @@person
  end

  get '/' do
    @pagetitle = 'START'
    @questions = Question.where(id: @question_ids).all
    @questions.each do |q|
      q[:finished] = TestEssay.for_editor_test_pq(@person.id, q.id).finished_at
    end
    erb :home
  end

  get %r{\A/question/([0-9]+)\Z} do |id|
    # tester can only do assigned questions.
    redirect '/et/' unless @question_ids.include? id.to_i
    @question = Question[id]
    @test_essay = TestEssay.for_editor_test_pq(@person.id, @question.id)
    @html = Kramdown::Document.new(@test_essay.content).to_html
    @pagetitle = @question.question
    erb :question
  end

  post %r{\A/question/([0-9]+)\Z} do |id|
    redirect '/et/' unless @question_ids.include? id.to_i
    t = TestEssay.for_editor_test_pq(@person.id, id)
    if params[:submit] == 'FINISHED'
      t.update(content: params[:content], finished_at: Time.now())
      redirect '/et/'
    else
      t.update(content: params[:content])
      redirect "/et/question/#{id}#youranswer"
    end
  end

  get '/help' do
    @pagetitle = 'HELP'
    erb :help
  end

  # just an error page:
  get '/country' do
    @pagetitle = 'MISSING COUNTRY'
    erb :country
  end


end
