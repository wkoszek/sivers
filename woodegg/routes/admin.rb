require 'erb'
include ERB::Util
require 'sinatra'
require 'kramdown'
root = File.dirname(File.dirname(File.realpath(__FILE__)))
require "#{root}/models.rb"

configure do
  set :root, root
  set :views, Proc.new { File.join(root, 'views/admin') }
end

use Rack::Auth::Basic, 'WoodEgg Admin' do |username, password|
  HTTPAuth.person = Person.find_by_email_pass(username, password)
end

before do
  redirect '/' unless HTTPAuth.person.admin?
  @person = HTTPAuth.person
  @bodyid = 'admin'
end

# of submitted params, get only the ones with these keys
# USAGE:
#   Thought.update(just(%w(author_id contributor_id created_at source_url)))
def just(keyz)
  params.select {|k, v| keyz.include? k}
end


##################  HOME, PURCHASE PROOF, STATS, TEST ESSAYS, INTERVIEWEES

get '/' do
  @pagetitle = 'home'
  @userstats = Userstat.filter(Sequel.like(:statkey, 'proof%')).all
  erb :home
end

post '/proof' do
  u = Userstat[params[:uid]]
  raise('no Userstat for %d' % params[:uid]) if u.nil?
  if params[:submit] == 'no'
    u.update(statkey: u.statkey.gsub('proof', 'nope'))
    redirect '/'
  else
    p = u.person
    raise('no Person for u %d with person_id %d' % [u.id, u.person_id]) if p.nil?
    c = p.woodegg_customer
    # if they weren't a customer before, they are now!
    if c.nil?
      c = WoodEgg::Customer.create(person_id: p.id)
      has_books = []
    else
      has_books = c.books
    end
		b = WoodEgg::Book[33]
   	c.add_book(b) unless has_books.include? b
    c.email_post_proof(b)
    u.update(statkey: u.statkey.gsub('proof', 'bought'))
    redirect '/'
  end
end

get '/stats' do
  @pagetitle = 'stats'
  @grid = Countries.userstats_grid
  @person_url_d = WoodEgg.config['woodegg_person_url']
  @newest = Userstat.newest_woodegg
  erb :stats
end

get '/stats/:country/:val' do
  @country_code = params[:country]
  @country_name = Countries.hsh[@country_code] || 'Any Country'
  @val = params[:val]
  @pagetitle = @country_name + ' ' + @val
  @people = Person.country_val(@country_code, @val)
  @person_url_d = WoodEgg.config['woodegg_person_url']
  erb :stats2
end

get '/test_essays' do
  @pagetitle = 'TEST ESSAYS'
  erb :test_essays
end

get '/test_essays/all' do
  @pagetitle = 'ALL TEST ESSAYS'
  @essays = WoodEgg::TestEssay.finished_with_names
  erb :test_essays_all
end

get '/test_essays/et' do
  @pagetitle = 'EDITOR TEST ESSAYS'
  @countries = WoodEgg::TestEssay.editor_tests_by_country
  erb :test_essays_et
end

get %r{\A/person/([0-9]+)/test_essays\Z} do |id|
  @p = Person[id]
  @person_url = WoodEgg.config['woodegg_person_url'] % id
  @tes = @p.test_essays
  @pagetitle = @p.name
  erb :person_test_essays
end

get %r{\A/test_essay/([0-9]+)\Z} do |id|
  @te = WoodEgg::TestEssay[id]
  @q = @te.question
  @pagetitle = "TEST ESSAY #{id}"
  @p = @te.person
  # ugly hack: if person is me, edit the essay itself
  if @p.id == 1
    @html = Kramdown::Document.new(@te.content).to_html
    erb :test_essay_edit
  elsif @te.id > 317  # if editor test, show that view
    @orig = WoodEgg::TestEssay.for_country(@te.country)
    @html = Kramdown::Document.new(@te.content).to_html
    erb :test_essay_et
  else  # otherwise, just edit notes
    @as = @q.answers
    erb :test_essay
  end
end

put %r{\A/test_essay/([0-9]+)\Z} do |id|
  te = WoodEgg::TestEssay[id]
  # ugly hack: if person is me, edit the essay itself
  if te.person_id == 1
    te.update(content: params[:content], notes: params[:notes])
  else  # otherwise, just edit notes
    te.update(notes: params[:notes])
  end
  redirect "/test_essay/#{te.id}"
