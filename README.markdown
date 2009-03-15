Jitter
======

A super-hackable Twitter-Jabber client. I wrote this because I didn't like that most twitter clients fought for my attention by popping up all the time. Certainly I could've turned that off, but really I didn't want any specific twitter client running at all. I already use IM, and I'm used to ignoring that when I'm 'in the zone', so I figured I would give it a shot instead.

Other notable features are:

  * Direct messaging works (prefix your tweet with 'd <username>'); you'll also receive DM's back
  * Searches work too


Setup
-----

Before you can use jitter, you'll need to create it a 'gateway' jabber account. This is the jabber account which the script will appear as in your roster - the account to which you'll send messages, and from which tweets will come from. Figuring out how to do that is, alas, your problem. I use Google Apps for your domain, where it's simply a case of enabled Google Talk, making sure the DNS records are set up and then creating a user.

Anyway, once all that's done, run

    jitter config
    
to create the configuration file in your home directory. You'll then be dropped into an IRB session where you can edit the config, but behind the scenes, it's stored as YAML. Here's what a fresh one looks like:

    --- 
    :twitter: 
      :username: YOUR_USERNAME
      :password: YOUR_PASSWORD
    :searches: []
    :accept_from: YOUR_JABBER_ACCOUNT
    :jabber: 
      :username: JABBER_TWITTER_GATEWAY_ACCOUNT
      :password: PASSWORD

Cool, refreshing YAML, right? Enter your twitter credentials - that's straightforward. Enter *your* jabber account in 'accept_from'; that's the account that you'll be sending messages from. In my case, it's james@lazyatom.com.

Enter the 'gateway' account details in the 'jabber' section. For this, I created another account @lazyatom.com, and a random password.

Then run

    jitter start
    
and add your gateway account to your Jabber IM client!


Basic usage
-----------

Jitter will send you tweets from the people you follow every 30 seconds. It will also check your direct messages for you, and send them along too. The messages have some formatted, designed so that Adium presents the tweets in a nice, clear way. Feel free to hack around with that in `Jitter#formatted_for_jabber`.

To send a direct message, just start your message with `d username`, same as Twitteriffic. Couldn't be simpler.