class User < ActiveRecord::Base
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable#, :validatable
  has_many :documents

  enum user_type: {user: "user", moderator: "moderator", admin: "admin", sysadmin: "sysadmin"}

  validates :user_type, inclusion: { in: User::user_types.keys}

  def is_admin?
    user_type == User::user_types[:admin]
  end

  def is_user?
    user_type == User::user_types[:user]
  end

  def is_sysadmin?
    user_type == User::user_types[:sysadmin]
  end

  def is_moderator?
    user_type == User::user_types[:moderator]
  end
end
