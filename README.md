## How to run:

1. Get a Telegram bot token
2. Get a Geonames username
3. Install Ruby: https://www.ruby-lang.org/en/documentation/installation/
   * After you're done, also install ruby-dev for your version of ruby: `sudo apt-get install ruby`ruby -e 'puts RUBY_VERSION[/\d+\.\d+/]'`-dev
`
4. Install Bundler: `sudo gem install bundler`
5. Install Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
6. Install libsqlite3-dev
7. Run `bundle install` on the bot directory.
8. Set up the SecretariaBot systemd service by running: `ansible-playbook ./secretariabot.yml`. Follow the on-screen instructions.
