#!/usr/bin/ruby

require 'json'
require 'net/http'
require 'uri'
require 'io/console'

NUMBER_OF_RESULTS = 5
GITHUB_LINK = "https://api.github.com/users/"
class Researcher
  def initialize(username, password)
    @username = username
    @password  = password
  end

  def set_username(username)
    @username = username
  end
  def set_password(password)
    @password = password
  end
  def get_username
    @username
  end
  def get_password
    @password
  end
end

class Wanted
  def initialize(username)
    @username = username
  end
  def set_username(username)
    @username = username
  end

  def get_username
    @username
  end
end

# < UTILS FUNCTIONS >
def message(number, key)
  if number.eql? 0
    return "There is no #{key}!", 0
  elsif number.eql?  1
    return "There is just #{number} #{key}!", 1
  elsif number < NUMBER_OF_RESULTS
    return "There are just #{number} #{key}s!", 1
  end
end

# Write remaining and reset times
def api_info(data)
  puts "\n\n"
  65.times { print  "-"}
  remaining     = data["X-RateLimit-Remaining"].to_i
  reset_time    = Time.at(data["X-RateLimit-Reset"].to_i)
  print "\nRemaining request: " + remaining.to_s
  puts "  |  Reset Time: " + reset_time.to_s
end


def request(url)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request.basic_auth($res.get_username, $res.get_password)

    req_options = {
        use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
    end
end

def check_auth?
  data =  request("https://api.github.com")
  if data["status"] =~ /401/
    return 0
  else
    return 1
  end
end

# </ UTILS FUNCTIONS >

# < MAIN FUNCTIONS >


def get_profile
  data = request(GITHUB_LINK + $wanted.get_username)
  parsed_data = JSON.parse(data.body)

  name        = parsed_data["name"]
  photo       = parsed_data["avatar_url"]
  location    = parsed_data["location"] || "No info"
  company     = parsed_data["company"] || "No info"
  blog        = parsed_data["blog"] || "No info"
  return [name, photo, location, company, blog], data
end


def get_last_repos
  # get all repos count
  data          = request(GITHUB_LINK + $wanted.get_username)
  parsed_data   = JSON.parse(data.body)
  count_of_repo = parsed_data["public_repos"].to_i

  text , check = message(count_of_repo, "repo")
  puts text , "\n"

  # get last NUMBER_OF_RESULTS repos
  unless check.eql? 0
    data2         = request(GITHUB_LINK + $wanted.get_username +
                       "/repos?sort=pushed&direction=desc&per_page=1000")
    parsed_data   = JSON.parse(data2.body)

    repos = Array.new
    counter = count_of_repo > NUMBER_OF_RESULTS ? NUMBER_OF_RESULTS.clone : count_of_repo.clone

    counter.times do |index|
        repos.push(parsed_data[index]["name"])
        end
    return repos, count_of_repo, data
  end
    return 0
end

# Print last NUMBER_OF_RESULTS starred repos
def get_starred_repos
  data = request(GITHUB_LINK + $wanted.get_username + "/starred")
  parsed_data = JSON.parse(data.body)
  result = Array.new
  i = 0
  # Get last NUMBER_OF_RESULTS starred repos name and total star
  while i < NUMBER_OF_RESULTS
    begin
      result.push(parsed_data[i]["name"])
      i += 1
    rescue
      break
    end
  end
  loop do # count all starred repos
    begin
      parsed_data[i]["name"]
      i += 1
    rescue
      break
    end
  end
  return result, i, data
end

def get_last_followers
  # Find followers count
  data            = request(GITHUB_LINK + $wanted.get_username )
  parsed_data     = JSON.parse(data.body)
  followers_count = parsed_data["followers"].to_i

  text, check = message(followers_count, "follower")
  puts text

  unless check.eql? 0
    data2 = request(GITHUB_LINK + $wanted.get_username + "/followers")
    parsed_data = JSON.parse(data2.body)
    i = 0
    user    = Array.new
    results = Array.new

    count = followers_count < NUMBER_OF_RESULTS ? followers_count.clone : NUMBER_OF_RESULTS.clone

    count.times do |i|
      user.push(parsed_data[i]["login"])
      user.push(parsed_data[i]["avatar_url"])
      results.push(user.clone)
      user.clear
    end
    return results, data2
  end
  return 0, data
end

# Is $wanted.get_username following $res.get_username?
def is_following?
  data = request(GITHUB_LINK + $wanted.get_username + "/following/" + $res.get_username)
  if data["Status"] =~ /204/
    return 1
  elsif data["Status"] =~ /404/
    return 0
  else
  end
end

def get_last_followings
  data = request(GITHUB_LINK + $wanted.get_username)
  count_of_following = JSON.parse(data.body)["following"]

  text, check = message(count_of_following, "following")
  puts text

  unless check.eql? 0
    data2       = request(GITHUB_LINK + $wanted.get_username + "/following")
    parced_data = JSON.parse(data2.body)

    results   = Array.new
    result     = Array.new
    index = count_of_following < NUMBER_OF_RESULTS ? count_of_following.clone : NUMBER_OF_RESULTS.clone

    index.times do |i|
      result.push(parced_data[i]["login"])
      result.push(parced_data[i]["avatar_url"])
      results.push(result.clone)
      result.clear
    end
    return results, data2

  end

  return 0, data
end

# </ MAIN FUNCTIONS >


# < PROGRESS >
puts "Github - Research Users"

$res = Researcher.new("", "")
$wanted = Wanted.new("")
loop do
  $res.set_username("")
  $res.set_password("")
  puts "\n"
  print "Please enter your username >"
  $res.set_username(gets.chop)
  print "Your Github password >"
  $res.set_password(gets.chop)
   check_auth?  ? break : ""
end

loop do
  $wanted.set_username("")
  print "Enter username which user you want to monitoring?>"
  $wanted.set_username(gets.chop)
  get_profile ? break : ""
end
loop do
  puts
  print "-"*65
  puts "
  1 | PROFILE
  2 | REPOS
  3 | STARRED
  4 | FOLLOWERS
  5 | FOLLOWINGS
  6 | DO USER FOLLOWING YOU?
  Please select one of above! >"

  choise = gets.chomp
  case choise
    when "1"
      puts "PROFİLE".center(65)
      arr, data = get_profile
      puts arr
      api_info(data)
    when "2"
      puts "\nREPOS".center(65)
      repos, count_of_repo, data =  get_last_repos
      puts repos
      print "#{$wanted.get_username} has #{count_of_repo} repo/s"
      api_info(data)
    when "3"
      puts "\nSTARRED".center(65)
      result, count, data = get_starred_repos
      puts result
      print "#{$wanted.get_username} starred #{count} repo/s"
      api_info(data)

    when "4"
      puts "\nFOLLOWERS".center(65)
      results, data = get_last_followers
      results.each {|i| i.each { |j| print " #{j}"}; puts}
      api_info(data)
    when "5"
      puts "\nFOLLOWINGS".center(65)
      results, data = get_last_followings
      results.each {|i| i.each { |j| print " #{j}"}; puts}
      api_info(data)
    when "6"
      print "\nFOLLOW YOU?".center(56)
      puts is_following? ? "YES" : "NO"
  end
  print "-"*65
  puts
end