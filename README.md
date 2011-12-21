Noticings Uploader iPhone app
=============================

This is the source code for the Noticings Uploader iPhone app, which is [available in the App Store][1].

[1]:http://itunes.apple.com/gb/app/noticings-uploader/id339183497?mt=8

It has moved on significantly since the version that's in the App Store, and we're working towards making it a great mobile uploader and browser for any purpose.

Getting started
---------------

It's fairly standard iPhone app, designed for iOS 4.3. The only things left out are the Flickr and TestFlight API keys - you'll need to get your own. Put them in `APIKeys.h`, like so:

    #define FLICKR_API_KEY @"keyhere"
    #define FLICKR_API_SECRET @"secrethere"
    #define TESTFLIGHT_API_KEY @""

Contributors
------------

* Tom Taylor
* Tom Insam 
* Tom Armitage
* Ben Terrett

Thanks
------

Thanks to lukhnos for [ObjectiveFlickr][2] which is awesome. ObjectiveFlickr is licensed under the MIT license.

[2]: http://github.com/lukhnos/objectiveflickr

License
-------

The Noticings Uploader is licensed under Apache 2.0. In addition to the trademark protection that the license covers, don't use the logo or name "Noticings" in anything you do with this, or suggest that it is in anyway endorsed by Noticings or any of the contributors to the app.