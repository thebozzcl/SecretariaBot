# SecretariaBot: a meeting scheduling helper bot for Telegram

## What is this?

This is a Telegram bot I built for a group chat with some friends. We're spread all over the world, so it's hard for us to decide meeting times because of timezones. Somebody on the group thought a bot to figure this out automatically would be a good idea... and then challenged me to code it.

Eh, I didn't have anything better to do, so I took the bait.

I used the project as a chance to learn a few things:
*  Ruby, because I've almost never used it. Keep in mind, the codebase is pretty ugly because of this. Very Java-y.
*  Building a basic chat bot. This is not a conversational bot, it only supports commands.
*  Dealing with timezones. Ugh. That's the worst part of the project, I'm a bit embarrassed by how clumsy the code is.
   It works, though.

## How to run

1. Get a Telegram bot token
2. Get a Geonames username
3. Install Ruby: https://www.ruby-lang.org/en/documentation/installation/
   * After you're done, also install ruby-dev for your version of ruby: `sudo apt-get install ruby-dev`
4. Install Bundler: `sudo gem install bundler`
5. Install Ansible: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
6. Install libsqlite3-dev
7. Run `bundle install` on the bot directory.
8. Set up the SecretariaBot systemd service by running: `ansible-playbook ./secretariabot.yml`. Follow the on-screen
   instructions.

## Why "Secretaria"?

The moment I started the project, I immediately thought about the secretary bird character from Aggretsuko. In fact, my
first iterations of the bot used dialog that was pretty inspired by her. I toned it down later because it was a bit
abrassive sometimes.

I thought about using a picture of her as the project logo, but Sanrio wouldn't like that, probably.

## Pending work:
*  Fix that ugly, clumsy time translation code.
*  Re-organize the code so it's easier to navigate. I need to split around all the chat bot methods.
*  Unit tests. Seriously, I think this needs some to prevent regressions.
