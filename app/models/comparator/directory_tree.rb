#simple comparison - take source and target directories (named because of our usage, nothing intrinsic to this class)
#get a list of all files in each along with their sizes
#allow showing which is in just the source, in just the target, or in both but with different sizes
#Obviously this is not the most efficient way to do, but it's clear
require 'open3'
require 'set'
require 'fileutils'
require 'tmpdir'
class Comparator::DirectoryTree < Comparator::FsBase

  def analyze
    uuid = UUID.generate
    db_dir = File.join(Dir.tmpdir, "lmdb-#{uuid}")
    FileUtils.mkdir_p(db_dir)
    env = LMDB.new(db_dir, mapsize: 4.gigabytes)
    db = env.database
    with_all_files_and_sizes(source_directory) do |path, source_size|
      db[path] = source_size
    end
    with_all_files_and_sizes(target_directory) do |path, target_size|
      if source_size = db[path]
        if source_size != target_size
          different_sizes_paths << path
        end
        db.delete(path)
      else
        target_only_paths << path
      end
    end
    self.source_only_paths = db.collect { |k, v| k }.to_set
    self
  ensure
    env.close if env
    FileUtils.rm_rf(db_dir) if db_dir and Dir.exist?(db_dir)
  end

  def with_all_files_and_sizes(directory)
    Dir.chdir(directory) do
      Open3.popen2(find_command, '.', '-type', 'f', '-exec', stat_command, '-c', '%n %s', '{}', '+') do |stdin, stdout, wait|
        stdout.each_line do |line|
          line.chomp!
          line.match(/^(.*) (\d+)$/)
          yield $1, $2
        end
      end
    end
  end

  def find_command
    if OS.linux?
      'find'
    elsif OS.mac?
      'gfind'
    else
      raise RuntimeError, 'Unrecognized platform'
    end
  end

  def stat_command
    if OS.linux?
      'stat'
    elsif OS.mac?
      'gstat'
    else
      raise RuntimeError, 'Unrecognized platform'
    end
  end

  protected

  def augment_paths(path_collection)
    base = File.basename(source_directory)
    path_collection.collect do |path|
      File.join(base, path)
    end
  end

end