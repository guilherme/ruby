# -*- coding: us-ascii -*-

class VPath
  attr_accessor :separator

  def initialize(*list)
    @list = list
    @additional = []
    @separator = nil
  end

  def inspect
    list.inspect
  end

  def search(meth, base, *rest)
    begin
      meth.call(base, *rest)
    rescue Errno::ENOENT => error
      list.each do |dir|
        return meth.call(File.join(dir, base), *rest) rescue nil
      end
      raise error
    end
  end

  def process(*args, &block)
    search(File.method(__callee__), *args, &block)
  end

  alias stat process
  alias lstat process

  def open(*args)
    f = search(File.method(:open), *args)
    if block_given?
      begin
        yield f
      ensure
        f.close unless f.closed?
      end
    else
      f
    end
  end

  def read(*args)
    open(*args) {|f| f.read}
  end

  def foreach(file, *args, &block)
    open(file) {|f| f.each(*args, &block)}
  end

  def def_options(opt)
    opt.on("-I", "--srcdir=DIR", "add a directory to search path") {|dir|
      @additional << dir
    }
    opt.on("-L", "--vpath=PATH LIST", "add directories to search path") {|dirs|
      @additional << [dirs]
    }
    opt.on("--path-separator=SEP", /\A\W\z/, "separator for vpath") {|sep|
      @separator = sep
    }
  end

  def list
    @separator ||= (require 'rbconfig'; RbConfig::CONFIG["PATH_SEPARATOR"])
    @additional.reject! do |dirs|
      case dirs
      when String
        @list << dirs
      when Array
        @list.concat(dirs[0].split(@separator))
      end
      true
    end
    @list
  end
end
