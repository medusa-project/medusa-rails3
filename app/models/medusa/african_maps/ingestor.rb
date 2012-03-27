module Medusa
  module AfricanMaps
    class Ingestor < Medusa::ContentDmIngestor

      def ingest
        #ingest collection
        #create collection object
        #attach metadata streams
        collection_files = self.collection_file_data
        collection_premis_file = collection_files.detect { |f| f[:base] == 'premis_object' }
        collection_mods_file = collection_files.detect { |f| f[:base] == 'mods' }
        collection_pid = collection_premis_file[:pid]
        puts "INGESTING COLLECTION: " + collection_pid
        fedora_collection = do_if_new_object(collection_pid, Medusa::Set) do |collection_object|
          add_xml_datastream_from_file(collection_object, 'PREMIS', collection_premis_file[:original])
          add_xml_datastream_from_file(collection_object, 'MODS', collection_mods_file[:original])
          collection_object.save
        end
        puts "INGESTED COLLECTION: #{collection_pid}"

        self.item_dirs.each do |item_dir|
          item_pid = File.basename(item_dir).sub('_', ':')
          puts "INGESTING ITEM: #{item_pid}"
          item_files = self.item_file_data(item_dir)
          item_premis_file = item_files.detect {|f| f[:base] == 'premis'}
          item_mods_file = item_files.detect {|f| f[:base] == 'mods'}
          item_content_dm_file = item_files.detect {|f| f[:base] == 'contentdm'}
          item_mods_from_marc_file = item_files.detect {|f| f[:base].match('mods_')}
          item_image_file = item_files.detect {|f| f[:base] == 'image'}
          fedora_item = do_if_new_object(item_pid, Medusa::Parent) do |item_object|
            add_xml_datastream_from_file(item_object, 'PREMIS', item_premis_file[:original])
            add_xml_datastream_from_file(item_object, 'MODS', item_mods_file[:original])
            add_xml_datastream_from_file(item_object, 'CONTENT_DM_MD', item_content_dm_file[:original])
            add_xml_datastream_from_file(item_object, 'MODS_FROM_MARC', item_mods_from_marc_file[:original])
            item_object.add_relationship(:is_member_of, fedora_collection)
            item_object.save
          end
          asset_pid = item_image_file[:pid]
          puts "INGESTING ASSET: #{asset_pid}"
          fedora_asset = do_if_new_object(asset_pid, Medusa::Asset) do |asset|
            add_managed_datastream_from_file(asset, 'JP2', item_image_file[:original], :mimeType => 'image/jp2')
          end
          fedora_asset.add_relationship(:is_part_of, fedora_item)
          fedora_asset.save
          puts "INGESTED ASSET: #{asset_pid}"
          puts "INGESTED ITEM: #{item_pid}"
        end
        puts ""
      end

    end
  end
end