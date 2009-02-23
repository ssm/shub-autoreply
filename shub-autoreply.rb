#!/usr/bin/ruby
#
# == Synposis
# 
# Return a specially crafted bounce message back to the sender, with a
# customized message body based on the intended recipient.  The message body is
# taken from a text file with the same name as the recipient, or a short string
# if this cannot be found.
# 
# == Usage
# 
# shub-autoreply --sender sender --recipient recipient
# 
# == Author
# 
# Stig Sandbeck Mathisen <ssm@fnord.no>
# 
# == Copyright
# 
# Copyright (c) 2005 Stig Sandbeck Mathisen.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Load modules
require 'tmail'
require 'optparse'
require 'net/smtp'

class ShubConfig
  attr_reader :domain,:mailhost,:template_dir

  # Read the configuration from the defined configuration file
  def initialize(arg = nil, &block)
    case arg
    when Hash
      set_conf_vars do
        @mailhost = arg[:mailhost] unless arg[:mailhost].nil?
        @domain = arg[:domain] unless arg[:domain].nil?
        @template_dir = arg[:template_dir] unless arg[:template_dir].nil?
      end
      instance_eval(&block) unless block.nil?
    when NilClass
      set_conf_vars(&block)
    else
      raise TypeError
    end
  end # of def initialize

  private

  # Here's the default configuration variables
  def set_conf_vars(arg=nil, &block)
    @mailhost		= 'smtp.example.com'
    @domain		= 'example.com'
    @template_dir	= '/etc/shub-autoreply/templates'
    instance_eval(&block) unless block.nil?
  end
end # of class ShubConfig

def main
  rcfile = '/etc/shub-autoreply/shub-autoreply.conf'
  begin
    eval File.new(rcfile).read
    config = ShubConfig.new(Conf) unless Conf.nil?
  rescue ScriptError=>e
    STDERR.puts(["Warning: Invalid syntax while reading %s: " % rcfile, e].join("\n"))
  end

  # Initialize variables
  recipient = ""
  sender = ""

  # Parse options
  opts = OptionParser.new
  opts.on("-h", "--help") { usage }
  opts.on("--recipient ADDRESS", String) {|address| recipient = address}
  opts.on("--sender ADDRESS", String) {|address| sender = address}
  rest = opts.parse(ARGV) rescue RDoc::usage
  if ( recipient.empty? or sender.empty? or not rest.join.empty? )
    usage
    exit 1
  end

  message = generate_mail(config,sender,recipient)
  send_mail(config,message,sender)
end

def usage
  STDERR.puts "%s [--help] --recipient <address> --sender <address> " % $0
end

def send_mail(config,message,address)
  smtp = Net::SMTP.start(config.mailhost){|smtp|
    smtp.send_message(message.encoded,	# the mail body
    		      '',		# Envelope sender
		      [address])	# Recipient
  }
end

def generate_mail(config,sender,recipient)
  message		= TMail::Mail.new
  message.to		= sender
  message.from		= 'Postmaster <postmaster@%s>' % config.domain
  message.date		= Time.now
  message.subject	= "Your mail to %s could not be delivered" % recipient
  message.body		= message_body(config,recipient)
  return message
end

def message_body(config,recipient)
  filename = "%s/%s" % [config.template_dir, recipient]
  begin
    body = IO.read(filename)
  rescue
    body = "%s is not a valid address" % recipient
  end
  return body
end

# Run the main subroutine.
main
