#Use to collect general methods that more specific ingestors may want to use
#Also has concept of package_path to hold the root of the ingest package
#Subclasses should typically define the ingest method, which will ingest the package
#based at package_path
module Medusa
  class GenericIngestor

    attr_accessor :package_root

    def initialize(package_root)
      self.package_root = package_root
      ActiveFedora.init
    end

    #If there is an object with the given pid delete it
    #Create a new object with the given class and yield to the block
    #return the new object
    def with_fresh_object(pid, klass = ActiveFedora::Base)
      begin
        object = klass.load_instance(pid)
        object.delete unless object.nil?
      rescue ActiveFedora::ObjectNotFoundError
        #nothing
      end
      klass.new(:pid => pid).tap do |object|
        yield object
      end
    end

    #return a Nokogiri::XML::Document on the file contents
    def file_to_xml(file)
      Nokogiri::XML::Document.parse(File.read(file))
    end

    def ingest
      raise NotImplementedError, "Subclass responsibility"
    end

    def add_xml_datastream(object, dsid, xml_string_or_doc, options = {})
      object.create_datastream(ActiveFedora::NokogiriDatastream, dsid,
                               options.reverse_merge(:controlGroup => 'X', :dsLabel => dsid)).tap do |datastream|
        datastream.content = xml_string_or_doc.to_s
        object.add_datastream(datastream)
      end
    end

    def add_xml_datastream_from_file(object, dsid, file, options = {})
      add_xml_datastream(object, dsid, File.open(file).read, options)
    end

  end
end