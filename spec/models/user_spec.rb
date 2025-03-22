require 'rails_helper'

RSpec.describe User, type: :model do
let(:user) { build(:user) }

describe 'factories' do
    it 'has a valid default factory' do
    expect(user).to be_valid
    end

    it 'has a valid factory with admin role' do
    admin = build(:user, :admin)
    expect(admin).to be_valid
    expect(admin.admin?).to be true
    end

    it 'has a valid factory with website' do
    user_with_website = build(:user, :with_website)
    expect(user_with_website).to be_valid
    expect(user_with_website.website).to be_present
    end

    it 'has a valid factory with bio' do
    user_with_bio = build(:user, :with_bio)
    expect(user_with_bio).to be_valid
    expect(user_with_bio.bio).to be_present
    end
end

describe 'validations' do
    context 'email' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    
    it 'validates email format' do
        valid_emails = ['user@example.com', 'user.name@domain.com', 'user+label@domain.co.uk']
        invalid_emails = ['user@', '@domain.com', 'user@.com', 'user@domain.', 'user.domain.com']

        valid_emails.each do |email|
        user.email = email
        expect(user).to be_valid
        end

        invalid_emails.each do |email|
        user.email = email
        expect(user).not_to be_valid
        end
    end
    end

context 'username' do
it { should validate_presence_of(:username) }
it { should validate_uniqueness_of(:username).case_insensitive }
it { should validate_length_of(:username).is_at_least(3).is_at_most(30) }

it 'validates username format' do
    valid_usernames = ['john123', 'jane_doe', 'test_user_123']
    invalid_usernames = ['ab', 'user name', 'user@name', 'user#name']

    valid_usernames.each do |username|
    user.username = username
    expect(user).to be_valid
    end

    invalid_usernames.each do |username|
    user.username = username
    expect(user).not_to be_valid
    end
end
end
context 'password' do
it { should validate_presence_of(:password) }
it { should validate_length_of(:password).is_at_least(12) }

it 'requires password to include at least one uppercase, one lowercase, and one number' do
    valid_passwords = ['StrongPassword123', 'ComplexPass1234', 'SecurePassw0rd']
    invalid_passwords = ['password12345678', 'UPPERCASE12345', '12345678901234', 'Pass word 123']

    valid_passwords.each do |password|
    user.password = password
    expect(user).to be_valid
    end

    invalid_passwords.each do |password|
    user.password = password
    expect(user).not_to be_valid
    end
end
end

context 'password expiration' do
let(:user) { create(:user) }

it 'requires password change after 6 months' do
    user.password_changed_at = 7.months.ago
    expect(user.need_change_password?).to be true
end

it 'does not require password change before 6 months' do
    user.password_changed_at = 5.months.ago
    expect(user.need_change_password?).to be false
end

it 'updates password_changed_at when password is changed' do
    original_change_time = user.password_changed_at
    Timecop.travel(7.months.from_now) do
    user.password = 'NewStrongPass123'
    user.password_confirmation = 'NewStrongPass123'
    user.save
    expect(user.password_changed_at).to be > original_change_time
    end
end
end

context 'password archiving and reuse' do
let(:user) { create(:user, password: 'InitialPass123!') }

it 'stores old passwords' do
    expect {
    user.password = 'NewPassword123!'
    user.password_confirmation = 'NewPassword123!'
    user.save
    }.to change(OldPassword, :count).by(1)
end

it 'prevents reuse of last 5 passwords' do
    old_passwords = [
    'OldPassword123!',
    'OldPassword234!',
    'OldPassword345!',
    'OldPassword456!',
    'OldPassword567!'
    ]

    old_passwords.each do |password|
    user.password = password
    user.password_confirmation = password
    user.save
    end

    user.password = old_passwords.first
    user.password_confirmation = old_passwords.first
    expect(user).not_to be_valid
    expect(user.errors[:password]).to include('cannot reuse last 5 passwords')
end

it 'allows reuse of passwords older than last 5' do
    initial_password = user.password
    6.times do |i|
    user.password = "NewPassword#{i}123!"
    user.password_confirmation = "NewPassword#{i}123!"
    user.save
    end

    user.password = initial_password
    user.password_confirmation = initial_password
    expect(user).to be_valid
end
end

context 'profile fields' do
it { should validate_length_of(:bio).is_at_most(500) }
it { should validate_length_of(:first_name).is_at_most(50) }
it { should validate_length_of(:last_name).is_at_most(50) }

it 'validates website format' do
    valid_websites = ['https://example.com', 'http://test.com', 'https://sub.domain.co.uk']
    invalid_websites = ['not-a-url', 'ftp://invalid.com', 'just.com']

    valid_websites.each do |website|
    user.website = website
    expect(user).to be_valid
    end

    invalid_websites.each do |website|
    user.website = website
    expect(user).not_to be_valid
    end