end

get '/interviewees' do
  @country_people = Person.interviewees
  @pagetitle = 'INTERVIEWEES'
  erb :interviewees
end

get %r{\A/interviewee/([0-9]+)\Z} do |id|
  @p = Person[id]
  @bio = @p.interviewee_bio
  @person_url_ds = WoodEgg.config['person_url'] % id
  @person_url_we = WoodEgg.config['woodegg_person_url'] % id
  @pagetitle = 'INTERVIEWEE: ' + @p.name
  erb :interviewee
end

put %r{\A/interviewee/([0-9]+)\Z} do |id|
  p = Person[id]
  p.set_interviewee_bio(params[:bio])
  redirect '/interviewees#%d' % id
end

###################### BOOKS

get '/books' do
  @pagetitle = 'books'
  @new_books = WoodEgg::Book.filter('id > 16').order(:id).all
  @old_books = WoodEgg::Book.filter('id <= 16').order(:id).all
  erb :books
end

get %r{\A/book/([0-9]+)\Z} do |id|
  @book = WoodEgg::Book[id]
  @pagetitle = @book.short_title
  @done = @book.done?
  unless @done
    @questions_missing_essays = @book.questions_missing_essays
    @essays_unedited = @book.essays_unedited.all
  end
  @questions = @book.questions
  @essays = @book.essays
  @researchers = @book.researchers
  @writers = @book.writers
  @editors = @book.editors
  erb :book
end

put %r{\A/book/([0-9]+)\Z} do |id|
  b = WoodEgg::Book[id]
  b.update(just(%w(title isbn asin apple leanpub intro salescopy credits pages)))
  redirect '/book/%d' % b.id
end

get %r{\A/book/([0-9]+)/questions\Z} do |id|
  @book = WoodEgg::Book[id]
  @pagetitle = @book.short_title + ' questions'
  @topicnest = WoodEgg::Question.topicnest(@book.questions, WoodEgg::Question.topichash(@book.country))
  erb :questions
end

get %r{\A/book/([0-9]+)/essays\Z} do |id|
  @book = WoodEgg::Book[id]
  @pagetitle = @book.short_title + ' essays'
  @essays = @book.essays
  @question_for_essay = WoodEgg::Question.for_these(@essays)
  erb :essays
end

# Search & Replace 
# GET = no params?  just show form
# GET has params[:q]? search edited for it & show results
# GET has params[:nu]? replace results with it
get %r{\A/book/([0-9]+)/gsub\Z} do |id|
  @book = WoodEgg::Book[id]
  @pagetitle = @book.short_title + ' — Search and Replace'
  @q = params[:q]
  @essays = (@q) ? @book.essays_with_text(@q) : []
  @nu = params[:nu]
  @new_essays = (@nu) ? @essays.map {|e| e.edited_gsub(@q, @nu)} : []
  erb :gsub
end

# Search & Replace
# POST q and nu to make the change. Redirect with nu now value of ?q
post %r{\A/book/([0-9]+)/gsub\Z} do |id|
  b = WoodEgg::Book[id]
  b.essays_with_text(params[:q]).each do |e|
    e.update(edited: e.edited_gsub(params[:q], params[:nu]))
  end
  redirect '/book/%d/gsub?q=%s' % [b.id, URI.escape(params[:nu])]
end

get %r{\A/book/([0-9]+)/essay\Z} do |book_id|
  b = WoodEgg::Book[book_id]
  e = b.essays[0]
  redirect '/book/%d/essay/%d' % [b.id, e.id]
end

# Final tweaking - editing only the "essays.edited" field, with JavaScript tools
get %r{\A/book/([0-9]+)/essay/([0-9]+)\Z} do |book_id, essay_id|
  @book = WoodEgg::Book[book_id]
  @essay = WoodEgg::Essay[essay_id]
  @question = @essay.question
  @prev = @book.essay_before(@essay)
  @next = @book.essay_after(@essay)
  @pagetitle = @book.short_title + ': ' + @question.question
  @bodyid = 'fullscreen'
  erb :tweak
end

