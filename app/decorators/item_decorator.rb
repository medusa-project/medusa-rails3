class ItemDecorator < BaseDecorator

  def search_barcode_link
    h.link_to(self.barcode.if_blank('<no barcode>'), h.item_path(self))
  end

  def search_project_link
    h.link_to(self.project_title, h.project_path(self.project))
  end

  def search_batch_link
    if self.batch.present?
      h.link_to(self.batch, h.project_path(self.project, batch: self.batch))
    else
      ''
    end
  end

  #TODO: create the checkbox - disable unless user can actually use
  def assign_checkbox(project)
    h.check_box_tag('', self.id, false, name: 'assign_batch[assign][]', id: "assign_batch_assign_#{self.id}", disabled: !h.safe_can?(:update, project))
  end

  #TODO: create the buttons
  def action_buttons
    h.small_edit_button(self) + ' ' + h.small_clone_button(h.new_item_path(source_id: self.id), method: :get)
  end

end