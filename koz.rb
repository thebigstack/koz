#### require necessary gems ####
require 'sinatra' #Ruby framework for creating websites
require 'data_mapper' #enables working with databases
require 'shotgun' #restarts the server on every page refresh (used for development only)

#### define SQLite database using DataMapper ####
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/koz.db")

#define a class to facilitate account creation
class User
    include DataMapper::Resource
    property :id, Serial
    property :username, Text, :required => true
    property :password, Text, :required => true
    property :application, Text, :required => false #field allowing edit application comments
    property :date_joined, DateTime
    property :edit, Boolean, :required => true, :default => false
end
#define a class to allow creation of article edit logs
class Edit
    include DataMapper::Resource
    property :id, Serial
    property :bioedit, Text #Biography edit log
    property :skmedit, Text #Sun Kil Moon edit log
    property :rhpedit, Text #Red House Painters edit log
    property :soloedit, Text  #Solo edit log
end
#define a class to allow comments to be posted on the message board
class Board
    include DataMapper::Resource
    property :id, Serial  #post id (used for post deletion)
    property :comment, Text
    property :author, Text
end

DataMapper.finalize.auto_upgrade! #automatically update the database

#### define a function to confirm credentials ####
helpers do
  def protected!
    if authorized?
      return
    end
    redirect '/denied'
  end

  def authorized?
    if $credentials != nil
      @Userz = User.first(:username => $credentials[0])
      if @Userz
        if @Userz.edit == true
          return true
        else
          return false
        end
      else
        return false
      end
    end
  end

end

#### define url handlers ####

get '/' do #redirect the root to the homepage
  redirect '/home'
end

### menu handlers ###

get '/home' do
  erb :home #call home erb view
end

#define method to allow site to display an archive of all the edit files
require 'find'
def get_files(path)
    dir_list_array = Array.new
    Find.find(path) do |f|
        dir_list_array << File.basename(f, ".*") if !File.directory?(f) 
    end
    return dir_list_array
end 

get '/archive' do
  @arr = get_files('./archive/')  #use the get_files method to generate list of all files in archive
  erb :archive
end

get '/users' do
  @list3 = User.all :order => :id.desc #allow display of all users from newest to oldest
  erb :users
end

get '/about' do
  erb :about
end

get '/login' do
  erb :login
end

post '/login' do
  $credentials = [params[:username],params[:password]]
  @Users = User.first(:username => $credentials[0])
  if @Users
    if @Users.password == $credentials[1]
       redirect '/'
    else
       $credentials = ['','']
       redirect '/badlogin'
    end
  else
    $credentials =['','']
    redirect '/badlogin'
  end
end

get '/badlogin' do
  erb :badlogin
end

get '/noaccount' do
  erb :noaccount
end

get '/user/:uzer' do
    @Userz = User.first(:username => params[:uzer])
    if @Userz != nil
        erb :profile
    else
        redirect '/noaccount'
    end
end

put '/user/:uzer' do
    n = User.first(:username => params[:uzer])
    n.edit = params[:edit] ? 1 : 0
    n.save
    redirect '/'
end
get '/user/delete/:uzer' do
    protected!
    n = User.first(:username => params[:uzer])
    if n.username == "Admin"
        erb :denied
    else
        n.destroy
        @list2 = User.all :order => :id.desc
        erb :admincontrols
    end
end

get '/admincontrols' do
    protected!
    @list2 = User.all :order => :id.desc
    erb :admincontrols
end

post '/admincreate' do
    protected!
    n = User.new
    n.username = params[:username]
    n.password = params[:password]
    n.date_joined = Time.now.asctime
    n.save
    redirect '/admincontrols'
end

get '/createaccount' do
  erb :createaccount
end

post '/createaccount' do
    n = User.new
    n.username=params[:username]
    n.password=params[:password]
    n.application=params[:application]
    n.date_joined=Time.now.asctime
    if n.username == "Admin" and n.password == "Password"
        n.edit = true
    end
    n.save
    redirect '/'
end

get '/logout' do
    $credentials = ['','']
    redirect '/'
end

### content handlers ###

get '/bio' do #Biography page
    info = ""
    file = File.open("bio.txt") #open the relevant article text file
    file.each do |line|
        info=info+line
    end
    file.close #close file
    @info = info #define an instance variable with the input
    $bio = @info #convert into a global variable

    @words = info.split.count #define a instance variable for the article with value equal to the number of words in the article

    erb :bio
end

put '/bio' do
  protected!
  info = "#{params[:message]}"
  @info = info
  file = File.open("bio.txt","w") #open article text and prepare for writing
  file.puts @info
  file.close
  @time = Time.now.asctime #generate a time snapshot if an edit is made
  
  n = Edit.new
  n.bioedit = @bio_edit #define new database entry in bioedit column
  n.save #save the database
  file = File.open("archive/BioLog_#{@time}.txt", "w") #create an archive file of the article with the time of creation in the name
  file.puts @info #write article input to the new file
  file.close #close file
    
  file = File.open("biolog.txt", "a") #open and append the log file
  file.puts "#################################################"
  file.puts "NEW EDIT ENTRY: 'BioLog_#{@time}'" #write the new edit iteration to the log file
  file.puts ""
  file.puts @info #add new article input
  file.puts ""
  file.close
  
  redirect '/bio'
