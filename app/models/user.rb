class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true, length: { maximum: 20 }

  has_many :posts
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy

  has_many :friendships
  has_many :friends, through: :friendships
  has_many :posts_from_friends, through: :friends, source: :posts
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id'

  def friends
    friendships.map { |friendship| friendship.friend if friendship.confirmed }.compact
  end

  # Users who have yet to confirme friend requests
  def pending_friends
    friendships.map { |friendship| friendship.friend unless friendship.confirmed }.compact
  end

  # Users who have requested to be friends
  def friend_requests
    inverse_friendships.map { |friendship| friendship.user unless friendship.confirmed }.compact
  end

  def confirm_friend(user)
    person = inverse_friendships.find { |friendship| friendship.user == user }
    person.confirmed = true
    person.save
    Friendship.create!(user_id: id, friend_id: user.id, confirmed: true)
  end

  def reject_friendship(user)
    friendship = inverse_friendships.find { |f| f.user == user }
    friendship.destroy
  end

  def friend?(user)
    friends.include?(user)
  end

  def timeline_posts
    posts.ordered_by_most_recent
  end

  def friends_posts
    posts_from_friends.ordered_by_most_recent
  end
end
