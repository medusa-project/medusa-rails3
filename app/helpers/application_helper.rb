module ApplicationHelper

  def link_to_external(name, url, opts = {})
    link_to name, external_url(url), opts.merge(:target => '_blank')
  end

  #if url doesn't contain the protocol then add it here
  def external_url(url)
    if url.blank?
      ''
    else
      url.match(/^http(s?):\/\//) ? url : "http://#{url}"
    end
  end

  #standard way to render a value in a show view
  def show_value(value, label)
    render 'shared/show_value', :label => label, :value => value
  end

  #standard way to render a field of a model in a show view, with custom label if needed
  def show_field(model, field, label = nil)
    label ||= field.to_s.titlecase
    show_value(model.send(field), label)
  end

  def generic_confirm_message
    'This is irreversible - are you sure?'
  end

  def wiki_link(label)
    link_to label, 'https://wiki.cites.uiuc.edu/wiki/display/LibraryDigitalPreservation/Home', :target => '_blank'
  end

  def date_picker_options(extra_opts = {})
    {:as => :string, :input_html => {'data-datepicker' => 'datepicker'},
     :order => [:day, :month, :year], :use_month_numbers => true}.merge(extra_opts)
  end

end
