if Object.const_defined?("DataMapper")
  #require 'dm-core'
  require 'dm-timestamps'
  require 'dm-validations'
  require 'date'
  require 'time'

  require Pathname(__FILE__).dirname.expand_path + "sl_user.rb"
  require Pathname(__FILE__).dirname.expand_path + "sl_aah.rb"

end

class User
  if Object.const_defined?("DataMapper")
    include SlAah
  else
    throw "'dm-core' required for red safe "
  end

  def initialize(interfacing_class_instance)
    @instance = interfacing_class_instance
  end

  def id
    @instance.id
  end

  def self.authenticate(email, pass)
    current_user = get(:email => email)
    return nil if current_user.nil?
    return current_user if User.encrypt(pass, current_user.salt) == current_user.hashed_password
    nil
  end

  protected

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass+salt)
  end

  def self.random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

#Created 3 actions and terminology thereof:
#1. sist: generates a string
#2. desist: receives the sist from an authorized server and breaks it apart
#3. resist: receives the desist string and reviews its integrity

  def self.sist
     TIME_FMT = '%Y-%m-%dT%H:%M:%SZ'
     junk = self.random_string(6)
     t = Time.now.getutc
     time_str = t.strftime(TIME_FMT)
     the_sist_str = time_str + junk
     return the_sist_str
  end

  def self.desist( the_sist_str )
     TIME_STR_LEN = '0000-00-00T00:00:00Z'.size
     TIME_VALIDATOR = /\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ/
     timestamp_str = the_sist_str[0...TIME_STR_LEN]
     raise ArgumentError if timestamp_str.size < TIME_STR_LEN
     raise ArgumentError unless timestamp_str.match(TIME_VALIDATOR)
     timestamp = Time.parse(timestamp_str).to_i
     raise ArgumentError if ts < 0
     return timestamp, the_sist_str[TIME_STR_LEN..-1]
  end

  def self.resist(the_sist_str)
     TIME_RANGE = 60*60*5
     timestamp, junk = self.desist(the_sist_str)
     now = Time.now.to_i 
     start = now - TIME_RANGE
     finish = now + TIME_RANGE
     return true if (start <= timestamp and timestamp <= finish)
     return false
  end



end



