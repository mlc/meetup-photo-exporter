Meetup Photo Copier
===================

Technologies used: Ruby 1.9, [sinatra], [heroku], [couchdb], etc.

To deploy to heroku:

```
heroku create -s cedar mup-copier
heroku config:set RACK_ENV=production
heroku config:set SESSION_SECRET=`dd if=/dev/urandom bs=30 count=1 | openssl base64`
heroku addons:add cloudant:oxygen
git push heroku master
```

Also, you need to set up the app with the various services (Meetup and the others), and set the appropriate config variables.

[sinatra]: http://www.sinatrarb.com/
[heroku]: http://www.heroku.com/
[couchdb]: https://couchdb.apache.org/