#encoding: utf-8
include ERB::Util

class WoodEggWT < Sinatra::Base

  configure do
    # set root one level up, since this routes file is inside subdirectory
    set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
    set :views, Proc.new { File.join(root, 'views/wt') }
    # re-use the Q&A public CSS
    set :public_folder, Proc.new { File.join(root, 'public-qa') }
  end

  use Rack::Auth::Basic, 'WoodEgg Writer Test' do |email, id|
    @@person = Person.find(id: id, email: email)
  end

  before do
    pass if request.path_info == '/country'
    @userstat = @@person.userstats_dataset.select(:statkey).where(statvalue: '14w').first
    redirect '/wt/country' if @userstat.nil?
    /\Awoodegg-([a-z]{2})\Z/.match @userstat[:statkey]
    redirect '/wt/country' if $1.nil?
    @country = $1.upcase
    @person = @@person
    # template_ids = [130, 200]
    # cc_qids = {'KH'=>[108, 178], 'CN'=>[329, 399], 'HK'=>[532, 602], 'IN'=>[753, 823], 'ID'=>[962, 1032], 'JP'=>[1169, 1239], 'KR'=>[1370, 1440], 'MY'=>[1579, 1649], 'MN'=>[1985, 2055], 'MM'=>[1784, 1854], 'PH'=>[2190, 2260], 'SG'=>[2403, 2473], 'LK'=>[2602, 2672], 'TW'=>[2807, 2877], 'TH'=>[3014, 3084], 'VN'=>[3221, 3291]}
    template_ids = [112]
    cc_qids = {'KH'=>[90], 'CN'=>[311], 'HK'=>[514], 'IN'=>[735], 'ID'=>[944], 'JP'=>[1151], 'KR'=>[1352], 'MY'=>[1561], 'MM'=>[1766], 'MN'=>[1967], 'SG'=>[2385], 'LK'=>[2584], 'TW'=>[2789], 'TH'=>[2996], 'VN'=>[3203], 'PH'=>[2172]}
    @question_ids = cc_qids[@country]
  end

  get '/' do
    @pagetitle = 'START'
    @questions = Question.where(id: @question_ids).all
    @questions.each do |q|
      q[:finished] = TestEssay.for_pq(@person.id, q.id).finished_at
    end
    erb :home
  end

  get %r{\A/question/([0-9]+)\Z} do |id|
    # tester can only do assigned questions.
    redirect '/wt/' unless @question_ids.include? id.to_i
    @question = Question[id]
    @answers = @question.answers
    @test_essay = TestEssay.for_pq(@person.id, @question.id)
    @pagetitle = @question.question
    erb :question
  end

  post %r{\A/question/([0-9]+)\Z} do |id|
    redirect '/wt/' unless @question_ids.include? id.to_i
    t = TestEssay.for_pq(@person.id, id)
    if params[:submit] == 'FINISHED'
      t.update(content: params[:content], finished_at: Time.now())
      redirect '/wt/'
    else
      t.update(content: params[:content])
      redirect "/wt/question/#{id}#youranswer"
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
