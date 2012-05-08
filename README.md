Factor Friends
===

Factor Friends is a simple code example of a multiplayer iOS/Android game with Facebook integration, written using [Corona SDK](http://www.anscamobile.com/corona/).
Here is a brief overview of the project.

By Paul Moore, licensed under GPL v3.0.
Artwork and sound courtesy of Morgan Long.

---
## Project Contents

* *root* - Contains iOS icon images, launch images, licensing, configuration files, and other basic paraphernalia.
* *aeslua* - AESLUA source files.
* *res* - Resource files for artwork, music, and animation.
* *game* - Game Scene source files.
* *menu* - Menu Scene source files.
* *connect* - Connection Scene source files.
* *result* - GameOver Scene source files.

---
## How to Play

The game is a fairly simple game based around integer factorization.
Because it depends on the GraphAPI for networking, it requires that you have a valid Facebook account.
Don't worry, it does not post anything to any of your feeds.

1. Open the App and click the 'log into Facebook' icon.  The app is equipped with SSO, so it may or may not login directly.
2. Once logged in, you should see a list of your Facebook friends.  Click 'play' beside any one of them.
3. If they have the app running and are in the menu screen, they will receive your game request.  If they accept, you will begin the game together.
4. The game alternates between one person creating integers from prime numbers, then the other person factoring that number.
5. You get points by correctly factoring your buddy's integer.
6. After x amount of turns, or a tie-breaker, the person with the most points wins.

And that is all there is to it!

---
## Technology

Below is a list of tech that the app utilizes.

### User Accounts

To avoid writing an application server from scratch (or integrating with one), [Facebook](http://www.facebook.com/) was chosen since it is easy to use, and already has the existing necessary social structure.

The app requires no extended permissions, but __does__ use the following information:

* Name
* Gender
* Facebook ID
* Friends (Facebook ID, Name, Profile Picture)

No login or account information is stored locally or remotely anywhere, aside from what may be stored (temporarily) by the Pubnub cloud servers.

### Networking

[Pubnub](http://www.pubnub.com/) is used for communication between clients.  I find it quite interesting, and usually enjoyable, to work with.
Pubnub is pretty accessible and not platform dependant, it has many language bindings.

For all intents and purposes, the communication model is peer-to-peer.  A user's Facebook ID is used to identify and connect to his or her Facebook friends.

### Dependencies

1. [AESLUA v0.2](http://luaforge.net/projects/aeslua/) (Not currently used, but would be if a Pubnub cipher key is used).
2. [LuaBit v0.4](http://luaforge.net/projects/bit/) (Dependency for AESLUA).
3. [base64](https://gist.github.com/2563975) (Needed if a Pubnub cipher key is used).
4. [pubnub-api](https://github.com/paulmoore/pubnub-api) (Any Pubnub API will do, however, my fork contains all the above dependencies).

These dependencies are included with the source distribution.

### Building

You can build so long as you have Corona SDK.  Everything you need should be packed within this source distribution.
Tested with *Corona SDK Build 2012.799*, on *OSX 10.7*.

If you do plan on building, make sure you update the __bundle identifier__ in the build.settings if you plan on testing on a device.

---
## Known Issues

The only bugs I am currently aware of are audio related bugs.  For some reason, audio sometimes decides not to play.  I've encoded the audio as 16-bit... __etc etc etc__ .wav files but I'm still having troubles.  I've monitored audio channels and looked for errors but I didn't find anything.  At this point, I'm not sure if it is a Corona bug, Apple's OpenAL implementation, or my own doing.

I'm sorry if it ruins your experience, the music is quite catchy.

---

Have Fun!
