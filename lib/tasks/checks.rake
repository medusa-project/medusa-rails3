require 'rake'

namespace :check do
  desc 'Run all checks'
  task :all => [:cfs_directories_vs_bit_level_file_groups, :file_count_and_size_totals,
                :cfs_directories_vs_physical_paths, :combined_paths] do
    #just run all dependencies
  end

  desc 'Find root cfs directories with no file group and vice-versa'
  task cfs_directories_vs_bit_level_file_groups: :environment do
    #find and display root cfs directories with no file group
    puts "\nCfs Directories without associated Bit Level File Group"
    puts "Id,Path,FileCount"
    CfsDirectory.roots.find_each do |cfs_directory|
      next if cfs_directory.file_group.present?
      puts "#{cfs_directory.id},#{cfs_directory.path},#{cfs_directory.tree_count}"
    end
    #find and display bit level file groups with no cfs directory
    puts "\nBit Level File Groups without associated Cfs Directory"
    puts "Id,Name,CollectionId,CollectionTitle"
    BitLevelFileGroup.find_each do |file_group|
      next if file_group.cfs_directory.present?
      puts "#{file_group.id},#{file_group.name},#{file_group.collection.id},#{file_group.collection.title}"
    end
  end

  desc 'Compare file and size totals computed in different ways'
  task file_count_and_size_totals: :environment do
    puts "\nMethod,FileCount,FileSize"
    puts "CfsFile objects,#{CfsFile.count},#{CfsFile.sum(:size)}"
    puts "ContentType objects,#{ContentType.sum(:cfs_file_count)},#{ContentType.sum(:cfs_file_size)}"
    roots = CfsDirectory.roots
    puts "RootCfsDirectories,#{roots.sum(:tree_count)},#{roots.sum(:tree_size)}"
    puts "BitLevelFileGroups,#{BitLevelFileGroup.sum(:total_files)},#{BitLevelFileGroup.sum(:total_file_size) * 1.gigabyte}"
  end

  desc 'Find cfs directories with no physical path and vice-versa'
  task cfs_directories_vs_physical_paths: :environment do
    #find cfs directories with no physical path
    puts "\nCfs Directory objects without a physical directory"
    puts "Id,Path"
    CfsDirectory.roots.find_each do |cfs_directory|
      next if File.directory?(cfs_directory.absolute_path)
      puts "#{cfs_directory.id},#{cfs_directory.path}"
    end
    #find physical paths with no cfs directory
    puts "\nPhysical potential cfs directories without Cfs Directory object"
    puts "Path"
    CfsRoot.instance.non_cached_physical_root_set.each do |path|
      next if CfsDirectory.find_by(path: path)
      puts path
    end
  end

  desc 'List all paths for which a physical path, cfs directory, or bit level file group is missing and show status of each'
  task combined_paths: :environment do
    puts "\nCombined path summary. We look at all paths implied by the physical file system,
\nthe CfsDirectory objects, and the Bit Level File Group objects. For any path where all are not present we show which are and are not."
    puts "Path,Physical,CfsDirectory,BitLevelFileGroup"
    physical_roots = CfsRoot.instance.non_cached_physical_root_set
    paths = CfsRoot.instance.non_cached_physical_root_set + CfsDirectory.roots.pluck(:path) + BitLevelFileGroup.find_each.collect {|fg| fg.expected_relative_cfs_root_directory}
    paths.sort.each do |path|
      physical_root_present = physical_roots.include?(path)
      cfs_directory = CfsDirectory.roots.find_by(path: path)
      bit_level_file_group = BitLevelFileGroup.find_by(id: path.split('/').last)
      next if physical_root_present and cfs_directory.present? and bit_level_file_group.present?
      puts [path, physical_root_present, cfs_directory.present?, bit_level_file_group.present?].join(',')
    end
  end
end