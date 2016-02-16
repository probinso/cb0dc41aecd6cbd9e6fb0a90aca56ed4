#!/usr/bin/ruby

require 'time'
require 'date'
require 'json'

class Session
 def initialize(time,site)
     @time = time
     @site = []
     @site = @site.push(site)
 end

 def add(time, site)
     @time = time
     @site.push(site)
 end

 def gettop(n=3)
     return @site[-1*n..-1]
 end

 def gettime
     return @time
 end
end

class User
 def initialize(name, time, site, timeout)
     @name     = name    # not nessicary to store user name...
     @sessions = [Session.new(time, site)]
     @timeout  = timeout # time in seconds
 end

 def add(time, site)     # sessions exire every 20 hours
     if (((time - @sessions[-1].gettime)/60) < @timeout)
         @sessions[-1].add(time, site)
     else
         @sessions.push(Session.new(time, site))
     end
 end

 def gettop(n=3)
     return @sessions[-1].gettop(n)
 end
end

class SessionManager
 def initialize
     @users = Hash.new()
 end

 def add_and_get_sites(user, time, site, depth)
     if @users.has_key?(user)
         @users[user].add(time, site)
     else
         @users[user] = User.new(user, time, site, 20*60)
     end
     return @users[user].gettop(depth)
 end
end

class SiteCounter
 def initialize
     @sitecount = Hash.new()
 end
 
 def inc(sites,date)
     if sites == nil
         return
     end 
     key = sites.push(date) #mangles counter with dates
     if not @sitecount.has_key?(key)
         @sitecount[key] = 0
     end
     @sitecount[key] += 1
 end

 def to_json
     # puts "entered dump"
     tmp_out = Hash.new()
     @sitecount.sort_by {|k,v| v}.reverse.each do |key, value|
         funnel, date = key[0..-2], key[-1]
         if not tmp_out.has_key?(date)
             tmp_out[date] = []
         end
         tmp_out[date].push({
             :funnel => funnel, 
             :count  => value
         })

         #puts "#{key}:#{value}"
     end

     file_out = []
     tmp_out.sort.reverse.each do |key, value|
         file_out.push({:date => key, :sites => value})
     end
     return {:array => file_out}.to_json
     return JSON.pretty_generate({:array => file_out})
 end
end

class LogParser
 def initialize(filename, depth=3, dateformat="%m/%d/%Y %l:%M:%S %p")
     @filename = filename
     @file = self.openFile(@filename)

     @depth = depth

     @dateformat = dateformat

     @sitecounter    = SiteCounter.new()
     @sessionmanager = SessionManager.new()
 end

 def openFile(filename)
     # checks for usual fileIO problems and raises appropriate error
     if not File.exists?(filename) 
         raise 'Path Does Not Exist'
     elsif not File.file?(filename)
         raise 'Path Not File'
     elsif not File.readable?(filename)
         raise 'File Not Readable'
     end
     return File.open(filename)
 end

 def parseline(linedata)
     # line is of form Month/Day/Year Hour:Minute:Second Shift\tUsername\tsite
     linedata = linedata.split(/\t/)
     time = Time.strptime(linedata[0], @dateformat)
     user, site = linedata[1], linedata[2]

     return time, user, site.rstrip() # rstrip removes whitespace from end
 end
 
 def processline(linedata)
     begin 
         time, user, site = parseline(linedata)

         if time == nil or user == nil or site == nil
             throw ArgumentError
         end
         sites = @sessionmanager.add_and_get_sites(user, time, site, @depth)
         @sitecounter.inc(sites, Date.parse(time.to_s).to_s)
         return
     rescue
         $stderr.puts "malformed line :: " + linedata
     end
 end
 
 def step
     if @file.eof?
         @file.close
         return false
     end
     processline(@file.readline)
     return true
 end
 
 def to_json_file(filename="outfile.json")
     # produces json file in sorted useful order

     js = @sitecounter.to_json

     File.open(filename, "w") do |file|
          file.write(js)
     end
 end
end

begin 
 p = LogParser.new(filename="in.2")
 {} while p.step # speed = O(n)
 p.to_json_file  # O(n lg(n))
end
