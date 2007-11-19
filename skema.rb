#!/usr/bin/ruby

# skema - A command line template expansion tool
#
# Copyright (c) 2007 Paolo Capriotti  <p.capriotti@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'fileutils'
require 'find'
require 'erb'
require 'yaml'

def template(*args)
    dirname = nil
    dirname = args.first if args.size > 1
    args = args.last || {}

    $last_template = Skema::TemplateDefinition.new(dirname, args)
end

module Skema
    def self.config
        @@config ||= Config.new
    end

    def self.last
        @@last
    end
    
    class Config
        def initialize
            configfile = File.join(ENV['HOME'], '.skemarc')
            if File.exist? configfile
                @config = File.open(configfile) {|f| YAML::load(f) }
            else
                @config = {}
            end
        end
        
        def [](key)
            @config[key]
        end
        
        def has_key? key
            @config.has_key? key
        end
    end
    
    class TemplateDefinition
        attr_reader :template, :args
        def initialize(template, args)
            @template = template
            @args = args
        end
    end
    
    class Template
        def initialize(dir, target)
            @dir = dir
            @target = target
        end
        
        def run(arguments)
            template_dir = File.join(@dir, 'templates')
            if File.exists? template_dir
                Find.find(template_dir) do |filename|
                    Find.purge if filename[0] == '.'
                    next if File.directory? filename
                    args = Args.new(@target, filename[template_dir.size+1..-1], arguments)
                    data = File.open(filename) do |f|
                      ERB.new(f.read).result(args.get_binding)
                    end
                    puts "-> #{args.filename}"
                    create_file(args.full_filename, data)
                end
            end
        end

        def create_file(filename, data)
            dir = File.dirname filename
            FileUtils.mkdir_p dir unless File.exist? dir
            File.open(filename, 'w') {|f| f.write data }
        end
    end
    
    class Args        
        def initialize(target, base, args)
            @_target = target
            @_base = base
            args.each do |arg, value|
                instance_variable_set("@#{arg}", value)
            end
        end
        
        def get_binding
            binding
        end

        def filename(*args)
            if args.size > 0
                filename = args.shift
                @_filename = if args.include? :absolute
                    filename
                else
                    File.join(File.dirname(@_base), filename)
                end
            else
                @_filename || @_base
            end
        end
        
        def full_filename
          File.join(@_target, filename)
        end
        
        def original_content
          if File.exist? full_filename
            File.open(full_filename) {|f| f.read }
          else
            ""
          end
        end
    end
end

if $0 == __FILE__
    def error(msg)
        warn "ERROR: #{msg}"
        exit 1
    end
    
    def usage
        error "Usage #$0 MODULE TARGET [ARGS...]"
    end

    def load_module(mod)
        alt = [mod]
        mdir = Skema::config[:skema_modules_dir]
        case mdir
        when String
            alt << File.join(mdir, mod)
        when Array
            mdir.each do |module_dir|
                alt << File.join(module_dir, mod)
            end
        end
        alt = alt.inject([]) do |res, file|
            if File.exist? file
                if File.directory? file
                    modfile = File.join(file, "#{File.basename(file)}.rb")
                    if File.exist? modfile
                        res << modfile
                    else
                        # add all ruby scripts
                        Dir[File.join(file, '*.rb')].each do |modfile|
                            res << modfile
                        end
                    end
                else
                    res << file
                end
            end
            res
        end

        alt.each do |file|
            begin
                load file
                return file
            rescue Exception => e
                warn "Could not load #{file}:"
                warn e
            end
        end
        error "Could not load module #{mod}. Tried #{alt.join ','}"
    end

    def ask(key, value)
        ans = nil
        while ans.nil? || ans.empty?
            q = key.to_s
            q += " [#{value}]" if value
            q += ": "
            $stdout.write(q)
            ans = $stdin.gets.chomp
            ans = value if ans.empty?
        end
        ans
    end

    mod = ARGV.shift or usage
    if mod == "-i"
        $interactive = true
        mod = ARGV.shift or usage
    end
    target = ARGV.shift or usage
    mod = load_module mod
    error "Invalid template module" unless $last_template
    
    # read args
    args = {}
    if File.exist?(target) and not File.directory?(target)
        args[:filename] = File.basename(target)
        target = File.dirname(target)
    end
    ARGV.each do |arg|
        if arg =~ /^(\S*):(.*)$/
            args[$1.to_sym] = $2
        else
            usage
        end
    end

    $last_template.args.each do |key, value|
        unless args.has_key? key
            default = nil
            if not value.nil?
                default = value
            elsif Skema::config.has_key? key
                default = Skema::config[key]
            end

            if $interactive || Skema::config[:interactive]
                args[key] = ask(key, default)
            elsif default
                args[key] = default
            else
                error "Missing argument #{key}"
            end
        end
    end
   
    dir = $last_template.template || File.dirname(mod)
    template = Skema::Template.new dir, target
    template.run args
end

