$:.unshift File.dirname(__FILE__)
require 'find'
require 'fileutils'
require 'erb'
require 'yaml'

def template(*args)
    dirname = nil
    dirname = args.first if args.size > 1
    args = args.last || {}

    $last_template = Skema::TemplateDefinition.new(dirname, args)
end

module Skema
    DEFAULT_MODULE_DIR = File.join(File.dirname(__FILE__), 'modules')
    
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
            md = @config[:skema_modules_dir] ||= []
            md.unshift(DEFAULT_MODULE_DIR) if md.class == Array
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
