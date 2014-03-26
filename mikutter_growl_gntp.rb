# -*- coding: utf-8 -*-
require "rubygems"
require "ruby_gntp"

class Plugin::Settings::Listener
  def self.[](symbol)
    return symbol if(symbol.is_a? Plugin::Settings::Listener)
    if symbol == :growl_password || symbol == :growl_appname || symbol == :growl_target || symbol == :growl_port
      Plugin::Settings::Listener.new(
        :get => lambda{ UserConfig[symbol] },
        :set => lambda{ |val|
          UserConfig[symbol] = val
          Plugin[:mikutter_growl_gntp].gntp_init
        }
      )
    else
      Plugin::Settings::Listener.new(
        :get => lambda{ UserConfig[symbol] },
        :set => lambda{ |val| UserConfig[symbol] = val }
      )
    end
  end
end
Plugin.create(:mikutter_growl_gntp) do

  settings("Growl") do
    settings("Growl通知設定 - 「通知」の設定を忘れずに！") do
      input "Growl通知に利用するアプリケーション名", :growl_appname
      input "通知先ホスト（自ホストならlocalhost）", :growl_target
      inputpass "パスワード", :growl_password
      adjustment "通知先ポート（デフォルト：23053）", :growl_port, 0, 65535
    end
  end

  UserConfig[:growl_appname] = "mikutter" if UserConfig[:growl_appname].nil?
  UserConfig[:growl_target] = "localhost" if UserConfig[:growl_target].nil?
  UserConfig[:growl_port] = 23053 if UserConfig[:growl_port].nil?
  UserConfig[:growl_password] = "" if UserConfig[:growl_password].nil?

  onupdate do |post, raw_messages|
    messages = Plugin.filtering(:show_filter, raw_messages.select{ |m| not(m.from_me? or m.to_me?) and m[:created] > DEFINED_TIME }).first
    if not(messages.empty?)
      if(UserConfig[:notify_friend_timeline])
        messages.each{ |message|
          notify(message[:user], message, "update") if not message.from_me? } end end end

  onmention do |post, raw_messages|
    messages = Plugin.filtering(:show_filter, raw_messages.select{ |m| not(m.from_me? or m[:retweet]) and m[:created] > DEFINED_TIME }).first
    if not(messages.empty?)
      if(not(UserConfig[:notify_friend_timeline]) and UserConfig[:notify_mention])
        messages.each{ |message|
          notify(message[:user], message, "mention") } end end end

  on_followers_created do |post, users|
    if not(users.empty?)
      if(UserConfig[:notify_followed])
        users.each{ |user|
          notify(users.first, __('%{users} にフォローされました。') % {users: users.map{|u| "@#{u[:idname]}" }.join(' ')}, "followers_created") } end end end

  on_followers_destroy do |post, users|
    if not(users.empty?)
      if(UserConfig[:notify_removed])
        self.notify(users.first, __('%{users} にリムーブされました。') % {users: users.map{|u| "@#{u[:idname]}" }.join(' ')}, "followers_destroy") end end end

  on_favorite do |service, by, to|
    if to.from_me?
      if(UserConfig[:notify_favorited])
        notify(by, __("fav by %{from_user} \"%{tweet}\"") % {
                      from_user: by[:idname],
                      tweet: to.to_s }, "favorite") end end end

  onmention do |post, raw_messages|
    messages = Plugin.filtering(:show_filter, raw_messages.select{ |m| m[:retweet] and not m.from_me? }).first
    if not(messages.empty?)
      if(UserConfig[:notify_retweeted])
        messages.each{ |message|
          notify(message[:user], __('ReTweet: %{tweet}') % {tweet: message.to_s}, "retweeted") } end end end

  on_direct_messages do |post, dms|
    newer_dms = dms.select{ |dm| Time.parse(dm[:created_at]) > DEFINED_TIME }
    if not(newer_dms.empty?)
      if(UserConfig[:notify_direct_message])
        newer_dms.each{ |dm|
          notify(User.generate(dm[:sender]), dm[:text], "direct_messages") } end end end

  def gntp_init
    appname = UserConfig[:growl_appname] 
    host = UserConfig[:growl_target] 
    pass = UserConfig[:growl_password] 
    port = UserConfig[:growl_port]
    @growl = GNTP.new appname, host, pass, port
    begin 
      @growl.register({:notifications => [{
        :name  => "update",
        :enabled => true,
      }, {
        :name => "mention",
        :enabled => true,
      }, {
        :name => "followers_created",
        :enabled => true,
      }, {
        :name => "followers_destroy",
        :enabled => true,
      }, {
        :name => "favorite",
        :enabled => true,
      }, {
        :name => "retweeted",
        :enabled => true,
      }, {
        :name => "direct_messages",
        :enabled => true,
      }]})
    rescue => e
      notice e.class
    end
  end
      
  def notify(user, text, type)
    gntp_init if @growl.nil?
    text = text.to_show if text.is_a? Message
    begin
      @growl.notify({
        :name => type,
        :title => "@#{user[:idname]} (#{user[:name]})",
        :text => text,
        :icon => "file://"+Gdk::WebImageLoader.local_path(user[:profile_image_url]),
      })
    end
  end

  def __(txt) 
    if defined? _
      _(txt)
    else
      txt
    end
  end
end
