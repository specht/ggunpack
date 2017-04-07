# Thimbleweed Park file extraction tool

This script extracts all files from the Thimbleweed Park pack files. To run the script, you need the game data files included in the game. 

In case you haven't done so already, go and buy the game on [Steam](http://store.steampowered.com/app/569860), 
[GOG](https://www.gog.com/game/thimbleweed_park), 
[XBox](https://www.microsoft.com/en-US/store/p/Thimbleweed-Park/9NBLGGH40DCM),
or in the [AppStore](https://itunes.apple.com/us/app/thimbleweed-park/id1214713872?mt=12).

Usage:

```
$ ./ggunpack.rb ~/GOG Games/Thimbleweed Park/game/ThimbleweedPark.ggpack1
$ ./ggunpack.rb ~/GOG Games/Thimbleweed Park/game/ThimbleweedPark.ggpack2
```

This will produce a lot of files:

```
$ du -h haul
67M	haul/png
2,8M	haul/tsv
504K	haul/byack
20K	haul/nut
824K	haul/fnt
54M	haul/lip
1,5M	haul/wimpy
118M	haul/wav
2,2M	haul/bnut
4,2M	haul/json
159M	haul/ogg/voicemail
635M	haul/ogg
1,9M	haul/txt
887M	haul
```

Have fun!
