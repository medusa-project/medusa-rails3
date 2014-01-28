require 'uiuc_ldap' #we may not need this here, but this will ensure it is available for anything  that needs it
class Ability
  include CanCan::Ability

  def initialize(user)
    #medusa admins can do anything
    can :manage, :all if medusa_admin?(user)
    #Assessments - must be done for each assessable, where the real check occurs
    [Collection, FileGroup, ExternalFileGroup, BitLevelFileGroup, ObjectLevelFileGroup, Repository].each do |klass|
      can [:create_assessment, :update_assessment], klass do |assessable|
        (assessable.is_a?(klass) and repository_manager?(user, assessable))
      end
    end
    #Attachments - must be done for each attachable, where the real check occurs
    [Collection].each do |klass|
      can [:create_attachment, :update_attachment], klass do |attachable|
        (attachable.is_a?(klass) and repository_manager?(user, attachable))
      end
    end
    can [:update, :create], Collection do |collection|
      repository_manager?(user, collection)
    end
    #Events - must be done for each eventable, where the real check occurs
    [FileGroup, BitLevelFileGroup, ObjectLevelFileGroup, ExternalFileGroup].each do |klass|
      can :create_event, klass do |eventable|
        repository_manager?(user, eventable)
      end
    end
    #File groups - do for all subclasses, though I'm not sure this is strictly necessary
    [FileGroup, BitLevelFileGroup, ObjectLevelFileGroup, ExternalFileGroup].each do |klass|
      can [:update, :create, :create_cfs_fits, :create_virus_scan], klass do |file_group|
        repository_manager?(user, file_group)
      end
    end
  end


  def medusa_admin?(user)
    ApplicationController.is_member_of?('Library Medusa Admins', user, 'uofi')
  end

  def repository_manager?(user, object)
    object.repository.manager?(user)
  end

end
