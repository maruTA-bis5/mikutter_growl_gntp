mikutter_growl_gntp
===================

show mikutter notifications via growl using ruby_gntp.


なんぞこれ
----------

mikutterの通知をGrowlにGNTP(Growl Notification Transport Protocol)を用いて送信するプラグインです。


使い方
------

- 「通知」設定で、Growlに通知したい項目の「ポップアップ」にチェックを入れてください
- 「Growl通知」設定で、通知に用いるアプリケーション名、通知先ホスト、パスワード、ポート番号を設定してください。


依存関係
--------

- ruby_gntpが必要です。`gem install ruby_gntp`または`bundle install`でインストールしてください。
- settings, notifyプラグインに依存します。

問い合わせ
----------

- Twitter http://twitter.com/maruTA_bis5
- Github @bis5
