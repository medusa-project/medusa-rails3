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
                                         cfs_directory_id: file_group.cfs_directory.id,
                                         date: Date.today)
        amazon_backup.save!
        Job::AmazonBackup.create_for(amazon_backup)
      end
    end
    redirect_to dashboard_path
  end

  def create_initial_cfs_assessment
    @file_group = BitLevelFileGroup.find(params[:id])
    authorize! :create_cfs_fits, @file_group
    x = @file_group.is_currently_assessable?
    y = Job::CfsInitialFileGroupAssessment.find_by(file_group_id: @file_group.id)
    z = Job::CfsInitialDirectoryAssessment.find_by(file_group_id: @file_group.id)
    if @file_group.is_currently_assessable?
      @file_group.schedule_initial_cfs_assessment
      flash[:notice] = 'CFS simple assessment scheduled'
    else
      flash[:notice] = 'CFS simple assessment already underway for this file group. Please try again later.'
    end
    redirect_to @file_group
  end

end
