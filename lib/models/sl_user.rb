class SlUser
  include DataMapper::Resource

  property :id, Serial
  property :email, String, :length => (5..40), :unique => true, :format => :email_address
  property :hashed_password, String
  property :salt, String
  property :created_at, DateTime
  property :permission_level, Integer, :default => 1
  property :nickname,   String, :length => 255
  property :identifier, String, :length => 255
  property :photo_url,  String, :length => 255

  has n, :oohs
  has n, :direct_messages, :model => "Ooh"
  has n, :relationships
  has n, :followers, :through => :relationships, :model => "SlUser", :child_key => [:SlUser_id]
  has n, :follows, :through => :relationships, :model => "SlUser", :remote_name => :SlUser, :child_key => [:follower_id]   
  if Sinatra.const_defined?('FacebookObject')
    property :fb_uid, String
  end

  attr_accessor :password, :password_confirmation
  #protected equievelant? :protected => true doesn't exist in dm 0.10.0
  #protected :id, :salt
  #doesn't behave correctly, I'm not even sure why I did this.

  validates_present :password_confirmation, :unless => Proc.new { |t| t.hashed_password }
  validates_present :password, :unless => Proc.new { |t| t.hashed_password }
  validates_is_confirmed :password

  def password=(pass)
    @password = pass
    self.salt = SlUser.random_string(10) if !self.salt
    self.hashed_password = SlUser.encrypt(@password, self.salt)
  end

  def admin?
    self.permission_level == -1 || self.id == 1
  end

  def site_admin?
    self.id == 1
  end

  def displayed_oohs
    oohs = []
    oohs += self.oohs.all(:recipient_id => nil, :limit => 10, :order => [:created_at.desc]) # don't show direct messsages
    self.follows.each do |follows| oohs += follows.oohs.all(:recipient_id => nil, :limit => 10, :order => [:created_at.desc]) end if @myself == @user
    oohs.sort! { |x,y| y.created_at <=> x.created_at }
    oohs[0..10]    
  end

  protected

  def method_missing(m, *args)
    return false
  end
end
class Relationship
  include DataMapper::Resource

  property :SlUser_id, Integer, :key => true
  property :follower_id, Integer, :key => true
  belongs_to :SlUser, :child_key => [:SlUser_id]
  belongs_to :follower, :model => "SlUser", :child_key => [:follower_id]
end

class Ooh
  include DataMapper::Resource

  property :id, Serial
  property :text, String, :length => 140
  property :created_at,  DateTime  
  belongs_to :recipient, :model => "SlUser", :child_key => [:recipient_id]
  belongs_to :SlUser  

  before :save do
    case 
    when starts_with?('dm ') 
      process_dm
    when starts_with?('follow ') 
      process_follow
    else 
      process
    end
  end

  # general scrubbing of an ooh
  def process
    # process url
    urls = self.text.scan(URL_REGEXP)
    urls.each { |url|
      tiny_url = open("http://tinyurl.com/api-create.php?url=#{url[0]}") {|s| s.read}    
      self.text.sub!(url[0], "<a href='#{tiny_url}'>#{tiny_url}</a>")
    }        
    # process @
    ats = self.text.scan(AT_REGEXP)
    ats.each { |at| self.text.sub!(at, "<a href='/#{at[2,at.length]}'>#{at}</a>") }            
  end

  # process direct messages 
  def process_dm
    self.recipient = SlUser.first(:email => self.text.split[1])  
    self.text = self.text.split[2..self.text.split.size].join(' ') # remove the first 2 words
    process
  end

  # process follow commands
  def process_follow 
    Relationship.create(:SlUser => SlUser.first(:email => self.text.split[1]), :follower => self.SlUser)   
    throw :halt # don't save
  end

  def starts_with?(prefix)
    prefix = prefix.to_s
    self.text[0, prefix.length] == prefix
  end  
end
