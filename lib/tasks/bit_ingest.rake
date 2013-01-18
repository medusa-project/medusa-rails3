require 'rake'

namespace :bit_level do

  desc 'Ingest to collection id INGEST_COLLECTION from directory INGEST_DIR on server'
  task :ingest => :environment do
    unless (ENV['INGEST_COLLECTION'].present? and ENV['INGEST_DIR'].present?)
      puts "Must specify INGEST_COLLECTION and INGEST_DIR"
      exit 0
    end
    collection = Collection.find ENV['INGEST_COLLECTION']
    dir = ENV['INGEST_DIR']
    collection.bit_ingest(dir)
  end

  desc 'Export from collection id EXPORT_COLLECTION to directory EXPORT_DIR on server'
  unless (ENV['EXPORT_COLLECTION'].present? and ENV['EXPORT_DIR'].present?)
    puts "Must specify EXPORT_COLLECTION and EXPORT_DIR"
    exit 0
  end
  task :export => :environment do
    collection = Collection.find ENV['EXPORT_COLLECTION']
    dir = ENV['EXPORT_DIR']
    collection.bit_export(dir)
  end

end