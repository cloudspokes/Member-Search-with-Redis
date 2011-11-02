require File.dirname(__FILE__) + '/environment'

class Member
  attr_reader :attributes

  KEYWORDS = %w(ruby rails heroku cloud-foundry jquery javascript salesforce html css google twilio java aws)

  def self.generate_attributes
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    username = (first_name[0..0] + last_name).downcase
    keywords = KEYWORDS.sort_by{rand}[0..rand(5)]

    {
      first_name: first_name,
      last_name: last_name,
      username: username,
      keywords: keywords
    }
  end

  def self.create(attributes)
    new(attributes)
  end

  def self.fetch(id)
    new(MultiJson.decode($redis.get "user:#{id}"))
  end

  def name
    [first_name, last_name].join(' ')
  end

  def self.with_keywords(*keywords)
    $redis.sinter(*Member.tokenize(*keywords).map{|k| "keyword:#{k}"}).map{|id| fetch(id)}
  end

  def initialize(attributes_or_id)
    if attributes_or_id.is_a?(Hash)
      @attributes = Hashie::Mash.new(attributes_or_id)
      persist! unless @attributes.id?
    else
      Member.fetch(attributes_or_id)
    end
  end

  def self.tokenize(*words)
    words.map{|w| w.downcase.gsub(/[^a-z0-9_-]/,'') }
  end

  def tokenized
    Member.tokenize(*keywords)
  end

  def persist!
    @attributes.id = $redis.incr "user:id"
    $redis.set "user:#{attributes.id}", MultiJson.encode(attributes.to_hash)
    tokenized.each do |token|
      $redis.sadd "members", attributes.id
      $redis.sadd "keyword:#{token}", attributes.id
      $redis.zincrby "keywords", 1, token
    end
  end

  def method_missing(*args)
    @attributes.send(*args)
  end
end
