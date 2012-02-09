Meetup Photo Copier
===================

To deploy to heroku:

```
heroku create -s cedar mup-copier
heroku config:set RACK_ENV=production
heroku config:set SESSION_SECRET=`dd if=/dev/urandom bs=30 count=1 | openssl base64`
git push heroku master
```