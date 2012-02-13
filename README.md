Meetup Photo Copier
===================

Technologies used: Ruby 1.9, [sinatra], [heroku], [couchdb], [iron worker], etc.

To deploy to heroku:

```
heroku create -s cedar mup-copier
heroku config:set RACK_ENV=production
heroku config:set SESSION_SECRET=`dd if=/dev/urandom bs=30 count=1 | openssl base64`
heroku addons:add cloudant:oxygen
heroku addons:add iron_worker:starter
git push heroku master
```

Also, you need to set up the app with the various services (Meetup and the others), and set the appropriate config variables.

[sinatra]: http://www.sinatrarb.com/
[heroku]: http://www.heroku.com/
[couchdb]: https://couchdb.apache.org/
[iron worker]: http://www.iron.io/products/worker