put %r{\A/book/([0-9]+)/essay/([0-9]+)\Z} do |book_id, essay_id|
  WoodEgg::Essay[essay_id].update(edited: params[:edited])
  redirect '/book/%d/essay/%d' % [book_id, essay_id]
end

get %r{\A/book/([0-9]+)/preview\Z} do |id|
  @book = WoodEgg::Book[id]
  @topicnest = WoodEgg::Question.topicnest(@book.questions, Question.topichash(@book.country))
  @pagetitle = @book.short_title
  erb :preview
end

################ ESSAYS, ANSWERS, QUESTIONS

get '/answers' do
  @pagetitle = 'ANSWERS - summary by status'
  @unjudged_count = WoodEgg::Answer.unjudged_count
  @unfinished_count = WoodEgg::Answer.unfinished_count
  erb :answers_summary
end

get '/answers/unfinished' do
  @answers = WoodEgg::Answer.unfinished
  @pagetitle = 'UNFINISHED ANSWERS'
  erb :answers_unfinished
end

get '/answers/unjudged' do
  @answers = WoodEgg::Answer.unjudged
  @pagetitle = 'UNJUDGED ANSWERS'
  erb :answers_unjudged
end

get '/answer/unjudged' do
  @unjudged_count = WoodEgg::Answer.unjudged_count
  redirect '/answers' if @unjudged_count == 0
  @answer = WoodEgg::Answer.unjudged_next
  @question = @answer.question
  @researcher = @answer.researcher
  @pagetitle = 'unjudged answer'
  erb :answer_unjudged
end

put %r{\A/answer/([0-9]+)/judge\Z} do |id|
  a = WoodEgg::Answer[id]
  if params[:payable] == 'yes'
    a.update(payable: true)
  else
    # if payable is NO, then erase finished_at timestamp
    a.update(payable: false, finished_at: nil)
  end
  redirect '/answer/unjudged'
end

get '/essays' do
  @pagetitle = 'ESSAYS - summary by status'
  @unjudged_count = WoodEgg::Essay.unjudged_count
  @unfinished_count = WoodEgg::Essay.unfinished_count
  erb :essays_summary
end

get '/essay/unjudged' do
  @unjudged_count = WoodEgg::Essay.unjudged_count
  redirect '/essays' if @unjudged_count == 0
  @essay = WoodEgg::Essay.unjudged_next
  @html = Kramdown::Document.new(@essay.content).to_html
  @question = @essay.question
  @writer = @essay.writer
  @pagetitle = 'unjudged essay'
  erb :essay_unjudged
end

get %r{\A/essay/([0-9]+)\Z} do |id|
  @essay = WoodEgg::Essay[id]
  @pagetitle = 'essay #%d' % @essay.id
  @html = Kramdown::Document.new(@essay.edited).to_html
  erb :essay
end

put %r{\A/essay/([0-9]+)\Z} do |id|
  e = WoodEgg::Essay[id]
  fields = %w(editor_id started_at finished_at payable edited_at content edited)
  fields.each do |f|
    # ignore empty fields - don't treat empty string as value
    params.delete(f) if params[f].empty?
  end
  e.update(just(fields))
  redirect '/essay/%d' % e.id
end

put %r{\A/essay/([0-9]+)/judge\Z} do |id|
  e = WoodEgg::Essay[id]
  if params[:payable] == 'yes'
    e.update(payable: true)
  else
    # [no] button needs reason:
    if params[:reason].empty?
      redirect '/essay/unjudged'
    else
      # email reason to writer
      h = {person: e.writer.person,
	subject: "please update essay ##{id}",
        category: 'woodegg',
	by: @person.firstname.downcase,
        profile: 'we@woodegg'}
      h[:body] = "Please update the essay, below, next time you log in to https://woodegg.com/write/  (It will be in the UNFINISHED link in the top menu there.)\n\n"
      h[:body] << params[:reason]
      h[:body] << "\n\n============\n#{e.question.question}\n============\n#{e.content}\n=============\n\n"
      h[:body] << "No need to reply to this email. But of course, feel free any questions. Thank you!"
      Email.new_to(h)
      # if payable is NO, then erase finished_at timestamp
      e.update(payable: false, finished_at: nil)
    end
  end
  redirect '/essay/unjudged'
