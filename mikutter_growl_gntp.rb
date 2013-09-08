# -*- coding: utf-8 -*-
require "rubygems"
require "ruby_gntp"

Plugin.create(:mikutter_growl_gntp) do

  settings("growl") do
    input "Growl通知に利用するアプリケーション名", :growl_appname
    if UserConfig[:growl_appname].nil?
      UserConfig[:growl_appname] = "mikutter" end
  end

  onupdate do |post, raw_messages|
    messages = Plugin.filtering(:show_filter, raw_messages.select{ |m| not(m.from_me? or m.to_me?) and m[:created] > DEFINED_TIME }).first
    if not(messages.empty?)
      if(UserConfig[:notify_friend_timeline])
        messages.each{ |message|
          self.notify(message[:user], message) if not message.from_me? } end
      if(UserConfig[:notify_sound_friend_timeline])
        self.notify_sound(UserConfig[:notify_sound_friend_timeline]) end end end

  onmention do |post, raw_messages|
    messages = Plugin.filtering(:show_filter, raw_messages.select{ |m| not(m.from_me? or m[:retweet]) and m[:created] > DEFINED_TIME }).first
    if not(messages.empty?)
      if(not(UserConfig[:notify_friend_timeline]) and UserConfig[:notify_mention])
        messages.each{ |message|
          self.notify(message[:user], message) } end
      if(UserConfig[:notify_sound_mention])
        self.notify_sound(UserConfig[:notify_sound_mention]) end end end

  on_followers_created do |post, users|
    if not(users.empty?)
      if(UserConfig[:notify_followed])
        users.each{ |user|
          self.notify(users.first, _('%{users} にフォローされました。') % {users: users.map{|u| "@#{u[:idname]}" }.join(' ')}) } end
      if(UserConfig[:notify_sound_followed])
        self.notify_sound(UserConfig[:notify_sound_followed]) end end end

  on_followers_destroy do |post, users|
    if not(users.empty?)
      if(UserConfig[:notify_removed])
        self.notify(users.first, _('%{users} にリムーブされました。') % {users: users.map{|u| "@#{u[:idname]}" }.join(' ')}) end
      if(UserConfig[:notify_sound_removed])
        self.notify_sound(UserConfig[:notify_sound_removed]) end end end

  on_favorite do |service, by, to|
    if to.from_me?
      if(UserConfig[:notify_favorited])
        self.notify(by, _("fav by %{from_user} \"%{tweet}\"") % {
                      from_user: by[:idname],
                      tweet: to.to_s }) end
      if(UserConfig[:notify_sound_favorited])
        self.notify_sound(UserConfig[:notify_sound_favorited]) end end end

  onmention do |post, raw_messages|
    messages = Plugin.filtering(:show_filter, raw_messages.select{ |m| m[:retweet] and not m.from_me? }).first
    if not(messages.empty?)
      if(UserConfig[:notify_retweeted])
        messages.each{ |message|
          self.notify(message[:user], _('ReTweet: %{tweet}') % {tweet: message.to_s}) } end
      if(UserConfig[:notify_sound_retweeted])
        self.notify_sound(UserConfig[:notify_sound_retweeted]) end end end

  on_direct_messages do |post, dms|
    newer_dms = dms.select{ |dm| Time.parse(dm[:created_at]) > DEFINED_TIME }
    if not(newer_dms.empty?)
      if(UserConfig[:notify_direct_message])
        newer_dms.each{ |dm|
          self.notify(User.generate(dm[:sender]), dm[:text]) } end
      if(UserConfig[:notify_sound_direct_message])
        self.notify_sound(UserConfig[:notify_sound_direct_message]) end end end

  def self.notify(user, text)
    GNTP.notify({
      :app_name => UserConfig[:growl_appname],
      :title => "@#{user[:idname]} (#{user[:name]})",
      :text => text,
      :icon => "file://"+Gdk::WebImageLoader.local_path(user[:profile_image_url]),
    })
  end

  def self.notify_sound(sndfile)
  end
end
