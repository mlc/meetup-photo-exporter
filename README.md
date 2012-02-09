Meetup Photo Copier
===================

To deploy to heroku:

```
heroku create -s cedar mup-copier
heroku config:add RACK_ENV=production
git push heroku master
```