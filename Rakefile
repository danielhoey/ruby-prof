require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'date'

# ------- Version ----
# Read version from header file
version_header = File.read('ext/ruby_prof/version.h')
match = version_header.match(/RUBY_PROF_VERSION\s*["](\d.+)["]/)
raise(RuntimeError, "Could not determine RUBY_PROF_VERSION") if not match
RUBY_PROF_VERSION = match[1]
  

# ------- Default Package ----------
FILES = FileList[
  'Rakefile',
  'README',
  'LICENSE',
  'CHANGES',
  'bin/*',
  'doc/**/*',
  'examples/*',
  'ext/ruby_prof/*.c',
  'ext/ruby_prof/*.h',
  'ext/ruby_prof/mingw/Rakefile',
  'ext/ruby_prof/mingw/build.rake',
  'ext/vc/*.sln',
  'ext/vc/*.vcproj',
  'lib/**/*',
  'rails/**/*',
  'test/*'
]

# Default GEM Specification
default_spec = Gem::Specification.new do |spec|
  spec.name = "ruby-prof-danielhoey"
  
  spec.homepage = "http://github.com/danielhoey/ruby-prof"
  spec.summary = "Fast Ruby profiler with real call trees"
  spec.description = <<-EOF
ruby-prof is a fast code profiler for Ruby. It is a C extension and
therefore is many times faster than the standard Ruby profiler. It
supports both flat and graph profiles.  For each method, graph profiles
show how long the method ran, which methods called it and which 
methods it called. RubyProf generate both text and html and can output
it to standard out or to a file.
EOF

  spec.version = RUBY_PROF_VERSION

  spec.author = "Shugo Maeda, Charlie Savage, Roger Pack, Daniel Hoey"
  spec.email = "danielhoey1@gmail.com"
  spec.platform = Gem::Platform::RUBY
  spec.require_path = "lib" 
  spec.bindir = "bin"
  spec.executables = ["ruby-prof"]
  spec.extensions = ["ext/ruby_prof/extconf.rb"]
  spec.files = FILES.to_a
  spec.test_files = Dir["test/test_*.rb"]
  spec.required_ruby_version = '>= 1.8.4'
  spec.date = DateTime.now
  spec.rubyforge_project = 'ruby-prof'
  spec.add_development_dependency 'os'
  spec.add_development_dependency 'rake-compiler'
  
end


desc 'build native .gem files -- use like "native_gems clobber cross native gem"--for non native gem creation use "native_gems clobber" then "clean gem"'
task :native_gems do
  ENV['RUBY_CC_VERSION'] = '1.8.6:1.9.1'
  require 'rake/extensiontask'
  Rake::ExtensionTask.new('ruby_prof', default_spec) do |ext|
    ext.cross_compile = true
    ext.cross_platform = ['x86-mswin32-60', 'x86-mingw32-60']
  end
end

# Rake task to build the default package
Rake::GemPackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
  #pkg.need_zip = true
end


# ---------  RDoc Documentation ------
desc "Generate rdoc documentation"
Rake::RDocTask.new("rdoc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "ruby-prof"
  # Show source inline with line numbers
  rdoc.options << "--inline-source" << "--line-numbers"
  # Make the readme file the start page for the generated html
  rdoc.options << '--main' << 'README'
  rdoc.rdoc_files.include('bin/**/*',
                          'doc/*.rdoc',
                          'examples/flat.txt',
                          'examples/graph.txt',
                          'examples/graph.html',
                          'lib/**/*.rb',
                          'ext/ruby_prof/ruby_prof.c',
                          'ext/ruby_prof/version.h',
                          'ext/ruby_prof/measure_*.h',
                          'README',
                          'LICENSE')
end

task :default => :package

desc 'Run the ruby-prof test suite'
Rake::TestTask.new do |t|
  t.libs += %w(lib ext test)
  t.test_files = Dir['test/test_suite.rb']
  t.verbose = true
  t.warning = true
end

require 'fileutils'

desc 'Buildr ruby_prof.so'
task :build do
 build(false)
end

def build(with_debug)
 Dir.chdir('ext/ruby_prof') do
  unless File.exist? 'Makefile'
    if with_debug
      system(Gem.ruby + " -d extconf.rb")
    else
      system(Gem.ruby + " extconf.rb")
    end
    system("make clean")
  end
  system("make")
  FileUtils.cp 'ruby_prof.so', '../../lib' 
 end
end

desc 'build ruby_prof.so with verbose debugging enabled'
task :build_debug do
 build(true)
end

task :cleanr do
 FileUtils.rm 'lib/ruby_prof.so' if File.exist? 'lib/ruby_prof.so'
 Dir.chdir('ext/ruby_prof') do
  if File.exist? 'Makefile'
    system("make clean")
    FileUtils.rm 'Makefile'
  end
  Dir.glob('*~') do |file|
    FileUtils.rm file
  end
 end
 system("rm -rf pkg")
end