end

get %r{\A/question/([0-9]+)\Z} do |id|
  @question = WoodEgg::Question[id]
  @pagetitle = 'question #%d' % @question.id
  erb :question
end

get %r{\A/answer/([0-9]+)\Z} do |id|
  @answer = WoodEgg::Answer[id]
  @pagetitle = 'answer #%d' % @answer.id
  @question = @answer.question
  @researcher = @answer.researcher
  erb :answer
end

put %r{\A/answer/([0-9]+)\Z} do |id|
  a = WoodEgg::Answer[id]
  params.delete 'finished_at' if params['finished_at'].strip == ''
  a.update(just(%w(started_at finished_at payable answer sources)))
  redirect '/answer/%d' % a.id
end

get '/template_questions' do
  @tqs = WoodEgg::TemplateQuestion.order(:id).all
  @pagetitle = 'TEMPLATE QUESTIONS'
  erb :template_questions
end

get %r{\A/template_question/([0-9]+)\Z} do |id|
  @tq = WoodEgg::TemplateQuestion[id]
  @questions = @tq.questions
  erb :template_question
end



################## RESEARCHERS, WRITERS, EDITORS - each URL type together, since so similar

get '/researchers' do
  # note order of things here. adding properies to researchers & books for stats chart
  @books_not_done = WoodEgg::Book.filter('id > 16')  # TEMP
  @active = WoodEgg::Researcher.all_people(active: true).sort_by(&:name)
  WoodEgg::Researcher.add_answer_count(@active)
  @inactive = WoodEgg::Researcher.all_people(active: false).sort_by(&:name)
  @books_researchers = WoodEgg::Researcher.group_by_book(@active)
  WoodEgg::Book.add_answer_count(@books_not_done, @books_researchers)
  @pagetitle = 'researchers'
  erb :researchers
end

get '/writers' do
  @pagetitle = 'writers'
  @active = WoodEgg::Writer.filter(active: true).order(:id).all
  @inactive = WoodEgg::Writer.filter(active: false).order(:id).all
  erb :writers
end

get '/editors' do
  @pagetitle = 'editors'
  @editors = WoodEgg::Editor.order(:id).all
  @active = WoodEgg::Editor.filter('id > 1').order(:id).all
  @inactive = WoodEgg::Editor.filter('id <= 1').order(:id).all
  erb :editors
end

get %r{\A/researcher/([0-9]+)\Z} do |id|
  @researcher = WoodEgg::Researcher[id]
  @pagetitle = 'RESEARCHER: %s' % @researcher.name
  @person_url = WoodEgg.config['woodegg_person_url'] % @researcher.person_id
  @ok_to_delete = (@researcher.answers_dataset.count == 0) ? true : false
  @books2add = WoodEgg::Book.filter(asin: nil).order(:id).all - @researcher.books
  @uploads = @researcher.uploads
  erb :researcher
end

get %r{\A/writer/([0-9]+)\Z} do |id|
  @writer = WoodEgg::Writer[id]
  @pagetitle = 'WRITER: %s' % @writer.name
  @person_url = WoodEgg.config['woodegg_person_url'] % @writer.person_id
  @books2add = WoodEgg::Book.filter(asin: nil).order(:id).all - @writer.books
  erb :writer
end

get %r{\A/editor/([0-9]+)\Z} do |id|
  @editor = WoodEgg::Editor[id]
  @pagetitle = 'EDITOR: %s' % @editor.name
  @person_url = WoodEgg.config['woodegg_person_url'] % @editor.person_id
  erb :editor
end

get %r{\A/researcher/([0-9]+)/answers/(finished|unfinished|unpaid|unjudged)\Z} do |id,filtr|
  @researcher = WoodEgg::Researcher[id]
  @pagetitle = "#{filtr} answers for #{@researcher.name}"
  @answers = @researcher.send("answers_#{filtr}")
  @question_for_answers = WoodEgg::Question.for_these(@answers)
  erb :researcher_answers
end

get %r{\A/writer/([0-9]+)/essays/(finished|unfinished|unpaid|unjudged)\Z} do |id,filtr|
  @writer = WoodEgg::Writer[id]
  @pagetitle = "#{filtr} essays for #{@writer.name}"
  @essays = @writer.send("essays_#{filtr}")
  @question_for_essays = WoodEgg::Question.for_these(@essays)
  erb :writer_essays
