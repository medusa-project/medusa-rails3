module BookTracker

  class Item < ApplicationRecord

    CSV_HEADER = ['Bib ID', 'Medusa ID', 'OCLC Number', 'Object ID', 'Title',
                  'Author', 'Volume', 'Date', 'IA Identifier',
                  'HathiTrust Handle', 'Exists in HathiTrust', 'Exists in IA',
                  'Exists in Google']

    # Used by self.insert_or_update!
    INSERTED = 0
    # Used by self.insert_or_update!
    UPDATED = 1

    attr_accessor :url
    before_save :truncate_values

    self.table_name = 'book_tracker_items'

    ##
    # Static method that either inserts a new item, or updates an existing item,
    # depending on whether an item with a matching object ID is already present
    # in the database.
    #
    # @param params Params hash
    # @param source_path Pathname of the file from which the params were
    # extracted
    # @return Array with the created or updated Item at position 0 and the status
    # (Item::INSERTED or Item::UPDATED) at position 1
    #
    def self.insert_or_update!(params, source_path = nil)
      status = Item::UPDATED
      item = Item.find_by_obj_id(params[:obj_id])
      if item
        item.update_attributes(params)
      else
        item = Item.new(params)
        status = Item::INSERTED
      end
      item.source_path = source_path
      item.save!
      return item, status
    end

    ##
    # @param record Nokogiri element corresponding to a /collection/record
    # element in a MARCXML file
    # @return Params hash for an Item
    #
    def self.params_from_marcxml_record(record)
      namespaces = { 'marc' => 'http://www.loc.gov/MARC21/slim' }
      item_params = {}

      # raw MARCXML
      item_params[:raw_marcxml] = record.to_xml(indent: 2)

      # extract bib ID
      nodes = record.xpath('marc:controlfield[@tag = 001]', namespaces)
      item_params[:bib_id] = nodes.first.content.strip if nodes.any?

      # extract OCLC no. from 035 subfield a
      nodes = record.
          xpath('marc:datafield[@tag = 035][1]/marc:subfield[@code = \'a\']', namespaces)
      item_params[:oclc_number] = nodes.first.content.sub(/^[(OCoLC)]*/, '').
          gsub(/[^0-9]/, '').strip if nodes.any?

      # extract author & title from 100 & 245 subfields a & b
      item_params[:author] = record.
          xpath('marc:datafield[@tag = 100][1]/marc:subfield', namespaces).
          map{ |t| t.content }.join(' ').strip
      item_params[:title] = record.
          xpath('marc:datafield[@tag = 245][1]/marc:subfield[@code = \'a\' or @code = \'b\']', namespaces).
          map{ |t| t.content }.join(' ').strip

      # extract volume from 955 subfield v
      nodes = record.xpath('marc:datafield[@tag = 955][1]/marc:subfield[@code = \'v\']', namespaces)
      item_params[:volume] = nodes.first.content.strip if nodes.any?

      # extract date from 260 subfield c
      nodes = record.
          xpath('marc:datafield[@tag = 260][1]/marc:subfield[@code = \'c\']', namespaces)
      item_params[:date] = nodes.first.content.strip if nodes.any?

      # extract object ID from 955 subfield b
      # For Google digitized volumes, this will be the barcode.
      # For Internet Archive digitized volumes, this will be the Ark ID.
      # For locally digitized volumes, this will be the bib ID (and other extensions)
      nodes = record.
          xpath('marc:datafield[@tag = 955]/marc:subfield[@code = \'b\']', namespaces)
      # strip leading "uiuc."
      item_params[:obj_id] = nodes.first.content.gsub(/^uiuc./, '').strip if nodes.any?

      # extract IA identifier from 955 subfield q
      nodes = record.
          xpath('marc:datafield[@tag = 955]/marc:subfield[@code = \'q\']', namespaces)
      item_params[:ia_identifier] = nodes.first.content.strip if nodes.any?

      item_params
    end

    def as_json(options = { })
      {
          id: self.id,
          bib_id: self.bib_id,
          oclc_number: self.oclc_number,
          obj_id: self.obj_id,
          title: self.title,
          author: self.author,
          volume: self.volume,
          date: self.date,
          url: self.url,
          catalog_url: self.uiuc_catalog_url,
          hathitrust_url: self.exists_in_hathitrust ?
              self.hathitrust_handle : nil,
          hathitrust_rights: self.hathitrust_rights,
          hathitrust_access: self.hathitrust_access,
          internet_archive_identifier: self.ia_identifier,
          internet_archive_url: self.exists_in_internet_archive ?
              self.internet_archive_url : nil,
          created_at: self.created_at,
          updated_at: self.updated_at
      }
    end

    ##
    # It is not possible to generate a link directly to a Google item, as
    # Google Books URLs use private IDs. Instead, this method returns a URL
    # of a search for the item.
    #
    # @return string
    #
    def google_url
      strip_characters = '`~!@#$%^&*()\\=[]{}|\\\"\'<>,.?/:;'
      blank_characters = '-_+'
      sanitized_title = self.title.tr(strip_characters, '').tr(blank_characters, ' ')
      sanitized_author = self.author.tr(strip_characters, '').tr(blank_characters, ' ')
      q = []
      q << 'intitle:' + sanitized_title.split(' ').select{ |t| t.length > 1 }.
          join(' intitle:') unless sanitized_title.blank?
      q << 'inauthor:' + sanitized_author.split(' ').select{ |t| t.length > 1 }.
          join(' inauthor:') unless sanitized_author.blank?
      "https://www.google.com/search?tbo=p&tbm=bks&q=#{q.join('+')}&num=10&gws_rd=ssl"
    end

    ##
    # @return [String] If self.exists_in_hathitrust is true, returns the
    # expected HathiTrust handle of the item. Otherwise, returns an empty
    # string.
    #
    def hathitrust_handle
      handle = ''
      if self.exists_in_hathitrust
        case self.service
          when Service::INTERNET_ARCHIVE
            handle = "https://hdl.handle.net/2027/uiuo.#{self.obj_id}"
          when Service::GOOGLE
            handle = "https://hdl.handle.net/2027/uiug.#{self.obj_id}"
          else # digitized locally or by vendors
            handle = "https://hdl.handle.net/2027/uiuc.#{self.obj_id}"
        end
      end
      handle
    end

    ##
    # Returns the expected Internet Archive URL of the item. If the item does not
    # exist in Internet Archive, the URL will be broken. The URL should work if
    # if self.exists_in_internet_archive is true.
    #
    # @return string
    #
    def internet_archive_url
      "https://archive.org/details/#{self.ia_identifier}"
    end

    def service
      if self.obj_id.start_with?('ark:/')
        Service::INTERNET_ARCHIVE
      elsif self.obj_id.length == 14 and self.obj_id[0] == '3'
        # It's a Google record if the object ID is a barcode. Barcodes are 14
        # digits and start with number 3.
        Service::GOOGLE
      end
    end

    def to_csv(options = {})
      CSV.generate(options) do |csv|
        # columns must be kept in sync with CSV_HEADER
        csv << [ self.bib_id, self.id, self.oclc_number, self.obj_id,
                 self.title, self.author, self.volume, self.date,
                 self.ia_identifier, self.hathitrust_handle,
                 self.exists_in_hathitrust, self.exists_in_internet_archive,
                 self.exists_in_google]
      end
    end

    def uiuc_catalog_url
      "https://vufind.carli.illinois.edu/vf-uiu/Record/uiu_#{self.bib_id}"
    end

    private

    def truncate_values
      self.author = self.author[0..254] if self.author and self.author.length > 255
      self.date = self.date[0..254] if self.date and self.date.length > 255
      self.title = self.title[0..254] if self.title and self.title.length > 255
      self.volume = self.volume[0..254] if self.volume and self.volume.length > 255
    end

  end

end
