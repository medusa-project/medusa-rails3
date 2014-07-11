class BitLevelFileGroupsController < FileGroupsController

  def create_amazon_backup
    @file_group = BitLevelFileGroup.find(params[:id])
    authorize! :create_amazon_backup, @file_group
    amazon_backup = AmazonBackup.create(user_id: current_user.id,
                                        cfs_directory_id: @file_group.cfs_directory.id,
                                        date: Date.today)
    Job::AmazonBackup.create_for(amazon_backup)
    redirect_to @file_group
  end

  def bulk_amazon_backup
    authorize! :create_amazon_backup, BitLevelFileGroup
    if params[:bit_level_file_groups].present?
      params[:bit_level_file_groups].each do |file_group_id|
        file_group = BitLevelFileGroup.find(file_group_id)
        amazon_backup = AmazonBackup.new(user_id: current_user.id,
                                            cfs_directory_id: file_group.cfs_directory_id,
                                            date: Date.today)
        amazon_backup.save!
        Job::AmazonBackup.create_for(amazon_backup)
      end
    end
    redirect_to dashboard_path
  end

end