end

get %r{\A/editor/([0-9]+)/essays/done} do |id|
  @editor = WoodEgg::Editor[id]
  @pagetitle = "Edited essays by #{@editor.name}"
  @essays = @editor.done_essays
  @question_for_essays = WoodEgg::Question.for_these(@essays)
  erb :editor_essays_done
end

get %r{\A/editor/([0-9]+)/essays/todo} do |id|
  @editor = WoodEgg::Editor[id]
  @questions = @editor.todo_questions
  @pagetitle = "Essays to edit by #{@editor.name}"
  erb :questions_nonest
end

post '/researchers' do
  x = WoodEgg::Researcher.create(person_id: params[:person_id].to_i)
  redirect '/researcher/%d' % x.id
end

post '/writers' do
  x = WoodEgg::Writer.create(person_id: params[:person_id].to_i)
  redirect '/writer/%d' % x.id
end

put %r{\A/researcher/([0-9]+)\Z} do |id|
  r = WoodEgg::Researcher[id]
  r.update(just(%w(bio)))
  redirect '/researcher/%d' % r.id
end

put %r{\A/writer/([0-9]+)\Z} do |id|
  x = WoodEgg::Writer[id]
  x.update(just(%w(bio)))
  redirect '/writer/%d' % x.id
end

put %r{\A/editor/([0-9]+)\Z} do |id|
  x = WoodEgg::Editor[id]
  x.update(just(%w(bio)))
  redirect '/editor/%d' % x.id
end

post %r{\A/researcher/([0-9]+)/books\Z} do |id|
  r = WoodEgg::Researcher[id]
  b = WoodEgg::Book[params[:book_id]]
  r.add_book(b) if b
  redirect '/researcher/%d' % r.id
end

post %r{\A/writer/([0-9]+)/books\Z} do |id|
  x = WoodEgg::Writer[id]
  b = WoodEgg::Book[params[:book_id]]
  x.add_book(b) if b
  redirect '/writer/%d' % x.id
end

post %r{\A/writer/([0-9]+)/approval\Z} do |id|
  x = WoodEgg::Writer[id]
  x.approve_finished_unjudged_essays
  redirect '/writer/%d' % x.id
end

post %r{\A/researcher/([0-9]+)/answers\Z} do |researcher_id|
  redirect "/researcher/#{researcher_id}" unless params[:question_id].to_i > 0
  a = WoodEgg::Answer.create(question_id: params[:question_id],
		    researcher_id: researcher_id,
		    started_at: Time.now(),
		    finished_at: Time.now(),
		    payable: true)
  redirect '/answer/%d' % a.id
end

delete %r{\A/researcher/([0-9]+)\Z} do |id|
  x = WoodEgg::Researcher[id]
  x.destroy
  redirect '/researchers'
end

delete %r{\A/writer/([0-9]+)\Z} do |id|
  x = WoodEgg::Writer[id]
  x.destroy
  redirect '/writers'
end


######################## CUSTOMERS

get '/customers' do
  @pagetitle = 'all customers'
  @customers = WoodEgg::Customer.order(:id).all
  @person_id = params[:person_id]
  erb :customers
end

post '/customers' do
  c = WoodEgg::Customer.create(person_id: params[:person_id])
  redirect '/customer/%d' % c.id
end

get %r{\A/book/([0-9]+)/customers\Z} do |id|
  @book = WoodEgg::Book[id]
  @pagetitle = 'customers of ' + @book.short_title
  @customers = @book.customers
  erb :customers
end

get %r{\A/customer/([0-9]+)\Z} do |id|
  @customer = WoodEgg::Customer[id]
  @pagetitle = 'customer: ' + @customer.name
  @books = @customer.books
  @books_to_add = WoodEgg::Book.where('id > 16').order(:title).all - @books
  @person_url = WoodEgg.config['woodegg_person_url'] % @customer.person_id
  @sent = params[:sent]
  erb :customer
end

