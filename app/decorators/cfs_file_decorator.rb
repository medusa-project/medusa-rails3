class CfsFileDecorator < BaseDecorator

  def label
    object.relative_path
  end

  def cfs_label
    object.relative_path
  end

  def cfs_type
    'CFS File'
  end

end