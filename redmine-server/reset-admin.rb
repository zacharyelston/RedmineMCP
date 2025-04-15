#!/usr/bin/env ruby
# Script to generate a valid password hash for admin

require 'digest/sha1'

# Password to set
password = "admin"

# Generate a hash for the password
def hash_password(clear_password)
  Digest::SHA1.hexdigest(clear_password || "")
end

# Generate a random salt
def generate_salt
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  salt = ""
  32.times { salt << chars[rand(chars.size)] }
  salt
end

# Generate the salt
salt = generate_salt

# Generate the hashed password
password_hash = hash_password(password)
hashed_password = hash_password("#{salt}#{password_hash}")

puts "SQL_SALT=#{salt}"
puts "SQL_HASH=#{hashed_password}"
