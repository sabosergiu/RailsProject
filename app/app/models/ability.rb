class Ability
  include CanCan::Ability

  def initialize(user)
    if !user
      return
    end
    if user.is_simple_user?
      can :read, Category
      #can :read, 
    end
    if user.is_moderator?
      can :read, Category
      can :create, Category
      #file permissions
    end
    if user.is_admin?
      can :read, Category
      can :create, Category
      can :update, Category
      can :read, Users :user_type => nil||'admin'||'moderator'
      can :update,Users :id => user.id 
      can :update, Users :user_type => nil||'moderator'
    end
    if user.is_sysadmin?
      can :read, Category
      can :create, Category
      can :update, Category
      alias_action :create, :read, :update, :destroy, :to => :crud
      can :crud, User
    end
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
  end
end