end
end
end

    context 'email format' do
    it 'allows valid email addresses' do
        valid_emails = ['user@example.com', 'USER@foo.COM', 'A_US-ER@foo.bar.org']
        valid_emails.each do |email|
        user.email = email
        expect(user).to be_valid
        end
    end

    it 'rejects invalid email addresses' do
        invalid_emails = ['user@example,com', 'user_at_foo.org', 'user.name@example.']
        invalid_emails.each do |email|
        user.email = email
        expect(user).not_to be_valid
        end
    end
    end

    context 'username format' do
    it 'allows valid usernames' do
        valid_usernames = ['john123', 'jane_doe', 'test_user_123']
        valid_usernames.each do |username|
        user.username = username
        expect(user).to be_valid
        end
    end

    it 'rejects invalid usernames' do
        invalid_usernames = ['j', 'a b', 'user@name']
        invalid_usernames.each do |username|
        user.username = username
        expect(user).not_to be_valid
        end
    end
    end
end

describe 'associations' do
describe 'posts association' do
    it 'has many posts' do
    user = create(:user)
    post = create(:post, user: user)
    expect(user.posts).to include(post)
    end
    
    it 'destroys dependent posts when user is destroyed' do
    user = create(:user)
    create(:post, user: user)
    expect { user.destroy }.to change { Post.count }.by(-1)
    end
end

describe 'comments association' do
    it 'has many comments' do
    user = create(:user)
    comment = create(:comment, user: user)
    expect(user.comments).to include(comment)
    end
    
    it 'destroys dependent comments when user is destroyed' do
    user = create(:user)
    create(:comment, user: user)
    expect { user.destroy }.to change { Comment.count }.by(-1)
    end
end

describe 'likes association' do
    it 'has many likes' do
    user = create(:user)
    like = create(:like, user: user)
    expect(user.likes).to include(like)
    end
    
    it 'destroys dependent likes when user is destroyed' do
    user = create(:user)
    create(:like, user: user)
    expect { user.destroy }.to change { Like.count }.by(-1)
    end
end

describe 'liked_posts association' do
    it 'has many liked posts through likes' do
    user = create(:user)
    post = create(:post)
    like = create(:like, user: user, post: post)
    expect(user.liked_posts).to include(post)
    end
end

describe 'followers association' do
    it 'has many followers' do
    user = create(:user)
    follower = create(:user)
    follow = Follow.create(follower: follower, followed: user)
    expect(user.followers).to include(follow)
    end
    
    it 'uses the correct class name and foreign key' do
    expect(User.reflect_on_association(:followers).options[:class_name]).to eq('Follow')
    expect(User.reflect_on_association(:followers).options[:foreign_key]).to eq('followed_id')
    end
end

describe 'following association' do
    it 'has many following' do
    user = create(:user)
    followed = create(:user)
    follow = Follow.create(follower: user, followed: followed)
    expect(user.following).to include(follow)
    end
    
    it 'uses the correct class name and foreign key' do
    expect(User.reflect_on_association(:following).options[:class_name]).to eq('Follow')
    expect(User.reflect_on_association(:following).options[:foreign_key]).to eq('follower_id')
    end
end

describe 'avatar association' do
    it 'has one attached avatar' do
    user = create(:user)
    file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'avatar.jpg'), 'image/jpeg')
    user.avatar.attach(file)
    expect(user.avatar).to be_attached
    end
end
end

describe 'instance methods' do
describe '#full_name' do
    context 'when first_name and last_name are present' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe') }
    
    it 'returns the full name' do
        expect(user.full_name).to eq('John Doe')
    end
    end

    context 'when only first_name is present' do
    let(:user) { build(:user, first_name: 'John', last_name: nil) }
    
    it 'returns only the first name' do
        expect(user.full_name).to eq('John')
    end
    end

    context 'when only last_name is present' do
    let(:user) { build(:user, first_name: nil, last_name: 'Doe') }
    
    it 'returns only the last name' do
        expect(user.full_name).to eq('Doe')
    end
    end

    context 'when neither name is present' do
    let(:user) { build(:user, first_name: nil, last_name: nil) }
    
    it 'returns an empty string' do
        expect(user.full_name).to eq('')
    end
    end
end

describe '#display_name' do
    context 'when full name is available' do
    let(:user) { build(:user, first_name: 'John', last_name: 'Doe', username: 'johndoe') }
    
    it 'returns the full name' do
        expect(user.display_name).to eq('John Doe')
    end
    end

    context 'when full name is not available' do
    let(:user) { build(:user, first_name: nil, last_name: nil, username: 'johndoe') }
    
    it 'returns the username' do
        expect(user.display_name).to eq('johndoe')
    end
    end
end

describe '#active_for_authentication?' do
    context 'when user is active' do
    let(:user) { build(:user, suspended: false) }
    
    it 'returns true' do
        expect(user.active_for_authentication?).to be true
    end
    end

    context 'when user is suspended' do
    let(:user) { build(:user, suspended: true) }
    
    it 'returns false' do
        expect(user.active_for_authentication?).to be false
    end
    end
end

describe '#online?' do
    context 'when last active within 5 minutes' do
    let(:user) { build(:user, last_active_at: 4.minutes.ago) }
    
    it 'returns true' do
        expect(user.online?).to be true
    end
    end

    context 'when last active more than 5 minutes ago' do
    let(:user) { build(:user, last_active_at: 6.minutes.ago) }
    
    it 'returns false' do
        expect(user.online?).to be false
    end
    end
end
end