post %r{\A/customer/([0-9]+)/books\Z} do |id|
  c = WoodEgg::Customer[id]
  has_books = c.books
  if params[:book_id] == 'all'
    WoodEgg::Book.available.each do |b|
      c.add_book(b) unless has_books.include? b
    end
  else
    b = WoodEgg::Book[params[:book_id]]
    unless b.nil?
      c.add_book(b) unless has_books.include? b
    end
  end
  redirect '/customer/%d' % c.id
end

post %r{\A/customer/([0-9]+)/email\Z} do |id|
  c = WoodEgg::Customer[id]
  c.email_first
  redirect '/customer/%d?sent=sent' % c.id
end



############# TIDBITS AND TAGS

get '/tidbits' do
  @pagetitle = 'tidbits'
  if params[:tag_id]
    @tag = WoodEgg::Tag[params[:tag_id]]
    @tidbits = @tag.tidbits
  else
    @tidbits = WoodEgg::Tidbit.order(Sequel.desc(:id)).all
  end
  @all_tags = WoodEgg::Tag.order(:id).all
  erb :tidbits
end

post '/tidbits' do
  t = WoodEgg::Tidbit.create(created_at: Time.now())
  redirect '/tidbit/%d' % t.id
end

get %r{\A/tidbit/([0-9]+)\Z} do |id|
  @tidbit = WoodEgg::Tidbit[id]
  @pagetitle = 'tidbit # %d' % @tidbit.id
  @all_tags = WoodEgg::Tag.order(:id).all - @tidbit.tags
  erb :tidbit
end

put %r{\A/tidbit/([0-9]+)\Z} do |id|
  t = WoodEgg::Tidbit[id]
  t.update(just(%w(created_at created_by headline url intro content)))
  redirect '/tidbit/%d' % t.id
end

delete %r{\A/tidbit/([0-9]+)\Z} do |id|
  t = WoodEgg::Tidbit[id]
  t.destroy
  redirect '/tidbits'
end

post %r{\A/tidbit/([0-9]+)/tags\Z} do |id|
  t = WoodEgg::Tidbit[id]
  # can post either tag_name, to make new, or tag_id, to use existing
  tag = nil
  if params[:tag_name].empty? == false
    tag = WoodEgg::Tag.create(name: params[:tag_name])
  elsif params[:tag_id].to_i > 0
    tag = WoodEgg::Tag[params[:tag_id]]
  end
  t.add_tag(tag) if tag
  redirect '/tidbit/%d' % t.id
end

post %r{\A/tidbit/([0-9]+)/questions\Z} do |id|
  t = WoodEgg::Tidbit[id]
  t.add_question(WoodEgg::Question[params[:question_id]])
  redirect '/tidbit/%d' % t.id
end

delete %r{\A/tidbit/([0-9]+)/tag/([0-9]+)\Z} do |id, tag_id|
  t = WoodEgg::Tidbit[id]
  t.remove_tag(WoodEgg::Tag[tag_id])
  redirect '/tidbit/%d' % t.id
end

delete %r{\A/tidbit/([0-9]+)/question/([0-9]+)\Z} do |id, question_id|
  t = WoodEgg::Tidbit[id]
  t.remove_question(WoodEgg::Question[question_id])
  redirect '/tidbit/%d' % t.id
end

################ UPLOADS

get '/uploads' do
  @uploads = WoodEgg::Upload.order(Sequel.desc(:created_at), Sequel.desc(:researcher_id)).all
  @rnames = {}
  WoodEgg::Researcher.all_people.each {|p| @rnames[p.id] = p.name}
  @pagetitle = 'UPLOADS'
  erb :uploads
end

get %r{\A/upload/([0-9]+)\Z} do |id|
  @upload = WoodEgg::Upload[id]
  @researcher = @upload.researcher
  @status_options = [''] + WoodEgg::Upload.statuses
  @downlink = ''
  if @upload.uploaded == 'y'
    @downlink = ' (<a href="' + @upload.url + '">click here to download</a>)'
  end
  @pagetitle = 'UPLOAD #%d' % id
  erb :upload
end

put %r{\A/upload/([0-9]+)\Z} do |id|
  u = WoodEgg::Upload[id]
  u.update(status: params[:status], notes: params[:notes], transcription: params[:transcription])
  #redirect '/upload/%d' % id
  redirect '/uploads'
end

