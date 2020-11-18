#encoding: utf-8
include ERB::Util

class WoodEggQA < Sinatra::Base

  configure do
    # set root one level up, since this routes file is inside subdirectory
    set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
    set :views, Proc.new { File.join(root, 'views/qa') }
    set :public_folder, Proc.new { File.join(root, 'public-qa') }
  end

  use Rack::Auth::Basic, 'WoodEgg QA' do |username, password|
    @@researcher = Researcher.find_by_email_pass(username, password)
  end

  before do
    redirect '/contact' if @@researcher.nil?    # HACK: should say to contact me for password
    @researcher = @@researcher
    @qacc = @researcher.countries
  end

  get '/' do
    if @qacc.size == 1
      redirect "/qa/#{@qacc.pop.downcase}"
    else
      @pagetitle = @researcher.name
      erb :choose_country
    end
  end

  get Regexp.new(Countries.routemap) do |cc|
    @country_code = cc
    @ccode = cc.upcase
    @cname = Countries.hsh[@ccode]
    @pagetitle = @cname
    @country_name = @cname.gsub(' ', '&nbsp;')
    @topics = @researcher.topics_unfinished
    erb :topics
  end

  get Regexp.new(Countries.routemap2) do |cc, topic_id|
    @country_code = cc
    @ccode = cc.upcase
    @cname = Countries.hsh[@ccode]
    @country_name = @cname.gsub(' ', '&nbsp;')
    @topic = Topic[topic_id]
    @pagetitle = @topic.topic
    @subtopics = @researcher.subtopics_unfinished_in_topic(@topic.id)
    @questions_for_subtopic = {}
    @subtopics.each do |s|
      @questions_for_subtopic[s.id] = @researcher.questions_unfinished_in_subtopic(s.id)
    end
    erb :subtopics
  end

  get '/answers/unfinished' do
    @pagetitle = 'Unfinished'
    @answers = @researcher.answers_unfinished
    erb :answers
  end

  get '/answers/finished' do
    @pagetitle = 'Finished'
    @answers = @researcher.answers_finished
    erb :answers
  end

  get %r{\A/question/([0-9]+)\Z} do |id|
    @q = Question[id]
    redirect('/qa/', 301) if @q.nil?
    @ccode = @q.country
    @cname = Countries.hsh[@ccode]
    @pagetitle = @q.question
    erb :question
  end

  post '/answer' do
    a = Answer.find(researcher_id: @researcher.id, question_id: params[:question_id])
    if a.nil?
      a = Answer.create(researcher_id: @researcher.id, question_id: params[:question_id], started_at: Time.now)
    end
    redirect "/qa/answer/#{a.id}"
  end

  get %r{\A/answer/([0-9]+)\Z} do |id|
    @answer = Answer[id]
    redirect '/' if @answer.nil?
    @question = @answer.question
    @pagetitle = @question.question
    @cname = Countries.hsh[@question.country]
    @subtopic = @question.template_question.subtopic
    erb :answer
  end

  post %r{\A/answer/([0-9]+)\Z} do |id|
    a = Answer[id]
    # if payable was marked false, then researcher updating it now will change payable to nil, so we can review it
    # but if it was already true, then it stays true
    payable = (a.payable) ? true : nil
    if params[:submit] =~ /FINISH/
      a.update(answer: params[:answer], sources: params[:sources], payable: payable, finished_at: Time.now)
      redirect '/qa/answers/finished'
    else
      a.update(answer: params[:answer], sources: params[:sources], payable: payable)
      redirect "/qa/answer/#{a.id}"
    end
  end

  get '/help' do
    @pagetitle = 'HELP'
    erb :help
  end

  get %r{\A/upload/([0-9]+)\Z} do |id|
    @upload = Upload[id]
    redirect '/qa/upload' unless @upload.researcher == @researcher
    @pagetitle = 'UPLOADED FILE: %s' % @upload.our_filename
    @downlink = ''
    if @upload.uploaded == 'y'
      @downlink = ' (<a href="' + @upload.url + '">click here to download</a>)'
    end
    erb :upload
  end

  get '/upload' do
    @pagetitle = 'UPLOAD A FILE'
    erb :upload_form
  end

  put %r{\A/upload/([0-9]+)\Z} do |id|
    u = Upload[id]
    redirect '/qa/upload' unless u.researcher == @researcher
    u.update(notes: params[:notes], transcription: params[:transcription])
    redirect "/qa/upload/#{id}"
  end

  post '/upload' do
    @upload = Upload.post_from_researcher(@researcher.id, params['myfile'], params['notes'])
    erb :uploaded
  end

end
