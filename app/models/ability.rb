require 'uiuc_ldap' #we may not need this here, but this will ensure it is available for anything  that needs it
class Ability
  include CanCan::Ability

  def initialize(user)
    can :manage, AccessSystem if medusa_admin?(user)
    #Assessments - must be done for each assessable, where the real check occurs
    [Collection, FileGroup, ExternalFileGroup, BitLevelFileGroup, ObjectLevelFileGroup, Repository].each do |klass|
      can :delete_assessment, klass if medusa_admin?(user)
      can :edit_assessment, klass do |collection|
        medusa_admin?(user) ||
            (collection.is_a?(klass) and repository_manager?(user, collection))
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
