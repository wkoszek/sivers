include ERB::Util
require 'kramdown'

class WoodEggA < Oth

  configure do
    # set root one level up, since this routes file is inside subdirectory
    set :root, File.dirname(File.dirname(File.realpath(__FILE__)))
    set :views, Proc.new { File.join(root, 'views/a') }
  end

  before Oth::ROUTEREG do
    oth!
    @customer = @person.woodegg_customer
  end

  get '/' do
    if @customer.nil?
      if @person.prepaid?
	@customer = WoodEgg::Customer.create_full_from @person
      else
	redirect "#{OTH_MAP}/proof"
      end
    end
    @pagetitle = 'account'
    erb :home
  end

  get '/proof' do
    @pagetitle = 'book registration'
    erb :proof
  end

  post '/proof' do
    if params[:book].nil? || WoodEgg::Book[code: params[:book]].nil? || params[:proof].nil? || params[:proof].empty?
      redirect "#{OTH_MAP}/proof"
    end
    @person.add_userstat(statkey: 'proof-' + params[:book], statvalue: params[:proof], created_at: Date.today)
    redirect "#{OTH_MAP}/thanks"
  end

  get '/thanks' do
    @pagetitle = 'thank you'
    erb :thanks
  end

  get %r{\A/book/(we1[3-9][a-z]{2})\Z} do |code|
    redirect "#{OTH_MAP}/proof" if @customer.nil?
    @book = WoodEgg::Book[code: code]
    redirect "#{OTH_MAP}/" unless @customer.books.include? @book
    @pagetitle = @book.short_title
    erb :book
  end

  get %r{\A/book/(we1[3-9][a-z]{2})/questions/([0-9]+)\Z} do |code, id|
    redirect "#{OTH_MAP}/proof" if @customer.nil?
    @book = WoodEgg::Book[code: code]
    redirect "#{OTH_MAP}/" unless @customer.books.include? @book
    @question = @book.questions.find {|b| b[:id] == id.to_i}
    redirect "#{OTH_MAP}/book/#{code}" unless @question
    @pagetitle = @book.short_title + ' QUESTION: ' + @question.question
    @essay = Kramdown::Document.new(@question.essays[0].content).to_html
    erb :book_question
  end

  get %r{\A/book/(we1[3-9][a-z]{2})/(pdf|epub|mobi)/\S+\Z} do |code, fmt|
    redirect "#{OTH_MAP}/proof" if @customer.nil?
    book = WoodEgg::Book[code: code]
    redirect "#{OTH_MAP}/" unless @customer.books.include? book
    download_url = book.download_url(fmt)
    redirect "#{OTH_MAP}/book/#{code}" unless download_url
    redirect download_url
  end

end