end

#define route for admin to resett article to default
get '/bioreset' do
    protected!
    file = File.open('default/biodefault.txt', 'r') #open default version as read only
    @content = file.read
    file.close
    file = File.open('bio.txt', 'w')  #open the existing version
    file.puts @content #overwrite current article with default version
    file.close
    redirect '/bio'
end

get '/skm' do
    info = ""
    file = File.open("skm.txt")
    file.each do |line|
        info=info+line
    end
    file.close
    @info = info
    $skm = @info

    @words = info.split.count

    erb :skm
end

put '/skm' do
  protected!
  info = "#{params[:message]}"
  @info = info
  file = File.open("skm.txt","w")
  file.puts @info
  file.close
  @time = Time.now.asctime
  
  n = Edit.new
  n.skmedit = @skm_edit
  n.save
  file = File.open("archive/SkmLog_#{@time}.txt", "w")
  file.puts @info
  file.close
    
  file = File.open("skmlog.txt", "a")
  file.puts "#################################################"
  file.puts "NEW EDIT ENTRY: 'SkmLog_#{@time}'"
  file.puts ""
  file.puts @info #add new article input
  file.puts ""
  file.close
  
  redirect '/skm'
end

get '/skmreset' do
    protected!
    file = File.open('default/skmdefault.txt', 'r')
    @content = file.read
    file.close
    file = File.open('skm.txt', 'w')
    file.puts @content
    file.close
    redirect '/skm'
end

get '/rhp' do
    info = ""
    file = File.open("rhp.txt")
    file.each do |line|
        info=info+line
    end
    file.close
    @info = info
    $rhp = @info

    @words = info.split.count

    erb :rhp
end

put '/rhp' do
  protected!
  info = "#{params[:message]}"
  @info = info
  file = File.open("rhp.txt","w")
  file.puts @info
  file.close
  @time = Time.now.asctime
  
  n = Edit.new
  n.rhpedit = @rhp_edit
  n.save #save database
  file = File.open("archive/RhpLog_#{@time}.txt", "w")
  file.puts @info
  file.close
    
  file = File.open("rhplog.txt", "a")
  file.puts "#################################################"
  file.puts "NEW EDIT ENTRY: 'RhpLog_#{@time}'"
  file.puts ""
  file.puts @info
  file.puts ""
  file.close
  
  redirect '/rhp'
end

get '/rhpreset' do
    protected!
    file = File.open('default/rhpdefault.txt', 'r')
    @content = file.read
    file.close
    file = File.open('rhp.txt', 'w')
    file.puts @content
    file.close
    redirect '/rhp'
end

get '/solo' do
    info = ""
    file = File.open("solo.txt")
    file.each do |line|
        info=info+line
    end
    file.close
    @info = info
    $solo = @info

    @words = info.split.count

    erb :solo
end

put '/solo' do
  protected!
  info = "#{params[:message]}"
  @info = info
  file = File.open("solo.txt","w")
  file.puts @info
  file.close
  @time = Time.now.asctime
  
  n = Edit.new
  n.soloedit = @solo_edit
  n.save
  file = File.open("archive/SoloLog_#{@time}.txt", "w")
  file.puts @info
  file.close
    
  file = File.open("sololog.txt", "a")
  file.puts "#################################################"
  file.puts "NEW EDIT ENTRY: 'SoloLog_#{@time}'"
  file.puts ""
  file.puts @info
  file.puts ""
  file.close
  
  redirect '/solo'
end

get '/soloreset' do
    protected!
    file = File.open('default/solodefault.txt', 'r')
    @content = file.read
    file.close
    file = File.open('solo.txt', 'w')
    file.puts @content
    file.close
    redirect '/solo'
end

get '/board' do
  @comments = Board.all :order => :id.asc #display comments oldest to newest
  erb :board
end

put '/boardpost' do
    x = "#{params[:posted_message]}"  #comment
    y = $credentials[0] #username
    n = Board.new
    n.comment = x #writes new entry in database in comment column
    n.author = y #writes the username to the database in the author column
    n.save
    redirect '/board'
end

#add an admin feature to delete comments
post '/deletecomment'do 
    @x = "#{params[:id]}" #comment id numbers
    n = Board.first(:id => @x)
    n.destroy #delete the database entry
    @commentlist = Board.all :order => :id.asc
    redirect '/board'
end

### misc handlers ###

get '/denied' do
  erb :denied
end

get '/notfound' do
  erb :notfound
end

not_found do
  status 404
  redirect '/notfound'
end