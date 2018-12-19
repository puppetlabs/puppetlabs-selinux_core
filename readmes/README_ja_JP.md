
# selinux_core

#### 目次

1. [説明](#description)
2. [セットアップ - selinux_coreモジュール導入の基本](#setup)
    * [セットアップ要件](#setup-requirements)
3. [使用 - 設定オプションと追加機能](#usage)
4. [リファレンス - ユーザマニュアル](#reference)
5. [制約 - OS互換性など](#limitations)
6. [開発 - モジュール貢献についてのガイド](#development)

<a id="description"></a>
## 説明

ファイルのSELinuxコンテキストを管理します。

<a id="setup"></a>
## セットアップ

<a id="setup-requirements"></a>
### セットアップ要件

selinuxモジュールを使用するためには、システム上で `selinux` rubyバインディングを使用できる状態になっている必要があります。

<a id="usage"></a>
## 使用

ファイルでSELinuxコンテキストを設定するには、以下のコードを使用します。
```
file { "/path/to/file":
  selinux_ignore_defaults => false,
  selrange => 's0',
  selrole => 'object_r',
  seltype => 'krb5_home_t',
  seluser => 'user_u',
}
```

SELinuxポリシーモジュールを管理するには、以下のコードを使用します。
```
selmodule { 'selmodule_policy':
  ensure => present,
  selmoduledir => '/usr/share/selinux/targeted',
}
```

SELinuxブーリアンを管理するには、以下のコードを使用します。
```
selboolean { 'collectd_tcp_network_connect':
  persistent => true,
  value => on,
}
```

<a id="reference"></a>
## リファレンス

REFERENCE.mdの参考文書と、[ファイルタイプのselinuxセクション](https://puppet.com/docs/puppet/latest/types/file.html#file-attribute-selinux_ignore_defaults)を参照してください。

このモジュールは、Puppet Stringsを用いて文書化されています。

Stringsの仕組みの簡単な概要については、Puppet Stringsに関する[こちらのブログ記事](https://puppet.com/blog/using-puppet-strings-generate-great-documentation-puppet-modules)または[README.md](https://github.com/puppetlabs/puppet-strings/blob/master/README.md)を参照してください。

文書をローカルで作成するには、以下のコードを実行します。
```
bundle install
bundle exec puppet strings generate ./lib/**/*.rb
```
このコマンドにより、閲覧可能な`\_index.html`ファイルが`doc`ディレクトリに作成されます。ここで利用可能なリファレンスはすべて、コードベースに埋め込まれたYARD形式のコメントから生成されます。このモジュールに関して何らかの開発をする場合は、影響を受ける文書も更新する必要があります。

<a id="limitations"></a>
## 制約

このモジュールは、selinux rubyバインディングを使用できるプラットフォームでのみ使用可能です。

<a id="development"></a>
## 開発

Puppet ForgeのPuppet Labsモジュールは、オープンプロジェクトです。プロジェクトをさらに発展させるには、コミュニティへの貢献が不可欠です。Puppetが役立つ可能性のある膨大な数のプラットフォーム、無数のハードウェア、ソフトウェア、デプロイメント構成に我々がアクセスすることはできません。

弊社は、できるだけ変更に貢献しやすくして、弊社のモジュールがユーザの環境で機能する状態を維持したいと考えています。弊社では、状況を把握できるよう、貢献者に従っていただくべきいくつかのガイドラインを設けています。

詳細については、[モジュール貢献ガイド](https://docs.puppetlabs.com/forge/contributing.html)を参照してください。
